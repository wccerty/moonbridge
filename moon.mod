// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "wccerty/moonbridge"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/wccerty/moonbridge"

license = "Apache-2.0"

keywords = [ "moonbit", "c", "ffi", "abi", "header" ]

preferred_target = "native"

description = "Generate C headers and Linux libraries from MoonBit scalar exports"

import {
  "moonbitlang/async@0.22.5",
}
