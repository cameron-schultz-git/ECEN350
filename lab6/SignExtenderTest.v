`timescale 1ns / 1ps

// Self-checking testbench for SignExtender.
//
// How it works:
//  - For every SignOp value it runs a few directed corner cases (all 0s,
//    all 1s, only the sign bit of the field set, everything outside the
//    field set) followed by NUM_RANDOM random Instruction[25:0] values.
//  - The expected value comes from a reference model that is written a
//    different way than the DUT: the field is placed at the top of a signed
//    64-bit register and arithmetic-shifted (>>>) back down, which sign
//    extends it, then multiplied by 4 for the branch types. I-Type is
//    simply a zero-extended copy of bits [21:10].
//  - Every mismatch prints an ERROR line; a summary is printed at the end.
//  - A VCD file (SignExtenderTest.vcd) is dumped for GTKWave.
module SignExtenderTest;

   parameter NUM_RANDOM = 100;

   reg  [25:0] Instruction;
   reg  [1:0]  SignOp;
   wire [63:0] SignExOut;

   reg signed [63:0] tmp;
   reg        [63:0] expected;
   integer           i, op, seed;
   integer           passed, failed;
   integer           opPassed [0:3];

   SignExtender uut (
       .SignExOut(SignExOut),
       .Instruction(Instruction),
       .SignOp(SignOp)
   );

   // Reference model
   function [63:0] refModel(input [1:0] sop, input [25:0] inst);
      reg signed [63:0] t;
      begin
         case (sop)
           2'b00: refModel = inst[21:10];                    // zero extend
           2'b01: begin t = {inst[20:12], 55'b0}; refModel = t >>> 55;       end
           2'b10: begin t = {inst[23:5],  45'b0}; refModel = (t >>> 45) * 4; end
           2'b11: begin t = {inst[25:0],  38'b0}; refModel = (t >>> 38) * 4; end
         endcase
      end
   endfunction

   task check;
      begin
         #1;
         expected = refModel(SignOp, Instruction);
         if (SignExOut !== expected)
           begin
              failed = failed + 1;
              $display("ERROR: SignOp=%b Instruction=%h  SignExOut=%h expected=%h",
                       SignOp, Instruction, SignExOut, expected);
           end
         else
           begin
              passed = passed + 1;
              opPassed[SignOp] = opPassed[SignOp] + 1;
           end
         #1;
      end
   endtask

   initial
     begin
        $dumpfile("SignExtenderTest.vcd");
        $dumpvars(0, SignExtenderTest);

        seed   = 350;
        passed = 0;
        failed = 0;
        for (op = 0; op < 4; op = op + 1)
          opPassed[op] = 0;

        for (op = 0; op < 4; op = op + 1)
          begin
             SignOp = op;

             // Directed corner cases
             Instruction = 26'h0000000; check;   // all zeros
             Instruction = 26'h3FFFFFF; check;   // all ones
             case (op)
               0: begin Instruction = 26'h0200000; check;     // only bit 21 (MSB of imm12)
                        Instruction = 26'h3C003FF; check; end // all ones outside [21:10]
               1: begin Instruction = 26'h0100000; check;     // only bit 20 (sign of imm9)
                        Instruction = 26'h00FF000; check;     // largest positive imm9
                        Instruction = 26'h3E00FFF; check; end // all ones outside [20:12]
               2: begin Instruction = 26'h0800000; check;     // only bit 23 (sign of imm19)
                        Instruction = 26'h07FFFE0; check;     // largest positive imm19
                        Instruction = 26'h300001F; check; end // all ones outside [23:5]
               3: begin Instruction = 26'h2000000; check;     // only bit 25 (sign of imm26)
                        Instruction = 26'h1FFFFFF; check; end // largest positive imm26
             endcase

             // Random tests
             for (i = 0; i < NUM_RANDOM; i = i + 1)
               begin
                  Instruction = $random(seed);
                  check;
               end
          end

        $display("SignExtender: I-Type  %0d passed", opPassed[0]);
        $display("SignExtender: D-Type  %0d passed", opPassed[1]);
        $display("SignExtender: CB-Type %0d passed", opPassed[2]);
        $display("SignExtender: B-Type  %0d passed", opPassed[3]);
        $display("SignExtender: %0d tests, %0d passed, %0d failed",
                 passed + failed, passed, failed);
        if (failed == 0)
          $display("ALL TESTS PASSED");
        $finish;
     end

endmodule
