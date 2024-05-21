module conv_kernal (
    input             clk,
    input [8:0][15:0] ifmap_1,
    input [8:0][15:0] ifmap_2,
    input [8:0][15:0] weight_3x3_ch1,
    input [8:0][15:0] weight_3x3_ch2,

    output [15:0] ofmap
);

  wire [8:0][15:0] ch1_out, ch2_out;
  reg [8:0][15:0] ch1_out_reg, ch2_out_reg;

  wire [15:0] ofmap_ch1, ofmap_ch2;

  generate
    for (genvar i = 0; i < 9; i++) begin
      floatMult u_float_multi_1 (
          //ports
          .num1  (weight_3x3_ch1[i]),
          .num2  (ifmap_1[i]),
          .result(ch1_out[i])
      );
      floatMult u_float_multi_2 (
          //ports
          .num1  (weight_3x3_ch2[i]),
          .num2  (ifmap_2[i]),
          .result(ch2_out[i])
      );
    end
  endgenerate

  always @(posedge clk) begin
    ch1_out_reg <= ch1_out;
    ch2_out_reg <= ch2_out;
  end

  addertree9_fp16 u_addertree9_fp16_1 (
      //ports
      .clk (clk),
      .a   (ch1_out_reg),
      .dout(ofmap_ch1)
  );

  addertree9_fp16 u_addertree9_fp16_2 (
      //ports
      .clk (clk),
      .a   (ch2_out_reg),
      .dout(ofmap_ch2)
  );

  floatAdd u_float_adder_stage2_2 (
      //ports
      .num1  (ofmap_ch1),
      .num2  (ofmap_ch2),
      .result(ofmap)
  );


endmodule  //conv_kernal_1x2
