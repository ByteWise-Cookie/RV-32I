`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2025 10:18:10 PM
// Design Name: 
// Module Name: _top_module
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


module _top_module(
input logic clk, master_reset, // clk , master_reset => PC == 0, REG_FILE == 0
input logic [31:0] instru, // Instruction
input logic [31:0] mem_data_in, // Memory data from test_bench
output logic [31:0] PC_instru_addr_out, // Instruction address
output logic [31:0] mem_data_out, // Data to memory
output logic [31:0] mem_addr_out // Data addrress in memory
);


logic MEMTO_REG, ALU_SRC, MEM_WRITE, MEM_READ, REG_WRITE, BRANCH, ZERO_FLAG;
logic [1:0] COMPARATOR_CLT;
logic [4:0] RS1, RS2, RD;
logic [11:0] IMM12;
logic [6:0] OPCODE;
logic [2:0] FUN3;
logic [6:0] FUN7;
logic [31:0] PC_NEXT, PC_OFFSET, PC_NEW, REG1, REG2, IMM32, ALU_BUFFER, RESULT, DATA_IN;

assign mem_data_out = REG2;
assign mem_addr_out = RESULT;

assign PC_NEXT = PC_NEW + 4;
assign PC_select = BRANCH && ZERO_FLAG;

//PC offset Adder
assign PC_OFFSET = PC_address + ({1'b0 + {IMM12}} << 1);

// PC select MUX
_PC_select _PC_select(
.s(PC_select),
.id0(PC_NEXT),
.id1(PC_OFFSET),
.od(PC_NEW)
);

//PC
 _PC_32b_ pc(
.clk(clk),
.high_rst(master_reset), 
.write_enable(1'b0), // Hard code to one
.PCin(PC_NEW),
.PCout(PC_address) // Output to test bench
);

// DECODER
_32b_DECODER _decoder ( 
.Iin(instru), // From Test Bench
.rs1(RS1), 
.rs2(RS2),
.rd(RD),
.imm12(IMM12),
.opcode(OPCODE),
.fun3(FUN3),
.fun7(FUN7)
);

// REG_FILE
_32b_REG_FILE _reg_file (
.clk(clk), 
.high_rst(master_reset),
.write_enable(REG_WRITE),
.din(DATA_IN),
.rs1(RS1),
.rs2(RS2),
.rd(RD),
.reg1(REG1), 
.reg2(REG2)
);

// IMM_GEN
_IMMGEN imm_gen (
.imm12(IMM12),
.signed_32(IMM32)
);

// ALU_SRC
_2o1_MUX _alu_src (
.s(ALU_SRC),
.id0(REG2),
.id1(IMM32),
.od(ALU_BUFFER)
);



// CONTROL_UNIT
_main_ctl_ control_unit (
.opcode(OPCODE),
.RegWrite(REG_WRITE),
.ALUSrc(ALU_SRC),
.MemRead(MEM_READ),
.MemWrite(MEM_WRITE),
.MemtoReg(MEMTO_REG),
.Branch(BRANCH),
.ALUOp(ALUOP)
);

// ALU_CONTROL
_ALU_ctl alu_ctl (
.fun3(FUN3),
.fun7(FUN7),
.alu_ctl(ALU_CTL),
.carry(CARRY),
.comparator_clt(COMPARATOR_CLT)
);
  
// ALU
_32b_ALU _alu (
.op1(REG1),
.op2(ALU_BUFFER),
.alu_ctl(ALU_CTL),
.result(RESULT),
.zero_flag(ZERO_FLAG),
.comparator_clt(COMPARARTOR_CLT)
);

//Output MUX
_2o1_MUX _output_mux (
.s(MEMTO_REG),
.id0(RESULT),
.id1(mem_data_in),
.od(DATA_IN) // From TB
);

endmodule