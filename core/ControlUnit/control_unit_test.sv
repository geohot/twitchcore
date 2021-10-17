/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

/// Specify the module to load or on files.f
`include "types.sv"
`include "apu.sv"
`include "loop.sv"
`include "pcache.sv"
`include "decoder.sv"
`include "control_unit.sv"

`timescale 1 ns / 100 ps

module control_unit_testbench();

    `SVUT_SETUP


    parameter SUPERSCALAR_LOG_WIDTH = 2;
    parameter LOG_LOOP_CNT = 3;
    parameter LOOP_LOG_CNT = 3;
    parameter LOG_APU_CNT = 3;
    parameter LOG_KCACHE_SIZE = 10;
    parameter MEMORY_ADDRESS_BITS = 15;
    parameter BITS = 18;
    parameter LOOP_CNT = (1 << LOG_LOOP_CNT);
    parameter APU_CNT = (1 << LOG_APU_CNT);

    reg clk;
    reg reset;
    reg [16:0] kernel_start_address;
    reg [BITS-1:0] di;
    reg [LOG_LOOP_CNT-1:0] loop_var;
    reg [LOG_APU_CNT-1:0] apu_selector;
    reg [0:17] raw_instruction;
    reg raw_instruction_fetch_successful;
    reg queue_almost_full;
    apu_formulas apu_formulas_ro_data;
    reg [BITS*2*8-1:0] loop_ro_data;
    queue_memory_instruction queue_memory_instructions;
    decoded_processing_instruction queue_processing_instructions;
    reg [SUPERSCALAR_LOG_WIDTH-1:0] copy_count;
    reg memory_instruction_we;
    reg processing_instruction_we;
    reg [LOG_KCACHE_SIZE-1:0] pc;
    reg error;

    cpu 
    #(
    LOG_KCACHE_SIZE,
    MEMORY_ADDRESS_BITS,
    LOG_APU_CNT,
    SUPERSCALAR_LOG_WIDTH,
    LOOP_LOG_CNT
    )
    dut 
    (
    clk,
    reset,
    kernel_start_address,
    raw_instruction,
    raw_instruction_fetch_successful,
    queue_almost_full,
    apu_formulas_ro_data,
    loop_ro_data,
    queue_memory_instructions,
    queue_processing_instructions,
    copy_count,
    memory_instruction_we,
    processing_instruction_we,
    pc,
    error
    );

    // To create a clock:
    initial clk = 0;
    always #20 clk = ~clk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("apu_testbench.vcd");
    //     $dumpvars(0, apu_testbench);
    // end

    // Setup time format when printing with $realtime
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        apu_formulas_ro_data = {
          {
            18'd1, 18'd2, 18'd0, 108'd0, // apu 0 is addr=i+2j+0
            18'd3, 18'd4, 18'd0, 108'd0, // apu 1 is addr=3i+4j+0,
            972'd81
          },
          {
            18'd2, 18'd1, 18'd0, 108'd0, // apu 0 is stridex=0+2i+1j
            18'd4, 18'd3, 18'd0, 108'd0, // apu 1 is stridex=0+3i+4j,
            972'd0
          },
          {
            18'd3, 18'd1, 18'd0, 108'd0, // apu 0 is stridey=03i+2j
            18'd4, 18'd3, 18'd0, 108'd0, // apu 1 is stridey=0+3i+4j,
            972'd0
          }
        };
        loop_ro_data = {
          18'd10, 18'd3, // loop 0, 10 iterations, 2 instruction in the loop (so we put 3 in instr)
          252'd0
        };
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("SUITE_NAME")

    `UNIT_TEST("BAD_INSTRUCTION")
        reset = 1;
        @(posedge clk); #2
        kernel_start_address = 1;
        reset = 0;
        @(posedge clk); #2
        queue_almost_full = 0;
        raw_instruction = {5'd20, 13'd0};
        raw_instruction_fetch_successful = 1;
        @(posedge clk); #2
        `ASSERT((error === 1));
    `UNIT_TEST_END

    `UNIT_TEST("PROCESSING_INSTRUCTIONS")
        reset = 1;
        @(posedge clk); #2
        kernel_start_address = 1;
        reset = 0;
        @(posedge clk); #2
        queue_almost_full = 0;
        raw_instruction = {5'd1, 13'd0};
        raw_instruction_fetch_successful = 1;
        
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '0));
        `ASSERT((processing_instruction_we === '1));
        `ASSERT((copy_count === 2'd0));
        `ASSERT((pc == 2));

        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '0));
        `ASSERT((processing_instruction_we === '1));
        `ASSERT((copy_count === 2'd0));
        `ASSERT((pc == 3));

        raw_instruction = {5'd13, 2'd2, 2'd1, 9'd0};
        raw_instruction_fetch_successful = 1;
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '0));
        `ASSERT((processing_instruction_we === '1));
        `ASSERT((copy_count === 2'd0));
        `ASSERT((pc == 4));
        `ASSERT((queue_processing_instructions.target == 2'd2));
        `ASSERT((queue_processing_instructions.source == 2'd1));

    `UNIT_TEST_END

    `UNIT_TEST("MEMORY_INSTRUCTIONS")
        reset = 1;
        @(posedge clk); #2
        kernel_start_address = 1;
        reset = 0;
        @(posedge clk); #2
        queue_almost_full = 0;
        raw_instruction = 18'b011110000011110000; // load
        raw_instruction_fetch_successful = 1;
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd0));
        `ASSERT((pc === 2));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '0));
        `ASSERT((queue_memory_instructions.params.height === 2'd3));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '0));
        `ASSERT((queue_memory_instructions.apu_values === 0));
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd0));
        `ASSERT((pc === 3));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '0));
        `ASSERT((queue_memory_instructions.params.height === 2'd3));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '0));
        `ASSERT((queue_memory_instructions.apu_values === 0));
        raw_instruction = 18'b011110000110110100; // load
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd0));
        `ASSERT((pc === 4));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '1));
        `ASSERT((queue_memory_instructions.params.height === 2'd2));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '1));
        `ASSERT((queue_memory_instructions.apu_values === 0));
    `UNIT_TEST_END

    // `UNIT_TEST("MEMORY_INSTRUCTIONS_AND_APU")
    // `UNIT_TEST_END

    `UNIT_TEST("LOOP_AND_MEMORY_INSTRUCTIONS_WITH_APU")
        reset = 1;
        @(posedge clk); #2
        kernel_start_address = 1;
        reset = 0;
        @(posedge clk); #2
        queue_almost_full = 0;
        raw_instruction = 18'b100010000000000000; // start independent loop
        raw_instruction_fetch_successful = 1;
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '0));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((pc === 2));
    
        raw_instruction = 18'b011110000110110100; // load
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd3));
        `ASSERT((pc === 3));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '1));
        `ASSERT((queue_memory_instructions.params.height === 2'd2));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '1));
        `ASSERT((queue_memory_instructions.apu_values.addr === 0));
        `ASSERT((queue_memory_instructions.apu_values.stridex === 0));
        `ASSERT((queue_memory_instructions.apu_values.stridey === 0));
        `ASSERT((queue_memory_instructions.apu_values.daddr === 1));
        `ASSERT((queue_memory_instructions.apu_values.dstridex === 2));
        `ASSERT((queue_memory_instructions.apu_values.dstridey === 3));
        `ASSERT((dut.loop.loop_current_iteration[0 +: BITS] == 18'd9));
        raw_instruction = 18'b011110000110110100; // load
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd3));
        `ASSERT((pc === 4));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '1));
        `ASSERT((queue_memory_instructions.params.height === 2'd2));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '1));
        `ASSERT((queue_memory_instructions.apu_values.addr === 0));
        `ASSERT((queue_memory_instructions.apu_values.stridex === 0));
        `ASSERT((queue_memory_instructions.apu_values.stridey === 0));
        `ASSERT((queue_memory_instructions.apu_values.daddr === 1));
        `ASSERT((queue_memory_instructions.apu_values.dstridex === 2));
        `ASSERT((queue_memory_instructions.apu_values.dstridey === 3));
        //`ASSERT((dut.loop.loop_current_iteration[0 +: BITS] == 18'd9));

        raw_instruction = 18'b100110000000000000; // end loop or jump
        @(posedge clk);
        #2;
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '0));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd3));
        `ASSERT((pc === 2));

        raw_instruction = 18'b011110000110110100; // load
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd3));
        `ASSERT((pc === 3));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '1));
        `ASSERT((queue_memory_instructions.params.height === 2'd2));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '1));
        `ASSERT((queue_memory_instructions.apu_values.addr === 4));
        `ASSERT((queue_memory_instructions.apu_values.stridex === 8));
        `ASSERT((queue_memory_instructions.apu_values.stridey === 12));
        `ASSERT((queue_memory_instructions.apu_values.daddr === 1));
        `ASSERT((queue_memory_instructions.apu_values.dstridex === 2));
        `ASSERT((queue_memory_instructions.apu_values.dstridey === 3));
        
        raw_instruction = 18'b011110000110110100; // load
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd3));
        `ASSERT((pc === 4));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '1));
        `ASSERT((queue_memory_instructions.params.height === 2'd2));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '1));
        `ASSERT((queue_memory_instructions.apu_values.addr === 4));
        `ASSERT((queue_memory_instructions.apu_values.stridex === 8));
        `ASSERT((queue_memory_instructions.apu_values.stridey === 12));
        `ASSERT((queue_memory_instructions.apu_values.daddr === 1));
        `ASSERT((queue_memory_instructions.apu_values.dstridex === 2));
        `ASSERT((queue_memory_instructions.apu_values.dstridey === 3));

        raw_instruction = 18'b100110000000000000; // end loop or jump
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '0));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd1));
        `ASSERT((pc === 2));

        raw_instruction = 18'b011110000110110100; // load
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd1));
        `ASSERT((pc === 3));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '1));
        `ASSERT((queue_memory_instructions.params.height === 2'd2));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '1));
        `ASSERT((queue_memory_instructions.apu_values.addr === 8));
        `ASSERT((queue_memory_instructions.apu_values.stridex === 16));
        `ASSERT((queue_memory_instructions.apu_values.stridey === 24));
        `ASSERT((queue_memory_instructions.apu_values.daddr === 1));
        `ASSERT((queue_memory_instructions.apu_values.dstridex === 2));
        `ASSERT((queue_memory_instructions.apu_values.dstridey === 3));

        raw_instruction = 18'b011110000110110100; // load
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '1));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd1));
        `ASSERT((pc === 4));
        `ASSERT((queue_memory_instructions.params.is_load === '1));
        `ASSERT((queue_memory_instructions.params.target === '1));
        `ASSERT((queue_memory_instructions.params.height === 2'd2));
        `ASSERT((queue_memory_instructions.params.width === 2'd3));
        `ASSERT((queue_memory_instructions.params.zero_flag === '0));
        `ASSERT((queue_memory_instructions.params.skip_flag === '1));
        `ASSERT((queue_memory_instructions.apu_values.addr === 8));
        `ASSERT((queue_memory_instructions.apu_values.stridex === 16));
        `ASSERT((queue_memory_instructions.apu_values.stridey === 24));
        `ASSERT((queue_memory_instructions.apu_values.daddr === 1));
        `ASSERT((queue_memory_instructions.apu_values.dstridex === 2));
        `ASSERT((queue_memory_instructions.apu_values.dstridey === 3));

        raw_instruction = 18'b100110000000000000; // end loop or jump
        @(posedge clk); #2
        `ASSERT((error === 0));
        `ASSERT((memory_instruction_we === '0));
        `ASSERT((processing_instruction_we === '0));
        `ASSERT((copy_count === 2'd0)); // we are out of our superscalar body so next instruction won't be in parallel
        `ASSERT((pc === 5)); // loop is complete so no need to jump!
    
    `UNIT_TEST_END

    // `UNIT_TEST("NESTED_LOOP")

    // `UNIT_TEST_END

    // `UNIT_TEST("LOTS_OF_RELUS")
    // simple loop over every elmeent in input matrix
    // load submatrix and compute relu on them
    // `UNIT_TEST_END

    // `UNIT_TEST("REAL_CHERRY_PROGRAM")
    //     // Multiply 2 matrices, 64x64x64
    //     // Compile from real python matmul program

    //     // reset cpu
    //     // feed in instructions. Nested loop is in here!
    //     // at some point pretend the queue is full
    //     // at end, say fetch unsuccessful
    //     // assert cpu state finish
    // `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
