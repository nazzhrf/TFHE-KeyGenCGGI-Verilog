`timescale 1ns / 1ps

module ModMulFast
#(
    parameter DATA_WIDTH = 32,
    parameter n_WIDTH = 8
)
(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [DATA_WIDTH-1:0] a,
    input wire signed [DATA_WIDTH-1:0] b,
    input wire signed [DATA_WIDTH-1:0] Q,
    output wire signed [DATA_WIDTH-1:0] ab_mod_Q,
    output wire ready,
    output wire done
);
    // Register
    reg [7:0] cntr ;
    reg signed [2*DATA_WIDTH-1:0] reg64_ab ;
    reg signed [DATA_WIDTH-1:0] reg_Q ;

    // Wire
    wire signed [DATA_WIDTH-1:0] w32_ab ;
    wire start_modulo, ready_modulo, done_modulo;

    // Modulo Instantiation
    Modulo
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    ) 
    mod 
    (
        .clk(clk),
        .rst(rst),
        .start(start_modulo),
        .m(w32_ab),
        .p(reg_Q),
        .m_mod_p(ab_mod_Q),
        .ready(ready_modulo),
        .done(done_modulo)
    );

    // Counter 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cntr <= 8'd0;  
        end else if (start) begin
            cntr <= cntr + 8'd1;
        end else if (cntr>=1 && !done) begin
            cntr <= cntr + 8'd1;
        end else begin
            cntr <= 0 ;      
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg64_ab <= 0; 
            reg_Q <= 0 ; 
        end else if (cntr >= 1 && cntr < 2) begin
            reg64_ab <= a * b;
            reg_Q <= Q ;
        end else begin
            reg64_ab <= reg64_ab ;  
            reg_Q <= reg_Q ; 
        end
    end
    
    assign ready = (cntr >= 2) ? 1 : 0;
    assign w32_ab = reg64_ab[43:12];
    assign start_modulo = (cntr == 3) ? 1 : 0;
    assign done = (done_modulo && ready_modulo) ? 1 : 0;

endmodule