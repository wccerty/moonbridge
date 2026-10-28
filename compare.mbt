///|
/// Change category in a comparison of two C ABI surfaces.
pub(all) enum AbiChangeKind {
  Added
  Removed
  SignatureChanged
}

///|
/// One C symbol change between two package versions.
pub(all) struct AbiChange {
  kind : AbiChangeKind
  c_name : String
  old_signature : String?
  new_signature : String?
  old_location : String?
  new_location : String?
}

///|
/// Summary of the exported ABI difference between a previous and current package.
pub(all) struct AbiComparison {
  changes : Array[AbiChange]
  added_count : Int32
  removed_count : Int32
  changed_count : Int32
}

///|
/// Find an export by its stable C symbol.
fn find_export(exports : Array[Export], c_name : String) -> Export? {
  for item in exports {
    if item.c_name == c_name {
      return Some(item)
    }
  }
  None
}

///|
/// Compare ABI types while intentionally ignoring MoonBit and C parameter names.
fn has_same_c_signature(previous : Export, current : Export) -> Bool {
  if !previous.result.same_as(current.result) ||
    previous.parameters.length() != current.parameters.length() {
    return false
  }
  for i = 0; i < previous.parameters.length(); i = i + 1 {
    if !previous.parameters[i].same_as(current.parameters[i]) {
      return false
    }
  }
  true
}

///|
/// Compare two validated export lists by C symbol and C-visible types.
pub fn compare_export_sets(
  previous : Array[Export],
  current : Array[Export],
) -> Result[AbiComparison, String] {
  let previous_diagnostics = validate_exports(previous)
  if has_errors(previous_diagnostics) {
    return Err(
      "previous ABI is invalid:\n\{format_diagnostics(previous_diagnostics)}",
    )
  }
  let current_diagnostics = validate_exports(current)
  if has_errors(current_diagnostics) {
    return Err(
      "current ABI is invalid:\n\{format_diagnostics(current_diagnostics)}",
    )
  }
  let changes : Array[AbiChange] = []
  let mut added_count = 0
  let mut removed_count = 0
  let mut changed_count = 0
  for item in current {
    match find_export(previous, item.c_name) {
      None => {
        added_count = added_count + 1
        changes.push({
          kind: Added,
          c_name: item.c_name,
          old_signature: None,
          new_signature: Some(item.signature()),
          old_location: None,
          new_location: Some("\{item.source_path}:\{item.source_line}"),
        })
      }
      Some(old_item) =>
        if !has_same_c_signature(old_item, item) {
          changed_count = changed_count + 1
          changes.push({
            kind: SignatureChanged,
            c_name: item.c_name,
            old_signature: Some(old_item.signature()),
            new_signature: Some(item.signature()),
            old_location: Some(
              "\{old_item.source_path}:\{old_item.source_line}",
            ),
            new_location: Some("\{item.source_path}:\{item.source_line}"),
          })
        }
    }
  }
  for item in previous {
    if find_export(current, item.c_name) is None {
      removed_count = removed_count + 1
      changes.push({
        kind: Removed,
        c_name: item.c_name,
        old_signature: Some(item.signature()),
        new_signature: None,
        old_location: Some("\{item.source_path}:\{item.source_line}"),
        new_location: None,
      })
    }
  }
  Ok({ changes, added_count, removed_count, changed_count, })
}

///|
/// Whether the comparison contains a C ABI breaking change.
pub fn AbiComparison::has_breaking_changes(self : AbiComparison) -> Bool {
  self.removed_count > 0 || self.changed_count > 0
}

///|
/// Format a concise text summary with source locations for review.
pub fn render_comparison_text(comparison : AbiComparison) -> String {
  let output = StringBuilder()
  let status = if comparison.has_breaking_changes() {
    "breaking changes"
  } else {
    "compatible"
  }
  output.write_string("ABI comparison: \{status}\n")
  output.write_string("Added: \{comparison.added_count}\n")
  output.write_string("Removed: \{comparison.removed_count}\n")
  output.write_string("Changed signatures: \{comparison.changed_count}\n")
  if comparison.changes.is_empty() {
    output.write_string("No C ABI differences.\n")
  }
  for change in comparison.changes {
    match change.kind {
      Added => {
        output.write_string("+ \{change.c_name}: ")
        output.write_string(change.new_signature.unwrap())
        output.write_string(" at ")
        output.write_string(change.new_location.unwrap())
      }
      Removed => {
        output.write_string("- \{change.c_name}: ")
        output.write_string(change.old_signature.unwrap())
        output.write_string(" at ")
        output.write_string(change.old_location.unwrap())
      }
      SignatureChanged => {
        output.write_string("~ \{change.c_name}: ")
        output.write_string(change.old_signature.unwrap())
        output.write_string(" -> ")
        output.write_string(change.new_signature.unwrap())
        output.write_string(" (")
        output.write_string(change.new_location.unwrap())
        output.write_char(')')
      }
    }
    output.write_char('\n')
  }
  output.to_string()
}

///|
/// Serialize a stable machine-readable ABI comparison result.
pub fn render_comparison_json(comparison : AbiComparison) -> String {
  let output = StringBuilder()
  output.write_string("{\"schema_version\":1,\"abi_contract\":")
  write_json_string(output, abi_contract_id())
  output.write_string(",\"breaking\":\{comparison.has_breaking_changes()}")
  output.write_string(",\"added\":\{comparison.added_count}")
  output.write_string(",\"removed\":\{comparison.removed_count}")
  output.write_string(",\"changed\":\{comparison.changed_count}")
  output.write_string(",\"changes\":[")
  for i = 0; i < comparison.changes.length(); i = i + 1 {
    if i > 0 {
      output.write_char(',')
    }
    let change = comparison.changes[i]
    output.write_string("{\"kind\":")
    write_json_string(
      output,
      match change.kind {
        Added => "added"
        Removed => "removed"
        SignatureChanged => "signature_changed"
      },
    )
    output.write_string(",\"c_name\":")
    write_json_string(output, change.c_name)
    output.write_string(",\"old_signature\":")
    write_optional_json_string(output, change.old_signature)
    output.write_string(",\"new_signature\":")
    write_optional_json_string(output, change.new_signature)
    output.write_string(",\"old_location\":")
    write_optional_json_string(output, change.old_location)
    output.write_string(",\"new_location\":")
    write_optional_json_string(output, change.new_location)
    output.write_char('}')
  }
  output.write_string("]}\n")
  output.to_string()
}

///|
/// Write an optional JSON string or the JSON null literal.
fn write_optional_json_string(output : StringBuilder, value : String?) -> Unit {
  match value {
    Some(text) => write_json_string(output, text)
    None => output.write_string("null")
  }
}
