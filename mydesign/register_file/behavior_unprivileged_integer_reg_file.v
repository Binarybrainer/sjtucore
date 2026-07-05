// status: draft, unverify, unoptimize

module unprivileged_integer_reg_file#(
    parameter WIDTH = 32
) (
    input clk,
    input reset_n,
    input [$clog2(WIDTH)-1:0] rs1_address,
    input [$clog2(WIDTH)-1:0] rs2_address,
    input [$clog2(WIDTH)-1:0] rd_address,    
    input [WIDTH-1:0] rd_data,

    output [WIDTH-1:0] rs1_data,
    output [WIDTH-1:0] rs2_data

);

reg [WIDTH-1:0] register [0:31];

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        integer i;
        for (i = 0; i < WIDTH; i = i + 1) begin
            register[i] <= {WIDTH{1'b0}};
        end
    end else begin
        if (rd_address != 0) begin
            register[rd_address] <= rd_data;
        end
    end
end


assign rs1_data = register[rs1_address];
assign rs2_data = register[rs2_address];


endmodule 
