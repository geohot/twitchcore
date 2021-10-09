/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

/// Specify the module to load or on files.f
`include "apu.sv"

`timescale 1 ns / 100 ps

module apu_testbench();

    `SVUT_SETUP

    parameter LOG_LOOP_CNT = 1;
    parameter LOG_APU_CNT = 1;
    parameter BITS = 8;
    parameter LOOP_CNT = (1 << LOG_LOOP_CNT);
    parameter APU_CNT = (1 << LOG_APU_CNT);

    reg clk;
    reg reset;
    reg [BITS-1:0] di;
    reg [(LOOP_CNT+1)*BITS*APU_CNT-1:0] new_address_formula, new_stride_x_formula, new_stride_y_formula;
    reg change_loop_var;
    reg [LOG_LOOP_CNT-1:0] loop_var;
    reg [LOG_APU_CNT-1:0] apu_selector;
    wire [BITS-1:0] addr, stridex, stridey, daddr, dstridex, dstridey;

    apu 
    #(
    BITS,
    LOG_LOOP_CNT,
    LOG_APU_CNT
    )
    dut 
    (
    clk,
    reset,
    di,
    new_address_formula, new_stride_x_formula, new_stride_y_formula, 
    change_loop_var,
    loop_var,
    apu_selector,
    addr, stridex, stridey, daddr, dstridex, dstridey
    );

    // To create a clock:
    initial clk = 0;
    always #2 clk = ~clk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("apu_testbench.vcd");
    //     $dumpvars(0, apu_testbench);
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

    `UNIT_TEST("SIMPLE_TEST")
        reset <= 1;
        change_loop_var <= 1;
        di <= 0;
        loop_var <= 0;
        new_address_formula <= {8'd2, 8'd1, 8'd0, // apu 0 is addr=0+i+2j
                                8'd4, 8'd3, 8'd0}; // apu 1 is addr=0+3i+4j
        apu_selector <= 0;
        @(posedge clk);
        // we have latency, so nothing to assert here.
        reset <= 0;
        change_loop_var <= 0;
        @(posedge clk);
        `ASSERT((addr == 0)); // TODO: how can I make assert fail when addr is x
        di <= 1;

        @(posedge clk);
        di <= 0;
        // DEBUG // $display("%d %d %x %d %d %d", addr, dut.address_formula[0][1*BITS+BITS +: BITS], new_address_formula[(LOOP_CNT+1)*BITS*(APU_CNT-0-1) +: (LOOP_CNT+1)*BITS], dut.active_daddress_di[0], dut.cur_address[0], dut.di);
        `ASSERT((addr == 0));
        `ASSERT((dut.cur_address[1] == 0));
        
        @(posedge clk);
        `ASSERT((addr == 1));
        `ASSERT((dut.cur_address[1] == 3));

        di <= 2; // we could use blocking logic, so this won't take 1 cycle to get feedback on
        @(posedge clk);
        `ASSERT((addr == 1));
        $display("%d %d %x %d %d %d", addr, dut.address_formula[0][1*BITS+BITS +: BITS], new_address_formula[(LOOP_CNT+1)*BITS*(APU_CNT-0-1) +: (LOOP_CNT+1)*BITS], dut.active_daddress_di[0], dut.cur_address[1], dut.di);
        `ASSERT((dut.cur_address[1] == 3));

        change_loop_var <= 1;
        loop_var <= 1;

        @(posedge clk);
        `ASSERT((addr == 3));
        `ASSERT((dut.cur_address[1] == 9));

        change_loop_var <= 0;

        @(posedge clk);
        `ASSERT((dut.active_daddress_di[0] == 2));
        `ASSERT((addr == 5));
        `ASSERT((dut.cur_address[1] == 15));

        @(posedge clk);
        `ASSERT((addr == 9));
        `ASSERT((dut.cur_address[1] == 23));

        apu_selector <= 1; // apu selector gives instant feedback but everything else takes a cycle. We may want to change this so things are consistent
        @(posedge clk);
        `ASSERT((dut.cur_address[1] == 31));

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
