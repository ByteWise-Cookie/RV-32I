// -----------------------------------------------------------------------------
// tb_pipeline.sv  -  Self-checking testbench for the 5-stage pipelined core
//
// Same program and expected end-state as the single-cycle testbench: both cores
// must reach identical architectural state.  Exercises forwarding, a load-use
// stall (addi x12,x9,1 after lw x9), a taken branch and a jump (flushes).
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_pipeline;

  logic        clk = 0, rst;
  logic [31:0] imem_addr, imem_rdata;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  logic [3:0]  dmem_wstrb;
  logic        dmem_we, dmem_re;
  logic [31:0] pc_debug;

  rv32i_pipeline dut (
    .clk(clk), .rst(rst),
    .imem_addr(imem_addr), .imem_rdata(imem_rdata),
    .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_wstrb(dmem_wstrb),
    .dmem_we(dmem_we), .dmem_re(dmem_re), .dmem_rdata(dmem_rdata),
    .pc_debug(pc_debug)
  );

  mem_model #(.HEXFILE("prog/test1.hex")) mem (
    .clk(clk),
    .imem_addr(imem_addr), .imem_rdata(imem_rdata),
    .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_wstrb(dmem_wstrb),
    .dmem_we(dmem_we), .dmem_re(dmem_re), .dmem_rdata(dmem_rdata)
  );

  always #5 clk = ~clk;

  int errors = 0;
  task check(input [4:0] r, input [31:0] exp);
    if (dut.u_rf.regs[r] !== exp) begin
      $display("  FAIL x%0d = %08x  expected %08x", r, dut.u_rf.regs[r], exp);
      errors++;
    end else begin
      $display("  ok   x%0d = %08x", r, exp);
    end
  endtask

  initial begin
    rst = 1;
    repeat (2) @(posedge clk);
    rst = 0;
    repeat (200) @(posedge clk);

    $display("[tb_pipeline] register check:");
    check(1,  32'h00000005);
    check(2,  32'h0000000A);
    check(3,  32'h0000000F);
    check(4,  32'h00000005);
    check(5,  32'h00000014);
    check(6,  32'h0000000A);
    check(7,  32'h0000000F);
    check(8,  32'h0000000A);
    check(9,  32'h0000000F);
    check(10, 32'h00000007);
    check(12, 32'h00000010);
    check(13, 32'h0000002A);
    check(14, 32'h12345000);
    check(15, 32'h00000048);

    if (errors == 0) $display("[tb_pipeline] ALL PASS");
    else             $display("[tb_pipeline] %0d ERRORS", errors);
    $finish;
  end

endmodule
