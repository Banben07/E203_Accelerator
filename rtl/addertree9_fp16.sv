`timescale 1ns / 1ps 


module addertree9_fp16 (
    input  wire clk,
    input  wire  [8:0][15:0] a, 

    output reg 	 [17:0] dout //The input significant value bit is 14, so output significant value bit is 17.

);

    reg  [8:0][15:0] a_tmp;

	generate
        for (genvar i=0; i<2; i++) begin
            float_adder u_float_adder_1(
                //ports
                .num1   		( weight_3x3_ch1[i] ),
                .num2   		( ifmap_3x3[i]      ),
                .result  		( ch1_out[i]        )
            );
            float_adder u_float_adder_2(
                //ports
                .num1   		( weight_3x3_ch1[i] ),
                .num2   		( ifmap_3x3[i]      ),
                .result  		( ch2_out[i]        )
            );
        end
    endgenerate
	

	always @(posedge clk) begin
		
	end
	
	

endmodule //addertree9_int16