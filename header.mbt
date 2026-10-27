///|
/// Render one stable, C++-compatible header for the validated exports.
pub fn render_header(
  exports : Array[Export],
  header_guard : String,
) -> Result[String, String] {
  if !is_c_identifier(header_guard) {
    return Err("header guard must be a C identifier")
  }
  // The scanner preserves source order; the CLI sorts source filenames first.
  let ordered = [ for item in exports => item ]
  for i = 0; i < ordered.length(); i = i + 1 {
    if !is_c_identifier(ordered[i].c_name) {
      return Err("invalid C symbol name: \{ordered[i].c_name}")
    }
    for j = 0; j < i; j = j + 1 {
      if ordered[i].c_name == ordered[j].c_name {
        return Err("duplicate C symbol: \{ordered[i].c_name}")
      }
    }
  }
  let output = StringBuilder()
  output.write_string("#ifndef \{header_guard}\n#define \{header_guard}\n\n")
  output.write_string("#include <stdint.h>\n\n")
  output.write_string("#ifdef __cplusplus\nextern \"C\" {\n#endif\n\n")
  for item in ordered {
    output.write_string(item.result.c_spelling())
    output.write_char(' ')
    output.write_string(item.c_name)
    output.write_char('(')
    if item.parameters.is_empty() {
      output.write_string("void")
    } else {
      for i = 0; i < item.parameters.length(); i = i + 1 {
        if i > 0 {
          output.write_string(", ")
        }
        output.write_string(item.parameters[i].c_spelling())
        output.write_string(" arg\{i}")
      }
    }
    output.write_string(");\n")
  }
  output.write_string(
    "\n#ifdef __cplusplus\n}\n#endif\n\n#endif /* \{header_guard} */\n",
  )
  Ok(output.to_string())
}
