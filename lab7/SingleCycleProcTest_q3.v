`timescale 1ns / 1ps
// Lab 7 Q3 version of SingleCycleProcTest.v: adds the MOVZ instruction. The prelab version is SingleCycleProcTest.v.

`define STRLEN 32
`define HalfClockPeriod 60
`define ClockPeriod `HalfClockPeriod * 2

module SingleCycleProcTest_v;

   initial
     begin
        $dumpfile("singlecycle_q3.vcd");
        $dumpvars;
     end

   // These tasks are used to check if a given test has passed and
   // confirm that all tests passed.
   task passTest;
      input [63:0] actualOut, expectedOut;
      input [`STRLEN*8:0] testType;
      inout [7:0] 	  passed;

      if(actualOut == expectedOut) begin $display ("%s passed", testType); passed = passed + 1; end
      else $display ("%s failed: 0x%x should be 0x%x", testType, actualOut, expectedOut);
   endtask

   task allPassed;
      input [7:0] passed;
      input [7:0] numTests;

      if(passed == numTests) $display ("All tests passed");
      else $display("Some tests failed: %d of %d passed", passed, numTests);
   endtask

   // Inputs
   reg 		  CLK;
   reg		  Reset;
   reg [63:0] 	  startPC;
   reg [7:0] 	  passed;
   reg [15:0] 	  watchdog;

   // Outputs
   wire [63:0] 	  MemtoRegOut;
   wire [63:0] 	  currentPC;

   // Instantiate the Unit Under Test (UUT)
   SingleCycleProc uut (   // FIXED: handout said "singlecycle", but the module is named SingleCycleProc
		    .CLK(CLK),
		    .reset(Reset),
		    .startpc(startPC),
		    .currentpc(currentPC),
		    .MemtoRegOut(MemtoRegOut)
		    );

   initial begin
      // Initialize Inputs
      Reset = 0;
      startPC = 0;
      passed = 0;

      // Initialize Watchdog timer
      watchdog = 0;

      // Wait for global reset
      #(1 * `ClockPeriod);

      // Program 1
      #1
        Reset = 1; startPC = 0;
      @(posedge CLK);
      @(negedge CLK);
      @(posedge CLK);
      Reset = 0;

      // ***********************************************************
      // This while loop will continue cycling the processor until the
      // PC reaches the final instruction in the first test.  If the
      // program forms an infinite loop, never reaching the end, the
      // watchdog timer will kick in and kill simulation after 64K
      // cycles.
      // ***********************************************************

      while (currentPC < 64'h30)
        begin
	   @(posedge CLK);
	   @(negedge CLK);
           $display("CurrentPC:%h",currentPC);
        end
      passTest(MemtoRegOut, 64'hF, "Results of Program 1", passed);

      // ***********************************************************
      // Add your new tests here
      // ***********************************************************

      // Program 2 (Lab 7): MOVZ test, starts at 0x34 after Program 1.
      // Reset the processor with startPC = 0x34, the same way Program 1 starts.
      #1
        Reset = 1; startPC = 64'h34;
      @(posedge CLK);
      @(negedge CLK);
      @(posedge CLK);
      Reset = 0;

      // Run up to the last ORR (0x4C). Its ALU result is the finished X9.
      while (currentPC < 64'h4c)
        begin
	   @(posedge CLK);
	   @(negedge CLK);
           $display("CurrentPC:%h",currentPC);
        end
      passTest(MemtoRegOut, 64'h123456789abcdef0, "Program 2: X9 built by MOVZ", passed);

      // Run up to the LDUR (0x54). MemtoRegOut is the value loaded back
      // from address 0x28, so it only matches if the STUR at 0x50 worked.
      while (currentPC < 64'h54)
        begin
	   @(posedge CLK);
	   @(negedge CLK);
           $display("CurrentPC:%h",currentPC);
        end
      passTest(MemtoRegOut, 64'h123456789abcdef0, "Program 2: X10 loaded from 0x28", passed);

      // Done
      allPassed(passed, 3);   // Program 1 (1 test) + Program 2 (2 tests)
      $finish;
   end

   // Initialize the clock to be 0
   initial begin
      CLK = 0;
   end

   // The following is correct if clock starts at LOW level at StartTime //
   always begin
      #`HalfClockPeriod CLK = ~CLK;
      #`HalfClockPeriod CLK = ~CLK;
      watchdog = watchdog +1;
   end

   // Kill the simulation if the watchdog hits 64K cycles
   always @*
     if (watchdog == 16'hFF)
       begin
          $display("Watchdog Timer Expired.");
          $finish;
       end


endmodule

