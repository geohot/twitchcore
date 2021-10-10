module decoder (
    input clk,
    input reset,
    input [0:17] raw_instruction,
    output decoded_memory_instruction memory_instruction,
    output decoded_processing_instruction processing_instruction,
    output decoded_loop_instruction loop_instruction,
    output reg[1:0] instruction_type // memory = 00, processing = 01, or loop = 10, or error = 11
);
  always @(posedge clk) begin
    if (reset) begin
      memory_instruction <= 0;
      processing_instruction <= 0;
      loop_instruction <= 0;
      instruction_type <= 0;
    end else begin
      if (raw_instruction[0:4] == 15 || raw_instruction[0:4] == 16) begin
        // MEMORY
        instruction_type <= 2'b00;
      end else if (raw_instruction[0:4] == 17 || raw_instruction[0:4] == 18 || raw_instruction[0:4] == 19) begin
        // LOOP
        instruction_type <= 2'b10;
      end else if (raw_instruction[0:4] >= 20) begin
        // ERROR
        instruction_type <= 2'b11;
      end else begin
        // PROCESSING
        instruction_type <= 2'b01;
      end

      case (raw_instruction[0:4])
        0 /* MATMUL */      : processing_instruction <= {13'b1000000000000, 5'b0};
        1 /* MULACC */      : processing_instruction <= {13'b0100000000000, 5'b0};
        2 /* ADD */         : processing_instruction <= {13'b0010000000000, 4'b0, 1'b1};
        3 /* SUB */         : processing_instruction <= {13'b0010000000000, 4'b0, 1'b0};
        4 /* MUL */         : processing_instruction <= {13'b0001000000000, 5'b0};
        5 /* DIV */         : processing_instruction <= {13'b0000100000000, 5'b0};
        6 /* POW */         : processing_instruction <= {13'b0000010000000, 5'b0};
        7 /* MAX */         : processing_instruction <= {13'b0000001000000, 4'b0, raw_instruction[5]};
        8 /* SUM */         : processing_instruction <= {13'b0000000100000, 5'b0, raw_instruction[5]};
        9 /* RELU */        : processing_instruction <= {13'b0000000010000, 4'b0, 1'b1};
        10 /* EXP */        : processing_instruction <= {13'b0000000001000, 4'b0};
        11 /* LOG */        : processing_instruction <= {13'b0000000000100, 4'b0};
        12 /* GTZ */        : processing_instruction <= {13'b0000000010000, 4'b0, 1'b0};
        13 /* COPY */       : processing_instruction <= {13'b0000000000010, raw_instruction[5:6], raw_instruction[7:8]};
        14 /* ZERO */       : processing_instruction <= {13'b0000000000001, raw_instruction[5:6], 2'b0};
        15 /* LOAD */       : memory_instruction <= {1'b1, raw_instruction[5:7], raw_instruction[8:9], raw_instruction[10:11], raw_instruction[12:13], raw_instruction[14], raw_instruction[15]};
        16 /* STORE */      : memory_instruction <= {1'b0, raw_instruction[5:7], raw_instruction[8:9], raw_instruction[10:11], raw_instruction[12:13], raw_instruction[14], raw_instruction[15]};
        17 /* START_INDEPENDENT_LOOP */ : loop_instruction <= {2'b00, raw_instruction[5:7]};
        18 /* START_LOOP */ :             loop_instruction <= {2'b01, raw_instruction[5:7]};
        19 /* JUMP_OR_END_LOOP */ :       loop_instruction <= {2'b11, raw_instruction[5:7]};
      endcase    
    end
  end

endmodule