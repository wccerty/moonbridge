///|
/// True for a blank line or a MoonBit line comment.
fn is_ignorable_line(line : String) -> Bool {
  let line = line.trim()
  line.is_empty() || line.has_prefix("//")
}

///|
/// Parse a single `#export_name("symbol")` attribute.
fn parse_export_name(line : String) -> Result[String, String] {
  match line.split_once("(") {
    Some((attribute, tail)) => {
      if attribute.trim().to_owned() != "#export_name" {
        return Err("expected #export_name(")
      }
      match tail.split_once(")") {
        Some((argument, suffix)) => {
          let literal = argument.trim().to_owned()
          if !literal.has_prefix("\"") || !literal.has_suffix("\"") {
            return Err("export name must be a quoted string literal")
          }
          if literal.contains_char('\\') {
            return Err("escaped export names are not supported")
          }
          if !suffix.trim().is_empty() && !suffix.trim().has_prefix("//") {
            return Err("unexpected text after #export_name")
          }
          let name = literal[1:literal.length() - 1].to_owned()
          if !is_c_identifier(name) {
            return Err("invalid C symbol name: \{name}")
          }
          Ok(name)
        }
        None => Err("unterminated #export_name attribute")
      }
    }
    None => Err("expected #export_name(")
  }
}

///|
/// Parse the limited top-level function header accepted by MoonBridge v0.
fn parse_function_header(
  source_path : String,
  source_line : Int32,
  c_name : String,
  header : String,
) -> Result[Export, String] {
  let header = match header.split_once("{") {
    Some((declaration, _)) => declaration.trim().to_owned()
    None => header.trim().to_owned()
  }
  match header.split_once("(") {
    Some((prefix, tail)) => {
      let prefix = prefix.trim().to_owned()
      if !prefix.has_prefix("pub fn") {
        return Err(
          "#export_name must be followed by a public top-level function",
        )
      }
      let moonbit_name = prefix[6:].trim().to_owned()
      if moonbit_name.is_empty() ||
        moonbit_name.contains_char('[') ||
        moonbit_name.contains("::") {
        return Err("generic functions and methods are not supported")
      }
      match tail.split_once(")") {
        Some((parameter_list, result_tail)) => {
          if parameter_list.contains_char('(') ||
            parameter_list.contains_char('?') ||
            parameter_list.contains_char('~') ||
            parameter_list.contains_char('=') {
            return Err(
              "nested, optional, labelled, or defaulted parameters are not supported",
            )
          }
          let parameters : Array[AbiType] = []
          if !parameter_list.trim().is_empty() {
            for parameter in parameter_list.split(",") {
              if parameter.trim().is_empty() {
                continue
              }
              match parameter.split_once(":") {
                Some((parameter_name, type_name)) => {
                  if parameter_name.trim().is_empty() {
                    return Err("parameter name is missing")
                  }
                  match parse_abi_type(type_name.to_owned()) {
                    Ok(Unit) =>
                      return Err("Unit is only supported as a function result")
                    Ok(abi_type) => parameters.push(abi_type)
                    Err(error) => return Err(error)
                  }
                }
                None =>
                  return Err(
                    "every exported parameter must have an explicit type",
                  )
              }
            }
          }
          let result_text = result_tail.trim().to_owned()
          let result = if result_text.is_empty() {
            Unit
          } else if result_text.has_prefix("->") {
            let type_name = result_text[2:].trim().to_owned()
            match parse_abi_type(type_name) {
              Ok(abi_type) => abi_type
              Err(error) => return Err(error)
            }
          } else {
            return Err("unsupported function result syntax")
          }
          Ok({
            source_path,
            source_line,
            moonbit_name,
            c_name,
            parameters,
            result,
          })
        }
        None => Err("unterminated function parameter list")
      }
    }
    None => Err("expected a function parameter list")
  }
}

///|
/// Extract and validate `#export_name` functions from one MoonBit source file.
/// The v0 grammar accepts public top-level functions with explicitly typed scalar parameters.
pub fn scan_exports(
  source_path : String,
  source : String,
) -> Result[Array[Export], String] {
  let lines = source.split("\n").to_array()
  let exports : Array[Export] = []
  let mut pending_name : String? = None
  let mut pending_line = 0
  let mut header = StringBuilder()
  let mut started = false
  for i = 0; i < lines.length(); i = i + 1 {
    let line = lines[i].to_owned().trim().to_owned()
    if pending_name is Some(c_name) {
      if is_ignorable_line(line) {
        continue
      }
      if !started {
        if line.has_prefix("#") {
          continue
        }
        if !line.has_prefix("pub fn") {
          return Err(
            "{source_path}:{pending_line}: #export_name must precede a public function",
          )
        }
        started = true
      }
      header.write_string(line)
      header.write_char(' ')
      if header.to_string().contains_char(')') {
        match
          parse_function_header(
            source_path,
            pending_line,
            c_name,
            header.to_string(),
          ) {
          Ok(item) => {
            for existing in exports {
              if existing.c_name == item.c_name {
                return Err(
                  "\{source_path}:\{pending_line}: duplicate C symbol \{item.c_name}",
                )
              }
            }
            exports.push(item)
            pending_name = None
            pending_line = 0
            header = StringBuilder()
            started = false
          }
          Err(error) => return Err("\{source_path}:\{pending_line}: \{error}")
        }
      }
      continue
    }
    if is_ignorable_line(line) {
      continue
    }
    if line.has_prefix("#export_name") {
      match parse_export_name(line) {
        Ok(name) => {
          pending_name = Some(name)
          pending_line = i + 1
          header = StringBuilder()
          started = false
        }
        Err(error) => {
          let source_line = i + 1
          return Err("\{source_path}:\{source_line}: \{error}")
        }
      }
    }
  }
  if pending_name is Some(_) {
    return Err(
      "\{source_path}:\{pending_line}: no function follows #export_name",
    )
  }
  Ok(exports)
}
