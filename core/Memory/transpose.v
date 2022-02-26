/*
 * Transpose input matrix if flag is on
 * Uses SZ*(SZ-1)*LINE input LUT3. And half of that in real Xilinx 7 series LUTs
 * 3 of these is 0.5% of Small Cherry 1 LUTs and 0.5% of Big Cherry 1 LUTs.
 * A 2:1 matrix MUX module probably uses the same exact amount of LUTs as this module. Perhaps that could be combined into this to not use any extra LUTs. (i.e. use our extra 3 inputs.)
 */
module transpose #(parameter LINE=19, SZ=16) (
  input should_transpose,  
  input [SZ*SZ*LINE-1:0] matrix_in,
  output [SZ*SZ*LINE-1:0] matrix_out
);
// 216 LUT3 for SZ=4 LINE=18
// makes sense since 4*4*18-4*18=216 (the diagonal 4 elements never change).
// each of the LUT3 is a 2 to 1 multiplexer. 2 signal inputs, 1 control input, 1 output, 1 LUT3.
// Should be able to share LUTs since many have common inputs. So expected 216/2=108 LUTs needed.

generate
    genvar x,y;
    for (y=0; y<SZ; y=y+1) begin
        for (x=0; x<SZ; x=x+1) begin
            assign matrix_out[(y*SZ+x)*LINE +: LINE] =
            should_transpose
            ? matrix_in[(x*SZ+y)*LINE +: LINE]
            : matrix_in[(y*SZ+x)*LINE +: LINE];
        end
    end
endgenerate

// I can imagine a more efficient system that instead of using multiplexers
// instead uses some kind of thing that lets you swap two input signals based on a control signal.
// Not sure how the verilog for that would look
// or if we can even implement that with just LUTs.
// With just LUTs it looks like what the above synthesized...
// A 6 input 2 output that wastes 3 of its inputs.
// Good idea for an ASIC maybe.
endmodule


// Exploring one idea mentioned above with combining with a 2:1 matrix MUX.
// The diagonal of the output matrix now requires LUT3 to decide whether to come from slack or not. That adds SZ*LINE LUT3.
// But why isn't it 216/2 LUT6? Probably because synthesis isn't combining LUTs. That's the job of place and route to combine two 6 in 1 out LUTs with the same 6 inputs.
// 3 of these uses 1.5% of Small Cherry 1 and almost 1% of Big Cherry 1
module mux_and_transpose #(parameter LINE=18, SZ=4) (
  input should_transpose,
  input should_select_slack,
  input [SZ*SZ*LINE-1:0] matrix_in,
  input [SZ*SZ*LINE-1:0] matrix_in_slack,
  output [SZ*SZ*LINE-1:0] matrix_out
);

generate
    genvar x,y;
    for (y=0; y<SZ; y=y+1) begin
        for (x=0; x<SZ; x=x+1) begin
            assign matrix_out[(y*SZ+x)*LINE +: LINE] =
            should_select_slack
            ?
                should_transpose
                ? matrix_in_slack[(x*SZ+y)*LINE +: LINE]
                : matrix_in_slack[(y*SZ+x)*LINE +: LINE]
            :   should_transpose
                ? matrix_in[(x*SZ+y)*LINE +: LINE]
                : matrix_in[(y*SZ+x)*LINE +: LINE];
        end
    end
endgenerate
endmodule