// RISK extensions
// 4x4 registers
// we have 270 18-bit rams, need this instead of 19. depth is 1024
// let's make 128 BRAMs, that's 256 elements of read bandwidth
// 2304-bit wide databus if we only use one port (36864-bit in big chip)
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
  input [14:0] addr,
  input [13:0] stride_x,
  input [13:0] stride_y,
  input [287:0] dat_w,
  input we,
  output reg [287:0] dat_r
);
  // 1 cycle to get all the addresses
  // 32 BRAMs
  // SZ*SZ*len(addr)
  reg [239:0] addrs;

  generate
    genvar x,y;
    for (y=0; y<4; y=y+1) begin
      for (x=0; x<4; x=x+1) begin
        always @(posedge clk) begin
          addrs[(y*4+x)*15 +: 15] <= addr + stride_x*x + stride_y*y;
        end
      end
    end
  endgenerate

  // CNT*SZ*SZ
  
  // this uses 17% of the LUTs
  reg [511:0] mask;

  // this uses 18% of the LUTs
  //reg [31:0] ens;
  //reg [127:0] choice;

  // CNT*18
  wire [575:0] outs;

  //wire [287:0] dat_r_comb;

  generate
    genvar i,k;

    // CNT number of priority encoders of SZ*SZ
    for (i=0; i<32; i=i+1) begin
      reg [9:0] taddr;
      reg [17:0] in;
      wire [17:0] out;
      risk_single_mem rsm(
        .clk(clk),
        .addr(taddr),
        .data_r(out),
        .data_w(in),
        .we(we)
      );

      integer l;
      always @(posedge clk) begin
        //ens[i] <= 'b0;
        mask[i*16 +: 16] <= 'b0;
        for (l=0; l<16; l=l+1) begin
          if (addrs[15*l +: 5] == i) begin
            mask[i*16 +: 16] <= (1 << l);
            //ens[i] <= 'b1;
            //choice[i*4 +: 4] <= l;
            taddr <= addrs[15*l+5 +: 10];
            in <= dat_w[18*l +: 18];
          end
        end

        /*taddr = 10'b0;
        in = 18'b0;
        for (l=0; l<16; l=l+1) begin
          taddr = taddr | (addrs[15*l+5 +: 10] & {10{mask[i*16 + l]}});
          in = in | (dat_w[18*l +: 18] & {18{mask[i*16 + l]}});
        end*/
      end
      assign outs[i*18 +: 18] = out;
    end

    // this is SZ*SZ number of CNT to 1 muxes. these don't have to be priority encoders, really just a big or gate
    for (k=0; k<16; k=k+1) begin
      wire [31:0] lmask;
      for (i=0; i < 32; i=i+1) assign lmask[i] = mask[i*16 + k];

      // this uses 19%
      /*reg [5:0] idx;

      integer l;
      always @(posedge clk) begin
        for (l=0; l<32; l=l+1)
          if (lmask[l])
            idx <= l;
      end

      always @(posedge clk) begin
        dat_r[18*k +: 18] <= outs[18*idx +: 18];
      end*/

      /*always @(posedge clk) begin
        casez (lmask)
          'b???????????????????????????????1: dat_r[18*k +: 18] <= outs[18*0 +: 18];
          'b??????????????????????????????1?: dat_r[18*k +: 18] <= outs[18*1 +: 18];
          'b00000000000000000000000000000100: dat_r[18*k +: 18] <= outs[18*2 +: 18];
          'b00000000000000000000000000001000: dat_r[18*k +: 18] <= outs[18*3 +: 18];
          'b00000000000000000000000000010000: dat_r[18*k +: 18] <= outs[18*4 +: 18];
          'b00000000000000000000000000100000: dat_r[18*k +: 18] <= outs[18*5 +: 18];
          'b00000000000000000000000001000000: dat_r[18*k +: 18] <= outs[18*6 +: 18];
          'b00000000000000000000000010000000: dat_r[18*k +: 18] <= outs[18*7 +: 18];
          'b00000000000000000000000100000000: dat_r[18*k +: 18] <= outs[18*8 +: 18];
          'b00000000000000000000001000000000: dat_r[18*k +: 18] <= outs[18*9 +: 18];
          'b00000000000000000000010000000000: dat_r[18*k +: 18] <= outs[18*10 +: 18];
          'b00000000000000000000100000000000: dat_r[18*k +: 18] <= outs[18*11 +: 18];
          'b00000000000000000001000000000000: dat_r[18*k +: 18] <= outs[18*12 +: 18];
          'b00000000000000000010000000000000: dat_r[18*k +: 18] <= outs[18*13 +: 18];
          'b00000000000000000100000000000000: dat_r[18*k +: 18] <= outs[18*14 +: 18];
          'b00000000000000001000000000000000: dat_r[18*k +: 18] <= outs[18*15 +: 18];
          'b00000000000000010000000000000000: dat_r[18*k +: 18] <= outs[18*16 +: 18];
          'b00000000000000100000000000000000: dat_r[18*k +: 18] <= outs[18*17 +: 18];
          'b00000000000001000000000000000000: dat_r[18*k +: 18] <= outs[18*18 +: 18];
          'b00000000000010000000000000000000: dat_r[18*k +: 18] <= outs[18*19 +: 18];
          'b00000000000100000000000000000000: dat_r[18*k +: 18] <= outs[18*20 +: 18];
          'b00000000001000000000000000000000: dat_r[18*k +: 18] <= outs[18*21 +: 18];
          'b00000000010000000000000000000000: dat_r[18*k +: 18] <= outs[18*22 +: 18];
          'b00000000100000000000000000000000: dat_r[18*k +: 18] <= outs[18*23 +: 18];
          'b00000001000000000000000000000000: dat_r[18*k +: 18] <= outs[18*24 +: 18];
          'b00000010000000000000000000000000: dat_r[18*k +: 18] <= outs[18*25 +: 18];
          'b00000100000000000000000000000000: dat_r[18*k +: 18] <= outs[18*26 +: 18];
          'b00001000000000000000000000000000: dat_r[18*k +: 18] <= outs[18*27 +: 18];
          'b00010000000000000000000000000000: dat_r[18*k +: 18] <= outs[18*28 +: 18];
          'b00100000000000000000000000000000: dat_r[18*k +: 18] <= outs[18*29 +: 18];
          'b01000000000000000000000000000000: dat_r[18*k +: 18] <= outs[18*30 +: 18];
          'b10000000000000000000000000000000: dat_r[18*k +: 18] <= outs[18*31 +: 18];
        endcase
      end*/

      // this is the best yet
      /*integer l;
      always @(posedge clk) begin
        for (l=0; l<32; l=l+1)
          // TODO: replace with and and or
          //if (ens[l] == 'b1 && choice[l*4 +: 4] == k)
          if (lmask[l])
            dat_r[18*k +: 18] <= outs[18*l +: 18];
      end*/

      // https://andy-knowles.github.io/one-hot-mux/
      // down to 14%
      // in this chip, this is 16 registers x 32 BRAMs x 18-bits
      // in final edition, this will be 1024 registers x 2048 BRAMs x 19-bits
      integer l;
      always @(posedge clk) begin
        //$display("%b", outs);
        dat_r[18*k +: 18] = 'b0;
        for (l=0; l<32; l=l+1)
          dat_r[18*k +: 18] = dat_r[18*k +: 18] | (outs[18*l +: 18] & {18{lmask[l]}});
      end

      /*assign dat_r_comb[18*k +: 18] = 'bz;
      for (i=0; i<32; i=i+1) begin
        assign dat_r_comb[18*k +: 18] = |(outs[18*i +: 18] & {18{mask[i*16 + k]}});
      end*/
    end

    /*always @(posedge clk) begin
      dat_r <= dat_r_comb;
    end*/

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
  input [14:0] risk_addr,
  input [13:0] risk_stride_x,
  input [13:0] risk_stride_y,
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


