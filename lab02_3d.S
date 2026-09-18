// lab02_3d.S
//   long long int lab02_3d(long long int b);
//   stores (b + 0xfe) at the .data symbol "myvalue", returns &myvalue

	.section .text
	.globl lab02_3d

lab02_3d:
	ADD  X0, X0, #0xfe            // X0 = argument + 0xfe
	ADRP X1, myvalue              // X1 = page containing myvalue
	ADD  X1, X1, :lo12:myvalue    // X1 = &myvalue
	STUR X0, [X1, #0]             // myvalue = X0
	MOV  X0, X1                   // return address of myvalue
	BR   X30

	.section .data
	.align 3
myvalue:
	.quad 0
