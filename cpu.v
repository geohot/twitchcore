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


