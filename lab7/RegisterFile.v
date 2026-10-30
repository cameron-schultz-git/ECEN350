`timescale 1ns / 1ps
// Question 6 (30 pts)
// Synthesizable behavioral 32 x 64-bit register file for ARMv8
// (ARMv8 has 32 registers, X0-X31, each 64 bits wide; X31 is XZR).
//
// How it works:
//  - registers is an array of 32 64-bit registers (the state elements).
//  - Reads are combinational: BusA/BusB continuously show the register
//    selected by RA/RB, with a #3 delay on the outputs. If the register
//    number is 31 (XZR) the output is forced to 0, no matter what is stored.
//  - Writes are sequential: on the negative edge of Clk, if RegWr is 1 the
//    value on BusW is stored into register RW using a non-blocking (<=)
//    assignment. Writes to register 31 are dropped by the RW != 31 check, so
//    XZR is handled without any initial block, keeping the design synthesizable.
module RegisterFile(
    output wire [63:0] BusA,
    output wire [63:0] BusB,
    input  wire [63:0] BusW,
    input  wire [4:0]  RA,
    input  wire [4:0]  RB,
    input  wire [4:0]  RW,
    input  wire        RegWr,
    input  wire        Clk
);

   reg [63:0] registers [31:0];

   // Read ports (combinational). XZR always reads as 0.
   assign #3 BusA = (RA == 5'd31) ? 64'd0 : registers[RA];
   assign #3 BusB = (RB == 5'd31) ? 64'd0 : registers[RB];

   // Write port (sequential). Writes to XZR are ignored.
   always @(negedge Clk)
     begin
       if (RegWr && (RW != 5'd31))
         registers[RW] <= BusW;
     end

endmodule
