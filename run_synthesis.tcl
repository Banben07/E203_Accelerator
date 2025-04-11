# Genus synthesis script for design with OpenRAM SRAM
set DESIGN_NAME "acc_top" 
set RTL_PATH "/home/sakamoto/E203_Accelerator/rtl"
set OUTPUT_PATH "./output_acc"
set SRAM_PATH "/home/sakamoto/OpenRAM/macros/freepdk45_sram_1rw1r_32x8192_8"
set_db max_cpus_per_server 12

set_multi_cpu_usage -local_cpu 12


# 创建输出目录
if {![file exists $OUTPUT_PATH]} {
    file mkdir $OUTPUT_PATH
}

# ---------------------------
# 1. 库文件设置
# ---------------------------
# 标准单元库
# 设置库搜索路径（包含标准单元和 SRAM 的目录）
set_db init_lib_search_path [list \
    "/home/sakamoto/NangateOpenCellLibrary/Front_End/Liberty/ECSM" \
    "${SRAM_PATH}" \
]
# 一次性读取所有库文件（避免多次调用 read_libs）
read_libs [list \
    "NangateOpenCellLibrary_typical_ecsm.lib" \
    "freepdk45_sram_1rw1r_32x8192_8_TT_1p0V_25C.lib" \
]

# 物理信息（可选，用于 Innovus 后端）
# set_db lef_library {
#     /path/to/your_tech.lef
#     "${SRAM_PATH}/freepdk45_sram_1rw1r_32x8192_8.lef"
# }

# 明确指定目标库为SRAM（关键！）
# set_db target_library "freepdk45_sram_1rw1r_32x8192_8_TT_1p0V_25C.lib"
# set_db link_library [list * freepdk45_sram_1rw1r_32x8192_8_TT_1p0V_25C.lib NangateOpenCellLibrary_typical_ecsm.lib]


# ---------------------------
# 2. 读取设计文件
# ---------------------------
read_hdl -sv {
    /home/sakamoto/E203_Accelerator/rtl/mem_shift_reg.sv
    /home/sakamoto/E203_Accelerator/rtl/addertree9_fp16.sv
    /home/sakamoto/E203_Accelerator/rtl/acc_top.sv
    /home/sakamoto/E203_Accelerator/rtl/conv_control.sv
    /home/sakamoto/E203_Accelerator/rtl/icb_slave.sv
    /home/sakamoto/E203_Accelerator/rtl/gelu.sv
    /home/sakamoto/E203_Accelerator/rtl/conv_kernal.sv
    /home/sakamoto/E203_Accelerator/rtl/linebuffer_3x3.sv
    /home/sakamoto/E203_Accelerator/rtl/floatAdd.v
    /home/sakamoto/E203_Accelerator/rtl/floatMult.v
    /home/sakamoto/E203_Accelerator/bn/AvgUnit.v
    /home/sakamoto/E203_Accelerator/bn/Bn_complete.v
    /home/sakamoto/E203_Accelerator/bn/equal.v
    /home/sakamoto/E203_Accelerator/bn/bn_multi.v
    /home/sakamoto/E203_Accelerator/bn/Bn.v
    /home/sakamoto/E203_Accelerator/bn/x_sub_u.v
    /home/sakamoto/E203_Accelerator/bn/Square_root.v
    }

elaborate $DESIGN_NAME
check_design -unresolved

# ---------------------------
# 3. SRAM 特殊处理
# ---------------------------
# 防止优化 SRAM 实例（关键！）
# set_dont_touch [get_cells -hierarchical *sram*] 
# set_size_only [get_cells -hierarchical *sram*]
# # 可选：添加调试信息查看处理的SRAM实例
# puts "INFO: Following SRAM instances will be preserved as blackbox:"
# foreach sram_cell [get_cells -hierarchical *sram*] {
#     puts "  $sram_cell"
# }

# ---------------------------
# 4. 约束设置
# ---------------------------
# 时钟约束（假设时钟端口名为 clk）
create_clock -name clk -period 10 [get_ports clk]

# 输入/输出延迟
set_input_delay -max 2 -clock clk [all_inputs]
set_output_delay -max 1 -clock clk [all_outputs]

# 负载和驱动强度
set_load 0.1 [all_outputs]
set_driving_cell -lib_cell INV_X1 [all_inputs]

# ---------------------------
# 5. 综合优化
# ---------------------------
set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high

syn_generic
syn_map
syn_opt

# ---------------------------
# 6. 生成报告和输出文件
# ---------------------------
file mkdir ${OUTPUT_PATH}/reports

report_timing -max_paths 10 > ${OUTPUT_PATH}/reports/${DESIGN_NAME}_timing.rpt
report_area > ${OUTPUT_PATH}/reports/${DESIGN_NAME}_area.rpt
report_power > ${OUTPUT_PATH}/reports/${DESIGN_NAME}_power.rpt

# 输出网表（包含 SRAM 黑盒）
write_hdl > ${OUTPUT_PATH}/${DESIGN_NAME}_netlist.v

# 输出约束文件
write_sdc > ${OUTPUT_PATH}/${DESIGN_NAME}_output.sdc

# 生成 SDF（用于时序仿真）
write_sdf -design $DESIGN_NAME \
    -version "3.0" \
    -timescale ps \
    > ${OUTPUT_PATH}/${DESIGN_NAME}_typical.sdf

# 为 Innovus 准备数据
# write_design -innovus -basename ${OUTPUT_PATH}/${DESIGN_NAME}_innovus

# ---------------------------
# 完成提示
# ---------------------------
puts "\nSynthesis with OpenRAM SRAM completed!"
puts "SRAM instance(s) preserved as blackbox."
puts "Results are in: $OUTPUT_PATH\n"

exit
