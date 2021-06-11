module decode (
  input [31:0] ins,
  output [6:0] opcode
);
  assign opcode = ins[6:0];
endmodule

// candy is a low performance RISC-V processor
module candy (
  input clk, resetn,
  output reg trap
);
  always @(posedge clk) begin
  end
endmodule
