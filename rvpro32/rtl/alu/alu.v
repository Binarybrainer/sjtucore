module alu #(
    parameter XLEN =  32;
) (
    input [XLEN-1 : 0] op_a,
    input [XLEN-1 : 0] op_b,
    input [2:0] func3,
    input [6:0] func7,

    output [XLEN-1 : 0] result,
    output zero,
    output less,
    output less_u

);
    localparam ADD  = 3'b000;
    localparam SLL  = 3'b001;
    localparam SLT  = 3'b010;
    localparam SLTU = 3'b011;
    localparam XOR  = 3'b100;
    localparam SR   = 3'b101; //func7[5] = 1: SRA, func7[5] = 0: SRL
    localparam OR   = 3'b110;
    localparam AND  = 3'b111;

    wire [XLEN-1 : 0] adder_o;
    wire [XLEN-1 : 0] sll_o;
    wire [XLEN-1 : 0] slt_o;
    wire [XLEN-1 : 0] sltu_o;
    wire [XLEN-1 : 0] xor_o;
    wire [XLEN-1 : 0] sr_o;
    wire [XLEN-1 : 0] sra_o;
    wire [XLEN-1 : 0] srl_o;
    wire [XLEN-1 : 0] or_o;
    wire [XLEN-1 : 0] and_o;

    always @(*) begin
        case (func3)
            ADD: result <= adder_o;
            SLL: result <= sll_o;
            SLT: result <= slt_o;
            SLTU: result <= sltu_o;
            XOR: result <= xor_o;
            SR: result <= sr_o;
            OR: result <= or_o;
            AND: result <= and_o;
            default: result <= adder_o;
        endcase
    end

    wire [XLEN-1:0] compare_o;
    wire [XLEN:0] compare_o_u;

    adder(.XLEN(32)) adder_i (.a(op_a), .b(op_b), .sub(func7[5]), sum(adder_o));
    
    comparator(.XLEN(32)) compare_i (.a(op_a), .b(op_b), .sub(1'b1), .less(less), .zero(zero));

    comparator(.XLEN(33)) compare_u (.a({{1'b0,op_a}}), .b({1'b0, op_b}), .less(less_u));

    assign sll_o   = op_a << op_b;
    assign slt_o   = {31'b0, less};
    assign sltu_o  = {31'b0, less_u}; 
    
    assign xor_o   = op_a ^ op_b;
    assign or_o    = op_a | op_b;
    assign and_o   = op_a & op_b;

    assign sra_o   = op_a >>> op_b;  
    assign srl_o   = op_a >> op_b;  

    assign sr_o    = func7[5] ? sra_o : srl_o; 

endmodule