typedef struct packed {
	reg is_load; // 1 for load, 0 for store
  reg [2:0] apu;
  reg [1:0] target;
  reg [1:0] height, width;
  reg zero_flag; // only used for load
  reg skip_flag;
} decoded_memory_instruction;

typedef struct packed {
  reg [1:0] loop_instr_type; // 00 for start_independent, 01 for start_slow, 11 for jump_or_end_loop
  reg [2:0] loop_address;
} decoded_loop_instruction;

typedef struct packed {
  reg [12:0] one_hot_enable; // one hot encoded for which alu (matmul, mulacc, binop, etc) to activate
  reg [1:0] target; // not all processing instructions use this. See ISA
  reg [1:0] source;
  reg is_default; // 1 for relu, 0 for gt0. 1 for add. 0 for sub. 1 for max accumulate. 0 for max nonaccumulate. 1 for sum accumulate. 0 for sum nonaccumulate
} decoded_processing_instruction;