#include <stdio.h>
float fp32_to_bf16(float x);                 
int main(){
    float a[3]={1.2,1.203125,2.31};
    float b[3]={2.3125,3.46,3.453125};
    float c[5];
    for(int k=0;k<3;k++){
        a[k]=fp32_to_bf16(a[k]);
        b[k]=fp32_to_bf16(b[k]);
    }
    for (int i = 0; i < 5; i++) {
        c[i] = 0.0;
        for (int j = 0; j < 3; j++) {
            // To right shift the impulse
            if ((i - j) >= 0
                && (i - j) < 3) {
                // Main calculation
                c[i] = c[i] + a[j] * b[i - j];
            }
        }
      printf("%f\t", c[i] );
    }
}
float fp32_to_bf16(float x)                 
{
    float y = x;
    int *p = (int *) &y;
    unsigned int exp = *p & 0x7F800000;
    unsigned int man = *p & 0x007FFFFF;
    if (exp == 0 && man == 0) /* zero */
        return x;
    if (exp == 0x7F800000) /* Fill this! /  / infinity or NaN */
        return x;

    /* Normalized number */
    /* round to nearest */
    float r = x;
    int *pr = (int *) &r;
    *pr &= 0xFF800000;  /* r has the same exp as x */
    r /= 0x100; /* Fill this! */
    y = x + r;

    *p &= 0xFFFF0000;

    return y;
}
