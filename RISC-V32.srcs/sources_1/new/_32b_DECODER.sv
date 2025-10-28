`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 12:02:18 AM
// Design Name: 
// Module Name: _32b_DECODER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module _32b_DECODER( 
  input logic [31:0] Iin,
  output logic [4:0] rs1, rs2, rd,
  output logic [11:0] imm12,
  output logic [6:0] opcode,
  output logic [2:0] fun3,
  output logic [6:0] fun7
  );

  assign imm12 = Iin[31:20];
  assign opcode = Iin[6:0];
  assign rs1 = Iin[19:15];
  assign rs2 = Iin[24:20];
  assign fun3 = Iin[14:12];
  assign fun7 = Iin[31:25];
  assign rd = Iin[11:7];

endmodule
