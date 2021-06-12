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

  always @(posedge clk) begin
    if (c.step_6 == 1'b1) begin
      $display("asd %h %d pc:%h -- opcode:%b -- func:%h alt:%d left:%h imm:%h pend:%h d_addr:%h d_data:%h trap:%d",
        c.ins, c.resetn, c.pc, c.opcode, c.alu_func, c.alu_alt, c.alu_left, c.alu_imm, c.pend, c.d_addr, c.d_data, c.trap);
    end
  end

  always @(posedge trap) begin
    $display("TRAP", c.regs[3]);
    $finish;
  end

  initial begin
    #50000
    $display("no more work ", cnt);
    $finish;
  end
endmodule

