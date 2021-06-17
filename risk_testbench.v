module risk #(parameter SZ=4, LOGCNT=5, BITS=18) (
  input clk,
  input [2:0] risk_func,
  input [4:0] risk_reg,
  input [10+LOGCNT-1:0] risk_addr,
  input [10+LOGCNT-2:0] risk_stride_x,
  input [10+LOGCNT-2:0] risk_stride_y,
  output [BITS*SZ*SZ-1:0] reg_view
);
  parameter REGSIZE = BITS*SZ*SZ;

  wire [REGSIZE-1:0] dat_r;
  reg [REGSIZE-1:0] dat_w;
  reg we;
  risk_mem #(SZ, LOGCNT, BITS) rm(
    .clk(clk),
    .addr(risk_addr),
    .stride_x(risk_stride_x),
    .stride_y(risk_stride_y),
    .we(we),
    .dat_r(dat_r),
    .dat_w(dat_w)
  );

  reg [REGSIZE-1:0] regs [0:2];
  assign reg_view = regs[0];
  always @(posedge clk) begin
    we <= 1'b0;
    case (risk_func)
      // load
      3'b000: regs[risk_reg] <= dat_r;
      // store
      3'b001: begin
        dat_w <= regs[risk_reg];
        we <= 1'b1;
      end
      3'b010: regs[risk_reg] <= 'b0;
    endcase
  end
endmodule

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
    risk_stride_y = 1;
    #20
    risk_func = 3'b001;
    #20
    risk_func = 3'b000;
  end

  always @(posedge clk) begin
    cnt <= cnt + 1;
    $display("%d %x -- %x %x %x %x", cnt, risk_reg_view,
      ri.rm.addrs[3*(LOGCNT+10) +: (LOGCNT+10)],
      ri.rm.addrs[2*(LOGCNT+10) +: (LOGCNT+10)],
      ri.rm.addrs[1*(LOGCNT+10) +: (LOGCNT+10)],
      ri.rm.addrs[0*(LOGCNT+10) +: (LOGCNT+10)]);
  end

endmodule

