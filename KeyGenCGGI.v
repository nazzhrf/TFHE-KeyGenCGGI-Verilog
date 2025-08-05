`timescale 1ns / 1ps
`include "defines.v"

module KeyGenCGGI
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
    input wire                          clk,
    input wire                          rst_n,
    input wire                          en,
    input wire                          clr,
    // *** Control and status port ***
    output wire                         ready,
    input wire                          start,
    output wire                         done,
    // *** INPUT BRAM parameters and bit message port ***
    input wire                          in_parbit_ena,
    input wire [ADDR_PARAM_WIDTH-1:0]   in_parbit_addra,
    input wire [BRAM_MAX_WIDTH-1:0]     in_parbit_dina,
    input wire [7:0]                    in_parbit_wea,
    // *** INPUT BRAM secret key port ***
    input wire                          in_sk_ena,
    input wire [ADDR_MAX_WIDTH-1:0]     in_sk_addra,
    input wire [BRAM_MAX_WIDTH-1:0]     in_sk_dina,
    input wire [7:0]                    in_sk_wea,
    // *** INPUT BRAM omega port ***
    input wire                          in_w_ena,
    input wire [ADDR_MAX_WIDTH+1:0]     in_w_addra,
    input wire [BRAM_MAX_WIDTH-1:0]     in_w_dina,
    input wire [7:0]                    in_w_wea,
    // *** OUTPUT BRAM  [A(X)_1 and A(X)_2] BRAM 1 ***
    input wire                          out_ax12_enb,
    input wire [ADDR_MAX_WIDTH-1:0]     out_ax12_addrb,
    output wire [BRAM_MAX_WIDTH-1:0]    out_ax12_doutb,
    // *** OUTPUT BRAM  [A(X)_3 and A(X)_4] BRAM 2 ***
    input wire                          out_ax34_enb,
    input wire [ADDR_MAX_WIDTH-1:0]     out_ax34_addrb,
    output wire [BRAM_MAX_WIDTH-1:0]    out_ax34_doutb,
    // *** OUTPUT BRAM  [B(X)_1 and B(X)_2] BRAM 3 ***
    input wire                          out_bx12_enb,
    input wire [ADDR_MAX_WIDTH-1:0]     out_bx12_addrb,
    output wire [BRAM_MAX_WIDTH-1:0]    out_bx12_doutb,
    // *** OUTPUT BRAM  [B(X)_3 and B(X)_4] BRAM 4 ***
    input wire                          out_bx34_enb,
    input wire [ADDR_MAX_WIDTH-1:0]     out_bx34_addrb,
    output wire [BRAM_MAX_WIDTH-1:0]    out_bx34_doutb
);

   // *** WIRE TO CONTROL ANOTHER PORT OF BRAM ********************************************************************************************************************************
    // Wire for port b of BRAM parameter and bit message
    wire                        in_parbit_enb;
    wire [ADDR_PARAM_WIDTH-1:0] in_parbit_addrb;
    wire [BRAM_MAX_WIDTH-1:0]   in_parbit_doutb;
    // Wire for port b of BRAM secret key
    wire                        in_sk_enb;
    wire [ADDR_MAX_WIDTH-1:0]   in_sk_addrb;
    wire [BRAM_MAX_WIDTH-1:0]   in_sk_doutb;
    // Wire for port b of BRAM omega 
    wire                        in_w_enb;
    wire [ADDR_MAX_WIDTH+1:0]   in_w_addrb;
    wire [BRAM_MAX_WIDTH-1:0]   in_w_doutb;
    // Wire for port a of BRAM ax_1 & ax_2
    wire                        out_ax12_ena;
    wire [ADDR_MAX_WIDTH-1:0]   out_ax12_addra;
    wire [7:0]                  out_ax12_wea;
    wire [BRAM_MAX_WIDTH-1:0]   out_ax12_dina;
    // Wire for port a of BRAM ax_3 & ax_4
    wire                        out_ax34_ena;
    wire [ADDR_MAX_WIDTH-1:0]   out_ax34_addra;
    wire [7:0]                  out_ax34_wea;
    wire [BRAM_MAX_WIDTH-1:0]   out_ax34_dina;
    // Wire for port a of BRAM ex_1 & ex_2
    wire                        out_bx12_ena;
    wire [ADDR_MAX_WIDTH-1:0]   out_bx12_addra;
    wire [7:0]                  out_bx12_wea;
    wire [BRAM_MAX_WIDTH-1:0]   out_bx12_dina;
    // Wire for port a of BRAM rlwe4
    wire                        out_bx34_ena;
    wire [ADDR_MAX_WIDTH-1:0]   out_bx34_addra;
    wire [7:0]                  out_bx34_wea;
    wire [BRAM_MAX_WIDTH-1:0]   out_bx34_dina;

    // *** WIRE FOR BRAM A(X) AND E(X) ********************************************************************************************************************************
    // ax
    wire                           ax_ena;
    wire [AX_EX_MAX_WIDTH-1:0]     ax_addra;
    wire [AX_EX_MAX_WIDTH-1:0]     ax_dina;
    wire [CNTR_WIDTH-1:0]          ax_wea;
    wire                           ax_enb;
    wire [AX_EX_MAX_WIDTH-1:0]     ax_addrb;
    wire [AX_EX_MAX_WIDTH-1:0]     ax_doutb;
    // ex
    wire                           ex_ena;
    wire [AX_EX_MAX_WIDTH-1:0]     ex_addra;
    wire [AX_EX_MAX_WIDTH-1:0]     ex_dina;
    wire [CNTR_WIDTH-1:0]          ex_wea;
    wire                           ex_enb;
    wire [AX_EX_MAX_WIDTH-1:0]     ex_addrb;
    wire [AX_EX_MAX_WIDTH-1:0]     ex_doutb;

    // *** INPUT PARAMETER AND BIT MESSAGE BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(640),                   // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(4),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(4),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_parbit
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(in_parbit_ena),
        .wea(in_parbit_wea),
        .addra(in_parbit_addra),
        .dina(in_parbit_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(in_parbit_enb),
        .web(0),
        .addrb(in_parbit_addrb),
        .dinb(0),
        .doutb(in_parbit_doutb)
    );

    // ***  INPUT SECRET KEY BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(65536),                   // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_sk
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(in_sk_ena),
        .wea(in_sk_wea),
        .addra(in_sk_addra),
        .dina(in_sk_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(in_sk_enb),
        .web(0),
        .addrb(in_sk_addrb),
        .dinb(0),
        .doutb(in_sk_doutb)
    );

    // ***  INPUT OMEGA BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(137280),                   // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(12),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(12),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_omega
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(in_w_ena),
        .wea(in_w_wea),
        .addra(in_w_addra),
        .dina(in_w_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(in_w_enb),
        .web(0),
        .addrb(in_w_addrb),
        .dinb(0),
        .doutb(in_w_doutb)
    );

    // ***  A(X) BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(131072),                // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(128),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(128),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(128),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(128),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_ax
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(ax_ena),
        .wea(ax_wea),
        .addra(ax_addra),
        .dina(ax_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(ax_enb),
        .web(0),
        .addrb(ax_addrb),
        .dinb(0),
        .doutb(ax_doutb)
    );

    // ***  E(X) BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(131072),                // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(128),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(128),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(128),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(128),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_ex
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(ex_ena),
        .wea(ex_wea),
        .addra(ex_addra),
        .dina(ex_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(ex_enb),
        .web(0),
        .addrb(ex_addrb),
        .dinb(0),
        .doutb(ex_doutb)
    );

    // ***  OUTPUT A(X)_1 & A(X)_2 BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(65536),                   // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_ax12
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(out_ax12_ena),
        .wea(out_ax12_wea),
        .addra(out_ax12_addra),
        .dina(out_ax12_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(out_ax12_enb),
        .web(0),
        .addrb(out_ax12_addrb),
        .dinb(0),
        .doutb(out_ax12_doutb)
    );

    // ***  OUTPUT A(X)_3 & A(X)_4 BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(65536),                   // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_ax34
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(out_ax34_ena),
        .wea(out_ax34_wea),
        .addra(out_ax34_addra),
        .dina(out_ax34_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(out_ax34_enb),
        .web(0),
        .addrb(out_ax34_addrb),
        .dinb(0),
        .doutb(out_ax34_doutb)
    );

    // ***  OUTPUT B(X)_1 & B(X)_2 BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(65536),                   // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_bx12
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(out_bx12_ena),
        .wea(out_bx12_wea),
        .addra(out_bx12_addra),
        .dina(out_bx12_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(out_bx12_enb),
        .web(0),
        .addrb(out_bx12_addrb),
        .dinb(0),
        .doutb(out_bx12_doutb)
    );

    // ***  OUTPUT B(X)_3 & B(X)_4 BRAM ********************************************************************************************************************************
    // xpm_memory_tdpram: True Dual Port RAM
    // Xilinx Parameterized Macro, version 2018.3
    xpm_memory_tdpram
    #(
        // Common module parameters
        .MEMORY_SIZE(65536),                   // DECIMAL, size: 8x64bit= 512 bits
        .MEMORY_PRIMITIVE("auto"),           // String
        .CLOCKING_MODE("common_clock"),      // String, "common_clock"
        .MEMORY_INIT_FILE("none"),           // String
        .MEMORY_INIT_PARAM("0"),             // String      
        .USE_MEM_INIT(1),                    // DECIMAL
        .WAKEUP_TIME("disable_sleep"),       // String
        .MESSAGE_CONTROL(0),                 // DECIMAL
        .AUTO_SLEEP_TIME(0),                 // DECIMAL          
        .ECC_MODE("no_ecc"),                 // String
        .MEMORY_OPTIMIZATION("true"),        // String              
        .USE_EMBEDDED_CONSTRAINT(0),         // DECIMAL
        
        // Port A module parameters
        .WRITE_DATA_WIDTH_A(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_A(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_A(8),              // DECIMAL
        .ADDR_WIDTH_A(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_A("0"),            // String
        .READ_LATENCY_A(1),                  // DECIMAL
        .WRITE_MODE_A("write_first"),        // String
        .RST_MODE_A("SYNC"),                 // String
        
        // Port B module parameters  
        .WRITE_DATA_WIDTH_B(64),             // DECIMAL, data width: 64-bit
        .READ_DATA_WIDTH_B(64),              // DECIMAL, data width: 64-bit
        .BYTE_WRITE_WIDTH_B(8),              // DECIMAL
        .ADDR_WIDTH_B(10),                    // DECIMAL, clog2(512/64)=clog2(8)= 3
        .READ_RESET_VALUE_B("0"),            // String
        .READ_LATENCY_B(1),                  // DECIMAL
        .WRITE_MODE_B("write_first"),        // String
        .RST_MODE_B("SYNC")                  // String
    )
    xpm_memory_tdpram_bx34
    (
        .sleep(1'b0),
        .regcea(1'b1), //do not change
        .injectsbiterra(1'b0), //do not change
        .injectdbiterra(1'b0), //do not change   
        .sbiterra(), //do not change
        .dbiterra(), //do not change
        .regceb(1'b1), //do not change
        .injectsbiterrb(1'b0), //do not change
        .injectdbiterrb(1'b0), //do not change              
        .sbiterrb(), //do not change
        .dbiterrb(), //do not change
        
        // Port A module ports
        .clka(clk),
        .rsta(~rst_n),
        .ena(out_bx34_ena),
        .wea(out_bx34_wea),
        .addra(out_bx34_addra),
        .dina(out_bx34_dina),
        .douta(),
        
        // Port B module ports
        .clkb(clk),
        .rstb(~rst_n),
        .enb(out_bx34_enb),
        .web(0),
        .addrb(out_bx34_addrb),
        .dinb(0),
        .doutb(out_bx34_doutb)
    );

    // *** CONNECTION TO ALL MODULE ********************************************************************************************************************************
    // Mersenne Twister
    wire mt_seed_start, mt_output_axis_tready ;
    wire [DATA_WIDTH-1:0] mt1_seed_val, mt2_seed_val, mt3_seed_val, mt4_seed_val;
    wire mt1_busy, mt2_busy, mt3_busy, mt4_busy;
    wire mt1_output_axis_tvalid, mt2_output_axis_tvalid, mt3_output_axis_tvalid, mt4_output_axis_tvalid;
    wire [DATA_WIDTH-1:0] mt1_output_axis_tdata, mt2_output_axis_tdata, mt3_output_axis_tdata, mt4_output_axis_tdata;
    // Gng
    wire gng_ce, gng1_valid_out, gng2_valid_out, gng3_valid_out, gng4_valid_out;
    wire [DATA_WIDTH-1:0] gng1_data_out, gng2_data_out, gng3_data_out, gng4_data_out ;
    // PreCompute128
    wire PC_start, PC_ready, PC_done;
    wire signed [DATA_WIDTH-1:0] PC_Bg, PC_Q ;
    wire signed [DATA_WIDTH-1:0] PC_GPow0, PC_GPow1, PC_GPow2 ; 
    // ModAddFastEq 
    wire signed [DATA_WIDTH-1:0] out1, out2, out3, out4 ;
    // NTTN Module
    wire ntt_trigger ;
    wire nttn_load_w, nttn_load_data, nttn_start ; 
    wire nttn_ax_1_done, nttn_ax_2_done, nttn_ax_3_done, nttn_ax_4_done ;
    wire nttn_sx_1_done, nttn_sx_2_done, nttn_sx_3_done, nttn_sx_4_done ;
    wire signed [DATA_WIDTH-1:0] nttn_ax_1_din, nttn_ax_2_din, nttn_ax_3_din, nttn_ax_4_din ; 
    wire signed [DATA_WIDTH-1:0] nttn_sx_1_din ;
    wire signed [DATA_WIDTH-1:0] nttn_ax_1_dout, nttn_ax_2_dout, nttn_ax_3_dout, nttn_ax_4_dout;
    wire signed [DATA_WIDTH-1:0] nttn_sx_1_dout ;
    // Temporary wire to calculate B(X)
    wire signed [DATA_WIDTH-1:0] bx1, bx2, bx3, bx4;
    
    // *** REGISTER TO SAVED BRAM READ OUTPUT TEMPORARELY *********************************************************************************************************
    reg signed [DATA_WIDTH-1:0] reg_N, reg_Q, reg_baseG, reg_digitsG, reg_digitsG2 ;
    reg signed [DATA_WIDTH-1:0] reg_mt1_seed, reg_mt2_seed, reg_mt3_seed, reg_mt4_seed ;
    reg signed [2*DATA_WIDTH-1:0] reg_gng1_seed, reg_gng2_seed, reg_gng3_seed, reg_gng4_seed ;
    
    // *** MERSENNE TWISTER MODULE ********************************************************************************************************************************
    MT1997Axis dug1 (
        .clk(clk),
        .rst(~rst_n),
        .seed_val(mt1_seed_val),
        .seed_start(mt_seed_start),
        .output_axis_tdata(mt1_output_axis_tdata),
        .output_axis_tvalid(mt1_output_axis_tvalid),
        .output_axis_tready(mt_output_axis_tready),
        .busy(mt1_busy)
    );
    assign mt1_seed_val = reg_mt1_seed ;

    MT1997Axis dug2 (
        .clk(clk),
        .rst(~rst_n),
        .seed_val(mt2_seed_val),
        .seed_start(mt_seed_start),
        .output_axis_tdata(mt2_output_axis_tdata),
        .output_axis_tvalid(mt2_output_axis_tvalid),
        .output_axis_tready(mt_output_axis_tready),
        .busy(mt2_busy)
    );
    assign mt2_seed_val = reg_mt2_seed; 

    MT1997Axis dug3 (
        .clk(clk),
        .rst(~rst_n),
        .seed_val(mt3_seed_val),
        .seed_start(mt_seed_start),
        .output_axis_tdata(mt3_output_axis_tdata),
        .output_axis_tvalid(mt3_output_axis_tvalid),
        .output_axis_tready(mt_output_axis_tready),
        .busy(mt3_busy)
    );
    assign mt3_seed_val = reg_mt3_seed;

    MT1997Axis dug4 (
        .clk(clk),
        .rst(~rst_n),
        .seed_val(mt4_seed_val),
        .seed_start(mt_seed_start),
        .output_axis_tdata(mt4_output_axis_tdata),
        .output_axis_tvalid(mt4_output_axis_tvalid),
        .output_axis_tready(mt_output_axis_tready),
        .busy(mt4_busy)
    );
    assign mt4_seed_val = reg_mt4_seed;

    // *** GAUSSIAN NOISE MODULE ********************************************************************************************************************************
    gng #
    (
        .INIT_Z1(64'd5030544883981424767),
        .INIT_Z2(64'd1844582927924155008),
        .INIT_Z3(64'd18436106498727503359)
    ) 
    gng1 
    (
        .clk(clk),
        .rstn(rst_n),
        .ce(gng_ce),
        .valid_out(gng1_valid_out),
        .data_out(gng1_data_out)
    );
    
    gng #
    (
        .INIT_Z1(64'd5030521883283424767),
        .INIT_Z2(64'd18445829279364155008),
        .INIT_Z3(64'd18436106298727503359)
    ) 
    gng2 
    (
        .clk(clk),
        .rstn(rst_n),
        .ce(gng_ce),
        .valid_out(gng2_valid_out),
        .data_out(gng2_data_out)
    );

    gng #
    (
        .INIT_Z1(64'd5040221183283424267),
        .INIT_Z2(64'd1854562928976155008),
        .INIT_Z3(64'd18136116598727503359)
    ) 
    gng3 
    (
        .clk(clk),
        .rstn(rst_n),
        .ce(gng_ce),
        .valid_out(gng3_valid_out),
        .data_out(gng3_data_out)
    );

    gng #
    (
        .INIT_Z1(64'd5030521883241424767),
        .INIT_Z2(64'd18445829277364155008),
        .INIT_Z3(64'd18436556298727903359)
    ) 
    gng4 
    (
        .clk(clk),
        .rstn(rst_n),
        .ce(gng_ce),
        .valid_out(gng4_valid_out),
        .data_out(gng4_data_out)
    );

    // *** PRECOMPUTE128 MODULE ******************************************************************************************************************************** 
    PreCompute128 #
    (
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    )
    precompute 
    (
        .clk(clk),
        .rst(rst_n),
        .start(PC_start),
        .Bg(PC_Bg),
        .Q(PC_Q),
        .GPow0(PC_GPow0),
        .GPow1(PC_GPow1),
        .GPow2(PC_GPow2),
        .ready(PC_ready),
        .done(PC_done)
    );
    assign PC_Bg = reg_baseG ;
    assign PC_Q = reg_Q ;

    // *** ModAddFastEq MODULE ********************************************************************************************************************************

    ModAddFastEq #
    (
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    )
    ModAddFastEq1 
    (
        .a(reg_a_mask[127:96]),
        .b(PC_GPow0),
        .Q(PC_Q),
        .out(out1)
    );

    ModAddFastEq #
    (
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    )
    ModAddFastEq2 
    (
        .a(reg_e_mask[95:64]),
        .b(PC_GPow0),
        .Q(PC_Q),
        .out(out2)
    );

    ModAddFastEq #
    (
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    )
    ModAddFastEq3 
    (
        .a(reg_a_mask[63:32]),
        .b(PC_GPow0),
        .Q(PC_Q),
        .out(out3)
    );

    ModAddFastEq #
    (
        .DATA_WIDTH(DATA_WIDTH),
        .n_WIDTH(n_WIDTH)
    )
    ModAddFastEq4 
    (
        .a(reg_e_mask[31:0]),
        .b(PC_GPow0),
        .Q(PC_Q),
        .out(out4)
    );

    // *** NTT MODULE ********************************************************************************************************************************
    NTTN NTT_AX_1
    (
        .clk(clk),
        .reset(~rst_n),
        .load_w(nttn_load_w),
        .load_data(nttn_load_data),
        .start(nttn_start),
        .start_intt(0),
        .din(nttn_ax_1_din),
        .done(nttn_ax_1_done),
        .dout(nttn_ax_1_dout)
    );

    NTTN NTT_AX_2
    (
        .clk(clk),
        .reset(~rst_n),
        .load_w(nttn_load_w),
        .load_data(nttn_load_data),
        .start(nttn_start),
        .start_intt(0),
        .din(nttn_ax_2_din),
        .done(nttn_ax_2_done),
        .dout(nttn_ax_2_dout)
    );

    NTTN NTT_AX_3
    (
        .clk(clk),
        .reset(~rst_n),
        .load_w(nttn_load_w),
        .load_data(nttn_load_data),
        .start(nttn_start),
        .start_intt(0),
        .din(nttn_ax_3_din),
        .done(nttn_ax_3_done),
        .dout(nttn_ax_3_dout)
    );

    NTTN NTT_AX_4
    (
        .clk(clk),
        .reset(~rst_n),
        .load_w(nttn_load_w),
        .load_data(nttn_load_data),
        .start(nttn_start),
        .start_intt(0),
        .din(nttn_ax_4_din),
        .done(nttn_ax_4_done),
        .dout(nttn_ax_4_dout)
    );

    NTTN NTT_SX_1
    (
        .clk(clk),
        .reset(~rst_n),
        .load_w(nttn_load_w),
        .load_data(nttn_load_data),
        .start(nttn_start),
        .start_intt(0),
        .din(nttn_sx_1_din),
        .done(nttn_sx_1_done),
        .dout(nttn_sx_1_dout)
    );

    // *** CONTROL & STATUS SIGNAL ********************************************************************************************************************************************************
    // Counter for main controller
    reg [CNTR_WIDTH-1:0] cntr_main_reg, cntr_addr_mt_gng, cntr_in_ntt, cntr_out_ntt ;  
    reg ax_ex_first_assign ;
    wire cntr_addr_mt_gng_done, cntr_in_ntt_done;
    // FSM for main counter
    always @(posedge clk) begin
        if (!rst_n || clr)
        begin
            cntr_main_reg <= 0;
        end
        else if (start)
        begin
            cntr_main_reg <= cntr_main_reg + 1;
        end
        else if (cntr_main_reg >= 1 && !done)
        begin
            cntr_main_reg <= cntr_main_reg + 1;
        end
        else if (done)
        begin
            cntr_main_reg <= 0;
        end
    end
    // FSM for mt and gng counter
    always @(posedge clk) begin
        if (!rst_n || clr)
        begin
            cntr_addr_mt_gng <= 0;
            ax_ex_first_assign <= 0;
        end
        else if (gng1_valid_out && mt1_output_axis_tvalid && !cntr_addr_mt_gng_done)
        begin
            cntr_addr_mt_gng <= cntr_addr_mt_gng + 1;
        end
        else if (cntr_addr_mt_gng == 1025 && !cntr_addr_mt_gng_done)
        begin
            ax_ex_first_assign <= 1;
        end
        else if (cntr_addr_mt_gng_done)
        begin
            cntr_addr_mt_gng <= 0;
        end
    end
    // FSM to load w and a(x) from BRAM and pass it as NTT Input
    always @(posedge clk) begin
        if (!rst_n || clr)
        begin
            cntr_in_ntt <= 0;
        end
        else if (ntt_trigger)
        begin
            cntr_in_ntt <= cntr_in_ntt + 1;
        end
        else if (cntr_in_ntt >= 1 && !cntr_in_ntt_done)
        begin
            cntr_in_ntt <= cntr_in_ntt + 1;
        end
        else if (cntr_in_ntt_done)
        begin
            cntr_in_ntt <= 0;
        end
    end
    // FSM to load NTTN output and pass it to BRAM
    always @(posedge clk) begin
        if (!rst_n || clr)
        begin
            cntr_out_ntt <= 0;
        end
        else if (nttn_ax_1_done)
        begin
            cntr_out_ntt <= cntr_out_ntt + 1;
        end
        else if (cntr_out_ntt >= 1 && cntr_out_ntt <= 1027)
        begin
            cntr_out_ntt <= cntr_out_ntt + 1;
        end
        else if (cntr_out_ntt > 1027)
        begin
            cntr_out_ntt <= 0;
        end
    end

    // *** CONTROL UNIT *****************************************************************************************************************************************************
    reg signed [2*DATA_WIDTH-1:0] reg_as1, reg_as2, reg_as3, reg_as4; 
    reg signed [DATA_WIDTH-1:0] reg_nttn_ax_1_din, reg_nttn_ax_2_din, reg_nttn_ax_3_din, reg_nttn_ax_4_din;
    reg signed [DATA_WIDTH-1:0] reg_nttn_sx_1_din ;
    reg signed [4*DATA_WIDTH-1:0] reg_a_mask, reg_e_mask ;
    
    assign ready = (cntr_main_reg == 1) ? 1 : 0 ;
    // FSM for pipelining input register to module top_forward_vae
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
        begin
            reg_as1 <= 0 ; reg_as2 <= 0 ;
            reg_as3 <= 0 ; reg_as4 <= 0 ;
        end
        else if (cntr_main_reg >= 2 && cntr_main_reg < 3) 
        begin
            reg_N <= in_parbit_doutb[63:32] ;
            reg_Q <= in_parbit_doutb[31:0] ; 
        end 
        else if (cntr_main_reg >= 3 && cntr_main_reg < 4) 
        begin
            reg_baseG <= in_parbit_doutb[63:32] ;
        end
        else if (cntr_main_reg >= 4 && cntr_main_reg < 5) 
        begin
            reg_digitsG <= in_parbit_doutb[63:32] ;
            reg_digitsG2 <= in_parbit_doutb[31:0] ; 
        end
        else if (cntr_main_reg >= 5 && cntr_main_reg < 6) 
        begin
            reg_mt1_seed <= in_parbit_doutb[63:32] ;
            reg_mt2_seed <= in_parbit_doutb[31:0] ; 
        end
        else if (cntr_main_reg >= 6 && cntr_main_reg < 7) 
        begin
            reg_mt3_seed <= in_parbit_doutb[63:32] ;
            reg_mt4_seed <= in_parbit_doutb[31:0] ; 
        end
        else if (cntr_main_reg >= 7 && cntr_main_reg < 8) 
        begin
            reg_gng1_seed <= {32'd0, in_parbit_doutb[63:32]} ;
            reg_gng2_seed <= {32'd0, in_parbit_doutb[31:0]} ; 
        end
        else if (cntr_main_reg >= 8 && cntr_main_reg < 9) 
        begin
            reg_gng3_seed <= {32'd0, in_parbit_doutb[63:32]} ;
            reg_gng4_seed <= {32'd0, in_parbit_doutb[31:0]} ; 
        end
        else if (cntr_addr_mt_gng >= 20 && cntr_addr_mt_gng < 21) 
        begin
            reg_a_mask <= ax_dina ;
            reg_e_mask <= ex_dina ; 
        end 
        else if (cntr_in_ntt >= 2 && cntr_in_ntt <= 2145) 
        begin
            reg_nttn_ax_1_din <= in_w_doutb[63:32] ;
            reg_nttn_ax_2_din <= in_w_doutb[63:32] ;
            reg_nttn_ax_3_din <= in_w_doutb[63:32] ;
            reg_nttn_ax_4_din <= in_w_doutb[63:32] ;
            reg_nttn_sx_1_din <= in_w_doutb[63:32] ; 
        end
        else if (cntr_in_ntt >= 2146 && cntr_in_ntt < 2147) 
        begin
            reg_nttn_ax_1_din <= reg_Q ;
            reg_nttn_ax_2_din <= reg_Q ;
            reg_nttn_ax_3_din <= reg_Q ;
            reg_nttn_ax_4_din <= reg_Q ;
            reg_nttn_sx_1_din <= reg_Q ; 
        end
        else if (cntr_in_ntt >= 2147 && cntr_in_ntt < 2148) 
        begin
            reg_nttn_ax_1_din <= reg_Q ;
            reg_nttn_ax_2_din <= reg_Q ;
            reg_nttn_ax_3_din <= reg_Q ;
            reg_nttn_ax_4_din <= reg_Q ;
            reg_nttn_sx_1_din <= reg_Q ; 
        end
        else if (cntr_in_ntt >= 2150 && cntr_in_ntt <= 3173) 
        begin
            reg_nttn_ax_1_din <= ax_doutb[127:96] ;
            reg_nttn_ax_2_din <= ax_doutb[95:64] ;
            reg_nttn_ax_3_din <= ax_doutb[63:32] ;
            reg_nttn_ax_4_din <= ax_doutb[31:0] ;
            reg_nttn_sx_1_din <= in_sk_doutb[63:32] ; 
        end
        else if (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) 
        begin
            reg_as1 <= nttn_ax_1_dout * nttn_sx_1_dout ;
            reg_as2 <= nttn_ax_2_dout * nttn_sx_1_dout ;
            reg_as3 <= nttn_ax_3_dout * nttn_sx_1_dout ;
            reg_as4 <= nttn_ax_4_dout * nttn_sx_1_dout ;
        end
    end

    // *** CLOCK 1-7 : READ PARAM BRAM INPUT ********************************************************************************************************************************
    assign in_parbit_enb    = (cntr_main_reg >= 1 && cntr_main_reg <= 7) ? 1: 0 ;
    assign in_parbit_addrb  = (cntr_main_reg == 1) ? 0 :
                              (cntr_main_reg == 2) ? 1 :
                              (cntr_main_reg == 3) ? 2 :
                              (cntr_main_reg == 4) ? 3 :
                              (cntr_main_reg == 5) ? 4 : 
                              (cntr_main_reg == 6) ? 5 :
                              (cntr_main_reg == 7) ? 6 : 0; // 7 to activate signal that trigger the next process
    // *** ASSIGN BRAM OUTPUT TO WIRE TEMPORARELY ********************************************************************************************************************************
    // (look at the FSM)
    
    // *** CLOCK 3 : ACTIVATE PRECOMPUTE128 MODULE TO CALCULATE GADGET MATRIX ********************************************************************************************************************************
    assign PC_start    = (cntr_main_reg == 3) ? 1 : 0;

    // *** CLOCK 7 : ACTIVATE DUG AND GNG , THEN WAIT UNTIL THEIR PRODUCES VALID NUMBER ********************************************************************************************************************************
    assign mt_seed_start = (cntr_main_reg == 7) ? 1 : 0; 
    assign mt_output_axis_tready = (cntr_main_reg >= 7) ? 1 : 0;
    assign gng_ce = (cntr_main_reg >= 7) ? 1 : 0;
    // When DUG and GNG outputs already valid, counter cntr_addr_mt_gng will start counting (see FSM for mt and gng)

    // *** AFTER DUG AND GNG PRODUCES VALID NUMBER, STORED 1024 VALID NUMBER AS [A(X), B(X)] IN BRAM ********************************************************************************************************************************
    // A(X)
    assign ax_ena    = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1025) ? 1: 0 ;   
    assign ax_wea    = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1025) ? 16'hffff: 0 ;
    assign ax_addra  = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1024) ? (cntr_addr_mt_gng-1) : 20;
    assign ax_dina   = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1024) ? {mt1_output_axis_tdata, mt2_output_axis_tdata, mt3_output_axis_tdata, mt4_output_axis_tdata} : {out1, reg_a_mask[95:64], out3, reg_a_mask[31:0]} ;
    // S(X)
    assign ex_ena    = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1025) ? 1: 0 ;   
    assign ex_wea    = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1025) ? 16'hffff: 0 ;
    assign ex_addra  = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1024) ? (cntr_addr_mt_gng-1) : 20;
    assign ex_dina   = (cntr_addr_mt_gng >= 1 && cntr_addr_mt_gng <= 1024) ? {gng1_data_out, gng2_data_out, gng3_data_out, gng4_data_out} : {reg_e_mask[127:96], out2, reg_e_mask[63:32], out4} ;
    // One clock after counter "cntr_addr_mt_gng" has value 1025, the register "ax_ex_first_assign" will has active high value

    // *** ADD THE MASKING COEFF IN ADDRESS 20 OF A(X) AND E(X)********************************************************************************************************************************
    // Masking coeff : Coefficient of polynomials A(X) and B(X) that multiply with gadget matrix, can only exist one masking coefficient.
    // Usually for even ciphertext (0 and 2), the masking coeff will be one coeff of A(x) 
    // Usually for odd ciphertext (1 and 3), the masking coeff will be one coeff of B(x)
    // We choose the x^19 degree coeff. This coeff is stored in address 20.
    // So when the counter "cntr_addr_mt_gng" reach 20, we will assign the value to some signal.
    // (si this in FSM)
    // This signal will fed as inputs to ModAddFastEq module that will multiply it with the relevant gadget matrix values.
    // The result from ModAddFastEq later will be stored again in addres 20 of BRAM.
    // Here's the trick. When counter "cntr_addr_mt_gng" reach 1025, the address will be 20, - 
    // - and the corresponding data fed to port A BRAM when that time happen is ModAddFastEq results.
    assign cntr_addr_mt_gng_done = (cntr_main_reg > 1658) ? 1: 0 ;

    // *** TRANSFORM A(X) AND E(X) INTO NTT ********************************************************************************************************************************
    // Activate the signal to start the omega stream as input to NTT modules
    assign ntt_trigger     = (cntr_addr_mt_gng == 1026) ? 1 : 0 ;
    // Signal ntt_trigger will start the counter "cntr_in_ntt".
    // When counter "cntr_in_ntt" in the counting process, operation to read port b of bram omega active
    assign in_w_enb        = (cntr_in_ntt >= 1 && cntr_in_ntt <= 2145) ? 1 : 0 ;
    assign in_w_addrb      = (cntr_in_ntt >= 1 && cntr_in_ntt <= 2145) ? (cntr_in_ntt-1) : 0 ;
    // We have to remember that : 
    //  > when cntr_in_ntt = 1, the addr = 0. The bram needs one clock cycle to read the values stored in certain address,
    //  > SO we can only read the doutb for addr 0 in one clock cycles after, that is when cntr_in_ntt = 2.
    //  > That means the bram start produce the valid doutb stream from cntr_in_ntt = 2
    // BUT, we have to pass it again to register. Register will delay one clock, -  
    // - this means the valid nttn_din streams start on cntr_in_ntt = 3 
    // That also means we have to activate nttn_load_w in cntr_in_ntt = 2 
    assign nttn_load_w     = (cntr_in_ntt == 2) ? 1 : 0 ;
    // In cntr_in_ntt = 2147, the last value of omega pass as nttn_din.
    // In this time, the operation to read port b of bram ax and sx active with the corresponding address
    assign ax_enb   = (cntr_in_ntt >= 2150 && cntr_in_ntt <= 3173) ? 1 : 0 ;
    assign ax_addrb = (cntr_in_ntt >= 2150 && cntr_in_ntt <= 3173) ? (cntr_in_ntt-2150) : 0 ;
    assign in_sk_enb   = (cntr_in_ntt >= 2150 && cntr_in_ntt <= 3173) ? 1 : 0 ;
    assign in_sk_addrb = (cntr_in_ntt >= 2150 && cntr_in_ntt <= 3173) ? (cntr_in_ntt-2150) : 0 ;
    // The ax_doutb become valid from cntr_in_ntt = 2151
    // Because we will assign the value to register, then only after that, the register's value is assign as nttn_din , -
    // Then the streams nttn_din only valid from cntr_in_ntt = 2152
    // With that, we activate the signal nttn_load_data in cntr_in_ntt = 2151
    assign cntr_in_ntt_done = (cntr_main_reg > 4834) ? 1: 0 ;
    assign nttn_load_data  = (cntr_in_ntt == 2150) ? 1 : 0 ;
    // Start the NTTN modules, assign the register's value to nttn_din signal
    assign nttn_start      = (cntr_in_ntt == 3175) ? 1 : 0 ;
    assign nttn_ax_1_din   = reg_nttn_ax_1_din ;
    assign nttn_ax_2_din   = reg_nttn_ax_2_din ;
    assign nttn_ax_3_din   = reg_nttn_ax_3_din ;
    assign nttn_ax_4_din   = reg_nttn_ax_4_din ;
    assign nttn_sx_1_din   = reg_nttn_sx_1_din ;
    // The output of nttn modules become valid one cycles after signal nttn_done active

    // *** STORED A(X), CALCULATE B(X)=A(X)*S(X)+E(X), AND STORED B(X) ********************************************************************************************************************************
    // When signal nttn_ax_1_done active, start the counter "cntr_out_ntt"
    // Stored A(X) in each A(X) BRAM
    assign out_ax12_ena    = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? 1: 0 ;   
    assign out_ax12_wea    = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? 8'b11111111: 0 ;
    assign out_ax12_addra  = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? (cntr_out_ntt-1) : 0;
    assign out_ax12_dina   = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? {nttn_ax_1_dout, nttn_ax_2_dout} : 0 ; 
    assign out_ax34_ena    = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? 1: 0 ;   
    assign out_ax34_wea    = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? 8'b11111111: 0 ;
    assign out_ax34_addra  = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? (cntr_out_ntt-1) : 0;
    assign out_ax34_dina   = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? {nttn_ax_3_dout, nttn_ax_4_dout} : 0 ; 
    // In cntr_out_ntt >= 2 && cntr_out_ntt <= 1025, the value of ax and sx will multiply. This multiply process between 32-bit integer requires one clock cycles.
    // That means, in cntr_out_ntt >= 3 && cntr_out_ntt <= 1026, the valid multiply results will stored in register reg_as
    // In this period of time, we need to adding a*s + e , -
    // In cntr_out_ntt >= 3 && cntr_out_ntt <= 1026, the doutb port of BRAM e(x) must already has valid value
    // That's why we have to activate the operation to read port b of bram E(X) one cycle before, that's it cntr_out_ntt >= 2 && cntr_out_ntt <= 1025
    assign ex_enb          = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? 1: 0 ;
    assign ex_addrb        = (cntr_out_ntt >= 1 && cntr_out_ntt <= 1024) ? (cntr_out_ntt-1) : 0;
    // In ntr_out_ntt >= 3 && cntr_out_ntt <= 1026, both reg_as and ex_doutb has valid values, -
    // We adding it to fulfill the operation B(X) = A(X)*S(X)+E(X)
    assign bx1             = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? (reg_as1[43:12]+ex_doutb[127:96]): 0 ;
    assign bx2             = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? (reg_as2[43:12]+ex_doutb[95:64]): 0 ;
    assign bx3             = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? (reg_as3[43:12]+ex_doutb[63:32]): 0 ;
    assign bx4             = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? (reg_as4[43:12]+ex_doutb[31:0]): 0 ;
    // Addition is simple operation, we expected the results will come out in same clock cycles
    // We need to stored bx_1, bx_2, bx_3, and bx_4 in output bx BRAM
    // Then, we need to activate the access to port a bx BRAM when bx_1, bx_2, bx_3, and bx_4 valid.
    assign out_bx12_ena    = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? 1: 0 ;   
    assign out_bx12_wea    = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? 8'b11111111: 0 ;
    assign out_bx12_addra  = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? (cntr_out_ntt-2) : 0;
    assign out_bx12_dina   = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? {bx1, bx2} : 0 ; 
    assign out_bx34_ena    = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? 1: 0 ;   
    assign out_bx34_wea    = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? 8'b11111111: 0 ;
    assign out_bx34_addra  = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? (cntr_out_ntt-2) : 0;
    assign out_bx34_dina   = (cntr_out_ntt >= 2 && cntr_out_ntt <= 1025) ? {bx3, bx4} : 0 ; 
    // Done signal
    assign done            = (cntr_out_ntt >= 1027) ? 1 : 0 ; 

endmodule