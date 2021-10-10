module decoder (
    input clk,
    input reset,
    input [17:0] raw_instruction,
    output reg[15:0] memory_instruction,
    output reg[15:0] processing_instruction,
    output reg[4:0] loop_instruction,
    output reg[1:0] instruction_type, // memory = 00, processing = 01, or loop = 10
    output reg error
);
  always @(posedge clk) begin
    if (reset) begin
      memory_instruction <= 0;
      processing_instruction <= 0;
      loop_instruction <= 0;
      instruction_type <= 0;
      error <= 0;
    end else begin
      case (raw_instruction[17:13])
        15 /* LOAD */        : instruction_type <= 2'b00;
        16 /* STORE */       : instruction_type <= 2'b00;
        17 /* START_LOOP */  : instruction_type <= 2'b10;
        default     : instruction_type <= 2'b01;
      endcase

      case (raw_instruction[17:13])
        0 /* MATMUL */      : processing_instruction <= {12'b100000000000, 4'b0};
        1 /* MULACC */      : processing_instruction <= {12'b010000000000, 4'b0};
        2 /* ADD */         : processing_instruction <= {12'b001000000000, 4'b0};
        3 /* SUB */         : processing_instruction <= {12'b001000000000, 4'b0};
        4 /* MUL */         : processing_instruction <= {12'b010000000000, raw_instruction[12], 3'b0};
        5 /* DIV */         : processing_instruction <= {12'b000100000000, 4'b0};
        6 /* POW */         : processing_instruction <= {12'b000010000000, 4'b0};
        7 /* MAX */         : processing_instruction <= {12'b000001000000, raw_instruction[12], 3'b0};
        8 /* SUM */         : processing_instruction <= {12'b000000100000, raw_instruction[12], 3'b0};
        9 /* RELU */        : processing_instruction <= {12'b000000010000, 4'b0};
        10 /* EXP */        : processing_instruction <= {12'b000000001000, 4'b0};
        11 /* LOG */        : processing_instruction <= {12'b000000000100, 4'b0};
        12 /* GTZ */        : processing_instruction <= {12'b000000010000, 4'b0};
        13 /* COPY */       : processing_instruction <= {12'b000000000010, raw_instruction[12:11], raw_instruction[10:9]};
        14 /* ZERO */       : processing_instruction <= {12'b000000000001, raw_instruction[12:11], 2'b0};
        // on or off, load or store, apu (0 through 15), reg used for load instructions, height, width, 0 flag used for load, skip flag used for load, reg used for store instruction
        15 /* LOAD */       : memory_instruction <= {1'b1, 1'b0, raw_instruction[12:9], raw_instruction[8:7], raw_instruction[6:5], raw_instruction[4:3], raw_instruction[2], raw_instruction[1], 2'b00};
        16 /* STORE */      : memory_instruction <= {1'b1, 1'b1, raw_instruction[12:9], 2'b00, raw_instruction[6:5], raw_instruction[4:3], 1'b0, 1'b0, raw_instruction[8:7]};
        17 /* START_INDEPENDENT_LOOP */ : loop_instruction <= {2'b00, raw_instruction[12:10]};
        18 /* START_LOOP */ : loop_instruction <= {2'b01, raw_instruction[12:10]};
        19 /* JUMP_OR_END_LOOP */ : loop_instruction <= {2'b11, raw_instruction[12:10]};
        // TODO: add end loop instruction
        default             : error <= 1;
      endcase    
    end
  end

endmodule