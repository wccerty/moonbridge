#ifndef MOONBRIDGE_SCALAR_EXPORTS_H
#define MOONBRIDGE_SCALAR_EXPORTS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int32_t moonbridge_add_i32(int32_t lhs, int32_t rhs);
int32_t moonbridge_add_i32_via_array(int32_t lhs, int32_t rhs);
int32_t moonbridge_echo_bool(int32_t value);
uint32_t moonbridge_echo_u32(uint32_t value);
int64_t moonbridge_echo_i64(int64_t value);
uint64_t moonbridge_echo_u64(uint64_t value);
float moonbridge_echo_float(float value);
double moonbridge_echo_double(double value);
void moonbridge_reset(void);

#ifdef __cplusplus
}
#endif

#endif /* MOONBRIDGE_SCALAR_EXPORTS_H */
