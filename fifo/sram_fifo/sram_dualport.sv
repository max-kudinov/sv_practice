module sram_dualport #(
    parameter WIDTH  = 8,
    parameter DEPTH  = 8,
    parameter ADDR_W = $clog2(DEPTH)
) (
    input  wire              clk_i,
    input  wire              wen_i,
    input  wire              ren_i,
    input  wire [ADDR_W-1:0] waddr_i,
    input  wire [ADDR_W-1:0] raddr_i,
    input  wire [WIDTH-1:0]  wdata_i,
    output reg  [WIDTH-1:0]  rdata_o
);

    reg [WIDTH-1:0] ram [DEPTH-1:0];

    always @(posedge clk_i) begin
        if (wen_i) begin
            ram[waddr_i] <= wdata_i;
        end
    end

    always @(posedge clk_i) begin
        if (ren_i) begin
            rdata_o <= ram[raddr_i];
        end
    end

endmodule
