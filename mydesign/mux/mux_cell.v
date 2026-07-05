//stautus: complete, verified
module mux_cell #(
    parameter LENGTH = 32
) (
    input src[LENGTH-1:0],
    input [$clog2(LENGTH)-1:0] sel,

    output data
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

wire [LENGTH-1:0] data_cell;
generate
    genvar i;
    for (i = 0; i < LENGTH; i = i+ 1) begin: DATA_CELL
       assign data_cell[i] = (sel == i) ? src[i] : 0;
    end
endgenerate


assign data = |data_cell;

endmodule
