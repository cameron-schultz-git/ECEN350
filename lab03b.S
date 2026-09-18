// lab03b.S
//   long long int lab03b(void);
//   Implements:  for (i = 0; i <= 5; i++) { UIN = UIN + 1; }
//   Returns the final value of UIN.

	.globl lab03b

	.section .text
lab03b:
	ADR  X10, UIN            // X10 = &UIN
	ADD  X9, XZR, XZR        // i = 0

loop_b:
	SUB  X12, X9, #6         // X12 = i - 6
	CBZ  X12, done_b         // exit when i == 6  (body runs i = 0..5)

	LDUR X11, [X10, #0]      // X11 = UIN
	ADD  X11, X11, #1        // UIN = UIN + 1
	STUR X11, [X10, #0]      // write it back

	ADD  X9, X9, #1          // i++
	B    loop_b

done_b:
	LDUR X0, [X10, #0]       // return UIN
	BR   X30

	.section .data
	.align 3
UIN:	.quad 33                
