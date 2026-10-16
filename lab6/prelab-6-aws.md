# prelab-6-aws

Prelab 06 and Lab 06: Datapath Components I — 2026-10-16

## Overview

Prelab 06 has 9 questions (190 pts) covering three datapath modules for the single-cycle ARMv8 CPU: the Sign Extender, the 64-bit ALU and the NextPC logic. Each module gets a design question, a Verilog implementation and a self-checking random testbench with a VCD dump.

| Q | Pts | Task |
| --- | --- | --- |
| 1 | 20 | Sign extender bit-field / extension / shift table |
| 2 | 30 | SignExtender.v |
| 3 | 30 | SignExtender testbench |
| 4 | 10 | ALU operation for LDUR, STUR, CBZ, ORR |
| 5 | 20 | ALU.v |
| 6 | 30 | ALU testbench |
| 7 | 10 | NextPC mux-select truth table |
| 8 | 20 | NextPClogic.v |
| 9 | 20 | NextPClogic testbench |

All code is in this Lab06 folder and was compiled and run with Icarus Verilog 12.0. The full code for Q2, Q3, Q5, Q6, Q8 and Q9 is in the `.v` files listed under each question; paste them from there into Canvas.

## Sign Extender (Q1–Q3)

### Q1 — Bit fields

I-Type is zero extended because ARMv8 immediate ALU ops (ADDI, SUBI, ORRI) use an unsigned 12-bit immediate. Only the branch offsets are word offsets, so only CB and B are shifted left 2.

| Instruction Type | SignOp | Bits needed | S/Z | Shift left 2? |
| --- | --- | --- | --- | --- |
| I-Type | 00 | [21:10] | Z | N |
| D-Type | 01 | [20:12] | S | N |
| CB-Type | 10 | [23:5] | S | Y |
| B-Type | 11 | [25:0] | S | Y |

### Q2 — SignExtender.v

See [SignExtender.v](SignExtender.v). A combinational `case` on SignOp pulls out the field and either zero-pads it (I-Type) or replicates its top bit (D, CB, B). CB and B append `2'b00` on the right for the shift. Every path assigns all 64 bits and there is a `default`, so there are no latches.

### Q3 — SignExtenderTest.v

See [SignExtenderTest.v](SignExtenderTest.v). Each SignOp gets 2–5 directed corner cases plus 100 random instructions (418 tests total). The reference model is written differently from the DUT: it puts the field at the top of a signed register and uses `>>>` to sign extend, then multiplies by 4 for the branch types. Every mismatch prints an ERROR line, and the bench dumps `SignExtenderTest.vcd`.

## ALU (Q4–Q6)

### Q4 — ALU operation per instruction

| Instruction | ALU operation | Why |
| --- | --- | --- |
| LDUR | ADD (0010) | address = Rn + sign-extended DT_address |
| STUR | ADD (0010) | address = Rn + sign-extended DT_address |
| CBZ | PassB (0111) | passes Rt through so Zero tells whether Rt == 0 |
| ORR | OR (0001) | Rd = Rn \| Rm |

### Q5 — ALU.v

See [ALU.v](ALU.v). A combinational `case` on ALUCtrl selects AND, OR, ADD, SUB or PassB. ADD and SUB wrap modulo 2^64. The `default` drives 0, so there is no latch. `Zero` is a continuous assign of `BusW == 0`, so it is valid for every operation.

### Q6 — ALUTest.v

See [ALUTest.v](ALUTest.v). Each of the 5 functions gets the 4 all-0s/all-1s combinations of BusA and BusB, a directed Zero=1 and Zero=0 case, and 100 random 64-bit pairs (533 tests). ADD adds three overflow cases: 0x7FFF…F + 1 (signed overflow), 0x8000…0 + 0x8000…0 (signed overflow with carry out) and 0xFFFF…F + 1 (unsigned carry out). The reference model keeps a 65-bit sum for ADD and computes SUB as A + ~B + 1. The bench also fails if any function never produced both Zero=1 and Zero=0, and it dumps `ALUTest.vcd`.

## NextPC (Q7–Q9)

### Q7 — Mux select truth table

Select = (Branch AND ALUZero) OR Uncondbranch; 1 picks BranchPC, 0 picks PC + 4.

| Branch | Uncondbranch | ALUZero | NextPC Mux Select |
| --- | --- | --- | --- |
| 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 0 |
| 0 | 1 | 0 | 1 |
| 0 | 1 | 1 | 1 |
| 1 | 0 | 0 | 0 |
| 1 | 0 | 1 | 1 |
| 1 | 1 | 0 | 1 |
| 1 | 1 | 1 | 1 |

### Q8 — NextPClogic.v

See [NextPClogic.v](NextPClogic.v). If `(Branch & ALUZero) | Uncondbranch`, NextPC = CurrentPC + SignExtImm64 (the sign extender has already shifted the offset), otherwise CurrentPC + 4. Both arms assign NextPC, so there is no latch.

### Q9 — NextPClogicTest.v

See [NextPClogicTest.v](NextPClogicTest.v). 10 random CurrentPC/SignExtImm64 pairs for each of the 8 control combinations, plus 6 directed branch and wrap-around cases (86 tests). The expected select is looked up from the Q7 table, not recomputed from the DUT's equation. The bench dumps `NextPClogicTest.vcd`.

## Lab 06 answers

All three units passed their testbenches on the first run, so no design fixes were needed. Each run wrote a VCD (SignExtenderTest.vcd, ALUTest.vcd, NextPClogicTest.vcd) for the GTKWave part of the TA demo.

### Lab Q1 — Sign Extender

```text
VCD info: dumpfile SignExtenderTest.vcd opened for output.
SignExtender: I-Type  104 passed
SignExtender: D-Type  105 passed
SignExtender: CB-Type 105 passed
SignExtender: B-Type  104 passed
SignExtender: 418 tests, 418 passed, 0 failed
ALL TESTS PASSED
SignExtenderTest.v:115: $finish called at 836000 (1ps)
```

Yes, a bug could still get through. 100 random values per type cover a tiny part of the 2^26 input space. The bigger risk is a shared misunderstanding: if the spec is misread (for example, sign-extending I-Type), the reference model carries the same mistake and both agree. Random inputs also rarely land on the exact sign-bit boundaries.

Ways to improve the bench:

- Test the I-Type and D-Type fields exhaustively. That is only 4,096 + 512 values, and the result depends only on the field bits.
- Hold the field fixed and randomize the bits outside it, to prove those bits are ignored.
- Check against real encodings from an assembler (for example, `LDUR X1, [X2, #-8]`) instead of only a hand-written model.
- Add coverage counters so each type is seen with both sign bit 0 and sign bit 1.

### Lab Q2 — ALU

```text
VCD info: dumpfile ALUTest.vcd opened for output.
ALU AND: 106 passed (Zero=1: 4, Zero=0: 102)
ALU OR: 106 passed (Zero=1: 2, Zero=0: 104)
ALU ADD: 109 passed (Zero=1: 4, Zero=0: 105)
ALU SUB: 106 passed (Zero=1: 3, Zero=0: 103)
ALU PassB: 106 passed (Zero=1: 3, Zero=0: 103)
ALU: 533 tests, 533 passed, 0 failed
ALL TESTS PASSED
ALUTest.v:147: $finish called at 1066000 (1ps)
```

The input space is 2^128 per operation. Random 64-bit operands almost never give a zero result or hit carry-chain edge cases. That is why every Zero=1 case above comes from directed tests, and why the bench checks Zero coverage per function. A reference model that uses the same `+`/`-` operators as the DUT can share its bugs, so SUB is checked as A + ~B + 1. The bench also never drives the unused ALUCtrl codes.

Unsigned immediates still work with signed numbers because two's-complement addition and subtraction produce the same bits whether the operands are read as signed or unsigned. To add a negative constant, use the opposite instruction with its magnitude: `ADDI X1, X1, #-5` becomes `SUBI X1, X1, #5`, and the assembler does this conversion. The result is correct as a signed value. Only the overflow and carry flags are read differently. Constants that do not fit in 12 bits are built in a register with MOVZ/MOVK.

### Lab Q3 — NextPC

```text
VCD info: dumpfile NextPClogicTest.vcd opened for output.
NextPC: Branch=0 Uncondbranch=0 ALUZero=0  sel=0  11 passed
NextPC: Branch=0 Uncondbranch=0 ALUZero=1  sel=0  10 passed
NextPC: Branch=0 Uncondbranch=1 ALUZero=0  sel=1  13 passed
NextPC: Branch=0 Uncondbranch=1 ALUZero=1  sel=1  10 passed
NextPC: Branch=1 Uncondbranch=0 ALUZero=0  sel=0  11 passed
NextPC: Branch=1 Uncondbranch=0 ALUZero=1  sel=1  11 passed
NextPC: Branch=1 Uncondbranch=1 ALUZero=0  sel=1  10 passed
NextPC: Branch=1 Uncondbranch=1 ALUZero=1  sel=1  10 passed
NextPC: 86 tests, 86 passed, 0 failed
ALL TESTS PASSED
NextPClogicTest.v:106: $finish called at 172000 (1ps)
```

The control side is covered exhaustively, since there are only 8 combinations. The data side has two gaps. Random 64-bit PCs are not word-aligned and look nothing like real addresses. Random 64-bit immediates are not the sign-extended 19- or 26-bit offsets the sign extender can actually produce. A better bench would draw offsets from the real CB/B ranges or drive NextPC straight from the SignExtender.

Mixing an unsigned PC with a signed offset works because the adder is two's-complement. Adding 0xFFFF…FFF0 (−16) to the PC is the same as subtracting 16, so one unsigned 64-bit adder handles forward and backward branches. On overflow or underflow my code wraps silently modulo 2^64 with no trap. The directed tests confirm 0x4 + (−8) = 0xFFFF_FFFF_FFFF_FFFC, 0xFFFF…FFFC + 4 = 0x0, and 0xFFFF…FFF0 + 0x20 = 0x10. In a real system the wrapped address would fault in the MMU. In practice wrap is unreachable from normal code, because branch reach is ±1 MB (CB) or ±128 MB (B) and code is never placed at the ends of the address space.

## Notes for review

All six files compile with `iverilog -Wall` with no warnings, and all 1,037 tests pass. The code was written with an LLM (Claude), so the prelab's "document any errors" request applies.

**LLM errors found and fixed**

- `%-5s` in the ALU bench's `$display` is not a valid Icarus format. Changed it to `%0s`.
- The module files had no `` `timescale `` but the testbenches did, so `-Wall` warned. Added `` `timescale 1ns / 1ps `` to SignExtender.v, ALU.v and NextPClogic.v.

**Checking that the testbenches catch bugs.** I put one bug at a time into copies of the modules and ran the unchanged testbenches. Every bug was caught:

| Bug injected | Failing tests |
| --- | --- |
| D-Type zero-extended instead of sign-extended | 55 / 418 |
| CB-Type shifts in 11 instead of 00 | 105 / 418 |
| SUB computes A + B | 104 / 533 |
| Zero flag inverted | 538 / 538 |
| Mux select ignores ALUZero | 11 / 86 |
| PC + 8 instead of PC + 4 | 32 / 86 |

**Assumptions to check against your notes**

- I-Type is zero extended. Lab Q2 ("ARMv8 has unsigned immediate ALU operations") supports this.
- The modules have no `#` delays because the prelab doesn't ask for any.

**To run** (from WSL):

```bash
cd ~/code/ECEN350_Labs-main/Lab06
iverilog -Wall -o ALUTest.out ALU.v ALUTest.v && vvp ALUTest.out
gtkwave ALUTest.vcd
```

The other two modules work the same way (`SignExtender.v SignExtenderTest.v`, `NextPClogic.v NextPClogicTest.v`).
