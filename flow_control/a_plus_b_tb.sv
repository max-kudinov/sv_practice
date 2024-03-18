`timescale 1ns/100ps

module a_plus_b_tb ();
    localparam CLK_PERIOD     = 10;
    localparam W_FIFO         = 8;
    localparam D_FIFO         = 8;
    localparam PUSH_DELAY_MIN = 0;
    localparam PUSH_DELAY_MAX = 20;
    localparam POP_DELAY_MIN  = 0;
    localparam POP_DELAY_MAX  = 10;
    localparam CHECKS         = 1000;

    logic                clk;
    logic                rst;

    logic [W_FIFO - 1:0] up_data_a;
    logic                up_valid_a;
    logic                up_ready_a;

    logic [W_FIFO - 1:0] up_data_b;
    logic                up_valid_b;
    logic                up_ready_b;

    logic [W_FIFO    :0] down_data_sum;
    logic                down_ready_sum;
    logic                down_valid_sum;

    logic [W_FIFO - 1:0] fifo_a   [$];
    logic [W_FIFO - 1:0] fifo_b   [$];

    logic [W_FIFO    :0] fifo_sum [$];

    a_plus_b_fifo
    # (
        .W_FIFO ( W_FIFO ),
        .D_FIFO (D_FIFO  )
    )
    i_a_plus_b_fifo
    (
        .clk            ( clk            ),
        .rst            ( rst            ),
        .up_data_a      ( up_data_a      ),
        .up_valid_a     ( up_valid_a     ),
        .up_ready_a     ( up_ready_a     ),
        .up_data_b      ( up_data_b      ),
        .up_valid_b     ( up_valid_b     ),
        .up_ready_b     ( up_ready_b     ),
        .down_ready_sum ( down_ready_sum ),
        .down_valid_sum ( down_valid_sum ),
        .down_data_sum  ( down_data_sum  )
    );

    initial begin
        clk = 0;
        forever begin
            #(CLK_PERIOD/2)  clk = ~clk;
        end
    end

    initial begin
        dump  ();
        reset ();
        init  ();

        fork
            drive_a    (PUSH_DELAY_MIN, PUSH_DELAY_MAX);
            drive_b    (PUSH_DELAY_MIN, PUSH_DELAY_MAX);
            drive_sum  (POP_DELAY_MIN,  POP_DELAY_MAX);
            monitor    ();
            scoreboard ();
        join
    end

    task drive_a(int delay_min, int delay_max);
        int delay;

        forever begin
            delay = $urandom_range(delay_min, delay_max);
            repeat(delay) @(posedge clk);

            up_valid_a <= 1;
            up_data_a  <= $urandom();

            do begin
                @(posedge clk);
            end
            while (~up_ready_a);

            up_valid_a <= 0;
        end
    endtask

    task drive_b(int delay_min, int delay_max);
        int delay;

        forever begin
            delay = $urandom_range(delay_min, delay_max);
            repeat(delay) @(posedge clk);

            up_valid_b <= 1;
            up_data_b  <= $urandom();

            do begin
                @(posedge clk);
            end
            while (~up_ready_b);

            up_valid_b <= 0;
        end
    endtask

    task drive_sum(int delay_min, int delay_max);
        int delay;

        forever begin
            delay = $urandom_range(delay_min, delay_max);
            repeat (delay) @(posedge clk);

            down_ready_sum <= 1;

            do begin
                @(posedge clk);
            end
            while (~down_valid_sum);

            down_ready_sum <= 0;
        end
    endtask

    task monitor();
        forever begin
            @(posedge clk);

            if (up_valid_a & up_ready_a) begin
                fifo_a.push_back(up_data_a);
            end

            if (up_valid_b & up_ready_b) begin
                fifo_b.push_back(up_data_b);
            end

            if (down_ready_sum & down_valid_sum) begin
                fifo_sum.push_back(down_data_sum);
            end
        end
    endtask

    task scoreboard();
        logic [W_FIFO - 1:0] a, b;
        logic [W_FIFO    :0] sum;

        repeat (CHECKS) begin

            // We mimick mailbox get() with this
            do begin
                @(posedge clk);
            end
            while (fifo_a.size() == 0);

            a = fifo_a[0];
            fifo_a.delete(0);

            do begin
                @(posedge clk);
            end
            while (fifo_b.size() == 0);

            b = fifo_b[0];
            fifo_b.delete(0);

            do begin
                @(posedge clk);
            end
            while (fifo_sum.size() == 0);

            sum = fifo_sum[0];
            fifo_sum.delete(0);

            assert (a + b === sum) else begin
                $error("Error: time %t a: %d, b: %d, output sum: %d",
                      $time, a, b, sum);
                $finish();
            end
        end
        $display("-----------------------------------");
        $display("All checks completed with no errors");
        $display("-----------------------------------");
        $finish();
    endtask

    task init();
        up_valid_a <= 0;
        up_valid_b <= 0;

        fifo_a   = {};
        fifo_b   = {};
        fifo_sum = {};
    endtask

    task reset();
        rst = 1;
        #CLK_PERIOD;
        rst = 0;
    endtask

    task dump();
        $dumpfile("a_plus_b.vcd");
        $dumpvars;
    endtask

endmodule
