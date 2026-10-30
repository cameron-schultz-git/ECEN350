`timescale 1ns / 1ps

// =============================================================================
// SingleCycleControlTest  -  self-checking testbench for SC_Control
// =============================================================================
//
// What this testbench does:
//   1. For every instruction the control unit supports, it tries EVERY
//      possible value of that opcode's don't-care bits.
//      (LDUR, STUR, ADD, SUB, AND, ORR = 1 opcode each,
//       ADDI and SUBI = 2 each, CBZ = 8, B = 32.)
//   2. It tries a few hand-picked opcodes that are NOT supported
//      (all 0s, all 1s, MOVZ, CBNZ, and an opcode one bit away from LDUR).
//   3. It tries 10 random opcodes that do not match any supported
//      instruction. For all of these, every control output must be 0.
//
// How each test is checked:
//   - Before each test we write down the expected value of every control
//     signal (the truth table row) in the "exp_" variables.
//   - An expected value of x means "don't care". Those signals are skipped,
//     because any value is correct there.
//   - Every other signal must match exactly. A mismatch prints an ERROR line
//     that names the instruction, the opcode, and the signal that was wrong.
//
// A VCD waveform file (SingleCycleControlTest.vcd) is written for GTKWave.
// =============================================================================

module SingleCycleControlTest;

   // How many random unsupported opcodes to test (the prelab asks for 10).
   parameter NUM_RANDOM = 10;

   // ---------------------------------------------------------------
   // Signals connected to the control unit
   // ---------------------------------------------------------------
   reg  [10:0] opcode;        // input we drive (reg, because the testbench assigns it)

   wire        Reg2Loc;       // outputs we read (wire, because the control unit drives them)
   wire        ALUSrc;
   wire        MemtoReg;
   wire        RegWrite;
   wire        MemRead;
   wire        MemWrite;
   wire        Branch;
   wire        Uncondbranch;
   wire [3:0]  ALUOp;
   wire [1:0]  SignOp;

   // ---------------------------------------------------------------
   // Expected values for the current test (one per control signal)
   // ---------------------------------------------------------------
   reg         exp_Reg2Loc;
   reg         exp_ALUSrc;
   reg         exp_MemtoReg;
   reg         exp_RegWrite;
   reg         exp_MemRead;
   reg         exp_MemWrite;
   reg         exp_Branch;
   reg         exp_Uncondbranch;
   reg  [3:0]  exp_ALUOp;
   reg  [1:0]  exp_SignOp;

   // ---------------------------------------------------------------
   // Bookkeeping
   // ---------------------------------------------------------------
   integer     dc;             // loop counter for the don't-care bits
   integer     numRandom;      // how many random unsupported opcodes tested so far
   integer     seed;           // seed for $random so every run is the same
   integer     passed;         // number of tests that passed
   integer     failed;         // number of tests that failed
   reg         testOK;         // 1 while the current test has no errors
   reg  [10:0] randomOpcode;   // a random opcode candidate

   // ---------------------------------------------------------------
   // The unit under test (uut)
   // ---------------------------------------------------------------
   SC_Control uut (
       .Reg2Loc(Reg2Loc),
       .ALUSrc(ALUSrc),
       .MemtoReg(MemtoReg),
       .RegWrite(RegWrite),
       .MemRead(MemRead),
       .MemWrite(MemWrite),
       .Branch(Branch),
       .Uncondbranch(Uncondbranch),
       .ALUOp(ALUOp),
       .SignOp(SignOp),
       .opcode(opcode)
   );

   // ---------------------------------------------------------------
   // Task: setExpected
   // Stores one row of the truth table in the exp_ variables.
   // Pass x for a signal that is a don't care.
   // ---------------------------------------------------------------
   task setExpected;
      input       r2l;
      input       aluSrc;
      input       m2r;
      input       regWr;
      input       memRd;
      input       memWr;
      input       br;
      input       ubr;
      input [3:0] aluOp;
      input [1:0] signOp;
      begin
         exp_Reg2Loc      = r2l;
         exp_ALUSrc       = aluSrc;
         exp_MemtoReg     = m2r;
         exp_RegWrite     = regWr;
         exp_MemRead      = memRd;
         exp_MemWrite     = memWr;
         exp_Branch       = br;
         exp_Uncondbranch = ubr;
         exp_ALUOp        = aluOp;
         exp_SignOp       = signOp;
      end
   endtask

   // ---------------------------------------------------------------
   // Task: compare1
   // Compares one 1-bit signal against its expected value.
   // Skips the check when the expected value is x (don't care).
   // !== is used (not !=) so that an x or z coming out of the control
   // unit counts as a mismatch instead of being ignored.
   // ---------------------------------------------------------------
   task compare1;
      input [8*12-1:0] signalName;   // up to 12 characters of text
      input            actual;
      input            expected;
      begin
         if (expected !== 1'bx)
           begin
              if (actual !== expected)
                begin
                   $display("    %0s = %b, expected %b", signalName, actual, expected);
                   testOK = 0;
                end
           end
      end
   endtask

   // ---------------------------------------------------------------
   // Task: checkOutputs
   // Waits for the control unit to settle, then checks all 10 signals.
   // ---------------------------------------------------------------
   task checkOutputs;
      input [8*12-1:0] instrName;    // name to print if the test fails
      begin
         #1;            // give the combinational logic time to update
         testOK = 1;    // assume the test passes until a signal is wrong

         compare1("Reg2Loc",      Reg2Loc,      exp_Reg2Loc);
         compare1("ALUSrc",       ALUSrc,       exp_ALUSrc);
         compare1("MemtoReg",     MemtoReg,     exp_MemtoReg);
         compare1("RegWrite",     RegWrite,     exp_RegWrite);
         compare1("MemRead",      MemRead,      exp_MemRead);
         compare1("MemWrite",     MemWrite,     exp_MemWrite);
         compare1("Branch",       Branch,       exp_Branch);
         compare1("Uncondbranch", Uncondbranch, exp_Uncondbranch);

         // ALUOp is 4 bits. It is either fully known or fully don't care.
         if (exp_ALUOp !== 4'bxxxx)
           begin
              if (ALUOp !== exp_ALUOp)
                begin
                   $display("    ALUOp = %b, expected %b", ALUOp, exp_ALUOp);
                   testOK = 0;
                end
           end

         // SignOp is 2 bits. It is either fully known or fully don't care.
         if (exp_SignOp !== 2'bxx)
           begin
              if (SignOp !== exp_SignOp)
                begin
                   $display("    SignOp = %b, expected %b", SignOp, exp_SignOp);
                   testOK = 0;
                end
           end

         // Count the result
         if (testOK == 1)
           begin
              passed = passed + 1;
           end
         else
           begin
              failed = failed + 1;
              $display("ERROR: %0s opcode=%b failed (wrong signals listed above)", instrName, opcode);
           end

         #1;            // small gap so each test is easy to see in GTKWave
      end
   endtask

   // ---------------------------------------------------------------
   // Function: isSupported
   // Returns 1 if the opcode belongs to an instruction the control unit
   // handles. Written with bit slices instead of casez, so it does not
   // share any mistake with the design.
   // ---------------------------------------------------------------
   function isSupported;
      input [10:0] op;
      begin
         isSupported = 0;
         if (op == 11'b11111000010)        isSupported = 1;   // LDUR
         if (op == 11'b11111000000)        isSupported = 1;   // STUR
         if (op == 11'b10001011000)        isSupported = 1;   // ADD
         if (op == 11'b11001011000)        isSupported = 1;   // SUB
         if (op == 11'b10001010000)        isSupported = 1;   // AND
         if (op == 11'b10101010000)        isSupported = 1;   // ORR
         if (op[10:1] == 10'b1001000100)   isSupported = 1;   // ADDI (last bit is don't care)
         if (op[10:1] == 10'b1101000100)   isSupported = 1;   // SUBI (last bit is don't care)
         if (op[10:3] == 8'b10110100)      isSupported = 1;   // CBZ  (last 3 bits are don't care)
         if (op[10:5] == 6'b000101)        isSupported = 1;   // B    (last 5 bits are don't care)
      end
   endfunction

   // ---------------------------------------------------------------
   // The tests
   // ---------------------------------------------------------------
   initial
     begin
        // Waveform file for GTKWave
        $dumpfile("SingleCycleControlTest.vcd");
        $dumpvars(0, SingleCycleControlTest);

        passed = 0;
        failed = 0;
        seed   = 350;      // fixed seed -> the same "random" opcodes every run
        opcode = 11'b0;

        // Order of arguments to setExpected:
        //   Reg2Loc, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite,
        //   Branch, Uncondbranch, ALUOp, SignOp

        // ---------------- LDUR (no don't-care bits) ----------------
        setExpected(1'bx, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 4'b0010, 2'b01);
        opcode = 11'b11111000010;
        checkOutputs("LDUR");

        // ---------------- STUR (no don't-care bits) ----------------
        setExpected(1'b1, 1'b1, 1'bx, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 4'b0010, 2'b01);
        opcode = 11'b11111000000;
        checkOutputs("STUR");

        // ---------------- ADD (no don't-care bits) -----------------
        setExpected(1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0010, 2'bxx);
        opcode = 11'b10001011000;
        checkOutputs("ADD");

        // ---------------- SUB register (no don't-care bits) --------
        setExpected(1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0110, 2'bxx);
        opcode = 11'b11001011000;
        checkOutputs("SUB");

        // ---------------- AND (no don't-care bits) -----------------
        setExpected(1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0000, 2'bxx);
        opcode = 11'b10001010000;
        checkOutputs("AND");

        // ---------------- ORR (no don't-care bits) -----------------
        setExpected(1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0001, 2'bxx);
        opcode = 11'b10101010000;
        checkOutputs("ORR");

        // ---------------- ADDI (1 don't-care bit -> 2 opcodes) -----
        setExpected(1'bx, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0010, 2'b00);
        for (dc = 0; dc < 2; dc = dc + 1)
          begin
             opcode = {10'b1001000100, dc[0]};    // fixed 10 bits + 1 don't-care bit
             checkOutputs("ADDI");
          end

        // ---------------- SUBI (1 don't-care bit -> 2 opcodes) -----
        setExpected(1'bx, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0110, 2'b00);
        for (dc = 0; dc < 2; dc = dc + 1)
          begin
             opcode = {10'b1101000100, dc[0]};    // fixed 10 bits + 1 don't-care bit
             checkOutputs("SUBI");
          end

        // ---------------- CBZ (3 don't-care bits -> 8 opcodes) -----
        setExpected(1'b1, 1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 4'b0111, 2'b10);
        for (dc = 0; dc < 8; dc = dc + 1)
          begin
             opcode = {8'b10110100, dc[2:0]};     // fixed 8 bits + 3 don't-care bits
             checkOutputs("CBZ");
          end

        // ---------------- B (5 don't-care bits -> 32 opcodes) ------
        setExpected(1'bx, 1'bx, 1'bx, 1'b0, 1'b0, 1'b0, 1'bx, 1'b1, 4'bxxxx, 2'b11);
        for (dc = 0; dc < 32; dc = dc + 1)
          begin
             opcode = {6'b000101, dc[4:0]};       // fixed 6 bits + 5 don't-care bits
             checkOutputs("B");
          end

        // ---------------- Hand-picked unsupported opcodes ----------
        // Every output must be 0.
        setExpected(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0000, 2'b00);

        opcode = 11'b00000000000;   // all zeros
        checkOutputs("BAD all0");

        opcode = 11'b11111111111;   // all ones
        checkOutputs("BAD all1");

        opcode = 11'b11010010100;   // MOVZ (defined, but not supported by this datapath)
        checkOutputs("BAD MOVZ");

        opcode = 11'b10110101000;   // CBNZ (one bit away from CBZ)
        checkOutputs("BAD CBNZ");

        opcode = 11'b11111000011;   // one bit away from LDUR
        checkOutputs("BAD ~LDUR");

        // ---------------- 10 random unsupported opcodes -----------
        // Keep drawing random opcodes, skip any that happen to be a
        // supported instruction, until NUM_RANDOM bad ones have been tested.
        numRandom = 0;
        while (numRandom < NUM_RANDOM)
          begin
             randomOpcode = $random(seed);    // $random gives 32 bits; only the low 11 are kept
             if (isSupported(randomOpcode) == 0)
               begin
                  opcode = randomOpcode;
                  checkOutputs("BAD random");
                  numRandom = numRandom + 1;
               end
          end

        // ---------------- Summary ----------------
        $display("SC_Control: %0d tests, %0d passed, %0d failed", passed + failed, passed, failed);
        if (failed == 0)
          $display("ALL TESTS PASSED");
        else
          $display("SOME TESTS FAILED");

        $finish;
     end

endmodule
