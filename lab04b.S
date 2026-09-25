        .globl power

power:
        //Compute base^exp recursively, using my_mul for all multiplications
        //   X0 = base, X1 = exp, result returned in X0
        //   C equivalent:
        //     if (exp == 0) return 1;
        //     return my_mul(base, power(base, exp - 1));
        //   Does not handle negative exp (or a negative result, since my_mul
        //   does not handle a negative X1)!
        SUB SP, SP, 32          //make room for X30, X19, X20 on the stack (keeps SP 16-byte aligned)
        STUR X30, [SP, 16]      //push X30 (return address), BL below will overwrite it
        STUR X19, [SP, 8]       //push X19 (callee-saved, will hold base)
        STUR X20, [SP, 0]       //push X20 (callee-saved, will hold exp)
        ADD X19, X0, XZR        //set X19 equal to base
        ADD X20, X1, XZR        //set X20 equal to exp
        CBNZ X20, power_recurse //if exp != 0, go do the recursive case
        MOV X0, 1               //base case: exp == 0, return 1
        B power_done
power_recurse:
        ADD X0, X19, XZR        //arg 0 = base
        SUB X1, X20, 1          //arg 1 = exp - 1
        BL power                //X0 = power(base, exp - 1)
        ADD X1, X0, XZR         //arg 1 = power(base, exp - 1)
        ADD X0, X19, XZR        //arg 0 = base (X19 was preserved across the call)
        BL my_mul               //X0 = my_mul(base, power(base, exp - 1))
power_done:
        LDUR X20, [SP, 0]       //pop X20
        LDUR X19, [SP, 8]       //pop X19
        LDUR X30, [SP, 16]      //pop X30 so we return to our caller
        ADD SP, SP, 32          //restore SP
        BR X30                  //return, result is in X0
