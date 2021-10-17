module testbench;
	reg clk;
    reg [7:0] cnt;
    reg reset;

	initial begin
		$display("doing work");
        clk = 0;
        cnt = 0;
        reset = 1;
        #20
        reset = 0; 
	end

    always
        #5 clk = !clk;

    initial begin
        #140
        $finish;
    end
  
    reg [17:0] raw_instruction;
    wire [15:0] memory_instruction;
    wire [15:0] processing_instruction;
    wire [2:0] loop_instruction;
    wire [1:0] instruction_type; 
    decoder decoder(
        .clk(clk),
        .reset(reset),
        .raw_instruction(raw_instruction),
        .memory_instruction(memory_instruction),
        .processing_instruction(processing_instruction),
        .loop_instruction(loop_instruction),
        .instruction_type(instruction_type)
    );

    initial begin
        raw_instruction <= 0;
        #10
        raw_instruction <= {5'd5, 13'b0}; // DIV instruction
    end

    always @(posedge clk) begin
        $display("%x %x", processing_instruction, instruction_type);
    end

endmodule