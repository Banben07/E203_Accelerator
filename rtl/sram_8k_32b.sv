module sram_8k_32b#(
  )(
    input clk,

    // write port
    input logic wsbn,
    input logic [12:0] waddr,
    input logic [31:0] wdata,

    //read port
    input  logic csbn,
    input  logic [12:0] raddr,
    output logic [31:0] rdata
  );

  logic [31:0] mem[8192];



  always_ff @(posedge clk)
  begin: write
    if(wsbn)
    begin
      mem[waddr] <= wdata;
    end
  end

  always_ff @(posedge clk)
  begin: read
    if(csbn)
    begin
      rdata <= mem[raddr];
    end
  end

endmodule
