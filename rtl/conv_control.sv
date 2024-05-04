module conv_control (
    input              clk,
    input              rst_n,
    input              start,
    input [31:0]       conv_num,
    input              conv_num_valid,
    // input wire [15:0] conv_len,
    input [ 8:0][15:0] kernel_num_1,
    input [ 8:0][15:0] kernel_num_2,

    output [15:0] ofmap_out,  //for test
    output        done,
    output        dout_valid
);

  //parameter
  localparam IDLE = 0;
  localparam LB = 1;
  localparam CONV_1 = 2;
  localparam CONV_OTHER = 3;

  //state
  reg  [ 1:0]       state;
  reg  [15:0]       ifmap_cnt;
  reg  [15:0]       conv_cnt;
  reg  [15:0]       ofmap_cnt;
  reg  [15:0]       dout_reg;
  reg  [15:0]       of_line_num;
  reg               dout_valid_reg;
  reg               done_reg;
  reg               lb_finish;
  wire [ 8:0][15:0] ifmap_1;
  wire [ 8:0][15:0] ifmap_2;
  wire [15:0]       dout;
  wire [15:0]       conv_num_1;
  wire [15:0]       conv_num_2;

  assign conv_num_1 = conv_num[15:0];
  assign conv_num_2 = conv_num[31:16];

  assign ofmap_out  = dout_reg;
  assign dout_valid = dout_valid_reg;
  assign done       = done_reg;

  linebuffer_3x3 #(
      .LEN(4)
  ) u_linebuffer_1 (
      .clk         (clk),
      .ifmap_stream(conv_num_1),
      .ifmap_3x3   (ifmap_1)
  );

  linebuffer_3x3 #(
      .LEN(4)
  ) u_linebuffer_2 (
      .clk         (clk),
      .ifmap_stream(conv_num_2),
      .ifmap_3x3   (ifmap_2)
  );

  conv_kernal u_conv_kernal (
      .clk           (clk),
      .ifmap_1       (ifmap_1),
      .ifmap_2       (ifmap_2),
      .weight_3x3_ch1(kernel_num_1),
      .weight_3x3_ch2(kernel_num_2),
      .ofmap         (dout)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ifmap_cnt <= 0;
      lb_finish <= 0;
    end else if (conv_num_valid) begin
      if (ifmap_cnt <= 16'h9) begin
        ifmap_cnt <= ifmap_cnt + 1;
        lb_finish <= (ifmap_cnt == 16'h9);
      end else if (ifmap_cnt == 16'h10) begin
        ifmap_cnt <= 16'h1;
        lb_finish <= 0;
      end else begin
        ifmap_cnt <= ifmap_cnt + 1;
        lb_finish <= 0;
      end
    end else begin
      ifmap_cnt <= ifmap_cnt;
      lb_finish <= 0;
    end
  end


  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state          <= LB;
      dout_reg       <= 0;
      dout_valid_reg <= 0;
      done_reg       <= 0;
      ofmap_cnt      <= 0;
      of_line_num    <= 0;
      conv_cnt       <= 0;
    end else begin
      case (state)
        IDLE: begin
          dout_reg       <= 0;
          dout_valid_reg <= 0;
          done_reg       <= 0;
          ofmap_cnt      <= 0;
          of_line_num    <= 0;
          conv_cnt       <= 0;
          if (start) begin
            state <= LB;
          end else begin
            state <= IDLE;
          end
        end
        LB: begin
          dout_reg       <= 0;
          dout_valid_reg <= 0;
          done_reg       <= 0;
          of_line_num    <= 0;
          conv_cnt       <= 0;
          if (lb_finish) begin
            state <= CONV_1;
          end else begin
            state <= LB;
          end
        end
        CONV_1: begin
          if (conv_cnt < 16'h2) begin
            state    <= CONV_1;
            conv_cnt <= conv_cnt + 16'h1;
          end else begin
            if (of_line_num < 16'h2) begin
              of_line_num    <= of_line_num + 16'h1;
              state          <= CONV_1;
              dout_reg       <= dout;
              ofmap_cnt      <= ofmap_cnt + 16'h1;
              dout_valid_reg <= 16'h1;
            end else begin
              state          <= CONV_OTHER;
              dout_reg       <= 0;
              conv_cnt       <= 0;
              dout_valid_reg <= 0;
              of_line_num    <= 0;
            end
          end
        end
        CONV_OTHER: begin
          if (conv_cnt < 16'h1) begin
            state    <= CONV_OTHER;
            conv_cnt <= conv_cnt + 16'h1;
          end else begin
            if ((ofmap_cnt < 5 && (ofmap_cnt % 5) < 16'h4) || (ofmap_cnt >= 5 && ((ofmap_cnt - 1) % 4) < 16'h3)) begin
              if (of_line_num < 16'h2) begin
                of_line_num    <= of_line_num + 16'h1;
                state          <= CONV_OTHER;
                dout_reg       <= dout;
                ofmap_cnt      <= ofmap_cnt + 16'h1;
                dout_valid_reg <= 16'h1;
              end else begin
                state          <= CONV_OTHER;
                dout_reg       <= 0;
                conv_cnt       <= 0;
                dout_valid_reg <= 0;
                of_line_num    <= 0;
              end
            end else begin
              if (ofmap_cnt < 16'd60) begin
                state          <= LB;
                dout_reg       <= 0;
                dout_valid_reg <= 0;
              end else begin
                state          <= LB;
                ofmap_cnt      <= 0;
                dout_reg       <= 0;
                dout_valid_reg <= 0;
                done_reg       <= 1;
                of_line_num    <= 0;
                conv_cnt       <= 0;
              end
            end
          end
        end
        default: begin
          state <= LB;
        end

      endcase
    end
  end

endmodule
