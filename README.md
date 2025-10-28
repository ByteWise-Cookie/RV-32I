
# RV-32I Processor Design (RISC-V)

This repository contains the complete design, implementation, and testing of a 32-bit RISC-V processor core (RV-32I) developed using **SystemVerilog** and **Xilinx Vivado**.  
The goal of this project is to build a **clean, modular, and synthesizable implementation** of the base integer instruction set architecture (RV32I), suitable for both simulation and FPGA deployment.

---

## 🧠 Overview

RISC-V is an open-source Instruction Set Architecture (ISA) designed for simplicity, modularity, and extensibility.  
This project focuses on implementing the **RV32I base ISA**, which supports 32-bit integer operations.

The CPU is designed using **SystemVerilog** in a fully structural and behavioral hierarchy, with the aim of:
- Learning the RISC-V architecture fundamentals
- Exploring pipelined CPU design
- Understanding ALU, control unit, register file, and memory interface design
- Synthesizing and testing on an FPGA board

---

## ⚙️ Features

- **ISA Support:** Full RV32I instruction set  
- **Pipeline:** Single-cycle (upgradable to 5-stage)  
- **ALU Operations:** ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, etc.  
- **Control Unit:** Decodes R-type, I-type, S-type, B-type, and J-type instructions  
- **Register File:** 32 general-purpose 32-bit registers with x0 hardwired to zero  
- **Memory Interface:** Separate instruction and data memory modules  
- **Branch & Jump Handling:** Supports PC update logic for BEQ, BNE, JAL, and JALR  
- **Synthesizable:** Ready for FPGA implementation on Xilinx boards  

---

## 🧩 Design Hierarchy

RV-32I/
├── ALU/
│ ├── alu.sv
│ └── alu_control.sv
├── Control_Unit/
│ └── main_control.sv
├── Datapath/
│ ├── register_file.sv
│ ├── immediate_gen.sv
│ ├── muxes.sv
│ └── program_counter.sv
├── Memory/
│ ├── instruction_memory.sv
│ └── data_memory.sv
├── top_module.sv
└── testbench/
└── rv32i_tb.sv



---

## 🧪 Simulation

You can simulate the design using:
- **Vivado Simulator**
- **Icarus Verilog** or **ModelSim**

Example:
```bash
iverilog -o rv32i_tb rv32i_tb.sv top_module.sv
vvp rv32i_tb
gtkwave dump.vcd

