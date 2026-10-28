///|
/// Commands supported by the MoonBridge CLI.
pub(all) enum CliCommand {
  GenerateHeader
  GenerateManifest
  GenerateReport
  CheckHeader
  CompareAbi
  Help
  Version
}

///|
/// Parsed options shared by the header, manifest, and check commands.
pub(all) struct CliOptions {
  command : CliCommand
  package_path : String
  previous_package_path : String
  current_package_path : String
  output_path : String
  header_guard : String
  recursive : Bool
  deny_breaking : Bool
}

///|
/// Convert command-line tokens into validated command settings.
pub fn parse_cli_args(args : Array[String]) -> Result[CliOptions, String] {
  if args.length() < 2 {
    return Ok({
      command: Help,
      package_path: "",
      previous_package_path: "",
      current_package_path: "",
      output_path: "",
      header_guard: "MOONBRIDGE_GENERATED_H",
      recursive: false,
      deny_breaking: false,
    })
  }
  let command = match args[1] {
    "header" => GenerateHeader
    "manifest" => GenerateManifest
    "report" => GenerateReport
    "check" => CheckHeader
    "compare" => CompareAbi
    "help" | "--help" | "-h" => Help
    "--version" => Version
    unknown => return Err("unknown command: \{unknown}")
  }
  let mut package_path = ""
  let mut output_path = if command is GenerateManifest ||
    command is GenerateReport ||
    command is CompareAbi {
    "-"
  } else {
    ""
  }
  let mut header_guard = "MOONBRIDGE_GENERATED_H"
  let mut recursive = false
  let mut previous_package_path = ""
  let mut current_package_path = ""
  let mut deny_breaking = false
  let mut package_seen = false
  let mut output_seen = false
  let mut guard_seen = false
  let mut recursive_seen = false
  let mut previous_seen = false
  let mut current_seen = false
  let mut deny_breaking_seen = false
  let mut index = 2
  while index < args.length() {
    let option = args[index]
    if option == "--recursive" {
      if recursive_seen {
        return Err("--recursive may only be specified once")
      }
      recursive = true
      recursive_seen = true
      index = index + 1
      continue
    }
    if option == "--deny-breaking" {
      if deny_breaking_seen {
        return Err("--deny-breaking may only be specified once")
      }
      deny_breaking = true
      deny_breaking_seen = true
      index = index + 1
      continue
    }
    if index + 1 >= args.length() {
      return Err("missing value for option \{option}")
    }
    let value = args[index + 1]
    if value.is_empty() {
      return Err("empty value for option \{option}")
    }
    match option {
      "--package" => {
        if package_seen {
          return Err("--package may only be specified once")
        }
        package_seen = true
        package_path = value
      }
      "--out" => {
        if output_seen {
          return Err("--out may only be specified once")
        }
        output_seen = true
        output_path = value
      }
      "--guard" => {
        if guard_seen {
          return Err("--guard may only be specified once")
        }
        guard_seen = true
        header_guard = value
      }
      "--old" => {
        if previous_seen {
          return Err("--old may only be specified once")
        }
        previous_seen = true
        previous_package_path = value
      }
      "--new" => {
        if current_seen {
          return Err("--new may only be specified once")
        }
        current_seen = true
        current_package_path = value
      }
      _ => return Err("unknown option: \{option}")
    }
    index = index + 2
  }
  if command is Help || command is Version {
    if args.length() > 2 {
      return Err("help and version commands do not accept options")
    }
  } else if command is CompareAbi {
    if previous_package_path.is_empty() || current_package_path.is_empty() {
      return Err("compare requires both --old and --new package paths")
    }
    if package_seen || guard_seen {
      return Err("compare accepts --old and --new, not --package or --guard")
    }
  } else {
    if previous_seen || current_seen || deny_breaking_seen {
      return Err("--old, --new, and --deny-breaking are only valid for compare")
    }
    if package_path.is_empty() {
      return Err("--package is required")
    }
    if command is GenerateHeader || command is CheckHeader {
      if output_path.is_empty() {
        return Err("--out is required for the `header` and `check` commands")
      }
      if output_path == "-" && command is CheckHeader {
        return Err("check requires a file path for --out")
      }
      if output_path == "-" && command is GenerateHeader {
        return Err("header output must be a file path, not stdout")
      }
    }
    if (command is GenerateManifest || command is GenerateReport) && guard_seen {
      return Err("--guard is only valid for the header and check commands")
    }
    if (command is GenerateManifest || command is GenerateReport) &&
      output_path == "" {
      output_path = "-"
    }
  }
  Ok({
    command,
    package_path,
    previous_package_path,
    current_package_path,
    output_path,
    header_guard,
    recursive,
    deny_breaking,
  })
}

///|
/// CLI package version shown by `--version`.
pub fn cli_version() -> String {
  "0.3.0"
}
