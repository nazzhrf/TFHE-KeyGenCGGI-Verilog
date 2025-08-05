`timescale 1ns / 1ps

module Modulo  
#(
    parameter DATA_WIDTH = 32,
    parameter n_WIDTH = 8
)
(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [DATA_WIDTH-1:0] m,
    input wire [DATA_WIDTH-1:0] p,
    output wire [DATA_WIDTH-1:0] m_mod_p,
    output wire ready,
    output wire done
);
    // Register
    reg [7:0] cntr ;
    reg [DATA_WIDTH-1:0] reg_m_mod_p ;
    reg reg_done_neg ;
    // Wire
    wire [DATA_WIDTH-1:0] in_dff ;
    wire w_done_pos ;
    
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
		if(!rst) begin
		    reg_m_mod_p <= 0 ;
            reg_done_neg <= 0 ;
		end else if (cntr == 1) begin
            if (m[DATA_WIDTH-1] == 0) begin
			    reg_m_mod_p <= m ; 
            end else begin 
                reg_m_mod_p <= -m ;
            end
		end else if (ready) begin
			reg_m_mod_p <= reg_m_mod_p-p ;
			if (m[DATA_WIDTH-1] == 1 && (reg_m_mod_p < p)) begin
			    reg_m_mod_p <= p - reg_m_mod_p ; 
			    reg_done_neg <= 1 ;
            end 
		end else begin
			reg_m_mod_p <= 0;
			reg_done_neg <= 0 ;
		end
	end 
    
    assign ready = (cntr >= 2) ? 1 : 0;
    assign m_mod_p = reg_m_mod_p;
    assign w_done_pos = (m[DATA_WIDTH-1] == 0 && (reg_m_mod_p < p) && ready) ? 1 : 0 ;
    assign done = (w_done_pos | reg_done_neg) ? 1 : 0;
    

endmodule