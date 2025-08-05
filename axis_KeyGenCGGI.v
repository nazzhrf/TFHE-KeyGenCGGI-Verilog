`timescale 1ns / 1ps

module axis_KeyGenCGGI
#(
    parameter n_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter CNTR_WIDTH = 16,
    parameter ADDR_MAX_WIDTH = 10,
    parameter ADDR_PARAM_WIDTH = 4,
    parameter BRAM_MAX_WIDTH = 64,
    parameter AX_EX_MAX_WIDTH = 128
)
(
    input wire         aclk,
    input wire         aresetn,
    // *** AXIS slave port ***
    output wire        s_axis_tready,
    input wire [63:0]  s_axis_tdata,
    input wire         s_axis_tvalid,
    input wire         s_axis_tlast,
    // *** AXIS master port ***
    input wire         m_axis_tready,
    output wire [63:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    output wire        m_axis_tlast
);

    // State machine
    reg [8:0] state_reg, state_next;
    reg [11:0] cnt_word_reg, cnt_word_next;

    // MM2S FIFO    
    wire [11:0] mm2s_data_count;
    wire start_from_mm2s;
    reg mm2s_ready_reg, mm2s_ready_next;
    wire [63:0] mm2s_data;
    
    // *** KeyGenCGGI ******************************************************************************************************
    // *** Control and status port ***
    wire        KeyGenCGGI_ready;
    wire        KeyGenCGGI_start;
    wire        KeyGenCGGI_done;
    // *** INPUT BRAM parameters and bit message port ***
    wire                          in_parbit_ena;
    wire [ADDR_PARAM_WIDTH-1:0]   in_parbit_addra;
    wire [BRAM_MAX_WIDTH-1:0]     in_parbit_dina;
    wire [7:0]                    in_parbit_wea;
    // *** INPUT BRAM secret key port ***
    wire                          in_sk_ena;
    wire [ADDR_MAX_WIDTH-1:0]     in_sk_addra;
    wire [BRAM_MAX_WIDTH-1:0]     in_sk_dina;
    wire [7:0]                    in_sk_wea;
    // *** INPUT BRAM omega port ***
    wire                          in_w_ena;
    wire [ADDR_MAX_WIDTH+1:0]     in_w_addra;
    wire [BRAM_MAX_WIDTH-1:0]     in_w_dina;
    wire [7:0]                    in_w_wea;
    // *** OUTPUT BRAM  [A(X)_1 and A(X)_2] BRAM 1 ***
    wire                          out_ax12_enb;
    wire [ADDR_MAX_WIDTH-1:0]     out_ax12_addrb;
    wire [BRAM_MAX_WIDTH-1:0]     out_ax12_doutb;
    // *** OUTPUT BRAM  [A(X)_3 and A(X)_4] BRAM 2 ***
    wire                          out_ax34_enb;
    wire [ADDR_MAX_WIDTH-1:0]     out_ax34_addrb;
    wire [BRAM_MAX_WIDTH-1:0]     out_ax34_doutb;
    // *** OUTPUT BRAM  [B(X)_1 and B(X)_2] BRAM 3 ***
    wire                          out_bx12_enb;
    wire [ADDR_MAX_WIDTH-1:0]     out_bx12_addrb;
    wire [BRAM_MAX_WIDTH-1:0]     out_bx12_doutb;
    // *** OUTPUT BRAM  [B(X)_3 and B(X)_4] BRAM 4 ***
    wire                          out_bx34_enb;
    wire [ADDR_MAX_WIDTH-1:0]     out_bx34_addrb;
    wire [BRAM_MAX_WIDTH-1:0]     out_bx34_doutb;

    // S2MM FIFO
    wire s2mm_ready;
    wire [63:0] s2mm_data;
    wire s2mm_valid, s2mm_valid_reg;
    wire s2mm_last, s2mm_last_reg;

    // *** MM2S FIFO ************************************************************
    // xpm_fifo_axis: AXI Stream FIFO
    // Xilinx Parameterized Macro, version 2018.3
    xpm_fifo_axis
    #(
        .CDC_SYNC_STAGES(2),                 // DECIMAL
        .CLOCKING_MODE("common_clock"),      // String
        .ECC_MODE("no_ecc"),                 // String
        .FIFO_DEPTH(4096),                   // DECIMAL, depth 256 elemen 
        .FIFO_MEMORY_TYPE("auto"),           // String
        .PACKET_FIFO("false"),               // String
        .PROG_EMPTY_THRESH(10),              // DECIMAL
        .PROG_FULL_THRESH(10),               // DECIMAL
        .RD_DATA_COUNT_WIDTH(1),             // DECIMAL
        .RELATED_CLOCKS(0),                  // DECIMAL
        .SIM_ASSERT_CHK(0),                  // DECIMAL
        .TDATA_WIDTH(64),                    // DECIMAL, data width 64 bit
        .TDEST_WIDTH(1),                     // DECIMAL
        .TID_WIDTH(1),                       // DECIMAL
        .TUSER_WIDTH(1),                     // DECIMAL
        .USE_ADV_FEATURES("0004"),           // String, write data count
        .WR_DATA_COUNT_WIDTH(13)              // DECIMAL, width log2(256)+1=9 
    )
    xpm_fifo_axis_0
    (
        .almost_empty_axis(), 
        .almost_full_axis(), 
        .dbiterr_axis(), 
        .prog_empty_axis(), 
        .prog_full_axis(), 
        .rd_data_count_axis(), 
        .sbiterr_axis(), 
        .injectdbiterr_axis(1'b0), 
        .injectsbiterr_axis(1'b0), 
    
        .s_aclk(aclk), // aclk
        .m_aclk(aclk), // aclk
        .s_aresetn(aresetn), // aresetn
        
        .s_axis_tready(s_axis_tready), // ready    
        .s_axis_tdata(s_axis_tdata), // data
        .s_axis_tvalid(s_axis_tvalid), // valid
        .s_axis_tdest(1'b0), 
        .s_axis_tid(1'b0), 
        .s_axis_tkeep(8'hff), 
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tstrb(8'hff), 
        .s_axis_tuser(1'b0), 
        
        .m_axis_tready(mm2s_ready_reg), // ready  
        .m_axis_tdata(mm2s_data), // data
        .m_axis_tvalid(), // valid
        .m_axis_tdest(), 
        .m_axis_tid(), 
        .m_axis_tkeep(), 
        .m_axis_tlast(), 
        .m_axis_tstrb(), 
        .m_axis_tuser(),  
        
        .wr_data_count_axis(mm2s_data_count) // data count
    );
    
    // *** Main control *********************************************************
    // Start signal from DMA MM2S
    assign start_from_mm2s = (mm2s_data_count >= 3076); // Weight = 27 word, input = 9 word, total = 36 word
    
    // State machine for AXI-Stream protocol
    always @(posedge aclk)
    begin
        if (!aresetn)
        begin
            state_reg <= 0;
            mm2s_ready_reg <= 0;
            cnt_word_reg <= 0;
        end
        else
        begin
            state_reg <= state_next;
            mm2s_ready_reg <= mm2s_ready_next;
            cnt_word_reg <= cnt_word_next;
        end
    end
    
    always @(*)
    begin
        state_next = state_reg;
        mm2s_ready_next = mm2s_ready_reg;
        cnt_word_next = cnt_word_reg;
        case (state_reg)
            0: // Wait until data from MM2S is ready (7 words)
            begin
                if (start_from_mm2s)
                begin
                    state_next = 1;
                    mm2s_ready_next = 1; // Tell the MM2S FIFO that it is ready to accept data
                end
            end
            1: // Write data to input parameter & bit message BRAM of KeyGenCGGI
            begin
                if (cnt_word_reg == 6)
                begin
                    state_next = 2;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end
            end
            2: // Write data to input secret key BRAM of KeyGenCGGI
            begin
                if (cnt_word_reg == 1023)
                begin
                    state_next = 3;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end                
            end
            3: // Write data to input omega BRAM of KeyGenCGGI
            begin
                if (cnt_word_reg == 2144)
                begin
                    state_next = 4;
                    mm2s_ready_next = 0;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end                
            end
            4: // Start KeyGenCGGI
            begin
                state_next = 5;
            end
            5: // Wait until KeyGenCGGI done and S2MM FIFO is ready to accept data
            begin
                if (KeyGenCGGI_done && s2mm_ready)
                begin
                    state_next = 6;
                end
            end
            6: // Read data output from BRAM ax12 of KeyGenCGGI
            begin
                if (cnt_word_reg == 1023)
                begin
                    state_next = 7;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end
            end
            7: // Read data output from BRAM ax34 of KeyGenCGGI
            begin
                if (cnt_word_reg == 1023)
                begin
                    state_next = 8;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end
            end
            8: // Read data output from BRAM bx12 of KeyGenCGGI
            begin
                if (cnt_word_reg == 1023)
                begin
                    state_next = 9;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end
            end
            9: // Read data output from BRAM bx34 of KeyGenCGGI
            begin
                if (cnt_word_reg == 1023)
                begin
                    state_next = 0;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end
            end
        endcase
    end

    // Control input parameter & bit message port of KeyGenCGGI
    assign in_parbit_ena = (state_reg == 1) ? 1 : 0;
    assign in_parbit_addra = cnt_word_reg;
    assign in_parbit_dina = mm2s_data;
    assign in_parbit_wea = (state_reg == 1) ? 8'hff : 0;

    // Control input secret key port of KeyGenCGGI
    assign in_sk_ena = (state_reg == 2) ? 1 : 0;
    assign in_sk_addra = cnt_word_reg;
    assign in_sk_dina = mm2s_data;
    assign in_sk_wea = (state_reg == 2) ? 8'hff : 0;

    // Control input omega port of KeyGenCGGI
    assign in_w_ena = (state_reg == 3) ? 1 : 0;
    assign in_w_addra = cnt_word_reg;
    assign in_w_dina = mm2s_data;
    assign in_w_wea = (state_reg == 3) ? 8'hff : 0;
    
    // Start KeyGenCGGI
    assign KeyGenCGGI_start = (state_reg == 4) ? 1 : 0;

    // Control output ax12 port of KeyGenCGGI
    assign out_ax12_enb = (state_reg == 6) ? 1 : 0;
    assign out_ax12_addrb = cnt_word_reg;

    // Control output ax34 port of KeyGenCGGI
    assign out_ax34_enb = (state_reg == 7) ? 1 : 0;
    assign out_ax34_addrb = cnt_word_reg;

    // Control output bx12 port of KeyGenCGGI
    assign out_bx12_enb = (state_reg == 8) ? 1 : 0;
    assign out_bx12_addrb = cnt_word_reg;

    // Control output bx34 port of KeyGenCGGI
    assign out_bx34_enb = (state_reg == 9) ? 1 : 0;
    assign out_bx34_addrb = cnt_word_reg;

    // Control S2MM FIFO
    assign s2mm_data =  (state_reg == 6) ? out_ax12_doutb :
                        (state_reg == 7) ? out_ax34_doutb :
                        (state_reg == 8) ? out_bx12_doutb :
                        (state_reg == 9) ? out_bx34_doutb : 0 ;
    
    assign s2mm_valid = (state_reg == 6) ? out_ax12_enb :
                        (state_reg == 7) ? out_ax34_enb :
                        (state_reg == 8) ? out_bx12_enb :
                        (state_reg == 9) ? out_bx34_enb : 0 ;

    register #(1) reg_s2mm_valid(aclk, aresetn, 1'b0, s2mm_valid, s2mm_valid_reg); 
    assign s2mm_last = ((state_reg == 9) && (out_bx34_addrb == 1022)) ? 1 : 0;
    register #(1) reg_s2mm_last(aclk, aresetn, 1'b0, s2mm_last, s2mm_last_reg);

    // *** KeyGenCGGI **********************************************************************************************************************************************
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
    KeyGenCGGI_0
    (
        .clk(aclk),
        .rst_n(aresetn),
        .en(1'b1),
        .clr(1'b0),
        .ready(KeyGenCGGI_ready),
        .start(KeyGenCGGI_start),
        .done(KeyGenCGGI_done),

        .in_parbit_ena(in_parbit_ena),
        .in_parbit_addra(in_parbit_addra),
        .in_parbit_dina(in_parbit_dina),
        .in_parbit_wea(in_parbit_wea),

        .in_sk_ena(in_sk_ena),
        .in_sk_addra(in_sk_addra),
        .in_sk_dina(in_sk_dina),
        .in_sk_wea(in_sk_wea),

        .in_w_ena(in_w_ena),
        .in_w_addra(in_w_addra),
        .in_w_dina(in_w_dina),
        .in_w_wea(in_w_wea),

        .out_ax12_enb(out_ax12_enb),
        .out_ax12_addrb(out_ax12_addrb),
        .out_ax12_doutb(out_ax12_doutb),

        .out_ax34_enb(out_ax34_enb),
        .out_ax34_addrb(out_ax34_addrb),
        .out_ax34_doutb(out_ax34_doutb),

        .out_bx12_enb(out_bx12_enb),
        .out_bx12_addrb(out_bx12_addrb),
        .out_bx12_doutb(out_bx12_doutb),

        .out_bx34_enb(out_bx34_enb),
        .out_bx34_addrb(out_bx34_addrb),
        .out_bx34_doutb(out_bx34_doutb)
    );

    // *** S2MM FIFO ************************************************************
    // xpm_fifo_axis: AXI Stream FIFO
    // Xilinx Parameterized Macro, version 2018.3
    xpm_fifo_axis
    #(
        .CDC_SYNC_STAGES(2),                 // DECIMAL
        .CLOCKING_MODE("common_clock"),      // String
        .ECC_MODE("no_ecc"),                 // String
        .FIFO_DEPTH(4096),                    // DECIMAL, depth 256 elemen 
        .FIFO_MEMORY_TYPE("auto"),           // String
        .PACKET_FIFO("false"),               // String
        .PROG_EMPTY_THRESH(10),              // DECIMAL
        .PROG_FULL_THRESH(10),               // DECIMAL
        .RD_DATA_COUNT_WIDTH(1),             // DECIMAL
        .RELATED_CLOCKS(0),                  // DECIMAL
        .SIM_ASSERT_CHK(0),                  // DECIMAL
        .TDATA_WIDTH(64),                    // DECIMAL, data width 64 bit
        .TDEST_WIDTH(1),                     // DECIMAL
        .TID_WIDTH(1),                       // DECIMAL
        .TUSER_WIDTH(1),                     // DECIMAL
        .USE_ADV_FEATURES("0004"),           // String, write data count
        .WR_DATA_COUNT_WIDTH(13)              // DECIMAL, width log2(256)+1=9 
    )
    xpm_fifo_axis_1
    (
        .almost_empty_axis(), 
        .almost_full_axis(), 
        .dbiterr_axis(), 
        .prog_empty_axis(), 
        .prog_full_axis(), 
        .rd_data_count_axis(), 
        .sbiterr_axis(), 
        .injectdbiterr_axis(1'b0), 
        .injectsbiterr_axis(1'b0), 
    
        .s_aclk(aclk), // aclk
        .m_aclk(aclk), // aclk
        .s_aresetn(aresetn), // aresetn
        
        .s_axis_tready(s2mm_ready), // ready    
        .s_axis_tdata(s2mm_data), // data
        .s_axis_tvalid(s2mm_valid_reg), // valid
        .s_axis_tdest(1'b0), 
        .s_axis_tid(1'b0), 
        .s_axis_tkeep(8'hff), 
        .s_axis_tlast(s2mm_last_reg),
        .s_axis_tstrb(8'hff), 
        .s_axis_tuser(1'b0), 
        
        .m_axis_tready(m_axis_tready), // ready  
        .m_axis_tdata(m_axis_tdata), // data
        .m_axis_tvalid(m_axis_tvalid), // valid
        .m_axis_tdest(), 
        .m_axis_tid(), 
        .m_axis_tkeep(), 
        .m_axis_tlast(m_axis_tlast), 
        .m_axis_tstrb(), 
        .m_axis_tuser(),  
        
        .wr_data_count_axis() // data count
    );
    
    // *** ILA ************************************************************
    
    ila_0 ila (
        .clk(aclk), // input wire clk
    
    
        .probe0(s_axis_tready), // input wire [0:0]  probe0  
        .probe1(s_axis_tdata), // input wire [63:0]  probe1 
        .probe2(s_axis_tvalid), // input wire [0:0]  probe2 
        .probe3(s_axis_tlast), // input wire [0:0]  probe3 
        .probe4(m_axis_tready), // input wire [0:0]  probe4 
        .probe5(m_axis_tdata), // input wire [63:0]  probe5 
        .probe6(m_axis_tvalid), // input wire [0:0]  probe6 
        .probe7(m_axis_tlast) // input wire [0:0]  probe7
    );

endmodule