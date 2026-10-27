///|
extern "C" fn exit_process(status : Int32) -> Unit = "exit"

///|
fn[T] fail(message : String) -> T {
  println("moonbridge: \{message}")
  exit_process(1)
  abort(message)
}

///|
fn print_usage() -> Unit {
  println(
    "MoonBridge: generate a C header from MoonBit #export_name declarations",
  )
  println("")
  println("Usage:")
  println(
    "  moon run cmd/main -- header --package PATH --out FILE [--guard IDENTIFIER]",
  )
  println("")
  println(
    "The package must already compile with `pkgtype(kind: \"foreign_library\")`.",
  )
}

///|
async fn main {
  let args = @env.args()
  if args.length() < 2 {
    print_usage()
    return
  }
  let command = args[1]
  if command == "--help" || command == "-h" {
    print_usage()
    return
  }
  if command == "--version" {
    println("moonbridge 0.1.0")
    return
  }
  if command != "header" {
    fail("unknown command: \{command}")
  }

  let mut package_path = ""
  let mut output_path = ""
  let mut header_guard = "MOONBRIDGE_GENERATED_H"
  let mut index = 2
  while index < args.length() {
    if index + 1 >= args.length() {
      fail("missing value for option \{args[index]}")
    }
    let option = args[index]
    let value = args[index + 1]
    match option {
      "--package" => package_path = value
      "--out" => output_path = value
      "--guard" => header_guard = value
      _ => fail("unknown option: \{option}")
    }
    index = index + 2
  }
  if package_path.is_empty() {
    fail("--package is required")
  }
  if output_path.is_empty() {
    fail("--out is required")
  }
  if !@fs.exists("\{package_path}/moon.pkg") {
    fail("package directory must contain moon.pkg: \{package_path}")
  }

  let entries = @fs.readdir(
    package_path,
    include_hidden=false,
    include_special=false,
    sort=true,
  )
  let exports : Array[@moonbridge.Export] = []
  let mut source_count = 0
  for entry in entries {
    if entry.has_suffix(".mbt") &&
      !entry.has_suffix("_test.mbt") &&
      !entry.has_suffix("_wbtest.mbt") {
      source_count = source_count + 1
      let source_path = "\{package_path}/\{entry}"
      let source = @fs.read_file(source_path).text()
      match @moonbridge.scan_exports(source_path, source) {
        Ok(found) =>
          for item in found {
            exports.push(item)
          }
        Err(error) => fail(error)
      }
    }
  }
  if source_count == 0 {
    fail("no production .mbt source files found in \{package_path}")
  }
  if exports.is_empty() {
    fail("no #export_name declarations found in \{package_path}")
  }
  let header = match @moonbridge.render_header(exports, header_guard) {
    Ok(value) => value
    Err(error) => {
      fail(error)
      ""
    }
  }

  // Stage beside the destination so the final rename remains on one filesystem.
  let temp_directory = "\{output_path}.moonbridge-tmp"
  if @fs.exists(temp_directory) {
    fail(
      "temporary directory already exists; inspect and remove it first: \{temp_directory}",
    )
  }
  @fs.mkdir(temp_directory)
  let temp_file = "\{temp_directory}/header.h"
  @fs.write_file(temp_file, header)
  @fs.rename(temp_file, output_path, replace=true)
  @fs.rmdir(temp_directory)
  let export_count = exports.length()
  println("Wrote \{output_path} (\{export_count} exports)")
}
