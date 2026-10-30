`timescale 1ns / 1ps
`define AND   4'b0000  // These defines are not required but may be helpful.
`define OR    4'b0001
`define ADD   4'b0010
`define SUB   4'b0110
`define PassB 4'b0111

// 64-bit ALU for the ARMv8 single cycle datapath.
//
// How it works:
//  - The always @(*) block is a combinational case statement on ALUCtrl that
//    selects AND, OR, ADD, SUB or pass-B of the two 64-bit inputs.
//  - ADD and SUB wrap modulo 2^64 (the carry out is dropped), which is the
//    same result for signed and unsigned operands.
//  - The default arm drives 0, so BusW is assigned on every path (no latch).
//  - Zero is a continuous assign that is 1 whenever BusW is all 0s, for any
//    operation.
module ALU(
    output reg [63:0] BusW,
    input      [63:0] BusA,
    input      [63:0] BusB,
    input      [3:0]  ALUCtrl,
    output            Zero
);

   always @(*)
     begin
       case (ALUCtrl)
         `AND:    BusW = BusA & BusB;
         `OR:     BusW = BusA | BusB;
         `ADD:    BusW = BusA + BusB;
         `SUB:    BusW = BusA - BusB;
         `PassB:  BusW = BusB;
         default: BusW = 64'b0;
       endcase
     end

   assign Zero = (BusW == 64'b0);

endmodule
