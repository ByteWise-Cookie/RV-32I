// -----------------------------------------------------------------------------
// alu_control.sv  -  Derives the ALU operation from ALUOp + funct fields
//
//   ALUOP_ADD    -> ALU_ADD          (loads, stores, AUIPC, JAL/JALR targets)
//   ALUOP_BRANCH -> ALU_SUB          (branch comparison in single-cycle path)
//   ALUOP_RTYPE  -> full decode from funct3 + funct7[5]
//   ALUOP_ITYPE  -> decode from funct3; funct7[5] only distinguishes SRLI/SRAI
//                   (SUB and SRA do not exist in OP-IMM form)
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module alu_control (
  input  alu_op_sel_e alu_op_sel,
  input  logic [2:0]  funct3,
  input  logic        funct7_5,   // inst[30]
  output alu_op_e     alu_op
);

  always_comb begin
    unique case (alu_op_sel)
      ALUOP_ADD:    alu_op = ALU_ADD;
      ALUOP_BRANCH: alu_op = ALU_SUB;

      ALUOP_RTYPE: begin
        unique case (funct3)
          3'b000: alu_op = alu_op_e'(funct7_5 ? ALU_SUB : ALU_ADD);  // ADD / SUB
          3'b001: alu_op = ALU_SLL;
          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b100: alu_op = ALU_XOR;
          3'b101: alu_op = alu_op_e'(funct7_5 ? ALU_SRA : ALU_SRL);  // SRA / SRL
          3'b110: alu_op = ALU_OR;
          3'b111: alu_op = ALU_AND;
          default: alu_op = ALU_ADD;
        endcase
      end

      ALUOP_ITYPE: begin
        unique case (funct3)
          3'b000: alu_op = ALU_ADD;                       // ADDI
          3'b001: alu_op = ALU_SLL;                       // SLLI
          3'b010: alu_op = ALU_SLT;                       // SLTI
          3'b011: alu_op = ALU_SLTU;                      // SLTIU
          3'b100: alu_op = ALU_XOR;                       // XORI
          3'b101: alu_op = alu_op_e'(funct7_5 ? ALU_SRA : ALU_SRL);  // SRAI / SRLI
          3'b110: alu_op = ALU_OR;                        // ORI
          3'b111: alu_op = ALU_AND;                       // ANDI
          default: alu_op = ALU_ADD;
        endcase
      end

      default: alu_op = ALU_ADD;
    endcase
  end

endmodule
