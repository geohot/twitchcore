// Vivado estimates this takes 901 out of our 63,400 total available real LUTs.
module apu #(parameter BITS=15, LOG_LOOP_CNT=3, LOG_APU_CNT=3) (
  input clk,
  input reset,
  input signed [BITS-1:0] di, // loop variable change amount. +1 on next iteration, -(loop body count) on end of loop
  
  input [(LOOP_CNT+1)*BITS*APU_CNT-1:0] new_address_formula, new_stride_x_formula, new_stride_y_formula, // connect to ro_data directly to save address_formula regs

  input change_loop_var,
  input [LOG_LOOP_CNT-1:0] loop_var,

  // view apu
  input [LOG_APU_CNT-1:0] apu_selector,
  output signed [BITS-1:0] addr, stridex, stridey, daddr, dstridex, dstridey
);
  parameter LOOP_CNT = (1 << LOG_LOOP_CNT);
  parameter APU_CNT = (1 << LOG_APU_CNT);

  reg signed [BITS-1:0] active_daddress_di [0:APU_CNT-1]; // set on active to active loop var
  reg signed [BITS-1:0] active_dstride_x_di [0:APU_CNT-1];
  reg signed [BITS-1:0] active_dstride_y_di [0:APU_CNT-1]; 

  // loop formulas: {coefficient LOOP_CNT, ..., coefficient 2, coefficient1, offset}
  // address_formula[0][0 +: BITS] gets you APU 0's offset
  // address_formula[0][loopvar*BITS+BITS +: BITS] gets you APU 0's coefficient for loopvar
  wire [(LOOP_CNT+1)*BITS-1:0] address_formula [0:APU_CNT-1];
  wire [(LOOP_CNT+1)*BITS-1:0] stride_x_formula [0:APU_CNT-1];
  wire [(LOOP_CNT+1)*BITS-1:0] stride_y_formula [0:APU_CNT-1];

  // Results
  reg signed [BITS-1:0] cur_address [0:APU_CNT-1];
  reg signed [BITS-1:0] cur_stride_x [0:APU_CNT-1];
  reg signed [BITS-1:0] cur_stride_y [0:APU_CNT-1];

  generate
  for(genvar i = 0; i < APU_CNT; i = i + 1) begin
    assign address_formula[i] = new_address_formula[(LOOP_CNT+1)*BITS*(APU_CNT-i-1) +: (LOOP_CNT+1)*BITS]; 
    assign stride_x_formula[i] = new_stride_x_formula[(LOOP_CNT+1)*BITS*(APU_CNT-i-1) +: (LOOP_CNT+1)*BITS];
    assign stride_y_formula[i] = new_stride_y_formula[(LOOP_CNT+1)*BITS*(APU_CNT-i-1) +: (LOOP_CNT+1)*BITS];
  end
  endgenerate
  always @(posedge clk) begin
    if (change_loop_var) begin
      // LOOP_CNT to 1 MUX. So LOOP_CNT data bits in, LOG_LOOP_CNT control bits in. 8+3=11 bits in. 2 LUT6. for each output bit. so 40 LUT6. * 3*APU_CNT = 1,000
      for(integer i = 0; i < APU_CNT; i = i + 1) begin
        active_daddress_di[i] <= address_formula[i][loop_var*BITS+BITS +: BITS];
        active_dstride_x_di[i] <= stride_x_formula[i][loop_var*BITS+BITS +: BITS];
        active_dstride_y_di[i] <= stride_y_formula[i][loop_var*BITS+BITS +: BITS];
      end
    end
    // cur_address[i] mux on reset control signal is expensive
    // APU_CNT*3 of them and each one is 18 bits wide 2 to 1. 432 LUT3s (2 data bits and a control bit in, 1 bit out. 18 of those per number. APU_CNT*3 numbers.) Can be combined into LUT6 though so 200 real LUTs
    if (reset) begin
      for(integer i = 0; i < APU_CNT; i = i + 1) begin
         // set to const
        cur_address[i] <= address_formula[i][0*BITS +: BITS];
        cur_stride_x[i] <= stride_x_formula[i][0*BITS +: BITS];
        cur_stride_y[i] <= stride_y_formula[i][0*BITS +: BITS];
      end
    end else begin
      for(integer i = 0; i < APU_CNT; i = i + 1) begin
        // i have a suspicion the adds are not using the DSPs
        cur_address[i] <= cur_address[i] + di * active_daddress_di[i];
        cur_stride_x[i] <= cur_stride_x[i] + di * active_dstride_x_di[i];
        cur_stride_y[i] <= cur_stride_y[i] + di * active_dstride_y_di[i];
      end
    end
  end
  

  // view APU
  // TODO: see if one hot mux is cheaper
  // 6 MUX, each one is apu_cnt to 1 and 18 bits wide. Each output bit has apu_cnt input data bits and log_apu_cnt control bits. so 8+3=11 bits in 1 bit out. Maybe 2 LUT6.
  assign addr = cur_address[apu_selector];
  assign stridex = cur_stride_x[apu_selector];
  assign stridey = cur_stride_y[apu_selector];
  assign daddr = active_daddress_di[apu_selector];
  assign dstridex = active_dstride_x_di[apu_selector];
  assign dstridey = active_dstride_y_di[apu_selector];
endmodule