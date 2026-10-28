///|
/// Severity of an ABI validation diagnostic.
pub(all) enum DiagnosticSeverity {
  Error
  Warning
}

///|
/// A location-aware issue that can be shown to a person or serialized for CI.
pub(all) struct Diagnostic {
  code : String
  severity : DiagnosticSeverity
  message : String
  source_path : String?
  source_line : Int32?
  help : String?
}

///|
/// Format a diagnostic consistently for terminal output.
pub fn Diagnostic::format(self : Diagnostic) -> String {
  let output = StringBuilder()
  let severity = match self.severity {
    Error => "error"
    Warning => "warning"
  }
  match (self.source_path, self.source_line) {
    (Some(path), Some(line)) => output.write_string("\{path}:\{line}: ")
    (Some(path), None) => output.write_string("\{path}: ")
    (None, _) => ()
  }
  output.write_string("\{severity}[\{self.code}]: \{self.message}")
  match self.help {
    Some(help) => {
      output.write_string("\n  help: ")
      output.write_string(help)
    }
    None => ()
  }
  output.to_string()
}

///|
/// Validate invariants that require seeing every export in a package.
/// This catches duplicate symbols across files before any output is written.
pub fn validate_exports(exports : Array[Export]) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  for i = 0; i < exports.length(); i = i + 1 {
    let current = exports[i]
    if !is_c_identifier(current.c_name) {
      diagnostics.push({
        code: "MB001",
        severity: Error,
        message: "invalid C symbol name: \{current.c_name}",
        source_path: Some(current.source_path),
        source_line: Some(current.source_line),
        help: Some("use a non-reserved ASCII C identifier"),
      })
    }
    if current.parameters.length() > 127 {
      diagnostics.push({
        code: "MB002",
        severity: Error,
        message: "exported function has more than 127 parameters",
        source_path: Some(current.source_path),
        source_line: Some(current.source_line),
        help: Some("split the API into smaller scalar functions"),
      })
    }
    if current.parameter_names.length() != current.parameters.length() {
      diagnostics.push({
        code: "MB004",
        severity: Error,
        message: "parameter name count does not match parameter type count",
        source_path: Some(current.source_path),
        source_line: Some(current.source_line),
        help: Some("re-scan the MoonBit declaration before rendering output"),
      })
    }
    for j = 0; j < i; j = j + 1 {
      let previous = exports[j]
      if previous.c_name == current.c_name {
        diagnostics.push({
          code: "MB003",
          severity: Error,
          message: "duplicate C symbol \{current.c_name}; first declared at \{previous.source_path}:\{previous.source_line}",
          source_path: Some(current.source_path),
          source_line: Some(current.source_line),
          help: Some("assign a unique #export_name to each exported function"),
        })
        break
      }
    }
  }
  diagnostics
}

///|
/// Render multiple diagnostics without losing their source locations.
pub fn format_diagnostics(diagnostics : Array[Diagnostic]) -> String {
  let output = StringBuilder()
  for i = 0; i < diagnostics.length(); i = i + 1 {
    if i > 0 {
      output.write_char('\n')
    }
    output.write_string(diagnostics[i].format())
  }
  output.to_string()
}

///|
/// Return whether any item is an error and therefore blocks code generation.
pub fn has_errors(diagnostics : Array[Diagnostic]) -> Bool {
  for diagnostic in diagnostics {
    if diagnostic.severity is Error {
      return true
    }
  }
  false
}

///|
/// Create the common source-parser diagnostic from its path and line context.
pub fn parse_diagnostic(
  source_path : String,
  source_line : Int32,
  message : String,
) -> Diagnostic {
  {
    code: "MB100",
    severity: Error,
    message,
    source_path: Some(source_path),
    source_line: Some(source_line),
    help: None,
  }
}

///|
/// Explain the supported ABI boundary in a machine-stable identifier.
pub fn abi_contract_id() -> String {
  "moonbit-c-scalar-v1"
}
