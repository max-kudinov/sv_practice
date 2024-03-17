`timescale 1ns/100ps

module fifo_tb();
    localparam CLK_PERIOD = 10;
    localparam W_FIFO     = 8;
    localparam D_FIFO     = 8;
    localparam DELAY_MIN  = 0;
    localparam DELAY_MAX  = 100;
    localparam CHECKS     = 1000;

    logic clk, rst;

    logic [W_FIFO - 1:0] up_data;
    logic [W_FIFO - 1:0] down_data;
    logic                up_valid;
    logic                down_ready;

    // Using queues because iverilog doesn't support mailboxes
    logic [W_FIFO - 1:0] model_fifo [$];
    logic [W_FIFO - 1:0] dut_fifo   [$];

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
        dump();
        reset();
        init();

        fork
            drive_in (DELAY_MIN, DELAY_MAX);
            drive_out(DELAY_MIN, DELAY_MAX);
            monitor();
            scoreboard();
        join
    end

    task init();
        down_ready <= 0;
        up_valid   <= 0;

        dut_fifo    = {};
        model_fifo  = {};
    endtask

    task drive_in(int delay_min, int delay_max);
        int delay;
        forever begin
            delay = $urandom_range(delay_min, delay_max);
            repeat (delay) @(posedge clk);

            up_valid <= 1;
            up_data  <= $urandom();
            @(posedge clk);
            up_valid <= 0;
        end
    endtask

    task drive_out(int delay_min, int delay_max);
        int delay;
        forever begin
            delay = $urandom_range(delay_min, delay_max);
            repeat (delay) @(posedge clk);

            down_ready <= 1;
            @(posedge clk);
            down_ready <= 0;
        end
    endtask

    task monitor();
        int model_size = 0;

        forever begin
            @(posedge clk);
            if (up_valid & model_size < 2 ** D_FIFO) begin
                model_fifo.push_back(up_data);
                model_size++;
            end

            if (down_ready & model_size > 0) begin
                dut_fifo.push_back(down_data);
                model_size--;
            end
        end
    endtask

    task scoreboard();
        logic [W_FIFO - 1:0] fifo_in, fifo_out;
        repeat(CHECKS) begin

            do begin
                @(posedge clk);
            end
            while (model_fifo.size() == 0);

            fifo_in = model_fifo[0];
            model_fifo.delete(0);

            do begin
                @(posedge clk);
            end
            while (dut_fifo.size() == 0);

            fifo_out = dut_fifo[0];
            dut_fifo.delete(0);

            if (fifo_in !== fifo_out) begin
                $display("Error at time %t, in: %d, out: %d",
                          $time, fifo_in, fifo_out);
                $finish();
            end
        end
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
