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
localparam int unsigned W_EXP      = 8;
localparam logic [7:0]  BIAS       = 127;

logic                  sign_a;
logic                  sign_b;
logic [W_EXP-1:0]      exponent_a;
logic [W_EXP-1:0]      exponent_b;
logic [W_EXP-1:0]      exponent_sum;
logic [W_EXP-1:0]      res_exponent;
logic                  exponent_overflow;
logic                  exponent_underflow;
logic [W_MANT-1:0]     mantissa_a;
logic [W_MANT-1:0]     mantissa_b;
logic [W_MANT_EXT-1:0] mantissa_ext_a;
logic [W_MANT_EXT-1:0] mantissa_ext_b;
logic [W_MANT_EXT-1:0] mantissa_ext_mult;
logic [W_MANT-1:0]     res_mantissa;

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

    mantissa_ext_mult = {
        (W_MANT_EXT * 2)'(mantissa_ext_a * mantissa_ext_b)
    }[W_MANT_EXT*2-1-:W_MANT_EXT];

    exponent_sum       = (exponent_a - BIAS) + exponent_b + 8'(mantissa_ext_mult[23]);
    exponent_overflow  =  exponent_a[7] &&  exponent_b[7] && !exponent_sum[7];
    exponent_underflow = !exponent_a[7] && !exponent_b[7] &&  exponent_sum[7];

    if (exponent_overflow) begin
        res_exponent = 8'b11111110;
        res_mantissa = '1;
    end else if (exponent_underflow) begin
        res_exponent = '0;
        res_mantissa = '0;
    end else begin
        res_exponent = exponent_sum;
        // TODO: probably would require normalization (and exponent adjust?)
        res_mantissa = mantissa_ext_mult[W_MANT-1:0];
    end

    num_o   = { 1'b0, res_exponent, res_mantissa };
    valid_o = valid_i;

end

endmodule

`resetall
