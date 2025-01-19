module sram_dualport #(
    parameter WIDTH  = 8,
    parameter DEPTH  = 8,
    parameter ADDR_W = $clog2(DEPTH)
) (
    input  logic              clk_i,
    input  logic              wen_i,
    input  logic              ren_i,
    input  logic [ADDR_W-1:0] waddr_i,
    input  logic [ADDR_W-1:0] raddr_i,
    input  logic [WIDTH-1:0]  wdata_i,
    output logic [WIDTH-1:0]  rdata_o
);

    logic [WIDTH-1:0] ram [DEPTH-1:0];

    always_ff @(posedge clk_i) begin
        if (wen_i) begin
            ram[waddr_i] <= wdata_i;
        end
    end

    always_ff @(posedge clk_i) begin
        if (ren_i) begin
            rdata_o <= ram[raddr_i];
        end
    end

endmodule
