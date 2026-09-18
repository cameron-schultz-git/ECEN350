`define OPCODE_ANDREG 11'b10001011000
`define OPCODE_ORRREG 11'b10101010000
`define OPCODE_ADDREG 11'b10001011000
`define OPCODE_SUBREG 11'b11001011000

`define OPCODE_ADDIMM 11'b1001000100?
`define OPCODE_SUBIMM 11'b1101000100?

`define OPCODE_MOVZ   11'b110100101??

`define OPCODE_B      11'b000101?????
`define OPCODE_CBZ    11'b10110100???

`define OPCODE_LDUR   11'b11111000010
`define OPCODE_STUR   11'b11111000000

module SC_Control(
               output reg       Reg2Loc,
               output reg       ALUSrc,
               output reg       MemtoReg,
               output reg       RegWrite,
               output reg       MemRead,
               output reg       MemWrite,
               output reg       Branch,
               output reg       Uncondbranch,
               output reg [3:0] ALUOp,
               output reg [1:0] SignOp,
               input [10:0]     opcode
               );
