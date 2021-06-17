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
  reg [15:0] ctr;
  always @(posedge clk) {clkdiv, ctr} <= ctr + 1'b1;

  wire [31:0] pc;
  twitchcore tc (
    .clk (clkdiv),
    .resetn (sw[0]),
    .trap (led[0]),
    .pc (pc)
  );

  // display pc
  assign led[3:1] = pc[2:0];
  assign led[7:5] = pc[5:3];
  assign led[11:9] = pc[8:6];
endmodule

