module arith (
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
  input clk, resetn
);
  reg [31:0] rom [0:4095];
  initial $readmemh("test-cache/rv32ui-p-add", rom);

  reg [31:0] regs [0:31];
  reg [31:0] pc;
  reg [3:0] rd;

  reg [31:0] ins;
  reg [31:0] vs1;
  reg [31:0] vs2;
  reg [31:0] vpc;

  // Instruction decode and register fetch
  wire [6:0] opcode = ins[6:0];
  wire [2:0] funct3 = ins[14:12];
  wire [7:0] funct7 = ins[31:25];
  wire [31:0] imm_i = {{24{ins[31]}}, ins[31:20]};
  wire [31:0] imm_s = {{24{ins[31]}}, ins[31:25], ins[11:7]};
  wire [31:0] imm_b = {{23{ins[31]}}, ins[31:30], ins[8:7], ins[30:25], ins[11:8], 1'b0};
  wire [31:0] imm_u = {ins[31:12], 12'b0};
  wire [31:0] imm_j = {{11{ins[31]}}, ins[19:12], ins[21:20], ins[30:21], 1'b0};

  reg [31:0] arith_left;
  reg [2:0] arith_func;
  reg arith_alt;
  reg [31:0] imm;

  wire [31:0] pend;
  wire pend_is_new_pc_cond;
  reg pend_is_new_pc;
  reg reg_writeback;

  reg step_1;
  reg step_2;
  reg step_3;
  reg step_4;
  reg step_5;

  arith a (
    .clk (clk),
    .funct3 (arith_func),
    .x (arith_left),
    .y (imm),
    .alt (arith_alt),
    .out (pend)
  );

  cond c (
    .clk (clk),
    .funct3 (funct3),
    .x (vs1),
    .y (vs2),
    .out (pend_is_new_pc_cond)
  );

  //$dumpfile("test.vcd");
  integer i;
  always @(negedge resetn) begin
    pc <= 32'h80000000;
    for (i=0; i<32; i=i+1) regs[i] <= 0;
    step_1 <= 1'b1;
    step_2 <= 1'b0;
    step_3 <= 1'b0;
    step_4 <= 1'b0;
    step_5 <= 1'b0;
  end

  always @(posedge clk) begin
    // *** Instruction Fetch ***
    step_2 <= step_1;
    ins <= rom[pc[30:2]];

    // *** Instruction decode and register fetch ***
    step_3 <= step_2;
    vs1 <= regs[ins[19:15]];
    vs2 <= regs[ins[24:20]];
    vpc <= pc;
    rd <= ins[11:7];

    arith_func <= 3'b000;
    arith_left <= vs1;
    arith_alt <= 1'b0;
    pend_is_new_pc <= 1'b0;
    reg_writeback <= 1'b0;
    case (opcode)
      7'b0110111: begin // LUI
        imm <= imm_u;
        reg_writeback <= 1'b1;
      end
      7'b0000011: begin // LOAD
        imm <= imm_i;
        reg_writeback <= 1'b1;
      end
      7'b0100011: begin // STORE
        imm <= imm_s;
      end

      7'b0010111: begin // AUIPC
        imm <= imm_u;
        arith_left <= pc;
        reg_writeback <= 1'b1;
      end
      7'b1100011: begin // BRANCH
        imm <= imm_b;
        arith_left <= pc;
        pend_is_new_pc <= pend_is_new_pc_cond;
      end
      7'b1101111: begin // JAL
        imm <= imm_j;
        arith_left <= pc;
        pend_is_new_pc <= 1'b1;
        reg_writeback <= 1'b1;
      end
      7'b1100111: begin // JALR
        imm <= imm_i;
        pend_is_new_pc <= 1'b1;
        reg_writeback <= 1'b1;
      end

      7'b0010011: begin // IMM
        imm <= imm_i;
        arith_func <= funct3;
        arith_alt <= (funct7 == 7'b0100000 && funct3 == 3'b101);
        reg_writeback <= 1'b1;
      end
      7'b0110011: begin // OP
        imm <= regs[ins[24:20]];
        arith_func <= funct3;
        arith_alt <= (funct7 == 7'b0100000);
        reg_writeback <= 1'b1;
      end
    endcase

    // *** Execute (happens above) ***
    step_4 <= step_3;

    // *** Memory access (later) ***
    step_5 <= step_4;
  end

  // *** Register Writeback ***
  always @(posedge step_5) begin
    $display("asd %h %d pc:%h -- opcode:%h -- func:%h left:%h imm:%h pend:%h", ins, resetn, pc, opcode, arith_func, arith_left, imm, pend);
    pc <= pend_is_new_pc ? pend : (vpc + 4);
    regs[rd] <= (reg_writeback && rd != 4'b0000) ? (pend_is_new_pc ? (vpc + 4) : pend) : regs[rd];
    step_1 <= 1'b1;
    step_2 <= 1'b0;
    step_3 <= 1'b0;
    step_4 <= 1'b0;
    step_5 <= 1'b0;
  end

endmodule

module testbench;
	reg clk;
  reg resetn;
  reg [7:0] cnt;

	initial begin
		clk = 0;
    cnt = 0;
    resetn = 1;
		$display("doing work", cnt);
	end

  always
    #5 clk = !clk;

  always @(posedge clk) begin
    cnt <= cnt + 1;
    resetn <= 0;
  end

  twitchcore c (
    .clk (clk),
    .resetn (resetn)
  );

  initial begin
    #10000
    $display("no more work ", cnt);
    $finish;
  end
endmodule


