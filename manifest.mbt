///|
/// Append a JSON string with every control character escaped.
fn write_json_string(output : StringBuilder, value : String) -> Unit {
  output.write_char('"')
  let hex = "0123456789abcdef".to_array()
  for character in value.to_array() {
    let code = character.to_int()
    match character {
      '"' => output.write_string("\\\"")
      '\\' => output.write_string("\\\\")
      '\n' => output.write_string("\\n")
      '\r' => output.write_string("\\r")
      '\t' => output.write_string("\\t")
      '\u{0008}' => output.write_string("\\b")
      '\u{000c}' => output.write_string("\\f")
      _ =>
        if code < 32 {
          output.write_string("\\u00")
          output.write_char(hex[code >> 4])
          output.write_char(hex[code & 15])
        } else {
          output.write_char(character)
        }
    }
  }
  output.write_char('"')
}

///|
/// Write the common JSON fields for a type mapping.
fn write_type_json(output : StringBuilder, abi_type : AbiType) -> Unit {
  output.write_string("{\"moonbit\":")
  write_json_string(output, abi_type.moonbit_spelling())
  output.write_string(",\"c\":")
  write_json_string(output, abi_type.c_spelling())
  output.write_string(",\"bits\":\{abi_type.bit_width()}")
  output.write_string(",\"integer\":\{abi_type.is_integer()}")
  output.write_char('}')
}

///|
/// Render a stable JSON ABI manifest for downstream build systems and audits.
/// The caller supplies exports in deterministic source-file order.
pub fn render_manifest(exports : Array[Export]) -> Result[String, String] {
  let diagnostics = validate_exports(exports)
  if has_errors(diagnostics) {
    return Err(format_diagnostics(diagnostics))
  }
  let output = StringBuilder()
  output.write_string("{\n  \"schema_version\": 1,\n  \"abi_contract\": ")
  write_json_string(output, abi_contract_id())
  output.write_string(
    ",\n  \"export_count\": \{exports.length()},\n  \"exports\": [",
  )
  if !exports.is_empty() {
    output.write_char('\n')
  }
  for i = 0; i < exports.length(); i = i + 1 {
    let item = exports[i]
    let c_parameter_names = parameter_c_names(item.parameter_names)
    output.write_string("    {\"c_name\":")
    write_json_string(output, item.c_name)
    output.write_string(",\"moonbit_name\":")
    write_json_string(output, item.moonbit_name)
    output.write_string(",\"signature\":")
    write_json_string(output, item.signature())
    output.write_string(",\"source\":{\"path\":")
    write_json_string(output, item.source_path)
    output.write_string(",\"line\":\{item.source_line}}")
    output.write_string(",\"parameters\":[")
    for parameter_index = 0
        parameter_index < item.parameters.length()
        parameter_index = parameter_index + 1 {
      if parameter_index > 0 {
        output.write_char(',')
      }
      output.write_string("{\"index\":\{parameter_index},\"moonbit_name\":")
      write_json_string(output, item.parameter_names[parameter_index])
      output.write_string(",\"c_name\":")
      write_json_string(output, c_parameter_names[parameter_index])
      output.write_string(",\"type\":")
      write_type_json(output, item.parameters[parameter_index])
      output.write_char('}')
    }
    output.write_string("],\"result\":")
    write_type_json(output, item.result)
    output.write_char('}')
    if i + 1 < exports.length() {
      output.write_char(',')
    }
    output.write_char('\n')
  }
  output.write_string("  ]\n}\n")
  Ok(output.to_string())
}

///|
/// Serialize diagnostics as JSON suitable for editors and CI parsers.
pub fn render_diagnostics_json(diagnostics : Array[Diagnostic]) -> String {
  let output = StringBuilder()
  output.write_string("{\"diagnostics\":[")
  for i = 0; i < diagnostics.length(); i = i + 1 {
    if i > 0 {
      output.write_char(',')
    }
    let diagnostic = diagnostics[i]
    output.write_string("{\"code\":")
    write_json_string(output, diagnostic.code)
    output.write_string(",\"severity\":")
    write_json_string(
      output,
      match diagnostic.severity {
        Error => "error"
        Warning => "warning"
      },
    )
    output.write_string(",\"message\":")
    write_json_string(output, diagnostic.message)
    match (diagnostic.source_path, diagnostic.source_line) {
      (Some(path), Some(line)) => {
        output.write_string(",\"source\":{\"path\":")
        write_json_string(output, path)
        output.write_string(",\"line\":\{line}}")
      }
      (Some(path), None) => {
        output.write_string(",\"source\":{\"path\":")
        write_json_string(output, path)
        output.write_char('}')
      }
      (None, _) => ()
    }
    match diagnostic.help {
      Some(help) => {
        output.write_string(",\"help\":")
        write_json_string(output, help)
      }
      None => ()
    }
    output.write_char('}')
  }
  output.write_string("]}\n")
  output.to_string()
}
