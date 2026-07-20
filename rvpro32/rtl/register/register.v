module register #(
    parameter XLEN = 32;
) (
    input clk;
    input rst_n;

    input [XLEN-1 : 0] d;
    input we;

    output reg [XLEN-1 : 0] q;
);
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) q <= 0;
        else if (we) q <= d;
        else q <= q;
    end
    
endmodule