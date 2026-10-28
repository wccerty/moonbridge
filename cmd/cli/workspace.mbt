///|
/// Result of scanning one package or a recursive MoonBit package tree.
priv struct ScanSummary {
  exports : Array[@moonbridge.Export]
  source_count : Int32
  package_count : Int32
}

///|
/// Ignore generated, vendored, and version-control trees during recursive scans.
fn is_ignored_directory(name : String) -> Bool {
  match name {
    ".git"
    | ".mooncakes"
    | ".repos"
    | ".tools"
    | "_build"
    | "build"
    | "dist"
    | "node_modules"
    | "target" => true
    _ => name.has_prefix(".")
  }
}

///|
/// Collect production MoonBit files in a package directory.
async fn collect_package_sources(
  directory : String,
  recursive : Bool,
  files : Array[String],
  package_count : Ref[Int32],
) -> Unit {
  let is_package = @fs.exists("\{directory}/moon.pkg")
  if is_package {
    package_count.val = package_count.val + 1
  }
  let entries = @fs.readdir(
    directory,
    include_hidden=false,
    include_special=false,
    sort=true,
  )
  for entry in entries {
    let path = "\{directory}/\{entry}"
    if is_package &&
      entry.has_suffix(".mbt") &&
      !entry.has_suffix("_test.mbt") &&
      !entry.has_suffix("_wbtest.mbt") {
      files.push(path)
    } else if recursive && !is_ignored_directory(entry) {
      match @fs.kind(path, follow_symlink=false) {
        @fs.FileKind::Directory =>
          collect_package_sources(path, recursive, files, package_count)
        _ => ()
      }
    }
  }
}

///|
/// Read exports from a package tree in stable path order and validate the whole ABI.
async fn scan_package_tree(
  package_path : String,
  recursive : Bool,
) -> Result[ScanSummary, String] {
  if !@fs.exists("\{package_path}/moon.pkg") {
    return Err("package directory must contain moon.pkg: \{package_path}")
  }
  let files : Array[String] = []
  let package_count = Ref(0)
  collect_package_sources(package_path, recursive, files, package_count)
  if files.is_empty() {
    return Err("no production .mbt source files found in \{package_path}")
  }
  let exports : Array[@moonbridge.Export] = []
  for source_path in files {
    let source = @fs.read_file(source_path).text()
    match @moonbridge.scan_exports(source_path, source) {
      Ok(found) =>
        for item in found {
          exports.push(item)
        }
      Err(error) => return Err(error)
    }
  }
  if exports.is_empty() {
    return Err("no #export_name declarations found in \{package_path}")
  }
  let diagnostics = @moonbridge.validate_exports(exports)
  if @moonbridge.has_errors(diagnostics) {
    return Err(@moonbridge.format_diagnostics(diagnostics))
  }
  Ok({
    exports,
    source_count: files.length(),
    package_count: package_count.val,
  })
}

///|
/// Find the first differing line to make a stale generated file easy to inspect.
fn first_different_line(expected : String, actual : String) -> Int32? {
  let expected_lines = expected.split("\n").to_array()
  let actual_lines = actual.split("\n").to_array()
  let count = if expected_lines.length() < actual_lines.length() {
    expected_lines.length()
  } else {
    actual_lines.length()
  }
  for i = 0; i < count; i = i + 1 {
    if expected_lines[i] != actual_lines[i] {
      return Some(i + 1)
    }
  }
  if expected_lines.length() != actual_lines.length() {
    return Some(count + 1)
  }
  None
}

///|
/// Produce a compact description of the first line where generated output drifted.
fn describe_header_drift(expected : String, actual : String) -> String {
  match first_different_line(expected, actual) {
    Some(line) =>
      "generated header differs at line \{line}; run the `header` command to update it"
    None => "generated header differs; run the `header` command to update it"
  }
}
