module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 1024
)(
    input clk, 
    input rst_n,

    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic wen,
    input  logic ren,

    output logic [DATA_WIDTH-1:0] rdata,
    output logic full,
    output logic empty,

    output logic almost_full,
    output logic overflow

);

    logic [$clog2(FIFO_DEPTH)-1:0] waddr, raddr;
    logic [$clog2(FIFO_DEPTH):0] cnt;
    logic [DATA_WIDTH-1:0] mem [FIFO_DEPTH];

    always_ff @(posedge clk or negedge rst_n) begin: fifo_counter
        if (!rst_n)
            cnt <= 0;
        else
            if ((wen && !full) && !(ren && !empty))
                cnt <= cnt + 1;
            else if ((ren && !empty) && !(wen && !full))
                cnt <= cnt - 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin: write_counter
        if (!rst_n) begin
            waddr <= 0;
        end
        else if (wen && !full)
            if (waddr == (FIFO_DEPTH-1))
                waddr <= 0;
            else
                waddr <= waddr + 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin: read_counter
        if (!rst_n)
            raddr <= 0;
        else if (ren && !empty)
            if (raddr == (FIFO_DEPTH-1))
                raddr <= 0;
            else
                raddr <= raddr + 1;
    end

    always_ff @(posedge clk) begin
        if (wen)
            mem[waddr] <= wdata;
    end

    assign rdata = empty ? 0:mem[raddr];

    assign full = (cnt == FIFO_DEPTH) ? 1:0;

    assign empty = (cnt == 0) ? 1:0;

    assign almost_full = (cnt == FIFO_DEPTH-1) ? 1:0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            overflow <= 0;
        else
            if (full && wen)
                overflow <= 1;
            else
                overflow <= 0;
    end

endmodule