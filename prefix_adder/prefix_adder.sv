module prefix_adder #(
    parameter int unsigned WIDTH = 16
) (
    input  var logic             clk,
    input  var logic             rst,
    input  var logic             valid_i,
    input  var logic [WIDTH-1:0] a,
    input  var logic [WIDTH-1:0] b,
    input  var logic             c_in,
    output var logic             valid_o,
    output var logic [WIDTH-1:0] sum,
    output var logic             c_out
);

localparam int unsigned N_ROWS = $clog2(WIDTH);

logic [N_ROWS-1:0] valids;
logic [WIDTH-1:0]  a_shreg [N_ROWS];
logic [WIDTH-1:0]  b_shreg [N_ROWS];
logic [WIDTH-1:0]  a_del;
logic [WIDTH-1:0]  b_del;

typedef struct packed {
    logic prop;
    logic gen;
} pg_block_t;

pg_block_t pg_init    [WIDTH];
pg_block_t prefix_res [WIDTH];

// Stage 0
assign pg_init[0].prop = '0;
assign pg_init[0].gen = c_in;

// P and G precomputation for each bit
for (genvar i = 1; i < WIDTH; i++) begin : init_pg_gen
    assign pg_init[i].prop = a[i-1] || b[i-1];
    assign pg_init[i].gen  = a[i-1] && b[i-1];
end

always_ff @(posedge clk) begin
    a_shreg[0] <= a;
    b_shreg[0] <= b;

    for (int unsigned i = 0; i < N_ROWS-1; i++) begin
        a_shreg[i+1] <= a_shreg[i];
        b_shreg[i+1] <= b_shreg[i];
    end
end

// Stages 1 - log2(N)
prefix_tree #(
    .pg_block_t (pg_block_t),
    .WIDTH      (WIDTH     ),
    .N_ROWS     (N_ROWS    )
) prefix_tree (
    .clk     (clk       ),
    .inputs  (pg_init   ),
    .outputs (prefix_res)
);

// Last stage
assign a_del = a_shreg[N_ROWS-1];
assign b_del = b_shreg[N_ROWS-1];

for (genvar i = 0; i < WIDTH; i++) begin : sum_gen
    assign sum[i] = a_del[i] ^ b_del[i] ^ prefix_res[i].gen;
end

assign c_out = (a_del[WIDTH-1] && b_del[WIDTH-1])          ||
               (a_del[WIDTH-1] && prefix_res[WIDTH-1].gen) ||
               (b_del[WIDTH-1] && prefix_res[WIDTH-1].gen);

always_ff @(posedge clk)
    if (rst)
        valids <= '0;
    else
        valids <= { valids[N_ROWS-2:0], valid_i };

assign valid_o = valids[N_ROWS-1];

endmodule
