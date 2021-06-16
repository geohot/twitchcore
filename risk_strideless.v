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
  output reg [71:0] data_r,
  input [71:0] data_w,
  input we
);
  // this is 4x 18k BRAM
  reg [71:0] mem [0:1023];
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
  input [18*4*4-1:0] dat_w,
  input we,
  output reg [18*4*4-1:0] dat_r
);
  parameter LOGCNT=4;
  parameter CNT=(1<<LOGCNT);
  parameter SZ=4;
  parameter BITS=18;
  parameter LINE=BITS*SZ;

  // 1 cycle to get all the addresses
  // 32 BRAMs
  reg [(10+LOGCNT)*SZ-1:0] addrs;

  generate
    genvar x,y;
    for (y=0; y<1; y=y+1) begin
      for (x=0; x<SZ; x=x+1) begin
        always @(posedge clk) begin
          addrs[(y*4+x)*(10+LOGCNT) +: (10+LOGCNT)] <= addr + stride_x*x + stride_y*y;
        end
      end
    end
  endgenerate

  // CNT*SZ*SZ
  
  // this uses 17% of the LUTs
  reg [CNT*SZ-1:0] mask;

  // this uses 18% of the LUTs
  //reg [31:0] ens;
  //reg [127:0] choice;

  // CNT*72
  wire [LINE*CNT-1:0] outs;

  //wire [287:0] dat_r_comb;

  generate
    genvar i,k;

    // CNT number of priority encoders of SZ*SZ
    for (i=0; i<CNT; i=i+1) begin
      reg [9:0] taddr;
      reg [LINE-1:0] in;
      wire [LINE-1:0] out;
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
        mask[i*SZ +: SZ] <= 'b0;
        for (l=SZ-1; l>=0; l=l-1) begin
          if (addrs[(10+LOGCNT)*l +: LOGCNT] == i) begin
            mask[i*SZ +: SZ] <= (1 << l);
            taddr <= addrs[(10+LOGCNT)*l+LOGCNT +: 10];
            in <= dat_w[LINE*l +: LINE];
          end
        end
      end
      assign outs[i*LINE +: LINE] = out;
    end

    // this is SZ*SZ number of CNT to 1 muxes. these don't have to be priority encoders, really just a big or gate
    for (k=0; k<SZ; k=k+1) begin
      wire [CNT-1:0] lmask;
      for (i=0; i < CNT; i=i+1) assign lmask[i] = mask[i*SZ + k];

      // https://andy-knowles.github.io/one-hot-mux/
      // down to 14%
      // in this chip, this is 16 registers x 32 BRAMs x 18-bits
      // in final edition, this will be 1024 registers x 2048 BRAMs x 19-bits
      integer l;
      always @(posedge clk) begin
        //$display("%b", lmask);
        if (lmask != 'b0) begin
          dat_r[LINE*k +: LINE] = 'b0;
          for (l=0; l<CNT; l=l+1)
            dat_r[LINE*k +: LINE] = dat_r[LINE*k +: LINE] | (outs[LINE*l +: LINE] & {LINE{lmask[l]}});
        end
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


