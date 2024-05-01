`timescale 1ns / 1ps 

module conv_kernal (
    input  wire clk,
    input  wire [8:0][15:0] ifmap_3x3,
    input  wire [8:0][15:0] weight_3x3_ch1,
    // input  wire [8:0][15:0] weight_3x3_ch2,

    output wire [15:0] ofmap_ch1
    // output wire [15:0] ofmap_ch2
);

    wire [8:0][15:0] ch1_out, ch2_out;

    reg  [8:0][15:0] ch1_out_reg, ch2_out_reg;
   
    generate
        for (genvar i=0; i<9; i++) begin
            float_multi u_float_multi_1(
                //ports
                .num1   		( weight_3x3_ch1[i] ),
                .num2   		( ifmap_3x3[i]      ),
                .result  		( ch1_out[i]        )
            );
            // float_multi u_float_multi_2(
            //     //ports
            //     .num1   		( weight_3x3_ch1[i] ),
            //     .num2   		( ifmap_3x3[i]      ),
            //     .result  		( ch2_out[i]        )
            // );
        end
    endgenerate

    always @(posedge clk) begin
        ch1_out_reg <= ch1_out;
        ch2_out_reg <= ch2_out;
    end

    addertree9_fp16 u_addertree9_fp16_1(
        //ports
        .clk  		( clk  		),
        .a          ( ch1_out_reg         ),
        .dout 		( ofmap_ch1 	  )
    );

    // addertree9_int16 u_addertree9_fp16_2(
    //     //ports
    //     .clk  		( clk  		),
    //     .a          ( ch2_out_reg         ),
    //     .dout 		( ofmap_ch2 	  )
    // );

    
endmodule //conv_kernal_1x2
