// Somewhat compliant IEEE-754 multiplier.
// Rounding to 0 (truncation), inf and NaN are not handled
// And yeah, subnormal input operands are not supported too

`default_nettype none

module fp_mult (
    input  var logic        clk,
    input  var logic        rst,
    input  var logic        valid_i,
    input  var logic [31:0] num_a_i,
    input  var logic [31:0] num_b_i,
    output var logic [31:0] num_o,
    output var logic        valid_o
);

localparam int unsigned W_MANT     = 23;
localparam int unsigned W_MANT_EXT = W_MANT + 1;
localparam int unsigned W_MULT     = W_MANT_EXT * 2;
localparam int unsigned W_MULT_IDX = $clog2(W_MULT);
localparam int unsigned W_EXP      = 8;
localparam logic [7:0]  BIAS       = 127;

logic                  sign_a;
logic                  sign_b;
logic                  res_sign;
logic [W_EXP-1:0]      exponent_a;
logic [W_EXP-1:0]      exponent_b;
logic [W_EXP-1:0]      exponent_sum;
logic [W_EXP-1:0]      bias_adjust_sum;
logic [W_EXP-1:0]      res_exponent;
logic [W_EXP-1:0]      raw_exponent_sum;
logic                  exponent_overflow;
logic                  exponent_underflow;
logic [W_MANT-1:0]     mantissa_a;
logic [W_MANT-1:0]     mantissa_b;
logic [W_MANT_EXT-1:0] mantissa_ext_a;
logic [W_MANT_EXT-1:0] mantissa_ext_b;
logic [W_MULT-1:0]     mult_res_full;
logic [W_MANT-1:0]     res_mantissa;

logic prev_ones;
logic [W_MULT-1:0] pri_onehot;
logic [W_MULT-1:0] conv_table [W_MULT_IDX];
logic [W_MULT_IDX-1:0] normalize_shamt;
logic [4:0] subnormal_shift;


always_comb begin

    { sign_a, exponent_a, mantissa_a } = num_a_i;
    { sign_b, exponent_b, mantissa_b } = num_b_i;

    if (exponent_a != '0)
        mantissa_ext_a = { 1'b1, mantissa_a };
    else
        mantissa_ext_a = { 1'b0, mantissa_a };

    if (exponent_b != '0)
        mantissa_ext_b = { 1'b1, mantissa_b };
    else
        mantissa_ext_b = { 1'b0, mantissa_b };

    mult_res_full = mantissa_ext_a * mantissa_ext_b;

    for (int i = W_MULT-1; i >= 0; i--) begin
        prev_ones = '0;

        for (int j = W_MULT-1; j > i; j--)
            prev_ones |= mult_res_full[j];

        pri_onehot[i] = mult_res_full[i] && !prev_ones;
    end

    for (int unsigned i = 0; i < W_MULT; i++)
        for (int unsigned j = 0; j < W_MULT_IDX; j++)
            conv_table[j][W_MULT-1-i] = logic'((i >> j));

    for (int unsigned i = 0; i < W_MULT; i++)
            normalize_shamt[i] = |(conv_table[i] & pri_onehot);

    raw_exponent_sum   = exponent_a + exponent_b;
    bias_adjust_sum    = raw_exponent_sum - BIAS;
    exponent_sum       = bias_adjust_sum + 8'(mult_res_full[47]);
    exponent_overflow  = (exponent_a[7] && exponent_b[7]) &&
                         (!exponent_sum[7] || exponent_sum == '1);
    exponent_underflow = (!exponent_a[7] && !exponent_b[7]) &&
                         (bias_adjust_sum[7] || exponent_sum == '0);
    subnormal_shift    = 5'(23'd127 - raw_exponent_sum);
    res_sign           = sign_a ^ sign_b;

    if (exponent_overflow) begin
        res_exponent = 8'b11111110;
        res_mantissa = '1;
    end else if (exponent_underflow) begin
        res_exponent = '0;

        if (raw_exponent_sum > 103)
            res_mantissa = 23'(mult_res_full[W_MULT-1-:W_MANT_EXT] >> subnormal_shift);
        else
            res_mantissa = '0;

    end else begin
        res_exponent = exponent_sum;
        res_mantissa = {mult_res_full << normalize_shamt}[W_MULT-2-:W_MANT];
    end

    num_o   = { res_sign, res_exponent, res_mantissa };
    valid_o = valid_i;

end

endmodule

`resetall
