module comparator #(
    parameter XLEN = 32
)(
    input [XLEN-1:0] a,
    input [XLEN-1:0] b,

    output less,
    output greater,
    output equal
);

assign equal = ~(|(a ^ b));

wire sub_less;
wire cout;
wire [XLEN-1:0] sum;
assign sub_less = cout & sum[XLEN-1];

assign less = (~a[XLEN-1]) & b[XLEN-1] | sub_less;
assign greater = (~equal) & (~less);

adder #(.XLEN(XLEN)) adder_i(.a(a), .b(b), .sub(1'b1), .sum(sum), .cout(cout));

endmodule