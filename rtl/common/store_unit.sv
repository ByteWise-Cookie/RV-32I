// -----------------------------------------------------------------------------
// store_unit.sv  -  Sub-word store alignment and byte-enable generation
//
// Replicates the store data into the correct byte lane(s) of the word and
// produces the 4-bit byte-enable mask the external memory uses to commit only
// the addressed bytes.  Handles SB / SH / SW.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module store_unit (
  input  logic [2:0]  funct3,
  input  logic [1:0]  addr_lo,
  input  logic [31:0] rs2,
  output logic [31:0] wdata,
  output logic [3:0]  wstrb
);

  always_comb begin
    wdata = rs2;
    wstrb = 4'b0000;
    unique case (funct3)
      F3_B: begin                               // SB
        wdata = {4{rs2[7:0]}};
        wstrb = 4'b0001 << addr_lo;
      end
      F3_H: begin                               // SH  (addr_lo[1] picks half)
        wdata = {2{rs2[15:0]}};
        wstrb = addr_lo[1] ? 4'b1100 : 4'b0011;
      end
      F3_W: begin                               // SW
        wdata = rs2;
        wstrb = 4'b1111;
      end
      default: wstrb = 4'b0000;
    endcase
  end

endmodule
