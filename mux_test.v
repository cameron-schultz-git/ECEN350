`timescale 1ns / 1ps

module mux2to1_8_tb();   // no ports

   reg  [7:0] in0;
   reg  [7:0] in1;
   reg        sel;
   wire [7:0] out;

   reg  [7:0] expected;
   integer    i;
   integer    errors;

   // Device under test
   mux2to1_8 DUT (
      .in0(in0),
      .in1(in1),
      .sel(sel),
      .out(out)
   );

   initial // dump all wire/reg values to the VCD file
     begin
       $dumpfile("mux2to1_8_tb.vcd");
       $dumpvars(0, mux2to1_8_tb);
     end

   initial
     begin
       errors = 0;

       for (i = 0; i < (1 << 17); i = i + 1)
         begin
           {sel, in1, in0} = i[16:0];   // apply stimulus
           #5;                          // let the outputs settle

           expected = sel ? in1 : in0;

           $display("t=%0t  sel=%b in0=%h in1=%h  -> out=%h (expected %h)",
                    $time, sel, in0, in1, out, expected);

           if (out !== expected)
             begin
               errors = errors + 1;
               $display("  ERROR: mismatch for sel=%b in0=%h in1=%h: got %h, expected %h",
                        sel, in0, in1, out, expected);
             end
         end

       if (errors == 0)
         $display("PASSED: all %0d input combinations produced the correct output.", i);
       else
         $display("FAILED: %0d of %0d input combinations were incorrect.", errors, i);

       $finish;
     end

endmodule
