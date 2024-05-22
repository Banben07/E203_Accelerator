module gelu (
    input        clk,
    input        rst_n,
    input        bn_valid,
    input [15:0] in_fp16,
    input [15:0] lut_result,

    output       [15:0] final_result,
    output logic [11:0] lut_addr,
    output logic        lut_sign
);

  logic [15:0] in_fp16_reg;
  logic [15:0] in_fp16_Square;
  logic [15:0] in_fp16_Square_reg;
  logic [15:0] in_fp16_Cube;
  logic [15:0] in_fp16_Cube_reg;
  logic [15:0] coeff_mul;
  logic [15:0] coeff_mul_add;
  logic [15:0] coeff_mul_add_reg;
  logic [15:0] tanh_input;
  logic [15:0] tanh_output;
  logic [15:0] tanh_output_reg;
  logic [15:0] gelu_part1;
  logic [15:0] gelu_part1_reg;
  logic [15:0] gelu_part2;

  //   logic [15:0] coeff = 16'h29B9;  // 0.044715 in FP16
  //   logic [15:0] sqrt_2_pi = 16'h3A62;  // sqrt(2/pi) in FP16

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_fp16_reg <= 16'h0;
    end else if (bn_valid) begin
      in_fp16_reg <= in_fp16;
    end else begin
      in_fp16_reg <= in_fp16_reg;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_fp16_Square_reg <= 16'h0;
      in_fp16_Cube_reg   <= 16'h0;
      coeff_mul_add_reg  <= 16'h0;
      gelu_part1_reg     <= 16'h0;
      tanh_output_reg   <= 16'h0;
    end else begin
      in_fp16_Square_reg <= in_fp16_Square;
      in_fp16_Cube_reg   <= in_fp16_Cube;
      coeff_mul_add_reg  <= coeff_mul_add;
      gelu_part1_reg     <= gelu_part1;
      tanh_output_reg   <= tanh_output;
    end
  end

  floatMult u_float_multi_1 (
      // ports
      .num1  (in_fp16_reg),
      .num2  (in_fp16_reg),
      .result(in_fp16_Square)
  );

  floatMult u_float_multi_x (
      // ports
      .num1  (in_fp16_reg),
      .num2  (16'h3800),
      .result(gelu_part1)
  );

  floatMult u_float_multi_2 (
      // ports
      .num1  (in_fp16_Square_reg),
      .num2  (in_fp16_Square_reg),
      .result(in_fp16_Cube)
  );

  floatMult u_float_multi_3 (
      // ports
      .num1  (in_fp16_Cube_reg),
      .num2  (16'h29B9),
      .result(coeff_mul)
  );

  floatAdd u_float_add_1 (
      // ports
      .num1  (coeff_mul),
      .num2  (in_fp16_reg),
      .result(coeff_mul_add)
  );

  floatMult u_float_multi_4 (
      // ports
      .num1  (coeff_mul_add_reg),
      .num2  (16'h3A62),
      .result(tanh_input)
  );

  always @(*) begin
    lut_addr = tanh_input[14:3];
    lut_sign = tanh_input[15];
    if (tanh_input[14:0] < 15'h2740) begin
      tanh_output = tanh_input;
    end else begin
      tanh_output = lut_result;
    end
  end

  floatAdd u_float_add_2 (
      // ports
      .num1  (tanh_output_reg),
      .num2  (16'b0011110000000000),
      .result(gelu_part2)
  );

  floatMult u_float_multi_o (
      // ports
      .num1  (gelu_part1_reg),
      .num2  (gelu_part2),
      .result(final_result)
  );


endmodule
