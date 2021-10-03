
// I look at https://github.com/dawsonjon/fpu/blob/master/multiplier/multiplier.v
// I make combinatorial and parameterize
// Still need denorm and norm?
module Mul (
    input      [WIDTH-1:0] A, B,
    output     [WIDTH-1:0] OUT
);
    parameter EXPONENT = 8;
    parameter MANTISSA = 8;
    parameter WIDTH = EXPONENT+MANTISSA+1;
    parameter MAX_EXPONENT = {(EXPONENT){1'b1}};

    // Unpack
    wire        A_s, B_s, A_is_zero, B_is_zero;
    wire [EXPONENT-1:0] A_e, B_e;
    wire [MANTISSA-1:0] A_f, B_f;
    assign A_s = A[WIDTH-1];
    assign B_s = B[WIDTH-1];
    assign A_e = A[WIDTH-2:MANTISSA];
    assign B_e = B[WIDTH-2:MANTISSA];
    assign A_f = A[MANTISSA-1:0]; 
    assign B_f = A[MANTISSA-1:0]; 
    wire should_return_nan, input_has_nan, A_inf, A_exponent_is_max, B_exponent_is_max;
    assign A_exponent_is_max = A_e == {EXPONENT{1'b1}}; // A_e == {1'b0,{(EXPONENT-1){1'b1}}};
    assign B_exponent_is_max = B_e == {EXPONENT{1'b1}}; // B_e == {1'b0,{(EXPONENT-1){1'b1}}};
    assign A_exponent_is_min = A_e == {EXPONENT{1'b0}}; // A_e == {EXPONENT{1'b1}};
    assign B_exponent_is_min = B_e == {EXPONENT{1'b0}}; // B_e == {EXPONENT{1'b1}};
    assign A_is_zero = A_exponent_is_min; // flush to zero enabled // && A[MANTISSA-1:1] == 0;
    assign B_is_zero = B_exponent_is_min; // flush to zero enabled && B[MANTISSA-1:1] == 0;
    assign A_is_inf = A_exponent_is_max && A_f == 0;
    assign B_is_inf = B_exponent_is_max && B_f == 0;
    assign A_is_nan = A_exponent_is_max && A_f != 0;
    assign B_is_nan = B_exponent_is_max && B_f != 0;
    // assign A_is_underflowed = A_exponent_is_min && A_f != 0; // lets just flush to zero so this line isn't needed
    // assign B_is_underflowed = B_exponent_is_min && B_f != 0; // lets just flush to zero so this line isn't needed

    // Special cases checks in parallel
    assign should_return_inf = (A_is_inf && !B_is_zero) || (B_is_inf && !A_is_zero);
    assign should_return_nan = (A_is_nan || B_is_nan) || (A_is_inf && B_is_zero)|| (B_is_inf && A_is_zero);
    assign should_return_zero = A_is_zero || B_is_zero;

    // Math
    wire [(MANTISSA+1)*2-1:0] pre_prod_frac;
    assign pre_prod_frac = {1'b1, A[MANTISSA-1:0]} * {1'b1, B[MANTISSA-1:0]};
    // assign pre_prod_frac = {A_is_underflowed ? 1'b0 : 1'b1, A[MANTISSA-1:0]} * {B_is_underflowed ? 1'b0 : 1'b1, B[MANTISSA-1:0]}; // on fp32 checking for underflows costs us 20 LUTs. I didn't even try normalizing the number after.

    wire [EXPONENT:0] pre_prod_exp;
    assign pre_prod_exp = A_e + B_e;

    // If MSB of product frac is 1, shift right one. Else if second MSB is 0, shift left one
    // TODO: Do we need rounding when we cut the bits off? Or is it ok to always round down in AI?
    wire [EXPONENT-1:0] oProd_e;
    wire [MANTISSA-1:0] oProd_f;
    assign need_mantissa_left_shift = pre_prod_frac[(MANTISSA+1)*2-2];
    assign need_mantissa_right_shift = pre_prod_frac[(MANTISSA+1)*2-1];
    assign oProd_e = need_mantissa_right_shift
        ? (pre_prod_exp-9'd126)
        : need_mantissa_left_shift
            ? (pre_prod_exp-9'd127)
            : (pre_prod_exp-9'd126);
    assign oProd_f = need_mantissa_right_shift
        ? pre_prod_frac[(MANTISSA+1)*2-2:MANTISSA+1]
        : need_mantissa_left_shift
            ? pre_prod_frac[(MANTISSA+1)*2-3:MANTISSA]
            : pre_prod_frac[(MANTISSA+1)*2-4:MANTISSA-1];

    // Detect underflow
    wire        underflow;
    assign underflow = pre_prod_exp < {1'b0, 1'b1, {EXPONENT-2{1'b0}}};  // 128. Second most signficant bit is 1
    // Should special cases come first?
    assign OUT = underflow        ? {WIDTH{1'b0}} : // is this a flush to zero?
                   should_return_nan ? {1'b1, MAX_EXPONENT, 1'b1, {(MANTISSA-1){1'b0}}} :
                   should_return_inf ? {A_s ^ B_s, MAX_EXPONENT, {MANTISSA{1'b0}}} :
                   should_return_zero ? {A_s ^ B_s, {WIDTH-1{1'b0}}} :
                   {A_s ^ B_s, oProd_e, oProd_f};

endmodule