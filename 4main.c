/* main.c simple program to test assembler program */

#include <stdio.h>

extern long long int my_mul(long long int a, long long int b);
extern long long int power(long long int base, long long int exp);

int main(void)
{
    long long int a = my_mul(3, 5);
    printf("Result of my_mul(3, 5) = %lld\n", a);

    /* test power with several base/exp pairs */
    long long int bases[] = {2, 3, 5, 7, 10, 1, 0, 4};
    long long int exps[]  = {10, 4, 3, 0, 5, 8, 3, 1};
    int n = sizeof(bases) / sizeof(bases[0]);

    for (int i = 0; i < n; i++) {
        long long int r = power(bases[i], exps[i]);
        printf("base = %lld, exp = %lld, power(%lld, %lld) = %lld\n",
               bases[i], exps[i], bases[i], exps[i], r);
    }
    return 0;
}
