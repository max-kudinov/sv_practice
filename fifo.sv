module fifo
# (
    parameter WIDTH = 8,
    parameter DEPTH = 8
)
(
    input                clk,
    input                rst,
    input  [WIDTH - 1:0] up_data,
    input                up_valid,
    input                down_ready,
    output [WIDTH - 1:0] down_data
);
    localparam w_ptr = $clog2(DEPTH) + 1'b1;

    logic [WIDTH - 1:0] data [DEPTH - 1:0];
    logic [w_ptr:0]     rd_ptr;
    logic [w_ptr:0]     wr_ptr;
    logic               full;
    logic               empty;
    logic               push;
    logic               pop;

    assign full = (rd_ptr[w_ptr - 2:0] == wr_ptr[w_ptr - 2:0]) &
                  (rd_ptr[w_ptr - 1]   != wr_ptr[w_ptr - 1]);

    assign empty = rd_ptr[w_ptr - 1:0] == wr_ptr[w_ptr - 1:0];

    assign push = up_valid   & ~full;
    assign pop  = down_ready & ~empty;

    assign down_data = data[rd_ptr[w_ptr - 2:0]];

    always_ff @(posedge clk)
        if (rst) begin
            rd_ptr <= '0;
            wr_ptr <= '0;
        end
        else begin
            if (push) begin
                assert(~full) else $error("Fifo overflow at %t", $time);
                wr_ptr       <= wr_ptr + 1'b1;
                data[wr_ptr[w_ptr - 2:0]] <= up_data;
            end
            if (pop) begin
                assert(~empty) else $error("Fifo underflow at %t", $time);
                rd_ptr     <= rd_ptr + 1'b1;
            end
        end

endmodule
