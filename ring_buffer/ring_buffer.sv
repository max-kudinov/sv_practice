module ring_buffer #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_i,
    input  logic             enable_i,
    input  logic [WIDTH-1:0] data_i,
    output logic [WIDTH-1:0] data_o
);

    localparam PTR_W = $clog2(DEPTH);
    // verilator lint_off WIDTHTRUNC
    localparam [PTR_W-1:0] MAX_PTR = DEPTH - 1;
    // verilator lint_on WIDTHTRUNC

    logic [WIDTH-1:0] mem [DEPTH];
    logic [PTR_W-1:0] ptr;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ptr <= '0;
        end else if (enable_i) begin
            if (ptr == MAX_PTR) begin
                ptr <= '0;
            end else begin
                ptr <= ptr + 1'b1;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (enable_i) begin
            mem[ptr] <= data_i;
        end
    end

    assign data_o = mem[ptr];

endmodule
