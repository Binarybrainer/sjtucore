module adder #(
    parameter XLEN = 32
)(
    input [XLEN-1:0] a,
    input [XLEN-1:0] b,
    input sub,
    output [XLEN-1:0] sum,
    output cout
);

    assign {cout, sum} = a + (b^{XLEN{sub}}) + sub;

endmodule