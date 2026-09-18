#include <stdio.h>

extern long long int test();
extern long long int lab02_3d(long long int b);

int main(void)
{
	test();

	long long int *myvalue = (long long int *) lab02_3d(100);
	printf("myvalue @ %p holds %lld\n", (void *)myvalue, *myvalue);

	return 0;
}
