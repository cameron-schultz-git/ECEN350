// Lab03c.S
// Implements the following C code:
//
//   long long int j = initial_value;
//   for (i = 0; i < 10; i++) {
//       my_array[i] = j + j;
//       j++;
//   }
//
// Register usage:
//   x0 = base address of my_array
//   x1 = j (long long int)
//   x2 = i (loop counter)
//   x3 = temporary holding j + j

    .equ INITIAL_VALUE, 5       // <-- replace with the first digit of your UIN

    .section .data
    .align 3                    // align to 8 bytes (2^3) for 64-bit elements
my_array:
    .space 80                   // 10 quad words * 8 bytes each = 80 bytes

    .section .text
    .global main
main:
    ldr   x0, =my_array         // x0 = address of my_array
    mov   x1, #INITIAL_VALUE    // j = initial_value
    mov   x2, #0                // i = 0

loop:
    cmp   x2, #10               // compare i with 10
    b.ge  done                  // if i >= 10, exit the loop

    add   x3, x1, x1            // x3 = j + j
    str   x3, [x0, x2, lsl #3]  // my_array[i] = x3 (offset = i * 8 bytes)

    add   x1, x1, #1            // j++
    add   x2, x2, #1            // i++
    b     loop                  // repeat

done:
    mov   x0, #0                // return 0
    ret
