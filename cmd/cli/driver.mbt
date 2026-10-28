///|
fn print_usage() -> Unit {
  println("MoonBridge 0.3.0: inspect and compare scalar C ABI exports")
  println("")
  println("Usage:")
  println(
    "  moon run cmd/main -- header --package PATH --out FILE [--guard IDENTIFIER] [--recursive]",
  )
  println(
    "  moon run cmd/main -- manifest --package PATH [--out FILE|-] [--recursive]",
  )
  println(
    "  moon run cmd/main -- report --package PATH [--out FILE|-] [--recursive]",
  )
  println(
    "  moon run cmd/main -- check --package PATH --out HEADER [--guard IDENTIFIER] [--recursive]",
  )
  println(
    "  moon run cmd/main -- compare --old PATH --new PATH [--out FILE|-] [--recursive] [--deny-breaking]",
  )
  println("")
  println("Commands:")
  println("  header    Generate a deterministic C/C++ header")
  println("  manifest  Emit a versioned JSON ABI manifest (stdout by default)")
  println(
    "  report    Print a human-readable ABI inventory (stdout by default)",
  )
  println("  check     Verify that a checked-in header matches current exports")
  println("  compare   Review C ABI additions, removals, and signature changes")
  println("")
  println("Options:")
  println("  --package PATH   Package directory containing moon.pkg")
  println(
    "  --out FILE       Output file; manifest also accepts '-' for stdout",
  )
  println("  --guard NAME     C include guard for header generation/checking")
  println(
    "  --recursive      Scan nested MoonBit packages in stable path order",
  )
  println("  --old / --new    Package snapshots for ABI comparison")
  println(
    "  --deny-breaking  Fail when symbols are removed or signatures change",
  )
  println("")
  println(
    "Only documented scalar C ABI types are accepted. Managed values are rejected.",
  )
}

///|
async fn write_atomic(
  output_path : String,
  contents : String,
) -> Result[Unit, String] {
  if output_path == "-" {
    println(contents)
    return Ok(())
  }
  let temp_directory = "\{output_path}.moonbridge-tmp"
  if @fs.exists(temp_directory) {
    return Err(
      "temporary directory already exists; inspect and remove it first: \{temp_directory}",
    )
  }
  @fs.mkdir(temp_directory)
  let temp_file = "\{temp_directory}/output.tmp"
  @fs.write_file(temp_file, contents)
  @fs.rename(temp_file, output_path, replace=true)
  @fs.rmdir(temp_directory)
  Ok(())
}

///|
async fn generate_header(options : CliOptions) -> Result[Unit, String] {
  let summary = match
    scan_package_tree(options.package_path, options.recursive) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let header = match
    @moonbridge.render_header(summary.exports, options.header_guard) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_atomic(options.output_path, header) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  println(
    "Wrote \{options.output_path} (\{summary.exports.length()} exports, \{summary.source_count} source files, \{summary.package_count} packages)",
  )
  Ok(())
}

///|
async fn generate_manifest(options : CliOptions) -> Result[Unit, String] {
  let summary = match
    scan_package_tree(options.package_path, options.recursive) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let manifest = match @moonbridge.render_manifest(summary.exports) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_atomic(options.output_path, manifest) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  if options.output_path != "-" {
    println(
      "Wrote \{options.output_path} (\{summary.exports.length()} exports, \{summary.package_count} packages)",
    )
  }
  Ok(())
}

///|
async fn generate_report(options : CliOptions) -> Result[Unit, String] {
  let summary = match
    scan_package_tree(options.package_path, options.recursive) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let report = match @moonbridge.render_report(summary.exports) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_atomic(options.output_path, report) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok(())
}

///|
async fn compare_abi(options : CliOptions) -> Result[Unit, String] {
  let previous = match
    scan_package_tree(options.previous_package_path, options.recursive) {
    Ok(value) => value
    Err(error) => return Err("old package: \{error}")
  }
  let current = match
    scan_package_tree(options.current_package_path, options.recursive) {
    Ok(value) => value
    Err(error) => return Err("new package: \{error}")
  }
  let comparison = match
    @moonbridge.compare_export_sets(previous.exports, current.exports) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let report = @moonbridge.render_comparison_text(comparison)
  match write_atomic(options.output_path, report) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  if comparison.has_breaking_changes() && options.deny_breaking {
    return Err("breaking ABI changes detected (--deny-breaking)")
  }
  Ok(())
}

///|
async fn check_header(options : CliOptions) -> Result[Unit, String] {
  let summary = match
    scan_package_tree(options.package_path, options.recursive) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let expected = match
    @moonbridge.render_header(summary.exports, options.header_guard) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !@fs.exists(options.output_path) {
    return Err(
      "header not found: \{options.output_path}; run the `header` command to create it",
    )
  }
  let actual = @fs.read_file(options.output_path).text()
  if actual != expected {
    return Err(describe_header_drift(expected, actual))
  }
  println(
    "Header is up to date (\{summary.exports.length()} exports, \{summary.source_count} source files, \{summary.package_count} packages)",
  )
  Ok(())
}

///|
/// Run the selected CLI command and return expected user-facing failures.
pub async fn run(args : Array[String]) -> Result[Unit, String] {
  let options = match parse_cli_args(args) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match options.command {
    Help => {
      print_usage()
      Ok(())
    }
    Version => {
      println("moonbridge \{cli_version()}")
      Ok(())
    }
    GenerateHeader => generate_header(options)
    GenerateManifest => generate_manifest(options)
    GenerateReport => generate_report(options)
    CheckHeader => check_header(options)
    CompareAbi => compare_abi(options)
  }
}
