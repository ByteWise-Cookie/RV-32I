// -----------------------------------------------------------------------------
// imm_gen.sv  -  Immediate generator
//
// Produces the sign-extended 32-bit immediate for every RV32I format from the
// raw 32-bit instruction, selected by opcode.  All immediates are sign-extended
// except the shift-amount, which lives in the low bits of the I-immediate.
//
//   I-type : ADDI, loads, JALR          inst[31:20]
//   S-type : stores                     {inst[31:25], inst[11:7]}
//   B-type : branches                   {inst[31],inst[7],inst[30:25],inst[11:8],0}
//   U-type : LUI, AUIPC                 {inst[31:12], 12'b0}
//   J-type : JAL                        {inst[31],inst[19:12],inst[20],inst[30:21],0}
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module imm_gen (
  input  logic [31:0] inst,
  output logic [31:0] imm
);

  logic [6:0] opcode;
  assign opcode = inst[6:0];

  always_comb begin
    unique case (opcode)
      OP_LUI, OP_AUIPC:            // U-type
        imm = {inst[31:12], 12'b0};

      OP_JAL:                      // J-type
        imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

      OP_JALR, OP_LOAD, OP_IMM:    // I-type
        imm = {{20{inst[31]}}, inst[31:20]};

      OP_STORE:                    // S-type
        imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

      OP_BRANCH:                   // B-type
        imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};

      default:                     // treat as I-type
        imm = {{20{inst[31]}}, inst[31:20]};
    endcase
  end

endmodule
