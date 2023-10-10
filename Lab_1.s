.data
arr1: .word 0x3f99999a, 0x3f9a0000, 0x4013d70a  #from problem2
arr2: .word 0x40140000, 0x405d70a4, 0x405d0000
arr3: .word 0, 0, 0
len: .word 3    #array length=3
str1: .string "pp"
str2: .string " end program"
space: .string "    "
#a1,a2 --> x[],h[]
#a3 --bf16-->[    x       h    ]
#s3 ---> result
.text
#-----------------------------------------------------------#
main:
    la s1, arr1    #s1=x[]
    la s2, arr2    #s2=h[]
    la s3, arr3    #s3=y[]     
    lw s4, len
    add s5, x0, x0    #s5=0 transfer counter
    jal x_fp32tobf16    #transfer to bf16
    
    jal y_fp32tobf16
    jal convolution
 
end_program:
    la a0, str2
    li a7, 4
    ecall
    li a7,10
    ecall
#-----------------------------------------------------------#
x_fp32tobf16:
    lw a1,0(s1)
    addi s1, s1, 4    #x[] next element
    li t0, 0x7F800000    #t0=0x7F800000
    and s6, a1, t0    #s6=exp  (*p&0x7F800000)
    li t1, 0x007FFFFF    #t0=0x007FFFFF
    and s7, a1, t1    #s7=man (*p&0x007FFFFF)
    
    or t1, s6, s7
    beqz t1,eqzero
    beq s6, t0, infinity_NaN
    
    li t0,0xFF800000
    and t1, t0, a1    #keep sign+exp
    srli t0, s7, 8    #man >>8
    li t2, 0x8000
    or t0, t0, t2
    add t0, t0, s7
    
    or t0, t0, t1    #assemble sign + exp + man
    
    li t1,0xFFFF0000    #truncate redundant bits
    and t0, t0, t1
    sw t0, 0(a3)    #store bf16 in a3[]=
    addi a3, a3, 4
    
    #add a0, x0, t0
    #li a7,2
    #ecall
    #la a0, space
    #li a7, 4
    #ecall
    
    addi s5, s5, 1    #counter++
    blt s5, s4, x_fp32tobf16    #counter< 3 loop
    addi s5, x0, 0
    ret
#-----------------------------------------------------------#
y_fp32tobf16:
    lw a2,0(s2)
    addi s2, s2, 4    #x[] next element
    li t0, 0x7F800000    #t0=0x7F800000
    and s6, a2, t0    #s6=exp  (*p&0x7F800000)
    li t1, 0x007FFFFF    #t0=0x007FFFFF
    and s7, a2, t1    #s7=man (*p&0x007FFFFF)
    
    or t1, s6, s7
    beqz t1,eqzero
    beq s6, t0, infinity_NaN
    
    li t0,0xFF800000
    and t1, t0, a2    #keep sign+exp
    srli t0, s7, 8    #man >>8
    li t2, 0x8000
    or t0, t0, t2
    add t0, t0, s7
    
    or t0, t0, t1    #assemble sign + exp + man
    
    li t1,0xFFFF0000    #truncate redundant bits
    and t0, t0, t1
    sw t0, 0(a3)    #store bf16 in a4[]=
    addi a3, a3, 4
    #add a0, x0, t0
    #li a7,2
    #ecall
    #la a0, space
    #li a7, 4
    #ecall
    
    addi s5, s5, 1    #counter++
    blt s5, s4, y_fp32tobf16    #counter< 3 loop
    addi a3, a3, -24    #correction a3
    ret
eqzero:
    jal return_val
infinity_NaN:
    jal return_val
    
return_val:
    li a7,2
    ecall
end:
    li a7,10
    ecall
#----------------------convolution-------------------------------#
convolution:
    addi a5, x0, 0    #i=0 counter
loop_i:
    add s11, x0, x0
    addi t6, x0, 5    #2*len-1=5
    addi a6, x0, 0    #j=0 counter
    loop_j:
        blt a5, a6, end_j    #
        addi t3, a6, 3    #j+3
        bge a5, t3, end_j
        #---bf16 mul----
        sub t1, a5, a6    #i-j
        
        add t1, t1, t1    
        add t1, t1, t1    #4*(i-j)
            add s6, a3, t1
            lw a2, (12)s6    #h[]
        add t1, a6, a6
        add t1, t1, t1    #4*j
            add s5, a3, t1
            lw a1,0(s5)    #x[]

        jal t6, bf16mul        ###### t1 result

        add a1, t1, x0
        add a2, x0, x0
        
        jal t6,fadd    #t0 result
        
        add a1, t0, x0
        add a2, s11, x0
        jal t6,fadd
        
        add s11, x0, t0    #y=y+x*h --> s11= s11+t0
        
end_j:
    
    addi a6,a6, 1    #j++
    blt a6, s4, loop_j     #if j < 3 -> loop_j
        sw s11, (0)s3
        addi s3, s3, 4
        
        mv a0,s11
        li a7,2
        ecall
    
        la a0, space
        li a7, 4
        ecall

    addi a5, a5, 1    #i++
        
    addi t6, x0, 5    #2*len-1=5
    blt a5, t6, loop_i #i<5 --> loop_i
    
    jal end_program
    
#--------------------------------------------#
fadd:
    # fadd(a1 , a2)
    bnez a2, fadd!=z #anyone =0 --> mv
    mv t0, a1
    jalr t6
fadd!=z:
    srli t0, a1, 23    #a1=val_1
    andi t0, t0, 0xFF    #t0=exp_1  assume result exp
    srli t1, a2, 23    #a2=val_2
    andi t1, t1, 0xFF    #t1=exp_2
    
    srli t2, a1, 16
    andi t2, t2, 0x7F    #man_1
    srli t3, a2, 16
    andi t3, t3, 0x7F    #man_2
    li t4, 0x80    #mask of significand
    or t2, t2, t4    #t2=sig_1
    or t3, t3, t4    #t3=sig_2
    sub t4, t0, t1    #diff between exp_1,2 
    blt t4, x0, swap    #if exp_1<exp_2  change result exp
    srl t3, t3, t4    #sig_2 >> diff
    jal fadd_1
swap:
    add t0, t1, x0   #change exp_2 to result exp 
    sub t4, x0, t4    #diff=-diff 
    srl t2, t2, t4    #sig_1 >> diff
fadd_1:
    add t4, t2, t3    #t4=sig_1+sig_2  result sig
    srli t5, t4, 8    #check 
    addi t1, x0, 1
    bne t5, t1, fadd_result
    srli t4, t4,1
    addi t0, t0, 1    #t0=result_exp=exp+1
fadd_result:
    slli t0, t0, 23    #result exp<<23
   
    andi t4, t4, 0x7F    #result man
    slli t4, t4, 16    #man <<16
    or t0, t0, t4    #result
        
    jalr t6
 
#-----------------------------------------#
    
bf16mul:
       ##bf16mul(a1, a2)
    srli s5, a1, 31    #s5= sign_1
    srli s6, a2, 31    #s6= sign_2
    
    li t4, 0x80    #significand mask
    srli s7, a1, 16
    andi s7, s7, 0x7F
    srli s8, a2, 16
    andi s8, s8, 0x7F
    or s7, s7, t4    #s7= sig_1    7+1bits
    or s8, s8, t4    #s8= sig_2
    
    srli s9, a1, 23
    srli s10, a2, 23 
    andi s9, s9, 0xFF    #s9= exp_1    8bits
    andi s10, s10, 0xFF    #s10=exp_2
    
    add t4, x0, x0    #imul result
    add t0, x0, x0    #i counter
imul:
    addi t1, x0, 8   #t1=8   
    bgt t0 , t1, fmul_1
    
getbit:
    srl t2, s8, t0
    andi t2, t2, 1
    addi t0, t0, 1    #i++
    beqz t2, imul
    addi t0,t0 ,-1
    sll t3, s7, t0    #t3=sig_1<<i
    add t4, t3, t4    #r+=a64<<i
    addi t0, t0, 1    #i++
    jal imul
fmul_1:
    srli t4 ,t4, 7    #imul32>>23    ##
    srli t5, t4, 8    #getbit(t4,24)
    andi t5, t5, 1    #sig shift    mshift 
    srl t4, t4, t5    #t4= result sig
    
    add t0,s9, s10    #ea+eb
    addi t0, t0, -127    #-127 ertmp    er
    bnez t5, inc
    
    jal fmul_2      #er=ertmp
inc:
    #mask lowest zero
    slli t2, t0, 1    #ori mask=t0 
    ori t2, t2, 0x1
    and t1, t0, t2
    
    slli t2, t1, 2
    ori t2, t2, 0x3
    and t1, t1, t2
    
    slli t2, t1, 4
    ori t2, t2, 0xF
    and t1, t1, t2
    
    slli t2, t1, 8
    ori t2, t2, 0xFF
    and t1, t1, t2
    
    slli t2, t1, 16
    li t3, 0xFFFF
    or t2, t2, t3
    and t1, t1, t2
    
    li t3, 0x20
    sll t2, t1, t3
    li t3, 0xFFFFFFFF
    or t2, t2, t3
    and t1, t1, t2    #return mask = t1
    
    slli t2, t1, 1
    ori t2, t2, 1
    xor t2, t1, t2    #z1
    
    xor t1, t1, t3    #~mask
    and t1, t0, t1    #x&~mask
    or t0, t1, t2    #inc return = t0    er
fmul_2:
    xor t1, s5, s6    #sign result
    slli t1, t1, 31    #sign<<31
    
    andi t0, t0, 0xFF
    slli t0, t0,23    #exp result
    
    andi t4, t4, 0x7F    #man result
    slli t4, t4, 16    #man <<16
    or t1, t1, t0
    or t1, t1, t4    #t1= result
        
    jalr t6