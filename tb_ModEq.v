`timescale 1ns / 1ps

module tb_ModEq;

    parameter DATA_WIDTH = 37;
    localparam T = 10;

    // Input
    reg clk;
    reg rst;
    reg start;
    reg signed [DATA_WIDTH-1:0] oldmod;
    reg signed [DATA_WIDTH-1:0] newmod;
    reg signed [DATA_WIDTH-1:0] in_oldmod;
    // Output
    wire signed [DATA_WIDTH-1:0] out_newmod;
    wire done;

    // Instantiate Modul
    ModEq uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .oldmod(oldmod),
        .newmod(newmod),
        .in_oldmod(in_oldmod),
        .out_newmod(out_newmod),
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
        start = 1 ;
        #T;
        
        rst = 1 ;
        oldmod = 37'd15 ;
        newmod = 37'd17 ;
        in_oldmod = 37'd11 ;
        #T;
        
        start = 0;

        #(T*20);

        $finish;
    end

endmodule

