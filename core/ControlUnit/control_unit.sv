// Low performance single stage CPU. Generates instructions for the actual cherry core.
// When combined with a BRAM kcache. Reading from BRAM and doing all of cpu module's combinatorial logic gets clock rate almost 60MHz.
// 2903 LUT total. 998 for APU. 1821 for Loop controller. Each individual loop is about 100 LUT.
// It will 3x when we go to big cherry 1. On small its 4%, on big it's 1%.
module cpu#(parameter LOG_KCACHE_SIZE=11, MEMORY_ADDRESS_BITS=15, LOG_APU_CNT=3, SUPERSCALAR_LOG_WIDTH=2, LOOP_LOG_CNT=3)(
  input clk,
  input reset,
  input [16:0] kernel_start_address,
  input [0:17] raw_instruction,
  input raw_instruction_fetch_successful,
  input queue_almost_full,
  input apu_formulas apu_formulas_ro_data,
  input wire [0:BITS*2*8-1] loop_ro_data,
  output queue_memory_instruction queue_memory_instructions,
  output decoded_processing_instruction queue_processing_instructions,
  output wire [SUPERSCALAR_LOG_WIDTH-1:0] copy_count,
  output reg memory_instruction_we, processing_instruction_we,
  output reg [LOG_KCACHE_SIZE-1:0] pc, // address of instruction we want to read next
  output reg error
);
assign queue_memory_instructions = {apu_output_wire, memory_instruction.control};
assign queue_processing_instructions = processing_instruction;
parameter SUPERSCALAR_WIDTH = (1 << SUPERSCALAR_LOG_WIDTH);
parameter LOOP_CNT = (1 << LOOP_LOG_CNT);
parameter APU_CNT = (1 << LOG_APU_CNT);
enum {STATE_START, STATE_EXECUTE, STATE_STALL, STATE_FINISH} state;
wire error_wire;

// Loop Controller
reg [MEMORY_ADDRESS_BITS - 1:0] new_loop_iteration_count;
reg new_loop_is_inner_independent_loop;
reg should_create_new_loop;
reg did_start_next_loop_iteration;
reg did_finish_loop;
wire is_loop_done;
wire loop_reset, loop_enable, loop_is_start_loop;
assign loop_reset = state == STATE_START;
assign loop_enable = instruction_type == INSTR_TYPE_LOOP && state != STATE_STALL;
assign loop_is_start_loop = loop_instruction.loop_instr_type !== LOOP_TYPE_JUMP_OR_END;
wire [LOOP_LOG_CNT-1:0] current_loop_depth;
wire [BITS-1:0] apu_di;
loop loop (
  .clk,
  .reset(loop_reset), // clear all state
  .enable(loop_enable),
  .new_loop(loop_controller_new_loop_wire),
  .end_loop_or_jump(loop_controller_end_loop_wire),
  .is_start_loop(loop_is_start_loop),
  .current_loop_done(is_loop_done),
  .copy_count(copy_count), // instead of 0, 1, 2, 3. it's 1, 2, 3, 4
  .current_loop_depth_out(current_loop_depth),
  .current_loop_cur_di(apu_di)
);

loop_controller_new_loop loop_controller_new_loop_wire;
loop_controller_end_loop loop_controller_end_loop_wire;
wire loop_mux_independent;
assign loop_mux_independent = loop_instruction.loop_instr_type == LOOP_TYPE_START_INDEPENDENT ? 1'b1 : 1'b0;
loopmux #(BITS) loopmux (
    .addr         (loop_instruction.loop_address),
    .in           (loop_ro_data),
    .independent  (loop_mux_independent),
    .new_loop     (loop_controller_new_loop_wire),
    .end_loop     (loop_controller_end_loop_wire)
);

// APU

wire [LOG_APU_CNT-1:0] apu_selector;
assign apu_selector = memory_instruction.apu;
apu_output apu_output_wire;
apu #(BITS, LOOP_LOG_CNT, LOG_APU_CNT) apu(
    .clk(clk),
    .reset(loop_reset),
    .enable(loop_enable),
    .current_loop_done(is_loop_done),
    .is_starting_new_loop(loop_is_start_loop),
    .iteration_count(loop_controller_end_loop_wire.iteration_count),
    .loop_var(current_loop_depth), 
    .loop_di(apu_di),
    .apu_selector(apu_selector),
    .formulas(apu_formulas_ro_data),
    .apu_out(apu_output_wire)
  );

// Decoder

wire decoded_memory_instruction memory_instruction;
wire decoded_processing_instruction processing_instruction;
decoded_loop_instruction loop_instruction;
e_instr_type instruction_type;
decoder decoder(
  .raw_instruction(raw_instruction),
  .memory_instruction(memory_instruction),
  .processing_instruction(processing_instruction),
  .loop_instruction(loop_instruction),
  .instruction_type(instruction_type),
  .error(error_wire)
);


always @(posedge clk) begin
  case (state)
    STATE_START: begin
      state <= kernel_start_address ? STATE_EXECUTE : STATE_START;
      pc <= kernel_start_address;
    end
    STATE_EXECUTE: begin
      state <= raw_instruction_fetch_successful
               ? queue_almost_full
                  ? STATE_STALL
                  : STATE_EXECUTE
               : STATE_FINISH; // tell queue to not read
      pc <= pc + 1
            - (!is_loop_done
              && loop_instruction.loop_instr_type == LOOP_TYPE_JUMP_OR_END
                ? loop_controller_end_loop_wire.jump_amount
                : 0);
      memory_instruction_we <= instruction_type == INSTR_TYPE_MEMORY;
      processing_instruction_we <= instruction_type == INSTR_TYPE_PROCESSING;
    end
    STATE_STALL: begin
      state <= queue_almost_full
                ? STATE_STALL
                : STATE_EXECUTE;
    end
    STATE_FINISH: begin
      state <= STATE_START;
    end
  endcase
  if (reset) begin
    state <= STATE_START;
    error <= 0;
  end else if (error_wire && state != STATE_START) begin
    error <= 1;
  end

  
end
endmodule