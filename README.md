# MoonBridge

MoonBridge is a MoonBit-first tool for generating a C/C++ header from a MoonBit package's `#export_name` declarations. It validates a narrow scalar ABI subset and refuses managed or ambiguous signatures before it writes output.

## Status

- **Implemented:** source scanning, scalar type validation, deterministic C/C++ header generation, CLI input checks, and staged output replacement.
- **Verified locally:** MoonBit package checks/tests, native CLI build/run, and C plus C++ consumers that compile, link, and execute against Windows `.lib` and Linux `.a`/`.so` outputs.
- **Linux shared-library packaging:** the script rebuilds MoonBit-generated C and the toolchain's runtime C objects with `-fPIC`, rejects text relocations, and checks every generated header symbol in both libraries.

MoonBit already provides `#export_name` and scalar C ABI mappings. MoonBridge adds header generation around those declarations and a Linux packaging step because the native build emits a static archive rather than a `.so` directly. The packaging step recompiles the generated C and runtime sources as PIC before linking the shared library.

## Quick start

The example package is a MoonBit `foreign_library` with nine exports. Its consumers call every supported scalar mapping (`Bool`, signed and unsigned 32/64-bit integers, `Float`, `Double`, and `Unit`) and an implementation that allocates an internal MoonBit array:

```moonbit
#export_name("moonbridge_add_i32")
pub fn add_i32(lhs : Int32, rhs : Int32) -> Int32 {
  lhs + rhs
}
```

Generate the header from the package directory:

```sh
moon run cmd/main -- header \
  --package examples/scalar_exports \
  --out examples/scalar_exports/moonbridge.h \
  --guard MOONBRIDGE_SCALAR_EXPORTS_H
```

On PowerShell, the same command can be written on one line:

```powershell
moon run cmd/main -- header --package examples/scalar_exports --out examples/scalar_exports/moonbridge.h --guard MOONBRIDGE_SCALAR_EXPORTS_H
```

Package the Linux header, static archive, and shared library, then compile and run the included C and C++ consumers against the outputs:

```sh
bash scripts/package-linux.sh examples/scalar_exports dist scalar_exports
cc -I dist examples/scalar_exports/consumer.c dist/libscalar_exports.a -o dist/static-c-consumer
./dist/static-c-consumer
c++ -I dist examples/scalar_exports/consumer.cpp -Ldist -lscalar_exports -Wl,-rpath,'$ORIGIN' -o dist/shared-cpp-consumer
./dist/shared-cpp-consumer
```

The script requires Linux, the official MoonBit toolchain runtime sources under `MOON_HOME` (or `~/.moon`), GNU `ar`/`nm`/`readelf`, and a GCC-compatible `cc`/`c++`. On Windows, `moon build --release --target native examples/scalar_exports` produces `scalar_exports.lib`; C and C++ consumers also compile, link, and run against that archive. See [the example notes](examples/scalar_exports/README.md) and [verification log](docs/verification.md) for exact results and platform boundaries.

## Supported ABI subset

| MoonBit type | C type |
|---|---|
| `Bool` | `int32_t` |
| `Int32` / `UInt32` | `int32_t` / `uint32_t` |
| `Int64` / `UInt64` | `int64_t` / `uint64_t` |
| `Float` / `Double` | `float` / `double` |
| `Unit` result | `void` |

The scanner accepts public top-level functions with explicit positional parameter types. It rejects `String`, `Bytes`, arrays, pointers/objects, structs, payload enums, closures, generics, optional or labelled/defaulted parameters, and error results. It also rejects invalid/duplicate C symbols and invalid include guards. C argument names are emitted as `arg0`, `arg1`, and so on.

The CLI scans `.mbt` files directly inside the selected package directory, in filename order. It skips `_test.mbt` and `_wbtest.mbt`. It parses a documented narrow declaration shape rather than claiming to be a complete MoonBit parser; keep `#export_name` on its own line before a public function, and use a simple scalar signature. Unsupported forms return a source path and line number.

## Output safety

MoonBridge validates every scanned export and the final header before it touches the destination. It writes to a temporary directory beside the requested file and renames the completed header into place. If the temporary directory already exists, the command stops and asks the caller to inspect it rather than reusing it.

## Development and verification

```sh
moon version --all
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon info
moon build --target native
moon run cmd/main -- header --package examples/scalar_exports --out examples/scalar_exports/moonbridge.h --guard MOONBRIDGE_SCALAR_EXPORTS_H
```

On 2026-10-27, the official stable updater confirmed the current local Windows toolchain as Moon `0.1.20261023` / `moonc v0.10.17+d971670cd` / `moonrun 0.1.20261023`. Check `moon version --all` for the installed versions on your machine; a clean CI runner installs the current stable toolchain through the official installer. See [the toolchain/rules audit](docs/rules.md) for the dated verification record.

## License and provenance

MoonBridge is licensed under Apache-2.0; see [LICENSE](LICENSE). The initial module skeleton came from the official `moon new` command. The CLI uses `moonbitlang/async` 0.22.5 for native file operations (Apache-2.0); no source files from that dependency are copied into MoonBridge. No source code has been copied from `moonbindgen`, `moonbind`, or MoonOHOS. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [the source/rules audit](docs/rules.md).
