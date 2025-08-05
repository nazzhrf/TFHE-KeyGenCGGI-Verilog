`timescale 1ns / 1ps

module tb_PreCompute128;

    parameter DATA_WIDTH = 32;
    parameter n_WIDTH = 8;
    localparam T = 10;

    // Input
    reg clk;
    reg rst;
    reg start;
    reg signed [DATA_WIDTH-1:0] Bg;
    reg signed [DATA_WIDTH-1:0] Q;
    // Output
    wire signed [DATA_WIDTH-1:0] GPow0;
    wire signed [DATA_WIDTH-1:0] GPow1;
    wire signed [DATA_WIDTH-1:0] GPow2;
    wire ready;
    wire done;

    // Instantiate Modul
    PreCompute128 #
    (
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    ) 
    uut 
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .Bg(Bg),
        .Q(Q),
        .GPow0(GPow0),
        .GPow1(GPow1),
        .GPow2(GPow2),
        .ready(ready),
        .done(done)
    );

    // Clock generation
    always
    begin
        clk = 0;
        #(T/2);
        clk = 1;
        #(T/2);
    end

    initial 
    begin
        // Initialize
        rst = 0 ;
        #T;
        
        start = 1 ;
        rst = 1 ;       
        Bg = 32'sb00000000001000000000000000000000 ;
        Q = 32'sb01111111111111111111000000000000 ;
        #T;
        
        start = 0;
        wait (done == 1);

        #(T*3);

        $finish;
    end

endmodule

