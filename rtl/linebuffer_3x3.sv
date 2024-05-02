module linebuffer_3x3 #(
    parameter LEN = 4
) (
    input        clk,
    input [15:0] ifmap_stream,

    output [8:0][15:0] ifmap_3x3
);

  wire [15:0] ifmap_tmp1, ifmap_tmp2;
  reg [15:0] ifmap1_1, ifmap1_2, ifmap1_3;
  reg [15:0] ifmap2_1, ifmap2_2, ifmap2_3;
  reg [15:0] ifmap3_1, ifmap3_2, ifmap3_3;

  wire [15:0] line1_in, line1_out;
  wire [15:0] line2_in, line2_out;

  assign line1_in = ifmap_stream;
  assign line2_in = line1_out;

  mem_shift_reg #(
      .DEPTH(LEN),
      .WIDTH(16)
  ) u_mem_shift_reg1 (
      //ports
      .clk (clk),
      .din (line1_in),
      .dout(ifmap_tmp1)
  );

  mem_shift_reg #(
      .DEPTH(LEN),
      .WIDTH(16)
  ) u_mem_shift_reg2 (
      //ports
      .clk (clk),
      .din (line2_in),
      .dout(ifmap_tmp2)
  );


  assign line1_out = ifmap_tmp1;
  assign line2_out = ifmap_tmp2;

  always_ff @(posedge clk) begin
    ifmap1_1 <= ifmap1_2;
    ifmap1_2 <= ifmap1_3;
    ifmap1_3 <= line2_out;

    ifmap2_1 <= ifmap2_2;
    ifmap2_2 <= ifmap2_3;
    ifmap2_3 <= line1_out;

    ifmap3_1 <= ifmap3_2;
    ifmap3_2 <= ifmap3_3;
    ifmap3_3 <= ifmap_stream;
  end

  assign ifmap_3x3 = {ifmap3_3, ifmap3_2, ifmap3_1, ifmap2_3, ifmap2_2, ifmap2_1, ifmap1_3, ifmap1_2, ifmap1_1};


endmodule  //linebuffer_3x3
