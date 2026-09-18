
.section .text
.globl test

test:
	ADR X0, msg1
	ADR X1, msg2
	ADR X6, num1

	LDURB w2, [X6,0]
	LDURSH X3,[X6,1]
	LDURSW X4,[X6,3]
	LDUR X5,[X6,7]
	BR X30
 .section       .data
        msg1:	.asciz "A 17 byte message"
        msg2:	.asciz "Another message of 27 bytes"
        num1:	.byte 45
        num2:	.hword 0xf654
        num3:	.word 0xcafebabe
        num4:	.quad 0xfeedface

