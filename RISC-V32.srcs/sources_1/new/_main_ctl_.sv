`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2025 07:25:21 PM
// Design Name: 
// Module Name: _main_ctl_
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


module _main_ctl_(
  input  logic [6:0] opcode,
  output logic RegWrite,
  output logic ALUSrc,
  output logic MemRead,
  output logic MemWrite,
  output logic MemtoReg,
  output logic Branch,
  output logic [1:0] ALUOp
);

always_comb begin
  // Default values
  RegWrite = 0;
  ALUSrc   = 0;
  MemRead  = 0;
  MemWrite = 0;
  MemtoReg = 0;
  Branch   = 0;
  ALUOp    = 2'b00;

  case (opcode)
    7'b0110011: begin
      // R-type (ADD, SUB, AND, OR)
      RegWrite = 1;
      ALUSrc   = 0;
      ALUOp    = 2'b10;
    end

    7'b0010011: begin
      // I-type (ADDI, ANDI, ORI)
      RegWrite = 1;
      ALUSrc   = 1;
      ALUOp    = 2'b11;
    end

    7'b0000011: begin
      // Load (LW)
      RegWrite = 1;
      ALUSrc   = 1;
      MemRead  = 1;
      MemtoReg = 1;
      ALUOp    = 2'b00;
    end

    7'b0100011: begin
      // Store (SW)
      ALUSrc   = 1;
      MemWrite = 1;
      ALUOp    = 2'b00;
    end

    7'b1100011: begin
      // Branch (BEQ, etc.)
      Branch   = 1;
      ALUOp    = 2'b01;
    end

    default: begin
      RegWrite = 0;
      ALUSrc   = 0;
      MemRead  = 0;
      MemWrite = 0;
      MemtoReg = 0;
      Branch   = 0;
      ALUOp    = 2'b00;
    end
  endcase
end

endmodule
