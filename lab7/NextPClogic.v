`timescale 1ns / 1ps

// NextPC logic for the ARMv8 single cycle datapath.
//
// How it works:
//  - The mux select is (Branch & ALUZero) | Uncondbranch:
//      * B   sets Uncondbranch, so it always branches.
//      * CBZ sets Branch and only branches when the ALU (PassB of Rt) gives
//        Zero = 1.
//  - When the select is 1, NextPC = CurrentPC + SignExtImm64 (the sign
//    extender has already shifted the offset left by 2).
//  - Otherwise NextPC = CurrentPC + 4 (the next sequential instruction).
//  - Both adds are 64-bit and wrap modulo 2^64. Adding a sign-extended
//    negative offset in two's complement is the same as subtracting, so the
//    same unsigned adder handles forward and backward branches.
//  - NextPC is assigned on both branches of the if, so there is no latch.
module NextPClogic(
    output reg [63:0] NextPC,
    input  [63:0] CurrentPC,
    input  [63:0] SignExtImm64,
    input         Branch,
    input         ALUZero,
    input         Uncondbranch
);

   always @(*)
     begin
       if ((Branch & ALUZero) | Uncondbranch)
         NextPC = CurrentPC + SignExtImm64;
       else
         NextPC = CurrentPC + 64'd4;
     end

endmodule
