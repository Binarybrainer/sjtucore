//status: complete, behavioral, unverify
module rv32_format (

    input [31:0] instr,
    
    output [4:0] rs1_addr,
    output [4:0] rs2_addr,
    output [4:0] rd_addr,

    output [6:0] opcode,

    output [31:0] imm,

    output [2:0] func3,
    output [6:0] func7

);

    parameter R_TYPE = 3'b000;
    parameter I_TYPE = 3'b001;
    parameter S_TYPE = 3'b010;
    parameter B_TYPE = 3'b011;
    parameter U_TYPE = 3'b100;
    parameter J_TYPE = 3'b101;
    parameter R4_TYPE = 3'b110;


    parameter LOAD     = 5'b00000;//
    parameter STORE    = 5'b01000;//
    parameter MADD     = 5'b10000;
    parameter BRANCH   = 5'b11000;//
    
    parameter LOAD_FP  = 5'b00001;
    parameter STORE_FP = 5'b01001;
    parameter MSUB     = 5'b10001;
    parameter JALR     = 5'b11001;//
    
    parameter NMSUB    = 5'b10010;
    
    parameter MISC_MEM = 5'b00011;//
    parameter AMO      = 5'b01011;
    parameter NMADD    = 5'b10011;
    parameter JAL      = 5'b11011;//
    
    parameter OP_IMM   = 5'b00100;//
    parameter OP       = 5'b01100;//
    parameter OP_FP    = 5'b10100;
    parameter SYSTEM   = 5'b11100;
    
    parameter AUIPC    = 5'b00101;//
    parameter LUI      = 5'b01101;//
    //parameter OP_V     = 5'b10101;
    //parameter OP_VE    = 5'b11101;
    
    //parameter OP_IMM_32 = 5'b00110;
    //parameter OP_32     = 5'b01110;

    assign opcode   = instr[6:0];
    assign rd_addr  = instr[11:7];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];

    assign func3 = instr[14:12];
    assign func7 = instr[31:25];


    wire [31:0] I_IMM;
    wire [31:0] S_IMM;
    wire [31:0] U_IMM;
    wire [31:0] B_IMM;
    wire [31:0] J_IMM;

    assign I_IMM = {{21{instr[31]}}, instr[30:20]};
    assign S_IMM = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    assign U_IMM = {instr[31:12],12'b0};
    assign B_IMM  = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    assign J_IMM  = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 

    reg [2:0] optype;

    always @(*) begin
        case (opcode[6:2])
            LUI  : optype = U_TYPE;
            AUIPC: optype = U_TYPE;

            JAL   : optype = J_TYPE;
            JALR  : optype = I_TYPE;
            
            BRANCH: optype = B_TYPE;
            LOAD  : optype = I_TYPE;
            STORE : optype = I_TYPE;

            OP_IMM: optype = I_TYPE;
            OP    : optype = R_TYPE;

            MISC_MEM : optype = I_TYPE;
            SYSTEM   : optype = I_TYPE;

            //RV32A, RV64A extension
            AMO : optype = R_TYPE;

            //RV32F, RV64F extension
            LOAD_FP : optype = I_TYPE;
            STORE_FP: optype = S_TYPE;
            
            MADD    : optype = R4_TYPE;
            MSUB    : optype = R4_TYPE;
            NMADD   : optype = R4_TYPE;
            NMSUB   : optype = R4_TYPE;

            OP_FP   : optype = R_TYPE;

            default: optype = 3'b000;
        endcase    
    end

    reg [31:0] imm_reg;
    always @(*) begin
        case (optype) 
            R_TYPE: imm_reg = 32'b0;
            J_TYPE: imm_reg = J_IMM;
            I_TYPE: imm_reg = I_IMM;
            B_TYPE: imm_reg = B_IMM;
            U_TYPE: imm_reg = U_IMM;
            S_TYPE: imm_reg = S_IMM;
            default: imm_reg = 32'b0;
        endcase    
    end

    assign imm = imm_reg;


endmodule
