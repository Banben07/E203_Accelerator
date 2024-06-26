module acc_top (
    // clk & rst_n
    input clk,
    input rst_n,

    input             icb_cmd_valid,
    output reg        icb_cmd_ready,
    input             icb_cmd_read,
    input      [31:0] icb_cmd_addr,
    input      [31:0] icb_cmd_wdata,
    input      [ 3:0] icb_cmd_wmask,

    output reg        icb_rsp_valid,
    input             icb_rsp_ready,
    output reg [31:0] icb_rsp_rdata,
    output            icb_rsp_err,
    output     [15:0] ofmap_out,      // for test
    output            done,           // for test
    output            dout_valid      // for test
);

  logic [31:0] STAT_REG_CAL;

  logic [31:0] RAM_SEL;

  logic        WEIGHT_FINISH_REG;

  logic [12:0] sram_wr_addr, sram_rd_addr;
  logic [31:0] sram_wr_data, sram_rd_data;

  logic [ 8:0][31:0] weight_data;
  logic [ 8:0][15:0] kernel_num_1;
  logic [ 8:0][15:0] kernel_num_2;
  logic [12:0]       weight_addr;
  logic [12:0]       ofmap_addr;
  logic [12:0]       ifmap_addr;
  logic [12:0]       input_read_addr;
  logic [31:0]       input_read_data;
  logic [31:0]       ifmap_data;
  // logic              done;
  logic              input_read_en;
  logic              weight_read_en;
  logic              ifmap_read_en;
  logic              conv_num_valid;

  logic [12:0] bn_cnt, bn_valid_cnt;
  logic [16*4-1:0]       bn_input;
  logic [16*4-1:0]       bn_input_reg;
  logic [     3:0][15:0] bn_output;
  logic                  bn_start;
  logic [    15:0]       bn_input_data;

  logic [    15:0]       ofmap_in;
  logic                  ofmap_in_valid;
  logic [    12:0]       ofmap_in_cnt;

  logic [     3:0][15:0] lut_result;

  logic [     3:0][11:0] lut_addr;
  logic [     3:0]       lut_sign;
  logic [     3:0][15:0] final_result;

  logic bn_update, bn_state, bn_valid;

  logic [ 1:0]       state;
  logic              gelu_state;
  logic [ 2:0]       gelu_cnt;
  logic              gelu_valid;

  logic [ 2:0]       lut_state_next;
  logic [ 2:0]       lut_state;

  logic              lut_sign_cur;
  logic [11:0]       lut_addr_cur;
  logic [31:0]       lut_result_cur;
  logic              lut_addr_valid;

  logic              ofmap_in_state;

  logic [ 1:0]       next_state;
  logic [12:0]       next_weight_addr;
  logic [ 8:0][31:0] next_weight_data;
  logic              next_weight_read_en;
  logic              next_WEIGHT_FINISH_REG;
  logic [12:0]       next_ifmap_addr;
  logic [31:0]       next_ifmap_data;
  logic              next_ifmap_read_en;
  logic              next_conv_num_valid;


  localparam IDLE = 0;
  localparam WEIGHT_CFG = 1;
  localparam START_CAL = 2;

  localparam WEIGHT_ADDR_BASE = 4079;

  icb_slave u_icb_slave (
      .clk  (clk),
      .rst_n(rst_n),

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

      .STAT_REG_CAL(STAT_REG_CAL),
      .RAM_SEL     (RAM_SEL),
      .DONE_REG    (done),

      .sram_wr_data(sram_wr_data),
      .sram_wr_addr(sram_wr_addr),
      .sram_wr_en  (sram_wr_en),
      .sram_rd_data(sram_rd_data),
      .sram_rd_addr(sram_rd_addr),
      .sram_rd_en  (sram_rd_en)

  );

  assign input_read_addr = WEIGHT_FINISH_REG ? ifmap_addr : weight_addr;
  assign input_read_en   = ifmap_read_en || weight_read_en;

  sram_8k_32b u_sram_input (  // 8k x 32b for input
      .clk  (clk),
      .wsbn (sram_wr_en & RAM_SEL[0]),
      .waddr(sram_wr_addr),
      .wdata(sram_wr_data),

      .csbn (input_read_en),
      .raddr(input_read_addr),
      .rdata(input_read_data)
  );

  sram_8k_32b u_sram_output (  // 8k x 32b for output
      .clk  (clk),
      .wsbn (ofmap_in_valid),
      .waddr(ofmap_addr),
      .wdata(ofmap_in),

      .csbn (sram_rd_en),
      .raddr(sram_rd_addr),
      .rdata(sram_rd_data)
  );

  sram_8k_32b u_sram_8k_32b_lut (
      .clk  (clk),
      .wsbn (sram_wr_en & RAM_SEL[1]),
      .waddr(sram_wr_addr),
      .wdata(sram_wr_data),

      .csbn (1),
      .raddr(lut_addr_cur),
      .rdata(lut_result_cur)
  );


  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state             <= IDLE;
      weight_addr       <= WEIGHT_ADDR_BASE - 1;
      weight_data       <= 0;
      weight_read_en    <= 0;
      WEIGHT_FINISH_REG <= 0;
      ifmap_addr        <= 0;
      ifmap_data        <= 0;
      ifmap_read_en     <= 0;
      conv_num_valid    <= 0;
    end else begin
      state             <= next_state;
      weight_addr       <= next_weight_addr;
      weight_data       <= next_weight_data;
      weight_read_en    <= next_weight_read_en;
      WEIGHT_FINISH_REG <= next_WEIGHT_FINISH_REG;
      ifmap_addr        <= next_ifmap_addr;
      ifmap_data        <= next_ifmap_data;
      ifmap_read_en     <= next_ifmap_read_en;
      conv_num_valid    <= next_conv_num_valid;
    end
  end

  always @(*) begin
    next_state             = state;
    next_weight_addr       = weight_addr;
    next_weight_data       = weight_data;
    next_weight_read_en    = weight_read_en;
    next_WEIGHT_FINISH_REG = WEIGHT_FINISH_REG;
    next_ifmap_addr        = ifmap_addr;
    next_ifmap_data        = ifmap_data;
    next_ifmap_read_en     = ifmap_read_en;
    next_conv_num_valid    = conv_num_valid;

    case (state)
      IDLE: begin
        next_weight_addr       = WEIGHT_ADDR_BASE - 1;
        next_weight_data       = 0;
        next_weight_read_en    = 0;
        next_WEIGHT_FINISH_REG = 0;
        next_ifmap_addr        = 0;
        next_ifmap_data        = 0;
        next_ifmap_read_en     = 0;
        next_conv_num_valid    = 0;

        if (STAT_REG_CAL[0]) begin
          next_state = WEIGHT_CFG;
        end else begin
          next_state = IDLE;
        end
      end

      WEIGHT_CFG: begin
        if (weight_addr < WEIGHT_ADDR_BASE - 1 + 9 + 2) begin
          next_weight_data       = {input_read_data, weight_data[8:1]};
          next_weight_addr       = weight_addr + 1;
          next_weight_read_en    = 1;
          next_state             = WEIGHT_CFG;
          next_WEIGHT_FINISH_REG = 0;
        end else begin
          next_weight_addr       = WEIGHT_ADDR_BASE - 1;
          next_weight_data       = weight_data;
          next_weight_read_en    = 0;
          next_state             = START_CAL;
          next_WEIGHT_FINISH_REG = 1;
        end
      end

      START_CAL: begin
        if (ifmap_addr < 480 + 2) begin
          next_ifmap_data     = input_read_data;
          next_ifmap_addr     = ifmap_addr + 1;
          next_ifmap_read_en  = 1;
          next_conv_num_valid = (ifmap_addr < 2) ? 0 : 1;
          next_state          = START_CAL;
        end else begin
          next_ifmap_addr     = ifmap_addr;
          next_conv_num_valid = 0;
          next_ifmap_data     = 0;
          next_ifmap_read_en  = 0;
          next_state          = IDLE;
        end
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end

  generate
    genvar i;
    for (i = 0; i < 9; i = i + 1) begin
      assign kernel_num_1[i] = weight_data[i][15:0];
      assign kernel_num_2[i] = weight_data[i][31:16];
    end
  endgenerate

  conv_control u_conv_control (
      .clk           (clk),
      .rst_n         (rst_n),
      .start         (),
      .conv_num      (ifmap_data),
      .conv_num_valid(conv_num_valid),
      .kernel_num_1  (kernel_num_1),
      .kernel_num_2  (kernel_num_2),
      .ofmap_out     (ofmap_out),
      .dout_valid    (dout_valid),
      .done          (done)
  );

  floatMult u_div_100 (
      .num1  (ofmap_out),
      .num2  (16'h1419),
      .result(bn_input_data)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bn_cnt         <= 0;
      bn_input_reg   <= 0;
      bn_start       <= 0;
      bn_valid_cnt   <= 0;
      bn_state       <= 0;
      bn_valid       <= 0;

      bn_update      <= 0;
      bn_input       <= 0;

      gelu_state     <= 0;
      gelu_cnt       <= 0;
      gelu_valid     <= 0;

      lut_addr_valid <= 0;
    end else begin

      if (dout_valid) begin
        if (bn_cnt < 4) begin
          bn_input_reg <= {bn_input_data, bn_input_reg[16*4-1:16]};
          if (bn_cnt == 3) begin
            bn_cnt    <= 0;
            bn_update <= 1;
          end else begin
            bn_cnt    <= bn_cnt + 1;
            bn_update <= 0;
          end
        end
      end else begin
        bn_update <= 0;
      end

      case (bn_state)
        0: begin
          bn_valid_cnt <= 0;
          bn_valid     <= 0;
          if (bn_update) begin
            bn_state <= 1;
            bn_start <= 1;
            bn_input <= bn_input_reg;
          end else begin
            bn_state <= 0;
          end
        end
        1: begin
          bn_start <= 0;
          if (bn_valid_cnt < 13) begin
            bn_valid_cnt <= bn_valid_cnt + 1;
            bn_state     <= 1;
            bn_valid     <= 0;
          end else begin
            bn_valid_cnt <= 0;
            bn_state     <= 0;
            bn_valid     <= 1;
          end
        end
      endcase

      case (gelu_state)
        0: begin
          gelu_valid     <= 0;
          lut_addr_valid <= 0;
          if (bn_valid) begin
            gelu_state <= 1;
          end
        end
        1: begin
          if (gelu_cnt < 4) begin
            gelu_cnt       <= gelu_cnt + 1;
            gelu_state     <= 1;
            gelu_valid     <= 0;
            lut_addr_valid <= (gelu_cnt == 1);
          end else begin
            gelu_cnt       <= 0;
            gelu_state     <= 0;
            gelu_valid     <= 1;
            lut_addr_valid <= 0;
          end
        end

      endcase
    end
  end

  bn_multi u_bn_multi (
      bn_input,
      bn_output,
      clk,
      bn_start
  );

  generate
    genvar j;
    for (j = 0; j < 4; j = j + 1) begin
      gelu u_gelu (
          .clk       (clk),
          .rst_n     (rst_n),
          .bn_valid  (bn_valid),
          .in_fp16   (bn_output[j]),
          .lut_result(lut_result[j]),

          .final_result(final_result[j]),
          .lut_addr    (lut_addr[j]),
          .lut_sign    (lut_sign[j])
      );

      // assign lut_result[j] = lut_sign[j] ? lut_result_neg[j] : lut_result_pos[j];
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lut_state <= 0;
    end else begin
      lut_state <= lut_state_next;
    end
  end

  always @(*) begin
    lut_state_next = lut_state;
    case (lut_state)
      0: begin
        lut_result[3] = lut_sign[3] ? lut_result_cur[31:16] : lut_result_cur[15:0];
        if (lut_addr_valid) begin
          lut_state_next = 1;
        end
      end
      1: begin
        lut_sign_cur   = lut_sign[0];
        lut_addr_cur   = lut_addr[0];
        lut_state_next = 2;
      end
      2: begin
        lut_sign_cur   = lut_sign[1];
        lut_addr_cur   = lut_addr[1];
        lut_result[0]  = lut_sign[0] ? lut_result_cur[31:16] : lut_result_cur[15:0];
        lut_state_next = 3;
      end
      3: begin
        lut_sign_cur   = lut_sign[2];
        lut_addr_cur   = lut_addr[2];
        lut_result[1]  = lut_sign[1] ? lut_result_cur[31:16] : lut_result_cur[15:0];
        lut_state_next = 4;
      end
      4: begin
        lut_sign_cur   = lut_sign[3];
        lut_addr_cur   = lut_addr[3];
        lut_result[2]  = lut_sign[2] ? lut_result_cur[31:16] : lut_result_cur[15:0];
        lut_state_next = 0;
      end
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ofmap_in_valid <= 0;
      ofmap_in       <= 0;
      ofmap_in_cnt   <= 0;
      ofmap_addr     <= 0;
      ofmap_in_state <= 0;
    end else begin
      case (ofmap_in_state)
        0: begin
          if (gelu_valid) begin
            ofmap_in_state <= 1;
          end
        end
        1: begin
          if (ofmap_in_cnt < 4) begin
            ofmap_in_cnt   <= ofmap_in_cnt + 1;
            ofmap_in       <= final_result[ofmap_in_cnt];
            ofmap_in_valid <= 1;
            ofmap_addr     <= ofmap_addr + 1;
            ofmap_in_state <= 1;
          end else begin
            ofmap_in_cnt   <= 0;
            ofmap_in       <= 0;
            ofmap_in_valid <= 0;
            ofmap_in_state <= 0;
          end
        end

      endcase
    end
  end


endmodule
