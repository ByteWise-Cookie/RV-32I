`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 11:22:31 PM
// Design Name: 
// Module Name: _2o1_MUX
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


module _2o1_MUX(
input logic s,
input logic [31:0] id0, id1,
output logic [31:0] od);

assign od = s?id1:id0;

endmodule
