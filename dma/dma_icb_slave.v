`define SR_ADDR     8'h00
`define CTR_ADDR    8'h04
`define CR_ADDR     8'h08
`define SRC_ADDR    8'h0c
`define DST_ADDR    8'h10
`define LEN_ADDR    8'h14

module dma_icb_slave #(
    parameter FIFO_DEPTH = 1024
)(
    input clk,
    input rst_n,

    // config port, slave mod, R/W result returns after 1 cycle.
    input  logic        dma_cfg_icb_cmd_valid,
    input  logic        dma_cfg_icb_cmd_read,
    input  logic [31:0] dma_cfg_icb_cmd_addr,
    input  logic [31:0] dma_cfg_icb_cmd_wdata,
    input  logic [3:0]  dma_cfg_icb_cmd_wmask,
    output logic        dma_cfg_icb_cmd_ready,

    input  logic        dma_cfg_icb_rsp_ready,
    output logic        dma_cfg_icb_rsp_valid,
    output logic [31:0] dma_cfg_icb_rsp_rdata,
    output logic        dma_cfg_icb_rsp_err,

    input  logic [31:0] SR,  // RO, [7:0] used
    output logic [31:0] CTR, // WR, [7:0] used
    output logic [31:0] CR,  // WR, [7:0] used
    output logic [31:0] SRC_REG, // WR, [31:0] used
    output logic [31:0] DST_REG, // WR, [31:0] used
    output logic [31:0] LEN_REG  // WR, [31:0] used
);

    logic dma_cfg_icb_cmd_hsk, dma_cfg_icb_rsp_hsk;
        
    assign dma_cfg_icb_cmd_hsk = dma_cfg_icb_cmd_valid & dma_cfg_icb_cmd_ready;
    assign dma_cfg_icb_rsp_hsk = dma_cfg_icb_rsp_valid & dma_cfg_icb_rsp_ready;

    assign dma_cfg_icb_cmd_ready = dma_cfg_icb_cmd_read ? 
                                (dma_cfg_icb_cmd_valid & (!dma_cfg_icb_rsp_valid)):
                                SR[2] ? 0:dma_cfg_icb_cmd_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dma_cfg_icb_rsp_valid <= 0;
        else
            if (dma_cfg_icb_cmd_hsk)
                dma_cfg_icb_rsp_valid <= 1;
            else if (dma_cfg_icb_rsp_valid)
                dma_cfg_icb_rsp_valid <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_cfg_icb_rsp_rdata <= 0;
        end
        else begin
            if (dma_cfg_icb_rsp_valid) begin
                dma_cfg_icb_rsp_rdata <= dma_cfg_icb_rsp_rdata;
            end
            else if (dma_cfg_icb_cmd_hsk && dma_cfg_icb_cmd_read) begin
                case (dma_cfg_icb_cmd_addr[7:0]) 
                    `SR_ADDR     :   dma_cfg_icb_rsp_rdata <= SR;
                    `CTR_ADDR    :   dma_cfg_icb_rsp_rdata <= CTR;
                    `CR_ADDR     :   dma_cfg_icb_rsp_rdata <= CR;
                    `SRC_ADDR    :   dma_cfg_icb_rsp_rdata <= SRC_REG;
                    `DST_ADDR    :   dma_cfg_icb_rsp_rdata <= DST_REG;
                    `LEN_ADDR    :   dma_cfg_icb_rsp_rdata <= LEN_REG;
                endcase
            end
            else begin
                dma_cfg_icb_rsp_rdata <= 0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            CTR <= 0;
            CR <= 0;
            SRC_REG <= 0;
            DST_REG <= 0;
            LEN_REG <= 0;
        end
        else begin
            if (dma_cfg_icb_cmd_hsk && (!dma_cfg_icb_cmd_read)) begin
                case (dma_cfg_icb_cmd_addr[7:0]) 
                    // WITHOUT SR!
                    `CTR_ADDR    :   CTR[7:0]        <= dma_cfg_icb_cmd_wdata[7:0];
                    `CR_ADDR     :   CR[7:0]         <= dma_cfg_icb_cmd_wdata[7:0];
                    `SRC_ADDR    :   SRC_REG         <= dma_cfg_icb_cmd_wdata;
                    `DST_ADDR    :   DST_REG         <= dma_cfg_icb_cmd_wdata;
                    `LEN_ADDR    :   LEN_REG         <= dma_cfg_icb_cmd_wdata;
                endcase
            end
            else begin
                CR[7:0] <= {{1'b0}, CR[6:0]};
            end
        end
    end

    assign dma_cfg_icb_rsp_err = dma_cfg_icb_cmd_hsk && (!dma_cfg_icb_cmd_read) && (dma_cfg_icb_cmd_addr[7:0] == 0);

endmodule