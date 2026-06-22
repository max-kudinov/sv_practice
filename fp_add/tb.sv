module tb;

logic [31:0] num_1;
logic [31:0] num_2;
logic [31:0] sum;

fp_add fp_add (
    .num_1_i (num_1),
    .num_2_i (num_2),
    .sum_o   (sum  )
);

initial begin
    shortreal a;
    shortreal b;
    shortreal expected;
    $dumpvars;

    for (int i = 0; i < 100; i++) begin
        a = $bitstoshortreal($urandom);
        b = $bitstoshortreal($urandom);
        num_1 = $shortrealtobits(a);
        num_2 = $shortrealtobits(b);
        #1;

        expected = a + b;

        if (sum !== $shortrealtobits(expected)) begin
            $display("Test: %d", i);
            $display("a: %f", a);
            $display("b: %f", b);
            $display("a: %b", $shortrealtobits(a));
            $display("b: %b", $shortrealtobits(b));
            $display("Actual: %f", $bitstoshortreal(sum));
            $display("Expected: %f", expected);
            $display("Actual  : %b", sum);
            $display("Expected: %b\n", $shortrealtobits(expected));
            $finish;
        end

        // $display("%b", sum);
        // $display("%h", sum);
        // $display("My exponent is: %b", sum[30-:8]);
        // $display("My mantissa is: %b", sum[22:0]);
        // $display("a: %b", num_1);
        // $display("b: %b", num_2);
        // $display("exp: %d", 00010010101111010000001);
        // $display("mant: %d", 8'b00100100);
    end

    $display("All done, no mistakes hehe");
    $finish;
end

endmodule
