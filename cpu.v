module arith (
  input clk,
  input [3:0] funct3,
  input [31:0] x,
  input [31:0] y,
  input alt,
  output [31:0] wout
);
  reg [31:0] out;
  assign wout = out;
  always @(posedge clk) begin
    case (funct3) 
      3'b000: begin  // ADDI
        out <= x + y;
      end
      3'b001: begin  // SLL
        out <= x << y[4:0];
      end
      3'b010: begin  // SLT
      end
      3'b011: begin  // SLTU
      end
      3'b100: begin  // XOR
        out <= x ^ y;
      end
      3'b101: begin  // SRL
        out <= x >> y[4:0];
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

// candy is a low performance RISC-V processor
module candy (
  input clk, resetn
);
  reg [31:0] rom [0:4095];
  initial $readmemh("test-cache/rv32ui-p-add", rom);

  reg [31:0] regs [0:31];
  reg [31:0] pc;

  reg [31:0] ins;
  reg [31:0] vs1;
  reg [31:0] vs2;

  // Instruction decode and register fetch
  wire [6:0] opcode = ins[6:0];
  wire [2:0] funct3 = ins[14:12];
  wire [7:0] funct7 = ins[31:25];
  wire [31:0] imm_i = {{24{ins[31]}}, ins[31:20]};
  wire [31:0] imm_s = {{24{ins[31]}}, ins[31:25], ins[11:7]};
  wire [31:0] imm_b = {{23{ins[31]}}, ins[31:30], ins[8:7], ins[30:25], ins[11:8], 1'b0};
  wire [31:0] imm_u = {ins[31:12], 12'b0};
  wire [31:0] imm_j = {{11{ins[31]}}, ins[19:12], ins[21:20], ins[30:21]};

  reg [31:0] arith_left;
  reg [2:0] arith_func;
  reg [31:0] imm;

  //$dumpfile("test.vcd");
  always @(posedge clk) begin
    if (resetn) pc <= 32'h80000000;

    // Instruction Fetch
    ins <= rom[pc[30:0]];

    // Instruction decode and register fetch
    vs1 <= regs[ins[19:15]];
    vs2 <= regs[ins[24:20]];

    // Execute
    arith_func <= 3'b000;
    arith_left <= vs1;
    case (opcode)
      7'b0110111: begin // LUI
        imm <= imm_u;
      end
      7'b0000011: begin // LOAD
        imm <= imm_i;
      end
      7'b0100011: begin // STORE
        imm <= imm_s;
      end

      7'b0010111: begin // AUIPC
        imm <= imm_u;
        arith_left <= pc;
      end
      7'b1100011: begin // BRANCH
        imm <= imm_b;
        arith_left <= pc;
      end
      7'b1101111: begin // JAL
        imm <= imm_j;
        arith_left <= pc;
      end
      7'b1100111: begin // JALR
        imm <= imm_i;
      end

      7'b0010011: begin // IMM
        imm <= imm_i;
        arith_func <= funct3;
      end
      7'b0110011: begin // OP
        imm <= vs2;
        arith_func <= funct3;
      end
    endcase


    $display("asd %h %d pc:%h -- %h -- %h %h %h", ins, resetn, pc, opcode, arith_func, arith_left, imm);
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

  candy c (
    .clk (clk),
    .resetn (resetn)
  );

  initial begin
    #100
    $display("no more work", cnt);
    $finish;
  end
endmodule


