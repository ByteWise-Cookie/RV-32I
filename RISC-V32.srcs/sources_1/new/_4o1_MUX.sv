`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2025 06:20:36 PM
// Design Name: 
// Module Name: _4o1_MUX
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


module _4o1_MUX(
input logic [1:0] s,
input logic [31:0] din [3:0],
output logic [31:0] dout);

always_comb begin

  case(s)
  2'b00: dout = din[0];
  2'b01: dout = din[1];
  2'b10: dout = din[2];
  2'b11: dout = din[3];

endcase
end 
endmodule
