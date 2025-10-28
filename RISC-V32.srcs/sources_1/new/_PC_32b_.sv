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

  always_ff@(posedge clk, write_enable) begin 
  
    if(write_enable) PC <= PCin;
    
    if(high_rst) PC <= 32'b0;

    end

  assign PCout = PC;
  

endmodule
