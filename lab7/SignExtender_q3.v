`timescale 1ns / 1ps
// Lab 7 Q3 version of SignExtender.v: adds the MOVZ instruction. The prelab version is SignExtender.v.
`define Itype    3'b000  // These defines are not required but may be helpful.
`define Dtype    3'b001
`define CBtype   3'b010
`define Btype    3'b011
`define MOVZtype 3'b100  // ADDED in Lab 7 for MOVZ

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
//  - MOVZ (Lab 7): MOV_immediate = Instruction[20:5] (16 bits), zero extended,
//    then shifted left by 16 * hw, where hw = Instruction[22:21]. So the
//    16-bit value lands in bits [15:0], [31:16], [47:32] or [63:48] and every
//    other bit is 0, which is exactly the value MOVZ writes to Rd.
//  - SignOp was widened from 2 to 3 bits in Lab 7, because all four 2-bit
//    codes were already used.
//  - Every path assigns all 64 bits and there is a default, so the
//    always @(*) block is purely combinational (no latches).
module SignExtender(
    output reg [63:0] SignExOut,
    input      [25:0] Instruction,
    input      [2:0]  SignOp
);

   always @(*)
     begin
       case (SignOp)
         `Itype:  SignExOut = {52'b0, Instruction[21:10]};                         // 52 + 12      = 64
         `Dtype:  SignExOut = {{55{Instruction[20]}}, Instruction[20:12]};         // 55 + 9       = 64
         `CBtype: SignExOut = {{43{Instruction[23]}}, Instruction[23:5], 2'b00};   // 43 + 19 + 2  = 64
         `Btype:  SignExOut = {{36{Instruction[25]}}, Instruction[25:0], 2'b00};   // 36 + 26 + 2  = 64
         `MOVZtype:
           case (Instruction[22:21])                                               // hw = which 16-bit slot
             2'b00:   SignExOut = {48'b0, Instruction[20:5]};                      // LSL 0
             2'b01:   SignExOut = {32'b0, Instruction[20:5], 16'b0};               // LSL 16
             2'b10:   SignExOut = {16'b0, Instruction[20:5], 32'b0};               // LSL 32
             default: SignExOut = {Instruction[20:5], 48'b0};                      // LSL 48
           endcase
         default: SignExOut = 64'b0;
       endcase
     end

endmodule
