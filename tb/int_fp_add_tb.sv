`define PATTERN "./utils/add_golden_pattern.txt"
`define PATTERN_NUM 20
module int_fp_add_tb ();

    reg [15:0] input1,input2;
    reg [15:0] expected;
    reg mode;
    reg [48:0] pattern [0:`PATTERN_NUM-1];
    reg [7:0] error_cnt;

    integer i;

    wire [15:0] result;
    float_adder u1 (input1,input2,result);
    real decimal_input1, decimal_input2, decimal_expected, decimal_result;
    real tolerance = 0.001; // Allowable tolerance for comparison
    
    // Task to convert 16-bit FP to decimal
    task automatic fp16_to_decimal(input [15:0] fp16, output real decimal);
        automatic integer exponent_bias = 15; // Declared as automatic
        automatic integer exponent, i;
        automatic real mantissa; // Declared as automatic to avoid unintended static behavior
        begin
            exponent = (fp16[14:10] - exponent_bias);
            mantissa = ((fp16[14:10] == 0) ? 0.0 : 1.0); // Check for subnormal numbers
            
            // Compute mantissa from the fractional part
            for (i = 0; i < 10; i = i + 1) begin
                mantissa = mantissa + ((fp16[9-i] & 1'b1) * (2.0 ** -(i+1)));
            end
            
            decimal = ((-1.0) ** fp16[15]) * mantissa * (2.0 ** exponent);
        end
    endtask

initial begin
    error_cnt = 0;
    #30;
    for(i=11;i<`PATTERN_NUM;i=i+1) begin
        {input1,input2,expected,mode} = pattern[i];
        #40
        fp16_to_decimal(input1, decimal_input1);
        fp16_to_decimal(input2, decimal_input2);
        fp16_to_decimal(expected, decimal_expected);
        fp16_to_decimal(result, decimal_result);
        $display("input1: %f, input2: %f, expected: %f, actual: %f", decimal_input1, decimal_input2, decimal_expected, decimal_result);
        if ((decimal_expected > decimal_result ? decimal_expected - decimal_result : decimal_result - decimal_expected) <= tolerance) begin 
            $display("Check PASSED");
            $display("--------------------");
        end else begin
            error_cnt = error_cnt + 1;
            $display("Check FAILED");
            $display("--------------------");
        end
    end
    #10;
    $display("Total error count: %d",error_cnt);
    #10;
    $finish;
end

initial begin 
    $vcdpluson;
    $vcdplusmemon();
end


initial begin 
    $readmemb(`PATTERN,pattern);
end

endmodule