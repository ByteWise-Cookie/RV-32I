`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 12:31:22 AM
// Design Name: 
// Module Name: _IMMGEN
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module _IMMGEN(
input logic [11:0] imm12,
output logic [31:0] signed_32);

assign signed_32 = {{20{imm12[11]}}, imm12};

endmodule
