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
