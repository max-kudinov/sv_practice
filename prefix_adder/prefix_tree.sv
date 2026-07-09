module prefix_tree #(
    parameter type pg_block_t,
    parameter int unsigned WIDTH,
    parameter int unsigned N_ROWS
) (
    input  var logic      clk,
    input  var pg_block_t inputs  [WIDTH],
    output var pg_block_t outputs [WIDTH]
);

generate if (WIDTH == 1) begin : input_connect_gen

    if (N_ROWS == 1) begin : register_align_gen

        // Additional register for prefix network alignment
        always_ff @(posedge clk)
            outputs <= inputs;

    end else begin : comb__gen

        assign outputs = inputs;

    end

end else begin : tree_gen

    localparam int unsigned RIGHT_WIDTH    = WIDTH / 2;
    localparam int unsigned LEFT_WIDTH     = WIDTH - RIGHT_WIDTH;
    localparam int unsigned REMAINING_ROWS = N_ROWS - 1;

    pg_block_t left_inputs   [LEFT_WIDTH];
    pg_block_t left_outputs  [LEFT_WIDTH];
    pg_block_t left_prefixes [LEFT_WIDTH];
    pg_block_t right_inputs  [RIGHT_WIDTH];
    pg_block_t right_outputs [RIGHT_WIDTH];

    assign left_inputs = inputs[RIGHT_WIDTH:WIDTH-1];

    prefix_tree #(
        .pg_block_t (pg_block_t    ),
        .WIDTH      (LEFT_WIDTH    ),
        .N_ROWS     (REMAINING_ROWS)
    ) left_leaf (
        .clk     (clk         ),
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
        .pg_block_t (pg_block_t    ),
        .WIDTH      (RIGHT_WIDTH   ),
        .N_ROWS     (REMAINING_ROWS)
    ) right_leaf (
        .clk     (clk          ),
        .inputs  (right_inputs ),
        .outputs (right_outputs)
    );

    // Register leaf outputs
    always_ff @(posedge clk) begin
        outputs[0:RIGHT_WIDTH-1]     <= right_outputs;
        outputs[RIGHT_WIDTH:WIDTH-1] <= left_prefixes;
    end

end endgenerate

endmodule
