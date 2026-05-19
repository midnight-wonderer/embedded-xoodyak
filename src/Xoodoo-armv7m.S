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
@ ARMv7m architecture (Cortex-M3, ...).

        .thumb
    .syntax unified
.text

.equ _r0   , 5
.equ _r1   , 14
.equ _t3   , 1

.equ _w1   , 11

.equ _e0   , 2
.equ _e1   , 8

.equ _rc12 , 0x00000058
.equ _rc11 , 0x00000038
.equ _rc10 , 0x000003C0
.equ _rc9  , 0x000000D0
.equ _rc8  , 0x00000120
.equ _rc7  , 0x00000014
.equ _rc6  , 0x00000060
.equ _rc5  , 0x0000002C
.equ _rc4  , 0x00000380
.equ _rc3  , 0x000000F0
.equ _rc2  , 0x000001A0
.equ _rc1  , 0x00000012

.equ _rc6x1, 0x00000003
.equ _rc5x2, 0x0b000000
.equ _rc4x3, 0x07000000
.equ _rc3x4, 0x000f0000
.equ _rc2x5, 0x0000d000
.equ _rc1x6, 0x00000048

.equ _rc12x1, 0xc0000002
.equ _rc11x2, 0x0e000000
.equ _rc10x3, 0x07800000
.equ _rc9x4 , 0x000d0000
.equ _rc8x5 , 0x00009000
.equ _rc7x6 , 0x00000050
.equ _rc6x7 , 0x0000000c
.equ _rc5x8 , 0x2c000000
.equ _rc4x9 , 0x1c000000
.equ _rc3x10, 0x003c0000
.equ _rc2x11, 0x00034000
.equ _rc1x12, 0x00000120

.macro    mXor3   ro, a0, a1, a2, rho_e1, rho_e2
    .if ((\rho_e1)%32) == 0
    eors    \ro, \a0, \a1
    .else
    eor     \ro, \a0, \a1, ROR #(32-(\rho_e1))%32
    .endif
    .if ((\rho_e2)%32) == 0
    eors    \ro, \ro, \a2
    .else
    eor     \ro, \ro, \a2, ROR #(32-(\rho_e2))%32
    .endif
    .endm

.macro    mRliXor ro, ri, rot
    .if ((\rot)%32) == 0
    eors    \ro, \ro, \ri
    .else
    eor     \ro, \ro, \ri, ROR #(32-(\rot))%32
    .endif
    .endm

.macro    mRloXor ro, ri, rot
    .if ((\rot)%32) == 0
    eors    \ro, \ro, \ri
    .else
    eor     \ro, \ri, \ro, ROR #(32-(\rot))%32
    .endif
    .endm

.macro    mChi3   a0,a1,a2,r0,r1
    bic     \r0, \a2, \a1, ROR #_w1
    eors    \a0, \a0, \r0, ROR #32-_w1
    bic     \r1, \a0, \a2, ROR #32-_w1
    eors    \a1, \a1, \r1
    bic     \r1, \a1, \a0
    eors    \a2, \a2, \r1, ROR #_w1
    .endm

.macro    mRound  r6i, r7i, r8i, r9i, r6w, r7w, r8w, r9w, r10i, r11i, r12i, lri, rho_e1, rho_we2, rc

    @ Theta: Column Parity Mixer (with late Rho-west, Rho-east bit rotations)
    mXor3   r0, r5, \r9i, \lri, \rho_e1, \rho_we2
    mXor3   r1, r2, \r6i, \r10i, \rho_e1, \rho_we2
    mRliXor r0, r0, _r1-_r0
    mRloXor r2, r0, 32-_r0
    mRloXor \r6i, r0, \rho_e1-_r0
    mRloXor \r10i, r0, \rho_we2-_r0

    mXor3   r0, r3, \r7i, \r11i, \rho_e1, \rho_we2
    mRliXor r1, r1, _r1-_r0
    mRloXor r3, r1, 32-_r0
    mRloXor \r7i, r1, \rho_e1-_r0
    mRloXor \r11i, r1, \rho_we2-_r0

    mXor3   r1, r4, \r8i, \r12i, \rho_e1, \rho_we2
    mRliXor r0, r0, _r1-_r0
    mRloXor r4, r0, 32-_r0
    mRloXor \r8i, r0, \rho_e1-_r0
    mRloXor \r12i, r0, \rho_we2-_r0

    mRliXor r1, r1, _r1-_r0
    mRloXor r5, r1, 32-_r0
    mRloXor \r9i, r1, \rho_e1-_r0
    mRloXor \lri, r1, \rho_we2-_r0
    @ After Theta the whole state is rotated -r0
    @ from here we must use a1.w instead of a1.i

    @ Iota: round constant
    .if      \rc == 0xc0000002
    eor     r2, r2, #0x00000002
    eor     r2, r2, #0xc0000000
    .else
    eor     r2, r2, #\rc
    .endif

    @ Chi: non linear step, on colums
    mChi3   r2, \r6w, \r10i, r0, r1
    mChi3   r3, \r7w, \r11i, r0, r1
    mChi3   r4, \r8w, \r12i, r0, r1
    mChi3   r5, \r9w, \lri, r0, r1
    .endm

.global Xoodoo_Permute_6rounds
.type	Xoodoo_Permute_6rounds, %function;
Xoodoo_Permute_6rounds:
    push    {r0,r4-r11,lr}
    ldmia   r0!, {r2-r5}
    ldmia   r0!, {r8-r9}
    ldmia   r0!, {r6-r7}
    ldmia   r0, {r10-r12,lr}
    mRound  r8, r9, r6, r7,    r7, r8, r9, r6,    r10, r11, r12, lr,   32,      32, _rc6x1
    mRound  r7, r8, r9, r6,    r6, r7, r8, r9,    r12, lr, r10, r11,    1, _e1+_w1, _rc5x2
    mRound  r6, r7, r8, r9,    r9, r6, r7, r8,    r10, r11, r12, lr,    1, _e1+_w1, _rc4x3
    mRound  r9, r6, r7, r8,    r8, r9, r6, r7,    r12, lr, r10, r11,    1, _e1+_w1, _rc3x4
    mRound  r8, r9, r6, r7,    r7, r8, r9, r6,    r10, r11, r12, lr,    1, _e1+_w1, _rc2x5
    mRound  r7, r8, r9, r6,    r6, r7, r8, r9,    r12, lr, r10, r11,    1, _e1+_w1, _rc1x6
    pop     {r0,r1}
    ror     r2, r2, #32-(6*_r0)%32
    ror     r3, r3, #32-(6*_r0)%32
    ror     r4, r4, #32-(6*_r0)%32
    ror     r5, r5, #32-(6*_r0)%32
    ror     r6, r6, #32-(6*_r0+1)%32
    ror     r7, r7, #32-(6*_r0+1)%32
    ror     r8, r8, #32-(6*_r0+1)%32
    ror     r9, r9, #32-(6*_r0+1)%32
    ror     r10, r10, #32-(6*_r0+_e1+_w1)%32
    ror     r11, r11, #32-(6*_r0+_e1+_w1)%32
    ror     r12, r12, #32-(6*_r0+_e1+_w1)%32
    ror     lr, lr, #32-(6*_r0+_e1+_w1)%32
    stmia   r0, {r2-r12,lr}
    mov     r4, r1
    pop     {r5-r11,pc}
    .align  4

.global Xoodoo_Permute_12rounds
.type	Xoodoo_Permute_12rounds, %function;
Xoodoo_Permute_12rounds:
    push    {r0,r4-r11,lr}
    ldmia   r0, {r2-r12,lr}
    mRound  r6, r7, r8, r9,    r9, r6, r7, r8,    r10, r11, r12, lr,   32,      32, _rc12x1
    mRound  r9, r6, r7, r8,    r8, r9, r6, r7,    r12, lr, r10, r11,    1, _e1+_w1, _rc11x2
    mRound  r8, r9, r6, r7,    r7, r8, r9, r6,    r10, r11, r12, lr,    1, _e1+_w1, _rc10x3
    mRound  r7, r8, r9, r6,    r6, r7, r8, r9,    r12, lr, r10, r11,    1, _e1+_w1, _rc9x4
    mRound  r6, r7, r8, r9,    r9, r6, r7, r8,    r10, r11, r12, lr,    1, _e1+_w1, _rc8x5
    mRound  r9, r6, r7, r8,    r8, r9, r6, r7,    r12, lr, r10, r11,    1, _e1+_w1, _rc7x6
    mRound  r8, r9, r6, r7,    r7, r8, r9, r6,    r10, r11, r12, lr,    1, _e1+_w1, _rc6x7
    mRound  r7, r8, r9, r6,    r6, r7, r8, r9,    r12, lr, r10, r11,    1, _e1+_w1, _rc5x8
    mRound  r6, r7, r8, r9,    r9, r6, r7, r8,    r10, r11, r12, lr,    1, _e1+_w1, _rc4x9
    mRound  r9, r6, r7, r8,    r8, r9, r6, r7,    r12, lr, r10, r11,    1, _e1+_w1, _rc3x10
    mRound  r8, r9, r6, r7,    r7, r8, r9, r6,    r10, r11, r12, lr,    1, _e1+_w1, _rc2x11
    mRound  r7, r8, r9, r6,    r6, r7, r8, r9,    r12, lr, r10, r11,    1, _e1+_w1, _rc1x12
    ror     r2, r2, #32-(12*_r0)%32
    ror     r3, r3, #32-(12*_r0)%32
    ror     r4, r4, #32-(12*_r0)%32
    ror     r5, r5, #32-(12*_r0)%32
    ror     r6, r6, #32-(12*_r0+1)%32
    ror     r7, r7, #32-(12*_r0+1)%32
    ror     r8, r8, #32-(12*_r0+1)%32
    ror     r9, r9, #32-(12*_r0+1)%32
    ror     r10, r10, #32-(12*_r0+_e1+_w1)%32
    ror     r11, r11, #32-(12*_r0+_e1+_w1)%32
    ror     r12, r12, #32-(12*_r0+_e1+_w1)%32
    ror     lr, lr, #32-(12*_r0+_e1+_w1)%32
    pop     {r0,r1}
    stmia   r0, {r2-r12,lr}
    mov     r4, r1
    pop     {r5-r11,pc}
    .align  4
