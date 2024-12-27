module tb;

    localparam WIDTH      = 8;
    localparam DEPTH      = 8;
    localparam CLK_PERIOD = 10;

    logic             clk;
    logic             rst;
    logic             enable;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] ring_data_out;
    logic [WIDTH-1:0] shift_data_out;

    initial begin
        clk = 0;

        forever begin
            clk = ~clk;
            #(CLK_PERIOD/2);
        end
    end

    initial begin
        rst <= 1;
        repeat(10) @(posedge clk);
        rst <= 0;
    end

    ring_buffer_with_single_pointer #(
        .WIDTH ( WIDTH ),
        .DEPTH ( DEPTH )
    ) DUT (
        .clk_i    ( clk           ),
        .rst_i    ( rst           ),
        .enable_i ( enable        ),
        .data_i   ( data_in       ),
        .data_o   ( ring_data_out )
    );

    shift_reg_with_global_enable #(
        .WIDTH ( WIDTH ),
        .DEPTH ( DEPTH )
    ) model (
        .clk_i    ( clk            ),
        .enable_i ( enable         ),
        .data_i   ( data_in        ),
        .data_o   ( shift_data_out )
    );

    initial begin
        $dumpvars;

        wait (!rst);
        fork
            driver();
            monitor();
            timeout();
        join
    end

    task driver;
        forever begin
            @(posedge clk);
            enable  <= 1' ($urandom_range(0, 1));
            data_in <= WIDTH' ($urandom);
        end
    endtask

    task monitor;
        forever begin
            @(posedge clk);
            if (ring_data_out !== shift_data_out) begin
                $error("Expected %d, got %d", shift_data_out, ring_data_out);
            end
        end
    endtask

    task timeout;
        repeat (100) @(posedge clk);
        $display("All checks passed");
        $finish;
    endtask

endmodule
