import "DPI-C" pure function int unsigned float_add(input int unsigned a, input int unsigned b);
import "DPI-C" pure function real bin_to_real(input int unsigned int_num);

module tb;

bit clk;
logic rst;
logic valid_i;
logic valid_o;
logic [31:0] num_1;
logic [31:0] num_2;
logic [31:0] sum;
int n_checks;

always #1 clk = !clk;

typedef struct packed {
    logic [31:0] a;
    logic [31:0] b;
} args_t;

mailbox #(args_t)       in_mbx  = new();
mailbox #(logic [31:0]) out_mbx = new();

fp_add fp_add (
    .clk     (clk    ),
    .rst     (rst    ),
    .valid_i (valid_i),
    .num_a_i (num_1  ),
    .num_b_i (num_2  ),
    .sum_o   (sum    ),
    .valid_o (valid_o)
);

task driver;
    args_t rand_args;
    forever begin
        @(posedge clk);
        valid_i <= '0;

        do
            @(posedge clk);
        while ($urandom_range(0, 1) != 0);

        valid_i <= '1;

        // Don't randomize inf and NaN
        if (std::randomize(rand_args) with {
            rand_args.a[31] == '0;
            rand_args.a[30:23] != '1;
            rand_args.b[31] == '0;
            rand_args.b[30:23] != '1;
        } != 1) begin
            $error("Failed to randomize input arguments");
        end

        num_1 <= rand_args.a;
        num_2 <= rand_args.b;
    end
endtask

task in_monitor;
    args_t input_args;
    forever begin
        @(posedge clk);

        if (valid_i) begin
            input_args.a = num_1;
            input_args.b = num_2;
            in_mbx.put(input_args);
        end
    end
endtask

task out_monitor;
    forever begin
        @(posedge clk);

        if (valid_o) begin
            out_mbx.put(sum);
        end
    end
endtask

task scoreboard;
    args_t inputs;
    logic [31:0] actual;
    logic [31:0] expected;

    forever begin
        in_mbx.get(inputs);
        out_mbx.get(actual);
        expected = float_add(inputs.a, inputs.b);

        // Ignore unsupported +-inf and NaN results
        if (expected[30:23] != '1) begin
            if (actual !== expected) begin
                $display("ERROR");
                $display("Check: %0d", n_checks);
                $display("a:        %b %b %b, %f",
                    inputs.a[31], inputs.a[30:23], inputs.a[22:0], bin_to_real(inputs.a));
                $display("b:        %b %b %b, %f",
                    inputs.b[31], inputs.b[30:23], inputs.b[22:0], bin_to_real(inputs.b));
                $display("Actual:   %b %b %b, %f",
                    sum[31], sum[30:23], sum[22:0], bin_to_real(sum));
                $display("Expected: %b %b %b, %f\n",
                    expected[31], expected[30:23], expected[22:0], bin_to_real(expected));
                $finish;
            end

            n_checks++;

            if (n_checks == 1_000_000) begin
                $display("All %d checks PASSED!", n_checks);
                $finish;
            end
        end
    end
endtask

always begin
    $dumpfile("dump.fst");
    $dumpvars;

    rst <= '1;
    @(posedge clk);
    rst <= '0;

    fork
        driver();
        in_monitor();
        out_monitor();
        scoreboard();
    join

    // _Verilator hack around unsupported NBA in initial
    wait(0);
end

endmodule
