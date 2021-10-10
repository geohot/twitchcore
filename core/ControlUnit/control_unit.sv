// You'll have a bad time changing ISA width for fun.
module control_unit#(parameter CHERRY_ISA_WIDTH=18, INSTRUCTION_ADDR_WIDTH=18, MEMORY_ADDRESS_BITS=15, LOG_APU_CNT=3, SUPERSCALAR_LOG_WIDTH=2, LOOP_LOG_CNT=3)(
  input clk,
  input reset,
  input [17:0] kernel_start_instruction,
  input [CHERRY_ISA_WIDTH-1:0] raw_instruction,
  output reg [(MEMORY_ADDRESS_BITS*3+15)*SUPERSCALAR_WIDTH+1:0] memory_instructions, //3*SUPERSCALAR_WIDTH integers and 1 bit to signal if instruction is load or store
  output decoded_processing_instruction processing_instructions,
  output reg [SUPERSCALAR_LOG_WIDTH-1:0] copy_count,
  output reg memory_instruction_we, processing_instruction_we,
  output reg [INSTRUCTION_ADDR_WIDTH-1:0] pc, // address of instruction we want to read next
  output reg error
);

parameter SUPERSCALAR_WIDTH = (1 << SUPERSCALAR_LOG_WIDTH);
parameter LOOP_CNT = (1 << LOOP_LOG_CNT);
parameter APU_CNT = (1 << LOG_APU_CNT);
enum {STATE_START, STATE_EXECUTE, STATE_STALL, STATE_FINISH} state;
reg [2:0] jump_amount;
wire [SUPERSCALAR_LOG_WIDTH-1:0] copy_count_wire;
wire error_wire;

// Loop Controller
reg [MEMORY_ADDRESS_BITS - 1:0] new_loop_iteration_count;
reg new_loop_is_inner_independent_loop;
reg should_create_new_loop;
reg did_start_next_loop_iteration;
reg did_finish_loop;
wire is_loop_done;
reg [LOG_APU_CNT-1:0] apu_selector;
wire [(LOOP_CNT+1)*MEMORY_ADDRESS_BITS*APU_CNT-1:0] new_address_formula, new_stride_x_formula, new_stride_y_formula; // TODO: set from memory
wire signed [MEMORY_ADDRESS_BITS-1:0] addr, stridex, stridey, daddr, dstridex, dstridey; // TODO: do stuff
loop loop (
  .clk(clk),
  .reset(state == 2'b00), // clear all state
  .should_increment(state != 2'b10), // active this cycle (could be stalled from full instruction queue)
  .new_loop_iteration_count(new_loop_iteration_count), // new loop instruction
  .new_loop_is_inner_independent_loop(new_loop_is_inner_independent_loop), // new loop instruction
  .should_create_new_loop(should_create_new_loop),
  .did_start_next_loop_iteration(did_start_next_loop_iteration),
  .did_finish_loop(did_finish_loop), //TODO: is this for end_loop_or_jump instruction?
  .done(is_loop_done), // is the most nested loop out of iterations
  .copy_count(copy_count_wire), // instead of 0, 1, 2, 3. it's 1, 2, 3, 4
  .apu_selector(apu_selector),
  .new_address_formula(new_address_formula),
  .new_stride_x_formula(new_stride_x_formula),
  .new_stride_y_formula(new_stride_y_formula),
  .addr(addr),
  .stridex(stridex),
  .stridey(stridey),
  .daddr(daddr),
  .dstridex(dstridex),
  .dstridey(dstridey)
);

// Decoder
wire decoded_memory_instruction memory_instruction;
wire decoded_processing_instruction processing_instruction;
wire decoded_loop_instruction loop_instruction;
wire [1:0] instruction_type;
decoder decoder(
  .clk(clk),
  .reset(reset),
  .raw_instruction(raw_instruction),
  .memory_instruction(memory_instruction), //TODO: send to APU
  .processing_instruction(processing_instruction),
  .loop_instruction(loop_instruction),
  .instruction_type(instruction_type)
);
always @(posedge clk) begin
  copy_count <= copy_count_wire;
  if (reset) begin
    state <= 2'b00;
  end
  case (state)
    STATE_START: begin
      state <= STATE_EXECUTE;
      // TODO: support starting new kernel using kernel_start_instruction
    end
    STATE_EXECUTE: begin
      state <= STATE_STALL;
      pc <= pc + 1 - jump_amount;
      case (instruction_type)
        2'b00: begin
          error <= 0;
          memory_instruction_we <= 1;
          processing_instruction_we <= 0;
          apu_selector <= memory_instruction.apu;
          memory_instructions <= {memory_instruction.is_load, memory_instruction.target, memory_instruction.height, memory_instruction.width, memory_instruction.zero_flag, memory_instruction.skip_flag, addr, stridex, stridey, daddr, dstridex, dstridey};
        end
        2'b01: begin
          error <= 0;
          memory_instruction_we <= 0;
          processing_instruction_we <= 1;
          processing_instructions <= processing_instruction;
        end
        2'b10: begin
          error <= 0;
          memory_instruction_we <= 0;
          processing_instruction_we <= 0;
          case (loop_instruction.loop_instr_type)
            LOOP_TYPE_START_INDEPENDENT : begin
              should_create_new_loop <= 1;
              new_loop_iteration_count <= loop_instruction[2:0]; // TODO: get from kcache
              new_loop_is_inner_independent_loop <= 1; // TODO: get from kcache
              did_start_next_loop_iteration <= 0;
              did_finish_loop <= 0;
            end
            LOOP_TYPE_START_SLOW : begin
              should_create_new_loop <= 1;
              new_loop_iteration_count <= loop_instruction[2:0];
              new_loop_is_inner_independent_loop <= 0;
              did_start_next_loop_iteration <= 0;
              did_finish_loop <= 0;
            end
            LOOP_TYPE_JUMP_OR_END : begin 
              should_create_new_loop <= 0;
              jump_amount = is_loop_done ? 0 : loop_instruction[2:0];
              did_start_next_loop_iteration <= !is_loop_done; // why is this set up here. for pipelining? can be in loop controller
              did_finish_loop <= is_loop_done;
            end
            // 2'b10 :
          endcase
        end
        2'b11: begin
          error <= 1;
          memory_instruction_we <= 0;
          processing_instruction_we <= 0;
        end
      endcase
    end
    STATE_STALL: begin
      state <= STATE_FINISH;
      // TODO: support stall
    end
    STATE_FINISH: begin
      state <= STATE_START;
      // TODO: support finishing kernel
    end
  endcase
  
  
end
endmodule