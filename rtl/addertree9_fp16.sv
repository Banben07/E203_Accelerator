`timescale 1ns / 1ps 


module addertree9_fp16 (
    input  wire clk,
    input  wire signed [8:0][15:0] a, 

    output reg 	signed [17:0] dout //The input significant value bit is 14, so output significant value bit is 17.

);

    reg signed [8:0][17:0] a_r1;
	
	reg signed [8:0][17:0] a_r2;
	
	always_comb begin: bit_expend
		for (int i=0; i<9; i++) begin
			a_r1[i] = {{a[i][15]}, {a[i][15]}, a[i]};
		end
	end

	always_ff @(posedge clk) begin: level1
		for (int i=0; i<3; i++) begin
			a_r2[i] <= a_r1[3*i] + a_r1[3*i+1] + a_r1[3*i+2];
		end
	end

	always_ff @(posedge clk) begin: level2
		dout <= a_r2[0] + a_r2[1] + a_r2[2];
	end

endmodule //addertree9_int16