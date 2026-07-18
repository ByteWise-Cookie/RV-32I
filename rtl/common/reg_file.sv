// -----------------------------------------------------------------------------
// reg_file.sv  -  32 x 32-bit register file
//
//   * x0 is hardwired to zero (write to x0 ignored, read of x0 returns 0).
//   * Two asynchronous (combinational) read ports.
//   * One synchronous write port (write on rising clk when we=1).
//   * Plain reads: a read returns the stored value (no write-first bypass).
//     The single-cycle core reads operands before it writes its own result,
//     and the pipeline resolves the WB->ID same-cycle case with explicit
//     forwarding, so no internal bypass is needed (and adding one would form a
//     combinational loop when rd == rs in the single-cycle datapath).
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module reg_file (
  input  logic        clk,
  input  logic        rst,          // synchronous, active-high: clears all regs
  input  logic        we,           // write enable
  input  logic [4:0]  rd_addr,      // write address
  input  logic [31:0] rd_data,      // write data
  input  logic [4:0]  rs1_addr,
  input  logic [4:0]  rs2_addr,
  output logic [31:0] rs1_data,
  output logic [31:0] rs2_data
);

  logic [31:0] regs [31:0];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 32; i++)
        regs[i] <= 32'b0;
    end else if (we && (rd_addr != 5'd0)) begin
      regs[rd_addr] <= rd_data;
    end
  end

  // Asynchronous read, x0 forced to zero.
  assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
  assign rs2_data = (rs2_addr == 5'd0) ? 32'b0 : regs[rs2_addr];

endmodule
