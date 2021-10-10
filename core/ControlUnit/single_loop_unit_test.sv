/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

/// Specify the module to load or on files.f
`include "loop.sv"

`timescale 1 ns / 100 ps

module single_loop_testbench();

    `SVUT_SETUP

    parameter SUPERSCALAR_LOG_WIDTH = 2;
    parameter BITS=18;

    reg clk;
    reg reset;
    reg should_increment;
    reg [BITS-1:0] initial_iteration_count;
    reg initial_is_inner_independent_loop;
    reg jumped;
    wire done;
    wire [BITS-1:0] current_iteration;

    single_loop #(BITS, SUPERSCALAR_LOG_WIDTH) dut (
    clk,
    reset,
    should_increment,
    initial_iteration_count,
    initial_is_inner_independent_loop,
    jumped,
    done,
    current_iteration
    );

    // To create a clock:
    initial clk = 0;
    always #10 clk = ~clk;

    // To dump data for visualization:
    initial begin
        $dumpfile("single_loop_testbench.vcd");
        $dumpvars(0, single_loop_testbench);
    end

    // Setup time format when printing with $realtime
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("SUITE_NAME")

    `UNIT_TEST("SIMPLE_LOOP")
        initial_iteration_count <= 3;
        jumped <= 0;
        initial_is_inner_independent_loop <= 0;
        reset <= 1;
        @(posedge clk);
        should_increment <= 1;
        reset <= 0;
        for(integer i = 0; i < initial_iteration_count; i = i + 1) begin
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            if (i < initial_iteration_count - 1) begin
                `FAIL_IF(done);
                jumped <= 1; 
                @(posedge clk); // end_loop instruction with jump
                jumped <= 0;
                `FAIL_IF(done);
            end else begin
                // end loop instruction with no jump
                `FAIL_IF_NOT(done);
            end
        end
        @(posedge clk);
        `FAIL_IF_NOT(done);
        @(posedge clk);
        `FAIL_IF_NOT(done);
        reset <= 1;
        should_increment <= 0;
        jumped <= 1;
        @(posedge clk);
        @(posedge clk);// done needs time to propagate
        jumped <= 0;
        `FAIL_IF(done);
        @(posedge clk);
        `FAIL_IF(done);
    `UNIT_TEST_END

    `UNIT_TEST("SIMPLE_INDEPENDENT_LOOP")
        initial_iteration_count <= 12;
        jumped <= 0;
        initial_is_inner_independent_loop <= 1;
        reset <= 1;
        @(posedge clk);
        should_increment <= 1;
        reset <= 0;
        for(integer i = 0; i < 3; i = i + 1) begin
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            if (i < 3 - 1) begin
                `FAIL_IF(done);
                jumped <= 1; 
                @(posedge clk); // end_loop instruction with jump
                jumped <= 0;
                `FAIL_IF(done);
            end else begin
                // end loop instruction with no jump
                
                `FAIL_IF_NOT(done);
            end
        end
        @(posedge clk);
        `FAIL_IF_NOT(done);
        @(posedge clk);
        `FAIL_IF_NOT(done);
        reset <= 1;
        should_increment <= 0;
        jumped <= 1;
        @(posedge clk);
        @(posedge clk);// done needs time to propagate
        jumped <= 0;
        `FAIL_IF(done);
        @(posedge clk);
        `FAIL_IF(done);
    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
