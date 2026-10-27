#include "moonbridge.h"

int main(void) {
  if (moonbridge_add_i32(20, 22) != 42) {
    return 1;
  }
  if (moonbridge_add_i32_via_array(20, 22) != 42) {
    return 2;
  }
  if (moonbridge_echo_bool(1) != 1 || moonbridge_echo_bool(0) != 0) {
    return 3;
  }
  if (moonbridge_echo_u32(UINT32_C(42)) != UINT32_C(42)) {
    return 4;
  }
  if (moonbridge_echo_i64(INT64_C(42)) != INT64_C(42)) {
    return 5;
  }
  if (moonbridge_echo_u64(UINT64_C(42)) != UINT64_C(42)) {
    return 6;
  }
  if (moonbridge_echo_float(3.5f) != 3.5f) {
    return 7;
  }
  if (moonbridge_echo_double(3.5) != 3.5) {
    return 8;
  }
  moonbridge_reset();
  return 0;
}
