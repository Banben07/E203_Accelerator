`define INPUT_ADDR 12'h000  // 32*96/8=384
`define WQ0_ADDR 12'h180  // 96*48/8=576，384+576=960
`define WQ1_ADDR 12'h3C0  // 96*48/8=576，960+576=1536
`define WK0_ADDR 12'h600  // 96*48/8=576，1536+576=2112
`define WK1_ADDR 12'h840  // 96*48/8=576，2112+576=2688
`define WV0_ADDR 12'hA80  // 96*48/8=576，2688+576=3264
`define WV1_ADDR 12'hCC0  // 96*48/8=576，3264+576=3840(0xF00)
`define CONTROL_ADDR 12'hF00
`define STATUS_ADDR 12'hF04

`define PATTERN "/home/sakamoto/E203_Accelerator/utils/conv_golden_pattern.txt"
`define PATTERN_NUM 30

module icb_slave_tb ();
  // clk & rst_n
  logic               clk;
  logic               rst_n;

  // icb bus
  logic               icb_cmd_valid;
  logic               icb_cmd_ready;
  logic               icb_cmd_read;
  logic [ 31:0]       icb_cmd_addr;
  logic [ 31:0]       icb_cmd_wdata;
  logic [  3:0]       icb_cmd_wmask;

  logic               icb_rsp_valid;
  logic               icb_rsp_ready;
  logic [ 31:0]       icb_rsp_rdata;
  logic               icb_rsp_err;

  // reg output
  logic [ 31:0]       ofmap_out;
  logic               done;
  logic               dout_valid;
  reg   [ 15:0][15:0] ifmap_1;
  reg   [ 15:0][15:0] ifmap_2;
  reg   [  8:0][15:0] weight_1;
  reg   [  8:0][15:0] weight_2;
  reg   [  3:0][15:0] of_map_expected;
  reg   [863:0]       pattern         [0:`PATTERN_NUM-1  ];

  reg   [ 31:0]       pattern_pos     [            8192];
  reg   [ 31:0]       pattern_neg     [            8192];

  reg   [  7:0]       error_cnt;
  integer i, j;
  reg  [119:0][15:0] ofmap_out_1;

  reg  [ 15:0]       pattern_data_pos;
  reg  [ 15:0]       pattern_data_neg;
  reg  [ 15:0]       pattern_addr;

  real               tolerance = 0.005;
  real decimal_input1, decimal_input2, decimal_expected, decimal_result;

  // 将时钟周期从40ns增加到50ns，进一步降低频率
  always #25 clk = ~clk;  // 从 #20 改为 #25，使时钟周期变为 50ns

  // 添加时序违例监控
  reg [31:0] hold_violations;
  initial begin
    hold_violations = 0;
  end

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
    $readmemb(`PATTERN, pattern);
    $readmemh("/home/sakamoto/E203_Accelerator/utils/tanh_lut_positive.txt", pattern_pos);
    $readmemh("/home/sakamoto/E203_Accelerator/utils/tanh_lut_negative.txt", pattern_neg);
  end

  initial begin
`ifdef A
    $vcdpluson;
    $vcdplusmemon();
    $fsdbDumpfile("test.fsdb");
    $fsdbDumpvars();

`endif

    clk       = 0;
    rst_n     = 0;
    error_cnt = 0;
    #20;
    rst_n        = 1;
    icb_cmd_read = 0;
    #10;


    @(posedge (clk));
    icb_cmd_valid = 1;
    icb_rsp_ready = 1;
    icb_cmd_read  = 0;
    icb_cmd_addr  = 32'h1004_2004;
    icb_cmd_wdata = 32'h0000_0002;
    @(posedge (clk));

    for (int i = 0; i < 2141; i++) begin
      pattern_data_pos = pattern_pos[i][15:0];
      pattern_data_neg = pattern_neg[i][15:0];
      pattern_addr = pattern_pos[i][31:16];
      @(posedge (clk));
      icb_cmd_valid = 1;
      icb_rsp_ready = 1;
      icb_cmd_read  = 0;
      icb_cmd_addr  = 32'h1004_2008 + pattern_addr[14:3];
      icb_cmd_wdata = {pattern_data_neg, pattern_data_pos};
      @(posedge (clk));
    end

    // @(posedge (clk));
    // icb_cmd_valid = 1;
    // icb_rsp_ready = 1;
    // icb_cmd_read  = 0;
    // icb_cmd_addr  = 32'h1004_2004;
    // icb_cmd_wdata = 32'h0000_0004;
    // @(posedge (clk));

    // for (int i = 0; i < 2141; i++) begin
    //   pattern_data = pattern_neg[i][15:0];
    //   pattern_addr = pattern_neg[i][31:16];
    //   @(posedge (clk));
    //   icb_cmd_valid = 1;
    //   icb_rsp_ready = 1;
    //   icb_cmd_read  = 0;
    //   icb_cmd_addr  = 32'h1004_2008 + pattern_addr[14:3];
    //   icb_cmd_wdata = pattern_data;
    //   @(posedge (clk));
    // end

    @(posedge (clk));
    icb_cmd_valid = 1;
    icb_rsp_ready = 1;
    icb_cmd_read  = 0;
    icb_cmd_addr  = 32'h1004_2004;
    icb_cmd_wdata = 32'h0000_0001;
    @(posedge (clk));


    for (i = 0; i < `PATTERN_NUM; i = i + 1) begin
      begin
        {ifmap_1, ifmap_2, weight_1, weight_2, of_map_expected} = pattern[i];

        for (int l = 0; l < 4; l++) begin
          ofmap_out_1[i*4+l] = of_map_expected[l];
        end

        for (int k = 0; k < 16; k++) begin
          @(posedge (clk));
          icb_cmd_valid = 1;
          icb_rsp_ready = 1;
          icb_cmd_read  = 0;
          icb_cmd_addr  = 32'h1004_2008 + k + i * 16 + 1;
          icb_cmd_wdata = {ifmap_2[k], ifmap_1[k]};
          @(posedge (clk));
        end

      end
    end

    for (int m = 0; m < 9; m++) begin
      @(posedge (clk));
      icb_cmd_valid = 1;
      icb_rsp_ready = 1;
      icb_cmd_read  = 0;
      icb_cmd_addr  = 32'h1004_2008 + m + 4078 + 1;
      icb_cmd_wdata = {weight_2[m], weight_1[m]};
      @(posedge (clk));
    end

    @(posedge (clk));
    icb_cmd_valid = 1;
    icb_rsp_ready = 1;
    icb_cmd_read  = 0;
    icb_cmd_addr  = 32'h1004_2004;
    icb_cmd_wdata = 32'h0000_0000;
    @(posedge (clk));


    @(posedge (clk));
    icb_cmd_valid = 1;
    icb_rsp_ready = 1;
    icb_cmd_read  = 0;
    icb_cmd_addr  = 32'h1004_2000;
    icb_cmd_wdata = 32'h0000_0001;
    @(posedge (clk));
    @(posedge (clk));
    icb_cmd_valid = 1;
    icb_cmd_read  = 0;
    icb_cmd_addr  = 32'h1004_2000;
    icb_cmd_wdata = 32'h0000_0000;
    @(posedge (clk));


    for (j = 0; j < 120; j++) begin
      @(posedge clk);
      #1;
      wait (dout_valid);
      $display("Test for ofmap[%0d]", j);

      fp16_to_decimal(ofmap_out_1[j], decimal_expected);
      fp16_to_decimal(ofmap_out[15:0], decimal_result);
      $display("expected[%0d]: %f, actual[%0d]: %f", j, decimal_expected, j, decimal_result);
      if ((decimal_expected > decimal_result ? (decimal_expected - decimal_result) / decimal_expected : (decimal_result - decimal_expected) / decimal_expected) <= tolerance) begin
        $display("Check PASSED");
        $display("--------------------");
      end else begin
        error_cnt = error_cnt + 1;
        $display("Check FAILED");
        $display("--------------------");
      end
    end

    $display("Total error count: %d", error_cnt);

    wait (done);
    @(posedge (clk));
    #10000;
    $display("Simulation done");
    $finish;

  end

  acc_top acc_top (
      .clk          (clk),
      .rst_n        (rst_n),
      .icb_cmd_valid(icb_cmd_valid),
      .icb_cmd_ready(icb_cmd_ready),
      .icb_cmd_read (icb_cmd_read),
      .icb_cmd_addr (icb_cmd_addr),
      .icb_cmd_wdata(icb_cmd_wdata),
      .icb_cmd_wmask(icb_cmd_wmask),
      .icb_rsp_valid(icb_rsp_valid),
      .icb_rsp_ready(icb_rsp_ready),
      .icb_rsp_rdata(icb_rsp_rdata),
      .icb_rsp_err  (icb_rsp_err),

      .ofmap_out (ofmap_out),
      .done      (done),
      .dout_valid(dout_valid)
  );


endmodule
