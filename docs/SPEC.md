# RV32I Core — Specification

This document is the contract the RTL implements: the supported instruction
set, the module hierarchy, and the memory interface both cores expose. Two
implementations share one set of building blocks (`rtl/common/`): a
**single-cycle** core and a **5-stage pipelined** core. Both retire the same
programs to identical architectural state (proven by the self-checking
testbenches).

---

## 1. Supported ISA — RV32I base

32 general-purpose 32-bit registers (`x0`–`x31`, `x0` hardwired to 0), a 32-bit
PC, little-endian, byte-addressed memory.

| Group | Instructions | Notes |
|-------|--------------|-------|
| Register-register (R) | `ADD SUB SLL SLT SLTU XOR SRL SRA OR AND` | `funct7[5]` selects SUB/SRA |
| Register-immediate (I) | `ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI` | shifts use `shamt = imm[4:0]`, `funct7[5]` selects SRAI |
| Load (I) | `LB LH LW LBU LHU` | sub-word extract + sign/zero extend |
| Store (S) | `SB SH SW` | byte-strobed writes |
| Branch (B) | `BEQ BNE BLT BGE BLTU BGEU` | compared in a dedicated branch unit |
| Jump | `JAL` (J), `JALR` (I) | link = PC+4; JALR target `(rs1+imm) & ~1` |
| Upper immediate (U) | `LUI`, `AUIPC` | `LUI` writes `imm`; `AUIPC` writes `PC+imm` |
| System / misc | `FENCE`, `ECALL`, `EBREAK` | decoded as NOP (no CSR/trap support) |

**Not implemented (out of RV32I base):** CSRs, traps/interrupts, `FENCE.I`,
misaligned-access faults. Misaligned loads/stores are serviced by the memory
model rather than trapped.

### Optional RV32M
`rtl/common/alu_m.sv` implements `MUL MULH MULHSU MULHU DIV DIVU REM REMU`
per the RISC-V spec (including divide-by-zero and signed-overflow results).
It is provided for completeness and **not wired into the base datapath**; hook
it in behind an `RV32M` build parameter if the multiply/divide opcode is added
to the control unit.

---

## 2. Instruction formats

```
 31        25 24   20 19   15 14  12 11    7 6     0
 ┌───────────┬───────┬───────┬──────┬───────┬───────┐
 │  funct7   │  rs2  │  rs1  │funct3│  rd   │opcode │  R-type
 ├───────────┴───────┼───────┼──────┼───────┼───────┤
 │    imm[11:0]      │  rs1  │funct3│  rd   │opcode │  I-type
 ├───────────┬───────┼───────┼──────┼───────┼───────┤
 │ imm[11:5] │  rs2  │  rs1  │funct3│imm[4:0]│opcode│  S-type
 ├─┬─────────┼───────┼───────┼──────┼─────┬─┼───────┤
 │i│imm[10:5]│  rs2  │  rs1  │funct3│i[4:1│i│opcode │  B-type (imm[12|10:5|4:1|11])
 ├─┴─────────┴───────┴───────┴──────┼───────┼───────┤
 │            imm[31:12]            │  rd   │opcode │  U-type
 ├──────────────────────────────────┼───────┼───────┤
 │  imm[20|10:1|11|19:12]           │  rd   │opcode │  J-type
 └──────────────────────────────────┴───────┴───────┘
```

Immediate assembly lives in `rtl/common/imm_gen.sv`, selected by opcode. All
immediates are sign-extended.

---

## 3. Memory interface (both cores)

Harvard, combinational-read, driven by the testbench/SoC. Word-organised data
memory with a per-byte write strobe.

| Signal | Dir | Width | Meaning |
|--------|-----|-------|---------|
| `imem_addr`  | out | 32 | instruction byte address (= PC) |
| `imem_rdata` | in  | 32 | instruction word |
| `dmem_addr`  | out | 32 | data byte address (= ALU result) |
| `dmem_wdata` | out | 32 | store data, aligned into byte lanes |
| `dmem_wstrb` | out | 4  | per-byte write enable (SB/SH/SW) |
| `dmem_we`    | out | 1  | store this cycle |
| `dmem_re`    | out | 1  | load this cycle |
| `dmem_rdata` | in  | 32 | loaded word (extracted/extended in `load_unit`) |
| `pc_debug`   | out | 32 | current PC (observability) |

The data memory is expected to return the aligned word containing `dmem_addr`;
sub-word selection and extension happen inside the core (`load_unit`,
`store_unit`).

---

## 4. Module hierarchy

```
rv32i_pkg                 shared types / opcodes / ALU + control encodings
common/
  reg_file                32x32 regs, x0=0, sync write, async read
  imm_gen                 I/S/B/U/J immediate assembly
  alu                     ADD SUB SLL SLT SLTU XOR SRL SRA OR AND (+PASS)
  alu_control             ALUOp + funct -> alu_op
  branch_unit             six branch conditions
  control                 opcode -> datapath control signals
  load_unit               sub-word load extract + extend
  store_unit              store alignment + byte strobe
  alu_m                   OPTIONAL RV32M mul/div (not wired in base)

single_cycle/
  rv32i_single_cycle      one instruction per clock

pipeline/
  forwarding_unit         EX-stage operand forwarding
  hazard_unit             load-use stall detection
  rv32i_pipeline          IF | ID | EX | MEM | WB
```

See [`single_cycle.md`](single_cycle.md) and [`pipeline.md`](pipeline.md) for
the datapath and hazard details.

---

## 5. Control signal summary

Produced by `control.sv` from the opcode:

| opcode | reg_write | alu_src_a | alu_src_b | mem_read | mem_write | branch | jump | jalr | wb_sel | alu_op_sel |
|--------|:---------:|:---------:|:---------:|:--------:|:---------:|:------:|:----:|:----:|--------|------------|
| OP (R)     | 1 | rs1 | rs2 | 0 | 0 | 0 | 0 | 0 | ALU | RTYPE  |
| OP-IMM (I) | 1 | rs1 | imm | 0 | 0 | 0 | 0 | 0 | ALU | ITYPE  |
| LOAD       | 1 | rs1 | imm | 1 | 0 | 0 | 0 | 0 | MEM | ADD    |
| STORE      | 0 | rs1 | imm | 0 | 1 | 0 | 0 | 0 | –   | ADD    |
| BRANCH     | 0 | rs1 | rs2 | 0 | 0 | 1 | 0 | 0 | –   | BRANCH |
| LUI        | 1 |  –  |  –  | 0 | 0 | 0 | 0 | 0 | IMM | ADD    |
| AUIPC      | 1 | PC  | imm | 0 | 0 | 0 | 0 | 0 | ALU | ADD    |
| JAL        | 1 |  –  |  –  | 0 | 0 | 0 | 1 | 0 | PC4 | ADD    |
| JALR       | 1 |  –  |  –  | 0 | 0 | 0 | 1 | 1 | PC4 | ADD    |
| others     | 0 |  –  |  –  | 0 | 0 | 0 | 0 | 0 | –   | ADD    |
