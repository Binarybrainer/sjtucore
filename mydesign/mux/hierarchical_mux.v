// status: draft, not complete
module reg_mux #(
    parameter WIDTH = 32,
    parameter LENGTH = 32
) (
    input [WIDTH-1:0] mux_in [LENGTH-1:0],
    input [$clog2(LENGTH)-1:0]select,

    output [WIDTH-1:0] data
);
    
endmodule