`timescale 1ns / 1ps

module PreCompute128
#(
    parameter DATA_WIDTH = 32,
    parameter n_WIDTH = 8
)
(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [DATA_WIDTH-1:0] Bg,
    input wire signed [DATA_WIDTH-1:0] Q,
    output wire signed [DATA_WIDTH-1:0] GPow0,
    output wire signed [DATA_WIDTH-1:0] GPow1,
    output wire signed [DATA_WIDTH-1:0] GPow2,
    output wire ready,
    output wire done
);

    // Register
    reg [15:0] cntr ;
    reg signed [DATA_WIDTH-1:0] reg_Bg , reg_Q;
    reg signed [DATA_WIDTH-1:0] reg_gpow0, reg_gpow1, reg_gpow2;
    reg reg_finish_gpow0, reg_finish_gpow1, reg_finish_gpow2; 
    
    // Wire
    wire signed [DATA_WIDTH-1:0] vtemp0;
    wire start_modulo_0, ready_modulo_0, done_modulo_0 ;
    wire start_modulo_1, ready_modulo_1, done_modulo_1 ;
    wire start_ModMulFast_2, ready_ModMulFast_2, done_ModMulFast_2 ;
    wire signed [DATA_WIDTH-1:0] ab_mod_Q_0, ab_mod_Q_1, ab_mod_Q_2;
    

    // Modulo Instantiation
    Modulo
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    ) 
    mod_0 
    (
        .clk(clk),
        .rst(rst),
        .start(start_modulo_0),
        .m(vtemp0),
        .p(reg_Q),
        .m_mod_p(ab_mod_Q_0),
        .ready(ready_modulo_0),
        .done(done_modulo_0)
    );

    Modulo
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    ) 
    mod_1 
    (
        .clk(clk),
        .rst(rst),
        .start(start_modulo_1),
        .m(reg_Bg),
        .p(reg_Q),
        .m_mod_p(ab_mod_Q_1),
        .ready(ready_modulo_1),
        .done(done_modulo_1)
    );

    // ModMulFast Instantiation
    ModMulFast
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    ) 
    mmf_2 
    (
        .clk(clk),
        .rst(rst),
        .start(start_ModMulFast_2),
        .a(reg_Bg),
        .b(reg_Bg),
        .Q(reg_Q),
        .ab_mod_Q(ab_mod_Q_2),
        .ready(ready_ModMulFast_2),
        .done(done_ModMulFast_2)
    );

    // Counter 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cntr <= 16'd0;  
        end else if (start) begin
            cntr <= cntr + 16'd1;
        end else if (!done) begin
            cntr <= cntr + 16'd1;
        end else begin
            cntr <= 16'd0 ;      
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_Bg <= 0; reg_Q <= 0; 
            // reg_finish_gpow0 <= 0; reg_finish_gpow1 <= 0; reg_finish_gpow2 <= 0;
            // reg_gpow0 <= 0 ; reg_gpow1 <= 0 ; reg_gpow2 <= 0 ;
        end else if (cntr >= 1 && cntr < 2) begin
            reg_Bg <= Bg;
            reg_Q <= Q ; 
        end else begin
            reg_Bg <= reg_Bg ; reg_Q <= reg_Q ; 
            // reg_finish_gpow0 <= reg_finish_gpow0;
            // reg_finish_gpow1 <= reg_finish_gpow1;
            // reg_finish_gpow2 <= reg_finish_gpow2;
            // reg_gpow0 <= reg_gpow0 ; reg_gpow1 <= reg_gpow1 ; reg_gpow2 <= reg_gpow2 ;
        end
    end
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_finish_gpow0 <= 0; reg_finish_gpow1 <= 0; reg_finish_gpow2 <= 0;
            reg_gpow0 <= 0 ; reg_gpow1 <= 0 ; reg_gpow2 <= 0 ;
        end
        else begin 
            if (ready_modulo_0 && done_modulo_0) begin
                reg_finish_gpow0 <= 1;
                reg_gpow0 <= ab_mod_Q_0 ;
            end
            if (ready_modulo_1 && done_modulo_1) begin
                reg_finish_gpow1 <= 1;
                reg_gpow1 <= ab_mod_Q_1 ;
            end
            if (ready_ModMulFast_2 && done_ModMulFast_2) begin
                reg_finish_gpow2 <= 1;
                reg_gpow2 <= ab_mod_Q_2 ;
            end 
//            else begin
//                reg_gpow0 <= reg_gpow0 ; reg_gpow1 <= reg_gpow1 ; reg_gpow2 <= reg_gpow2 ;
//                reg_finish_gpow0 <= reg_finish_gpow0;
//                reg_finish_gpow1 <= reg_finish_gpow1;
//                reg_finish_gpow2 <= reg_finish_gpow2;
//            end
        end
    end

    assign ready = (cntr >= 2) ? 1 : 0;
    assign start_modulo_0 = (cntr >= 2 && cntr < 3) ? 1 : 0;
    assign start_modulo_1 = (cntr >= 2 && cntr < 3) ? 1 : 0;
    assign start_ModMulFast_2 = (cntr >= 2 && cntr < 3) ? 1 : 0;
    assign vtemp0 = 32'b00000000000000000001000000000000;
    assign GPow0 = reg_gpow0 ;
    assign GPow1 = reg_gpow1 ;
    assign GPow2 = reg_gpow2 ;
    assign done = (reg_finish_gpow0 && reg_finish_gpow1 && reg_finish_gpow2) ? 1 : 0 ;
    
endmodule