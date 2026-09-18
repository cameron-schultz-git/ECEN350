// Lab03c.S
//   long long int *lab03c(void);
//   Implements:
//     long long int j = 5;          // first digit of UIN 535003575
//     for (i = 0; i < 10; i++) { my_array[i] = j + j; j++; }
//   Returns &my_array[0].

	.globl lab03c

	.section .text
lab03c:
	ADR  X10, my_array       // X10 = &my_array[0], running pointer
	ADD  X9, XZR, XZR        // i = 0
	MOVZ X11, #5             // j = initial_value

loop_c:
	SUB  X12, X9, #10        // X12 = i - 10
	CBZ  X12, done_c         // exit when i == 10

	ADD  X13, X11, X11       // X13 = j + j
	STUR X13, [X10, #0]      // my_array[i] = X13

	ADD  X11, X11, #1        // j++
	ADD  X10, X10, #8        // step one quad word
	ADD  X9, X9, #1          // i++
	B    loop_c

done_c:
	ADR  X0, my_array        // return &my_array[0]
	BR   X30

	.section .data
	.align 3
my_array:
	.space 80                // 10 quad words x 8 bytes
