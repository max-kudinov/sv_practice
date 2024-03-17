module fifo
# (
    parameter W_FIFO = 8,
    parameter D_FIFO = 8
)
(
    input                 clk,
    input                 rst,
    input  [W_FIFO - 1:0] up_data,
    input                 up_valid,
    input                 down_ready,
    output [W_FIFO - 1:0] down_data
);

    localparam W_PTR = D_FIFO + 1;

    logic [W_FIFO - 1:0] data [2 ** D_FIFO - 1:0];
    logic [W_PTR  - 1:0] rd_ptr;
    logic [W_PTR  - 1:0] wr_ptr;
    logic                full;
    logic                empty;
    logic                push;
    logic                pop;

    assign full = (rd_ptr[W_PTR - 2:0] == wr_ptr[W_PTR - 2:0]) &
                  (rd_ptr[W_PTR - 1]   != wr_ptr[W_PTR - 1]);

    assign empty = rd_ptr[W_PTR - 1:0] == wr_ptr[W_PTR - 1:0];

    assign push = up_valid   & ~full;
    assign pop  = down_ready & ~empty;

    assign down_data = data[rd_ptr[W_PTR - 2:0]];

    always_ff @(posedge clk)
        if (rst) begin
            rd_ptr <= '0;
            wr_ptr <= '0;
        end
        else begin
            if (push) begin
                assert(~full) else $error("Fifo overflow at %t", $time);
                wr_ptr     <= wr_ptr + 1'b1;
                data[wr_ptr[W_PTR - 2:0]] <= up_data;
            end
            if (pop) begin
                assert(~empty) else $error("Fifo underflow at %t", $time);
                rd_ptr     <= rd_ptr + 1'b1;
            end
        end

endmodule
