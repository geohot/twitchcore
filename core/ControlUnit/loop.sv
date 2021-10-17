module loopmux #(parameter BITS=18) (
    input [2:0] addr,
    input [0:LINE*8-1] in,
    input independent,
    output loop_controller_new_loop new_loop,
    output loop_controller_end_loop end_loop
);
parameter LINE = BITS * 2;
reg [LINE-1:0] out;
//assign out = in[addr*18*6 +: 18*6]; // synthesizes so poorly it uses a DSP lmao
assign new_loop = {out[35 : 18], independent};
assign end_loop = out;
always @(*) begin
    case (addr)
        3'd0: out <= in[0*LINE +: LINE];
        3'd1: out <= in[1*LINE +: LINE];
        3'd2: out <= in[2*LINE +: LINE];
        3'd3: out <= in[3*LINE +: LINE];
        3'd4: out <= in[4*LINE +: LINE];
        3'd5: out <= in[5*LINE +: LINE];
        3'd6: out <= in[6*LINE +: LINE];
        3'd7:  out <= in[7*LINE +: LINE];
    endcase
end
endmodule

module single_loop #(parameter BITS=18, SUPERSCALAR_LOG_WIDTH=2) (
  input clk,
  input reset,
  input enable,
  input [BITS-1:0] initial_iteration_count,
  input initial_is_inner_independent_loop,
  output wire done,
  output wire [BITS-1:0] current_iteration,
  output wire [BITS-1:0] cur_di // Send to APU
);
  parameter SUPERSCALAR_WIDTH = (1 << SUPERSCALAR_LOG_WIDTH);
  reg is_inner_independent_loop;
  reg [BITS-1:0] prev_iteration;
  // Only one loop is enabled at a time so are we wasting LUTs by having this update logic run in each one?
  assign cur_di = enable ? (is_inner_independent_loop ? (prev_iteration < SUPERSCALAR_WIDTH ? prev_iteration : SUPERSCALAR_WIDTH) : 1) : 0;
  assign current_iteration = prev_iteration - cur_di;
  assign done = current_iteration == 0;
  always @(posedge clk) begin
    if (reset) begin
      is_inner_independent_loop <= initial_is_inner_independent_loop;
      prev_iteration <= initial_iteration_count - 1; // should i fold this into current_iteration?
    end else if (enable) begin
      prev_iteration <= current_iteration;
    end
  end
endmodule


module loop #(parameter BITS=18, LOOP_LOG_CNT=3, SUPERSCALAR_LOG_WIDTH=2, LOG_APU_CNT=3) (
  input clk,
  input reset, // clear all state
  input enable, // active this cycle (could be stalled from full instruction queue) or maybe just not loop controller stage of cpu
  input loop_controller_new_loop new_loop,
  input loop_controller_end_loop end_loop_or_jump,
  input is_start_loop,
  output current_loop_done, // is the most nested loop out of iterations
  output reg [SUPERSCALAR_LOG_WIDTH-1:0] copy_count, // instead of 0, 1, 2, 3. it's 1, 2, 3, 4
  output [LOOP_LOG_CNT-1:0] current_loop_depth_out,
  output [BITS-1:0] current_loop_cur_di
);
  parameter LOOP_CNT = (1 << LOOP_LOG_CNT);
  parameter APU_CNT = (1 << LOG_APU_CNT);
  parameter SUPERSCALAR_WIDTH = (1 << SUPERSCALAR_LOG_WIDTH);

  reg signed [LOOP_LOG_CNT-1:0] old_loop_depth;
  wire signed [LOOP_LOG_CNT:0] current_loop_depth; // -1 is empty
  assign current_loop_depth = enable && is_start_loop ? old_loop_depth + 1 : old_loop_depth;
  assign current_loop_depth_out = current_loop_depth[2:0]; // prune signed high bit
  wire is_top_of_stack_independent_loop;
  reg old_is_top_of_stack_independent_loop;
  
  assign is_top_of_stack_independent_loop = enable && is_start_loop ? new_loop.is_inner_independent_loop : old_is_top_of_stack_independent_loop;

  assign current_loop_done = loop_done[current_loop_depth];
  assign current_loop_cur_di = loop_cur_di[(current_loop_depth)*BITS +: BITS]; // should only be nonzero when loop enable is on

  wire [BITS-1:0] di;
  always @(posedge clk) begin
    // uses lots of LUT
    // do i care if this runs even when enable is off?
    // do i save time and money by computing this as a function of loop_cur_di? Does that formula exist? And is it even possible?
    copy_count <= is_top_of_stack_independent_loop
                  ? loop_current_iteration[(current_loop_depth)*BITS +: BITS] < SUPERSCALAR_WIDTH
                    ? loop_current_iteration[(current_loop_depth)*BITS +: BITS] // loop_current_iteration + 1
                    : SUPERSCALAR_WIDTH - 1 // 4
                  : 0; // 1
  end

  // A stack of loops.
  // When receive new instruction, push loop to top of stack
  // When loop completes, pop it off stack
  wire [LOOP_CNT-1:0] enable_loop, reset_loop, loop_done;
  wire [LOOP_CNT*BITS-1:0] loop_current_iteration, loop_cur_di;
  single_loop #(BITS, SUPERSCALAR_LOG_WIDTH) single_loop[LOOP_CNT-1:0](
    .clk,
    .reset(reset_loop),
    .enable(enable_loop),
    .initial_iteration_count(new_loop.iteration_count),
    .initial_is_inner_independent_loop(new_loop.is_inner_independent_loop),
    .done(loop_done),
    .current_iteration(loop_current_iteration),
    .cur_di(loop_cur_di)
  );


  // =====================================
  // ======== Reset Enable Logic =========
  // =====================================

  generate
    for (genvar i = 0; i < LOOP_CNT ; i = i + 1) begin
      assign reset_loop[i]    = reset | (i-1 == current_loop_depth && is_start_loop); // reset before use. not after
      assign enable_loop[i]   = enable && i == current_loop_depth && !is_start_loop;
    end
  endgenerate

  always @(posedge clk) begin
    if (reset) begin
      old_loop_depth <= -1;
      old_is_top_of_stack_independent_loop <= 0;
    end
    if (enable) begin
      old_loop_depth <= current_loop_done ? current_loop_depth - 1 : current_loop_depth;
      old_is_top_of_stack_independent_loop <= is_top_of_stack_independent_loop;
    end
  end
endmodule