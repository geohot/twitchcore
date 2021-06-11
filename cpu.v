module decode (
  input [31:0] ins,
  output [6:0] opcode
);
	assign opcode = ins[6:0];
  
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

  // Instruction decode and register fetch
  wire [6:0] opcode = ins[6:0];
  wire [2:0] funct3 = ins[14:12];
  wire [7:0] funct7 = ins[31:25];
  wire [31:0] imm_i = {{24{ins[31]}}, ins[31:20]};
  wire [31:0] imm_s = {{24{ins[31]}}, ins[31:25], ins[11:7]};
  wire [31:0] imm_b = {{23{ins[31]}}, ins[31:30], ins[8:7], ins[30:25], ins[11:8], 1'b0};
  wire [31:0] imm_u = {ins[31:12], 12'b0};
  wire [31:0] imm_j = {{11{ins[31]}}, ins[19:12], ins[21:20], ins[30:21]};

  //$dumpfile("test.vcd");
  always @(posedge clk) begin
    if (resetn) pc <= 0;

    // Instruction Fetch
    ins <= rom[pc];



    $display("asd %h %d %h", ins, resetn, pc);
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


