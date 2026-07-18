// -----------------------------------------------------------------------------
// hazard_unit.sv  -  Load-use stall detection
//
// A load's result is not available until the end of MEM, one cycle too late for
// an immediately dependent instruction sitting in ID.  When the instruction in
// EX is a load whose rd feeds either source register of the instruction in ID,
// we stall one cycle: freeze the PC and IF/ID register and inject a bubble into
// ID/EX.  Everything else is covered by forwarding.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module hazard_unit (
  input  logic       ex_mem_read,   // instruction in EX is a load
  input  logic [4:0] ex_rd,
  input  logic [4:0] id_rs1,
  input  logic [4:0] id_rs2,
  output logic       stall          // 1 = freeze PC + IF/ID, bubble ID/EX
);

  always_comb begin
    stall = ex_mem_read && (ex_rd != 5'd0) &&
            ((ex_rd == id_rs1) || (ex_rd == id_rs2));
  end

endmodule
