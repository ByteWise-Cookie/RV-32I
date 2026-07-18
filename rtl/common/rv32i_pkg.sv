// -----------------------------------------------------------------------------
// rv32i_pkg.sv  -  Shared types and constants for the RV32I core
//
// One source of truth for opcodes, ALU operation codes and control encodings.
// Imported by every RTL module so the datapath and control agree by construction.
// -----------------------------------------------------------------------------
`ifndef RV32I_PKG_SV
`define RV32I_PKG_SV

package rv32i_pkg;

  // ---- RV32I major opcodes (inst[6:0]) ------------------------------------
  localparam logic [6:0] OP_LUI    = 7'b0110111;
  localparam logic [6:0] OP_AUIPC  = 7'b0010111;
  localparam logic [6:0] OP_JAL    = 7'b1101111;
  localparam logic [6:0] OP_JALR   = 7'b1100111;
  localparam logic [6:0] OP_BRANCH = 7'b1100011;
  localparam logic [6:0] OP_LOAD   = 7'b0000011;
  localparam logic [6:0] OP_STORE  = 7'b0100011;
  localparam logic [6:0] OP_IMM    = 7'b0010011;  // OP-IMM (ADDI, ...)
  localparam logic [6:0] OP_REG    = 7'b0110011;  // OP     (ADD, ...)
  localparam logic [6:0] OP_FENCE  = 7'b0001111;
  localparam logic [6:0] OP_SYSTEM = 7'b1110011;  // ECALL / EBREAK

  // ---- ALU operation select ----------------------------------------------
  typedef enum logic [3:0] {
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_SLL  = 4'd2,
    ALU_SLT  = 4'd3,   // signed  set-less-than
    ALU_SLTU = 4'd4,   // unsigned set-less-than
    ALU_XOR  = 4'd5,
    ALU_SRL  = 4'd6,
    ALU_SRA  = 4'd7,
    ALU_OR   = 4'd8,
    ALU_AND  = 4'd9,
    ALU_PASS = 4'd10   // pass op2 straight through (used for LUI)
  } alu_op_e;

  // ---- ALUOp field driven by the main control unit -----------------------
  // Tells the ALU-control block how to derive the final alu_op_e.
  typedef enum logic [1:0] {
    ALUOP_ADD    = 2'b00,   // loads/stores/AUIPC/JAL(R): force ADD
    ALUOP_BRANCH = 2'b01,   // branches: force SUB (compare)
    ALUOP_RTYPE  = 2'b10,   // decode from funct3/funct7
    ALUOP_ITYPE  = 2'b11    // decode from funct3 (+ funct7 for SRAI/SLLI)
  } alu_op_sel_e;

  // ---- Writeback source select -------------------------------------------
  typedef enum logic [1:0] {
    WB_ALU  = 2'b00,   // ALU result
    WB_MEM  = 2'b01,   // data-memory load
    WB_PC4  = 2'b10,   // PC+4 (JAL / JALR link)
    WB_IMM  = 2'b11    // immediate (LUI)
  } wb_sel_e;

  // ---- funct3 codes -------------------------------------------------------
  // Branch
  localparam logic [2:0] F3_BEQ  = 3'b000;
  localparam logic [2:0] F3_BNE  = 3'b001;
  localparam logic [2:0] F3_BLT  = 3'b100;
  localparam logic [2:0] F3_BGE  = 3'b101;
  localparam logic [2:0] F3_BLTU = 3'b110;
  localparam logic [2:0] F3_BGEU = 3'b111;
  // Load / Store width
  localparam logic [2:0] F3_B    = 3'b000;  // byte
  localparam logic [2:0] F3_H    = 3'b001;  // half
  localparam logic [2:0] F3_W    = 3'b010;  // word
  localparam logic [2:0] F3_BU   = 3'b100;  // byte  unsigned
  localparam logic [2:0] F3_HU   = 3'b101;  // half  unsigned

endpackage

`endif
