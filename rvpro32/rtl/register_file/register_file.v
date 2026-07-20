module register_file (
     input clk,
     input rst_n,
     input [4:0] rs1_addr,
     input [4:0] rs2_addr,
     input [4:0] rd_addr, // No need for write enable
     input rd_data,

     output [31:0] rs1_data,
     output [31:0] rs2_data
);
    wire [31:0] register_o[31:0];

    assign rs1_data = registers_o[rs1_addr];
    assign rs2_data = registers_o[rs2_addr];

    assign registers_o[0] = 32'b0;

    wire [31:0] rd_we;
    
    assign rd_we = 1 << rd_addr;

    generate
        genvar i;
        for (i = 1; i < 32 ;i = i + 1 ) begin: REG_FILE
            register register_i (.clk(clk), .rst_n(rst_n), .d(rd_data), .q(registers_o[i]), .we(rd_we[i]));
        end
    endgenerate

endmodule