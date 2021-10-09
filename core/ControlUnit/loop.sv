// reset before using, please
// outer loop, inner loop, inner independent loop
// outer loop with only inner loops, outer loo wpith 
// on every clock edge, current_iteration is the amount of iterations remaining at the time the control unit passes an instruction in. We assume that as this edge falls, the instruction has been processed thus we need to make sure current_iteration is incremented once that clockedge falls.
module single_loop #(parameter BITS=18, SUPERSCALAR_LOG_WIDTH=2) (
  input clk,
  input reset,
  input should_increment,
  input [BITS-1:0] initial_iteration_count,
  input initial_is_inner_independent_loop,
  input jumped,
  output wire done,
  output reg [BITS-1:0] current_iteration,
  output wire [SUPERSCALAR_LOG_WIDTH:0] MIN_OF_CUR_ITERATION_AND_SUPERSCALAR // APU needs this
);
  parameter SUPERSCALAR_WIDTH = (1 << SUPERSCALAR_LOG_WIDTH);
  assign MIN_OF_CUR_ITERATION_AND_SUPERSCALAR = current_iteration < SUPERSCALAR_WIDTH ? current_iteration : SUPERSCALAR_WIDTH;
  reg is_inner_independent_loop;
  assign done = (is_inner_independent_loop ? current_iteration < SUPERSCALAR_WIDTH : ~(|current_iteration));
  always @(posedge clk) begin
    if (reset) begin
      is_inner_independent_loop <= initial_is_inner_independent_loop;
      current_iteration <= initial_iteration_count - 1;
    end else if (should_increment) begin
      if (jumped) current_iteration <= current_iteration - (is_inner_independent_loop ? (MIN_OF_CUR_ITERATION_AND_SUPERSCALAR) : 1);
    end
  end
endmodule


// start_loop instruction just needs 8 numbers.
// initial values and gradients for address and strides (6 numbers) as well as the loop iterations (1 number) and number of instructions in loop body (1 number).
// So loop instruction width is 8*18=144 bits. Saved in ro_data to keep instruction itself < 18 bits.

// Manages nested loop iterations
// Tell it when a create_independent_loop or create_loop instruction starts, and the info about that
// reset before using, please
module loop #(parameter BITS=15, LOOP_LOG_CNT=3, SUPERSCALAR_LOG_WIDTH=2, LOG_APU_CNT=3) (
  input clk,
  input reset, // clear all state
  input should_increment, // active this cycle (could be stalled from full instruction queue)
  input [BITS-1:0] new_loop_iteration_count, // new loop instruction
  input new_loop_is_inner_independent_loop, // new loop instruction
  input should_create_new_loop,
  input did_start_next_loop_iteration,
  input did_finish_loop,
  output done, // is the most nested loop out of iterations
  output reg [SUPERSCALAR_LOG_WIDTH-1:0] copy_count, // instead of 0, 1, 2, 3. it's 1, 2, 3, 4

  // expose some APU ports to whoever owns the loop module
  input [LOG_APU_CNT-1:0] apu_selector,
  input [(LOOP_CNT+1)*BITS*APU_CNT-1:0] new_address_formula, new_stride_x_formula, new_stride_y_formula,
  output signed [BITS-1:0] addr, stridex, stridey, daddr, dstridex, dstridey
);
  reg[LOOP_LOG_CNT:0] current_loop_depth; // need one extra bit to to consider when no loops are initialized
  reg is_top_of_stack_independent_loop;
  
  parameter LOOP_CNT = (1 << LOOP_LOG_CNT);
  parameter APU_CNT = (1 << LOG_APU_CNT);

  wire [LOOP_CNT*(SUPERSCALAR_LOG_WIDTH+1)-1:0] MIN_OF_CUR_ITERATION_AND_SUPERSCALAR;
  wire [LOOP_LOG_CNT-1:0] loop_var;
  assign loop_var = (current_loop_depth - 1);
  wire [BITS-1:0] di;
  assign di = did_finish_loop ? -loop_current_iteration[(current_loop_depth-1)*BITS +: BITS] : did_start_next_loop_iteration ? MIN_OF_CUR_ITERATION_AND_SUPERSCALAR[current_loop_depth] : 0;
  
  apu #(BITS, LOOP_LOG_CNT, LOG_APU_CNT) apu(
    .clk(clk),
    .reset(reset),
    .di(di), // set within this module
    .new_address_formula(new_address_formula),
    .new_stride_x_formula(new_stride_x_formula),
    .new_stride_y_formula(new_stride_y_formula),
    .change_loop_var(did_change_loop_depth), // set within this module
    .loop_var(loop_var), // set within this module
    .apu_selector(apu_selector),
    .addr(addr),
    .stridex(stridex),
    .stridey(stridey),
    .daddr(daddr),
    .dstridex(dstridex),
    .dstridey(dstridey)
  );

  // A stack of loops.
  // When receive new instruction, push loop to top of stack
  // When loop completes, pop it off stack
  wire [LOOP_CNT-1:0] loop_should_increment, loop_reset, loop_done;
  wire [LOOP_CNT*BITS-1:0] loop_current_iteration;
  single_loop #(BITS) single_loop[LOOP_CNT-1:0](
    .clk(clk),
    .reset(loop_reset),
    .should_increment(loop_should_increment),
    .initial_iteration_count(new_loop_iteration_count),
    .initial_is_inner_independent_loop(new_loop_is_inner_independent_loop),
    .jumped(did_start_next_loop_iteration),
    .done(loop_done),
    .current_iteration(loop_current_iteration),
    .MIN_OF_CUR_ITERATION_AND_SUPERSCALAR(MIN_OF_CUR_ITERATION_AND_SUPERSCALAR)
  );


  generate
    for (genvar i = 1; i < LOOP_CNT+1 ; i = i + 1) begin
      assign loop_reset[i-1] = reset | (i-1 == current_loop_depth && should_create_new_loop); // reset before use. not after
      assign loop_should_increment[i-1] = i == current_loop_depth && should_increment;
    end
  endgenerate

  reg did_change_loop_depth;
  reg just_jumped_back;
  always @(posedge clk) begin
    if (reset) begin
      current_loop_depth <= 0;
      copy_count <= 0; // 1
      is_top_of_stack_independent_loop <= 0;
    end else begin
      // 300 LUT out of the total module's 500
      // makes sense, is_top_of_stack_independent_loop is 1 bit and loop_current_iteration is 18*8 bits and current_loop_depth is 5 bits. 150 bits in and 2 bits out
      // maybe using single_loop.MIN_OF_CUR_ITERATION_AND_SUPERSCALAR will save LUTs with less recalculations
      copy_count <= is_top_of_stack_independent_loop
                    ? loop_current_iteration[(current_loop_depth-1)*BITS +: BITS] < (1 << SUPERSCALAR_LOG_WIDTH)
                      ? loop_current_iteration[(current_loop_depth-1)*BITS +: BITS] - 1 // loop_current_iteration
                      : (1 << SUPERSCALAR_LOG_WIDTH) - 1 // 4
                    : 0; // 1
    end
    if (should_increment) begin
      if (did_finish_loop) begin
        current_loop_depth <= current_loop_depth - 1;
        is_top_of_stack_independent_loop <= 0;
        did_change_loop_depth <= 1;
      end else if (should_create_new_loop) begin
        current_loop_depth <= current_loop_depth + 1;
        is_top_of_stack_independent_loop <= new_loop_is_inner_independent_loop;
        did_change_loop_depth <= 1;
      end else begin
        did_change_loop_depth <= 0;
      end
    end
  end

  assign done = loop_done[current_loop_depth-1];

endmodule

// it's really just an integer stack with the traditonal methods
// along with a decrement method which decrements the top value on the stack
// maybe reprogramming the verilog as a stack will save LUTs as the compiler can more clearly see what the logic is
// can use bram now instead of flip flops and LUT multiplexers