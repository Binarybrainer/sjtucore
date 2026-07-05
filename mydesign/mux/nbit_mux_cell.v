//stautus: complete, unverified

`include "mydesign/mux/mux_cell"

module nbit_mux_cell #(
    parameter LENGTH = 32,
    parameter WIDTH = 32
) (
    input [WIDTH-1:0] src[LENGTH-1:0],
    input [$clog2(LENGTH)-1:0] sel,

    output [WIDTH-1:0] data
);

/*
+---------+---------+
| Sel[1:0]| Output  |
+---------+---------+
|   00    | src0    |
|   01    | src1    |
|   10    | src2    |
|   11    | src3    |
+---------+---------+
*/


generate
    genvar i;
    for (i = 0; i < WIDTH; i = i + 1) begin
        
    end
endgenerate

endmodule
