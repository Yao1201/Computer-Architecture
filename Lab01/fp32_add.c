#include <stdio.h>
#include <stdint.h>
float fadd32(float a, float b)
{
    /* TODO: Special values like NaN and INF */
    int32_t ia = *(int32_t *) &a, ib = *(int32_t *) &b;
    int32_t er,sr,result;
    /* sign */
    int signa = ia >> 31;
    int signb = ib >> 31;
    /* significand */
    int32_t sa = (ia & 0x7FFFFF) | 0x800000;
    int32_t sb = (ib & 0x7FFFFF) | 0x800000;

    /* exponent */
    int32_t ea = ((ia >> 23) & 0xFF);
    int32_t eb = ((ib >> 23) & 0xFF);
    int diff_exp=ea-eb;
    if(diff_exp<0){
        diff_exp=-diff_exp;
        er=eb;
        sa=sa>>diff_exp;
    }
    else{
        
        er=ea;
        sb=sb>>diff_exp;
    }
    sr=sa+sb;
    if(sr>>24!=0){
        sr=sr>>1;
        er++;
    }
    result=(0<<31)|((er&0xFF)<<23)|(sr&0x7FFFFF);
    return *(float*)&result;
}
int main(){
    float a=1.2;
    float b=0.3;
    float c=fadd32(a,b);
    printf("%f",c);
    return 0;
}
