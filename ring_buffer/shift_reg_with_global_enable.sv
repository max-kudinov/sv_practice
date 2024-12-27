module shift_reg_with_global_enable #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
) (
    input  logic             clk_i,
    input  logic             enable_i,
    input  logic [WIDTH-1:0] data_i,
    output logic [WIDTH-1:0] data_o
);

    logic [DEPTH-1:0][WIDTH-1:0] mem;

    always_ff @(posedge clk_i) begin
        if (enable_i) begin
            mem <= { mem[DEPTH-2:0], data_i };
        end
    end

    assign data_o = mem[DEPTH-1];

endmodule
