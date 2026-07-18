// -----------------------------------------------------------------------------
// rv32i_single_cycle.sv  -  Single-cycle RV32I core
//
// One instruction retires per clock.  Instruction and data memories are
// external (Harvard, combinational read) and driven by the testbench/SoC:
//
//        imem_addr  ->|  IMEM  |-> imem_rdata        (byte address = PC)
//        dmem_addr  ->|  DMEM  |<->                  (word data + byte strobe)
//
// The whole datapath is combinational except the PC and the register file.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module rv32i_single_cycle (
  input  logic        clk,
  input  logic        rst,          // synchronous, active-high

  // Instruction memory (read-only)
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,

  // Data memory
  output logic [31:0] dmem_addr,
  output logic [31:0] dmem_wdata,
  output logic [3:0]  dmem_wstrb,   // per-byte write enable
  output logic        dmem_we,
  output logic        dmem_re,
  input  logic [31:0] dmem_rdata,

  // Debug
  output logic [31:0] pc_debug
);

  // ---- Program counter ----------------------------------------------------
  logic [31:0] pc, pc_next, pc_plus4;

  always_ff @(posedge clk) begin
    if (rst) pc <= 32'b0;
    else     pc <= pc_next;
  end

  assign imem_addr = pc;
  assign pc_plus4  = pc + 32'd4;
  assign pc_debug  = pc;

  // ---- Instruction decode -------------------------------------------------
  logic [31:0] inst;
  logic [6:0]  opcode;
  logic [4:0]  rd, rs1, rs2;
  logic [2:0]  funct3;
  logic        funct7_5;

  assign inst     = imem_rdata;
  assign opcode   = inst[6:0];
  assign rd       = inst[11:7];
  assign funct3   = inst[14:12];
  assign rs1      = inst[19:15];
  assign rs2      = inst[24:20];
  assign funct7_5 = inst[30];

  // ---- Control ------------------------------------------------------------
  logic        reg_write, alu_src_a, alu_src_b, mem_read, mem_write;
  logic        branch, jump, jalr;
  wb_sel_e     wb_sel;
  alu_op_sel_e alu_op_sel;

  control u_control (
    .opcode(opcode),
    .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
    .mem_read(mem_read), .mem_write(mem_write),
    .branch(branch), .jump(jump), .jalr(jalr),
    .wb_sel(wb_sel), .alu_op_sel(alu_op_sel)
  );

  // ---- Immediate ----------------------------------------------------------
  logic [31:0] imm;
  imm_gen u_imm (.inst(inst), .imm(imm));

  // ---- Register file ------------------------------------------------------
  logic [31:0] rs1_data, rs2_data, wb_data;
  reg_file u_rf (
    .clk(clk), .rst(rst), .we(reg_write),
    .rd_addr(rd), .rd_data(wb_data),
    .rs1_addr(rs1), .rs2_addr(rs2),
    .rs1_data(rs1_data), .rs2_data(rs2_data)
  );

  // ---- ALU ----------------------------------------------------------------
  alu_op_e     alu_op;
  logic [31:0] alu_op1, alu_op2, alu_result;
  logic        alu_zero;

  alu_control u_aluctl (
    .alu_op_sel(alu_op_sel), .funct3(funct3), .funct7_5(funct7_5), .alu_op(alu_op)
  );

  assign alu_op1 = alu_src_a ? pc  : rs1_data;
  assign alu_op2 = alu_src_b ? imm : rs2_data;

  alu u_alu (
    .op1(alu_op1), .op2(alu_op2), .alu_op(alu_op),
    .result(alu_result), .zero(alu_zero)
  );

  // ---- Branch decision ----------------------------------------------------
  logic branch_take;
  branch_unit u_branch (
    .funct3(funct3), .rs1(rs1_data), .rs2(rs2_data), .take(branch_take)
  );

  // ---- Data memory access -------------------------------------------------
  logic [31:0] load_data;

  assign dmem_addr = alu_result;
  assign dmem_we   = mem_write;
  assign dmem_re   = mem_read;

  store_unit u_store (
    .funct3(funct3), .addr_lo(alu_result[1:0]), .rs2(rs2_data),
    .wdata(dmem_wdata), .wstrb(dmem_wstrb)
  );

  load_unit u_load (
    .funct3(funct3), .addr_lo(alu_result[1:0]), .word(dmem_rdata),
    .load_data(load_data)
  );

  // ---- Writeback mux ------------------------------------------------------
  always_comb begin
    unique case (wb_sel)
      WB_ALU: wb_data = alu_result;
      WB_MEM: wb_data = load_data;
      WB_PC4: wb_data = pc_plus4;
      WB_IMM: wb_data = imm;
      default: wb_data = alu_result;
    endcase
  end

  // ---- Next-PC logic ------------------------------------------------------
  logic [31:0] branch_target, jalr_target;
  assign branch_target = pc + imm;                 // JAL and branches
  assign jalr_target   = (rs1_data + imm) & ~32'd1;

  always_comb begin
    if (jump)
      pc_next = jalr ? jalr_target : branch_target;
    else if (branch && branch_take)
      pc_next = branch_target;
    else
      pc_next = pc_plus4;
  end

endmodule
