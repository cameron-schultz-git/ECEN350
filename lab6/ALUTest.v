`timescale 1ns / 1ps

// Self-checking testbench for the 64-bit ALU.
//
// How it works:
//  - For each of the 5 functions it runs:
//      1. every combination of all 0s / all 1s on BusA and BusB (4 tests),
//      2. a directed test that must give Zero = 1 and one that must give
//         Zero = 0,
//      3. NUM_RANDOM random 64-bit BusA/BusB pairs.
//  - ADD also gets signed overflow (0x7FFF... + 1) and unsigned carry-out
//    (0xFFFF... + 1) tests.
//  - Expected results come from a reference model: ADD keeps a 65-bit sum
//    and drops the carry, SUB is computed as A + ~B + 1, Zero is recomputed
//    from the expected result. Any mismatch prints an ERROR line.
//  - The testbench also counts how many Zero=1 and Zero=0 results each
//    function produced and flags a coverage error if either count is 0.
//  - A VCD file (ALUTest.vcd) is dumped for GTKWave.
module ALUTest;

   parameter NUM_RANDOM = 100;

   reg  [63:0] BusA, BusB;
   reg  [3:0]  ALUCtrl;
   wire [63:0] BusW;
   wire        Zero;

   reg  [63:0] expW;
   reg         expZ;
   reg  [64:0] sum65;
   reg  [3:0]  ops [0:4];
   reg  [47:0] names [0:4];
   integer     i, k, a, b, seed;
   integer     passed, failed;
   integer     zeroHi [0:4], zeroLo [0:4], opPassed [0:4];

   ALU uut (
       .BusW(BusW),
       .BusA(BusA),
       .BusB(BusB),
       .ALUCtrl(ALUCtrl),
       .Zero(Zero)
   );

   task check;
      begin
         #1;
         case (ALUCtrl)
           4'b0000: expW = BusA & BusB;
           4'b0001: expW = BusA | BusB;
           4'b0010: begin sum65 = {1'b0, BusA} + {1'b0, BusB}; expW = sum65[63:0]; end
           4'b0110: expW = BusA + ~BusB + 64'd1;
           4'b0111: expW = BusB;
           default: expW = 64'b0;
         endcase
         expZ = (expW == 64'b0);

         if ((BusW !== expW) || (Zero !== expZ))
           begin
              failed = failed + 1;
              $display("ERROR: %0s A=%h B=%h  BusW=%h Zero=%b  expected BusW=%h Zero=%b",
                       names[k], BusA, BusB, BusW, Zero, expW, expZ);
           end
         else
           begin
              passed = passed + 1;
              opPassed[k] = opPassed[k] + 1;
              if (Zero) zeroHi[k] = zeroHi[k] + 1;
              else      zeroLo[k] = zeroLo[k] + 1;
           end
         #1;
      end
   endtask

   initial
     begin
        $dumpfile("ALUTest.vcd");
        $dumpvars(0, ALUTest);

        ops[0] = 4'b0000; names[0] = "AND";
        ops[1] = 4'b0001; names[1] = "OR";
        ops[2] = 4'b0010; names[2] = "ADD";
        ops[3] = 4'b0110; names[3] = "SUB";
        ops[4] = 4'b0111; names[4] = "PassB";

        seed   = 350;
        passed = 0;
        failed = 0;
        for (k = 0; k < 5; k = k + 1)
          begin
             zeroHi[k] = 0; zeroLo[k] = 0; opPassed[k] = 0;
          end

        for (k = 0; k < 5; k = k + 1)
          begin
             ALUCtrl = ops[k];

             // 1. All combinations of all zeros / all ones
             for (a = 0; a < 2; a = a + 1)
               for (b = 0; b < 2; b = b + 1)
                 begin
                    BusA = a ? {64{1'b1}} : 64'b0;
                    BusB = b ? {64{1'b1}} : 64'b0;
                    check;
                 end

             // 2. Directed Zero = 1 and Zero = 0 tests
             case (k)
               0: begin BusA = 64'hF0F0_F0F0_F0F0_F0F0; BusB = 64'h0F0F_0F0F_0F0F_0F0F; check;   // AND -> 0
                        BusA = 64'hF0F0_F0F0_F0F0_F0F0; BusB = 64'h1000_0000_0000_0001; check; end
               1: begin BusA = 64'h0;                   BusB = 64'h0;                   check;   // OR  -> 0
                        BusA = 64'h0;                   BusB = 64'h8000_0000_0000_0000; check; end
               2: begin BusA = 64'h0000_0000_0000_0005; BusB = 64'hFFFF_FFFF_FFFF_FFFB; check;   // 5 + -5 = 0
                        BusA = 64'h0000_0000_0000_0005; BusB = 64'h0000_0000_0000_0003; check;   // 5 + 3 = 8
                        // Overflow tests
                        BusA = 64'h7FFF_FFFF_FFFF_FFFF; BusB = 64'h1;                   check;   // signed overflow -> 0x8000...
                        BusA = 64'h8000_0000_0000_0000; BusB = 64'h8000_0000_0000_0000; check;   // signed overflow, carry out -> 0
                        BusA = 64'hFFFF_FFFF_FFFF_FFFF; BusB = 64'h1;                   check; end // unsigned carry out -> 0
               3: begin BusA = 64'h1234_5678_9ABC_DEF0; BusB = 64'h1234_5678_9ABC_DEF0; check;   // A - A = 0
                        BusA = 64'h0;                   BusB = 64'h1;                   check; end // 0 - 1 = 0xFFFF...
               4: begin BusA = 64'hDEAD_BEEF_DEAD_BEEF; BusB = 64'h0;                   check;   // pass 0
                        BusA = 64'h0;                   BusB = 64'hCAFE_F00D_CAFE_F00D; check; end
             endcase

             // 3. Random tests
             for (i = 0; i < NUM_RANDOM; i = i + 1)
               begin
                  BusA = {$random(seed), $random(seed)};
                  BusB = {$random(seed), $random(seed)};
                  check;
               end
          end

        for (k = 0; k < 5; k = k + 1)
          begin
             $display("ALU %0s: %0d passed (Zero=1: %0d, Zero=0: %0d)",
                      names[k], opPassed[k], zeroHi[k], zeroLo[k]);
             if (zeroHi[k] == 0 || zeroLo[k] == 0)
               begin
                  failed = failed + 1;
                  $display("ERROR: %0s did not cover both Zero=1 and Zero=0", names[k]);
               end
          end
        $display("ALU: %0d tests, %0d passed, %0d failed", passed + failed, passed, failed);
        if (failed == 0)
          $display("ALL TESTS PASSED");
        $finish;
     end

endmodule
