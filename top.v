module top (
  input clk_i,
  input [3:0] sw, 
  output [11:0] led,
);
	reg clk50 = 1'b0;
	always @(posedge clk_i)
			clk50 <= ~clk50;

	wire clk;
	BUFGCTRL bufg_i (
			.I0(clk50),
			.CE0(1'b1),
			.S0(1'b1),
			.O(clk)
	);  

  reg clkdiv;
  reg [22:0] ctr;
  always @(posedge clk) {clkdiv, ctr} <= ctr + 1'b1;

  wire [31:0] pc;
  twitchcore tc (
    .clk (clkdiv),
    .resetn (sw[0]),
    .trap (led[0]),
    .pc (pc)
  );

  // display pc
  assign led[11:1] = pc[10:0];
endmodule

