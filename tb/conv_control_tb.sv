`define PATTERN "./utils/conv_golden_pattern.txt"
`define PATTERN_NUM 30

module conv_control_tb ();


  reg  [ 15:0][15:0] ifmap_4x4;
  reg  [  8:0][15:0] weight_3x3;
  reg  [  3:0][15:0] of_map_expected;
  reg  [463:0]       pattern         [0:`PATTERN_NUM-1];
  reg  [  7:0]       error_cnt;
  reg                clk;
  reg                start;
  reg                rst_n;
  wire               done;
  wire               dout_valid;

  reg  [  3:0][15:0] ofmap;
  integer i, j;
  wire [ 15:0]       result;
  reg  [ 15:0]       conv_num;
  reg  [119:0][15:0] ofmap_out_1;
  reg  [119:0][15:0] ofmap_out_2;
  // int_fp_mul u1 (mode, input1, input2, result, error);

  conv_control u2 (
      clk,
      rst_n,
      start,
      conv_num,
      weight_3x3,
      result,
      done,
      dout_valid
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
    error_cnt   = 0;
    start       = 0;
    rst_n       = 0;
    ofmap_out_1 = 0;
    ofmap_out_2 = 0;
    #30;
    rst_n = 1;
    fork
      for (i = 0; i < `PATTERN_NUM; i = i + 1) begin

        begin
          @(posedge clk);
          start                                    = 1;
          {ifmap_4x4, weight_3x3, of_map_expected} = pattern[i];
          ofmap_out_1[i*4]                         = of_map_expected[0];
          ofmap_out_1[i*4+1]                       = of_map_expected[1];
          ofmap_out_1[i*4+2]                       = of_map_expected[2];
          ofmap_out_1[i*4+3]                       = of_map_expected[3];
          for (int k = 0; k < 16; k++) begin
            if (k == 1) begin
              start = 0;
            end
            conv_num = ifmap_4x4[k];
            @(posedge clk);
          end

          wait (done);
          start = 1;

        end

      end

      for (j = 0; j < 120; j++) begin
        @(posedge clk);
        #1;
        wait (dout_valid);
        ofmap_out_2[j] = result;
        $display("Test for ifmap[%0d]", j);

        fp16_to_decimal(ofmap_out_1[j], decimal_expected);
        fp16_to_decimal(result, decimal_result);
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

    join

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
