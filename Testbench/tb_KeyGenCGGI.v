`timescale 1ns / 1ps

module tb_KeyGenCGGI;

    parameter T = 10;
    parameter n_WIDTH = 8;
    parameter DATA_WIDTH = 32;
    parameter CNTR_WIDTH = 16;
    parameter ADDR_MAX_WIDTH = 10;
    parameter ADDR_PARAM_WIDTH = 4;
    parameter BRAM_MAX_WIDTH = 64;
    parameter AX_EX_MAX_WIDTH = 128;

    parameter UNI_RANDOM = (1 << 20) - 1;
    parameter GAUSS = (1 << 10) - 1 ;

    reg clk;
    reg rst_n;
    reg en = 0 ;
    reg clr = 0;

    // *** Control and status port ***
    wire                         ready;
    reg                          start;
    wire                         done;
    // *** INPUT BRAM parameters and bit message port ***
    reg                          in_parbit_ena;
    reg [ADDR_PARAM_WIDTH-1:0]   in_parbit_addra;
    reg [BRAM_MAX_WIDTH-1:0]     in_parbit_dina;
    reg [7:0]                    in_parbit_wea;
    // *** INPUT BRAM secret key port ***
    reg                          in_sk_ena;
    reg [ADDR_MAX_WIDTH-1:0]     in_sk_addra;
    reg [BRAM_MAX_WIDTH-1:0]     in_sk_dina;
    reg [7:0]                    in_sk_wea;
    // *** INPUT BRAM omega port ***
    reg                          in_w_ena;
    reg [ADDR_MAX_WIDTH+1:0]     in_w_addra;
    reg [BRAM_MAX_WIDTH-1:0]     in_w_dina;
    reg [7:0]                    in_w_wea;
    // *** OUTPUT BRAM  [A(X)_1 and A(X)_2] BRAM 1 ***
    reg                          out_ax12_enb;
    reg [ADDR_MAX_WIDTH-1:0]     out_ax12_addrb;
    wire [BRAM_MAX_WIDTH-1:0]    out_ax12_doutb;
    // *** OUTPUT BRAM  [A(X)_3 and A(X)_4] BRAM 2 ***
    reg                          out_ax34_enb;
    reg [ADDR_MAX_WIDTH-1:0]     out_ax34_addrb;
    wire [BRAM_MAX_WIDTH-1:0]    out_ax34_doutb;
    // *** OUTPUT BRAM  [B(X)_1 and B(X)_2] BRAM 3 ***
    reg                          out_bx12_enb;
    reg [ADDR_MAX_WIDTH-1:0]     out_bx12_addrb;
    wire [BRAM_MAX_WIDTH-1:0]    out_bx12_doutb;
    // *** OUTPUT BRAM  [B(X)_3 and B(X)_4] BRAM 4 ***
    reg                          out_bx34_enb;
    reg [ADDR_MAX_WIDTH-1:0]     out_bx34_addrb;
    wire [BRAM_MAX_WIDTH-1:0]    out_bx34_doutb;

    // Temporary
    reg [DATA_WIDTH-1:0] mt1s, mt2s, mt3s, mt4s ;
    reg [DATA_WIDTH-1:0] gng1s, gng2s, gng3s, gng4s ;
    reg [DATA_WIDTH-1:0] sk ;

    KeyGenCGGI #
    (
        .n_WIDTH(n_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CNTR_WIDTH(CNTR_WIDTH),
        .ADDR_MAX_WIDTH(ADDR_MAX_WIDTH),
        .ADDR_PARAM_WIDTH(ADDR_PARAM_WIDTH),
        .BRAM_MAX_WIDTH(BRAM_MAX_WIDTH),
        .AX_EX_MAX_WIDTH(AX_EX_MAX_WIDTH)
    )
    dut 
    (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clr(clr),
        // *** Control and status port ***
        .ready(ready),
        .start(start),
        .done(done),
        // *** INPUT BRAM parameters and bit message port ***
        .in_parbit_ena(in_parbit_ena),
        .in_parbit_addra(in_parbit_addra),
        .in_parbit_dina(in_parbit_dina),
        .in_parbit_wea(in_parbit_wea),
        // *** INPUT BRAM secret key port ***
        .in_sk_ena(in_sk_ena),
        .in_sk_addra(in_sk_addra),
        .in_sk_dina(in_sk_dina),
        .in_sk_wea(in_sk_wea),
        // *** INPUT BRAM omega port ***
        .in_w_ena(in_w_ena),
        .in_w_addra(in_w_addra),
        .in_w_dina(in_w_dina),
        .in_w_wea(in_w_wea),
        // *** OUTPUT BRAM  [A(X)_1 and A(X)_2] BRAM 1 ***
        .out_ax12_enb(out_ax12_enb),
        .out_ax12_addrb(out_ax12_addrb),
        .out_ax12_doutb(out_ax12_doutb),
        // *** OUTPUT BRAM  [A(X)_3 and A(X)_4] BRAM 2 ***
        .out_ax34_enb(out_ax34_enb),
        .out_ax34_addrb(out_ax34_addrb),
        .out_ax34_doutb(out_ax34_doutb),
        // *** OUTPUT BRAM  [B(X)_1 and B(X)_2] BRAM 3 ***
        .out_bx12_enb(out_bx12_enb),
        .out_bx12_addrb(out_bx12_addrb),
        .out_bx12_doutb(out_bx12_doutb),
        // *** OUTPUT BRAM  [B(X)_3 and B(X)_4] BRAM 4 ***
        .out_bx34_enb(out_bx34_enb),
        .out_bx34_addrb(out_bx34_addrb),
        .out_bx34_doutb(out_bx34_doutb)
    );

    // Clock generation
    always
    begin
        clk = 0;
        #(T/2);
        clk = 1;
        #(T/2);
    end

    // Generate val ∈ {-1, 0, 1}
    always @(posedge clk) begin
        case ($urandom % 3)
            0: sk <= 0;
            1: sk <= 1;
            2: sk <= -1;
        endcase
    end

    integer i;

    initial begin
        // Step 1: Reset
        rst_n = 0;
        en = 1 ;
        clr = 0 ;
        start = 0 ;
        in_parbit_ena = 1; in_parbit_addra = 0; in_parbit_dina = 0; in_parbit_wea = 0; 
        in_sk_ena = 0; in_sk_addra = 0; in_sk_dina = 0; in_sk_wea = 0;
        in_w_ena = 0; in_w_addra = 0; in_w_dina = 0; in_w_wea = 0;
        #(T*2);

        rst_n = 1;
        // N_Q
        in_parbit_wea = 8'hff; in_parbit_addra = 0 ;
        in_parbit_dina = 64'h00400000_7FFFFFFF ;
        #T;
        // baseG
        in_parbit_wea = 8'hff; in_parbit_addra = 1 ;
        in_parbit_dina = 64'h00200000_00000000 ;
        #T;
        // digitsG, digitsG2
        in_parbit_wea = 8'hff; in_parbit_addra = 2 ;
        in_parbit_dina = 64'h00003000_00004000 ;
        #T;
        // MT1seed_MT2seed
        in_parbit_wea = 8'hff; in_parbit_addra = 3 ; 
        mt1s = $random % (UNI_RANDOM + 1);
        mt2s = $random % (UNI_RANDOM + 1);
        in_parbit_dina[63:32] = mt1s ;
        in_parbit_dina[31:0] = mt2s ;
        #T;
        // MT3seed, MT4seed
        in_parbit_wea = 8'hff; in_parbit_addra = 4 ;
        mt3s = ($random % (UNI_RANDOM + 1)) << 12;
        mt4s = ($random % (UNI_RANDOM + 1)) << 12;
        in_parbit_dina[63:32] = mt3s ;
        in_parbit_dina[31:0] = mt4s ;
        #T;
        // gng1seed, gng2seed
        in_parbit_wea = 8'hff; in_parbit_addra = 5 ;
        gng1s = ($random % (GAUSS + 1)) << 12;
        gng2s = ($random % (GAUSS + 1)) << 12;
        in_parbit_dina[63:32] = gng1s ;
        in_parbit_dina[31:0] = gng2s ;
        #T;
        // gng3seed, gng4seed
        in_parbit_wea = 8'hff; in_parbit_addra = 6 ;
        gng3s = ($random % (GAUSS + 1)) << 12;
        gng4s = ($random % (GAUSS + 1)) << 12;
        in_parbit_dina[63:32] = gng3s ;
        in_parbit_dina[31:0] = gng4s ;
        #T;
        in_parbit_ena = 0; in_parbit_wea = 0; 
        in_w_ena = 1 ; in_w_wea = 8'hff ;

        #T;
        
        i = 0 ;
        // Write the omega and secret key
        for (i = 0; i < 2145; i = i + 1) begin
            if (i < 1024 ) begin 
                in_sk_ena = 1 ; in_sk_wea = 8'hff ;
                in_sk_addra = i ;
                in_sk_dina[63:32] = sk << 12 ;
                in_sk_dina[31:0] = 0 ;
            end
            in_w_addra = i ; 
            in_w_dina[63:32] = ($urandom % (GAUSS + 1)) << 12;
            in_w_dina[31:0] = 0 ;
            #T;
        end
        #T;

        in_w_ena = 0 ; in_w_wea = 0 ;
        in_sk_ena = 0 ; in_sk_wea = 0 ;
        #(T*2);
    
        start = 1 ;
        #T;

        start = 0 ;
        #T;

        wait (done)
        #T;

        i = 0 ;
        // Read output
        for (i = 0; i < 1024; i = i + 1) begin
            out_ax12_enb <= 1 ; out_ax34_enb <= 1 ; 
            out_bx12_enb <= 1 ; out_bx34_enb <= 1 ; 

            out_ax12_addrb <= i ; out_ax34_addrb <= i ;
            out_bx12_addrb  <= i ; out_bx34_addrb <= i ;
            #T;
        end

        out_ax12_enb <= 0 ; out_ax34_enb <= 0 ; 
        out_bx12_enb <= 0 ; out_bx34_enb <= 0 ;
        #T;

        $finish;
    end

endmodule
