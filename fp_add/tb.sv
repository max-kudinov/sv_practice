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
    num_1 = $shortrealtobits(0.69);
    num_2 = $shortrealtobits(0.400);
    #1;
    $display("%f", $bitstoshortreal(sum));
    $display("%f", 0.69 + 0.400);
    $display("%b", sum);
end

endmodule
