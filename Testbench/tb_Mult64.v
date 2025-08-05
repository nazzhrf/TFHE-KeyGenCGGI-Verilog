`timescale 1ns / 1ps

module tb_Mult64;

    parameter DATA_WIDTH = 32;
    parameter n_WIDTH = 8;
    localparam T = 10;

    // Input
    reg clk;
    reg rst;
    reg signed [DATA_WIDTH-1:0] a;
    reg signed [DATA_WIDTH-1:0] b;
    // Output
    wire signed [DATA_WIDTH-1:0] out;

    // Instantiate Modul
    Mult64 uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .out(out)
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
        $dumpfile("tb_Mult64.vcd");
        $dumpvars(0, tb_Mult64);
        // Initialize
        rst = 0 ;
        #T;
        
        rst = 1 ;
        a = 32'h0002ebd2 ; 
        b = 32'h01396ffc ; 
        #T;
        
        a = 32'h01d500ff ;
        b = 32'h01a42433 ;
        #T;
        
        a = 32'h5f7f6514 ;
        b = 32'hb30b6000 ;
        #T;
        
        a = 32'h00cd4a46 ;
        b = 32'h01003419 ;
        #T;
        
        a = 32'h0040c2b4 ;
        b = 32'h000f6d06 ;
        #T;
        
        // start = 0;

        #(T*10);

        $finish;
    end

endmodule

