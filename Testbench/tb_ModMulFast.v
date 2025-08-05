`timescale 1ns / 1ps

module tb_ModMulFast;

    parameter DATA_WIDTH = 32;
    localparam T = 10;

    // Input
    reg clk;
    reg rst;
    reg start;
    reg signed [DATA_WIDTH-1:0] a;
    reg signed [DATA_WIDTH-1:0] b;
    reg signed [DATA_WIDTH-1:0] Q;
    // Output
    wire signed [DATA_WIDTH-1:0] ab_mod_Q;
    wire ready;
    wire done;

    // Instantiate Modul
    ModMulFast uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .Q(Q),
        .ab_mod_Q(ab_mod_Q),
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
        
        rst = 1 ;
//        a = 32'sb00000000000000001100000000000000 ;
//        b = 32'sb00000000000000001100000000000000 ;
//        Q = 32'sb00000000000010001000000000000000 ;
        
        a = 32'sb00000000001000000000000000000000 ;
        b = 32'sb00000000001000000000000000000000 ;
        Q = 32'sb01111111111111111111000000000000 ;
        start = 1;
        
        #T;
        start = 0;
        #T;
        
       
        wait (done == 1);

        #(T*5);

        $finish;
    end

endmodule

