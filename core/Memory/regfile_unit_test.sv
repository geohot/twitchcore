/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

/// Specify the module to load or on files.f
`include "regfile.sv"

`timescale 1 ns / 100 ps

module regfile_testbench();

    `SVUT_SETUP

    parameter REG_CNT = 4;
    parameter SUPERSCALAR_WIDTH = 4;
    parameter REG_WIDTH = 288;

    reg clk;
    reg port_c_we, port_d_we;
    reg [0:REG_CNT*SUPERSCALAR_WIDTH-1] port_a_read_addr, port_b_read_addr, port_c_write_addr, port_d_write_addr;
    reg [REG_WIDTH-1:0] port_c_in, port_d_in;
    logic [REG_WIDTH-1:0] port_a_out, port_b_out;

    regfile
    #(
    REG_CNT,
    SUPERSCALAR_WIDTH,
    REG_WIDTH
    )
    dut 
    (
    clk,
    port_c_we, port_d_we,
    port_a_read_addr, port_b_read_addr, port_c_write_addr, port_d_write_addr,
    port_c_in, port_d_in,
    port_a_out, port_b_out
    );

    // To create a clock:
    initial clk = 0;
    always #10 clk = ~clk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("regfile(_testbench.vcd");
    //     $dumpvars(0, regfile(_testbench);
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

    `UNIT_TEST("BASIC_TEST")
        port_c_we = 1;
        port_c_in = 2;
        port_c_write_addr = 15;
        @(posedge clk); #2
        port_c_we = 0;
        port_c_in = 3;
        port_b_read_addr = 15;
        port_a_read_addr = 14;
        @(posedge clk); #2
        `ASSERT((port_a_out !== 2));
        `ASSERT((port_b_out === 2));
        port_a_read_addr = 15;
        port_b_read_addr = 12;
        @(posedge clk); #2
        `ASSERT((port_a_out === 2));
        `ASSERT((port_b_out !== 2));

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
