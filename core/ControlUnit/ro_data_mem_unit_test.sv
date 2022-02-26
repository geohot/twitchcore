/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

/// Specify the module to load or on files.f
`include "pcache.sv"

`timescale 1 ns / 100 ps

module ro_data_mem_testbench();

    `SVUT_SETUP

    parameter ADDRESS_WIDTH=4;

    reg clk;
    reg reset_read;
    reg [7:0] read_prog_addr;
    reg [7:0] loop_write_prog_addr;
    logic [8*ADDRESS_WIDTH-1:0] loop_read_data;
    reg [8*ADDRESS_WIDTH-1:0] loop_write_data;
    reg loop_we_pos;
    reg [7:0] apu_write_prog_addr;
    logic [20*ADDRESS_WIDTH-1:0] apu_read_data;
    reg [20*ADDRESS_WIDTH-1:0] apu_write_data;
    reg apu_we_pos;

    ro_data_mem 
    #(
    ADDRESS_WIDTH
    )
    dut 
    (
    clk,
    reset_read,
    read_prog_addr,
    loop_write_prog_addr,
    loop_read_data,
    loop_write_data,
    loop_we_pos,
    apu_write_prog_addr,
    apu_read_data,
    apu_write_data,
    apu_we_pos
    );

    // To create a clock:
    initial clk = 0;
    always #2 clk = ~clk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("ro_data_mem_testbench.vcd");
    //     $dumpvars(0, ro_data_mem_testbench);
    // end

    // Setup time format when printing with $realtime
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        /// setup() runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("SUITE_NAME")

    ///    Available macros:"
    ///
    ///    - `MSG("message"):       Print a raw white message
    ///    - `INFO("message"):      Print a blue message with INFO: prefix
    ///    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
    ///    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
    ///    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter 
    ///    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
    ///
    ///    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    ///    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    ///    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    ///    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    ///    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    ///    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
    ///
    ///    Available flag:
    ///
    ///    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

    `UNIT_TEST("BASIC_WRITE_THEN_READ")
        // Start write
        loop_write_prog_addr = 8'd3;
        loop_we_pos = 0;
        loop_write_data = 32'd311564344;
        
        @(posedge clk); #2 // write first half
        loop_write_prog_addr = 8'd3;
        loop_we_pos = 1;
        
        @(posedge clk); #2 // write second half

        // Start read
        loop_write_prog_addr = 8'd0; // disable write
        read_prog_addr = 8'd3;
        reset_read = 1;
        @(posedge clk); #2 // reset
        
        reset_read = 0;
        @(posedge clk); #2 // read first half
        @(posedge clk); #2 // read second half
        `ASSERT((loop_read_data === 32'd311564344));
    `UNIT_TEST_END

    `UNIT_TEST("BASIC_WRITE_THEN_READ")
        // Start write
        loop_write_prog_addr = 8'd3;
        loop_we_pos = 0;
        loop_write_data = 32'd311564344;
        
        @(posedge clk); #2 // write first half
        loop_write_prog_addr = 8'd3;
        loop_we_pos = 1;
        
        @(posedge clk); #2 // write second half

        // Start read and start write
        loop_write_prog_addr = 8'd4;
        loop_we_pos = 0;
        loop_write_data = 32'd11111111;

        read_prog_addr = 8'd3;
        reset_read = 1;
        @(posedge clk); #2 // reset read and start write
        
        loop_write_prog_addr = 8'd4;
        loop_we_pos = 1;
        reset_read = 0;
        @(posedge clk); #2 // read first half and write second half
        loop_write_prog_addr = 8'd0;
        @(posedge clk); #2 // read second half and stop write
        `ASSERT((loop_read_data === 32'd311564344));

        // Start read second program
        loop_write_prog_addr = 8'd0; // disable write
        read_prog_addr = 8'd4;
        reset_read = 1;
        @(posedge clk); #2 // reset
        
        reset_read = 0;
        @(posedge clk); #2 // read first half
        @(posedge clk); #2 // read second half
        `ASSERT((loop_read_data === 32'd11111111));
    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
