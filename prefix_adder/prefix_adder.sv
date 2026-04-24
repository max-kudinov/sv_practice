module prefix_adder #(
    parameter int unsigned WIDTH = 16
) (
    input  var logic [WIDTH-1:0] a,
    input  var logic [WIDTH-1:0] b,
    input  var logic             c_in,
    output var logic [WIDTH-1:0] sum,
    output var logic             c_out
);

typedef struct {
    logic prop;
    logic gen;
} pg_block_t;

pg_block_t pg_init    [WIDTH];
pg_block_t prefix_res [WIDTH];

assign pg_init[0].prop = '0;
assign pg_init[0].gen = c_in;

// P and G precomputation for each bit
for (genvar i = 1; i < WIDTH; i++) begin : init_pg_gen
    assign pg_init[i].prop = a[i-1] || b[i-1];
    assign pg_init[i].gen  = a[i-1] && b[i-1];
end

prefix_tree #(
    .pg_block_t (pg_block_t),
    .WIDTH      (WIDTH     )
) prefix_tree (
    .inputs  (pg_init   ),
    .outputs (prefix_res)
);

for (genvar i = 0; i < WIDTH; i++) begin : sum_gen
    assign sum[i] = a[i] ^ b[i] ^ prefix_res[i].gen;
end

assign c_out = (a[WIDTH-1] && b[WIDTH-1])              ||
               (a[WIDTH-1] && prefix_res[WIDTH-1].gen) ||
               (b[WIDTH-1] && prefix_res[WIDTH-1].gen);

endmodule
