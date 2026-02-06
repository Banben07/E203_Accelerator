# ==============================================================================
# Basic Setup
# ==============================================================================
# Include base UVM Makefile if needed (often defines UVM_HOME, etc.)
# Comment out if not strictly needed or causing conflicts.
include $(UVM_HOME)/examples/Makefile.ius

SHELL := /bin/zsh
export PATH := $(PATH)

# Default UVM Test
UVM_TESTNAME ?= test0

# Enable Coverage Collection (0 = off, 1 = on)
COVER ?= 0

WAVE ?= 1 # Enable waveform generation (0 = off, 1 = on)

# Default simulator (can be changed via command line, e.g., make SIMULATOR=xcelium)
SIMULATOR ?= xcelium # Default to xcelium, can be set to vcs

# ==============================================================================
# Tool Paths & Common Flags
# ==============================================================================
# Define tool commands (allows easy switching if needed)
VCS      := vcs
XCELIUM  := xrun
IMC      := source ~/.zshrc && imc
VERDI    := verdi
DVE      := dve
URG      := urg
GENUS    := genus
INDAGO   := indago

# Common Compile/Elaboration Flags
COMMON_FLAGS = \
	-f filelist.f 

# Common Simulation Flags
COMMON_SIM_FLAGS = \
	+UVM_TESTNAME=$(UVM_TESTNAME) 

# ==============================================================================
# VCS Specific Settings (Synopsys)
# ==============================================================================
VCS_COMPILE_FLAGS = \
	-sverilog +v2k \
	-lwdgen \
	-debug_access+all \
	+define+SVA+ASSERT_ON \
	-fsdb \
	+define+A \
	$(COMMON_FLAGS)

VCS_SIM_FLAGS = \
	$(COMMON_SIM_FLAGS) \
	+fsdb+sva_success

# Conditional VCS Coverage Flags
VCS_COVER_FLAGS_COMPILE =
VCS_COVER_FLAGS_SIM =
ifeq ($(COVER), 1)
  VCS_COVER_FLAGS_COMPILE = -cm line+cond+fsm+tgl+branch -debug_access+all # debug_access needed for coverage
  VCS_COVER_FLAGS_SIM = -cm line+cond+fsm+tgl+branch
endif

# ==============================================================================
# Xcelium Specific Settings (Cadence)
# ==============================================================================
XCELIUM_COMPILE_FLAGS = \
	-64bit \
	-lwdgen \
    -sv \
    -access +rwc \
    -svseed random \
    -sva \
    -status \
    $(COMMON_FLAGS) \
    -errormax 15
    # Multi-core flags (use if needed and licensed)
    # -mce
    # -mcmaxcores 16
    # -mce_sim_thread_count 16
    # -mce_pie

XCELIUM_SIM_FLAGS = \
	$(COMMON_SIM_FLAGS) \
	-timescale 1ns/1ps

# 根据COVER值决定是否添加run.tcl
ifeq ($(WAVE), 1)
  ifneq ($(COVER), 1)
  	XCELIUM_SIM_FLAGS += -input run.tcl
  endif
endif

# Conditional Xcelium Coverage Flags
XCELIUM_COVER_FLAGS_COMPILE =
IMC_REPORT_DIR = coverage_report_imc
ifeq ($(COVER), 1)
  # -coverage all: Enables common coverage metrics (block, expr, toggle, fsm, assertion)
  # -covoverwrite: Deletes previous coverage database for this test before starting
  # -covtest $(UVM_TESTNAME): Names the specific test run within the coverage database
  # -covworkdir cov_work: Specifies the directory for the coverage database (default is ./cov_work)
  XCELIUM=/opt/cadence/xceliummain20.09/tools/bin/64bit/xrun
  XCELIUM_COMPILE_FLAGS += -coverage all -covoverwrite -covtest $(UVM_TESTNAME) -covworkdir cov_work -xmlibdirname cover/xcelium.d
endif

# ==============================================================================
# Default Target
# ==============================================================================
all: run

# ==============================================================================
# Generic Targets (Dispatch based on SIMULATOR variable)
# ==============================================================================
compile:
	@echo "Compiling using $(SIMULATOR)..."
	@$(MAKE) compile_$(SIMULATOR)

run: 
	@echo "Running simulation using $(SIMULATOR)..."
	@$(MAKE) run_$(SIMULATOR)

report_cover: run # Ensure simulation ran first
	@echo "Generating coverage report using $(SIMULATOR)..."
	@$(MAKE) report_cover_$(SIMULATOR)

gui_debug: run # Ensure simulation ran first
	@echo "Starting GUI debugger for $(SIMULATOR)..."
	@$(MAKE) gui_debug_$(SIMULATOR)

# ==============================================================================
# VCS Targets
# ==============================================================================
compile_vcs: filelist.f generate
	$(VCS) $(VCS_COMPILE_FLAGS) $(VCS_COVER_FLAGS_COMPILE) -o simv

run_vcs: compile_vcs
	./simv $(VCS_SIM_FLAGS) $(VCS_COVER_FLAGS_SIM)

report_cover_vcs: run_vcs
	@echo "Generating VCS coverage report..."
	$(URG) -dir simv.vdb $(VCS_SIM_FLAGS_COVER) -format both -report coverage_report_vcs
	@echo "VCS Coverage reports generated in ./coverage_report_vcs"
	# Optional: Launch DVE GUI for coverage
	# $(DVE) -cov -dir simv.vdb &

gui_debug_vcs: run_vcs
	$(DVE) -vpd vcdplus.vpd &

# ==============================================================================
# Xcelium Targets
# ==============================================================================
# Xcelium uses a single command for compile+elaborate+simulate or compile+elaborate only
# This target performs compile + elaborate + simulate in one step
run_xcelium: filelist.f run.tcl 
	$(XCELIUM) $(XCELIUM_COMPILE_FLAGS) $(XCELIUM_SIM_FLAGS) -l run.log

# Target to only compile/elaborate (creates snapshot) without running simulation
compile_xcelium: filelist.f 
	$(XCELIUM) $(XCELIUM_COMPILE_FLAGS) -l compile.log -compile -exit

# Target to run simulation from an existing snapshot (less common for simple flows)
# run_xcelium_snapshot:
#	$(XCELIUM) -R $(XCELIUM_SIM_FLAGS)

report_cover_xcelium: run_xcelium
	@echo "Generating Xcelium coverage report using IMC..."
ifeq ($(COVER), 1)

	@[ -d cov_work/scope/$(UVM_TESTNAME) ] || { echo "Coverage database cov_work/scope/$(UVM_TESTNAME) not found. Did you run with COVER=1?"; exit 1; }

# $(IMC) -exec merge_coverage.tcl
	$(IMC) -load cov_work/scope/$(UVM_TESTNAME)
# $(IMC) -batch -load cov_work/scope/$(UVM_TESTNAME) \
# "report summary -out coverage_report_imc/summary.rpt; \
#  report html -out coverage_report_imc/html; \
#  exit"
	@echo "IMC Coverage reports generated in $(IMC_REPORT_DIR)/$(UVM_TESTNAME)"
else
	@echo "Coverage was not enabled (COVER=0). No report generated."
endif

# Target to launch IMC GUI
gui_cover_imc: run_xcelium
	@echo "Launching IMC GUI..."
ifeq ($(COVER), 1)
	@[ -d cov_work/$(UVM_TESTNAME) ] || { echo "Coverage database cov_work/$(UVM_TESTNAME) not found. Did you run with COVER=1?"; exit 1; }
	$(IMC) -gui -load cov_work/$(UVM_TESTNAME) &
else
	@echo "Coverage was not enabled (COVER=0). Cannot launch IMC."
endif

# Target to launch Verdi (FSDB) or Xcelium GUI (SimVision - SHM/FSDB)
gui_debug_xcelium: run_xcelium
	@echo "Launching SimVision GUI..."
	# Assumes run.tcl generated waves (e.g., using probe + database commands) into waves.shm or similar
	# Or if FSDB was generated via Tcl commands (e.g., dump -file test.fsdb)
	# Check for FSDB first, then SimVision default database
	@if [ -f test.fsdb ]; then \
		echo "Found test.fsdb, launching Verdi..."; \
		$(VERDI) -ssf test.fsdb & \
	elif [ -d xcelium.d/waves.shm ]; then \
		echo "Found waves.shm, launching SimVision..."; \
		simvision xcelium.d/waves.shm & \
	else \
		echo "No standard wave database (test.fsdb or waves.shm) found. Cannot launch waveform GUI."; \
	fi


# ==============================================================================
# Other Tools & Utilities
# ==============================================================================
generate:
	@echo "Running test generation script..."
	python ./utils/conv_test.py

indago:
	$(INDAGO) -db SmartLogWaves.db

genus:
	$(GENUS) -f run_synthesis.tcl

# Regenerate filelist (use cautiously if manual edits exist)
find:
	@echo "Generating filelist.f..."
	rm -f filelist.f
	find . -name "*.sv" >> filelist.f
	find . -name "*.v" >> filelist.f
	@echo "filelist.f generated."

# ==============================================================================
# Clean Target
# ==============================================================================
clean:
	@echo "Cleaning generated files..."
	sh -c 'rm -rf core csrc simv* vc_hdrs.h ucli.key urg* *.log \
	compile.log sim.log xcelium_compile.log xcelium_sim.log imc_batch.log verisium_debug_logs* vmgr_db imc.key cover/*.d\
	coverage_report_vcs/ coverage_report_imc/ \
	*.fsdb *.vpd DVEfiles transcript .ida* .indago* *.db indago* *.d \
	xrun.* xcelium.* cov_work/ \
	novas.* genus.* innovus.* \
	NCA_libs/ irun.key *.history *.dsn *.trn \
	imc_report.tcl'

# ==============================================================================
# Phony Targets (Prevent conflicts with filenames)
# ==============================================================================
.PHONY: all compile run report_cover gui_debug \
	compile_vcs run_vcs report_cover_vcs gui_debug_vcs \
	compile_xcelium run_xcelium report_cover_xcelium gui_cover_imc gui_debug_xcelium \
	generate indago genus find cleans