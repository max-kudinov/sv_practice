module tb;

localparam int unsigned WIDTH    = 17;
localparam int unsigned N_CHECKS = 10_000;

bit               clk;
logic             rst;
logic [WIDTH-1:0] a;
logic [WIDTH-1:0] b;
logic [WIDTH-1:0] sum;
logic             c_in;
logic             c_out;
logic             valid_i;
logic             valid_o;
int unsigned      n_checks;

typedef struct packed {
    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic             c;
} args_t;

mailbox #(args_t)          in_mbx  = new();
mailbox #(logic [WIDTH:0]) out_mbx = new();

always #1 clk = !clk;

prefix_adder #(
    .WIDTH (WIDTH)
) prefix_adder (
    .clk     (clk    ),
    .rst     (rst    ),
    .valid_i (valid_i),
    .a       (a      ),
    .b       (b      ),
    .c_in    (c_in   ),
    .valid_o (valid_o),
    .sum     (sum    ),
    .c_out   (c_out  )
);

task driver;
    args_t rand_args;
    forever begin
        @(posedge clk);
        valid_i <= '1;

        if (std::randomize(rand_args) != 1)
            $error("Failed to randomize input arguments");

        a    <= rand_args.a;
        b    <= rand_args.b;
        c_in <= rand_args.c;
    end
endtask

task in_monitor;
    args_t input_args;
    forever begin
        @(posedge clk);

        if (valid_i) begin
            input_args.a = a;
            input_args.b = b;
            input_args.c = c_in;
            in_mbx.put(input_args);
        end
    end
endtask

task out_monitor;
    forever begin
        @(posedge clk);

        if (valid_o) begin
            out_mbx.put({c_out, sum});
        end
    end
endtask

task scoreboard;
    args_t inputs;
    logic [WIDTH:0] actual;
    logic [WIDTH:0] expected;

    forever begin
        in_mbx.get(inputs);
        out_mbx.get(actual);

        expected = inputs.a + inputs.b + WIDTH'(inputs.c);

        if (actual !== expected) begin
            $display("ERROR");
            $display("Check: %0d", n_checks);
            $display("a: %0d", inputs.a);
            $display("b: %0d", inputs.b);
            $display("c_in: %0d", inputs.c);
            $display("actual: %0d %0d", actual[WIDTH-1], actual[WIDTH-2:0]);
            $display("expected: %0d %0d", expected[WIDTH-1], expected[WIDTH-2:0]);
            $finish;
        end

        n_checks++;

        if (n_checks == N_CHECKS) begin
            $display("All %0d checks PASSED!", n_checks);
            $finish;
        end
    end
endtask

always begin
    $dumpfile("dump.fst");
    $dumpvars;

    @(posedge clk);
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
