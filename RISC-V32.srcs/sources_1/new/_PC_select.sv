`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2025 10:06:11 PM
// Design Name: 
// Module Name: _PC_select
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


module _PC_select(
input logic s,
input logic [31:0] id0, id1,
output logic [31:0] od);

assign od = s?id1:id0;

endmodule
