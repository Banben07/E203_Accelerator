`define PATTERN "./utils/conv_golden_pattern.txt"
`define PATTERN_NUM 30

module conv_tb ();


  reg [15:0][15:0] ifmap_4x4;
  reg [8:0][15:0] window, weight_3x3;
  reg     [  3:0][15:0] of_map_expected;
  reg     [463:0]       pattern         [0:`PATTERN_NUM-1];
  reg     [  7:0]       error_cnt;
  reg                   clk;
  wire                  error;

  reg     [  3:0][15:0] ofmap;
  integer               i;
  wire    [ 15:0]       result;
  // int_fp_mul u1 (mode, input1, input2, result, error);

  conv_kernal u2 (
      clk,
      window,
      weight_3x3,
      result
  );

  real decimal_input1, decimal_input2, decimal_expected, decimal_result;
  real tolerance = 0.004;  // Allowable tolerance for comparison

  // Task to convert 16-bit FP to decimal
  task automatic fp16_to_decimal(input [15:0] fp16, output real decimal);
    automatic integer exponent_bias = 15;  // Declared as automatic
    automatic integer exponent, i;
    automatic real mantissa;  // Declared as automatic to avoid unintended static behavior
    begin
      exponent = (fp16[14:10] - exponent_bias);
      mantissa = ((fp16[14:10] == 0) ? 0.0 : 1.0);  // Check for subnormal numbers

      // Compute mantissa from the fractional part
      for (i = 0; i < 10; i = i + 1) begin
        mantissa = mantissa + ((fp16[9-i] & 1'b1) * (2.0 ** -(i + 1)));
      end

      decimal = ((-1.0) ** fp16[15]) * mantissa * (2.0 ** exponent);
    end
  endtask

  initial begin
    clk = 0;
    #10;
    forever begin
      #10 clk = ~clk;
    end
  end

  initial begin
    error_cnt = 0;
    #30;
    for (i = 0; i < `PATTERN_NUM; i = i + 1) begin
     
      ofmap                                    = 0;

      fork

        begin

          @(posedge clk);
          {ifmap_4x4, weight_3x3, of_map_expected} = pattern[i];
          window[0] = ifmap_4x4[0];
          window[1] = ifmap_4x4[1];
          window[2] = ifmap_4x4[2];
          window[3] = ifmap_4x4[4];
          window[4] = ifmap_4x4[5];
          window[5] = ifmap_4x4[6];
          window[6] = ifmap_4x4[8];
          window[7] = ifmap_4x4[9];
          window[8] = ifmap_4x4[10];
          @(posedge clk);
          window[0] = ifmap_4x4[1];
          window[1] = ifmap_4x4[2];
          window[2] = ifmap_4x4[3];
          window[3] = ifmap_4x4[5];
          window[4] = ifmap_4x4[6];
          window[5] = ifmap_4x4[7];
          window[6] = ifmap_4x4[9];
          window[7] = ifmap_4x4[10];
          window[8] = ifmap_4x4[11];
          @(posedge clk);
          window[0] = ifmap_4x4[4];
          window[1] = ifmap_4x4[5];
          window[2] = ifmap_4x4[6];
          window[3] = ifmap_4x4[8];
          window[4] = ifmap_4x4[9];
          window[5] = ifmap_4x4[10];
          window[6] = ifmap_4x4[12];
          window[7] = ifmap_4x4[13];
          window[8] = ifmap_4x4[14];
          @(posedge clk);
          window[0] = ifmap_4x4[5];
          window[1] = ifmap_4x4[6];
          window[2] = ifmap_4x4[7];
          window[3] = ifmap_4x4[9];
          window[4] = ifmap_4x4[10];
          window[5] = ifmap_4x4[11];
          window[6] = ifmap_4x4[13];
          window[7] = ifmap_4x4[14];
          window[8] = ifmap_4x4[15];
        end

        begin
          @(posedge clk);
          @(posedge clk);
          @(posedge clk);
          #1;
          ofmap[0] = result;
          @(posedge clk);
          #1;
          ofmap[1] = result;
          @(posedge clk);
          #1;
          ofmap[2] = result;
          @(posedge clk);
          #1;
          ofmap[3] = result;

          $display("Test for ifmap[%0d]", i);
          for (int j = 0; j < 4; j++) begin
            fp16_to_decimal(of_map_expected[j], decimal_expected);
            fp16_to_decimal(ofmap[j], decimal_result);
            $display("expected[%0d]: %f, actual[%0d]: %f", j, decimal_expected, j, decimal_result);
            if ((decimal_expected > decimal_result ? decimal_expected - decimal_result : decimal_result - decimal_expected) <= tolerance) begin
              $display("Check PASSED");
              $display("--------------------");
            end else begin
              error_cnt = error_cnt + 1;
              $display("Check FAILED");
              $display("--------------------");
            end
          end

        end

      join
    end

    #10;
    $display("Total error count: %d", error_cnt);
    #10;
    $finish;
  end

  initial begin
    $vcdpluson;
    $vcdplusmemon();
  end

  initial begin
    $readmemb(`PATTERN, pattern);
  end

endmodule
