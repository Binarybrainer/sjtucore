module flat_mux #(
    parameter WIDTH = 32,
    parameter LENGTH = 32
) (
    input [WIDTH-1:0] src [LENGTH-1:0],
    input [$clog2(LENGTH)-1:0] sel,

    output [WIDTH-1:0] data
);
    assign data = src[sel];
    
endmodule