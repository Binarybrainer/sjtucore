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

assign register[0] = 0;

generate
    genvar i;
    for (i = 1; i<32; i = i + 1) begin: REGISTER_INSTANCE
        always_ff @(posedge clk or negedge reset_n) begin
            if (reset_n == 0) begin
                register [i] <= 0;
            end else begin
                if (rd_address == i) 
                    register[i] <= rd_data;
                else 
                    register[i] <= register[i];
            end
        end
    end
endgenerate

assign rs1_data = register[rs1_address];
assign rs2_data = register[rs2_address];


endmodule 
