module testbench;
	reg clk;
  reg [7:0] cnt;

	initial begin
		$display("doing work");
    clk = 0;
    cnt = 0;
	end

  always
    #5 clk = !clk;


  initial begin
    #100
    $finish;
  end

  reg [2:0] risk_func;
  reg [4:0] risk_reg;
  reg [16:0] risk_addr;
  reg [14:0] risk_stride_x;
  reg [14:0] risk_stride_y;
  wire [287:0] risk_reg_view;
  risk ri (
    .clk (clk),
    .risk_func (risk_func),
    .risk_reg (risk_reg),
    .risk_addr (risk_addr),
    .risk_stride_x (risk_stride_x),
    .risk_stride_y (risk_stride_y),
    .reg_view (risk_reg_view)
  );

  initial begin
    risk_func = 3'b000;
    risk_reg = 5'b00000;
    risk_addr = 34;
    risk_stride_x = 3;
    risk_stride_y = 3;
  end

  always @(posedge clk) begin
    cnt <= cnt + 1;
    $display("%d %x %x", cnt, risk_reg_view, ri.rm.addrs);
  end

endmodule
