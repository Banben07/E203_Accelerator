include $(UVM_HOME)/examples/Makefile.vcs

UVM_TESTNAME := test0

COVER := 0

ifeq ($(COVER), 1)
VCS_FLAGS_COVER = -cm line+cond+fsm+tgl+branch
SIM_FLAGS_COVER = -cm line+cond+fsm+tgl+branch
endif

# 编译选项
VCSDIY = vcs
VCS_FLAGS = -sverilog +v2k $(VCS_FLAGS_COVER) -debug_all +define+SVA+ASSERT_ON -fsdb -l com.log


# 仿真选项
SIM = ./simv $(VCS_FLAGS_COVER) +fsdb+sva_success
SIM_FLAGS =

# 默认目标
all: sim 

# 编译目标
sim: compile
	$(SIM) $(SIM_FLAGS) -l sim.log

compile: filelist.f
	$(VCSDIY) $(VCS_FLAGS) -o $(SIM) -f $^

uvm: filelist.f
	$(VCS) +incdir+../sV \
		-f $^

run: uvm
	$(SIMV) +UVM_TESTNAME=$(UVM_TESTNAME)
	$(CHECK)

dve: 
	dve -vpd vcdplus.vpd &

cover:
	urg -dir simv.vdb -format both -report cover
	dve -cov -dir simv.vdb &

verdi: sim
	verdi  -f filelist.f -ssf test.fsdb &

find:
	find -name "*.sv" >> filelist.f
	find -name "*.v" >> filelist.f

# 清理目标、uvm环境中已有
# clean:
# 	rm -rf *.log csrc simv* *.key *.vpd DVEfile coverage *.vdb

.PHONY: all sim compile dve verdi clean find
