// -----------------------------------------------------------------------------
// alu_m.sv  -  OPTIONAL RV32M multiply/divide unit  (NOT part of RV32I base)
//
// Provided for completeness and gated behind the `RV32M` parameter in the
// cores; it is not wired into the base RV32I datapath.  funct3 follows the
// RV32M encoding (MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU).  Division-by-zero
// and signed overflow follow the RISC-V spec's defined results.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module alu_m (
  input  logic [31:0] rs1,
  input  logic [31:0] rs2,
  input  logic [2:0]  funct3,
  output logic [31:0] alu_out
);

  logic signed [63:0] mul_ss;   // signed   * signed
  logic signed [63:0] mul_su;   // signed   * unsigned
  logic        [63:0] mul_uu;   // unsigned * unsigned

  assign mul_ss = $signed(rs1)          * $signed(rs2);
  assign mul_su = $signed(rs1)          * $signed({1'b0, rs2});
  assign mul_uu = $unsigned(rs1)        * $unsigned(rs2);

  always_comb begin
    unique case (funct3)
      3'b000: alu_out = mul_ss[31:0];    // MUL
      3'b001: alu_out = mul_ss[63:32];   // MULH
      3'b010: alu_out = mul_su[63:32];   // MULHSU
      3'b011: alu_out = mul_uu[63:32];   // MULHU

      3'b100:                            // DIV
        if (rs2 == 32'b0)                          alu_out = 32'hFFFF_FFFF;
        else if (rs1 == 32'h8000_0000 && rs2 == 32'hFFFF_FFFF) alu_out = 32'h8000_0000;
        else                                       alu_out = $signed(rs1) / $signed(rs2);

      3'b101:                            // DIVU
        alu_out = (rs2 == 32'b0) ? 32'hFFFF_FFFF : (rs1 / rs2);

      3'b110:                            // REM
        if (rs2 == 32'b0)                          alu_out = rs1;
        else if (rs1 == 32'h8000_0000 && rs2 == 32'hFFFF_FFFF) alu_out = 32'b0;
        else                                       alu_out = $signed(rs1) % $signed(rs2);

      3'b111:                            // REMU
        alu_out = (rs2 == 32'b0) ? rs1 : (rs1 % rs2);

      default: alu_out = 32'b0;
    endcase
  end

endmodule
