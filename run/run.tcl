# Compile phase
-64bit \
-access +rwc \
-timescale 1ns/1ps \
-sv \
+define+NETLIST_SIM \
-sdf_file /home/sakamoto/E203_Accelerator/output_acc/acc_top_typical.sdf \
-v /home/sakamoto/NangateOpenCellLibrary/Front_End/Verilog/NangateOpenCellLibrary.v \
/home/sakamoto/E203_Accelerator/output_acc/acc_top_netlist.v \
/home/sakamoto/E203_Accelerator/tb/icb_slave_tb.sv \
/home/sakamoto/E203_Accelerator/rtl/freepdk45_sram_1rw1r_32x8192_8.v \
-elaborate \
-licqueue \
+sdf_verbose \
-input wave.tcl