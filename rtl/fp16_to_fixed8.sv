module fp16_to_fixed8 (
    input logic [15:0] fp16,      // 输入的 FP16 浮点数
    output logic [15:0] fixed8    // 输出的定点数，保留 8 位小数
);
    // 提取 FP16 浮点数的符号、指数和尾数部分
    logic sign;
    logic [4:0] exponent;
    logic [9:0] mantissa;
    logic [15:0] result;

    assign sign = fp16[15];
    assign exponent = fp16[14:10];
    assign mantissa = fp16[9:0];

    // 将 FP16 转换为定点数的过程
    always_comb begin
        logic [25:0] fixed_point;  // 暂存中间结果
        logic [15:0] int_part;     // 整数部分
        logic [9:0] frac_part;     // 小数部分
        int exp_value;

        if (exponent == 5'b00000) begin
            // 处理非规格化数和零
            result = 16'h0000;
        end else if (exponent == 5'b11111) begin
            // 处理 NaN 和无穷大
            result = 16'hFFFF; // 用全1表示异常情况
        end else begin
            // 规格化数的转换
            exp_value = $signed(exponent) - 15;

            // 计算整数部分和小数部分
            if (exp_value >= 0) begin
                // 指数大于等于0，整数部分包含尾数和部分小数位
                int_part = ({1'b1, mantissa} << exp_value);
                frac_part = 10'h0;
            end else begin
                // 指数小于0，只有小数部分
                int_part = 16'h0000;
                frac_part = (1'b1 << 10) | mantissa;
                frac_part = frac_part >> (-exp_value);
            end

            // 合成结果，注意小数部分需要右移 2 位以保留 8 位小数
            fixed_point = {int_part, frac_part};
            fixed_point = fixed_point >> 2;

            // 考虑符号位
            result = sign ? -fixed_point[15:0] : fixed_point[15:0];
        end

        fixed8 = result;
    end
endmodule