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
    output     [31:0] ofmap_out,      // for test
    output            done,           // for test
    output            dout_valid      // for test
);

  logic [15:0] STAT_REG_CAL;

  logic WEIGHT_FINISH_REG;

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
  logic [16*4-1:0] bn_input;
  logic [16*4-1:0] bn_input_reg;
  logic [3:0][15:0] bn_output;
  logic            bn_start;

  logic bn_update, bn_state, bn_valid;

  logic [1:0] state;

  localparam IDLE = 0;
  localparam WEIGHT_CFG = 1;
  localparam START_CAL = 2;

  localparam WEIGHT_ADDR_BASE = 4080;

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
      .DONE_REG  (done),

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
      .wsbn (sram_wr_en),
      .waddr(sram_wr_addr),
      .wdata(sram_wr_data),
      .csbn (input_read_en),
      .raddr(input_read_addr),
      .rdata(input_read_data)
  );

  sram_8k_32b u_sram_output (  // 8k x 32b for output
      .clk  (clk),
      .wsbn (dout_valid),
      .waddr(ofmap_addr),
      .wdata(ofmap_out),

      .csbn (sram_rd_en),
      .raddr(sram_rd_addr),
      .rdata(sram_rd_data)
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
      case (state)
        IDLE: begin
          weight_addr       <= WEIGHT_ADDR_BASE - 1;
          weight_data       <= 0;
          weight_read_en    <= 0;
          WEIGHT_FINISH_REG <= 0;
          ifmap_addr        <= 0;
          ifmap_data        <= 0;
          ifmap_read_en     <= 0;
          conv_num_valid    <= 0;

          if (STAT_REG_CAL[0]) begin
            state <= WEIGHT_CFG;
          end else begin
            state <= IDLE;
          end
        end

        WEIGHT_CFG: begin
          if (weight_addr < WEIGHT_ADDR_BASE - 1 + 9 + 2) begin
            weight_data       <= {input_read_data, weight_data[8:1]};
            weight_addr       <= weight_addr + 1;
            weight_read_en    <= 1;
            state             <= WEIGHT_CFG;
            WEIGHT_FINISH_REG <= 0;
          end else begin
            weight_addr       <= WEIGHT_ADDR_BASE - 1;
            weight_data       <= weight_data;
            weight_read_en    <= 0;
            state             <= START_CAL;
            WEIGHT_FINISH_REG <= 1;
          end
        end

        START_CAL: begin
          if (ifmap_addr < 480 + 2) begin
            ifmap_data     <= input_read_data;
            ifmap_addr     <= ifmap_addr + 1;
            ifmap_read_en  <= 1;
            conv_num_valid <= (ifmap_addr < 2) ? 0 : 1;
            state          <= START_CAL;
          end else begin
            ifmap_addr     <= ifmap_addr;
            conv_num_valid <= 0;
            ifmap_data     <= 0;
            ifmap_read_en  <= 0;
            state          <= IDLE;
          end
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
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

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ofmap_addr   <= 0;
      bn_cnt       <= 0;
      bn_input_reg <= 0;
      bn_start     <= 0;
      bn_valid_cnt <= 0;
      bn_state     <= 0;
      bn_valid     <= 0;

      bn_update    <= 0;
      bn_input     <= 0;
    end else begin

      if (dout_valid) begin
        if (bn_cnt < 4) begin
          bn_input_reg <= {ofmap_out[15:0], bn_input_reg[16*4-1:16]};
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
          if (bn_valid_cnt < 12) begin
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

    end
  end

  bn_multi u_bn_multi (
      bn_input,
      bn_output,
      clk,
      bn_start
  );

endmodule
