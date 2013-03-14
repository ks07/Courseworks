    ; Example test file of all COMS12600 assignemnt instructions
    ; with their assembly syntax
    ; Note: this program is not supposed to make sense ---
    ; it is simply an example of how to use each instruction
    ; 
    ; Simon Hollis (simon@cs.bris.ac.uk)
    ; 01 March 2013
 
    THUMB

    ORIGIN 0x20000000

    ADDI r0, #1
    ADDR r1, r2, r3
    ADDSPI r2, sp, #20
    INCSP sp, #8

    ADDPCI r3, pc, #4
    SUBI r5, #2
    SUBR r2, r3, r5
    DECSP sp, #8
    MULR r2, r3

    ANDR r3, r1
    ORR r2, r3
    EORR r3, r4
    NEGR r0, r1

    LSLI r0, r2, #1
    LSLR r0, r2
    LSRI r0, r2, #2
    LSRR r0, r2
    ASRI r0, r2, #2

    MOVI r2, #20
    MOVNR r0, r2
    MOVRSP sp, r0

    LDRI r0, [r2, #4]
    LDRR r0, [r1, r2]
    LDRSPI r0, [sp,  #4 ]
    LDRPCI r0, [pc, #4]
    STRI r0, [r3, #12]
    STRR r0, [r2, r3]
    STRSPI r2, [sp, #32]
    PUSH {lr}
    POP  {pc}

    BU Foobar
    BEQ Foobar
    BNE Foobar
    BGT Foobar
    BLT Foobar
    BL Foobar
    BR lr
    SVC 0x10


    ; test of PC-relative loads. The target data
    ; must be aligned on a 32-bit word boundary
    LDRI r0, =Food
Foobar
    LDRI r0, =Food
    LDRI r0, =Food
    LDRI r0, =Food
    LDRI r0, =Food

    LDRR r4, [r2, r3]
    LDRR r3, [r2, r5]
Food
    DCD 0xbad00d
    

