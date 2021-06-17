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
    #140
    $finish;
  end

  parameter SZ = 4;
  parameter LOGCNT = 5;
  parameter BITS = 18;

  reg [2:0] risk_func;
  reg [4:0] risk_reg;
  reg [10+LOGCNT-1:0] risk_addr;
  reg [10+LOGCNT-2:0] risk_stride_x;
  reg [10+LOGCNT-2:0] risk_stride_y;
  wire [BITS*SZ*SZ-1:0] risk_reg_view;

  risk #(SZ, LOGCNT, BITS) ri (
    .clk (clk),
    .risk_func (risk_func),
    .risk_reg (risk_reg),
    .risk_addr (risk_addr),
    .risk_stride_x (risk_stride_x),
    .risk_stride_y (risk_stride_y),
    .reg_view (risk_reg_view)
  );

  initial begin
    risk_func = 3'b010;
    risk_reg = 5'b00000;
    risk_addr = 0;
    risk_stride_x = 1;
    risk_stride_y = 4;
    #20
    risk_func = 3'b001;
    #20
    risk_func = 3'b000;
  end

  always @(posedge clk) begin
    cnt <= cnt + 1;
    $display("%d %x -- %x", cnt, risk_reg_view, ri.rm.addrs);
    //$display("%x", ri.rm.ens);
    //$display("%x", ri.rm.ens);
  end

endmodule
