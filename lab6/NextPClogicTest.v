`timescale 1ns / 1ps

// Self-checking testbench for NextPClogic.
//
// How it works:
//  - Loops over all 8 combinations of {Branch, Uncondbranch, ALUZero} and
//    runs NUM_RANDOM random CurrentPC / SignExtImm64 pairs for each.
//  - The expected mux select is looked up from the Prelab Q7 truth table
//    (not recomputed from the same boolean equation as the DUT), then the
//    expected NextPC is CurrentPC + SignExtImm64 or CurrentPC + 4.
//  - Directed tests also check backward branches and wrap-around at the
//    top and bottom of the 64-bit address space.
//  - Every mismatch prints an ERROR line; a summary is printed at the end.
//  - A VCD file (NextPClogicTest.vcd) is dumped for GTKWave.
module NextPClogicTest;

   parameter NUM_RANDOM = 10;

   reg  [63:0] CurrentPC, SignExtImm64;
   reg         Branch, ALUZero, Uncondbranch;
   wire [63:0] NextPC;

   reg  [7:0]  selTable;   // selTable[{Branch,Uncondbranch,ALUZero}] = mux select
   reg  [63:0] expected;
   reg         expSel;
   integer     c, i, seed;
   integer     passed, failed;
   integer     comboPassed [0:7];

   NextPClogic uut (
       .NextPC(NextPC),
       .CurrentPC(CurrentPC),
       .SignExtImm64(SignExtImm64),
       .Branch(Branch),
       .ALUZero(ALUZero),
       .Uncondbranch(Uncondbranch)
   );

   task check;
      begin
         #1;
         expSel   = selTable[{Branch, Uncondbranch, ALUZero}];
         expected = expSel ? (CurrentPC + SignExtImm64) : (CurrentPC + 64'd4);
         if (NextPC !== expected)
           begin
              failed = failed + 1;
              $display("ERROR: B=%b UB=%b Z=%b PC=%h Imm=%h  NextPC=%h expected=%h",
                       Branch, Uncondbranch, ALUZero, CurrentPC, SignExtImm64, NextPC, expected);
           end
         else
           begin
              passed = passed + 1;
              comboPassed[{Branch, Uncondbranch, ALUZero}] = comboPassed[{Branch, Uncondbranch, ALUZero}] + 1;
           end
         #1;
      end
   endtask

   initial
     begin
        $dumpfile("NextPClogicTest.vcd");
        $dumpvars(0, NextPClogicTest);

        // Truth table from Prelab Q7, index = {Branch, Uncondbranch, ALUZero}
        //            111 110 101 100 011 010 001 000
        selTable = 8'b1___1___1___0___1___1___0___0;

        seed   = 350;
        passed = 0;
        failed = 0;
        for (c = 0; c < 8; c = c + 1)
          comboPassed[c] = 0;

        // Random tests: NUM_RANDOM per control combination
        for (c = 0; c < 8; c = c + 1)
          begin
             {Branch, Uncondbranch, ALUZero} = c;
             for (i = 0; i < NUM_RANDOM; i = i + 1)
               begin
                  CurrentPC    = {$random(seed), $random(seed)};
                  SignExtImm64 = {$random(seed), $random(seed)};
                  check;
               end
          end

        // Directed tests
        {Branch, Uncondbranch, ALUZero} = 3'b010;                                  // B, backward
        CurrentPC = 64'h0000_0000_0000_0100; SignExtImm64 = 64'hFFFF_FFFF_FFFF_FFF0; check; // 0x100 - 16 = 0xF0
        {Branch, Uncondbranch, ALUZero} = 3'b101;                                  // CBZ taken, forward
        CurrentPC = 64'h0000_0000_0000_0100; SignExtImm64 = 64'h0000_0000_0000_0040; check; // 0x100 + 64 = 0x140
        {Branch, Uncondbranch, ALUZero} = 3'b100;                                  // CBZ not taken
        CurrentPC = 64'h0000_0000_0000_0100; SignExtImm64 = 64'h0000_0000_0000_0040; check; // 0x104
        {Branch, Uncondbranch, ALUZero} = 3'b000;                                  // PC+4 wraps at top
        CurrentPC = 64'hFFFF_FFFF_FFFF_FFFC; SignExtImm64 = 64'h0;                   check; // -> 0x0
        {Branch, Uncondbranch, ALUZero} = 3'b010;                                  // backward branch below 0
        CurrentPC = 64'h0000_0000_0000_0004; SignExtImm64 = 64'hFFFF_FFFF_FFFF_FFF8; check; // -> 0xFFFF...FFFC
        {Branch, Uncondbranch, ALUZero} = 3'b010;                                  // forward branch past top
        CurrentPC = 64'hFFFF_FFFF_FFFF_FFF0; SignExtImm64 = 64'h0000_0000_0000_0020; check; // -> 0x10

        for (c = 0; c < 8; c = c + 1)
          $display("NextPC: Branch=%b Uncondbranch=%b ALUZero=%b  sel=%b  %0d passed",
                   c[2], c[1], c[0], selTable[c], comboPassed[c]);
        $display("NextPC: %0d tests, %0d passed, %0d failed", passed + failed, passed, failed);
        if (failed == 0)
          $display("ALL TESTS PASSED");
        $finish;
     end

endmodule
