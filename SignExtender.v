`timescale 1ns / 1ps
`define Itype   2'b00  // These defines are not required but may be helpful.
`define Dtype   2'b01
`define CBtype  2'b10
`define Btype   2'b11

// Sign Extender for the ARMv8 single cycle datapath.
//
// How it works:
//  - SignOp tells the unit which instruction format the immediate comes from,
//    which selects the bit field to pull out of Instruction[25:0].
//  - I-Type  (ADDI, ORRI, ...): ALU_immediate = Instruction[21:10] (12 bits).
//    ARMv8 immediate ALU ops use an unsigned immediate, so it is ZERO extended.
//  - D-Type  (LDUR/STUR): DT_address = Instruction[20:12] (9 bits), sign
//    extended by replicating Instruction[20].
//  - CB-Type (CBZ): COND_BR_address = Instruction[23:5] (19 bits), sign
//    extended by replicating Instruction[23], then shifted left 2 (word offset
//    -> byte offset) by appending two 0 bits on the right.
//  - B-Type  (B): BR_address = Instruction[25:0] (26 bits), sign extended by
//    replicating Instruction[25], then shifted left 2 the same way.
//  - Every path assigns all 64 bits and there is a default, so the
//    always @(*) block is purely combinational (no latches).
module SignExtender(
    output reg [63:0] SignExOut,
    input      [25:0] Instruction,
    input      [1:0]  SignOp
);

   always @(*)
     begin
       case (SignOp)
         `Itype:  SignExOut = {52'b0, Instruction[21:10]};                         // 52 + 12      = 64
         `Dtype:  SignExOut = {{55{Instruction[20]}}, Instruction[20:12]};         // 55 + 9       = 64
         `CBtype: SignExOut = {{43{Instruction[23]}}, Instruction[23:5], 2'b00};   // 43 + 19 + 2  = 64
         `Btype:  SignExOut = {{36{Instruction[25]}}, Instruction[25:0], 2'b00};   // 36 + 26 + 2  = 64
         default: SignExOut = 64'b0;
       endcase
     end

endmodule
