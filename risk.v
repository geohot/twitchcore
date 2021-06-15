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
  reg [511:0] mask;
  // CNT*18
  wire [575:0] outs;

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
        for (l=0; l<16; l=l+1) begin
          if (addrs[15*l +: 5] == i) begin
            taddr <= addrs[15*l+5 +: 10];
            in <= dat_w[18*l +: 18];
            mask[i*16 +: 16] <= (1 << l);
          end
        end
      end
      assign outs[i*18 +: 18] = out;
    end

    // this is SZ*SZ number of CNT to 1 muxes. these don't have to be priority encoders, really just a big or gate
    for (k=0; k<16; k=k+1) begin
      integer l;
      always @(posedge clk) begin
        for (l=0; l<32; l=l+1)
          // TODO: replace with and and or
          if (mask[l*16 + k])
            dat_r[18*k +: 18] <= outs[18*l +: 18];
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


