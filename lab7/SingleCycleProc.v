`timescale 1ns / 1ps

// =============================================================================
// SingleCycleProc  -  top level of the single cycle ARMv8 processor
// =============================================================================
//
// What this module does:
//   It connects every piece of the processor together, exactly like the
//   datapath figure in the prelab:
//     PC -> Instruction Memory -> Control + Register File + Sign Extender
//        -> ALU -> Data Memory -> MemtoReg mux -> back into the Register File
//   and the NextPC logic picks the address of the next instruction.
//
// "Single cycle" means every instruction is fetched, decoded, executed and
// finished in ONE clock cycle. The only things that change on a clock edge
// are the state elements: the PC, the register file and the data memory.
// Everything in between is combinational logic that settles during the cycle.
//
// Modules used (each in its own .v file in this folder):
//   InstructionMemory  (given)        DataMemory    (given)
//   SC_Control         (this prelab)  RegisterFile  (Lab 5)
//   SignExtender, ALU, NextPClogic    (Lab 6)
// =============================================================================

module SingleCycleProc(
		   input	     reset, //Active High
		   input [63:0]	     startpc,
		   output reg [63:0] currentpc,
		   output [63:0]     MemtoRegOut, // this should be
						   // attached to the
						   // output of the
						   // MemtoReg Mux
		   input	     CLK
		   );

   // Next PC connections
   wire [63:0] 			     nextpc;       // The next PC, to be updated on clock cycle

   // Instruction Memory connections
   wire [31:0] 			     instruction;  // The current instruction

   // Parts of instruction
   // NOTE: these names come from the handout. In ARMv8 terms, "rm" below
   // holds Rn (bits 9:5, the first source register) and "rn" holds the
   // output of the Reg2Loc mux (either Rm or Rt). They are just labels.
   wire [4:0] 			     rd;            // The destination register
   wire [4:0] 			     rm;            // Operand 1
   wire [4:0] 			     rn;            // Operand 2
   wire [10:0] 			     opcode;

   // Control wires
   wire 			     Reg2Loc;
   wire 			     ALUSrc;
   wire 			     MemtoReg;
   wire 			     RegWrite;
   wire 			     MemRead;
   wire 			     MemWrite;
   wire 			     Branch;
   wire 			     Uncondbranch;
   wire [3:0] 			     ALUOp;        // FIXED: the handout declared this as "ALUop" (lower-case p)
                                                   // but connected "ALUOp". Verilog would have silently made a
                                                   // new 1-bit wire, so only 1 of the 4 ALUOp bits would reach the ALU.
   wire [1:0] 			     SignOp;

   // Register file connections
   wire [63:0] 			     regoutA;     // Output A
   wire [63:0] 			     regoutB;     // Output B

   // ALU connections
   wire [63:0] 			     aluout;
   wire 			     zero;

   // Sign Extender connections
   wire [63:0] 			     extimm;

   // ADDED: wires for the parts the handout left out
   wire [63:0] 			     aluinB;      // ALU input B = output of the ALUSrc mux
   wire [63:0] 			     dmemout;     // data read out of the data memory

   // PC update logic
   // On every rising clock edge the PC moves to the next instruction.
   // While reset is 1 the PC is loaded with startpc instead.
   always @(posedge CLK)
     begin
        if (reset)
          currentpc <= #3 startpc;
        else
          currentpc <= #3 nextpc;
     end

   // Parts of instruction
   assign rd = instruction[4:0];                                  // Rd / Rt: register to write (or the value for STUR/CBZ)
   assign rm = instruction[9:5];                                  // Rn: first source register (goes to Read register 1)
   assign rn = Reg2Loc ? instruction[4:0] : instruction[20:16];   // Reg2Loc mux: 1 -> Rt (STUR, CBZ), 0 -> Rm (R-type)
   assign opcode = instruction[31:21];                            // top 11 bits tell the control unit what to do

   // ---------------------------------------------------------------
   // Instruction Memory: give it the PC, it gives back the instruction
   // ---------------------------------------------------------------
   InstructionMemory imem(
			  .Data(instruction),
			  .Address(currentpc)
			  );

   // ---------------------------------------------------------------
   // Control unit: give it the opcode, it gives back all control signals
   // FIXED: the handout had "control SingleCycleControl(" which has the
   // module name and the instance name swapped. The module is SC_Control.
   // ---------------------------------------------------------------
   SC_Control control(
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

   /*
    * Connect the remaining datapath elements below.
    * Do not forget any additional multiplexers that may be required.
    */

   // ---------------------------------------------------------------
   // Register File (Lab 5)
   //   Read register 1 = rm (bits 9:5)        -> Read data 1 = regoutA
   //   Read register 2 = rn (Reg2Loc mux out) -> Read data 2 = regoutB
   //   Write register  = rd (bits 4:0)
   //   Write data      = MemtoRegOut (ALU result or memory data)
   //   It only writes when RegWrite = 1, on the falling clock edge.
   // ---------------------------------------------------------------
   RegisterFile registers(
			  .BusA(regoutA),
			  .BusB(regoutB),
			  .BusW(MemtoRegOut),
			  .RA(rm),
			  .RB(rn),
			  .RW(rd),
			  .RegWr(RegWrite),
			  .Clk(CLK)
			  );

   // ---------------------------------------------------------------
   // Sign Extender (Lab 6)
   //   Takes the low 26 bits of the instruction and, using SignOp to know
   //   which field to grab, makes a 64-bit immediate / branch offset.
   // ---------------------------------------------------------------
   SignExtender signext(
			.SignExOut(extimm),
			.Instruction(instruction[25:0]),
			.SignOp(SignOp)
			);

   // ---------------------------------------------------------------
   // ALUSrc mux (the extra mux in front of the ALU's B input)
   //   ALUSrc = 0 -> B = register value (ADD, SUB, AND, ORR, CBZ)
   //   ALUSrc = 1 -> B = sign-extended immediate (LDUR, STUR, ADDI, SUBI)
   // ---------------------------------------------------------------
   assign aluinB = ALUSrc ? extimm : regoutB;

   // ---------------------------------------------------------------
   // ALU (Lab 6)
   //   A = Read data 1, B = ALUSrc mux output, operation = ALUOp.
   //   Zero is 1 when the result is 0 (used by CBZ).
   // ---------------------------------------------------------------
   ALU alu(
	   .BusW(aluout),
	   .BusA(regoutA),
	   .BusB(aluinB),
	   .ALUCtrl(ALUOp),
	   .Zero(zero)
	   );

   // ---------------------------------------------------------------
   // Data Memory (given)
   //   Address    = ALU result (Xn + offset for LDUR/STUR)
   //   Write data = Read data 2 (the Rt value for STUR)
   //   Reads when MemRead = 1, writes on the rising clock edge when MemWrite = 1.
   // ---------------------------------------------------------------
   DataMemory dmem(
		   .ReadData(dmemout),
		   .Address(aluout),
		   .WriteData(regoutB),
		   .MemoryRead(MemRead),
		   .MemoryWrite(MemWrite),
		   .Clock(CLK)
		   );

   // ---------------------------------------------------------------
   // MemtoReg mux (picks what gets written back to the register file)
   //   MemtoReg = 0 -> ALU result (ADD, SUB, AND, ORR, ADDI, SUBI)
   //   MemtoReg = 1 -> data memory output (LDUR)
   // ---------------------------------------------------------------
   assign MemtoRegOut = MemtoReg ? dmemout : aluout;

   // ---------------------------------------------------------------
   // Next PC logic (Lab 6)
   //   If (Branch AND Zero) OR Uncondbranch -> nextpc = PC + offset
   //   otherwise                            -> nextpc = PC + 4
   // ---------------------------------------------------------------
   NextPClogic nextpclogic(
			   .NextPC(nextpc),
			   .CurrentPC(currentpc),
			   .SignExtImm64(extimm),
			   .Branch(Branch),
			   .ALUZero(zero),
			   .Uncondbranch(Uncondbranch)
			   );

endmodule
