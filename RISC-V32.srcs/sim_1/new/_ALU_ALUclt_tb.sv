`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2025 09:12:19 PM
// Design Name: 
// Module Name: _ALU_ALUclt_tb
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


module _ALU_ALUclt_tb();
logic CARRY;
logic [2:0] COMPARATOR_CTL; 
reg [3:0] ALU_CTL;
logic [2:0] FUN3;
logic [6:0] FUN7;
wire [31:0] RESULT;
wire ZERO_FLAG;
reg [31:0] OP1, OP2;

DUT1 _ALU_ctl(
  .fun3(FUN3),
  .fun7(FUN7),
  .alu_ctl(ALU_CTL),
  .carry(CARRY),
  .comparator_clt(COMPARATOR_CTL)
  );
  
DUT2 _32b_ALU(
    .op1(OP1), 
    .op2(OP2),
    .alu_ctl(ALU_CTL),
    .result(RESULT),
    .zero_flag(ZERO_FLAG),
    .comprarator_clt(COMPARATOR_CTL)
    );
initial begin 
//nop
end

endmodule
