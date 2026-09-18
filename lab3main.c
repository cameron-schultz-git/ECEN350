/* main.c simple program to test assembler program */

#include <stdio.h>

extern long long int test(long long int a, long long int b);
extern long long int lab03b(void);

int main(void)
{
    long long int a = test(3, 5);
    printf("Result of test(3, 5) = %lld\n", a);

    long long int uin = lab03b();
    printf("UIN after loop = %lld\n", uin);

    return 0;
}
