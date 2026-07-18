// -----------------------------------------------------------------------------
// mem_model.sv  -  Simple Harvard memory model for simulation
//
// Separate instruction and data arrays, both word-organised and byte-writable.
//   * Instruction port : combinational read (word at imem_addr).
//   * Data port        : combinational read + synchronous byte-strobed write.
// The program is loaded into instruction memory from a hex file ($readmemh,
// one 32-bit word per line).  Only the low address bits index the arrays.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module mem_model #(
  parameter int    WORDS   = 1024,           // 4 KiB per array
  parameter string HEXFILE = ""
) (
  input  logic        clk,

  input  logic [31:0] imem_addr,
  output logic [31:0] imem_rdata,

  input  logic [31:0] dmem_addr,
  input  logic [31:0] dmem_wdata,
  input  logic [3:0]  dmem_wstrb,
  input  logic        dmem_we,
  input  logic        dmem_re,
  output logic [31:0] dmem_rdata
);

  localparam int IDXW = $clog2(WORDS);

  logic [31:0] imem [0:WORDS-1];
  logic [31:0] dmem [0:WORDS-1];

  logic [IDXW-1:0] iidx, didx;
  assign iidx = imem_addr[IDXW+1:2];
  assign didx = dmem_addr[IDXW+1:2];

  initial begin
    for (int i = 0; i < WORDS; i++) begin
      imem[i] = 32'b0;
      dmem[i] = 32'b0;
    end
    if (HEXFILE != "") $readmemh(HEXFILE, imem);
  end

  assign imem_rdata = imem[iidx];
  assign dmem_rdata = dmem[didx];

  always_ff @(posedge clk) begin
    if (dmem_we) begin
      if (dmem_wstrb[0]) dmem[didx][7:0]   <= dmem_wdata[7:0];
      if (dmem_wstrb[1]) dmem[didx][15:8]  <= dmem_wdata[15:8];
      if (dmem_wstrb[2]) dmem[didx][23:16] <= dmem_wdata[23:16];
      if (dmem_wstrb[3]) dmem[didx][31:24] <= dmem_wdata[31:24];
    end
  end

endmodule
