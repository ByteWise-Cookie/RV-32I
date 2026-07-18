// -----------------------------------------------------------------------------
// load_unit.sv  -  Sub-word load extraction and sign/zero extension
//
// The external data memory returns the aligned 32-bit word containing the
// address.  This block selects the requested byte/half using addr[1:0] and
// extends it per funct3 (LB/LH sign-extend, LBU/LHU zero-extend, LW passes).
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

import rv32i_pkg::*;

module load_unit (
  input  logic [2:0]  funct3,
  input  logic [1:0]  addr_lo,   // byte offset within the word
  input  logic [31:0] word,      // raw word from memory
  output logic [31:0] load_data
);

  logic [7:0]  b;
  logic [15:0] h;

  always_comb begin
    // Byte select
    unique case (addr_lo)
      2'b00: b = word[7:0];
      2'b01: b = word[15:8];
      2'b10: b = word[23:16];
      2'b11: b = word[31:24];
    endcase
    // Half select (addr_lo[1] picks lower/upper half)
    h = addr_lo[1] ? word[31:16] : word[15:0];

    unique case (funct3)
      F3_B : load_data = {{24{b[7]}},  b};   // LB
      F3_H : load_data = {{16{h[15]}}, h};   // LH
      F3_W : load_data = word;               // LW
      F3_BU: load_data = {24'b0, b};         // LBU
      F3_HU: load_data = {16'b0, h};         // LHU
      default: load_data = word;
    endcase
  end

endmodule
