module tb_fp16_to_fixed8;

    // 测试平台中的信号
    reg [15:0] fp16;
    wire [15:0] fixed8;

    // 实例化待测试模块
    fp16_to_fixed8 uut (
        .fp16(fp16),
        .fixed8(fixed8)
    );

    // 任务：打印当前状态
    task print_state;
        begin
            $display("FP16: %h => Fixed8: %h", fp16, fixed8);
        end
    endtask

    // 初始块用于仿真
    initial begin
        // 仿真开始
        $display("Start of Simulation");

        // 测试1：零
        fp16 = 16'h0000; #10; print_state();

        // 测试2：正数
        fp16 = 16'h3C00; #10; print_state(); // 1.0 in FP16

        // 测试3：负数
        fp16 = 16'hBC00; #10; print_state(); // -1.0 in FP16

        // 测试4：较大正数
        fp16 = 16'h4000; #10; print_state(); // 2.0 in FP16

        // 测试5：较小正数
        fp16 = 16'h3400; #10; print_state(); // 0.25 in FP16

        // 测试6：非规格化数
        fp16 = 16'h03FF; #10; print_state();

        // 测试7：无穷大
        fp16 = 16'h7C00; #10; print_state();

        // 测试8：NaN
        fp16 = 16'h7E00; #10; print_state();

        // 仿真结束
        $display("End of Simulation");
        $finish;
    end
endmodule