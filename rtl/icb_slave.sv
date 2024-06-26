`define STAT_REG_ADDR 4'h0


module icb_slave (
    // icb bus
    input             icb_cmd_valid,
    output            icb_cmd_ready,
    input             icb_cmd_read,
    input      [31:0] icb_cmd_addr,
    input      [31:0] icb_cmd_wdata,
    input      [ 3:0] icb_cmd_wmask,

    output reg        icb_rsp_valid,
    input             icb_rsp_ready,
    output reg [31:0] icb_rsp_rdata,
    output            icb_rsp_err,

    // clk & rst_n
    input clk,
    input rst_n,

    // reg IO
    output reg [31:0] STAT_REG_CAL,
    output reg [31:0] RAM_SEL,


    input       DONE_REG,

    output reg [31:0] sram_wr_data,
    output reg [12:0] sram_wr_addr,
    output reg        sram_wr_en,

    input      [31:0] sram_rd_data,
    output reg [12:0] sram_rd_addr,
    output reg        sram_rd_en

);

  assign icb_rsp_err = 1'b0;

  // cmd ready, icb_cmd_ready

  assign icb_cmd_ready = icb_cmd_read? icb_cmd_valid & (~icb_rsp_valid) : icb_cmd_valid;

  // always @(negedge rst_n or posedge clk) begin
  //   if (!rst_n) begin
  //     icb_cmd_ready <= 1'b0;
  //   end else begin
  //     if (icb_cmd_valid & icb_cmd_ready) begin
  //       icb_cmd_ready <= 1'b0;
  //     end else if (icb_cmd_valid) begin
  //       icb_cmd_ready <= 1'b1;
  //     end else begin
  //       icb_cmd_ready <= icb_cmd_ready;
  //     end
  //   end
  // end

  // ADDR and PARAM setting
  always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
      STAT_REG_CAL <= 32'h0;
      RAM_SEL <= 2;
      sram_wr_data <= 0;
      sram_wr_addr <= 0;
      sram_wr_en   <= 0;
    end else begin
      if (icb_cmd_valid & icb_cmd_ready & !icb_cmd_read & (icb_cmd_addr[31:12] == 20'h10042)) begin
        if (icb_cmd_addr[11:0] == 0) begin
            STAT_REG_CAL <= icb_cmd_wdata;
        end else if (icb_cmd_addr[11:0] == 4) begin
            RAM_SEL <= icb_cmd_wdata;
        end else begin
          sram_wr_data <= icb_cmd_wdata;
          sram_wr_addr <= icb_cmd_addr[11:0] - 8;
          sram_wr_en   <= 1;
        end
      end else begin
        sram_wr_data <= 0;
        sram_wr_addr <= 0;
        sram_wr_en   <= 0;
      end
    end
  end

  always @(*) begin
    if (icb_cmd_valid & icb_cmd_ready & icb_cmd_read) begin
      if (icb_cmd_addr >= 8) begin
        sram_rd_en   = 1'h1;
        sram_rd_addr = icb_cmd_addr[11:0]-8;
      end else begin
        sram_rd_en   = 1'h0;
        sram_rd_addr = 13'h0;
      end
    end else begin
      sram_rd_en   = 1'h0;
      sram_rd_addr = 13'h0;
    end
  end

  reg        icb_rsp_valid_r;
  reg [31:0] icb_cmd_addr_r;

  // response valid, icb_rsp_valid
  always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
      icb_rsp_valid   <= 1'h0;
      icb_rsp_valid_r <= 1'b0;
      icb_cmd_addr_r  <= 32'h0;
    end else begin
      if (icb_cmd_valid & icb_cmd_ready) begin
        if (!icb_cmd_read) begin
          icb_rsp_valid <= 1'h1;
        end else begin
          icb_rsp_valid_r <= 1'h1;
          icb_cmd_addr_r  <= icb_cmd_addr;
        end
      end else if (icb_rsp_valid & icb_rsp_ready) begin
        icb_rsp_valid <= 1'h0;
      end else if (icb_rsp_valid_r) begin
        icb_rsp_valid_r <= 1'h0;
        icb_cmd_addr_r  <= 32'h0;
        icb_rsp_valid   <= 1'h1;
      end else begin
        icb_rsp_valid <= icb_rsp_valid;
      end
    end
  end

  // read data, icb_rsp_rdata
  always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
      icb_rsp_rdata <= 32'h0;
    end else begin
      if (icb_rsp_valid_r) begin
        if (icb_cmd_addr[11:0] == 0) begin
          icb_rsp_rdata <= {31'b0, DONE_REG};
        end else begin
          icb_rsp_rdata <= sram_rd_data;
        end
      end else begin
        icb_rsp_rdata <= 32'h0;
      end
    end
  end



endmodule
