module alu (
  input clk,
  input [2:0] funct3,
  input [31:0] x,
  input [31:0] y,
  input alt,
  output reg [31:0] out
);
  always @(posedge clk) begin
    case (funct3) 
      3'b000: begin  // ADDI
        out <= alt ? (x - y) : (x + y);
      end
      3'b001: begin  // SLL
        out <= x << y[4:0];
      end
      3'b010: begin  // SLT
        out <= $signed(x) < $signed(y);
      end
      3'b011: begin  // SLTU
        out <= x < y;
      end
      3'b100: begin  // XOR
        out <= x ^ y;
      end
      3'b101: begin  // SRL
        out <= alt ? (x >>> y[4:0]) : (x >> y[4:0]);
      end
      3'b110: begin  // OR
        out <= x | y;
      end
      3'b111: begin  // AND
        out <= x & y;
      end
    endcase
  end
endmodule

module cond (
  input clk, 
  input [2:0] funct3,
  input [31:0] x,
  input [31:0] y,
  output reg out
);
  always @(posedge clk) begin
    case (funct3) 
      3'b000: begin  // BEQ
        out <= x == y;
      end
      3'b001: begin  // BNE
        out <= x != y;
      end
      3'b100: begin  // BLT
        out <= $signed(x) < $signed(y);
      end
      3'b101: begin  // BGE
        out <= $signed(x) >= $signed(y);
      end
      3'b110: begin  // BLTU
        out <= x < y;
      end
      3'b111: begin  // BGEU
        out <= x >= y;
      end
    endcase
  end
endmodule

// twitchcore is a low performance RISC-V processor
module twitchcore (
  input clk, resetn,
  output reg trap,
  output reg [31:0] pc,
  input [31:0] i_data,
  output [11:0] i_addr,
  input [31:0] d_data,
  output [11:0] d_addr
);

  reg [31:0] regs [0:31];
  reg [3:0] rd;

  wire [31:0] ins;
  reg [31:0] vs1;
  reg [31:0] vs2;
  reg [31:0] vpc;

  // Instruction decode and register fetch
  wire [6:0] opcode = ins[6:0];
  wire [2:0] funct3 = ins[14:12];
  wire [7:0] funct7 = ins[31:25];
  wire [31:0] imm_i = {{24{ins[31]}}, ins[31:20]};
  wire [31:0] imm_s = {{24{ins[31]}}, ins[31:25], ins[11:7]};
  wire [31:0] imm_b = {{23{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0};
  wire [31:0] imm_u = {ins[31:12], 12'b0};
  wire [31:0] imm_j = {{11{ins[31]}}, ins[31], ins[19:12], ins[20], ins[30:21], 1'b0};

  reg [31:0] alu_left;
  reg [2:0] alu_func;
  reg alu_alt;
  reg [31:0] imm;

  wire [31:0] pend;
  wire cond_out;
  reg [1:0] update_pc;  // 2'b00: don't update, 2'b01: update always, 2'b10: update cond
  reg reg_writeback;

  wire pend_is_new_pc = update_pc[0] || (update_pc[1] && cond_out);
  reg do_load;
  reg do_store;

  reg step_1;
  reg step_2;
  reg step_3;
  reg step_4;
  reg step_5;
  reg step_6;

  alu a (
    .clk (clk),
    .funct3 (alu_func),
    .x (alu_left),
    .y (imm),
    .alt (alu_alt),
    .out (pend)
  );

  cond c (
    .clk (clk),
    .funct3 (funct3),
    .x (vs1),
    .y (vs2),
    .out (cond_out)
  );

  assign i_addr = pc[13:2];
  assign ins = i_data;

  assign d_addr = pend[13:2];

  integer i;
  always @(posedge clk) begin
    if (resetn) begin
      pc <= 32'h80000000;
      for (i=0; i<32; i=i+1) regs[i] <= 0;
      step_1 <= 1'b1;
      step_2 <= 1'b0;
      step_3 <= 1'b0;
      step_4 <= 1'b0;
      step_5 <= 1'b0;
      step_6 <= 1'b0;
      trap <= 1'b0;
    end

    // *** Instruction Fetch ***
    step_2 <= step_1;
    // it sets ins here from rom_data

    // *** Instruction decode and register fetch ***
    step_3 <= step_2;
    vs1 <= regs[ins[19:15]];
    vs2 <= regs[ins[24:20]];
    vpc <= pc;
    rd <= ins[11:7];

    alu_func <= 3'b000;
    alu_left <= vs1;
    alu_alt <= 1'b0;
    update_pc <= 2'b00;
    reg_writeback <= 1'b0;
    do_load <= 1'b0;
    do_store <= 1'b0;
    case (opcode)
      7'b0110111: begin // LUI
        imm <= imm_u;
        alu_left <= 32'b0;
        reg_writeback <= 1'b1;
      end
      7'b0000011: begin // LOAD
        imm <= imm_i;
        reg_writeback <= 1'b1;
        do_load <= 1'b1;
        $display("LOAD");
      end
      7'b0100011: begin // STORE
        imm <= imm_s;
        do_store <= 1'b1;
      end

      7'b0010111: begin // AUIPC
        imm <= imm_u;
        alu_left <= pc;
        reg_writeback <= 1'b1;
      end
      7'b1100011: begin // BRANCH
        imm <= imm_b;
        alu_left <= pc;
        update_pc <= 2'b10;
      end
      7'b1101111: begin // JAL
        imm <= imm_j;
        alu_left <= pc;
        update_pc <= 2'b01;
        reg_writeback <= 1'b1;
      end
      7'b1100111: begin // JALR
        imm <= imm_i;
        update_pc <= 2'b01;
        reg_writeback <= 1'b1;
      end

      7'b0010011: begin // IMM
        imm <= imm_i;
        alu_func <= funct3;
        alu_alt <= (funct7 == 7'b0100000 && funct3 == 3'b101);
        reg_writeback <= 1'b1;
      end
      7'b0110011: begin // OP
        imm <= regs[ins[24:20]];
        alu_func <= funct3;
        alu_alt <= (funct7 == 7'b0100000);
        reg_writeback <= 1'b1;
      end
      7'b1110011: begin // SYSTEM
        trap <= regs[3] > 0;
      end
    endcase

    // *** Execute (happens above in arith and cond) ***
    step_4 <= step_3;
    // it sets pend and cond here

    // *** Memory access (later) ***
    step_5 <= step_4;
    // this sets d_data based on pend
    
    // *** Register Writeback ***
    step_6 <= step_5;
    if (step_6 == 1'b1) begin
      pc <= pend_is_new_pc ? pend : (vpc + 4);
      if (reg_writeback && rd != 4'b0000) begin
        if (do_load) begin
          case (funct3)
            3'b000: regs[rd] <= {{24{d_data[7]}}, d_data[7:0]};
            3'b001: regs[rd] <= {{16{d_data[15]}}, d_data[15:0]};
            3'b010: regs[rd] <= d_data;
            3'b100: regs[rd] <= {24'b0, d_data[7:0]};
            3'b101: regs[rd] <= {16'b0, d_data[15:0]};
          endcase
        end else begin
          regs[rd] <= (pend_is_new_pc ? (vpc + 4) : pend);
        end
      end
      step_1 <= 1'b1;
      step_2 <= 1'b0;
      step_3 <= 1'b0;
      step_4 <= 1'b0;
      step_5 <= 1'b0;
      step_6 <= 1'b0;
    end
  end

endmodule


