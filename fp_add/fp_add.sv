// Almost* compliant IEEE-754 adder.
// * rouding to 0 (truncation), +-inf as well as NaN are not supported, negative
// numbers are not handled properly in some cases

`default_nettype none

module fp_add (
    input  var logic        clk,
    input  var logic        rst,
    input  var logic        valid_i,
    input  var logic [31:0] num_a_i,
    input  var logic [31:0] num_b_i,
    output var logic [31:0] sum_o,
    output var logic        valid_o
);

localparam int unsigned W_MANT     = 23;
localparam int unsigned W_MANT_EXT = W_MANT + 1;
localparam int unsigned W_EXP      = 8;
localparam int unsigned W_MANT_IDX = $clog2(W_MANT_EXT + 1);

// Stage 0
logic                  sign_a;
logic                  sign_b;
logic [W_EXP-1:0]      exponent_a;
logic [W_EXP-1:0]      exponent_b;
logic [W_MANT-1:0]     mantissa_a;
logic [W_MANT-1:0]     mantissa_b;
logic [W_MANT_EXT-1:0] mantissa_ext_a;
logic [W_MANT_EXT-1:0] mantissa_ext_b;
logic [W_MANT_EXT-1:0] mantissa_aligned_a;
logic [W_MANT_EXT-1:0] mantissa_aligned_b;
logic [W_EXP-1:0]      exponent_diff;
logic                  shift_align_num;

// Stage 1
logic                  valid_p1;
logic                  sign_a_p1;
logic                  sign_b_p1;
logic                  overflow;
logic                  res_sign;
logic [W_MANT_EXT-1:0] add_result;
logic [W_EXP-1:0]      exponent_a_p1;
logic [W_EXP-1:0]      exponent_b_p1;
logic [W_MANT_EXT-1:0] mantissa_aligned_a_p1;
logic [W_MANT_EXT-1:0] mantissa_aligned_b_p1;
logic                  shift_align_num_p1;

// Stage 2
logic                  valid_p2;
logic [W_MANT_EXT-1:0] add_result_p2;
logic                  overflow_p2;
logic                  res_sign_p2;
logic [W_EXP-1:0]      exponent_a_p2;
logic [W_EXP-1:0]      exponent_b_p2;
logic                  shift_align_num_p2;
logic [W_MANT_EXT-1:0] pri_onehot;
logic                  prev_ones;
logic [W_MANT_EXT-1:0] conv_table [W_MANT_IDX];
logic [W_MANT_IDX-1:0] normalize_shamt;

// Stage 3
logic [W_MANT_EXT-1:0] add_result_p3;
logic                  overflow_p3;
logic                  res_sign_p3;
logic [W_EXP-1:0]      exponent_a_p3;
logic [W_EXP-1:0]      exponent_b_p3;
logic [W_EXP-1:0]      res_exponent;
logic [W_EXP-1:0]      higher_exponent;
logic [W_MANT-1:0]     mantissa_normalized;
logic                  shift_align_num_p3;
logic [W_MANT_IDX-1:0] normalize_shamt_p3;

// ============================================================================
// Stage 0
// ============================================================================

always_comb begin
    // Decode
    { sign_a, exponent_a, mantissa_a } = num_a_i;
    { sign_b, exponent_b, mantissa_b } = num_b_i;

    // Prepend leading 1 if the number is not 0
    if (exponent_a != '0)
        mantissa_ext_a = { 1'b1, mantissa_a };
    else
        mantissa_ext_a = { 1'b0, mantissa_a };

    if (exponent_b != '0)
        mantissa_ext_b = { 1'b1, mantissa_b };
    else
        mantissa_ext_b = { 1'b0, mantissa_b };

    // emin for subnormal numbers (IEEE 754-2019 3.4)
    if (exponent_a == '0)
        exponent_a = 8'd1;
    if (exponent_b == '0)
        exponent_b = 8'd1;

    // Compare exponents
    if (exponent_a > exponent_b) begin
        exponent_diff   = exponent_a - exponent_b;
        shift_align_num = '0;
    end else begin
        exponent_diff   = exponent_b - exponent_a;
        shift_align_num = '1;
    end

    // Shift smaller mantissa
    if (shift_align_num) begin
        mantissa_aligned_a = mantissa_ext_a >> exponent_diff;
        mantissa_aligned_b = mantissa_ext_b;
    end else begin
        mantissa_aligned_a = mantissa_ext_a;
        mantissa_aligned_b = mantissa_ext_b >> exponent_diff;
    end
end

// ============================================================================
// Stage 1
// ============================================================================

always_ff @(posedge clk) begin
    sign_a_p1             <= sign_a;
    sign_b_p1             <= sign_b;
    mantissa_aligned_a_p1 <= mantissa_aligned_a;
    mantissa_aligned_b_p1 <= mantissa_aligned_b;
    exponent_a_p1         <= exponent_a;
    exponent_b_p1         <= exponent_b;
    shift_align_num_p1    <= shift_align_num;
end

always_ff @(posedge clk)
    if (rst)
        valid_p1 <= '0;
    else
        valid_p1 <= valid_i;

always_comb begin

    // Figure out the sign
    if (sign_a_p1 != sign_b_p1) begin
        overflow = '0;

        // Subtract negative from positive
        if (sign_a_p1)
            { res_sign, add_result } = mantissa_aligned_b_p1 - mantissa_aligned_a_p1;
        else
            { res_sign, add_result } = mantissa_aligned_a_p1 - mantissa_aligned_b_p1;

        // If the result is negative, take an absolute value
        if (res_sign)
            add_result = -add_result;

    end else begin

        { overflow, add_result } = mantissa_aligned_a_p1 + mantissa_aligned_b_p1;
        res_sign = sign_a_p1;

    end

end

// ============================================================================
// Stage 2
// ============================================================================

always_ff @(posedge clk) begin
    add_result_p2      <= add_result;
    overflow_p2        <= overflow;
    res_sign_p2        <= res_sign;
    exponent_a_p2      <= exponent_a_p1;
    exponent_b_p2      <= exponent_b_p1;
    shift_align_num_p2 <= shift_align_num_p1;
end

always_ff @(posedge clk)
    if (rst)
        valid_p2 <= '0;
    else
        valid_p2 <= valid_p1;


always_comb begin

    for (int i = W_MANT_EXT-1; i >= 0; i--) begin
        prev_ones = '0;

        for (int j = W_MANT_EXT-1; j > i; j--)
            prev_ones |= add_result_p2[j];

        pri_onehot[i] = add_result_p2[i] && !prev_ones;
    end

    for (int unsigned i = 0; i < W_MANT_EXT; i++)
        for (int unsigned j = 0; j < W_MANT_IDX; j++)
            conv_table[j][W_MANT_EXT-1-i] = logic'((i >> j));

    for (int unsigned i = 0; i < W_MANT_EXT; i++)
            normalize_shamt[i] = |(conv_table[i] & pri_onehot);

end

// ============================================================================
// Stage 3
// ============================================================================

always_ff @(posedge clk) begin
    add_result_p3      <= add_result_p2;
    overflow_p3        <= overflow_p2;
    res_sign_p3        <= res_sign_p2;
    exponent_a_p3      <= exponent_a_p2;
    exponent_b_p3      <= exponent_b_p2;
    shift_align_num_p3 <= shift_align_num_p2;
    normalize_shamt_p3 <= normalize_shamt;
end

always_ff @(posedge clk)
    if (rst)
        valid_o <= '0;
    else
        valid_o <= valid_p2;

always_comb begin

    if (shift_align_num_p3)
        higher_exponent = exponent_b_p3;
    else
        higher_exponent = exponent_a_p3;

    // Adjust exponent
    if (overflow_p3) begin

        if (higher_exponent != 8'b11111110) begin
            res_exponent        = higher_exponent + 1'b1;
            mantissa_normalized = W_MANT'(add_result_p3 >> 1);
        end else begin
            // In round to zero mode, we set the result to format's largest
            // finite number
            res_exponent        = higher_exponent;
            mantissa_normalized = '1;
        end

    end else begin

        if (add_result_p3 == '0)
            res_exponent = '0;
        else
            res_exponent = higher_exponent - 8'(normalize_shamt_p3);

        mantissa_normalized = W_MANT'(add_result_p3 << normalize_shamt_p3);

    end

    sum_o = { res_sign_p3, res_exponent, mantissa_normalized };
end

endmodule

`resetall
