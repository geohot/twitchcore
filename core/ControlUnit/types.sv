typedef enum {LOOP_TYPE_START_INDEPENDENT, LOOP_TYPE_START_SLOW, LOOP_TYPE_JUMP_OR_END} e_loop_instr_type;

typedef enum {INSTR_TYPE_MEMORY, INSTR_TYPE_PROCESSING, INSTR_TYPE_LOOP, INSTR_TYPE_ERROR} e_instr_type;

typedef struct packed {
  reg is_load; // 1 for load, 0 for store
  reg [1:0] target;
  reg [1:0] height, width;
  reg zero_flag; // only used for load
  reg skip_flag;
} memory_unit_control_signals;

typedef struct packed {
  reg [2:0] apu;
  memory_unit_control_signals control;
} decoded_memory_instruction;

typedef struct packed {
  e_loop_instr_type loop_instr_type; // 00 for start_independent, 01 for start_slow, 11 for jump_or_end_loop
  reg [2:0] loop_address;
} decoded_loop_instruction;

typedef struct packed {
  reg [12:0] one_hot_enable; // one hot encoded for which alu (matmul, mulacc, binop, etc) to activate
  reg [1:0] target; // not all processing instructions use this. See ISA
  reg [1:0] source;
  reg is_default; // 1 for relu, 0 for gt0. 1 for add. 0 for sub. 1 for max accumulate. 0 for max nonaccumulate. 1 for sum accumulate. 0 for sum nonaccumulate
} decoded_processing_instruction;

parameter BITS=18;
parameter APU_CNT=8;
parameter LOOP_CNT=8;
typedef struct packed {
  reg [BITS-1:0] iteration_count;
  reg is_inner_independent_loop;
} loop_controller_new_loop;

typedef struct packed {
  reg [BITS-1:0] iteration_count;
  reg [BITS-1:0] jump_amount;
} loop_controller_end_loop;

typedef struct packed {
  reg [(LOOP_CNT+1)*BITS*APU_CNT-1:0] address;
  reg [(LOOP_CNT+1)*BITS*APU_CNT-1:0] stride_x;
  reg [(LOOP_CNT+1)*BITS*APU_CNT-1:0] stride_y;
} apu_formulas;

typedef struct packed {
  reg signed [BITS-1:0] addr;
  reg signed [BITS-1:0] stridex;
  reg signed [BITS-1:0] stridey;
  reg signed [BITS-1:0] daddr;
  reg signed [BITS-1:0] dstridex;
  reg signed [BITS-1:0] dstridey;
} apu_output;


typedef struct packed {
  apu_output apu_values;
  memory_unit_control_signals params;
} queue_memory_instruction;