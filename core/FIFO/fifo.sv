// Can save signfiicant LUTs by decreasing LINE
// Can push up to 4 elements per cycle
// Can pop up to 1 element per cycle
module superscalar_fifo #(parameter LINE=18)(
  input clk,
  input reset,
  input re,
  input we,
  input [1:0] we_count,
  input [LINE-1:0] dat_w_1,
  input [LINE-1:0] dat_w_2,
  input [LINE-1:0] dat_w_3,
  input [LINE-1:0] dat_w_4,
  output reg [LINE-1:0] dat_r,
  output full_soon, // at most 4 cycles away from being full
  output empty_soon, // at most 4 cycles away from being empty
);
  // mem[tail] is in the list. mem[head] is next position to put something
  reg [LINE*4-1:0] mem [0:63]; // 6 bit memory addresses should provide some FPGA benefits. We don't need large queue
  reg [5:0] head, tail;
  reg [1:0] read_line_position;
  wire [1:0] read_line_position_next;
  assign read_line_position_next = read_line_position + 1;
  assign size = head > tail ? head - tail : 63 - tail + head;
  // 6 bit size means both flags together just 1 (6 in 2 out) LUT!!!
  assign full_soon = size == 63 | size == 64;
  assign empty_soon = size == 1 | size == 0;
  always @(posedge clk) begin
    if (reset) begin
      head <= 0;
      tail <= 0;
      read_line_position <= 0;
    end
    else begin
      if (we) begin
        mem[head] <= {we_count, dat_w_1, dat_w_2, dat_w_3, dat_w_4};
        head <= head + 1; // % 64
      end
      if (re) begin
        read_line_position <= read_line_position_next > dat_r[1:0] ? 0 : read_line_position_next;
        tail <= read_line_position_next > dat_r[1:0] ? tail + 1 : tail;
        dat_r <= mem[tail][2+read_line_position*LINE +: LINE];
      end
    end
  end
endmodule


// For small line widths and small queue sizes, can save BRAM by using shift regs or luts?
module basic_fifo #(parameter LINE=18)(
  input clk,
  input reset,
  input re,
  input we,
  input [LINE-1:0] dat_w,
  output reg [LINE-1:0] dat_r,
  output full_next,
  output empty_next,
  output full,
  output empty
);
  // mem[tail] is in the list. mem[head] is next position to put something
  reg [LINE-1:0] mem [0:63]; // 6 bit memory addresses should provide some FPGA benefits. We don't need large queue
  reg [5:0] head, tail;
  assign size = head > tail ? head - tail : 63 - tail + head;
  // 6 bit size means both flags together just 1 (6 in 2 out) LUT!!!
  assign full_next = size == 63 | size == 64;
  assign full = size == 64;
  assign empty_next = size == 1 | size == 0;
  assign empty = size == 0;
  always @(posedge clk) begin
    if (reset) begin
      head <= 0;
      tail <= 0;
    end
    else begin
      if (we) begin
        mem[head] <= dat_w;
        head <= head + 1; // % 64
      end
      if (re) begin
        dat_r <= mem[tail];
        tail <= tail + 1;
      end
    end
  end
endmodule