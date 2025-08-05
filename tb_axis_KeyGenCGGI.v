`timescale 1ns / 1ps

module tb_axis_KeyGenCGGI;

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

    reg aclk;
    reg aresetn;

    // *** AXIS slave port ***
    wire        s_axis_tready;
    reg [63:0]  s_axis_tdata;
    reg         s_axis_tvalid;
    reg         s_axis_tlast;
    // *** AXIS master port ***
    reg         m_axis_tready;
    wire [63:0] m_axis_tdata;
    wire        m_axis_tvalid;
    wire        m_axis_tlast;

    // Temporary
    reg [DATA_WIDTH-1:0] mt1s, mt2s, mt3s, mt4s ;
    reg [DATA_WIDTH-1:0] gng1s, gng2s, gng3s, gng4s ;
    reg [DATA_WIDTH-1:0] sk ;

    axis_KeyGenCGGI #
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
        .aclk(aclk),
        .aresetn(aresetn),
        // *** AXIS slave port ***
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        // *** AXIS master port ***
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );

    // Clock generation
    always
    begin
        aclk = 0;
        #(T/2);
        aclk = 1;
        #(T/2);
    end

    // Generate val ∈ {-1, 0, 1}
    always @(posedge aclk) begin
        case ($urandom % 3)
            0: sk <= 0;
            1: sk <= 1;
            2: sk <= -1;
        endcase
    end

    integer i;

    initial begin
        // Step 1: Reset
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
                
        aresetn = 0;
        #(T*5);
        aresetn = 1;
        #(T*5);

        s_axis_tvalid = 1;

        // *** Input *** //

        // 0 parbit : N_Q
        s_axis_tdata = 64'h00400000_7FFFFFFF ;
        #T;
        // 1 parbit : baseG
        s_axis_tdata = 64'h00200000_00000000 ;
        #T;
        // 2 parbit : digitsG, digitsG2
        s_axis_tdata = 64'h00003000_00004000 ;
        #T;
        // 3 parbit : MT1seed_MT2seed
        mt1s = $random % (UNI_RANDOM + 1);
        mt2s = $random % (UNI_RANDOM + 1);
        s_axis_tdata[63:32] = mt1s ;
        s_axis_tdata[31:0] = mt2s ;
        #T;
        // 4 parbit : MT3seed, MT4seed
        mt3s = ($random % (UNI_RANDOM + 1)) << 12;
        mt4s = ($random % (UNI_RANDOM + 1)) << 12;
        s_axis_tdata[63:32] = mt3s ;
        s_axis_tdata[31:0] = mt4s ;
        #T;
        // 5 parbit : gng1seed, gng2seed
        gng1s = ($random % (GAUSS + 1)) << 12;
        gng2s = ($random % (GAUSS + 1)) << 12;
        s_axis_tdata[63:32] = gng1s ;
        s_axis_tdata[31:0] = gng2s ;
        #T;
        // 6 parbit : gng3seed, gng4seed
        gng3s = ($random % (GAUSS + 1)) << 12;
        gng4s = ($random % (GAUSS + 1)) << 12;
        s_axis_tdata[63:32] = gng3s ;
        s_axis_tdata[31:0] = gng4s ;
        #T;
        
        i = 0 ;
        // Write secret key
        for (i = 0; i < 1024; i = i + 1) begin
            s_axis_tdata[63:32] = sk << 12 ;
            s_axis_tdata[31:0] = 0 ;
            #T;
        end
        #T;

        i = 0 ;
        // Write omega 
        for (i = 0; i < 2145; i = i + 1) begin
            s_axis_tdata[63:32] = ($urandom % (GAUSS + 1)) << 12 ;
            s_axis_tdata[31:0] = 0 ;
            #T;
        end

        #(T*2);

        s_axis_tvalid = 0;
        s_axis_tdata = 0; 
        s_axis_tlast = 0;
        
        wait (m_axis_tlast);
        
        #(T*5);

        $finish;

    end

endmodule
