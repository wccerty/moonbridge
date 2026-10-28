# Local verification log

Verification date: 2026-10-27 (Asia/Shanghai). This log distinguishes commands actually run from remaining platform work. Earlier cross-platform checks used MoonBit `moon 0.1.20261023`, `moonc v0.10.17+d971670cd`, and `moonrun 0.1.20261023`; the current stable-upgrade result and Windows regression run are recorded below after completion.

## Toolchain setup

The official stable updater completed on 2026-10-27, installing to the user's MoonBit directory and reporting `Finished. moon: ran 324 tasks, now up to date` and `Moonbit installed successfully` (exit code 0). It reported the same stable versions already used by the project: `moon 0.1.20261023`, `moonc v0.10.17+d971670cd`, and `moonrun 0.1.20261023`. Its PowerShell `Set-ExecutionPolicy` module-load warning was nonfatal. The async dependency is pinned to `moonbitlang/async@0.22.5`. No development-channel flag was used.

For local commands in this log, PowerShell was started from the repository root. The contest pages do not pin a MoonBit compiler version. The stable command reference documents `--dev` as the development-version option; the official updater completed without `--dev` and resolved the stable versions shown above. CI prints the installed version; see [the rules audit](rules.md).

## MoonBit checks

| Command | Result |
|---|---|
| `moon version --all` | Passed; reports the versions above. |
| `moon fmt --check` | Passed. |
| `moon check --deny-warn` | Passed. |
| `moon test --deny-warn` | Passed; 4 tests. |
| `moon info` | Passed; a repeated run produced no further interface changes. |
| `moon build --target native` | Passed for the CLI and scalar export example. |
| `moon build --release --target native` | Passed on Windows and Linux; built the CLI and foreign-library example. |
| `moon build --release --target native examples/scalar_exports` | Passed; produced `_build/native/release/build/examples/scalar_exports/scalar_exports.lib` on Windows and `scalar_exports.a` on Linux. |
| `moon run cmd/main -- header --package examples/scalar_exports --out examples/scalar_exports/moonbridge.h --guard MOONBRIDGE_SCALAR_EXPORTS_H` | Passed after stable refresh; wrote nine exports and preserved the header SHA-256. |

The generated interfaces `pkg.generated.mbti`, `cmd/main/pkg.generated.mbti`, and `examples/scalar_exports/pkg.generated.mbti` are compiler output, not hand-edited declarations. The public API interface does not encode the `#export_name` attribute, which is why MoonBridge scans source declarations. `moon info` regenerated the example interface after adding the ABI matrix; no manual interface edits were made.

The Ubuntu workflow at `.github/workflows/ci.yml` follows the shape of the [OSC 2026 sample](https://github.com/PaiGack/moonbitlang-OSC2026/blob/main/.github/workflows/test.yml) and [MoonBit Community workflow templates](https://github.com/moonbit-community/.github/tree/main/workflow-templates), adjusted to run the project's actual Linux `.a/.so` packaging and C/C++ consumer checks.

## C ABI evidence on Windows

Host: Windows x86-64, Visual Studio Community 2022 C/C++ tools (`cl.exe`, `dumpbin.exe`), compiler toolset 14.36.32532.

`dumpbin /linkermember:2 _build/native/release/build/examples/scalar_exports/scalar_exports.lib` listed unmangled external C symbols. The generated header and library expose nine functions: the two `Int32` examples plus echo functions for `Bool` (`int32_t`), `UInt32`, `Int64`, `UInt64`, `Float`, `Double`, and a `Unit`/`void` return.

After calling `VC/Auxiliary/Build/vcvars64.bat`, both of these independent consumers compiled and linked against the generated header and `.lib`, and both executables returned exit code 0:

```powershell
cl.exe /nologo /I examples/scalar_exports examples/scalar_exports/consumer.c _build/native/release/build/examples/scalar_exports/scalar_exports.lib /Fe:_build/native/release/c-consumer.exe
_build/native/release/c-consumer.exe

cl.exe /nologo /I examples/scalar_exports examples/scalar_exports/consumer.cpp _build/native/release/build/examples/scalar_exports/scalar_exports.lib /Fe:_build/native/release/cpp-consumer.exe
_build/native/release/cpp-consumer.exe
```

Both C and C++ consumers were recompiled and run after adding the ABI matrix. Each calls all nine exports, including every advertised scalar representation and the `Unit` return; the array-allocating implementation also succeeds without crossing the C boundary with a managed object. One Windows native build emitted MSVC warning C4005 (`EINVAL` redefinition) from the pinned `moonbitlang/async` file-system dependency, but the build and consumers succeeded.

## Linux static and shared library evidence

Host: the local Docker Desktop Linux amd64 engine, Ubuntu 24.04, MoonBit `moon 0.1.20261023` / `moonc v0.10.17+d971670cd`, GCC/G++ 13.3.0 and GNU binutils. The container mounted the repository read-only, copied source into a fresh temporary directory, and installed MoonBit with the official Unix installer. `moon update` fetched the declared async dependency.

The initial `scalar_exports.a` links and runs in independent C and C++ consumers. A direct `-shared --whole-archive` link fails because MoonBit's archive contains non-PIC runtime objects (`R_X86_64_PC32` against `stderr`). `scripts/package-linux.sh` addresses that build boundary: it extracts the actual compiler archive, recompiles matching runtime C sources and MoonBit-generated package C as PIC, links a shared object, rejects `TEXTREL`, and verifies every header prototype appears in both library symbol tables.

The following full command passed in the clean Linux container:

```sh
bash scripts/package-linux.sh examples/scalar_exports /tmp/moonbridge-package scalar_exports
nm -g --defined-only /tmp/moonbridge-package/libscalar_exports.a
cc -I /tmp/moonbridge-package examples/scalar_exports/consumer.c /tmp/moonbridge-package/libscalar_exports.a -o /tmp/moonbridge-c-consumer
/tmp/moonbridge-c-consumer
g++ -I /tmp/moonbridge-package examples/scalar_exports/consumer.cpp /tmp/moonbridge-package/libscalar_exports.a -o /tmp/moonbridge-cpp-consumer
/tmp/moonbridge-cpp-consumer
cc -I /tmp/moonbridge-package examples/scalar_exports/consumer.c -L/tmp/moonbridge-package -lscalar_exports -Wl,-rpath,/tmp/moonbridge-package -o /tmp/moonbridge-shared-c-consumer
/tmp/moonbridge-shared-c-consumer
g++ -I /tmp/moonbridge-package examples/scalar_exports/consumer.cpp -L/tmp/moonbridge-package -lscalar_exports -Wl,-rpath,/tmp/moonbridge-package -o /tmp/moonbridge-shared-cpp-consumer
/tmp/moonbridge-shared-cpp-consumer
```

After expanding the example, reran the Linux workflow from a read-only workspace mount copied into a temporary container directory. `moon update`, `moon fmt --check`, `moon check --deny-warn`, all four MoonBit tests, `moon info` interface comparisons, release build, and header generation all passed. GCC and G++ consumers each compiled, linked, and ran against both `.a` and `.so`; all returned exit code 0 while calling all nine exports. The packager found all header symbols in both libraries, and `readelf` found no `TEXTREL`. Final output included `LINUX_ABI_MATRIX_PASS`.

## CLI failure safety

An ignored temporary fixture declared a `String` parameter, which the supported ABI must reject. The CLI returned exit code 1 with a file/line diagnostic (`unsupported C ABI type: String`), kept a pre-existing destination marker unchanged, and left no staging directory behind. The fixture and marker were stored below ignored `.tools/` and are not part of the distributable source tree.

## Remaining verification

- A local Linux package and consumer run has passed; `.github/workflows/ci.yml` repeats it on Ubuntu. Remote GitHub Actions run `40521954109` completed successfully on 2026-10-27; the `linux-native` job passed MoonBit checks, build, `.a/.so` packaging, and C/C++ static/shared consumer runs. The Copilot setup workflow run `40521953181` also succeeded.
- `moon package --list` passed after `moon.mod` was populated with `https://github.com/wccerty/moonbridge`; the package listing includes source, generated interfaces, docs, license notices, example, and packager with no missing-repository warning. The Mooncakes archive is not yet published.
- Source count and participant rewrite notes are in `submission/`; the 2026-10-28 working tree contains 15 `.mbt` files / 2,587 physical lines and 2,320 nonblank, noncomment lines (1,592 implementation, 728 tests). No package has been published and no contest form has been submitted.
- The public repository is `https://github.com/wccerty/moonbridge`, with `origin` configured, `main` as default branch, and 13 pushed commits. GitHub's commits API reports all 13 authors as `wccerty`. The current GitHub CLI identity was verified on 2026-10-27 by running `gh api user --jq .login`; the result was `wccerty`.

## 2026-10-27 toolchain refresh and remote state

On 2026-10-27, `moon version --all` after upgrade reported `moon 0.1.20261023 (3778465 2026-10-23)`, `moonc v0.10.17+d971670cd (2026-10-23)`, and `moonrun 0.1.20261023 (3778465 2026-10-23)`. The following all returned exit code 0: `moon fmt --check`, `moon check --deny-warn`, `moon test --deny-warn` (4 passed), `moon info`, `moon build --release --target native`, and `moon package --list`. The package listing no longer warned about the repository URL. The Windows release build emitted the known nonfatal MSVC C4005 warning for `EINVAL` in the pinned async dependency. The CLI regenerated `examples/scalar_exports/moonbridge.h` with 9 exports; its SHA-256 before and after was identical (`AC17E252F05C4054E47594D27428B11B3FE83924B56997D3DCD2FFB258F31930`). Both MSVC C and C++ consumers compiled, linked to the release `.lib`, and ran successfully (exit code 0).

The GitHub identity check is complete: the exact command `gh api user --jq .login` returned `wccerty` with exit code 0. The public profile `email` field was empty, so with the user's authorization the repository-only Git author was set to `wccerty` and the GitHub ID-based noreply format. GitHub confirmed all 13 pushed commits are authored by `wccerty`. The public repo has `main` as its default branch and remote Actions passed.

`moon publish --dry-run` validated the package archive and ran `moon check` on the extracted archive successfully, then returned HTTP 403 because the current Mooncakes CLI login does not match the module owner `wccerty`. No package was uploaded and no Mooncakes account was changed. Retry publication after the user authenticates the Mooncakes CLI as `wccerty`.

## 2026-10-28 ABI tooling expansion

The working tree now adds a JSON ABI manifest, a text ABI inventory, location-aware validation diagnostics, stable recursive package scanning, generated-header drift checking, safe C parameter names, and a package-snapshot comparison API and CLI. The comparator reports additions, removals, and C-visible signature changes; `--deny-breaking` makes removals and signature changes return a failure status. It intentionally ignores MoonBit function and parameter renames when the exported C symbol and C types stay the same.

Current local toolchain from `moon version --all`: Moon `0.1.20261023`, `moonc v0.10.17+d971670cd`, and `moonrun 0.1.20261023`.

| Command or check | Result |
|---|---|
| `moon fmt --check` | Passed after the extension. |
| `moon check --deny-warn` | Passed. |
| `moon test --deny-warn` | Passed; 28 tests. |
| `moon info` | Passed; updated generated interface files, including the new CLI package interface. |
| `moon run cmd/main -- compare --old examples/scalar_exports --new examples/scalar_exports --deny-breaking` | Passed; 0 additions, removals, or signature changes. |
| `moon run cmd/main -- manifest --package examples/scalar_exports --out _build/moonbridge-manifest-check.json` | Passed; PowerShell `ConvertFrom-Json` confirmed schema 1, 9 exports, and contract `moonbit-c-scalar-v1`. |
| `moon run cmd/main -- header ...` and `moon run cmd/main -- check ...` | Passed; regenerated the 9-export header and confirmed it is current. |
| Source size | 15 `.mbt` files; 2,587 physical lines; 2,320 nonblank, noncomment lines (1,592 implementation and example, 728 tests). |
| `moon run cmd/main -- compare --old _build/abi-compare-old --new _build/abi-compare-new --deny-breaking` | Expected failure verified; detected one addition, one removal, and one signature change, then exited 1. Fixtures are ignored under `_build/`. |
| `moon build --release --target native` | Passed; produced the CLI executable and scalar example `.lib`. |
| MSVC C and C++ consumer compile/link/run | Both passed against the regenerated header and release `.lib` after this expansion. |
| `moon package --list` | Passed; archive listing includes the CLI package, comparator, diagnostics, manifest, report, examples, notices, and docs. |

README, the ABI feature CI step, and submission fact sheets were updated with the new commands and the measured source count. The ABI extension remains local and unpushed; GitHub Actions has not yet run this revision. The current read-only `gh api user --jq .login` check returned HTTP 401, so no remote update was attempted. The Windows `.lib` and C/C++ consumers were rerun successfully after the expansion. The Linux `.a/.so` consumers passed on 2026-10-27; rerun the Linux package workflow and remote CI after publishing this revision.
