`timescale 1ns / 1ps

module tb_MT1997Axis;

    parameter T = 10;
    reg clk = 0;
    reg rst = 0;

    reg [31:0] seed_val = 0;
    reg seed_start = 0;
    reg output_axis_tready = 1;

    wire [31:0] output_axis_tdata;
    wire output_axis_tvalid;
    wire busy;

    MT1997Axis dut (
        .clk(clk),
        .rst(rst),
        .seed_val(seed_val),
        .seed_start(seed_start),
        .output_axis_tdata(output_axis_tdata),
        .output_axis_tvalid(output_axis_tvalid),
        .output_axis_tready(output_axis_tready),
        .busy(busy)
    );

    // Clock generation
    always #(T/2) clk = ~clk;

    integer i;

    initial begin
        $display("Start simulation");
        $dumpfile("tb_MT1997Axis.vcd");
        $dumpvars(0, tb_MT1997Axis);

        // Step 1: Reset
        rst = 1;
        #T;
        rst = 0;
        #T;

        // Step 2: Berikan seed dan trigger
        seed_val = 32'h12345678;
        seed_start = 1;
        #T;
        seed_start = 0;

        // Step 3: Tunggu hingga output valid muncul
        wait (output_axis_tvalid == 1);

        // Step 4: Ambil dan tampilkan 1000 angka acak
        for (i = 0; i < 1000; i = i + 1) begin
            @(posedge clk);
            if (output_axis_tvalid) begin
                $display("Random[%0d] = %h", i, output_axis_tdata);
            end
        end

        $display("Selesai.");
        $finish;
    end

endmodule
