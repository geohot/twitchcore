`include "../Arith/Mul.v"
`include "../FpAdd_c/FpAdd_c.v"

module recursivesum (
    input [27*N-1:0] OUT_IN,
    output [27*N/2-1:0] OUT_NEXT
);
    parameter N = 32;
    wire [27*(N/2)-1:0] nextA, nextB, nextOUT;
    assign nextA = OUT_IN[27*(N/2)-1:0];
    assign nextB = OUT_IN[27*N-1:27*(N/2)];
    FpAdd_c add_unit[N/2-1:0](
        nextA,
        nextB,
        nextOUT
    );
    assign OUT_NEXT = nextOUT;
endmodule

module DotProduct (
    input [27*N-1:0] A, B,
    output wire[27-1:0] OUT
);
parameter N = 32;
Mul #(.MANTISSA(18)) mul_unit[N-1:0] (A, B, firstOUT);
wire[27*N-1:0] firstOUT;
recursivesum#(N) depth1(
    firstOUT,
    nextOUT1
);
wire[27*N/2-1:0] nextOUT1;
recursivesum#(N/2) depth2(
    nextOUT1,
    nextOUT2
);
wire[27*N/4-1:0] nextOUT2;
// assign OUT = nextOUT2; // uncomment for N=4

// start commenting here (to end) for N=4
// Update to use if statements on tree depth. Is that allowed to define wires in parameter if statement? Most people at this point would generate the verilog with python but i hate that.
recursivesum#(N/4) depth3(
    nextOUT2,
    nextOUT3
);
wire[27*N/8-1:0] nextOUT3;
recursivesum#(N/8) depth4(
    nextOUT3,
    nextOUT4
);
wire[27*N/16-1:0] nextOUT4;
recursivesum#(N/16) depth5(
    nextOUT4,
    nextOUT5
);
wire[27*N/32-1:0] nextOUT5;
assign OUT = nextOUT5;

endmodule