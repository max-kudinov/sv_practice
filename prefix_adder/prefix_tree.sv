module prefix_tree #(
    parameter type pg_block_t,
    parameter int unsigned WIDTH
) (
    input  var pg_block_t inputs  [WIDTH],
    output var pg_block_t outputs [WIDTH]
);

generate if (WIDTH == 1) begin : input_connect_gen

    assign outputs = inputs;

end else begin : tree_gen

    localparam int unsigned LEFT_WIDTH  = WIDTH / 2;
    localparam int unsigned RIGHT_WIDTH = WIDTH - LEFT_WIDTH;

    pg_block_t left_inputs   [LEFT_WIDTH];
    pg_block_t left_outputs  [LEFT_WIDTH];
    pg_block_t left_prefixes [LEFT_WIDTH];
    pg_block_t right_inputs  [RIGHT_WIDTH];
    pg_block_t right_outputs [RIGHT_WIDTH];

    assign left_inputs = inputs[RIGHT_WIDTH:WIDTH-1];

    prefix_tree #(
        .pg_block_t (pg_block_t),
        .WIDTH      (LEFT_WIDTH)
    ) left_tree (
        .inputs  (left_inputs ),
        .outputs (left_outputs)
    );

    // Generate prefixes only for the left side of a tree
    for (genvar i = 0; i < LEFT_WIDTH; i++) begin : prefix_gen
        assign left_prefixes[i].prop = left_outputs[i].prop &&
                                       right_outputs[RIGHT_WIDTH-1].prop;

        assign left_prefixes[i].gen = (left_outputs[i].prop              &&
                                       right_outputs[RIGHT_WIDTH-1].gen) ||
                                       left_outputs[i].gen;
    end

    assign right_inputs = inputs[0:RIGHT_WIDTH-1];

    prefix_tree #(
        .pg_block_t (pg_block_t ),
        .WIDTH      (RIGHT_WIDTH)
    ) right_tree (
        .inputs  (right_inputs ),
        .outputs (right_outputs)
    );

    assign outputs[0:RIGHT_WIDTH-1]     = right_outputs;
    assign outputs[RIGHT_WIDTH:WIDTH-1] = left_prefixes;

end endgenerate

endmodule
