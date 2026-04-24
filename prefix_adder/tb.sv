module tb;

localparam int unsigned WIDTH = 17;

logic [WIDTH-1:0] a;
logic [WIDTH-1:0] b;
logic [WIDTH-1:0] sum;
logic             c_in;
logic             c_out;

prefix_adder #(
    .WIDTH (WIDTH)
) prefix_adder (
    .a     (a    ),
    .b     (b    ),
    .c_in  (c_in ),
    .sum   (sum  ),
    .c_out (c_out)
);

initial begin
    $dumpfile("dump.fst");
    $dumpvars;
    c_in = '0;
    a    = '0;
    b    = '0;

    repeat (1_000_000) begin
        a = WIDTH'($urandom_range(0, (2**WIDTH)-1));
        b = WIDTH'($urandom_range(0, (2**WIDTH)-1));

        #1;
        assert ({c_out, sum} === a + b) else begin
            $display("expected %d, got %d", (WIDTH+1)'(a+b), {c_out, sum});
            $display("expected %b, got %b", (WIDTH+1)'(a+b), {c_out, sum});
        end
        $display({c_out, sum});
    end

    $finish;
end

endmodule
