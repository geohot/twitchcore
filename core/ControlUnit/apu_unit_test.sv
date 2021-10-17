/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

/// Specify the module to load or on files.f
`include "types.sv"
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
    reg enable;
    reg [BITS-1:0] di;
    reg [(LOOP_CNT+1)*BITS*APU_CNT-1:0] new_address_formula, new_stride_x_formula, new_stride_y_formula;
    reg [LOG_LOOP_CNT-1:0] loop_var;
    reg [LOG_APU_CNT-1:0] apu_selector;
    apu_output addr, stridex, stridey, daddr, dstridex, dstridey;

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
    enable,
    di,
    new_address_formula, new_stride_x_formula, new_stride_y_formula, 
    loop_var,
    apu_selector,
    {addr, stridex, stridey, daddr, dstridex, dstridey}
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
        /// setup() runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("SUITE_NAME")

    `UNIT_TEST("SIMPLE_TEST")
        reset = 1;
        enable = 1;
        di = 0;
        loop_var = 0;
        new_address_formula = {8'd2, 8'd1, 8'd0, // apu 0 is addr=0+i+2j
                                8'd4, 8'd3, 8'd0}; // apu 1 is addr=0+3i+4j
        apu_selector = 0;
        
        @(posedge clk);#2

        $display("%d %d %x %d %d %d", addr, dut.address_formula[0][0*BITS +: BITS], new_address_formula[(LOOP_CNT+1)*BITS*(APU_CNT-0-1) +: (LOOP_CNT+1)*BITS], dut.daddress_di[0], dut.cur_address[1], dut.di);
        `ASSERT((addr == 0)); // TODO: how can I make assert fail when addr is x
        `ASSERT((dut.cur_address[1] == 0));
        reset = 0;
        di = 1;
        @(posedge clk);#2
        `ASSERT((addr == 1));
        di = 0;

        @(posedge clk);#2
        `ASSERT((addr == 1));
        `ASSERT((dut.cur_address[1] == 3));
        // DEBUG // $display("%d %d %x %d %d %d", addr, dut.address_formula[0][1*BITS+BITS +: BITS], new_address_formula[(LOOP_CNT+1)*BITS*(APU_CNT-0-1) +: (LOOP_CNT+1)*BITS], dut.active_daddress_di[0], dut.cur_address[0], dut.di);
        di = 2; // we could use blocking logic, so this won't take 1 cycle to get feedback on
        @(posedge clk);#2
        `ASSERT((addr == 3));
        $display("%d %d %x %d %d %d", addr, dut.address_formula[0][1*BITS+BITS +: BITS], new_address_formula[(LOOP_CNT+1)*BITS*(APU_CNT-0-1) +: (LOOP_CNT+1)*BITS], dut.daddress_di[0], dut.cur_address[1], dut.di);
        `ASSERT((dut.cur_address[1] == 9));

        loop_var = 1;
        @(posedge clk);#2
        `ASSERT((addr == 7));
        `ASSERT((dut.cur_address[1] == 17));

        di = -2;
        @(posedge clk); #2
        `ASSERT((addr == 3));
        `ASSERT((dut.cur_address[1] == 9));

        apu_selector = 1;
        #2 `ASSERT((addr == 9));

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
