`timescale 1ns / 1ps

module ModAddFastEq
#(
    parameter DATA_WIDTH = 32,
    parameter n_WIDTH = 8
)
(
    // input wire clk,
    // input wire rst,
    // input wire start,
    input wire signed [DATA_WIDTH-1:0] a,
    input wire signed [DATA_WIDTH-1:0] b,
    input wire signed [DATA_WIDTH-1:0] Q,
    output wire signed [DATA_WIDTH-1:0] out
    // output wire ready,
    // output wire done
);

    // Wire
    wire signed [DATA_WIDTH-1:0] c ;

    assign c = a + b ;
    assign out = (c > Q) ? (c-Q) : c;


endmodule