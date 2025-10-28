`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 12:18:02 AM
// Design Name: 
// Module Name: _32b_ADDER
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


module _32b_ADDER(
input logic [31:0] op1, op2,
input logic cin,
output logic [31:0] sum,
output logic carry
);
logic [32:0] carrysum;
assign carrysum = op1+op2+cin;
assign carry = carrysum[32];
assign sum = carrysum[31:0];

endmodule
