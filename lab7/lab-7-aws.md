# lab-7-aws

Lab 07: Single Cycle Processor Control Unit and Top Level — 2026-10-30

## Overview

Lab 07 has 3 questions (130 pts). You run the control unit and processor from the prelab through their testbenches, then add the MOVZ instruction to the processor and test it with a new program.

| Q | Pts | Task | Files |
| --- | --- | --- | --- |
| 1 | 30 | Run the SC_Control testbench, discuss testing and garbled opcodes | [SingleCycleControl.v](SingleCycleControl.v), [SingleCycleControlTest.v](SingleCycleControlTest.v) |
| 2 | 50 | Run the SingleCycleProc testbench | [SingleCycleProc.v](SingleCycleProc.v), [SingleCycleProcTest.v](SingleCycleProcTest.v) |
| 3 | 50 | Add MOVZ, write Test Program 2 | the `_q3` files listed under Q3 |

All code is in this Lab07 folder and was compiled and run with Icarus Verilog. The prelab files are not changed. Q1 and Q2 run them as they were turned in for Prelab 7. Q3 puts every changed file in a new copy with `_q3` added to the name (for example `SignExtender_q3.v`). The module names inside are the same, so you choose a version by which files you compile, and the `_q3` testbenches write their own VCD files so they never overwrite the prelab ones.

## Q1 — SC_Control testbench

No test failed, so no fixes were needed. Run:

```bash
iverilog -Wall -o SingleCycleControlTest.out SingleCycleControl.v SingleCycleControlTest.v && vvp SingleCycleControlTest.out
gtkwave SingleCycleControlTest.vcd
```

**Testbench output** (prelab version, before MOVZ was added):

```text
VCD info: dumpfile SingleCycleControlTest.vcd opened for output.
SC_Control: 65 tests, 65 passed, 0 failed
ALL TESTS PASSED
SingleCycleControlTest.v:342: $finish called at 130000 (1ps)
```

The Q3 version of this bench ([SingleCycleControlTest_q3.v](SingleCycleControlTest_q3.v)) has 4 more MOVZ tests and also passes: `SC_Control: 69 tests, 69 passed, 0 failed`.

**Challenges with the testing strategy**

- **Don't cares.** Many outputs are X in the truth table, so the bench needs a way to skip them. An expected value of `x` means "do not check", and every other signal is compared with `!==`. With `!=`, an `x` from the design compares as unknown, so the `if` is never true and the error would be missed.
- **The same person wrote the design and the expected values.** If I had the truth table wrong (for example, the wrong ALUOp code for CBZ), the design and the bench would agree and the test would pass. The unit test only proves the Verilog matches my table. The full processor test in Q2 is what proves the table is right.
- **Coverage of bad opcodes.** The bench tests every opcode of every supported instruction (50 in the prelab version), but only 15 of the roughly 2000 unsupported ones (5 hand-picked and 10 random). The opcode is only 11 bits, so a loop over all 2048 values would also be cheap. The hand-picked ones are the risky ones, one bit away from a real opcode (CBNZ vs CBZ, LDUR with the last bit flipped).
- **It cannot catch wiring bugs.** The unit test drives SC_Control directly, so it cannot see mistakes in how the outputs are connected in the top level. The handout's `ALUop` typo (only 1 of the 4 ALUOp bits reached the ALU) passes this bench and only fails in the full processor.
- **Simulation start.** `always @(*)` runs only when its input changes. If the first opcode driven is `x`, nothing changes at time 0 and the outputs stay `x` instead of the default 0s. The bench avoids this by setting the opcode to a real value first.

**What happens with a garbled instruction**

An opcode that matches none of the `casez` patterns falls through to the `default` arm, so every output keeps the 0 it was given at the top of the block. I checked this for unsupported opcodes (15 of them in the bench) and for an all-`x` opcode, which is what the instruction memory returns for an address with no instruction.

With all 0s the instruction does nothing:

- RegWrite = 0 and MemWrite = 0, so no register or memory changes.
- MemRead = 0, so no memory read.
- Branch = 0 and Uncondbranch = 0, so the next PC is PC + 4.
- ALUOp = 0000 (AND) and SignOp = 0 still produce a value, but nothing uses it.

So a garbled instruction acts as a **NOP**: it is skipped and the program keeps running. Nothing is corrupted, but it also hides the problem. A real ARMv8 processor raises an "undefined instruction" exception instead. The handout's wrong AND opcode showed this: AND silently did nothing, and the only sign was that Program 1 never finished.

One more case: the control unit only looks at Instruction[31:21]. If those 11 bits are a valid opcode but the other bits are garbled, it runs as that instruction with the wrong registers or immediate.

**Demo notes:** walk through the two steps in [SingleCycleControl.v](SingleCycleControl.v) (all outputs set to 0, then `casez`), then the bench's `setExpected` / `checkOutputs` tasks. In GTKWave, add `opcode` and the 10 outputs. The B section shows 32 opcodes in a row with `Uncondbranch = 1`, and the don't cares appear as red `x` traces.

## Q2 — SingleCycleProc testbench

No test failed, so no fixes were needed (the handout bugs were already fixed in the prelab). Run:

```bash
iverilog -o SingleCycleProcTest.out SingleCycleProc.v SingleCycleControl.v RegisterFile.v ALU.v \
    SignExtender.v NextPClogic.v InstructionMemory.v DataMemory.v SingleCycleProcTest.v && vvp SingleCycleProcTest.out
gtkwave singlecycle.vcd
```

**Testbench output.** The full text to paste is in [SingleCycleProcTest.log](SingleCycleProcTest.log). The loop runs 15 times, since `0x0ffbea7deadbeeff & 0xF = 0xF`. The 15 loop passes are shortened here:

```text
VCD info: dumpfile singlecycle.vcd opened for output.
CurrentPC:0000000000000008
CurrentPC:000000000000000c
CurrentPC:0000000000000010
CurrentPC:0000000000000014
CurrentPC:0000000000000018
CurrentPC:000000000000001c
CurrentPC:0000000000000020
CurrentPC:0000000000000024
CurrentPC:0000000000000028
   ... 1c, 20, 24, 28 repeats 14 more times ...
CurrentPC:000000000000001c
CurrentPC:000000000000002c
CurrentPC:0000000000000030
             Results of Program 1 passed
All tests passed
SingleCycleProcTest.v:97: $finish called at 8520000 (1ps)
```

**Demo notes:** in GTKWave, add `CLK`, `currentpc`, `instruction`, `uut.control` outputs, `regoutA`, `regoutB`, `aluout`, `zero` and `MemtoRegOut`. Good points to show:

- 0x00–0x10: the five LDURs. MemRead = 1 and MemtoRegOut is the loaded value.
- 0x1C: CBZ. While X12 ≠ 0, `zero` = 0 and the PC goes to 0x20. On the last pass `zero` = 1 and the PC jumps to 0x2C.
- 0x28: B. `Uncondbranch` = 1 and the PC goes back to 0x1C.
- 0x30: the final LDUR puts 0xF on MemtoRegOut, and the bench checks it.

## Q3 — Adding MOVZ

The handout says "these two instructions", but it only names MOVZ. That wording seems left over from an older version of the lab, so only MOVZ is added.

### What MOVZ does

`MOVZ Xd, #imm16, LSL #(16*hw)` writes `imm16 << (16*hw)` into Xd, with every other bit 0 (the Z means "zero the rest").

| Bits | 31:23 | 22:21 | 20:5 | 4:0 |
| --- | --- | --- | --- | --- |
| Field | opcode `110100101` | hw | MOV_immediate | Rd |

So the 11-bit opcode the control sees is `110100101??`, where the 2 low bits are hw. That is 4 opcodes, one per shift amount (0, 16, 32, 48).

### Paragraph for Canvas: changes to the datapath and control

To support MOVZ, the processor has to build the value `imm16 << (16*hw)` and write it to Rd. I did this in the sign extender, since it already pulls immediates out of the instruction. The sign extender gets a new mode that takes Instruction[20:5], zero extends it, and shifts it left by 0, 16, 32 or 48 bits according to hw = Instruction[22:21]. All four 2-bit SignOp codes were already in use, so SignOp was widened from 2 to 3 bits, and MOVZ is `100`. The existing codes keep their values with a 0 added in front. The control unit gets a new `casez` arm for `OPCODE_MOVZ` (`110100101??`). It sets ALUSrc = 1 so the shifted immediate goes to ALU input B, ALUOp = PassB so the ALU passes it through unchanged, MemtoReg = 0 so the ALU result is written back, and RegWrite = 1 so it goes into Rd. The memory and branch signals are 0, and Reg2Loc is a don't care because Read data 2 is not used. In the top level, the only change is widening the SignOp wire to 3 bits. No new muxes, ALU operations or wires were needed. Read register 1 still reads bits 9:5, which for MOVZ are part of the immediate, but PassB ignores ALU input A, so that value is never used.

### Control signal table

All supported instructions, with SignOp now 3 bits. Only the MOVZ row is new.

| Instruction | Opcode | Reg2Loc | ALUSrc | MemtoReg | RegWrite | MemRead | MemWrite | Branch | Uncondbranch | ALUOp | SignOp |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| LDUR | 11111000010 | X | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0010 | 001 |
| STUR | 11111000000 | 1 | 1 | X | 0 | 0 | 1 | 0 | 0 | 0010 | 001 |
| ADD | 10001011000 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0010 | XXX |
| SUB | 11001011000 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0110 | XXX |
| AND | 10001010000 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0000 | XXX |
| ORR | 10101010000 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0001 | XXX |
| ADDI | 1001000100X | X | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0010 | 000 |
| SUBI | 1101000100X | X | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0110 | 000 |
| CBZ | 10110100XXX | 1 | 0 | X | 0 | 0 | 0 | 1 | 0 | 0111 | 010 |
| B | 000101XXXXX | X | X | X | 0 | 0 | 0 | X | 1 | XXXX | 011 |
| **MOVZ** | **110100101XX** | **X** | **1** | **0** | **1** | **0** | **0** | **0** | **0** | **0111** | **100** |

| SignOp | Type | Output |
| --- | --- | --- |
| 000 | I-Type | Instruction[21:10], zero extended |
| 001 | D-Type | Instruction[20:12], sign extended |
| 010 | CB-Type | Instruction[23:5], sign extended, ×4 |
| 011 | B-Type | Instruction[25:0], sign extended, ×4 |
| **100** | **MOVZ** | **Instruction[20:5], zero extended, << (16 × Instruction[22:21])** |

### Test Program 2

MOVZ clears every bit it does not set, so four MOVZs to the same register would only keep the last one. Instead, each 16-bit piece is built in X10 and ORed into X9. This uses all four shift amounts.

| Addr | Assembly | Machine code | Result |
| --- | --- | --- | --- |
| 0x34 | `MOVZ X9, 0x1234, LSL 48` | `D2E24689` | X9 = 0x1234000000000000 |
| 0x38 | `MOVZ X10, 0x5678, LSL 32` | `D2CACF0A` | X10 = 0x0000567800000000 |
| 0x3C | `ORR X9, X9, X10` | `AA0A0129` | X9 = 0x1234567800000000 |
| 0x40 | `MOVZ X10, 0x9abc, LSL 16` | `D2B3578A` | X10 = 0x000000009abc0000 |
| 0x44 | `ORR X9, X9, X10` | `AA0A0129` | X9 = 0x123456789abc0000 |
| 0x48 | `MOVZ X10, 0xdef0, LSL 0` | `D29BDE0A` | X10 = 0x000000000000def0 |
| 0x4C | `ORR X9, X9, X10` | `AA0A0129` | X9 = 0x123456789abcdef0 |
| 0x50 | `STUR X9, [XZR, 0x28]` | `F80283E9` | Memory[0x28] = X9 |
| 0x54 | `LDUR X10, [XZR, 0x28]` | `F84283EA` | X10 = 0x123456789abcdef0 |

How the MOVZ words are encoded, using 0x34 as the example:

```text
  110100101 | 11 | 0001 0010 0011 0100 | 01001
   opcode     hw=3      imm16=0x1234      Rd=X9
= 1101 0010 1110 0010 0100 0110 1000 1001 = 0xD2E24689
```

Program 2 starts at 0x34, right after Program 1's last instruction (0x30). The testbench runs Program 1 first, unchanged, so all the old instructions are still checked. It then resets the processor with `startPC = 0x34`, the same way Program 1 is started, and makes two checks:

1. At 0x4C (the last ORR), MemtoRegOut is the ALU result, which is the finished X9. This checks the MOVZs and ORRs.
2. At 0x54 (the LDUR), MemtoRegOut is the value loaded from 0x28. Address 0x28 is never initialized, so it reads as `x` unless the STUR worked. This checks the store and the load.

`allPassed` now expects 3 tests. The whole run is about 80 cycles, which is under the 255-cycle watchdog.

Run:

```bash
iverilog -o SingleCycleProcTest_q3.out SingleCycleProc_q3.v SingleCycleControl_q3.v RegisterFile.v ALU.v \
    SignExtender_q3.v NextPClogic.v InstructionMemory_q3.v DataMemory.v SingleCycleProcTest_q3.v && vvp SingleCycleProcTest_q3.out
gtkwave singlecycle_q3.vcd
```

**Testbench output** (full text in [SingleCycleProcTest_q3.log](SingleCycleProcTest_q3.log), Program 1's loop shortened):

```text
VCD info: dumpfile singlecycle_q3.vcd opened for output.
CurrentPC:0000000000000008
   ... Program 1, same as Q2 ...
CurrentPC:0000000000000030
             Results of Program 1 passed
CurrentPC:000000000000003c
CurrentPC:0000000000000040
CurrentPC:0000000000000044
CurrentPC:0000000000000048
CurrentPC:000000000000004c
      Program 2: X9 built by MOVZ passed
CurrentPC:0000000000000050
CurrentPC:0000000000000054
  Program 2: X10 loaded from 0x28 passed
All tests passed
SingleCycleProcTest_q3.v:125: $finish called at 9600000 (1ps)
```

### Units changed (paste these into Canvas)

Each is a copy of the prelab file with the changes below. The prelab file next to it is untouched.

| File | Change |
| --- | --- |
| [SignExtender_q3.v](SignExtender_q3.v) | SignOp widened to 3 bits; new `MOVZtype` (100) case that shifts Instruction[20:5] by 16 × hw |
| [SingleCycleControl_q3.v](SingleCycleControl_q3.v) | SignOp output widened to 3 bits; every SignOp value rewritten as 3 bits; new `OPCODE_MOVZ` arm |
| [SingleCycleProc_q3.v](SingleCycleProc_q3.v) | `SignOp` wire widened from `[1:0]` to `[2:0]` (comments updated) |
| [InstructionMemory_q3.v](InstructionMemory_q3.v) | Test Program 2 at 0x34–0x54, under "Add code for your tests here" |
| [SingleCycleProcTest_q3.v](SingleCycleProcTest_q3.v) | Runs Program 2 after Program 1 with 2 checks; `allPassed(passed, 3)`; dumps `singlecycle_q3.vcd` |
| [SingleCycleControlTest_q3.v](SingleCycleControlTest_q3.v) | 3-bit SignOp; dumps `SingleCycleControlTest_q3.vcd`; 4 MOVZ tests; MOVZ moved from "unsupported" to `isSupported`; MOVK (`11110010100`) replaces it as a hand-picked bad opcode |

DataMemory.v, ALU.v, RegisterFile.v and NextPClogic.v did not change, so the Q3 build uses the same files as the prelab build.

**Demo notes:** in GTKWave, zoom in after the second reset (PC = 0x34) and add `instruction`, `SignOp`, `extimm`, `aluout` and `MemtoRegOut`. At each MOVZ, `SignOp` = 100 and `extimm` shows the 16-bit piece moving up: `1234000000000000`, `0000567800000000`, `000000009abc0000`, `000000000000def0`. At each ORR, `aluout` shows X9 filling in. At 0x50, `MemWrite` = 1, and at 0x54 `MemtoRegOut` = `123456789abcdef0`.

## Notes for review

The code was written with an LLM (Claude). Everything compiled and passed on the first run.

**Checking that Program 2 catches bugs.** I put one bug at a time into a copy of the design and ran the unchanged testbench. Program 1 still passed each time, and Program 2 failed:

| Bug injected | Result |
| --- | --- |
| Sign extender: LSL 16 slot put in LSL 48 position | both Program 2 checks fail (`0x9abc56781234def0`) |
| Control: MOVZ uses ADD instead of PassB | both fail (`x`: input A reads the register named by imm16 bits, which was never written) |
| Top level: data memory writes blocked from PC 0x34 on | only the load check fails (`x`) |

**Design choice to check against your notes.** I did the MOVZ shift in the sign extender with a new SignOp code. That needed SignOp widened to 3 bits, which touches the control unit, the top level and the control testbench (all in their `_q3` copies). The other common approach is to keep SignOp at 2 bits and add a new ALU operation that shifts ALU input B by `16 × hw`. That needs a new ALUOp code and hw routed to the ALU. Both are valid. If your class notes or TA prefer one, the control table changes only in the ALUOp and SignOp columns.

**Lab 6 SignExtenderTest.** The Lab 6 testbench drives a 2-bit SignOp. It is in the Lab06 folder and still uses the Lab 6 SignExtender.v there, so it is not affected. It would need updating only if you ran it against SignExtender_q3.v.

**Remaining warnings.** `iverilog -Wall` still prints only "@* is sensitive to all 1024 words in array 'memBank'" from the given `DataMemory.v`.

**To run** (from WSL):

```bash
cd ~/code/ECEN350_Labs-main/Lab07

# Q1: control unit (prelab version)
iverilog -Wall -o SingleCycleControlTest.out SingleCycleControl.v SingleCycleControlTest.v && vvp SingleCycleControlTest.out

# Q2: full processor, Program 1 (prelab version)
iverilog -o SingleCycleProcTest.out SingleCycleProc.v SingleCycleControl.v RegisterFile.v ALU.v \
    SignExtender.v NextPClogic.v InstructionMemory.v DataMemory.v SingleCycleProcTest.v && vvp SingleCycleProcTest.out

# Q3: control unit with MOVZ
iverilog -Wall -o SingleCycleControlTest_q3.out SingleCycleControl_q3.v SingleCycleControlTest_q3.v && vvp SingleCycleControlTest_q3.out

# Q3: full processor, Program 1 + Program 2
iverilog -o SingleCycleProcTest_q3.out SingleCycleProc_q3.v SingleCycleControl_q3.v RegisterFile.v ALU.v \
    SignExtender_q3.v NextPClogic.v InstructionMemory_q3.v DataMemory.v SingleCycleProcTest_q3.v && vvp SingleCycleProcTest_q3.out

gtkwave SingleCycleControlTest.vcd     # or singlecycle.vcd, SingleCycleControlTest_q3.vcd, singlecycle_q3.vcd
```
