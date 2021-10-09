// You'll have a bad time changing ISA width for fun.
module control_unit#(parameter CHERRY_ISA_WIDTH=18, INSTRUCTION_ADDR_WIDTH=18)(
  input clk,
  input reset,
  input [17:0] kernel_start_instruction,
  input [CHERRY_ISA_WIDTH-1:0] raw_instruction,
  output reg [16*4-1:0] memory_instructions,
  output reg [16*4-1:0] processing_instructions,
  output reg [2*4-1:0] apu_instructions,
  output reg [1:0] memory_instructions_count, processing_instructions_count, apu_instructions_count,
  output reg memory_instruction_we, processing_instruction_we, apu_instruction_we,
  output reg [INSTRUCTION_ADDR_WIDTH-1:0] pc, // address of instruction we want to read next
  output reg error
);
// TODO: instantiate loop controller
wire [15:0] memory_instruction, processing_instruction;
wire [2:0] loop_instruction;
wire [1:0] instruction_type;
decoder decoder(
  .clk(clk),
  .reset(reset),
  .raw_instruction(raw_instruction),
  .memory_instruction(memory_instruction),
  .processing_instruction(processing_instruction),
  .loop_instruction(loop_instruction),
  .instruction_type(instruction_type),
  .error(error)
);
// TODO: broadcast loop controller's apu outputs to the queue. Send copycount to queue as well. no logic
// TODO: broadcast instruction to the queue, send copycount to queue as well. no logic
always @(posedge clk) begin
  pc <= pc + 1; // TODO: support jump from decoder if on end_loop_or_jump instruction and loop controller says inner loop not done
  
  case (instruction_type)
    2'b00: begin
      memory_instructions[0 +: 16] <= memory_instruction;
      memory_instructions_count <= 2'b00; // 1
      memory_instruction_we <= 1;
      processing_instruction_we <= 0;
      apu_instruction_we <= 0;
    end
    2'b01: begin
      processing_instructions[0 +: 16] <= processing_instruction;
      processing_instructions_count <= 2'b00; // 1
      memory_instruction_we <= 0;
      processing_instruction_we <= 1;
      apu_instruction_we <= 0;
    end
    2'b10: begin
      apu_instructions[0 +: 3] <= loop_instruction;
      apu_instructions_count <= 2'b00;
      memory_instruction_we <= 0;
      processing_instruction_we <= 0;
      apu_instruction_we <= 1;
    end
    // 2'b11: begin
    // end
  endcase
  
  
end
endmodule