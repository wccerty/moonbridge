# Scalar C ABI example

This is a minimal MoonBit `foreign_library` package used to exercise the header generator.

1. On Linux, run `bash scripts/package-linux.sh examples/scalar_exports dist scalar_exports`; it generates `dist/scalar_exports.h`, `dist/libscalar_exports.a`, and `dist/libscalar_exports.so` after validating every declared C symbol in both libraries.
2. `consumer.c` and `consumer.cpp` include the generated header and exercise every advertised scalar ABI mapping: `Bool`, signed and unsigned 32/64-bit integers, `Float`, `Double`, and `Unit` return. They also call the array-allocating `Int32` export.

The Linux packager also compiles and links both consumer sources against its `.a` and `.so` outputs in CI. On Windows, `moon build --release --target native examples/scalar_exports` emits a compiler-specific `.lib`; the C and C++ consumers are verified against it. Exact local evidence is recorded in [the verification log](../../docs/verification.md).
