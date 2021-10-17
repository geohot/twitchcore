// Vivado estimates this takes 901 out of our 63,400 total available real LUTs.
// 1 cycle latency.
module apu #(parameter BITS=15, LOG_LOOP_CNT=3, LOG_APU_CNT=3) (
  input clk,
  input reset,
  input enable,
  input is_starting_new_loop,
  input current_loop_done,
  input [BITS-1:0] iteration_count,
  input apu_formulas formulas, // connect to ro_data directly
  input [LOG_LOOP_CNT-1:0] loop_var,
  input [BITS-1:0] loop_di,

  // view apu after the 1 cycle latency
  input [LOG_APU_CNT-1:0] apu_selector,
  output apu_output apu_out
);
  parameter LOOP_CNT = (1 << LOG_LOOP_CNT);
  parameter APU_CNT = (1 << LOG_APU_CNT);
  wire signed [BITS-1:0] di; // loop variable change amount. +1 on next iteration, -(loop body count) on end of loop
  assign di = is_starting_new_loop
              ? 0
              : current_loop_done
                ? -iteration_count // end. undo loops effect on apu
                : loop_di; // jump (next loop iteration) // TODO: incorrect because doesnt include superscalar width
  

  wire signed [BITS-1:0] daddress_di [0:APU_CNT-1]; // set on active to active loop var
  wire signed [BITS-1:0] dstride_x_di [0:APU_CNT-1];
  wire signed [BITS-1:0] dstride_y_di [0:APU_CNT-1]; 

  // loop formulas: {coefficient LOOP_CNT, ..., coefficient 2, coefficient1, offset}
  // address_formula[0][0 +: BITS] gets you APU 0's offset
  // address_formula[0][loopvar*BITS+BITS +: BITS] gets you APU 0's coefficient for loopvar
  wire [(LOOP_CNT+1)*BITS-1:0] address_formula [0:APU_CNT-1];
  wire [(LOOP_CNT+1)*BITS-1:0] stride_x_formula [0:APU_CNT-1];
  wire [(LOOP_CNT+1)*BITS-1:0] stride_y_formula [0:APU_CNT-1];

  // Registers
  reg signed [BITS-1:0] prev_address [0:APU_CNT-1];
  reg signed [BITS-1:0] prev_stride_x [0:APU_CNT-1];
  reg signed [BITS-1:0] prev_stride_y [0:APU_CNT-1];

  // Results
  reg signed [BITS-1:0] cur_address [0:APU_CNT-1];
  reg signed [BITS-1:0] cur_stride_x [0:APU_CNT-1];
  reg signed [BITS-1:0] cur_stride_y [0:APU_CNT-1];

  generate
  for(genvar i = 0; i < APU_CNT; i = i + 1) begin
    assign address_formula[i] = formulas.address[(LOOP_CNT+1)*BITS*(APU_CNT-i-1) +: (LOOP_CNT+1)*BITS]; 
    assign stride_x_formula[i] = formulas.stride_x[(LOOP_CNT+1)*BITS*(APU_CNT-i-1) +: (LOOP_CNT+1)*BITS];
    assign stride_y_formula[i] = formulas.stride_y[(LOOP_CNT+1)*BITS*(APU_CNT-i-1) +: (LOOP_CNT+1)*BITS];

    // LOOP_CNT to 1 MUX. So LOOP_CNT data bits in, LOG_LOOP_CNT control bits in. 8+3=11 bits in. 2 LUT6. for each output bit. so 40 LUT6. * 3*APU_CNT = 1,000
    assign daddress_di[i] = address_formula[i][(LOOP_CNT-loop_var-1)*BITS+BITS +: BITS];
    assign dstride_x_di[i] = stride_x_formula[i][(LOOP_CNT-loop_var-1)*BITS+BITS +: BITS];
    assign dstride_y_di[i] = stride_y_formula[i][(LOOP_CNT-loop_var-1)*BITS+BITS +: BITS];
  end
  endgenerate
  always @(posedge clk) begin
    if (reset) begin
      for(integer i = 0; i < APU_CNT; i = i + 1) begin
         // set to const
        prev_address[i] <= address_formula[i][0 +: BITS];
        prev_stride_x[i] <= stride_x_formula[i][0 +: BITS];
        prev_stride_y[i] <= stride_y_formula[i][0 +: BITS];
      end
    end else if (enable) begin
      for(integer i = 0; i < APU_CNT; i = i + 1) begin
        prev_address[i] <= cur_address[i];
        prev_stride_x[i] <= cur_stride_x[i];
        prev_stride_y[i] <= cur_stride_y[i];
      end
    end
  end
  always @(*) begin
    // cur_address[i] mux on reset control signal is expensive
    // APU_CNT*3 of them and each one is 18 bits wide 2 to 1. 432 LUT3s (2 data bits and a control bit in, 1 bit out. 18 of those per number. APU_CNT*3 numbers.) Can be combined into LUT6 though so 200 real LUTs
    for(integer i = 0; i < APU_CNT; i = i + 1) begin
      // i have a suspicion the adds are not using the DSPs
      cur_address[i] <= enable ? prev_address[i] + di * daddress_di[i] : prev_address[i];
      cur_stride_x[i] <= enable ? prev_stride_x[i] + di * dstride_x_di[i] : prev_stride_x[i];
      cur_stride_y[i] <= enable ? prev_stride_y[i] + di * dstride_y_di[i] : prev_stride_y[i];
    end
  end
  
  always @(posedge clk) begin
    // view APU
    // TODO: see if one hot mux is cheaper. This MUX is 1 ns. I know by comparing delay for prev_address to delay for apu_out. Only difference between the two is the mux.
    // We probably can get away with doing this mux after the clock,
    // That way we push it's combinatorial delay to the queue unit.
    // 6 MUX, each one is apu_cnt to 1 and 18 bits wide. Each output bit has apu_cnt input data bits and log_apu_cnt control bits. so 8+3=11 bits in 1 bit out. Maybe 2 LUT6.
    apu_out <= {
      cur_address[apu_selector],
      cur_stride_x[apu_selector],
      cur_stride_y[apu_selector],
      daddress_di[apu_selector],
      dstride_x_di[apu_selector],
      dstride_y_di[apu_selector]
    };
  end
endmodule