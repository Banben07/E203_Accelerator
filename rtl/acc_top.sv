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
    output     [31:0] ofmap_out, // for test
    output            done,      // for test
    output            dout_valid // for test
  );

  logic [15:0] STAT_REG_CAL, STAT_REG_RD;
  logic [31:0] CONFIG_REG, CALCBASE_REG, RWBASE_REG;

  logic WEIGHT_FINISH_REG;

  logic [12:0] sram_wr_addr, sram_rd_addr;
  logic [31:0] sram_wr_data, sram_rd_data;

  logic [ 8:0][31:0] weight_data;
  logic [ 8:0][15:0] kernel_num_1;
  logic [ 8:0][15:0] kernel_num_2;
  logic [12:0]       weight_addr;
  logic [12:0]       ifmap_cnt;
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

  logic [1:0] state;

  localparam IDLE = 0;
  localparam WEIGHT_CFG = 1;
  localparam START_CAL = 2;

  localparam WEIGHT_ADDR_BASE = 7680;

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
              .CONFIG_REG  (CONFIG_REG),
              .CALCBASE_REG(CALCBASE_REG),
              .RWBASE_REG  (RWBASE_REG),
              .STAT_REG_RD (STAT_REG_RD),

              .sram_wr_data(sram_wr_data),
              .sram_wr_addr(sram_wr_addr),
              .sram_wr_en  (sram_wr_en),
              .sram_rd_data(sram_rd_data),
              .sram_rd_addr(sram_rd_addr),
              .sram_rd_en  (sram_rd_en)

            );

  assign input_read_addr = WEIGHT_FINISH_REG ? ifmap_addr : weight_addr;
  assign input_read_en   = ifmap_read_en || weight_read_en;

  sram_8k_32b_input u_sram_input (  // 8k x 32b for input
                      .clk  (clk),
                      .wsbn (sram_wr_en),
                      .waddr(sram_wr_addr),
                      .wdata(sram_wr_data),
                      .csbn (input_read_en),
                      .raddr(input_read_addr),
                      .rdata(input_read_data)
                    );

  sram_8k_32b_output u_sram_output (  // 8k x 32b for input
                       .clk  (clk),
                       .wsbn (dout_valid),
                       .waddr(ofmap_addr),
                       .wdata(ofmap_out),
                       
                       .csbn (sram_rd_en),
                       .raddr(sram_rd_addr),
                       .rdata(sram_rd_data)
                     );

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state <= IDLE;
      weight_addr       <= WEIGHT_ADDR_BASE-1;
      weight_data       <= 0;
      weight_read_en    <= 0;
      WEIGHT_FINISH_REG <= 0;
      ifmap_addr     <= 0;
      ifmap_data     <= 0;
      ifmap_read_en  <= 0;
      conv_num_valid <= 0;
    end
    else
    begin
      case (state)
        IDLE:
        begin
          weight_addr       <= WEIGHT_ADDR_BASE-1;
          weight_data       <= 0;
          weight_read_en    <= 0;
          WEIGHT_FINISH_REG <= 0;
          ifmap_addr     <= 0;
          ifmap_data     <= 0;
          ifmap_read_en  <= 0;
          conv_num_valid <= 0;

          if (STAT_REG_CAL[0])
          begin
            state <= WEIGHT_CFG;
          end
          else
          begin
            state <= IDLE;
          end
        end

        WEIGHT_CFG:
        begin
          if (weight_addr < WEIGHT_ADDR_BASE-1+9+2)
          begin
            weight_data       <= {input_read_data, weight_data[8:1]};
            weight_addr       <= weight_addr + 1;
            weight_read_en    <= 1;
            state <= WEIGHT_CFG;
            WEIGHT_FINISH_REG <= 0;
          end
          else
          begin
            weight_addr       <= WEIGHT_ADDR_BASE-1;
            weight_data       <= weight_data;
            weight_read_en    <= 0;
            state <= START_CAL;
            WEIGHT_FINISH_REG <= 1;
          end
        end

        START_CAL:
        begin
          if (ifmap_addr < 480+2)
          begin
            ifmap_data     <= input_read_data;
            ifmap_addr     <= ifmap_addr + 1;
            ifmap_read_en  <= 1;
            conv_num_valid <= (ifmap_addr < 2)? 0: 1;
            state <= START_CAL;
          end
          else
          begin
            ifmap_addr     <= ifmap_addr;
            conv_num_valid <= 0;
            ifmap_data     <= 0;
            ifmap_read_en  <= 0;
            state <= IDLE;
          end
        end

        default:
        begin
          state <= IDLE;
        end
      endcase
    end
  end




  generate
    genvar i;
    for (i = 0; i < 9; i = i + 1)
    begin
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
        ofmap_addr <= 0;
      end
      else begin
        if (dout_valid) begin
          ofmap_addr <= ofmap_addr + 1;
        end
        else begin
          ofmap_addr <= ofmap_addr;
        end
      end
    end


endmodule
