///|
test "identifier and ABI type validation" {
  assert_true(@moonbridge.is_c_identifier("moonbridge_add_i32"))
  assert_true(!@moonbridge.is_c_identifier("9bad"))
  assert_true(!@moonbridge.is_c_identifier("has-dash"))
  assert_true(!@moonbridge.is_c_identifier("restrict"))
  assert_true(!@moonbridge.is_c_identifier("class"))
  assert_true(!@moonbridge.is_c_identifier("_reserved"))
  assert_true(@moonbridge.parse_abi_type("Bool") is Ok(@moonbridge.Bool))
  assert_true(@moonbridge.parse_abi_type("Int32") is Ok(@moonbridge.Int32))
  assert_true(@moonbridge.parse_abi_type("UInt32") is Ok(@moonbridge.UInt32))
  assert_true(@moonbridge.parse_abi_type("Int64") is Ok(@moonbridge.Int64))
  assert_true(@moonbridge.parse_abi_type("UInt64") is Ok(@moonbridge.UInt64))
  assert_true(@moonbridge.parse_abi_type("Float") is Ok(@moonbridge.Float))
  assert_true(@moonbridge.parse_abi_type("Double") is Ok(@moonbridge.Double))
  assert_true(@moonbridge.parse_abi_type("Unit") is Ok(@moonbridge.Unit))
  assert_eq(@moonbridge.Bool.c_spelling(), "int32_t")
  assert_eq(@moonbridge.Int32.c_spelling(), "int32_t")
  assert_eq(@moonbridge.UInt32.c_spelling(), "uint32_t")
  assert_eq(@moonbridge.Int64.c_spelling(), "int64_t")
  assert_eq(@moonbridge.UInt64.c_spelling(), "uint64_t")
  assert_eq(@moonbridge.Float.c_spelling(), "float")
  assert_eq(@moonbridge.Double.c_spelling(), "double")
  assert_eq(@moonbridge.Unit.c_spelling(), "void")
  assert_true(@moonbridge.parse_abi_type("String") is Err(_))
}

///|
test "scan multiline scalar exports and render deterministic header" {
  let source =
    #|// leading comment
    #|///|
    #|#export_name("moonbridge_add_i32")
    #|pub fn add_i32(
    #|  lhs : Int32,
    #|  rhs : Int32,
    #|) -> Int32 {
    #|  lhs + rhs
    #|}
    #|
    #|#export_name("moonbridge_reset")
    #|pub fn reset() -> Unit {
    #|  ()
    #|}
  match @moonbridge.scan_exports("fixture.mbt", source) {
    Ok(exports) => {
      assert_eq(exports.length(), 2)
      match @moonbridge.render_header(exports, "MOONBRIDGE_FIXTURE_H") {
        Ok(header) => {
          let expected =
            #|#ifndef MOONBRIDGE_FIXTURE_H
            #|#define MOONBRIDGE_FIXTURE_H
            #|
            #|#include <stdint.h>
            #|
            #|#ifdef __cplusplus
            #|extern "C" {
            #|#endif
            #|
            #|int32_t moonbridge_add_i32(int32_t lhs, int32_t rhs);
            #|void moonbridge_reset(void);
            #|
            #|#ifdef __cplusplus
            #|}
            #|#endif
            #|
            #|#endif /* MOONBRIDGE_FIXTURE_H */
            #|
          assert_eq(header, expected)
        }
        Err(error) => fail(error)
      }
    }
    Err(error) => fail(error)
  }
}

///|
test "managed and optional types are rejected with source location" {
  let managed =
    #|#export_name("moonbridge_string")
    #|pub fn from_string(value : String) -> Int32 { 0 }
  match @moonbridge.scan_exports("managed.mbt", managed) {
    Err(error) =>
      assert_eq(error, "managed.mbt:1: unsupported C ABI type: String")
    Ok(_) => fail("String should not cross the C ABI")
  }

  let optional =
    #|#export_name("moonbridge_optional")
    #|pub fn optional_value(value? : Int32) -> Int32 { value }
  match @moonbridge.scan_exports("optional.mbt", optional) {
    Err(error) =>
      assert_eq(
        error, "optional.mbt:1: nested, optional, labelled, or defaulted parameters are not supported",
      )
    Ok(_) => fail("optional parameters should be rejected")
  }
}

///|
test "duplicate names and invalid header guards fail" {
  let first =
    #|#export_name("moonbridge_same")
    #|pub fn first() -> Int32 { 1 }
  let second =
    #|#export_name("moonbridge_same")
    #|pub fn second() -> Int32 { 2 }
  match @moonbridge.scan_exports("first.mbt", first) {
    Ok(first_exports) =>
      match @moonbridge.scan_exports("second.mbt", second) {
        Ok(second_exports) => {
          for item in second_exports {
            first_exports.push(item)
          }
          assert_true(
            @moonbridge.render_header(first_exports, "BAD-GUARD") is Err(_),
          )
          assert_true(
            @moonbridge.render_header(first_exports, "VALID_GUARD") is Err(_),
          )
        }
        Err(error) => fail(error)
      }
    Err(error) => fail(error)
  }
}

///|
test "ABI metadata and display signatures agree with generated C spellings" {
  assert_eq(@moonbridge.Bool.moonbit_spelling(), "Bool")
  assert_eq(@moonbridge.Bool.c_spelling(), "int32_t")
  assert_eq(@moonbridge.Bool.bit_width(), 32)
  assert_true(!@moonbridge.Bool.is_integer())
  assert_eq(@moonbridge.Int32.bit_width(), 32)
  assert_true(@moonbridge.Int32.is_integer())
  assert_eq(@moonbridge.UInt64.bit_width(), 64)
  assert_true(@moonbridge.UInt64.is_integer())
  assert_eq(@moonbridge.Float.bit_width(), 32)
  assert_true(!@moonbridge.Float.is_integer())
  assert_eq(@moonbridge.Double.bit_width(), 64)
  assert_eq(@moonbridge.Unit.bit_width(), 0)
  assert_eq(
    @moonbridge.Export::{
      source_path: "math.mbt",
      source_line: 4,
      moonbit_name: "sum",
      c_name: "moonbridge_sum",
      parameters: [@moonbridge.Int32, @moonbridge.Int32],
      parameter_names: ["left", "right"],
      result: @moonbridge.Int32,
    }.signature(),
    "sum(Int32, Int32) -> Int32",
  )
}

///|
test "package validation reports duplicate symbols with both locations" {
  let exports : Array[@moonbridge.Export] = [
    {
      source_path: "first.mbt",
      source_line: 2,
      moonbit_name: "first",
      c_name: "moonbridge_shared",
      parameters: [],
      parameter_names: [],
      result: @moonbridge.Int32,
    },
    {
      source_path: "nested/second.mbt",
      source_line: 7,
      moonbit_name: "second",
      c_name: "moonbridge_shared",
      parameters: [],
      parameter_names: [],
      result: @moonbridge.Int32,
    },
  ]
  let diagnostics = @moonbridge.validate_exports(exports)
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].code, "MB003")
  assert_eq(diagnostics[0].source_path, Some("nested/second.mbt"))
  assert_eq(diagnostics[0].source_line, Some(7))
  assert_eq(
    diagnostics[0].format(),
    "nested/second.mbt:7: error[MB003]: duplicate C symbol moonbridge_shared; first declared at first.mbt:2\n  help: assign a unique #export_name to each exported function",
  )
  assert_true(@moonbridge.has_errors(diagnostics))
}

///|
test "manifest describes the ABI and each source signature" {
  let source =
    #|#export_name("moonbridge_add")
    #|pub fn add(lhs : Int32, rhs : UInt32) -> Int64 { 0L }
  match @moonbridge.scan_exports("fixture.mbt", source) {
    Ok(exports) => {
      let manifest = match @moonbridge.render_manifest(exports) {
        Ok(value) => value
        Err(error) => fail(error)
      }
      assert_true(manifest.contains("moonbit-c-scalar-v1"))
      assert_true(manifest.contains("\"export_count\": 1"))
      assert_true(manifest.contains("moonbridge_add"))
      assert_true(manifest.contains("add(Int32, UInt32) -> Int64"))
      assert_true(manifest.contains("fixture.mbt"))
      assert_true(manifest.contains("uint32_t"))
      assert_true(manifest.contains("\"bits\":64"))
      assert_true(manifest.has_suffix("}\n"))
    }
    Err(error) => fail(error)
  }
}

///|
test "manifest JSON escapes quote, slash, and control characters in paths" {
  let source =
    #|#export_name("moonbridge_one")
    #|pub fn one() -> Int32 { 1 }
  let path = "fixture\t\"quoted\".mbt"
  match @moonbridge.scan_exports(path, source) {
    Ok(exports) => {
      let manifest = match @moonbridge.render_manifest(exports) {
        Ok(value) => value
        Err(error) => fail(error)
      }
      assert_true(manifest.contains("\\t"))
      assert_true(manifest.contains("\\\"quoted\\\""))
    }
    Err(error) => fail(error)
  }
}

///|
test "inline comments do not interrupt multiline scalar signatures" {
  let source =
    #|#export_name("moonbridge_add") // stable C entry point
    #|pub fn add(
    #|  lhs : Int32, // left operand
    #|  rhs : Int32, // right operand
    #|) -> Int32 { lhs + rhs } // implementation
  match @moonbridge.scan_exports("comments.mbt", source) {
    Ok(exports) => {
      assert_eq(exports.length(), 1)
      assert_eq(exports[0].parameter_names, ["lhs", "rhs"])
      assert_eq(exports[0].signature(), "add(Int32, Int32) -> Int32")
      match @moonbridge.render_header(exports, "COMMENTS_H") {
        Ok(header) =>
          assert_true(
            header.contains("int32_t moonbridge_add(int32_t lhs, int32_t rhs);"),
          )
        Err(error) => fail(error)
      }
    }
    Err(error) => fail(error)
  }
}

///|
test "C parameter names replace keywords and avoid collisions" {
  assert_eq(@moonbridge.parameter_c_names(["lhs", "rhs"]), ["lhs", "rhs"])
  assert_eq(@moonbridge.parameter_c_names(["class", "arg1"]), ["arg0", "arg1"])
  assert_eq(@moonbridge.parameter_c_names(["arg1", "class"]), [
    "arg1", "moonbridge_arg1_1",
  ])
  assert_eq(@moonbridge.parameter_c_names(["_reserved", "normal"]), [
    "arg0", "normal",
  ])
}

///|
test "scanner rejects malformed names and unsupported declaration forms" {
  let malformed_name =
    #|#export_name(unquoted)
    #|pub fn one() -> Int32 { 1 }
  assert_true(
    @moonbridge.scan_exports("bad-name.mbt", malformed_name) is Err(_),
  )

  let non_identifier =
    #|#export_name("moonbridge-hyphen")
    #|pub fn one() -> Int32 { 1 }
  assert_true(
    @moonbridge.scan_exports("bad-symbol.mbt", non_identifier) is Err(_),
  )

  let private_function =
    #|#export_name("moonbridge_private")
    #|fn one() -> Int32 { 1 }
  assert_true(
    @moonbridge.scan_exports("private.mbt", private_function) is Err(_),
  )

  let generic_function =
    #|#export_name("moonbridge_generic")
    #|pub fn identity[T](value : T) -> T { value }
  assert_true(
    @moonbridge.scan_exports("generic.mbt", generic_function) is Err(_),
  )

  let missing_result_type =
    #|#export_name("moonbridge_missing_type")
    #|pub fn one(value) -> Int32 { 1 }
  assert_true(
    @moonbridge.scan_exports("missing-type.mbt", missing_result_type) is Err(_),
  )
}

///|
test "source scanner tolerates unrelated declarations and preserves export order" {
  let source =
    #|pub fn helper() -> Int32 { 0 }
    #|
    #|#deprecated
    #|#export_name("moonbridge_first")
    #|pub fn first() -> Int32 { helper() }
    #|
    #|#export_name("moonbridge_second")
    #|pub fn second() -> Unit { () }
  match @moonbridge.scan_exports("ordered.mbt", source) {
    Ok(exports) => {
      assert_eq(exports.length(), 2)
      assert_eq(exports[0].c_name, "moonbridge_first")
      assert_eq(exports[0].source_line, 4)
      assert_eq(exports[1].c_name, "moonbridge_second")
      assert_eq(exports[1].source_line, 7)
    }
    Err(error) => fail(error)
  }
}

///|
test "diagnostic JSON handles optional source fields and all severity levels" {
  let warnings : Array[@moonbridge.Diagnostic] = [
    {
      code: "MB900",
      severity: @moonbridge.Warning,
      message: "a general note",
      source_path: None,
      source_line: None,
      help: Some("review the ABI documentation"),
    },
  ]
  let json = @moonbridge.render_diagnostics_json(warnings)
  assert_true(json.contains("warning"))
  assert_true(json.contains("MB900"))
  assert_true(json.contains("review the ABI documentation"))
  assert_true(!json.contains("source"))
  assert_true(!@moonbridge.has_errors(warnings))
}

///|
test "C and C++ reserved words are rejected as generated identifiers" {
  let reserved = [
    "auto", "bool", "break", "case", "catch", "char", "class", "concept", "const",
    "consteval", "constexpr", "continue", "decltype", "default", "delete", "double",
    "else", "enum", "explicit", "extern", "false", "float", "for", "friend", "goto",
    "if", "inline", "int", "long", "namespace", "new", "noexcept", "nullptr", "operator",
    "private", "protected", "public", "register", "requires", "return", "short",
    "signed", "sizeof", "static", "struct", "switch", "template", "this", "thread_local",
    "throw", "true", "try", "typedef", "typename", "union", "unsigned", "using",
    "virtual", "void", "volatile", "while",
  ]
  for word in reserved {
    assert_true(!@moonbridge.is_c_identifier(word))
  }
  assert_true(@moonbridge.is_c_identifier("moonbridge_value_2"))
  assert_true(!@moonbridge.is_c_identifier("moonbridge__value"))
  assert_true(!@moonbridge.is_c_identifier("moonbridge-value"))
  assert_true(!@moonbridge.is_c_identifier("2moonbridge"))
  assert_true(!@moonbridge.is_c_identifier("值"))
}

///|
test "all scalar mappings render named parameters and portable prototypes" {
  let source =
    #|#export_name("moonbridge_scalar_matrix")
    #|pub fn scalar_matrix(
    #|  truth : Bool,
    #|  signed32 : Int32,
    #|  unsigned32 : UInt32,
    #|  signed64 : Int64,
    #|  unsigned64 : UInt64,
    #|  single : Float,
    #|  double_value : Double,
    #|) -> Double { double_value }
  match @moonbridge.scan_exports("matrix.mbt", source) {
    Ok(exports) => {
      let header = match @moonbridge.render_header(exports, "SCALAR_MATRIX_H") {
        Ok(value) => value
        Err(error) => fail(error)
      }
      assert_true(header.contains("int32_t truth"))
      assert_true(header.contains("int32_t signed32"))
      assert_true(header.contains("uint32_t unsigned32"))
      assert_true(header.contains("int64_t signed64"))
      assert_true(header.contains("uint64_t unsigned64"))
      assert_true(header.contains("float single"))
      assert_true(header.contains("double double_value"))
      assert_true(
        header.contains(
          "double moonbridge_scalar_matrix(int32_t truth, int32_t signed32, uint32_t unsigned32, int64_t signed64, uint64_t unsigned64, float single, double double_value);",
        ),
      )
      let manifest = match @moonbridge.render_manifest(exports) {
        Ok(value) => value
        Err(error) => fail(error)
      }
      for
        c_type in [
          "int32_t", "uint32_t", "int64_t", "uint64_t", "float", "double",
        ] {
        assert_true(manifest.contains(c_type))
      }
      assert_true(manifest.contains("moonbit_name"))
      assert_true(manifest.contains("c_name"))
    }
    Err(error) => fail(error)
  }
}

///|
test "portable function arity limit blocks oversized output across renderers" {
  let parameters : Array[@moonbridge.AbiType] = []
  let names : Array[String] = []
  for i = 0; i < 128; i = i + 1 {
    parameters.push(@moonbridge.Int32)
    names.push("parameter_\\{i}")
  }
  let too_many : @moonbridge.Export = {
    source_path: "arity.mbt",
    source_line: 1,
    moonbit_name: "too_many",
    c_name: "moonbridge_too_many",
    parameters,
    parameter_names: names,
    result: @moonbridge.Unit,
  }
  let exports = [too_many]
  let diagnostics = @moonbridge.validate_exports(exports)
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].code, "MB002")
  assert_true(@moonbridge.render_header(exports, "ARITY_H") is Err(_))
  assert_true(@moonbridge.render_manifest(exports) is Err(_))
  assert_true(@moonbridge.render_report(exports) is Err(_))
}

///|
test "inconsistent public export models fail before indexing parameter names" {
  let malformed : @moonbridge.Export = {
    source_path: "malformed.mbt",
    source_line: 9,
    moonbit_name: "broken",
    c_name: "moonbridge_broken",
    parameters: [@moonbridge.Int32, @moonbridge.UInt32],
    parameter_names: ["only_one_name"],
    result: @moonbridge.Int32,
  }
  let exports = [malformed]
  let diagnostics = @moonbridge.validate_exports(exports)
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].code, "MB004")
  assert_true(@moonbridge.render_header(exports, "BROKEN_H") is Err(_))
  assert_true(@moonbridge.render_manifest(exports) is Err(_))
  assert_true(@moonbridge.render_report(exports) is Err(_))
}

///|
test "scanner keeps comment markers inside quoted export names for validation" {
  let source =
    #|#export_name("moonbridge//not-a-c-name")
    #|pub fn not_a_name() -> Int32 { 0 }
  match @moonbridge.scan_exports("quoted-comment.mbt", source) {
    Err(error) =>
      assert_eq(
        error, "quoted-comment.mbt:1: invalid C symbol name: moonbridge//not-a-c-name",
      )
    Ok(_) => fail("invalid C symbol name should be rejected")
  }
}

///|
test "ABI comparison classifies additions, removals, and changed C signatures" {
  let previous_source =
    #|#export_name("moonbridge_keep")
    #|pub fn keep(previous_count : Int32) -> Int32 { previous_count }
    #|
    #|#export_name("moonbridge_removed")
    #|pub fn removed() -> Unit { () }
    #|
    #|#export_name("moonbridge_changed")
    #|pub fn changed(value : Int32) -> Int32 { value }
  let current_source =
    #|#export_name("moonbridge_keep")
    #|pub fn keep_renamed(current_count : Int32) -> Int32 { current_count }
    #|
    #|#export_name("moonbridge_added")
    #|pub fn added() -> Unit { () }
    #|
    #|#export_name("moonbridge_changed")
    #|pub fn changed(value : Int64) -> Int64 { value }
  let previous = match
    @moonbridge.scan_exports("previous.mbt", previous_source) {
    Ok(exports) => exports
    Err(error) => fail(error)
  }
  let current = match @moonbridge.scan_exports("current.mbt", current_source) {
    Ok(exports) => exports
    Err(error) => fail(error)
  }
  match @moonbridge.compare_export_sets(previous, current) {
    Ok(comparison) => {
      assert_eq(comparison.added_count, 1)
      assert_eq(comparison.removed_count, 1)
      assert_eq(comparison.changed_count, 1)
      assert_true(comparison.has_breaking_changes())
      assert_true(comparison.changes[0].kind is @moonbridge.Added)
      assert_true(comparison.changes[1].kind is @moonbridge.SignatureChanged)
      assert_true(comparison.changes[2].kind is @moonbridge.Removed)
      let text = @moonbridge.render_comparison_text(comparison)
      assert_true(text.contains("ABI comparison: breaking changes"))
      assert_true(text.contains("+ moonbridge_added"))
      assert_true(text.contains("~ moonbridge_changed"))
      assert_true(text.contains("- moonbridge_removed"))
      assert_true(text.contains("current.mbt:"))
      let json = @moonbridge.render_comparison_json(comparison)
      assert_true(json.contains("\"breaking\":true"))
      assert_true(json.contains("\"kind\":\"signature_changed\""))
      assert_true(
        json.contains("\"old_signature\":\"changed(Int32) -> Int32\""),
      )
    }
    Err(error) => fail(error)
  }
}

///|
test "ABI comparison allows additions and ignores source parameter renames" {
  let previous_source =
    #|#export_name("moonbridge_stable")
    #|pub fn stable(old_name : UInt32) -> UInt32 { old_name }
  let current_source =
    #|#export_name("moonbridge_stable")
    #|pub fn renamed_function(new_name : UInt32) -> UInt32 { new_name }
    #|
    #|#export_name("moonbridge_extension")
    #|pub fn extension() -> Int32 { 1 }
  let previous = match @moonbridge.scan_exports("v1.mbt", previous_source) {
    Ok(exports) => exports
    Err(error) => fail(error)
  }
  let current = match @moonbridge.scan_exports("v2.mbt", current_source) {
    Ok(exports) => exports
    Err(error) => fail(error)
  }
  match @moonbridge.compare_export_sets(previous, current) {
    Ok(comparison) => {
      assert_eq(comparison.added_count, 1)
      assert_eq(comparison.removed_count, 0)
      assert_eq(comparison.changed_count, 0)
      assert_true(!comparison.has_breaking_changes())
      assert_true(
        @moonbridge.render_comparison_text(comparison).contains("compatible"),
      )
    }
    Err(error) => fail(error)
  }
}

///|
test "ABI report summarizes type use and prints C prototypes" {
  let source =
    #|#export_name("moonbridge_mix")
    #|pub fn mix(flag : Bool, count : Int32) -> UInt64 { 0UL }
    #|
    #|#export_name("moonbridge_reset")
    #|pub fn reset() -> Unit { () }
  match @moonbridge.scan_exports("report.mbt", source) {
    Ok(exports) => {
      assert_eq(exports.length(), 2)
      assert_eq(
        @moonbridge.render_c_prototype(exports[0]),
        "uint64_t moonbridge_mix(int32_t flag, int32_t count)",
      )
      let report = match @moonbridge.render_report(exports) {
        Ok(value) => value
        Err(error) => fail(error)
      }
      assert_true(report.contains("Contract: moonbit-c-scalar-v1"))
      assert_true(report.contains("Exports: 2"))
      assert_true(report.contains("Scalar parameters: 2"))
      assert_true(report.contains("Bool -> int32_t; parameters=1, results=0"))
      assert_true(report.contains("Unit -> void; parameters=0, results=1"))
      assert_true(report.contains("report.mbt:1"))
      assert_true(
        report.contains("moonbridge_mix(int32_t flag, int32_t count)"),
      )
      assert_true(
        report.contains("Managed MoonBit values remain inside the module"),
      )
    }
    Err(error) => fail(error)
  }
}

///|
test "diagnostic JSON preserves locations and machine-readable codes" {
  let diagnostics : Array[@moonbridge.Diagnostic] = [
    @moonbridge.parse_diagnostic("src/api.mbt", 12, "bad \"signature\""),
  ]
  let json = @moonbridge.render_diagnostics_json(diagnostics)
  assert_true(json.contains("MB100"))
  assert_true(json.contains("src/api.mbt"))
  assert_true(json.contains("\\\"signature\\\""))
}
