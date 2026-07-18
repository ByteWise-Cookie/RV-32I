// -----------------------------------------------------------------------------
// control.sv  -  Main control unit (opcode -> datapath control signals)
//
// One combinational decode of the 7-bit opcode.  Every output has a safe
// default (a bubble / NOP) so illegal or unimplemented opcodes never write
// architectural state.  SYSTEM and FENCE decode to NOPs here.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module control (
  input  logic [6:0]  opcode,
  output logic        reg_write,
  output logic        alu_src_a,   // 0 = rs1, 1 = PC          (AUIPC)
  output logic        alu_src_b,   // 0 = rs2, 1 = immediate
  output logic        mem_read,
  output logic        mem_write,
  output logic        branch,      // conditional branch
  output logic        jump,        // unconditional (JAL / JALR)
  output logic        jalr,        // jump base is rs1 (else PC)
  output wb_sel_e     wb_sel,
  output alu_op_sel_e alu_op_sel
);

  always_comb begin
    // Defaults: NOP, writes nothing.
    reg_write  = 1'b0;
    alu_src_a  = 1'b0;
    alu_src_b  = 1'b0;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    branch     = 1'b0;
    jump       = 1'b0;
    jalr       = 1'b0;
    wb_sel     = WB_ALU;
    alu_op_sel = ALUOP_ADD;

    unique case (opcode)
      OP_REG: begin                       // R-type
        reg_write  = 1'b1;
        alu_op_sel = ALUOP_RTYPE;
      end

      OP_IMM: begin                       // I-type ALU
        reg_write  = 1'b1;
        alu_src_b  = 1'b1;
        alu_op_sel = ALUOP_ITYPE;
      end

      OP_LOAD: begin                      // LB/LH/LW/LBU/LHU
        reg_write  = 1'b1;
        alu_src_b  = 1'b1;                // addr = rs1 + imm
        mem_read   = 1'b1;
        wb_sel     = WB_MEM;
        alu_op_sel = ALUOP_ADD;
      end

      OP_STORE: begin                     // SB/SH/SW
        alu_src_b  = 1'b1;                // addr = rs1 + imm
        mem_write  = 1'b1;
        alu_op_sel = ALUOP_ADD;
      end

      OP_BRANCH: begin                    // BEQ/BNE/BLT/BGE/BLTU/BGEU
        branch     = 1'b1;
        alu_op_sel = ALUOP_BRANCH;
      end

      OP_LUI: begin                       // rd = imm
        reg_write  = 1'b1;
        wb_sel     = WB_IMM;
      end

      OP_AUIPC: begin                     // rd = PC + imm
        reg_write  = 1'b1;
        alu_src_a  = 1'b1;
        alu_src_b  = 1'b1;
        alu_op_sel = ALUOP_ADD;
      end

      OP_JAL: begin                       // rd = PC+4, PC = PC + imm
        reg_write  = 1'b1;
        jump       = 1'b1;
        wb_sel     = WB_PC4;
      end

      OP_JALR: begin                      // rd = PC+4, PC = (rs1 + imm) & ~1
        reg_write  = 1'b1;
        jump       = 1'b1;
        jalr       = 1'b1;
        wb_sel     = WB_PC4;
      end

      // OP_FENCE, OP_SYSTEM and anything else fall through as NOP.
      default: ;
    endcase
  end

endmodule
