`include "../DotProduct/DotProduct.v"
module MatMul (
    input [27*N*N-1:0] MAT_A, MAT_B,
    output [27*N*N-1:0] MAT_OUT
);
    parameter N = 4;

    genvar i, j;
    generate
		for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                wire [27*N-1:0] row, col;
                assign row = MAT_A[27*i+27*N-1:27*i];
                assign col = MAT_B[27*j+27*N-1:27*j];
                DotProduct#(N) dot_prod_unit(
                    row, col, element_result
                );
                wire [27-1:0] element_result;
                assign MAT_OUT[27*(i*N+j)] = element_result;
            end
		end
	endgenerate
endmodule
/*
module VectorMul (
    input [27*N-1:0] A, B,
    output wire[27*N-1:0] OUT
)
parameter N = 32;
FpMul mul_unit[N-1:0] (
    A, B, OUT
);
endmodule
*/