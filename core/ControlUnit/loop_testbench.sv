module testbench;
	reg clk;
    reg [7:0] cnt;
    reg reset;
    reg should_increment;
    parameter BITS=15;
    parameter SUPERSCALAR_LOG_WIDTH=2;
    parameter LOOP_LOG_CNT=2;
    reg [BITS-1:0] new_loop_iteration_count;
    reg new_loop_is_inner_independent_loop;
    reg should_create_new_loop;
    wire [BITS-1:0] current_iteration;
    wire done;
    wire [SUPERSCALAR_LOG_WIDTH-1:0] copy_count;
    reg did_start_next_loop_iteration;
    reg did_finish_loop;

	initial begin
		$display("doing work");
        clk = 0;
        cnt = 0;
        reset = 1;
        stoptesting = 0;
        #20
        reset = 0; 
	end

    always
        #5 clk = !clk;

    initial begin
        #10000
        $finish;
    end
    loop  #(BITS, LOOP_LOG_CNT, SUPERSCALAR_LOG_WIDTH) loop(
        .clk(clk),
        .reset(reset),
        .should_increment(should_increment),
        .new_loop_iteration_count(new_loop_iteration_count),
        .new_loop_is_inner_independent_loop(new_loop_is_inner_independent_loop),
        .should_create_new_loop(should_create_new_loop),
        .did_start_next_loop_iteration(did_start_next_loop_iteration),
        .did_finish_loop(did_finish_loop), // last in
        .done(done), // first out
        .copy_count(copy_count)
    );

    initial begin
        $display("%s %s %s %s %s %s %s %s", "cnt", "insert", "done", "copy_count", "current_loop_depth", "depth1_loop_current_iteration","depth2_loop_current_iteration", "is_top_of_stack_independent_loop");
        // Test 1: simple test
        reset <= 1;
        
        #10
        reset <= 0;
        did_start_next_loop_iteration <= 0;
        new_loop_iteration_count <= 3;
        new_loop_is_inner_independent_loop <= 0;
        should_create_new_loop <= 1;
        should_increment <= 1;

        #10 // creates the new loop
        should_create_new_loop <= 0;
        #40
        did_start_next_loop_iteration <= 1;
        #10
        did_start_next_loop_iteration <= 0;
        #40
        did_start_next_loop_iteration <= 1;
        #10
        did_start_next_loop_iteration <= 0;
        #40
        if (done==1) $display("SUCCESS TEST 1"); else $display("FAILURE TEST 1 done: %x", done);
        did_finish_loop <= 1; // instead of turning on did_start_next_loop_iteration, we turned on did_finish_loop... real control unit only does this if done == 1
        stoptesting <= 1;

        // Test 2: 1 independent loop
        // stoptesting <= 0;
        // reset <= 1;
        
        // #10
        // reset <= 0;
        // new_loop_iteration_count <= 10;
        // new_loop_is_inner_independent_loop <= 1;
        // should_create_new_loop <= 1;
        // should_increment <= 1;

        // #10
        // should_create_new_loop <= 0;

        // #300
        // if (!stoptesting) $display("FAILURE TEST 2"); else $display("SUCCESS TEST 2");

        // // Test 3: outer loop and inner loop (no independent). inner loop 1 iteration
        // stoptesting <= 0;
        // reset <= 1;
        
        // #10 // outer loop
        // reset <= 0;
        // new_loop_iteration_count <= 20;
        // new_loop_is_inner_independent_loop <= 0;
        // should_create_new_loop <= 1;
        // should_increment <= 1;

        // #10 // inner loop first time adding instruction
        // new_loop_iteration_count <= 2;
        // new_loop_is_inner_independent_loop <= 0;
        // should_create_new_loop <= 1;

        // #10
        // should_create_new_loop <= 0;
        // should_increment <= 1;
        
        // #20 // inner loop second time adding instruction
        // new_loop_iteration_count <= 2;
        // new_loop_is_inner_independent_loop <= 0;
        // should_create_new_loop <= 1;

        // #10
        // should_create_new_loop <= 0;
        // should_increment <= 1;

        // // #20  // inner loop third time adding instruction
        // // new_loop_iteration_count <= 2;
        // // new_loop_is_inner_independent_loop <= 0;
        // // should_create_new_loop <= 1;
        // // should_increment <= 1; 

        // // #10
        // // should_create_new_loop <= 0;

        // #300
        // if (!stoptesting) $display("FAILURE TEST 3"); else $display("SUCCESS TEST 3");
    end
    
    reg stoptesting;
    always @(posedge clk) begin
        if (!stoptesting) begin
            cnt <= cnt + 1;
            $display("%x  %d      %d %d      %d               %d                        %d                              %d", cnt, should_create_new_loop, done, copy_count + 1, loop.current_loop_depth, loop.loop_current_iteration[0*BITS +: BITS], loop.loop_current_iteration[1*BITS +: BITS], loop.is_top_of_stack_independent_loop);
        end
        
    end

endmodule