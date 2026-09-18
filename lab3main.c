/* main.c simple program to test assembler program */

#include <stdio.h>

extern long long int test(long long int a, long long int b);
extern long long int lab03b(void);
extern long long int *lab03c(void);

int main(void)
{
    long long int a = test(3, 5);
    printf("Result of test(3, 5) = %lld\n", a);

    printf("UIN after loop = %lld\n", lab03b());

    long long int *arr = lab03c();
    for (int i = 0; i < 10; i++)
        printf("my_array[%d] = %lld\n", i, arr[i]);

    return 0;
}/* main.c simple program to test assembler program */

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
