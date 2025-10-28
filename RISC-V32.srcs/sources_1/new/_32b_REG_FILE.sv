`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 11:47:17 PM
// Design Name: 
// Module Name: _32b_REG_FILE
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


module _32b_REG_FILE(
  input logic clk, high_rst, write_enable,
  input logic [31:0] din,
  input logic [4:0] rs1, rs2, rd,
  output logic [31:0] reg1, reg2
  
  );

  logic [31:0] REG_F [31:0];

  always_ff@(posedge clk, high_rst) begin 
  
  if(high_rst) begin 
  // reset
  end
  
  if(write_enable) begin 
  REG_F[rd] <= din;
  end

  end

  assign reg1 = REG_F[rs1];
  assign reg2 = REG_F[rs2];

endmodule
