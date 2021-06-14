// RISK extensions
// 4x4 registers
// we have 270 18-bit rams, need this instead of 19. depth is 1024
// let's make 128 BRAMs, that's 256 elements of read bandwidth
// this is also the size of ECC
// use a 9 bit mantissa (cherryfloat)

module risk_single_mem (
  input clk,
  input [9:0] addr_r,
  output [17:0] data_r,
  input [9:0] addr_w,
  input [17:0] data_w,
  input we
);
  // this is 1 18k BRAM
  reg [17:0] mem [0:1023];
  assign data_r = mem[addr_r];
  always @(posedge clk) begin
    mem[addr_w] <= data_w;
  end
endmodule

// this is hard to synthesize
module risk_mem (
  input clk,
  input [16:0] addr,
  input [15:0] stride_x,
  input [15:0] stride_y,
  input [287:0] dat_w,
  input we,
  output reg [287:0] dat_r
);
  // 1 cycle to get all the addresses
  reg [16:0] addrs [0:15];

  generate
    genvar x,y;
    for (y=0; y<4; y=y+1) begin
      for (x=0; x<4; x=x+1) begin
        always @(posedge clk) begin
          addrs[y*4+x] <= addr + stride_x*x + stride_y*y;
        end
      end
    end
  endgenerate

  generate
    genvar i;
    for (i=0; i<16; i=i+1) begin
      wire [17:0] out;
      wire [17:0] in = dat_w[(i*18)+17:(i*18)];

      risk_single_mem rsm(
        .clk(clk),
        .addr_r(addrs[i]),
        .data_r(out),
        .addr_w(addrs[i]),
        .data_w(in),
        .we(we)
      );

      always @(posedge clk) begin
        dat_r[(i*18)+17:(i*18)] <= out;
      end
    end
  endgenerate
endmodule


module risk_alu (
  input clk
);

endmodule

module risk (
  input clk,
  input [2:0] risk_func,
  input [4:0] risk_reg,
  input [16:0] risk_addr,
  input [15:0] risk_stride_x,
  input [15:0] risk_stride_y,
  output [287:0] reg_view
);
  wire [287:0] dat_r;
  reg [287:0] dat_w;
  reg we;
  risk_mem rm(
    .clk(clk),
    .addr(risk_addr),
    .stride_x(risk_stride_x),
    .stride_y(risk_stride_y),
    .we(we),
    .dat_r(dat_r),
    .dat_w(dat_w)
  );

  reg [287:0] regs [0:2];
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
    endcase
  end

endmodule


