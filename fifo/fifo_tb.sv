`timescale 1ns/100ps

module fifo_tb();
    localparam CLK_PERIOD     = 10;
    localparam W_FIFO         = 8;
    localparam D_FIFO         = 8;
    localparam PUSH_DELAY_MIN = 0;
    localparam PUSH_DELAY_MAX = 10;
    localparam POP_DELAY_MIN  = 0;
    localparam POP_DELAY_MAX  = 10;
    localparam CHECKS         = 1000;

    logic                clk;
    logic                rst;
    logic [W_FIFO - 1:0] up_data;
    logic [W_FIFO - 1:0] down_data;
    logic                up_valid;
    logic                up_ready;
    logic                down_valid;
    logic                down_ready;

    // Using queues because iverilog doesn't support mailboxes
    logic [W_FIFO - 1:0] fifo_in  [$];
    logic [W_FIFO - 1:0] fifo_out [$];

    fifo
    # (
        .W_FIFO ( W_FIFO ),
        .D_FIFO ( D_FIFO )
    )
    DUT
    (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .up_data    ( up_data    ),
        .up_valid   ( up_valid   ),
        .up_ready   ( up_ready   ),
        .down_valid ( down_valid ),
        .down_ready ( down_ready ),
        .down_data  ( down_data  )
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
            drive_in   (PUSH_DELAY_MIN, PUSH_DELAY_MAX);
            drive_out  (POP_DELAY_MIN, POP_DELAY_MAX);
            monitor    ();
            scoreboard ();
        join
    end

    task init();
        down_ready <= 0;
        up_valid   <= 0;

        fifo_in     = {};
        fifo_out    = {};
    endtask

    task drive_in(int delay_min, int delay_max);
        int delay;

        forever begin
            delay = $urandom_range(delay_min, delay_max);
            repeat (delay) @(posedge clk);

            up_valid <= 1;
            up_data  <= $urandom();

            do begin
                @(posedge clk);
            end
            while (~up_ready);

            up_valid <= 0;
        end
    endtask

    task drive_out(int delay_min, int delay_max);
        int delay;

        forever begin
            delay = $urandom_range(delay_min, delay_max);
            repeat (delay) @(posedge clk);

            down_ready <= 1;

            do begin
                @(posedge clk);
            end
            while (~down_valid);

            down_ready <= 0;
        end
    endtask

    task monitor();
        forever begin
            @(posedge clk);

            if (up_valid & up_ready)
                fifo_in.push_back(up_data);

            if (down_ready & down_valid)
                fifo_out.push_back(down_data);
        end
    endtask

    task scoreboard();
        logic [W_FIFO - 1:0] data_in;
        logic [W_FIFO - 1:0] data_out;

        repeat(CHECKS) begin
            do begin
                @(posedge clk);
            end
            while (fifo_in.size() == 0);

            data_in = fifo_in[0];
            fifo_in.delete(0);

            do begin
                @(posedge clk);
            end
            while (fifo_out.size() == 0);

            data_out = fifo_out[0];
            fifo_out.delete(0);

            if (data_in !== data_out) begin
                $error("Error at time %t, in: %d, out: %d",
                          $time, data_in, data_out);
                $finish();
            end
        end
        $display("-----------------------------------");
        $display("All checks completed with no errors");
        $display("-----------------------------------");
        $finish();
    endtask

    task reset();
        rst = 1;
        #CLK_PERIOD;
        rst = 0;
    endtask

    task dump();
        $dumpfile("fifo.vcd");
        $dumpvars;
    endtask
endmodule
