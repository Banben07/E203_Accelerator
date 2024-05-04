module sram_8k_32b#(
    parameter INIT = ""
)(
    input clk,

    // write port
    input logic wsbn, //write enable, active low
    input logic [12:0] waddr,
    input logic [31:0] wdata,

    //read port
    input  logic csbn, //read enable, active low
    input  logic [12:0] raddr,
    output logic [31:0] rdata
);

logic [31:0] mem[8192];

initial begin
    if (INIT != "") begin
        int fp, k;
        fp = $fopen(INIT, "r");
        $fscanf(fp, "%d\n", k);
        for (int i=0;i<k;i++) begin
            $fscanf(fp, "%b\n", mem[i]);
        end
        $fclose(fp);
    end
end

always_ff @(posedge clk) begin: write
    if(!csbn && !wsbn) begin
        mem[waddr] <= wdata;
    end
end

always_ff @(posedge clk) begin: read
    if(!csbn) begin
        rdata <= mem[raddr];
    end
end

endmodule