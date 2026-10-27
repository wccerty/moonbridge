#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/package-linux.sh <foreign-library-package> <output-directory> [library-name]

Builds a Linux native .a and PIC .so from a MoonBit foreign_library package,
generates its C header, and verifies the declared C symbols in the .so.
Run from a MoonBit module that includes MoonBridge.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi
if [[ $(uname -s) != Linux ]]; then
  echo "MoonBridge Linux packaging requires Linux; use the host MoonBit build for its native archive on other platforms." >&2
  exit 2
fi

moonbridge_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
package_dir=$(realpath "$1")
output_dir=$(mkdir -p "$2" && cd "$2" && pwd)
library_name=${3:-$(basename "$package_dir")}
module_root=$package_dir
while [[ ! -f "$module_root/moon.mod" ]]; do
  parent=$(dirname "$module_root")
  if [[ "$parent" == "$module_root" ]]; then
    echo "could not find moon.mod above package: $package_dir" >&2
    exit 2
  fi
  module_root=$parent
done
package_rel=$(realpath --relative-to="$module_root" "$package_dir")
if [[ ! -f "$package_dir/moon.pkg" ]]; then
  echo "package directory must contain moon.pkg: $package_dir" >&2
  exit 2
fi
if [[ ! "$library_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "library name must be a portable C identifier: $library_name" >&2
  exit 2
fi

moon_home=${MOON_HOME:-"$HOME/.moon"}
runtime_dir="$moon_home/lib/runtime"
include_dir="$moon_home/include"
if [[ ! -d "$runtime_dir" || ! -f "$include_dir/moonbit.h" ]]; then
  echo "MoonBit runtime sources were not found under $moon_home; install the native toolchain or set MOON_HOME." >&2
  exit 2
fi

package_name=$(basename "$package_dir")
build_dir="$module_root/_build/native/release/build/$package_rel"
temp_dir=$(mktemp -d "$output_dir/.moonbridge-package.XXXXXXXX")
cleanup() { rm -rf -- "$temp_dir"; }
trap cleanup EXIT

cd "$module_root"
moon build --release --target native "$package_rel"
archive="$build_dir/$package_name.a"
generated_c="$build_dir/$package_name.c"
if [[ ! -f "$archive" || ! -f "$generated_c" ]]; then
  echo "MoonBit did not produce the expected archive and generated C source under $build_dir" >&2
  exit 1
fi

guard="MOONBRIDGE_$(printf '%s' "$library_name" | tr '[:lower:]' '[:upper:]')_H"
moon -C "$moonbridge_root" run cmd/main -- header --package "$package_dir" --out "$temp_dir/$library_name.h" --guard "$guard"
cp -- "$archive" "$temp_dir/lib$library_name.a"

object_dir="$temp_dir/objects"
mkdir -p "$object_dir"
(cd "$object_dir" && ar x "$archive")
cc=${CC:-cc}
compiled_runtime_objects=0
for object in "$object_dir"/runtime-*.o; do
  [[ -e "$object" ]] || continue
  source_name=${object##*/runtime-}
  source_name=${source_name%.o}.c
  source_file="$runtime_dir/$source_name"
  if [[ -f "$source_file" ]]; then
    "$cc" -fPIC -O2 -fwrapv -fno-strict-aliasing -I"$include_dir" -I"$runtime_dir" -c "$source_file" -o "$object"
    compiled_runtime_objects=$((compiled_runtime_objects + 1))
  fi
done
if [[ $compiled_runtime_objects -eq 0 ]]; then
  echo "No MoonBit runtime C objects could be rebuilt as PIC; refusing to emit a shared library." >&2
  exit 1
fi
"$cc" -fPIC -O2 -fwrapv -fno-strict-aliasing -I"$include_dir" -c "$generated_c" -o "$object_dir/$package_name.o"
pic_archive="$temp_dir/lib${library_name}_pic.a"
ar rcs "$pic_archive" "$object_dir"/*.o
"$cc" -shared -Wl,--whole-archive "$pic_archive" -Wl,--no-whole-archive -o "$temp_dir/lib$library_name.so"
if readelf -d "$temp_dir/lib$library_name.so" | grep -q TEXTREL; then
  echo "The generated shared library contains text relocations; refusing to publish it." >&2
  exit 1
fi
header_symbols=$(sed -nE 's/^[[:space:]]*(void|int32_t|uint32_t|int64_t|uint64_t|float|double)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(.*/\2/p' "$temp_dir/$library_name.h")
if [[ -z "$header_symbols" ]]; then
  echo "The generated header contains no supported exported function declarations." >&2
  exit 1
fi
while IFS= read -r symbol; do
  if ! nm -g --defined-only "$temp_dir/lib$library_name.a" | awk -v expected="$symbol" '$NF == expected { found = 1 } END { exit !found }'; then
    echo "The static archive is missing declared C symbol: $symbol" >&2
    exit 1
  fi
  if ! nm -D --defined-only "$temp_dir/lib$library_name.so" | awk -v expected="$symbol" '$NF == expected { found = 1 } END { exit !found }'; then
    echo "The shared library is missing declared C symbol: $symbol" >&2
    exit 1
  fi
done <<< "$header_symbols"

mv -f -- "$temp_dir/$library_name.h" "$output_dir/$library_name.h"
mv -f -- "$temp_dir/lib$library_name.a" "$output_dir/lib$library_name.a"
mv -f -- "$temp_dir/lib$library_name.so" "$output_dir/lib$library_name.so"
echo "Packaged $output_dir/$library_name.h, lib$library_name.a, lib$library_name.so"
