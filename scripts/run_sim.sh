#!/bin/sh
# -----------------------------------------------------------------------------
# run_sim.sh - build and run both self-checking testbenches with Icarus Verilog.
#
# Runs natively if `iverilog` is on PATH; otherwise falls back to a rootless
# container (podman/docker) carrying Icarus.  Invoke from the repository root:
#
#     sh scripts/run_sim.sh
# -----------------------------------------------------------------------------
set -e

IMAGE=docker.io/hdlc/iverilog:latest

# If iverilog is missing but a container engine exists, re-exec inside it.
if ! command -v iverilog >/dev/null 2>&1; then
  for ENGINE in podman docker; do
    if command -v "$ENGINE" >/dev/null 2>&1; then
      echo "iverilog not found; running via $ENGINE ($IMAGE)"
      exec "$ENGINE" run --rm -v "$PWD":/work:Z -w /work "$IMAGE" sh scripts/run_sim.sh
    fi
  done
  echo "error: need iverilog, or podman/docker to pull $IMAGE" >&2
  exit 1
fi

mkdir -p build

COMMON="rtl/common/rv32i_pkg.sv \
        rtl/common/reg_file.sv \
        rtl/common/imm_gen.sv \
        rtl/common/alu.sv \
        rtl/common/alu_control.sv \
        rtl/common/branch_unit.sv \
        rtl/common/control.sv \
        rtl/common/load_unit.sv \
        rtl/common/store_unit.sv"

echo "=== single-cycle ==="
iverilog -g2012 -s tb_single_cycle -o build/sc.vvp \
  $COMMON rtl/single_cycle/rv32i_single_cycle.sv sim/mem_model.sv sim/tb_single_cycle.sv
vvp build/sc.vvp

echo "=== pipeline ==="
iverilog -g2012 -s tb_pipeline -o build/pl.vvp \
  $COMMON rtl/pipeline/forwarding_unit.sv rtl/pipeline/hazard_unit.sv \
  rtl/pipeline/rv32i_pipeline.sv sim/mem_model.sv sim/tb_pipeline.sv
vvp build/pl.vvp
