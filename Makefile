# -----------------------------------------------------------------------------
# RV32I core - simulation build (Icarus Verilog)
#
#   make single    build + run the single-cycle self-checking testbench
#   make pipeline  build + run the 5-stage pipeline self-checking testbench
#   make all       run both
#   make clean     remove build products
#
# Run from the repository root so prog/test1.hex resolves for $readmemh.
# -----------------------------------------------------------------------------
IVERILOG := iverilog
VVP      := vvp
IVFLAGS  := -g2012 -Wall

COMMON := rtl/common/rv32i_pkg.sv \
          rtl/common/reg_file.sv \
          rtl/common/imm_gen.sv \
          rtl/common/alu.sv \
          rtl/common/alu_control.sv \
          rtl/common/branch_unit.sv \
          rtl/common/control.sv \
          rtl/common/load_unit.sv \
          rtl/common/store_unit.sv

SC_SRC := $(COMMON) rtl/single_cycle/rv32i_single_cycle.sv \
          sim/mem_model.sv sim/tb_single_cycle.sv

PL_SRC := $(COMMON) \
          rtl/pipeline/forwarding_unit.sv \
          rtl/pipeline/hazard_unit.sv \
          rtl/pipeline/rv32i_pipeline.sv \
          sim/mem_model.sv sim/tb_pipeline.sv

BUILD := build

.PHONY: all single pipeline clean
all: single pipeline

single: $(BUILD)/tb_single_cycle.vvp
	$(VVP) $<

pipeline: $(BUILD)/tb_pipeline.vvp
	$(VVP) $<

$(BUILD)/tb_single_cycle.vvp: $(SC_SRC) prog/test1.hex | $(BUILD)
	$(IVERILOG) $(IVFLAGS) -s tb_single_cycle -o $@ $(SC_SRC)

$(BUILD)/tb_pipeline.vvp: $(PL_SRC) prog/test1.hex | $(BUILD)
	$(IVERILOG) $(IVFLAGS) -s tb_pipeline -o $@ $(PL_SRC)

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)
