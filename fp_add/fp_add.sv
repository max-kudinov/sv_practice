`default_nettype none

module fp_add (
    input  var logic [31:0] num_1_i,
    input  var logic [31:0] num_2_i,
    output var logic [31:0] sum_o
);

logic sign_1;
logic sign_2;

logic [7:0] exponent_1;
logic [7:0] exponent_2;

logic [22:0] mantissa_1;
logic [22:0] mantissa_2;

logic [23:0] mantissa_ext_1;
logic [23:0] mantissa_ext_2;

logic [23:0] mantissa_aligned_1;
logic [23:0] mantissa_aligned_2;

logic [23:0] add_result;
logic [22:0] mantissa_normalized;

logic [7:0]  exponent_diff;
logic        shift_align_num;

logic res_sign;
logic [7:0] res_exponent;
logic overflow;

logic [23:0] pri_onehot;
logic        prev_ones;
logic [23:0] conv_table [5];
logic [4:0]  normalize_shamt;

always_comb begin
    // Decode
    { sign_1, exponent_1, mantissa_1 } = num_1_i;
    { sign_2, exponent_2, mantissa_2 } = num_2_i;

    // Prepend leading 1
    mantissa_ext_1 = { 1'b1, mantissa_1 };
    mantissa_ext_2 = { 1'b1, mantissa_2 };

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
            add_result = mantissa_aligned_2 - mantissa_aligned_1;
        else
            add_result = mantissa_aligned_1 - mantissa_aligned_2;

        res_sign = add_result[23];

    end else begin

        { overflow, add_result } = mantissa_aligned_1 + mantissa_aligned_2;

        res_sign = sign_1;

    end

    for (int i = 23; i >= 0; i--) begin
        prev_ones = '0;

        for (int j = 23; j > i; j--)
            prev_ones |= add_result[j];

        pri_onehot[i] = add_result[i] && !prev_ones;
    end

    for (int unsigned i = 0; i < 32; i++)
        for (int unsigned j = 0; j < 5; j++)
            conv_table[j][31-i] = logic'((i >> j));

    for (int unsigned i = 0; i < 5; i++)
            normalize_shamt[i] = |(conv_table[i] & pri_onehot);

    // Adjust exponent
    if (overflow) begin

        if (shift_align_num)
            res_exponent = exponent_2 + 1'b1;
        else
            res_exponent = exponent_1 + 1'b1;

        mantissa_normalized = 23'(add_result);

    end else begin

        if (shift_align_num)
            res_exponent = exponent_2 - 8'(normalize_shamt);
        else
            res_exponent = exponent_1 - 8'(normalize_shamt);

        mantissa_normalized = 23'(add_result << normalize_shamt);

    end

    sum_o = { res_sign, res_exponent, mantissa_normalized };

end

endmodule

`resetall
