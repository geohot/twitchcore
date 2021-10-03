module testbench;
	reg clk;
    reg [7:0] cnt;
    reg reset;
    reg should_increment;
    parameter BITS=15;
    parameter SUPERSCALAR_LOG_WIDTH=2;
    reg initial_is_inner_independent_loop;
    reg [BITS-1:0] initial_iteration_count;
    reg jumped;
    wire [BITS-1:0] body_instruction_count, current_iteration;
    wire done;
	initial begin
		$display("doing work");
        clk = 0;
        cnt = 0;
        reset = 1;
        stoptesting <= 0;
        #20
        reset = 0; 
	end

    always
        #5 clk = !clk;

    initial begin
        #2000
        $finish;
    end

    single_loop  #(BITS, SUPERSCALAR_LOG_WIDTH) dut(
        .clk(clk),
        .reset(reset),
        .should_increment(should_increment),
        .initial_iteration_count(initial_iteration_count),
        .jumped(jumped),
        .initial_is_inner_independent_loop(initial_is_inner_independent_loop), // last in
        .done(done), // first out
        .current_iteration(current_iteration)
    );

    initial begin
        $display("cnt done current_iteration should_increment");
        // simple loop test. 3 iterations. 3 
        reset <= 1;
        initial_iteration_count <= 3;
        jumped <= 0;
        initial_is_inner_independent_loop <= 0;
        
        #10
        should_increment <= 1;
        reset <= 0;
        for(integer i = 0; i < initial_iteration_count; i = i + 1) begin
            #30 // 3 * processing instruction
            if (i < initial_iteration_count - 1) begin
                jumped <= 1; 
                #10;// end_loop instruction with jump
                jumped <= 0;
            end else begin
                // end loop instruction with no jump
                if (done == 1) $display("SUCCESS TEST 1"); else $display("FAILURE TEST 1 done: %x", done);
            end
        end
        

        // indpeentent loop test
        should_increment <= 0;
        reset <= 1;
        initial_iteration_count <= 2;
        jumped <= 0;
        initial_is_inner_independent_loop <= 1;
        #10
        reset <= 0;
        should_increment <= 1;
        #20
        jumped <= 1;
        if (done == 1) $display("SUCCESS TEST 2"); else $display("FAILURE TEST 2 done: %x", done);

        // long independent loop test
        should_increment <= 0;
        reset <= 1;
        initial_iteration_count <= 16;
        jumped <= 0;
        initial_is_inner_independent_loop <= 1;
        #10
        reset <= 0;
        should_increment <= 1;
        #10
        jumped <= 1;
        #30
        if (!done) $display("FAILURE TEST 3"); else $display("SUCCESS TEST 3");
        stoptesting <= 1;
    end
    
    reg stoptesting;
    always @(posedge clk) begin
        if (!stoptesting) begin
            cnt <= cnt + 1;
            $display("%x  %d    %d                   %d", cnt, done, current_iteration, should_increment);
        end
    end

endmodule