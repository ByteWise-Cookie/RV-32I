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
_pc_select _PC_select(
.s(PC_select),
.id0(PC_NEXT),
.id1(PC_OFFSET),
.od(PC_NEW)
);

//PC
_pc _PC_32b_(
.clk(clk),
.high_rst(master_reset), 
.write_enable(1'b0), // Hard code to one
.PCin(PC_NEW),
.PCout(PC_address) // Output to test bench
);

// DECODER
_decoder _32b_DECODER( 
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
_reg_file _32b_REG_FILE(
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
imm_gen _IMMGEN(
.imm12(IMM12),
.signed_32(IMM32)
);

// ALU_SRC
_alu_src _2o1_MUX(
.s(ALU_SRC),
.id0(REG2),
.id1(IMM32),
.od(ALU_BUFFER)
);



// CONTROL_UNIT
control_unit _main_ctl_(
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
alu_ctl _ALU_ctl(
.fun3(FUN3),
.fun7(FUN7),
.alu_ctl(ALU_CTL),
.carry(CARRY),
.comparator_clt(COMPARATOR_CLT)
);
  
// ALU
_alu _32b_ALU(
.op1(REG1),
.op2(ALU_BUFFER),
.alu_ctl(ALU_CTL),
.result(RESULT),
.zero_flag(ZERO_FLAG),
.comprarator_clt(COMPARARTOR_CLT)
);

//Output MUX
_output_mux _output_mux(
.s(MEMTO_REG),
.id0(RESULT),
.id1(mem_data_in),
.od(DATA_IN) // From TB
);

endmodule
