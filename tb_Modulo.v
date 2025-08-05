`timescale 1ns / 1ps

module tb_Modulo;

    parameter DATA_WIDTH = 32;
    localparam T = 10;

    // Input
    reg clk;
    reg rst;
    reg start;
    reg [DATA_WIDTH-1:0] m;
    reg signed [DATA_WIDTH-1:0] p;
    // Output
    wire signed [DATA_WIDTH-1:0] m_mod_p;
    wire ready;
    wire done;

    // Instantiate Modul
    Modulo uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .m(m),
        .p(p),
        .m_mod_p(m_mod_p),
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
        start = 1 ;
        #T;
        
        rst = 1 ;
//        m = 32'b00000000000010010000000000000000 ; //9
        m = 32'sb11111111111101110000000000000000 ; //-9
        p = 32'b00000000000001000000000000000000 ; // 4
//        p = 32'b00000000000101000000000000000000 ; //20
        #T;
        
        start = 0;

        #(T*50);

        $finish;
    end

endmodule

