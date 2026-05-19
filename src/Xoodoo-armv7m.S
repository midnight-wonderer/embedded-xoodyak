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

    .align  4
.L_RC:
    .word   0x00000058  # _rc12
    .word   0x00000038  # _rc11
    .word   0x000003C0  # _rc10
    .word   0x000000D0  # _rc9
    .word   0x00000120  # _rc8
    .word   0x00000014  # _rc7
    .word   0x00000060  # _rc6
    .word   0x0000002C  # _rc5
    .word   0x00000380  # _rc4
    .word   0x000000F0  # _rc3
    .word   0x000001A0  # _rc2
    .word   0x00000012  # _rc1
.L_RC_end:

.global Xoodoo_Permute_Nrounds
.type   Xoodoo_Permute_Nrounds, %function
Xoodoo_Permute_Nrounds:
    @ Input: r0 = state pointer, r1 = nrounds
    push    {r4-r11, lr}     @ Save callee-saved registers

    @ Calculate starting RC pointer: .L_RC + (12 - nrounds) * 4
    adr     r2, .L_RC
    movs    r3, #12
    subs    r1, r3, r1       @ r1 = 12 - nrounds
    add     r2, r2, r1, lsl #2 @ r2 = RC pointer

    @ Push state pointer and RC pointer to stack
    push    {r0, r2}         @ sp+0 = RC pointer, sp+4 = state pointer

    @ Load state lanes into r0-r11
    ldm     r0, {r0-r11}

.L_round_loop:
    @ -------------------------------------------------------------
    @ Theta: Column Parity Mixer
    @ -------------------------------------------------------------
    eor     r12, r0, r4
    eor     r12, r12, r8    @ r12 = P0
    eor     lr, r1, r5
    eor     lr, lr, r9      @ lr = P1
    push    {r12, lr}       @ sp+0 = P0, sp+4 = P1 (after register ordering rules: sp+0 = r12, sp+4 = lr)
    
    eor     r12, r2, r6
    eor     r12, r12, r10   @ r12 = P2
    eor     lr, r3, r7
    eor     lr, lr, r11     @ lr = P3
    push    {r12, lr}       @ sp+0 = P2, sp+4 = P3
    @ Stack layout now:
    @ sp+0: P2, sp+4: P3, sp+8: P0, sp+12: P1, sp+16: RC ptr, sp+20: state ptr

    @ E0 (uses P3 at sp+4):
    ldr     lr, [sp, #4]
    eor     lr, lr, lr, ror #9
    ror     lr, lr, #18
    eor     r0, r0, lr
    eor     r4, r4, lr
    eor     r8, r8, lr

    @ E1 (uses P0 at sp+8):
    ldr     lr, [sp, #8]
    eor     lr, lr, lr, ror #9
    ror     lr, lr, #18
    eor     r1, r1, lr
    eor     r5, r5, lr
    eor     r9, r9, lr

    @ E2 (uses P1 at sp+12):
    ldr     lr, [sp, #12]
    eor     lr, lr, lr, ror #9
    ror     lr, lr, #18
    eor     r2, r2, lr
    eor     r6, r6, lr
    eor     r10, r10, lr

    @ E3 (uses P2 at sp+0):
    ldr     lr, [sp, #0]
    eor     lr, lr, lr, ror #9
    ror     lr, lr, #18
    eor     r3, r3, lr
    eor     r7, r7, lr
    eor     r11, r11, lr

    add     sp, sp, #16     @ Pop parities

    @ -------------------------------------------------------------
    @ Rho-west: Plane shift Row 1 & Rotate Row 2
    @ -------------------------------------------------------------
    mov     r12, r7
    mov     r7, r6
    mov     r6, r5
    mov     r5, r4
    mov     r4, r12

    ror     r8, r8, #21
    ror     r9, r9, #21
    ror     r10, r10, #21
    ror     r11, r11, #21

    @ -------------------------------------------------------------
    @ Iota: Round Constant
    @ -------------------------------------------------------------
    ldr     r12, [sp, #0]   @ r12 = RC pointer
    ldr     lr, [r12], #4   @ lr = RC value, advance pointer by 4
    str     r12, [sp, #0]   @ save RC pointer back
    eor     r0, r0, lr

    @ -------------------------------------------------------------
    @ Chi: Non-linear step
    @ -------------------------------------------------------------
    bic     r12, r8, r4
    eor     r0, r0, r12
    bic     r12, r0, r8
    eor     r4, r4, r12
    bic     r12, r4, r0
    eor     r8, r8, r12

    bic     r12, r9, r5
    eor     r1, r1, r12
    bic     r12, r1, r9
    eor     r5, r5, r12
    bic     r12, r5, r1
    eor     r9, r9, r12

    bic     r12, r10, r6
    eor     r2, r2, r12
    bic     r12, r2, r10
    eor     r6, r6, r12
    bic     r12, r6, r2
    eor     r10, r10, r12

    bic     r12, r11, r7
    eor     r3, r3, r12
    bic     r12, r3, r11
    eor     r7, r7, r12
    bic     r12, r7, r3
    eor     r11, r11, r12

    @ -------------------------------------------------------------
    @ Rho-east: Plane shift Row 1 & Rotate/Shift Row 2
    @ -------------------------------------------------------------
    ror     r4, r4, #31
    ror     r5, r5, #31
    ror     r6, r6, #31
    ror     r7, r7, #31

    ror     r12, r8, #24
    ror     lr, r9, #24
    ror     r8, r10, #24
    ror     r9, r11, #24
    mov     r10, r12
    mov     r11, lr

    @ -------------------------------------------------------------
    @ Loop control
    @ -------------------------------------------------------------
    ldr     lr, [sp, #0]     @ lr = current RC pointer
    adr     r12, .L_RC_end
    cmp     lr, r12
    blo     .L_round_loop

    @ Write state back and return
    ldr     r12, [sp, #4]    @ r12 = state pointer
    stm     r12, {r0-r11}
    add     sp, sp, #8       @ Pop RC pointer and state pointer
    pop     {r4-r11, pc}

.global Xoodoo_Permute_6rounds
.type   Xoodoo_Permute_6rounds, %function
Xoodoo_Permute_6rounds:
    movs    r1, #6
    b       Xoodoo_Permute_Nrounds

.global Xoodoo_Permute_12rounds
.type   Xoodoo_Permute_12rounds, %function
Xoodoo_Permute_12rounds:
    movs    r1, #12
    b       Xoodoo_Permute_Nrounds
