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
            #|int32_t moonbridge_add_i32(int32_t arg0, int32_t arg1);
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
