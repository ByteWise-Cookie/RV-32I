// -----------------------------------------------------------------------------
// forwarding_unit.sv  -  EX-stage operand forwarding
//
// Resolves read-after-write hazards for back-to-back dependent instructions by
// steering the freshest producer value onto each EX operand:
//
//   fwd = 2'b10  forward from EX/MEM  (highest priority, most recent)
//   fwd = 2'b01  forward from MEM/WB
//   fwd = 2'b00  no forward, use the register-file value
//
// Load-use hazards (producer still in EX as a load) are NOT solved here; the
// hazard unit inserts a stall so the value is available from EX/MEM next cycle.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module forwarding_unit (
  input  logic [4:0] ex_rs1,
  input  logic [4:0] ex_rs2,
  input  logic [4:0] mem_rd,
  input  logic       mem_reg_write,
  input  logic [4:0] wb_rd,
  input  logic       wb_reg_write,
  output logic [1:0] fwd_a,
  output logic [1:0] fwd_b
);

  always_comb begin
    // rs1
    if (mem_reg_write && (mem_rd != 5'd0) && (mem_rd == ex_rs1))
      fwd_a = 2'b10;
    else if (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == ex_rs1))
      fwd_a = 2'b01;
    else
      fwd_a = 2'b00;

    // rs2
    if (mem_reg_write && (mem_rd != 5'd0) && (mem_rd == ex_rs2))
      fwd_b = 2'b10;
    else if (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == ex_rs2))
      fwd_b = 2'b01;
    else
      fwd_b = 2'b00;
  end

endmodule
