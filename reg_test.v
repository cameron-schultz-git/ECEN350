`timescale 1ns / 1ps

module RegisterFile_tb();   // no ports

   reg  [63:0] BusW;
   reg  [4:0]  RA;
   reg  [4:0]  RB;
   reg  [4:0]  RW;
   reg         RegWr;
   reg         Clk;
   wire [63:0] BusA;
   wire [63:0] BusB;

   reg  [63:0] model [0:31];   // what each register should currently hold
   reg  [63:0] value;
   integer     r;
   integer     errors;
   integer     seed;

   // Device under test
   RegisterFile DUT (
      .BusA(BusA),
      .BusB(BusB),
      .BusW(BusW),
      .RA(RA),
      .RB(RB),
      .RW(RW),
      .RegWr(RegWr),
      .Clk(Clk)
   );

   initial // dump all wire/reg values to the VCD file
     begin
       $dumpfile("RegisterFile_tb.vcd");
       $dumpvars(0, RegisterFile_tb);
     end

   // Clock: period of 20 ticks
   initial Clk = 1'b1;
   always #10 Clk = ~Clk;

   // Attempt a write and let one negative clock edge pass
   task do_write;
      input [4:0]  reg_num;
      input [63:0] data;
      input        enable;
      begin
        RW    = reg_num;
        BusW  = data;
        RegWr = enable;
        @(negedge Clk);              // the register file writes on this edge
        #1 RegWr = 1'b0;
        if (enable && (reg_num != 5'd31))
          model[reg_num] = data;     // only update the model if the write should happen
        $display("t=%0t  WRITE  RW=%0d BusW=%h RegWr=%b", $time, reg_num, data, enable);
      end
   endtask

   // Read registers on both ports and compare with the model
   task check_read;
      input [4:0] reg_a;
      input [4:0] reg_b;
      reg   [63:0] expA;
      reg   [63:0] expB;
      begin
        RA = reg_a;
        RB = reg_b;
        #5;                          // longer than the #3 output delay
        expA = (reg_a == 5'd31) ? 64'd0 : model[reg_a];
        expB = (reg_b == 5'd31) ? 64'd0 : model[reg_b];
        $display("t=%0t  READ   RA=%0d BusA=%h (exp %h) | RB=%0d BusB=%h (exp %h)",
                 $time, reg_a, BusA, expA, reg_b, BusB, expB);
        if (BusA !== expA)
          begin
            errors = errors + 1;
            $display("  ERROR: BusA for X%0d is %h, expected %h", reg_a, BusA, expA);
          end
        if (BusB !== expB)
          begin
            errors = errors + 1;
            $display("  ERROR: BusB for X%0d is %h, expected %h", reg_b, BusB, expB);
          end
      end
   endtask

   initial
     begin
       errors = 0;
       seed   = 350;
       RegWr  = 1'b0;
       RW     = 5'd0;
       RA     = 5'd0;
       RB     = 5'd0;
       BusW   = 64'd0;

       // XZR must read 0 even before anything has been written
       check_read(5'd31, 5'd31);

       for (r = 0; r < 32; r = r + 1)
         begin
           // Write enable ON: the random value should be stored
           value = {$random(seed), $random(seed)};
           do_write(r, value, 1'b1);
           check_read(r, r);

           // Write enable OFF: a new random value must NOT be stored
           value = {$random(seed), $random(seed)};
           do_write(r, value, 1'b0);
           check_read(r, r);
         end

       // Final sweep: no register was disturbed by writes to other registers
       for (r = 0; r < 32; r = r + 1)
         check_read(r, 31 - r);

       if (errors == 0)
         $display("PASSED: all register file checks were correct.");
       else
         $display("FAILED: %0d register file checks were incorrect.", errors);

       $finish;
     end

endmodule
