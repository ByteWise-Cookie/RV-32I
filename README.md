# RV32I Processor Core (RISC-V)

A clean, modular, synthesizable **RV32I** CPU in SystemVerilog, in two flavours
that share one set of building blocks:

- **Single-cycle** — one instruction per clock, easiest to read.
- **5-stage pipeline** — IF/ID/EX/MEM/WB with forwarding, load-use stalls, and
  branch/jump flush.

Both cores retire the same programs to **identical architectural state**, checked
by self-checking testbenches.

```
rtl/
  common/            shared, reusable blocks (package, ALU, control, reg file, ...)
  single_cycle/      rv32i_single_cycle.sv
  pipeline/          rv32i_pipeline.sv  + forwarding_unit + hazard_unit
sim/                 memory model + self-checking testbenches
prog/                test1.hex  (hand-assembled RV32I program)
docs/                SPEC.md, single_cycle.md, pipeline.md
scripts/run_sim.sh   build + run both testbenches (native or containerised)
Makefile             make single | pipeline | all | clean
```

## Documentation

- [`docs/SPEC.md`](docs/SPEC.md) — supported ISA, instruction formats, memory
  interface, module hierarchy, control table.
- [`docs/single_cycle.md`](docs/single_cycle.md) — single-cycle datapath and
  next-PC logic.
- [`docs/pipeline.md`](docs/pipeline.md) — pipeline stages and every hazard
  (forwarding, WB→ID bypass, load-use stall, control flush).

## Supported ISA

Full RV32I base: R/I ALU ops, `LB/LH/LW/LBU/LHU`, `SB/SH/SW`, all six branches,
`JAL/JALR`, `LUI/AUIPC`. `FENCE`/`ECALL`/`EBREAK` decode as NOP (no CSR/trap
support). An optional RV32M multiply/divide unit (`rtl/common/alu_m.sv`) is
included but not wired into the base datapath. See the spec for the full list
and exclusions.

## Simulate

Uses [Icarus Verilog](http://iverilog.icarus.com/). From the repository root:

```bash
make all            # build + run both testbenches (needs native iverilog)
# or, native OR containerised (auto-falls back to podman/docker):
sh scripts/run_sim.sh
```

Expected output (both cores):

```
[tb_single_cycle] register check:
  ok   x1 = 00000005
  ...
[tb_single_cycle] ALL PASS
[tb_pipeline] ALL PASS
```

The testbenches load `prog/test1.hex`, run to a halt loop, and compare the
register file against hand-computed values. `test1.hex` exercises R/I ALU ops,
load/store, a load-use hazard, a taken branch, a jump, `LUI`, and `AUIPC`.

## Memory interface

Both cores expose a Harvard, combinational-read interface (instruction + data)
driven externally by the testbench or an SoC wrapper; data memory is word-wide
with a per-byte write strobe. Details in [`docs/SPEC.md`](docs/SPEC.md).

## Status

| Core | Simulated (Icarus) | Result |
|------|--------------------|--------|
| `rv32i_single_cycle` | yes | ALL PASS |
| `rv32i_pipeline`     | yes | ALL PASS |

RTL is written to the SystemVerilog LRM and elaborates on Icarus Verilog; the
`sorry`/`unique`-related messages Icarus prints are cosmetic (dev-build
limitations) and do not affect results. Synthesis (Vivado/Yosys) has not been
re-run against this rewrite.
