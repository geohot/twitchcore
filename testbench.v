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

  reg [31:0] mem [0:4095];
  initial $readmemh("test-cache/rv32ui-p-lw", mem);

  wire [11:0] i_addr;
  reg [31:0] i_data;
  wire [11:0] d_addr;
  reg [31:0] d_data;

  twitchcore c (
    .clk (clk),
    .resetn (resetn),
    .trap (trap),
    .i_data (i_data),
    .i_addr (i_addr),
    .d_data (d_data),
    .d_addr (d_addr)
  );

  always @(posedge clk) begin
    i_data <= mem[i_addr];
    d_data <= mem[d_addr];
    if (c.step_6 == 1'b1) begin
      $display("asd %h %d pc:%h -- opcode:%b -- func:%h alt:%d left:%h imm:%h pend:%h d_addr:%h d_data:%h trap:%d",
        c.ins, c.resetn, c.pc, c.opcode, c.alu_func, c.alu_alt, c.alu_left, c.imm, c.pend, c.d_addr, c.d_data, c.trap);
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

