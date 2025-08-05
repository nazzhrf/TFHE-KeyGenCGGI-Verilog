`timescale 1ns / 1ps

module Mult64
#(
    parameter DATA_WIDTH = 32,
    parameter n_WIDTH = 8
)
(
    input wire clk,
    input wire rst,
    input wire signed [DATA_WIDTH-1:0] a,
    input wire signed [DATA_WIDTH-1:0] b,
    output wire signed [DATA_WIDTH-1:0] out
    // output wire ready,
    // output wire done
);

    // Wire
    reg signed [2*DATA_WIDTH-1:0] ab64 ;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ab64 <= 0;  
        end else begin
            ab64 <= a * b ;  
        end
    end

    assign out = ab64[43:12] ;


endmodule