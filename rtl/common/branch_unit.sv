// -----------------------------------------------------------------------------
// branch_unit.sv  -  Evaluates the branch condition
//
// Compares the two register operands directly (not via the ALU) so all six
// branch conditions are handled correctly, including the signed/unsigned split.
// `take` is only meaningful when the instruction is a branch; the datapath
// gates it with the control `branch` signal.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module branch_unit (
  input  logic [2:0]  funct3,
  input  logic [31:0] rs1,
  input  logic [31:0] rs2,
  output logic        take
);

  logic eq, lt, ltu;
  assign eq  = (rs1 == rs2);
  assign lt  = ($signed(rs1) < $signed(rs2));
  assign ltu = (rs1 < rs2);

  always_comb begin
    unique case (funct3)
      F3_BEQ : take =  eq;
      F3_BNE : take = ~eq;
      F3_BLT : take =  lt;
      F3_BGE : take = ~lt;
      F3_BLTU: take =  ltu;
      F3_BGEU: take = ~ltu;
      default: take = 1'b0;
    endcase
  end

endmodule
