module dma_top #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 1024
)(
    input clk,
    input rst_n,

    // config port, slave mod
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

    // data port, master mod
    output logic        dma_icb_cmd_valid,
    output logic        dma_icb_cmd_read,
    output logic [31:0] dma_icb_cmd_addr,
    output logic [DATA_WIDTH-1:0]       dma_icb_cmd_wdata,
    output logic [(DATA_WIDTH>>3)-1:0]  dma_icb_cmd_wmask,

    input  logic        acc_cmd_ready,
    input  logic        mem_cmd_ready,

    output logic        dma_icb_rsp_ready,

    input  logic        acc_rsp_valid,
    input  logic        mem_rsp_valid,

    input  logic [DATA_WIDTH-1:0]       mem_rdata,
    input  logic [DATA_WIDTH-1:0]       acc_rdata,

    input  logic        dma_icb_rsp_err,

    output logic        dma_irq

);
    
    // icb_slave interface
    logic [31:0] SR;  // RO, [7:0] used. SR[0]: irq sign. SR[1]: 1-dma transfer done. 
                      // SR[2]: 1-DMA busy. SR[3]: 1-DMA configured.
    logic [31:0] CTR; // RW, [7:0] used. CTR[6]: irq enable. CTR[7]: DMA enable.
    logic [31:0] CR;  // RW, [7:0] used. CR[0]: irq ack(clear SR[0]). CR[7]: start. Set CR[7] will clear itself.
    logic [31:0] SRC_REG; // WR, [31:0] used. src addr for data moving.
    logic [31:0] DST_REG; // WR, [31:0] used. dst addr for data moving.
    logic [31:0] LEN_REG; // WR, [31:0] used. length for data moving.

    logic dma_icb_cmd_hsk, dma_icb_rsp_hsk;

    enum logic [1:0] {IDLE, READ, WRITE} state, next_state;

    logic [DATA_WIDTH-1:0]       dma_icb_rsp_rdata;
    logic acc_hsk;
    
    assign dma_icb_rsp_rdata = (acc_hsk) ? acc_rdata:mem_rdata;
    logic        dma_icb_cmd_ready;
    assign dma_icb_cmd_ready = (acc_hsk) ? acc_cmd_ready:mem_cmd_ready;
    logic        dma_icb_rsp_valid;
    assign dma_icb_rsp_valid = (acc_hsk) ? acc_rsp_valid:mem_rsp_valid;
    
    logic src_check, dst_check;

    assign src_check = SRC_REG >= 32'h10042000 && SRC_REG <= 32'h10042fff;

    assign dst_check = DST_REG >= 32'h10042000 && DST_REG <= 32'h10042fff;

    assign acc_hsk = (src_check && (state == READ)) || (dst_check && (state == WRITE));
        
    assign dma_icb_cmd_hsk = dma_icb_cmd_valid & dma_icb_cmd_ready;
    assign dma_icb_rsp_hsk = dma_icb_rsp_valid & dma_icb_rsp_ready;
    
    // sync_fifo interface
    logic [DATA_WIDTH-1:0] wdata, rdata;
    logic wen, ren, full, empty, almost_full, overflow;


    logic [31:0] read_rsp_cnt, write_rsp_cnt, read_cmd_cnt, write_cmd_cnt;

    logic dma_enable, dma_start, dma_busy, dma_done, dma_cfged;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    assign dma_enable = CTR[7];

    assign dma_start  = CR[7];

    always_comb begin
        case (state)
            IDLE  : begin
                if (dma_enable && dma_start)
                    next_state = READ;
                else
                    next_state = IDLE;
            end
            READ  : begin
                if ((read_rsp_cnt < LEN_REG) &&
                    ((almost_full && dma_icb_rsp_hsk) != 1))
                    next_state = READ;
                else
                    next_state = WRITE;
            end
            WRITE : begin
                if ((write_cmd_cnt < LEN_REG) &&
                    ((empty && dma_icb_rsp_hsk) != 1))
                    next_state = WRITE;
                else if (read_rsp_cnt < LEN_REG)
                    next_state = READ;
                else 
                    next_state = IDLE;
            end
            default :  next_state = IDLE;
        endcase
    end

    // hsk conuters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_cmd_cnt <= 0;
        else if (dma_icb_cmd_hsk && (state == READ))
            read_cmd_cnt <= read_cmd_cnt + 1;
        else if (SR[1])
            read_cmd_cnt <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            write_cmd_cnt <= 0;
        else if (dma_icb_cmd_hsk && (state == WRITE))
            write_cmd_cnt <= write_cmd_cnt + 1;
        else if (SR[1])
            write_cmd_cnt <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_rsp_cnt <= 0;
        else if (dma_icb_rsp_hsk && (state == READ))
            read_rsp_cnt <= read_rsp_cnt + 1;
        else if (SR[1])
            read_rsp_cnt <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            write_rsp_cnt <= 0;
        else if (dma_icb_rsp_hsk && (state == WRITE))
            write_rsp_cnt <= write_rsp_cnt + 1;
        else if (SR[1])
            write_rsp_cnt <= 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_icb_cmd_valid <= 0;
        end
        else begin
            if (dma_icb_cmd_hsk)
                dma_icb_cmd_valid <= 0;
            else if ((read_cmd_cnt < LEN_REG) && (state == READ)) begin
                if (!almost_full)
                    dma_icb_cmd_valid <= 1;
            end
            else if ((write_cmd_cnt < LEN_REG) && (state == WRITE)) begin
                if (!empty)
                    dma_icb_cmd_valid <= 1;
            end
        end
    end

    assign dma_icb_rsp_ready = 1;

    always_comb begin
        if (dma_icb_cmd_hsk && (state == READ)) begin
            if (src_check) begin
                dma_icb_cmd_addr = SRC_REG + read_cmd_cnt;
            end else begin
                dma_icb_cmd_addr = SRC_REG + (read_cmd_cnt << 2);
            end
        end else if (dma_icb_cmd_hsk && (state == WRITE)) begin
            if (DST_REG == 32'h10042000) begin
                dma_icb_cmd_addr = DST_REG;
            end
            else if (DST_REG >= 32'h10042008 && DST_REG <= 32'h10042fff) begin
                dma_icb_cmd_addr = DST_REG + write_cmd_cnt;
            end else begin
                dma_icb_cmd_addr = DST_REG + (write_cmd_cnt << 2);
            end
        end else 
            dma_icb_cmd_addr = 0;
    end

    assign dma_icb_cmd_read = (state == READ) ? 1:0;

    assign wdata = (dma_icb_rsp_hsk && (state == READ)) ? dma_icb_rsp_rdata:0;

    assign dma_icb_cmd_wdata = (state == WRITE) ? rdata:0;

    assign dma_icb_cmd_wmask = (state == WRITE) ? {(DATA_WIDTH>>3){1'b1}}:0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dma_irq <= 0;
        else
            if (SR[1] && CTR[6]) // dma done & irq enable
                dma_irq <= 0;
            else if (CR[0]) // irq request
                dma_irq <= 0;
    end

        always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dma_busy <= 0;
        else
            if (next_state == IDLE) 
                dma_busy <= 0;
            else
                dma_busy <= 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dma_done <= 0;
        else
            if ((write_cmd_cnt == LEN_REG) && SR[3]) // dma config
                dma_done <= 1;
            else if (CTR[7] && (CR[7] || CR[0])) // dma enable && (start || ack)
                dma_done <= 0;
    end

    assign dma_cfg = (SRC_REG != 0) & (DST_REG != 0) & (LEN_REG != 0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            SR <= 0;
        else
            SR <= {{28'd0}, dma_cfg, dma_busy, dma_done, dma_irq};
    end

    dma_icb_slave #(.FIFO_DEPTH(FIFO_DEPTH))
    u_icb_slave (
        .clk(clk),
        .rst_n(rst_n),

        // config port, slave mod, R/W result returns after 1 cycle.
        .dma_cfg_icb_cmd_valid(dma_cfg_icb_cmd_valid),
        .dma_cfg_icb_cmd_read(dma_cfg_icb_cmd_read),
        .dma_cfg_icb_cmd_addr(dma_cfg_icb_cmd_addr),
        .dma_cfg_icb_cmd_wdata(dma_cfg_icb_cmd_wdata),
        .dma_cfg_icb_cmd_wmask(dma_cfg_icb_cmd_wmask),
        .dma_cfg_icb_cmd_ready(dma_cfg_icb_cmd_ready),

        .dma_cfg_icb_rsp_ready(dma_cfg_icb_rsp_ready),
        .dma_cfg_icb_rsp_valid(dma_cfg_icb_rsp_valid),
        .dma_cfg_icb_rsp_rdata(dma_cfg_icb_rsp_rdata),
        .dma_cfg_icb_rsp_err(dma_cfg_icb_rsp_err),

        .SR(SR),  // RO, [7:0] used
        .CTR(CTR), // WR, [7:0] used
        .CR(CR),  // WR, [7:0] used
        .SRC_REG(SRC_REG), // WR, [31:0] used
        .DST_REG(DST_REG), // WR, [31:0] used
        .LEN_REG(LEN_REG)  // WR, [$clog2(FIFO_DEPTH)-1:0] used
    );

    logic wen, ren;

    assign wen = dma_icb_rsp_hsk && (state == READ);
    assign ren = dma_icb_cmd_hsk && (state == WRITE);

    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH))
    u_sync_fifo(
        .clk(clk), 
        .rst_n(rst_n),

        .wdata(wdata),
        .wen(wen),
        .ren(ren),

        .rdata(rdata),
        .full(full),
        .empty(empty),

        .almost_full(almost_full),
        .overflow(overflow)
    );
    
endmodule