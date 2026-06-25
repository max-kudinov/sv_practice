module tb;

bit clk;
logic rst;
logic valid_i;
logic valid_o;
logic [31:0] num_1;
logic [31:0] num_2;
logic [31:0] sum;
logic [63:0] input_q [$];

always #1 clk = !clk;

fp_add fp_add (
    .clk     (clk    ),
    .valid_i (valid_i),
    .num_a_i (num_1  ),
    .num_b_i (num_2  ),
    .sum_o   (sum    ),
    .valid_o (valid_o)
);

task driver;
    forever begin
        @(posedge clk);
        valid_i <= '0;

        do
            @(posedge clk);
        while (!$urandom_range(0, 1));

        valid_i <= '1;
        num_1   <= $urandom();
        num_2   <= $urandom();
    end
endtask

task monitor;
    forever begin
        @(posedge clk);

        if (valid_i)
            input_q.push_back({num_1, num_2});
    end
endtask

task scoreboard;
    logic [63:0] inputs;
    logic [31:0] a_bit;
    logic [31:0] b_bit;
    shortreal a;
    shortreal b;
    real a_full;
    real b_full;
    real expected;

    forever begin
        @(posedge clk);

        if (valid_o) begin
            inputs = input_q.pop_front();
            a_bit = 32'(inputs >> 32);
            b_bit = 32'(inputs);
            a = $bitstoshortreal(a_bit);
            b = $bitstoshortreal(b_bit);
            a_full = a;
            b_full = b;
            expected = a_full + b_full;

            // Will fail when rounding would make a difference
            if (sum !== $shortrealtobits(expected)) begin
                $display("ERROR");
                $display("a: %f", a);
                $display("b: %f", b);
                $display("a: %b", a_bit);
                $display("b: %b", b_bit);
                $display("Actual: %f", $bitstoshortreal(sum));
                $display("Expected: %f", expected);
                $display("Actual  : %b", sum);
                $display("Expected: %b\n", $shortrealtobits(expected));
                $finish;
            end else begin
                $display("GOOD");
                $display("a: %f", a);
                $display("b: %f", b);
                $display("Expected: %f", expected);
                $display("Actual  : %b\n", sum);
            end
        end
    end
endtask

initial begin
    $dumpvars;

    rst <= '1;
    @(posedge clk);
    rst <= '0;

    fork
        driver();
        monitor();
        scoreboard();
    join
end

initial begin
    repeat (100) begin
        do
            @(posedge clk);
        while (!valid_o);
    end
    $display("All done, no mistakes hehe");
    $finish;
end

endmodule
