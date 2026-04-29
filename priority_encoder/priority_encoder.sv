module priority_encoder #(
    parameter  int unsigned W_IN  = 8,
    localparam int unsigned W_OUT = $clog2(W_IN + 1)
) (
    input  var logic [W_IN-1:0]  data_in,
    output var logic [W_OUT-1:0] data_out
);

logic [W_IN-1:0] pri_onehot;
logic            prev_ones;
logic [W_IN-1:0] conv_table [W_OUT];

always_comb begin
    for (int unsigned i = 0; i < W_IN; i++) begin
        prev_ones = '0;

        for (int unsigned j = 0; j < i; j++)
            prev_ones |= data_in[j];

        pri_onehot[i] = data_in[i] && !prev_ones;
    end

    for (int unsigned i = 0; i < W_IN; i++)
        for (int unsigned j = 0; j < W_OUT; j++)
            conv_table[j][i] = logic'((int'(i+1) >> j));

    for (int unsigned i = 0; i < W_OUT; i++)
            data_out[i] = |(conv_table[i] & pri_onehot);

end

endmodule
