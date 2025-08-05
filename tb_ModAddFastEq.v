`timescale 1ns / 1ps
`include "ModAddFastEq.v"

module tb_ModAddFastEq;

    parameter DATA_WIDTH = 32;
    localparam T = 10;

    // Input
    reg clk;
    // reg rst;
    // reg start;
    reg signed [DATA_WIDTH-1:0] a;
    reg signed [DATA_WIDTH-1:0] b;
    reg signed [DATA_WIDTH-1:0] Q;
    // Output
    wire signed [DATA_WIDTH-1:0] out;

    // Instantiate Modul
    ModAddFastEq uut (
        // .clk(clk),
        // .rst(rst),
        // .start(start),
        .a(a),
        .b(b),
        .Q(Q),
        .out(out)
        // .ready(ready),
        // .done(done)
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
        $dumpfile("tb_ModAddFastEq.vcd");
        $dumpvars(0, tb_ModAddFastEq);
        // Initialize
        // rst = 0 ;
        // start = 1 ;
        #T;
        
        // rst = 1 ;
        a = 32'sb00000111111111111111100000000000 ; //-9
        b = 32'sb00000000000000000000001000000000 ; // 4
        Q = 32'sb00000111111111111111100000000001;
        #T;
        
        // start = 0;

        #(T*10);

        $finish;
    end

endmodule

