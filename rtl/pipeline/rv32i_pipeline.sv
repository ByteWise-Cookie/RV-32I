// -----------------------------------------------------------------------------
// rv32i_pipeline.sv  -  Classic 5-stage RV32I core  (IF | ID | EX | MEM | WB)
//
// Hazard handling:
//   * Data hazards   : EX-stage forwarding from EX/MEM and MEM/WB
//                      (forwarding_unit). The register file is write-first, so
//                      a WB->ID read in the same cycle also sees the new value.
//   * Load-use       : one-cycle stall (hazard_unit) freezes PC + IF/ID and
//                      bubbles ID/EX.
//   * Control hazards : branches and jumps resolve in EX. On a taken
//                      transfer the two younger instructions (IF/ID, ID/EX) are
//                      flushed to bubbles -> 2-cycle penalty.
//
// Instruction and data memories are external and combinational-read, same
// contract as the single-cycle core.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module rv32i_pipeline (
  input  logic        clk,
  input  logic        rst,          // synchronous, active-high

  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,

  output logic [31:0] dmem_addr,
  output logic [31:0] dmem_wdata,
  output logic [3:0]  dmem_wstrb,
  output logic        dmem_we,
  output logic        dmem_re,
  input  logic [31:0] dmem_rdata,

  output logic [31:0] pc_debug
);

  // ==========================================================================
  //  Hazard / control-flow signals (declared up-front; driven in EX/hazard)
  // ==========================================================================
  logic        stall;          // load-use stall
  logic        flush;          // taken branch/jump in EX
  logic [31:0] ex_target;      // resolved branch/jump target

  // ==========================================================================
  //  IF  -  Instruction fetch
  // ==========================================================================
  logic [31:0] pc_f, pc_next_f, pc_plus4_f;

  assign pc_plus4_f = pc_f + 32'd4;
  assign imem_addr  = pc_f;
  assign pc_debug   = pc_f;

  always_comb begin
    if (flush)      pc_next_f = ex_target;   // redirect dominates
    else if (stall) pc_next_f = pc_f;        // hold on load-use
    else            pc_next_f = pc_plus4_f;
  end

  always_ff @(posedge clk) begin
    if (rst) pc_f <= 32'b0;
    else     pc_f <= pc_next_f;
  end

  // ==========================================================================
  //  IF/ID register
  // ==========================================================================
  logic [31:0] id_pc, id_pc_plus4, id_inst;

  always_ff @(posedge clk) begin
    if (rst || flush) begin
      id_pc       <= 32'b0;
      id_pc_plus4 <= 32'b0;
      id_inst     <= 32'b0;             // opcode 0 -> NOP in control
    end else if (!stall) begin
      id_pc       <= pc_f;
      id_pc_plus4 <= pc_plus4_f;
      id_inst     <= imem_rdata;
    end
    // stall && !flush: hold current IF/ID contents
  end

  // ==========================================================================
  //  ID  -  Decode, register read, immediate, control
  // ==========================================================================
  logic [6:0] id_opcode;
  logic [4:0] id_rd, id_rs1, id_rs2;
  logic [2:0] id_funct3;
  logic       id_funct7_5;

  assign id_opcode   = id_inst[6:0];
  assign id_rd       = id_inst[11:7];
  assign id_funct3   = id_inst[14:12];
  assign id_rs1      = id_inst[19:15];
  assign id_rs2      = id_inst[24:20];
  assign id_funct7_5 = id_inst[30];

  logic        c_reg_write, c_alu_src_a, c_alu_src_b, c_mem_read, c_mem_write;
  logic        c_branch, c_jump, c_jalr;
  wb_sel_e     c_wb_sel;
  alu_op_sel_e c_alu_op_sel;

  control u_control (
    .opcode(id_opcode),
    .reg_write(c_reg_write), .alu_src_a(c_alu_src_a), .alu_src_b(c_alu_src_b),
    .mem_read(c_mem_read), .mem_write(c_mem_write),
    .branch(c_branch), .jump(c_jump), .jalr(c_jalr),
    .wb_sel(c_wb_sel), .alu_op_sel(c_alu_op_sel)
  );

  logic [31:0] id_imm, id_rs1_data, id_rs2_data;
  imm_gen u_imm (.inst(id_inst), .imm(id_imm));

  // Register file: written from the WB stage (declared later, wired by name).
  logic        wb_reg_write;
  logic [4:0]  wb_rd;
  logic [31:0] wb_data;

  logic [31:0] rf_rs1_data, rf_rs2_data;
  reg_file u_rf (
    .clk(clk), .rst(rst), .we(wb_reg_write),
    .rd_addr(wb_rd), .rd_data(wb_data),
    .rs1_addr(id_rs1), .rs2_addr(id_rs2),
    .rs1_data(rf_rs1_data), .rs2_data(rf_rs2_data)
  );

  // WB->ID forwarding: an instruction writing back this cycle is not yet
  // visible through the plain register file, so bypass it into the ID read.
  assign id_rs1_data = (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == id_rs1))
                       ? wb_data : rf_rs1_data;
  assign id_rs2_data = (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == id_rs2))
                       ? wb_data : rf_rs2_data;

  // Bubble = stall or flush: kill all control that changes state.
  logic id_bubble;
  assign id_bubble = stall || flush;

  // ==========================================================================
  //  ID/EX register
  // ==========================================================================
  logic        ex_reg_write, ex_alu_src_a, ex_alu_src_b, ex_mem_read, ex_mem_write;
  logic        ex_branch, ex_jump, ex_jalr;
  wb_sel_e     ex_wb_sel;
  alu_op_sel_e ex_alu_op_sel;
  logic [31:0] ex_pc, ex_pc_plus4, ex_imm, ex_rs1_data, ex_rs2_data;
  logic [4:0]  ex_rs1, ex_rs2, ex_rd;
  logic [2:0]  ex_funct3;
  logic        ex_funct7_5;

  always_ff @(posedge clk) begin
    if (rst || id_bubble) begin
      ex_reg_write <= 1'b0;
      ex_mem_read  <= 1'b0;
      ex_mem_write <= 1'b0;
      ex_branch    <= 1'b0;
      ex_jump      <= 1'b0;
      ex_jalr      <= 1'b0;
      ex_alu_src_a <= 1'b0;
      ex_alu_src_b <= 1'b0;
      ex_wb_sel    <= WB_ALU;
      ex_alu_op_sel<= ALUOP_ADD;
      ex_pc        <= 32'b0;
      ex_pc_plus4  <= 32'b0;
      ex_imm       <= 32'b0;
      ex_rs1_data  <= 32'b0;
      ex_rs2_data  <= 32'b0;
      ex_rs1       <= 5'b0;
      ex_rs2       <= 5'b0;
      ex_rd        <= 5'b0;
      ex_funct3    <= 3'b0;
      ex_funct7_5  <= 1'b0;
    end else begin
      ex_reg_write <= c_reg_write;
      ex_mem_read  <= c_mem_read;
      ex_mem_write <= c_mem_write;
      ex_branch    <= c_branch;
      ex_jump      <= c_jump;
      ex_jalr      <= c_jalr;
      ex_alu_src_a <= c_alu_src_a;
      ex_alu_src_b <= c_alu_src_b;
      ex_wb_sel    <= c_wb_sel;
      ex_alu_op_sel<= c_alu_op_sel;
      ex_pc        <= id_pc;
      ex_pc_plus4  <= id_pc_plus4;
      ex_imm       <= id_imm;
      ex_rs1_data  <= id_rs1_data;
      ex_rs2_data  <= id_rs2_data;
      ex_rs1       <= id_rs1;
      ex_rs2       <= id_rs2;
      ex_rd        <= id_rd;
      ex_funct3    <= id_funct3;
      ex_funct7_5  <= id_funct7_5;
    end
  end

  // ==========================================================================
  //  EX  -  Forwarding, ALU, branch/jump resolution
  // ==========================================================================
  logic [1:0]  fwd_a, fwd_b;
  logic [31:0] mem_result_pre;   // EX/MEM writeback candidate (non-memory)

  // Forward-declared EX/MEM outputs consumed here by the forwarding unit
  // (their registers live in the EX/MEM section below).
  logic       mem_reg_write;
  logic [4:0] mem_rd;

  forwarding_unit u_fwd (
    .ex_rs1(ex_rs1), .ex_rs2(ex_rs2),
    .mem_rd(mem_rd), .mem_reg_write(mem_reg_write),
    .wb_rd(wb_rd),   .wb_reg_write(wb_reg_write),
    .fwd_a(fwd_a),   .fwd_b(fwd_b)
  );

  logic [31:0] fwd_rs1, fwd_rs2;
  always_comb begin
    unique case (fwd_a)
      2'b10:   fwd_rs1 = mem_result_pre;
      2'b01:   fwd_rs1 = wb_data;
      default: fwd_rs1 = ex_rs1_data;
    endcase
    unique case (fwd_b)
      2'b10:   fwd_rs2 = mem_result_pre;
      2'b01:   fwd_rs2 = wb_data;
      default: fwd_rs2 = ex_rs2_data;
    endcase
  end

  alu_op_e     ex_alu_op;
  logic [31:0] alu_op1, alu_op2, ex_alu_result;
  logic        ex_alu_zero;

  alu_control u_aluctl (
    .alu_op_sel(ex_alu_op_sel), .funct3(ex_funct3),
    .funct7_5(ex_funct7_5), .alu_op(ex_alu_op)
  );

  assign alu_op1 = ex_alu_src_a ? ex_pc  : fwd_rs1;
  assign alu_op2 = ex_alu_src_b ? ex_imm : fwd_rs2;

  alu u_alu (
    .op1(alu_op1), .op2(alu_op2), .alu_op(ex_alu_op),
    .result(ex_alu_result), .zero(ex_alu_zero)
  );

  // Branch decision on forwarded operands.
  logic ex_branch_take;
  branch_unit u_branch (
    .funct3(ex_funct3), .rs1(fwd_rs1), .rs2(fwd_rs2), .take(ex_branch_take)
  );

  logic [31:0] ex_branch_target, ex_jalr_target;
  assign ex_branch_target = ex_pc + ex_imm;
  assign ex_jalr_target   = (fwd_rs1 + ex_imm) & ~32'd1;

  // Resolve control flow.
  assign flush     = ex_jump || (ex_branch && ex_branch_take);
  assign ex_target = ex_jalr ? ex_jalr_target : ex_branch_target;

  // Writeback candidate available already at EX (everything but a load).
  logic [31:0] ex_result_pre;
  always_comb begin
    unique case (ex_wb_sel)
      WB_PC4:  ex_result_pre = ex_pc_plus4;
      WB_IMM:  ex_result_pre = ex_imm;
      default: ex_result_pre = ex_alu_result;   // WB_ALU (and WB_MEM placeholder)
    endcase
  end

  // ==========================================================================
  //  EX/MEM register
  // ==========================================================================
  logic        mem_mem_read, mem_mem_write;   // mem_reg_write declared above
  wb_sel_e     mem_wb_sel;
  logic [31:0] mem_alu_result, mem_result_pre_r, mem_store_data;
  logic [2:0]  mem_funct3;                     // mem_rd declared above

  assign mem_result_pre = mem_result_pre_r;

  always_ff @(posedge clk) begin
    if (rst) begin
      mem_reg_write   <= 1'b0;
      mem_mem_read    <= 1'b0;
      mem_mem_write   <= 1'b0;
      mem_wb_sel      <= WB_ALU;
      mem_alu_result  <= 32'b0;
      mem_result_pre_r<= 32'b0;
      mem_store_data  <= 32'b0;
      mem_rd          <= 5'b0;
      mem_funct3      <= 3'b0;
    end else begin
      mem_reg_write   <= ex_reg_write;
      mem_mem_read    <= ex_mem_read;
      mem_mem_write   <= ex_mem_write;
      mem_wb_sel      <= ex_wb_sel;
      mem_alu_result  <= ex_alu_result;
      mem_result_pre_r<= ex_result_pre;
      mem_store_data  <= fwd_rs2;
      mem_rd          <= ex_rd;
      mem_funct3      <= ex_funct3;
    end
  end

  // ==========================================================================
  //  MEM  -  Data memory access
  // ==========================================================================
  logic [31:0] mem_load_data;

  assign dmem_addr = mem_alu_result;
  assign dmem_we   = mem_mem_write;
  assign dmem_re   = mem_mem_read;

  store_unit u_store (
    .funct3(mem_funct3), .addr_lo(mem_alu_result[1:0]), .rs2(mem_store_data),
    .wdata(dmem_wdata), .wstrb(dmem_wstrb)
  );

  load_unit u_load (
    .funct3(mem_funct3), .addr_lo(mem_alu_result[1:0]), .word(dmem_rdata),
    .load_data(mem_load_data)
  );

  // ==========================================================================
  //  MEM/WB register
  // ==========================================================================
  wb_sel_e     wbs_wb_sel;
  logic [31:0] wbs_result_pre, wbs_load_data;

  always_ff @(posedge clk) begin
    if (rst) begin
      wb_reg_write   <= 1'b0;
      wbs_wb_sel     <= WB_ALU;
      wbs_result_pre <= 32'b0;
      wbs_load_data  <= 32'b0;
      wb_rd          <= 5'b0;
    end else begin
      wb_reg_write   <= mem_reg_write;
      wbs_wb_sel     <= mem_wb_sel;
      wbs_result_pre <= mem_result_pre_r;
      wbs_load_data  <= mem_load_data;
      wb_rd          <= mem_rd;
    end
  end

  // ==========================================================================
  //  WB  -  Writeback mux (feeds register file, declared in ID)
  // ==========================================================================
  always_comb begin
    if (wbs_wb_sel == WB_MEM) wb_data = wbs_load_data;
    else                      wb_data = wbs_result_pre;
  end

  // ==========================================================================
  //  Hazard unit (load-use)
  // ==========================================================================
  hazard_unit u_hazard (
    .ex_mem_read(ex_mem_read), .ex_rd(ex_rd),
    .id_rs1(id_rs1), .id_rs2(id_rs2),
    .stall(stall)
  );

endmodule
