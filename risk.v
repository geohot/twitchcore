// RISK extensions
// 4x4 registers
// we have 270 18-bit rams, need this instead of 19. depth is 1024
// let's make 128 BRAMs, that's 256 elements of read bandwidth
// this is also the size of ECC
// use a 9 bit mantissa (cherryfloat)

module risk_single_mem (
  input clk,
  input [9:0] addr,
  output reg [17:0] data_r,
  input [17:0] data_w,
  input we
);
  // this is 1 18k BRAM
  reg [17:0] mem [0:1023];
  always @(posedge clk) begin
    if (we) begin
      mem[addr] <= data_w;
    end else begin
      data_r <= mem[addr];
    end
  end
  //assign data_r = {8'hff, addr};
endmodule

// this is hard to synthesize
module risk_mem (
  input clk,
  input [16:0] addr,
  input [14:0] stride_x,
  input [14:0] stride_y,
  input [287:0] dat_w,
  input we,
  output reg [287:0] dat_r
);
  // 1 cycle to get all the addresses
  // 128 BRAMs
  reg [271:0] addrs;

  generate
    genvar x,y;
    for (y=0; y<4; y=y+1) begin
      for (x=0; x<4; x=x+1) begin
        always @(posedge clk) begin
          addrs[(y*4+x)*17+16:(y*4+x)*17] <= addr + stride_x*x + stride_y*y;
        end
      end
    end
  endgenerate

  wire [287:0] dat_r_comb;
  generate
    genvar i,k;
    for (i=0; i<128; i=i+1) begin
      wire [9:0] taddr;
      wire [17:0] in;
      wire [17:0] out;
      wire [4:0] choic;
      risk_single_mem rsm(
        .clk(clk),
        .addr(taddr),
        .data_r(out),
        .data_w(in),
        .we(we)
      );

      // CNT number of priority encoders of SZ*SZ
      assign taddr = (addrs[0*17+6:0*17] == i) ? addrs[0*17+16:0*17+7] :
                     (addrs[1*17+6:1*17] == i) ? addrs[1*17+16:1*17+7] :
                     (addrs[2*17+6:2*17] == i) ? addrs[2*17+16:2*17+7] :
                     (addrs[3*17+6:3*17] == i) ? addrs[3*17+16:3*17+7] :
                     (addrs[4*17+6:4*17] == i) ? addrs[4*17+16:4*17+7] :
                     (addrs[5*17+6:5*17] == i) ? addrs[5*17+16:5*17+7] :
                     (addrs[6*17+6:6*17] == i) ? addrs[6*17+16:6*17+7] :
                     (addrs[7*17+6:7*17] == i) ? addrs[7*17+16:7*17+7] :
                     (addrs[8*17+6:8*17] == i) ? addrs[8*17+16:8*17+7] :
                     (addrs[9*17+6:9*17] == i) ? addrs[9*17+16:9*17+7] :
                     (addrs[10*17+6:10*17] == i) ? addrs[10*17+16:10*17+7] :
                     (addrs[11*17+6:11*17] == i) ? addrs[11*17+16:11*17+7] :
                     (addrs[12*17+6:12*17] == i) ? addrs[12*17+16:12*17+7] :
                     (addrs[13*17+6:13*17] == i) ? addrs[13*17+16:13*17+7] :
                     (addrs[14*17+6:14*17] == i) ? addrs[14*17+16:14*17+7] :
                     (addrs[15*17+6:15*17] == i) ? addrs[15*17+16:15*17+7] :
                     10'b0;
      // tags
      assign in = (addrs[0*17+6:0*17] == i) ? dat_w[0*18+17:0*18] :
                  (addrs[1*17+6:1*17] == i) ? dat_w[1*18+17:1*18] :
                  (addrs[2*17+6:2*17] == i) ? dat_w[2*18+17:2*18] :
                  (addrs[3*17+6:3*17] == i) ? dat_w[3*18+17:3*18] :
                  (addrs[4*17+6:4*17] == i) ? dat_w[4*18+17:4*18] :
                  (addrs[5*17+6:5*17] == i) ? dat_w[5*18+17:5*18] :
                  (addrs[6*17+6:6*17] == i) ? dat_w[6*18+17:6*18] :
                  (addrs[7*17+6:7*17] == i) ? dat_w[7*18+17:7*18] :
                  (addrs[8*17+6:8*17] == i) ? dat_w[8*18+17:8*18] :
                  (addrs[9*17+6:9*17] == i) ? dat_w[9*18+17:9*18] :
                  (addrs[10*17+6:10*17] == i) ? dat_w[10*18+17:10*18] :
                  (addrs[11*17+6:11*17] == i) ? dat_w[11*18+17:11*18] :
                  (addrs[12*17+6:12*17] == i) ? dat_w[12*18+17:12*18] :
                  (addrs[13*17+6:13*17] == i) ? dat_w[13*18+17:13*18] :
                  (addrs[14*17+6:14*17] == i) ? dat_w[14*18+17:14*18] :
                  (addrs[15*17+6:15*17] == i) ? dat_w[15*18+17:15*18] :
                  18'b0;

      assign choic = (addrs[0*17+6:0*17] == i) ? 'h10 :
                     (addrs[1*17+6:1*17] == i) ? 'h11 :
                     (addrs[2*17+6:2*17] == i) ? 'h12 : 
                     (addrs[3*17+6:3*17] == i) ? 'h13 :
                     (addrs[4*17+6:4*17] == i) ? 'h14 :
                     (addrs[5*17+6:5*17] == i) ? 'h15 :
                     (addrs[6*17+6:6*17] == i) ? 'h16 :
                     (addrs[7*17+6:7*17] == i) ? 'h17 :
                     (addrs[8*17+6:8*17] == i) ? 'h18 :
                     (addrs[9*17+6:9*17] == i) ? 'h19 :
                     (addrs[10*17+6:10*17] == i) ? 'h1a :
                     (addrs[11*17+6:11*17] == i) ? 'h1b :
                     (addrs[12*17+6:12*17] == i) ? 'h1c :
                     (addrs[13*17+6:13*17] == i) ? 'h1d :
                     (addrs[14*17+6:14*17] == i) ? 'h1e :
                     (addrs[15*17+6:15*17] == i) ? 'h1f :
                     5'b0;

      // this is SZ*SZ number of CNT to 1 muxs
      for (k=0; k<16; k=k+1) begin
        assign dat_r_comb[18*k+17:18*k] = (choic[3:0] == k && choic[4] == 'b1) ? out : 'bz; 
      end
    end
  endgenerate

  always @(posedge clk) begin
    dat_r <= dat_r_comb;
  end

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
  input [14:0] risk_stride_x,
  input [14:0] risk_stride_y,
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
      3'b010: regs[risk_reg] <= 'b0;
    endcase
  end

endmodule


