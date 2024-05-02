module conv_control (
    input  clk,
    input  rst_n,
    input  start,
    input  [15:0] conv_num,
    // input wire [15:0] conv_len,
    input  [8:0][15:0] kernel_num,

    output  [15:0] ofmap_out, //for test
    output  done,
    output  dout_valid
);

    //parameter
    localparam IDLE = 0;
    localparam CONV_1 = 1;
    localparam LB = 2;
    localparam CONV_2 = 3;

    //state
    reg [1:0] state, next_state;
    reg [15:0] ifmap_cnt;
    reg [15:0] conv_cnt;
    reg [15:0] ofmap_cnt;
    reg [15:0] dout_reg;
    reg [15:0] of_line_num;
    reg dout_valid_reg;
    reg done_reg;
    wire [8:0][15:0] ifmap_3x3;
    wire [15:0]  dout;

    assign ofmap_out = dout_reg;
    assign dout_valid = dout_valid_reg;
    assign done = done_reg;

    linebuffer_3x3 #(
        .LEN(4)
    ) u_linebuffer_3x3 (
        .clk(clk),
        .ifmap_stream(conv_num),
        .ifmap_3x3(ifmap_3x3)
    );

    conv_kernal u_conv_kernal (
        .clk(clk),
        .ifmap_3x3(ifmap_3x3),
        .weight_3x3_ch1(kernel_num),
        .ofmap_ch1(dout)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end       
    end

    always @(*) begin

        case(state)
            IDLE: begin
                if (start) begin
                    ifmap_cnt = 0;
                    next_state = LB;
                    dout_reg = 0;
                    dout_valid_reg = 0;
                    done_reg = 0;
                    ofmap_cnt = 0;
                    of_line_num = 0;
                    conv_cnt = 0;
                end
                else begin
                    next_state = IDLE;
                end
            end
            LB: begin
                if (ifmap_cnt < 9) begin
                    next_state = LB;
                    ifmap_cnt = ifmap_cnt + 1;
                end
                else begin
                    next_state = CONV_1;
                    ifmap_cnt = 0;
                end
            end
            CONV_1: begin
                if (conv_cnt < 2) begin
                    next_state = CONV_1;
                    conv_cnt = conv_cnt + 1;
                end
                else begin
                    if (of_line_num < 2) begin
                        of_line_num = of_line_num + 1;
                        next_state = CONV_1;
                        dout_reg = dout;
                        ofmap_cnt = ofmap_cnt + 1;
                        dout_valid_reg = 1;
                    end
                    else begin
                        next_state = CONV_2;
                        dout_reg = 0;
                        conv_cnt = 0;
                        dout_valid_reg = 0;
                        of_line_num = 0;
                    end
                end
            end
            CONV_2: begin
                if (conv_cnt < 3) begin
                    next_state = CONV_2;
                    conv_cnt = conv_cnt + 1;
                end
                else begin
                    if (ofmap_cnt < 5) begin
                        if (of_line_num < 2) begin
                            of_line_num = of_line_num + 1;
                            next_state = CONV_2;
                            dout_reg = dout;
                            ofmap_cnt = ofmap_cnt + 1;
                            dout_valid_reg = 1;
                        end
                        else begin
                            next_state = CONV_2;
                            dout_reg = 0;
                            conv_cnt = 0;
                            dout_valid_reg = 0;
                            of_line_num = 0;
                        end
                    end
                    else begin
                        next_state = IDLE;
                        dout_reg = 0;
                        dout_valid_reg = 0;
                        done_reg = 1;
                    end
                end
            end
            default: begin
                next_state = IDLE;
            end

        endcase
    end

    
endmodule
