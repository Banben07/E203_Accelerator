`define PATTERN "./utils/conv_golden_pattern.txt"
`define PATTERN_NUM 30

module sram_8k_32b_input#(
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
  logic     [863:0]       pattern         [0:`PATTERN_NUM-1];
  logic  [ 15:0][15:0] ifmap_1;
  logic  [ 15:0][15:0] ifmap_2;
  logic  [  8:0][15:0] weight_1;
  logic  [  8:0][15:0] weight_2;
  logic  [  3:0][15:0] of_map_expected;

  localparam WEIGHT_ADDR_BASE = 7680;

  initial
  begin
    if (`PATTERN != "")
    begin

      $readmemb(`PATTERN, pattern);

      for (int i=0;i < `PATTERN_NUM;i++)
      begin
        {ifmap_1, ifmap_2, weight_1, weight_2, of_map_expected} = pattern[i];
        for (int k = 0; k < 16; k++) begin
            mem[i*16+k+1][15:0] = ifmap_1[k];
            mem[i*16+k+1][31:16] = ifmap_2[k];
        end
        for (int k = 0; k < 9; k++) begin
            if (i == 0) begin
                mem[i*9+k+WEIGHT_ADDR_BASE][15:0] = weight_1[k];
                mem[i*9+k+WEIGHT_ADDR_BASE][31:16] = weight_2[k];
            end
        end
      end
      mem[9+WEIGHT_ADDR_BASE] = 0;
      mem[10+WEIGHT_ADDR_BASE] = 0;
    end
  end

//   always_ff @(posedge clk)
//   begin: write
//     if(!csbn && !wsbn)
//     begin
//       mem[waddr] <= wdata;
//     end
//   end

  always_ff @(posedge clk)
  begin: read
    if(csbn)
    begin
      rdata <= mem[raddr];
    end
  end

endmodule
