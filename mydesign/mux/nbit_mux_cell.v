//stautus: complete, unverified

`include "mydesign/mux/mux_cell.v"

module nbit_mux_cell #(
    parameter LENGTH = 32,
    parameter WIDTH = 32
) (
    input [WIDTH-1:0] src [LENGTH-1:0],
    input [$clog2(LENGTH)-1:0] sel,

    output [WIDTH-1:0] data
);



generate
    genvar i;
    for (i=0; i<WIDTH; i=i+1) begin : GEN_MUX

        wire  column [LENGTH-1:0]; 
        genvar j;
        for (j=0; j<LENGTH; j=j+1) begin : GEN_COL
            assign column[j] = src[j][i];
        end

        mux_cell #(
            .LENGTH(LENGTH)
        ) u_mux (
            .src(column),
            .sel(sel),
            .data(data[i])
        );
    end
endgenerate

endmodule
