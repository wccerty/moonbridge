///|
/// Adds two signed 32-bit values. The C symbol is intentionally explicit.
#export_name("moonbridge_add_i32")
pub fn add_i32(lhs : Int32, rhs : Int32) -> Int32 {
  lhs + rhs
}

///|
/// Adds two values after allocating a temporary MoonBit array. This checks
/// that scalar exports still work when the implementation uses the runtime.
#export_name("moonbridge_add_i32_via_array")
pub fn add_i32_via_array(lhs : Int32, rhs : Int32) -> Int32 {
  let values = Array::make(2, lhs)
  values[1] = rhs
  values[0] + values[1]
}

///|
/// Echoes scalar values so C consumers exercise the documented ABI mappings.
#export_name("moonbridge_echo_bool")
pub fn echo_bool(value : Bool) -> Bool {
  value
}

///|
#export_name("moonbridge_echo_u32")
pub fn echo_u32(value : UInt32) -> UInt32 {
  value
}

///|
#export_name("moonbridge_echo_i64")
pub fn echo_i64(value : Int64) -> Int64 {
  value
}

///|
#export_name("moonbridge_echo_u64")
pub fn echo_u64(value : UInt64) -> UInt64 {
  value
}

///|
#export_name("moonbridge_echo_float")
pub fn echo_float(value : Float) -> Float {
  value
}

///|
#export_name("moonbridge_echo_double")
pub fn echo_double(value : Double) -> Double {
  value
}

///|
#export_name("moonbridge_reset")
pub fn reset() -> Unit {
  ()
}
