#include "fenv.h"
#include "Vtb__Dpi.h"

#pragma STDC FENV_ACCESS ON

union float_bits_conv {
    float f_num;
    unsigned int i_num;
};

unsigned int float_add(unsigned int a, unsigned int b) {
    union float_bits_conv a_conv;
    union float_bits_conv b_conv;
    union float_bits_conv sum_conv;

    a_conv.i_num = a;
    b_conv.i_num = b;

    int original_rounding = fegetround();

    // Set IEEE 754 rounding mode towards zero
    fesetround(FE_TOWARDZERO);
    sum_conv.f_num = a_conv.f_num + b_conv.f_num;

    // Reset rounding mode
    fesetround(original_rounding);

    return sum_conv.i_num;
}

double bin_to_real(unsigned int int_num) {
    union float_bits_conv conv;

    conv.i_num = int_num;
    return (double) conv.f_num;
}
