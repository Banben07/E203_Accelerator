module addertree9_fp16 (
    input  wire clk,
    input  wire  [8:0][15:0] a, 

    output wire 	 [15:0] dout //The input significant value bit is 14, so output significant value bit is 17.

);


    wire [2:0][15:0] c_mid, c_0;
    wire [15:0] o_mid;

    reg  [2:0][15:0] c_reg;

    generate
        for (genvar i= 0; i<3; i++) begin
            floatAdd u_float_adder_stage1_1(
                //ports
                .num1   		( a[3*i+0] ),
                .num2   		( a[3*i+1]      ),
                .result  		( c_mid[i]   )
            );
            floatAdd u_float_adder_stage1_2(
                //ports
                .num1   		( a[3*i+2] ),
                .num2   		( c_mid[i]      ),
                .result  		( c_0[i]        )
            );
        end
    endgenerate


	

	always @(posedge clk) begin
		c_reg <= c_0;
	end

    floatAdd u_float_adder_stage2_1(
        //ports
        .num1   		( c_reg[0]   ),
        .num2   		( c_reg[1]   ),
        .result  		( o_mid   )
    );
    floatAdd u_float_adder_stage2_2(
        //ports
        .num1   		( c_reg[2] ),
        .num2   		( o_mid     ),
        .result  		( dout      )
    );
	
	

endmodule //addertree9_int16
