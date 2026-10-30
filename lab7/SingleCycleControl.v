`timescale 1ns / 1ps

// =============================================================================
// SC_Control  -  Main Control unit for the single cycle ARMv8 processor
// =============================================================================
//
// What this module does:
//   The control unit is the "brain" of the processor. It looks at the 11-bit
//   opcode (Instruction[31:21]) and decides how every part of the datapath
//   should behave for that instruction: which mux inputs to pick, what the
//   ALU should do, whether to read/write memory, whether to write a register,
//   and whether to branch.
//
// How it works:
//   1. At the top of the always block every output is set to 0. This is the
//      "safe" value, and it is also what an undefined opcode must output.
//      Because every output gets a value at the start of every run of the
//      block, no latches can be created.
//   2. A casez statement compares the opcode against each supported
//      instruction. In a casez, a "?" in the pattern means "don't care about
//      this bit", so one line can match all the opcodes of one instruction
//      (for example, B matches 000101 followed by any 5 bits).
//   3. When a pattern matches, that instruction's row of the truth table is
//      assigned, one signal per line.
//   4. Signals that do not matter for an instruction are set to x (don't
//      care). This lets the synthesis tool pick whatever value makes the
//      logic smallest.
//
// Encodings used (same as Lab 6):
//   ALUOp  : 0000 = AND, 0001 = OR, 0010 = ADD, 0110 = SUB, 0111 = PassB
//   SignOp : 00 = I-Type, 01 = D-Type, 10 = CB-Type, 11 = B-Type
// =============================================================================


// ---------------------------------------------------------------------------
// Opcode patterns (Instruction[31:21]).  "?" = don't care bit.
// NOTE: The handout had OPCODE_ANDREG = 11'b10001011000, which is the same
//       value as ADD. The real ARMv8 opcode for AND (and the value in the
//       prelab truth table) is 11'b10001010000, so it is fixed here.
// ---------------------------------------------------------------------------
`define OPCODE_ANDREG 11'b10001010000
`define OPCODE_ORRREG 11'b10101010000
`define OPCODE_ADDREG 11'b10001011000
`define OPCODE_SUBREG 11'b11001011000

`define OPCODE_ADDIMM 11'b1001000100?
`define OPCODE_SUBIMM 11'b1101000100?

`define OPCODE_MOVZ   11'b110100101??

`define OPCODE_B      11'b000101?????
`define OPCODE_CBZ    11'b10110100???

`define OPCODE_LDUR   11'b11111000010
`define OPCODE_STUR   11'b11111000000


module SC_Control(
               output reg       Reg2Loc,      // picks Read register 2: 0 = Rm (bits 20:16), 1 = Rt (bits 4:0)
               output reg       ALUSrc,       // picks ALU input B: 0 = register, 1 = sign-extended immediate
               output reg       MemtoReg,     // picks what is written to a register: 0 = ALU result, 1 = memory data
               output reg       RegWrite,     // 1 = write a result into the register file
               output reg       MemRead,      // 1 = read from data memory (LDUR)
               output reg       MemWrite,     // 1 = write to data memory (STUR)
               output reg       Branch,       // 1 = conditional branch (CBZ), taken only if ALU Zero = 1
               output reg       Uncondbranch, // 1 = unconditional branch (B), always taken
               output reg [3:0] ALUOp,        // tells the ALU which operation to do
               output reg [1:0] SignOp,       // tells the sign extender which immediate field to use
               input      [10:0] opcode       // Instruction[31:21]
               );

   // always @(*) means: re-run this block any time an input (the opcode)
   // changes. That makes it combinational logic (no clock, no memory).
   always @(*)
     begin

        // ---------------------------------------------------------------
        // Step 1: default every output to 0.
        // - An undefined opcode must output all 0s, so if no case below
        //   matches, these are the values that come out.
        // - Every output is given a value on every pass through the block,
        //   so the synthesizer will not build any latches.
        // ---------------------------------------------------------------
        Reg2Loc      = 1'b0;
        ALUSrc       = 1'b0;
        MemtoReg     = 1'b0;
        RegWrite     = 1'b0;
        MemRead      = 1'b0;
        MemWrite     = 1'b0;
        Branch       = 1'b0;
        Uncondbranch = 1'b0;
        ALUOp        = 4'b0000;
        SignOp       = 2'b00;

        // ---------------------------------------------------------------
        // Step 2: decode the opcode.
        // casez treats "?" in the patterns as "match anything".
        // ---------------------------------------------------------------
        casez (opcode)

          // ===== LDUR  Xt, [Xn, #imm]   Xt = Memory[Xn + imm] =====
          `OPCODE_LDUR:
            begin
               Reg2Loc      = 1'bx;     // don't care: Read data 2 is not used
               ALUSrc       = 1'b1;     // ALU B = immediate (the address offset)
               MemtoReg     = 1'b1;     // write the value read from memory into Xt
               RegWrite     = 1'b1;     // yes, we write Xt
               MemRead      = 1'b1;     // yes, read data memory
               MemWrite     = 1'b0;     // do not write memory
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0010;  // ADD: address = Xn + offset
               SignOp       = 2'b01;    // D-Type immediate (bits 20:12), sign extended
            end

          // ===== STUR  Xt, [Xn, #imm]   Memory[Xn + imm] = Xt =====
          `OPCODE_STUR:
            begin
               Reg2Loc      = 1'b1;     // Read register 2 = Rt (bits 4:0), the value to store
               ALUSrc       = 1'b1;     // ALU B = immediate (the address offset)
               MemtoReg     = 1'bx;     // don't care: nothing is written to a register
               RegWrite     = 1'b0;     // do not write a register
               MemRead      = 1'b0;     // do not read memory
               MemWrite     = 1'b1;     // yes, write data memory
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0010;  // ADD: address = Xn + offset
               SignOp       = 2'b01;    // D-Type immediate (bits 20:12), sign extended
            end

          // ===== ADD  Xd, Xn, Xm   Xd = Xn + Xm =====
          `OPCODE_ADDREG:
            begin
               Reg2Loc      = 1'b0;     // Read register 2 = Rm (bits 20:16)
               ALUSrc       = 1'b0;     // ALU B = register Xm
               MemtoReg     = 1'b0;     // write the ALU result into Xd
               RegWrite     = 1'b1;     // yes, we write Xd
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0010;  // ADD
               SignOp       = 2'bxx;    // don't care: no immediate is used
            end

          // ===== SUB  Xd, Xn, Xm   Xd = Xn - Xm =====
          // (Not in the Q1 table, but OPCODE_SUBREG is part of the Q2 module
          //  definition, and Test Program 1 uses it at address 0x24.)
          `OPCODE_SUBREG:
            begin
               Reg2Loc      = 1'b0;     // Read register 2 = Rm (bits 20:16)
               ALUSrc       = 1'b0;     // ALU B = register Xm
               MemtoReg     = 1'b0;     // write the ALU result into Xd
               RegWrite     = 1'b1;     // yes, we write Xd
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0110;  // SUB
               SignOp       = 2'bxx;    // don't care: no immediate is used
            end

          // ===== AND  Xd, Xn, Xm   Xd = Xn & Xm =====
          `OPCODE_ANDREG:
            begin
               Reg2Loc      = 1'b0;     // Read register 2 = Rm (bits 20:16)
               ALUSrc       = 1'b0;     // ALU B = register Xm
               MemtoReg     = 1'b0;     // write the ALU result into Xd
               RegWrite     = 1'b1;     // yes, we write Xd
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0000;  // AND
               SignOp       = 2'bxx;    // don't care: no immediate is used
            end

          // ===== ORR  Xd, Xn, Xm   Xd = Xn | Xm =====
          `OPCODE_ORRREG:
            begin
               Reg2Loc      = 1'b0;     // Read register 2 = Rm (bits 20:16)
               ALUSrc       = 1'b0;     // ALU B = register Xm
               MemtoReg     = 1'b0;     // write the ALU result into Xd
               RegWrite     = 1'b1;     // yes, we write Xd
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0001;  // OR
               SignOp       = 2'bxx;    // don't care: no immediate is used
            end

          // ===== ADDI  Xd, Xn, #imm   Xd = Xn + imm =====
          // (Not in the Q1 table, but OPCODE_ADDIMM is part of the Q2 module
          //  definition, and the ALU and sign extender already support it.)
          `OPCODE_ADDIMM:
            begin
               Reg2Loc      = 1'bx;     // don't care: Read data 2 is not used
               ALUSrc       = 1'b1;     // ALU B = immediate
               MemtoReg     = 1'b0;     // write the ALU result into Xd
               RegWrite     = 1'b1;     // yes, we write Xd
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0010;  // ADD
               SignOp       = 2'b00;    // I-Type immediate (bits 21:10), zero extended
            end

          // ===== SUBI  Xd, Xn, #imm   Xd = Xn - imm =====
          `OPCODE_SUBIMM:
            begin
               Reg2Loc      = 1'bx;     // don't care: Read data 2 is not used
               ALUSrc       = 1'b1;     // ALU B = immediate
               MemtoReg     = 1'b0;     // write the ALU result into Xd
               RegWrite     = 1'b1;     // yes, we write Xd
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'b0;     // not a branch
               Uncondbranch = 1'b0;     // not a branch
               ALUOp        = 4'b0110;  // SUB
               SignOp       = 2'b00;    // I-Type immediate (bits 21:10), zero extended
            end

          // ===== CBZ  Xt, label   if (Xt == 0) PC = PC + offset =====
          `OPCODE_CBZ:
            begin
               Reg2Loc      = 1'b1;     // Read register 2 = Rt (bits 4:0), the register we test
               ALUSrc       = 1'b0;     // ALU B = register Xt
               MemtoReg     = 1'bx;     // don't care: nothing is written to a register
               RegWrite     = 1'b0;     // do not write a register
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'b1;     // conditional branch: taken only if Zero = 1
               Uncondbranch = 1'b0;     // not an unconditional branch
               ALUOp        = 4'b0111;  // PassB: ALU outputs Xt, so Zero = 1 when Xt == 0
               SignOp       = 2'b10;    // CB-Type offset (bits 23:5), sign extended, shifted left 2
            end

          // ===== B  label   PC = PC + offset (always) =====
          `OPCODE_B:
            begin
               Reg2Loc      = 1'bx;     // don't care: no registers are read
               ALUSrc       = 1'bx;     // don't care: the ALU result is not used
               MemtoReg     = 1'bx;     // don't care: nothing is written to a register
               RegWrite     = 1'b0;     // do not write a register
               MemRead      = 1'b0;     // no memory access
               MemWrite     = 1'b0;     // no memory access
               Branch       = 1'bx;     // don't care: Uncondbranch = 1 already forces the branch
               Uncondbranch = 1'b1;     // always branch
               ALUOp        = 4'bxxxx;  // don't care: the ALU result is not used
               SignOp       = 2'b11;    // B-Type offset (bits 25:0), sign extended, shifted left 2
            end

          // ===== Anything else =====
          // This includes MOVZ: its opcode is defined above, but this
          // datapath has no hardware to run it yet (it needs a "shift a
          // 16-bit value into place" operation), so it outputs all 0s.
          default:
            begin
               // Nothing to do: every output keeps the 0 it was given in
               // Step 1, which is the required "all 0s" for an undefined
               // opcode.
            end

        endcase
     end

endmodule
