`timescale 1ns / 1ps

module tb_linebuffer_3x3;

    // Testbench uses the same parameter size as the DUT
    

    // Inputs
    reg clk;
    reg [2:0] sel;
    reg [15:0] ifmap_stream;

    // Outputs
    wire [8:0][15:0] ifmap_3x3;
    int i;

    // Instantiate the Unit Under Test (UUT)
    linebuffer_3x3  uut (
        .clk(clk),
        .ifmap_stream(ifmap_stream),
        .ifmap_3x3(ifmap_3x3)
    );

    // Clock generation
    always #5 clk = ~clk; // 100MHz Clock

    initial begin
        // Initialize Inputs
        $vcdpluson;
        $vcdplusmemon();
        clk = 0;
        ifmap_stream = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Stimulus: Apply different selections and input streams
        i = 0;
        repeat(16) begin
            @(posedge clk);
            ifmap_stream = i+1;
            i = i + 1;
        end

        // Add more stimuli as needed to fully test the linebuffer

        // Finish simulation
        #10000;
        $finish;
    end

    // Optional: Add initial block to display outputs for debugging
    initial begin
        $monitor("Time=%t sel=%d ifmap_stream=%h ifmap_3x3=%h", $time, sel, ifmap_stream, ifmap_3x3);
    end

endmodule
