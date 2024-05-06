
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/04/29 17:17:45
// Design Name:
// Module Name: bn_multi_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module bn_multi_tb();
  parameter DATA_WIDTH = 16;
  parameter size = 4;


  reg clk, reset;
  reg [DATA_WIDTH*size-1:0]x;
  wire [DATA_WIDTH*size-1:0]Out;

  reg[2:0]  test_1;
  reg[0:2]  test_2;


  localparam PERIOD = 20;

  always
    #(PERIOD/2) clk = ~clk;

  initial
  begin
    $vcdpluson;
    $vcdplusmemon();
	test_1 = 3'b001;
	test_2 = 3'b001;
	$display("test_1=%b",test_1[0]);
	$display("test_2=%b",test_2[0]);
    #0 //starting the tanh
     clk <= 1'b1;
    reset <= 1'b1;
    x<=64'h40dd_40e3_3bdc_403d;
    #(2*PERIOD)
     reset <= 1'b0;
    #400
     //x<=64'h3C00_4000_4200_4400;
     //x<=64'h9C00_8000_B200_A400;

	$display("x=%h",Out);

     #2000000

     $finish;
  end
  bn_multi  UUT (x,Out,clk,reset);


endmodule
