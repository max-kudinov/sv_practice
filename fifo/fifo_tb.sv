`timescale 1ns/100ps

module fifo_tb();
    localparam CLK_PERIOD = 10;
    localparam WIDTH      = 8;
    localparam DEPTH      = 8;
    localparam DELAY_MIN  = 0;
    localparam DELAY_MAX  = 10;

    logic clk, rst;

    logic [WIDTH - 1:0] up_data;
    logic [WIDTH - 1:0] down_data;
    logic               up_valid;
    logic               down_ready;
    logic               push;
    logic               pop;

    logic [WIDTH - 1:0] queue [$:DEPTH];

    logic [WIDTH - 1:0] in_q  [$];
    logic [WIDTH - 1:0] out_q [$];

    fifo
    # (
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
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

        forever begin
            @(posedge clk);

            push = up_valid & queue.size() < DEPTH;
            pop  = down_ready & queue.size() != 0;

            if (push) in_q.push_back(up_data);
            if (pop)  out_q.push_back(down_data);

            if (rst)
                queue = {};
            else if (push)
                queue.push_back(up_data);
            else if (pop)
                queue.delete(0);
        end
    end

    initial begin
        wait(~rst);

        fork
            drive_in ($urandom_range(DELAY_MIN, DELAY_MAX));
            drive_out($urandom_range(DELAY_MIN, DELAY_MAX));
            scoreboard();
        join
    end

    task init();
        in_q  = {};
        out_q = {};

        down_ready <= 0;
        up_valid   <= 0;
    endtask

    task drive_in(int delay = 0);
        forever begin
            repeat (delay) @(posedge clk);
            up_valid <= 1;
            up_data  <= $urandom();

            @(posedge clk);
            up_valid <= 0;
        end
    endtask

    task drive_out(int delay = 0);
        forever begin
            repeat (delay) @(posedge clk);
            down_ready <= 1;
            @(posedge clk);

            down_ready <= 0;
        end
    endtask

    task scoreboard();
        repeat(10) begin
            int fifo_in, fifo_out;

            do begin
                @(posedge clk);
            end
            while (in_q.size() == 0);

            fifo_in = in_q[0];
            in_q.delete(0);

            do begin
                @(posedge clk);
            end
            while (out_q.size() == 0);

            fifo_out = out_q[0];
            out_q.delete(0);

            if (fifo_in !== fifo_out) begin
                $display("Error at time %t, in: %d, out: %d", $time, fifo_in, fifo_out);
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
