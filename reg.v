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
