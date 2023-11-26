#include<stdio.h>
float fp32_to_bf16(float x);
int main(){
    float x=-2.1;
    unsigned u;
    //x=fp32_to_bf16(x);
    u=*(unsigned*)&x;

    printf("%x\n",u);
    //printf("%f",x);
    return 0;
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
    float *tr;
    printf("1\t%x\n",*p);
    *pr &= 0xFF800000;  /* r has the same exp as x */
    printf("2\t%x\n",*pr);
    r /= 0x100; /* Fill this! */
    printf("3\t%f\n",r);
    printf("3\t%f\n",x);

    printf("3\t%x\n",*pr);

    y = x + r;
    printf("4\t%x\n",*p);

    *p &= 0xFFFF0000;

    return y;
}
