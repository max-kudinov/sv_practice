`default_nettype none

module fp_add (
    input  var logic [31:0] num_1_i,
    input  var logic [31:0] num_2_i,
    output var logic [31:0] sum_o
);

localparam int unsigned W_MANT     = 23;
localparam int unsigned W_MANT_EXT = W_MANT + 1;
localparam int unsigned W_EXP      = 8;
localparam int unsigned W_MANT_IDX = $clog2(W_MANT_EXT + 1);

logic                  sign_1;
logic                  sign_2;

logic [W_EXP-1:0]      exponent_1;
logic [W_EXP-1:0]      exponent_2;

logic [W_MANT-1:0]     mantissa_1;
logic [W_MANT-1:0]     mantissa_2;

logic [W_MANT_EXT-1:0] mantissa_ext_1;
logic [W_MANT_EXT-1:0] mantissa_ext_2;

logic [W_MANT_EXT-1:0] mantissa_aligned_1;
logic [W_MANT_EXT-1:0] mantissa_aligned_2;

logic [W_MANT_EXT-1:0] add_result;
logic [W_MANT-1:0]     mantissa_normalized;

logic [W_EXP-1:0]      exponent_diff;
logic                  shift_align_num;

logic                  res_sign;
logic [W_EXP-1:0]      res_exponent;
logic                  overflow;

logic [W_MANT_EXT-1:0] pri_onehot;
logic                  prev_ones;
logic [W_MANT_EXT-1:0] conv_table [W_MANT_IDX];
logic [W_MANT_IDX-1:0] normalize_shamt;

always_comb begin
    // Decode
    { sign_1, exponent_1, mantissa_1 } = num_1_i;
    { sign_2, exponent_2, mantissa_2 } = num_2_i;

    // Prepend leading 1 if the number is not 0
    if (exponent_1 != '0)
        mantissa_ext_1 = { 1'b1, mantissa_1 };
    else
        mantissa_ext_1 = { 1'b0, mantissa_1 };

    if (exponent_2 != '0)
        mantissa_ext_2 = { 1'b1, mantissa_2 };
    else
        mantissa_ext_2 = { 1'b0, mantissa_2 };

    // Compare exponents
    if (exponent_1 > exponent_2) begin
        exponent_diff   = exponent_1 - exponent_2;
        shift_align_num = '0;
    end else begin
        exponent_diff   = exponent_2 - exponent_1;
        shift_align_num = '1;
    end

    // Shift smaller mantissa
    if (shift_align_num) begin
        mantissa_aligned_1 = mantissa_ext_1 >> exponent_diff;
        mantissa_aligned_2 = mantissa_ext_2;
    end else begin
        mantissa_aligned_1 = mantissa_ext_1;
        mantissa_aligned_2 = mantissa_ext_2 >> exponent_diff;
    end

    // Figure out the sign
    if (sign_1 != sign_2) begin
        overflow = '0;

        // Subtract negative from positive
        if (sign_1)
            { res_sign, add_result } = mantissa_aligned_2 - mantissa_aligned_1;
        else
            { res_sign, add_result } = mantissa_aligned_1 - mantissa_aligned_2;

        // If the result is negative, take an absolute value
        if (res_sign)
            add_result = -add_result;

    end else begin

        { overflow, add_result } = mantissa_aligned_1 + mantissa_aligned_2;
        res_sign = sign_1;

    end

    for (int i = W_MANT_EXT-1; i >= 0; i--) begin
        prev_ones = '0;

        for (int j = W_MANT_EXT-1; j > i; j--)
            prev_ones |= add_result[j];

        pri_onehot[i] = add_result[i] && !prev_ones;
    end

    for (int unsigned i = 0; i < W_MANT_EXT; i++)
        for (int unsigned j = 0; j < W_MANT_IDX; j++)
            conv_table[j][W_MANT_EXT-1-i] = logic'((i >> j));

    for (int unsigned i = 0; i < W_MANT_EXT; i++)
            normalize_shamt[i] = |(conv_table[i] & pri_onehot);

    // Adjust exponent
    if (overflow) begin

        if (shift_align_num)
            res_exponent = exponent_2 + 1'b1;
        else
            res_exponent = exponent_1 + 1'b1;

        mantissa_normalized = W_MANT'(add_result >> 1);

    end else begin

        if (shift_align_num)
            res_exponent = exponent_2 - 8'(normalize_shamt);
        else
            res_exponent = exponent_1 - 8'(normalize_shamt);

        mantissa_normalized = W_MANT'(add_result << normalize_shamt);

    end

    sum_o = { res_sign, res_exponent, mantissa_normalized };

end

endmodule

`resetall
