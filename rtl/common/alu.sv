// -----------------------------------------------------------------------------
// alu.sv  -  32-bit RV32I ALU
//
// Pure combinational.  One clean case over alu_op_e; no hidden state, no
// double-driven nets.  `zero` is the equality flag (result == 0), consumed by
// the branch unit / single-cycle branch logic.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module alu (
  input  logic [31:0] op1,
  input  logic [31:0] op2,
  input  alu_op_e     alu_op,
  output logic [31:0] result,
  output logic        zero
);

  logic signed [31:0] sop1, sop2;
  assign sop1 = op1;
  assign sop2 = op2;

  always_comb begin
    unique case (alu_op)
      ALU_ADD : result = op1 + op2;
      ALU_SUB : result = op1 - op2;
      ALU_SLL : result = op1 << op2[4:0];
      ALU_SLT : result = (sop1 < sop2)             ? 32'd1 : 32'd0;
      ALU_SLTU: result = (op1  < op2)              ? 32'd1 : 32'd0;
      ALU_XOR : result = op1 ^ op2;
      ALU_SRL : result = op1 >> op2[4:0];
      ALU_SRA : result = $unsigned(sop1 >>> op2[4:0]);
      ALU_OR  : result = op1 | op2;
      ALU_AND : result = op1 & op2;
      ALU_PASS: result = op2;
      default : result = 32'b0;
    endcase
  end

  assign zero = (result == 32'b0);

endmodule
