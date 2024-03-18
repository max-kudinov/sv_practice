module a_plus_b_fifo
# (
    parameter W_FIFO = 8,
    parameter D_FIFO = 8
)
(
    input                     clk,
    input                     rst,

    // First operand
    input [W_FIFO - 1:0]      up_data_a,
    input                     up_valid_a,
    output                    up_ready_a,

    // Second operand
    input [W_FIFO - 1:0]      up_data_b,
    input                     up_valid_b,
    output                    up_ready_b,

    input                     down_ready_sum,
    output                    down_valid_sum,
    output [W_SUM_FIFO - 1:0] down_data_sum
);

    localparam W_SUM_FIFO = W_FIFO + 1;

    // First operand
    logic [W_FIFO - 1:0]     down_data_a;
    logic                    down_ready_a;
    logic                    down_valid_a;

    // Second operand
    logic [W_FIFO - 1:0]     down_data_b;
    logic                    down_ready_b;
    logic                    down_valid_b;

    // Sum
    logic [W_SUM_FIFO - 1:0] up_data_sum;
    logic                    up_valid_sum;
    logic                    up_ready_sum;

    assign up_valid_sum = down_valid_a & down_valid_b;
    assign down_ready_a = up_ready_sum & up_valid_sum;
    assign down_ready_b = up_ready_sum & up_valid_sum;
    assign up_data_sum  = down_data_a + down_data_b;

    fifo
    # (
        .W_FIFO ( W_FIFO ),
        .D_FIFO ( D_FIFO )
    )
    ififo_a
    (
        .clk          ( clk          ),
        .rst          ( rst          ),
        .up_data      ( up_data_a    ),
        .up_valid     ( up_valid_a   ),
        .up_ready     ( up_ready_a   ),
        .down_valid   ( down_valid_a ),
        .down_ready   ( down_ready_a ),
        .down_data    ( down_data_a  )
    );

    fifo
    # (
        .W_FIFO ( W_FIFO ),
        .D_FIFO ( D_FIFO )
    )
    ififo_b
    (
        .clk          ( clk          ),
        .rst          ( rst          ),
        .up_data      ( up_data_b    ),
        .up_valid     ( up_valid_b   ),
        .up_ready     ( up_ready_b   ),
        .down_valid   ( down_valid_b ),
        .down_ready   ( down_ready_b ),
        .down_data    ( down_data_b  )
    );

    fifo
    # (
        .W_FIFO ( W_SUM_FIFO ),
        .D_FIFO ( D_FIFO     )
    )
    ififo_sum
    (
        .clk          ( clk            ),
        .rst          ( rst            ),
        .up_data      ( up_data_sum    ),
        .up_valid     ( up_valid_sum   ),
        .up_ready     ( up_ready_sum   ),
        .down_valid   ( down_valid_sum ),
        .down_ready   ( down_ready_sum ),
        .down_data    ( down_data_sum  )
    );

endmodule
