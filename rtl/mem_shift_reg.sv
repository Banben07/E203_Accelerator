module mem_shift_reg
#(
    parameter DEPTH = 8,  // 默认深度
    parameter WIDTH = 16   // 默认数据宽度
)
(
    input wire clk,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

// 移位寄存器数组
reg [WIDTH-1:0] shift_reg [300:0];

// 顺序逻辑以移动数据
always_ff @(posedge clk) begin
    shift_reg[0] <= din;
    for (int i = 1; i < DEPTH; i++) begin
        shift_reg[i] <= shift_reg[i-1];
        
    end
end

// 将移位寄存器的最后一个元素分配给输出
assign dout = shift_reg[DEPTH-1];

endmodule
