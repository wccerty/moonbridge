///|
/// Canonical ABI type order used by reports and audit tooling.
fn abi_type_order() -> Array[AbiType] {
  [Bool, Int32, UInt32, Int64, UInt64, Float, Double, Unit]
}

///|
/// Count how often a type appears in parameter positions.
fn count_parameter_type(exports : Array[Export], abi_type : AbiType) -> Int32 {
  let mut count = 0
  for item in exports {
    for parameter in item.parameters {
      if parameter.same_as(abi_type) {
        count = count + 1
      }
    }
  }
  count
}

///|
/// Count how often a type appears as a function result.
fn count_result_type(exports : Array[Export], abi_type : AbiType) -> Int32 {
  let mut count = 0
  for item in exports {
    if item.result.same_as(abi_type) {
      count = count + 1
    }
  }
  count
}

///|
/// Render a C declaration using readable, collision-safe parameter names.
pub fn render_c_prototype(item : Export) -> String {
  let output = StringBuilder()
  let c_names = parameter_c_names(item.parameter_names)
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
      output.write_char(' ')
      output.write_string(c_names[i])
    }
  }
  output.write_char(')')
  output.to_string()
}

///|
/// Build a human-readable ABI inventory for code review and release notes.
pub fn render_report(exports : Array[Export]) -> Result[String, String] {
  let diagnostics = validate_exports(exports)
  if has_errors(diagnostics) {
    return Err(format_diagnostics(diagnostics))
  }
  let output = StringBuilder()
  let mut parameter_count = 0
  for item in exports {
    parameter_count = parameter_count + item.parameters.length()
  }
  output.write_string("MoonBridge ABI report\n")
  output.write_string("Contract: \{abi_contract_id()}\n")
  output.write_string("Exports: \{exports.length()}\n")
  output.write_string("Scalar parameters: \{parameter_count}\n")
  output.write_string("\nType usage (MoonBit type -> C type):\n")
  for abi_type in abi_type_order() {
    let parameter_uses = count_parameter_type(exports, abi_type)
    let result_uses = count_result_type(exports, abi_type)
    if parameter_uses > 0 || result_uses > 0 {
      output.write_string(
        "  \{abi_type.moonbit_spelling()} -> \{abi_type.c_spelling()}",
      )
      output.write_string(
        "; parameters=\{parameter_uses}, results=\{result_uses}\n",
      )
    }
  }
  output.write_string("\nExports:\n")
  for item in exports {
    output.write_string("  \{item.source_path}:\{item.source_line}\n")
    output.write_string("    \{item.signature()}\n")
    output.write_string("    C: \{render_c_prototype(item)}\n")
  }
  output.write_string(
    "\nOnly scalar values cross the C ABI. Managed MoonBit values remain inside the module.\n",
  )
  Ok(output.to_string())
}
