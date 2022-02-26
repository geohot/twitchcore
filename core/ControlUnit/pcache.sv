// On Small Cherry 1
// For one program
// 4 loops possible. Each has iteration count and body size. 8 numbers per program
// To load 8 numbers in 2 cycles, need 2 BRAM18s with port width 36 bits.
// 4 APU formulas. Each has 4 coefficients and 1 constant. 20 numbers per program
// To load 20 numbers in 2 cycles, need 5 BRAM18s with port width 36 bits.
// Each of our BRAM18 can have 256 lines now. So we can support 256 programs with our ro_data BRAMs.
// Also will need instruction data. 18 bit port width BRAM18s
// 2 BRAM18s. Can I configure these as 1 BRAM36 with 18 bit port width?
// That's 2048 instructions. Average program has 8 instructions so we can fit 256 programs with our instruction cache BRAMs.

// 9 BRAM18s total. 256 programs with an average of 8 instructions each.
// Program 0 is null data space. So 255 programs.

// should be 300 lut total not sure why so big.
module ro_data_mem #(parameter ADDRESS_WIDTH=15) (
  input clk,
  input reset_read,
  input [7:0] read_prog_addr,

  // loop ro_data
  input [7:0] loop_write_prog_addr, // set to 0 if you dont want to write
  output reg [LOOP_VALS*ADDRESS_WIDTH-1:0] loop_read_data,
  input [LOOP_VALS*ADDRESS_WIDTH-1:0] loop_write_data,
  input loop_we_pos,
  
  // apu ro_data
  input [7:0] apu_write_prog_addr, // set to 0 if you dont want to write
  output reg [APU_VALS*ADDRESS_WIDTH-1:0] apu_read_data,
  input [APU_VALS*ADDRESS_WIDTH-1:0] apu_write_data,
  input apu_we_pos
);
  parameter LOOP_CNT=4;
  parameter APU_CNT=4;
  parameter LOOP_VALS=LOOP_CNT*2;
  parameter APU_VALS=APU_CNT*(LOOP_VALS+1)*3;
  
  reg [(LOOP_VALS*ADDRESS_WIDTH>>1)-1:0] mem_loops [0:511]; // 256 programs, 8 numbers each
  reg [(APU_VALS*ADDRESS_WIDTH>>1)-1:0] mem_apus [0:511]; // 256 programs, 20 numbers each

  reg read_state;
  reg write_state;

  wire [0:511] write_addr_calculated_loops;
  wire [0:511] write_addr_calculated_apus;
  
  assign write_addr_calculated_loops = {loop_write_prog_addr, loop_we_pos};
  assign write_addr_calculated_apus = {apu_write_prog_addr, apu_we_pos};


  wire [(LOOP_VALS*ADDRESS_WIDTH>>1)-1:0] loops_read_now;
  wire [(APU_VALS*ADDRESS_WIDTH>>1)-1:0] apus_read_now;
  assign loops_read_now = mem_loops[{read_prog_addr, read_state}];
  assign apus_read_now = mem_apus[{read_prog_addr, read_state}];
  

  always @(posedge clk) begin
    // Write to any program, position controlled by caller
    // 1 cycle latency
    // Latency: 2 cycle (1 cycle to write first half, 1 cycle to write second half)
    // Throughput: 0.5 programs per cycle
    mem_loops[write_addr_calculated_loops] <= loop_we_pos ? loop_write_data[LOOP_VALS*ADDRESS_WIDTH>>1 +: LOOP_VALS*ADDRESS_WIDTH>>1] : loop_write_data[0 +: LOOP_VALS*ADDRESS_WIDTH>>1];
    mem_apus[write_addr_calculated_apus] <= apu_we_pos ? apu_write_data[(APU_VALS*ADDRESS_WIDTH>>1) +: (APU_VALS*ADDRESS_WIDTH>>1)] : apu_write_data[0 +: (APU_VALS*ADDRESS_WIDTH>>1)];

    // Read a single programs data in 3 cycles.
    // Latency: 3 cycles (1 reset cycle, 1 cycle to read first half, 1 cycle to read second half)
    // Throughput: 0.33 programs per cycle
    if (reset_read) begin
      read_state <= 0;
    end else begin
      read_state <= ~read_state; // proabably a waste of power lol constantly reading alternating addresses from memory
    end
    if (read_state == 0) loop_read_data[0 +: (LOOP_VALS*ADDRESS_WIDTH>>1)] <= loops_read_now;
    if (read_state == 0) apu_read_data[0 +: (APU_VALS*ADDRESS_WIDTH>>1)] <= apus_read_now;
    if (read_state == 1) loop_read_data[(LOOP_VALS*ADDRESS_WIDTH>>1) +: (LOOP_VALS*ADDRESS_WIDTH>>1)] <= loops_read_now;
    if (read_state == 1) apu_read_data[(APU_VALS*ADDRESS_WIDTH>>1) +: (APU_VALS*ADDRESS_WIDTH>>1)] <= apus_read_now;
    // maybe a shift registers would be better? They are just passing the control signal along though. probably the same
  end
endmodule

module icache_mem (
  input clk,
  input [10:0] read_instr_addr,
  input [10:0] write_instr_addr, // just write to 0 if you don't want to write
  output [ISA_WIDTH-1:0] raw_instr_read,
  input [ISA_WIDTH-1:0] raw_instr_write
);
  parameter ISA_WIDTH=18;
  reg [ISA_WIDTH-1:0] mem_instrs [0:2047]; // 2BRAM18
  assign raw_instr_read = mem_instrs[read_instr_addr];
  always @(posedge clk) begin
    mem_instrs[write_instr_addr] <= raw_instr_write;
  end
endmodule