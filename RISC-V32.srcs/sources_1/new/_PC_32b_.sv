`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 11:28:33 PM
// Design Name: 
// Module Name: _PC_32b_
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


module _PC_32b_(
  input logic clk, high_rst, write_enable,
  input logic [31:0] PCin,
  output logic [31:0] PCout
  );
  
  logic [31:0] PC;

  always_ff@(posedge clk or posedge high_rst) begin 
  if (high_rst)
  PCout <= 32'b0;
  else if (write_enable)
      PCout <= PCin;
  end

  assign PCout = PC;
  

endmodule
