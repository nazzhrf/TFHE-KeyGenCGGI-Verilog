/*
Copyright 2020, Ahmet Can Mert <ahmetcanmert@sabanciuniv.edu>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

`include "defines.v"

module ModRed (
    input clk, reset,
    input [`DATA_SIZE_ARB-1:0] q,
    input [(2*`DATA_SIZE_ARB)-1:0] P,
    output reg [`DATA_SIZE_ARB-1:0] C
);

// Konversi ukuran
// DATA_SIZE_ARB = 30
// W_SIZE = 6
// L_SIZE = 5 (berarti butuh 6 C_reg manual: 0 sampai 5)

// --- Manual wires (ganti array)
wire [59:0] C_reg_0;
wire [54:0] C_reg_1;
wire [49:0] C_reg_2;
wire [44:0] C_reg_3;
wire [39:0] C_reg_4;
wire [31:0] C_reg_5;  // Final stage

assign C_reg_0 = P;

// --- Instansiasi ModRed_sub manual
ModRed_sub #(.CURR_DATA(60), .NEXT_DATA(55)) mrs0 (
    .clk(clk),
    .reset(reset),
    .qH(q[29:6]),
    .T1(C_reg_0),
    .C (C_reg_1)
);

ModRed_sub #(.CURR_DATA(55), .NEXT_DATA(50)) mrs1 (
    .clk(clk),
    .reset(reset),
    .qH(q[29:6]),
    .T1(C_reg_1),
    .C (C_reg_2)
);

ModRed_sub #(.CURR_DATA(50), .NEXT_DATA(45)) mrs2 (
    .clk(clk),
    .reset(reset),
    .qH(q[29:6]),
    .T1(C_reg_2),
    .C (C_reg_3)
);

ModRed_sub #(.CURR_DATA(45), .NEXT_DATA(40)) mrs3 (
    .clk(clk),
    .reset(reset),
    .qH(q[29:6]),
    .T1(C_reg_3),
    .C (C_reg_4)
);

ModRed_sub #(.CURR_DATA(40), .NEXT_DATA(32)) mrs4 (
    .clk(clk),
    .reset(reset),
    .qH(q[29:6]),
    .T1(C_reg_4),
    .C (C_reg_5)
);

// --- Final stage
wire [31:0] C_ext = C_reg_5;
wire [31:0] C_temp = C_ext - q;

always @(posedge clk or posedge reset) begin
    if (reset)
        C <= 0;
    else begin
        if (C_temp[30])
            C <= C_ext;
        else
            C <= C_temp[29:0];
    end
end

endmodule

