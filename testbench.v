module testbench;
	reg clk;
  reg resetn;
  wire trap;
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
    .resetn (resetn),
    .trap (trap)
  );

  always @(posedge c.step_5) begin
    $display("asd %h %d pc:%h -- opcode:%b -- func:%h alt:%d left:%h imm:%h pend:%h pend_is_new_pc:%d trap:%d",
      c.ins, c.resetn, c.pc, c.opcode, c.arith_func, c.arith_alt, c.arith_left, c.imm, c.pend, c.pend_is_new_pc, c.trap);
  end

  always @(posedge trap) begin
    $display("TRAP", c.regs[3]);
    $finish;
  end

  initial begin
    #21000
    $display("no more work ", cnt);
    $finish;
  end
endmodule

