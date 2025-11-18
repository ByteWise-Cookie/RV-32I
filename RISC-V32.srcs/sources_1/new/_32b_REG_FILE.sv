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
  input  logic        clk,
  input  logic        high_rst,
  input  logic        write_enable,
  input  logic [31:0] din,
  input  logic [4:0]  rs1, rs2, rd,
  output logic [31:0] reg1, reg2
);

  logic [31:0] REG_F [31:0];

  // Synchronous reset + write
  always_ff @(posedge clk) begin
    if (high_rst) begin
      // Clear all registers
      for (int i = 0; i < 32; i++)
        REG_F[i] <= 32'b0;
    end else begin
      // Write on enable, except to x0
      if (write_enable && rd != 5'd0)
        REG_F[rd] <= din;
    end
  end

  // Combinational read
  assign reg1 = (rs1 == 5'd0) ? 32'b0 : REG_F[rs1];
  assign reg2 = (rs2 == 5'd0) ? 32'b0 : REG_F[rs2];

endmodule
