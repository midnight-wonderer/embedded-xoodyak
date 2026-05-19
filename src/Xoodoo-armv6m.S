@
@ The eXtended Keccak Code Package (XKCP)
@ https://github.com/XKCP/XKCP
@
@ The Xoodoo permutation, designed by Joan Daemen, Seth Hoffert, Gilles Van Assche and Ronny Van Keer.
@
@ Implementation by Ronny Van Keer, hereby denoted as "the implementer".
@
@ For more information, feedback or questions, please refer to the Keccak Team website:
@ https://keccak.team/
@
@ To the extent possible under law, the implementer has waived all copyright
@ and related or neighboring rights to the source code in this file.
@ http://creativecommons.org/publicdomain/zero/1.0/
@

@ WARNING: These functions work only on little endian CPU with
@ ARMv6m architecture (Cortex-M0, ...).

        .thumb
    .syntax unified
.text

@ offsets in RAM state
.equ _oA00      , 0*4
.equ _oA01      , 1*4
.equ _oA02      , 2*4
.equ _oA03      , 3*4
.equ _oA10      , 4*4
.equ _oA11      , 5*4
.equ _oA12      , 6*4
.equ _oA13      , 7*4
.equ _oA20      , 8*4
.equ _oA21      , 9*4
.equ _oA22      , 10*4
.equ _oA23      , 11*4

@ possible locations of state lanes
.equ locRegL    , 1
.equ locRegH    , 2
.equ locMem     , 3

.equ _r0   , 5
.equ _r1   , 14
.equ _r2   , 1

.equ _w1   , 11

.equ _e0   , 2
.equ _e1   , 8

.macro    mXor3   ro, a0, a1, a2, loc, tt
    mov     \ro, \a1
    eors    \ro, \ro, \a2
    .if \loc == locRegL
    eors    \ro, \ro, \a0
    .else
    .if \loc == locRegH
    mov     \tt, \a0
    .else
    ldr     \tt, [sp, #\a0]
    .endif
    eors    \ro, \ro, \tt
    .endif
    .endm

.macro    mXor    ro, ri, tt, loc
    .if \loc == locRegL
    eors    \ro, \ro, \ri
    .else
    .if \loc == locRegH
    mov     \tt, \ro
    eors    \tt, \tt, \ri
    mov     \ro, \tt
    .else
    ldr     \tt, [sp, #\ro]
    eors    \tt, \tt, \ri
    str     \tt, [sp, #\ro]
    .endif
    .endif
    .endm

.macro    mChi3   a0,a1,a2,r0,r1,a0s,loc
    mov     \r1, \a2
    mov     \r0, \a1
    bics    \r1, \r1, \r0
    eors    \a0, \a0, \r1
    .if \loc != locRegL
    .if \loc == locRegH
    mov     \a0s, \a0
    .else
    str     \a0, [sp, #\a0s]
    .endif
    .endif

    mov     \r0, \a0
    bics    \r0, \r0, \a2
    mov     \r1, \a1
    eors    \r1, \r1, \r0
    mov     \a1, \r1

    bics    \r1, \r1, \a0
    eors    \a2, \a2, \r1
    .endm

.macro    mRound  offsetRC, offsetA03

    @ Theta: Column Parity Mixer
    mXor3   r0, \offsetA03, lr, r7, locMem, r2
    mov     r1, r0
    movs    r2, #32-(_r1-_r0)
    rors    r1, r1, r2
    eors    r1, r1, r0
    movs    r2, #32-_r0
    rors    r1, r1, r2
    mXor3   r0, r3, r10, r4, locRegL, r2
    mXor    r3, r1, r2, locRegL
    mXor    r10, r1, r2, locRegH
    mXor    r4, r1, r2, locRegL

    mov     r1, r0
    movs    r2, #32-(_r1-_r0)
    rors    r1, r1, r2
    eors    r1, r1, r0
    movs    r2, #32-_r0
    rors    r1, r1, r2
    mXor3   r0, r8, r11, r5, locRegH, r2
    mXor    r8, r1, r2, locRegH
    mXor    r11, r1, r2, locRegH
    mXor    r5, r1, r2, locRegL

    mov     r1, r0
    movs    r2, #32-(_r1-_r0)
    rors    r1, r1, r2
    eors    r1, r1, r0
    movs    r2, #32-_r0
    rors    r1, r1, r2
    mXor3   r0, r9, r12, r6, locRegH, r2
    mXor    r9, r1, r2, locRegH
    mXor    r12, r1, r2, locRegH
    mXor    r6, r1, r2, locRegL

    mov     r1, r0
    movs    r2, #32-(_r1-_r0)
    rors    r1, r1, r2
    eors    r1, r1, r0
    movs    r2, #32-_r0
    rors    r1, r1, r2
    mXor    \offsetA03, r1, r2, locMem
    mXor    lr, r1, r2, locRegH
    mXor    r7, r1, r2, locRegL

    @ Rho-west: Plane shift
    movs    r0, #32-_w1
    rors    r4, r4, r0
    rors    r5, r5, r0
    rors    r6, r6, r0
    rors    r7, r7, r0
    mov     r0, lr
    mov     lr, r12
    mov     r12, r11
    mov     r11, r10
    mov     r10, r0

    @ Iota: round constant
    ldr     r0, [sp, #\offsetRC]
    ldmia   r0!, {r1}
    str     r0, [sp, #\offsetRC]
    eors    r3, r3, r1

    @ Chi: non linear step, on colums
    mChi3   r3, r10, r4, r0, r1, r3, locRegL
    mov     r2, r8
    mChi3   r2, r11, r5, r0, r1, r8, locRegH
    mov     r2, r9
    mChi3   r2, r12, r6, r0, r1, r9, locRegH
    ldr     r2, [sp, #\offsetA03]
    mChi3   r2, lr, r7, r0, r1, \offsetA03, locMem

    @ Rho-east: Plane shift
    movs    r0, #32-1
    mov     r1, r10
    rors    r1, r1, r0
    mov     r10, r1
    mov     r1, r11
    rors    r1, r1, r0
    mov     r11, r1
    mov     r1, r12
    rors    r1, r1, r0
    mov     r12, r1
    mov     r1, lr
    rors    r1, r1, r0
    mov     lr, r1

    movs    r0, #32-_e1
    rors    r4, r4, r0
    rors    r5, r5, r0
    rors    r6, r6, r0
    rors    r7, r7, r0

    mov     r0, r4
    mov     r4, r6
    mov     r6, r0
    mov     r0, r5
    mov     r5, r7
    mov     r7, r0

    .endm

@ offsets on stack
.equ Xoodoo_Permute_Nrounds_offsetA03   , 0
.equ Xoodoo_Permute_Nrounds_offsetRC    , 4
.equ Xoodoo_Permute_Nrounds_SAS         , 8
.equ Xoodoo_Permute_Nrounds_offsetState , Xoodoo_Permute_Nrounds_SAS

.global Xoodoo_Permute_Nrounds
.type	Xoodoo_Permute_Nrounds, %function;
Xoodoo_Permute_Nrounds:
    push    {r4-r6,lr}
    mov     r2, r8
    mov     r3, r9
    mov     r4, r10
    mov     r5, r11
    push    {r0,r2-r5,r7}

    sub     sp, #Xoodoo_Permute_Nrounds_SAS
    adr     r2, Xoodoo_Permute_RoundConstants12
    lsls    r1, r1, #2
    subs    r2, r2, r1
    str     r2, [sp, #Xoodoo_Permute_Nrounds_offsetRC]

    ldm     r0!, {r3,r5,r6,r7}
    mov     r8, r5
    mov     r9, r6
    str     r7, [sp, #Xoodoo_Permute_Nrounds_offsetA03]
    ldm     r0!, {r4,r5,r6,r7}
    mov     r10, r4
    mov     r11, r5
    mov     r12, r6
    mov     lr, r7
    ldm     r0!, {r4,r5,r6,r7}
Xoodoo_Permute_Nrouds_Loop:
    mRound  Xoodoo_Permute_Nrounds_offsetRC, Xoodoo_Permute_Nrounds_offsetA03
    ldr     r0, [sp, #Xoodoo_Permute_Nrounds_offsetRC]
    ldr     r0, [r0]
    cmp     r0, #0
    beq     Xoodoo_Permute_Nrouds_Done
    b       Xoodoo_Permute_Nrouds_Loop
Xoodoo_Permute_Nrouds_Done:
    ldr     r0, [sp, #Xoodoo_Permute_Nrounds_offsetState]

    stm     r0!, {r3}
    mov     r1, r8
    mov     r2, r9
    ldr     r3, [sp, #Xoodoo_Permute_Nrounds_offsetA03]
    stm     r0!, {r1,r2,r3}

    mov     r1, r10
    mov     r2, r11
    mov     r3, r12
    stm     r0!, {r1,r2,r3}

    mov     r1, lr
    stm     r0!, {r1,r4,r5,r6,r7}

    add     sp, #Xoodoo_Permute_Nrounds_SAS
    pop     {r0-r4,r7}
    mov     r8, r1
    mov     r9, r2
    mov     r10, r3
    mov     r11, r4
    pop     {r4-r6,pc}
    .align  4

Xoodoo_Permute_RoundConstants:
    .long      0x00000058
    .long      0x00000038
    .long      0x000003C0
    .long      0x000000D0
    .long      0x00000120
    .long      0x00000014
    .long      0x00000060
    .long      0x0000002C
    .long      0x00000380
    .long      0x000000F0
    .long      0x000001A0
    .long      0x00000012
Xoodoo_Permute_RoundConstants12:
    .long      0
    .align  4

.global Xoodoo_Permute_6rounds
.type	Xoodoo_Permute_6rounds, %function;
Xoodoo_Permute_6rounds:
    movs    r1, #6
    b       Xoodoo_Permute_Nrounds
    .align  4

.global Xoodoo_Permute_12rounds
.type	Xoodoo_Permute_12rounds, %function;
Xoodoo_Permute_12rounds:
    movs    r1, #12
    b       Xoodoo_Permute_Nrounds
    .align  4
