#include <stdio.h>


static int A[50000];
static int B[50000];
static int C[50000];


int main(void) {
    for (int i = 0; i < 50000; i++){
        A[i] = i;
        B[i] = 50000 - i;
        C[i] = 0;
    }


    for ( int i = 0; i < 50000; i++){
        int sum = 0;
        for ( int j = 0; j< A[i]; j++){
            sum += B[j];
        }
        C[i] = sum;


    }
    long long checksum = 0;
    for (int i =0; i < 50000; i++){
        checksum += C[i];
    }
    printf("%lld\n", checksum);
    if (checksum != 41667916675000){
        printf("checksum does not equal: 41667916675000");
        return 1;
    }
    return 0;
}
