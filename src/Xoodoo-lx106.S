    .text
    .literal_position
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

    .align  4
.L_RC_addr:
    .word   .L_RC

    .align  4
.L_RC_end:
    .word   .L_RC + 48

    .align  4
.global Xoodoo_Permute_Nrounds
.type   Xoodoo_Permute_Nrounds, @function
Xoodoo_Permute_Nrounds:
    # Entry: a2 = state pointer, a3 = nr (number of rounds)
    # Stack layout (64 bytes):
    # sp + 0..28  : callee-saved registers (a8-a15)
    # sp + 32     : state pointer (a2)
    # sp + 36     : current RC pointer
    # sp + 40..52 : P0, P1, P2, P3
    # sp + 56     : free / padding
    addi    sp, sp, -64
    s32i    a8, sp, 0
    s32i    a9, sp, 4
    s32i    a10, sp, 8
    s32i    a11, sp, 12
    s32i    a12, sp, 16
    s32i    a13, sp, 20
    s32i    a14, sp, 24
    s32i    a15, sp, 28
    s32i    a2, sp, 32      # Save state pointer

    # Calculate RC pointer: RC_base + (12 - nr) * 4
    l32r    a8, .L_RC_addr  # a8 = RC_base
    movi    a9, 12
    sub     a9, a9, a3      # a9 = 12 - nr
    slli    a9, a9, 2       # a9 = (12 - nr) * 4
    add     a8, a8, a9      # a8 = pointer to RC[12 - nr]
    s32i    a8, sp, 36      # Save current RC pointer

    # Load state lanes into registers
    l32i    a4, a2, 0       # a4 = A00
    l32i    a5, a2, 4       # a5 = A01
    l32i    a6, a2, 8       # a6 = A02
    l32i    a7, a2, 12      # a7 = A03
    l32i    a8, a2, 16      # a8 = A10
    l32i    a9, a2, 20      # a9 = A11
    l32i    a10, a2, 24     # a10 = A12
    l32i    a11, a2, 28     # a11 = A13
    l32i    a12, a2, 32     # a12 = A20
    l32i    a13, a2, 36     # a13 = A21
    l32i    a14, a2, 40     # a14 = A22
    l32i    a15, a2, 44     # a15 = A23

.L_round_loop:
    # -------------------------------------------------------------
    # Theta: Column Parity Mixer
    # -------------------------------------------------------------
    # P0 = A00 ^ A10 ^ A20
    xor     a2, a4, a8
    xor     a2, a2, a12
    s32i    a2, sp, 40      # Store P0

    # P1 = A01 ^ A11 ^ A21
    xor     a2, a5, a9
    xor     a2, a2, a13
    s32i    a2, sp, 44      # Store P1

    # P2 = A02 ^ A12 ^ A22
    xor     a2, a6, a10
    xor     a2, a2, a14
    s32i    a2, sp, 48      # Store P2

    # P3 = A03 ^ A13 ^ A23
    xor     a2, a7, a11
    xor     a2, a2, a15
    s32i    a2, sp, 52      # Store P3

    # Apply E0 to Col 0: using P3 (sp + 52)
    l32i    a2, sp, 52      # a2 = P3
    ssai    27              # Rotate by 5 (right by 27)
    src     a3, a2, a2      # a3 = ROTL(P3, 5)
    ssai    18              # Rotate by 14 (right by 18)
    src     a2, a2, a2      # a2 = ROTL(P3, 14)
    xor     a2, a3, a2      # a2 = E0
    xor     a4, a4, a2      # A00 ^= E0
    xor     a8, a8, a2      # A10 ^= E0
    xor     a12, a12, a2    # A20 ^= E0

    # Apply E1 to Col 1: using P0 (sp + 40)
    l32i    a2, sp, 40      # a2 = P0
    ssai    27
    src     a3, a2, a2
    ssai    18
    src     a2, a2, a2
    xor     a2, a3, a2
    xor     a5, a5, a2      # A01 ^= E1
    xor     a9, a9, a2      # A11 ^= E1
    xor     a13, a13, a2    # A21 ^= E1

    # Apply E2 to Col 2: using P1 (sp + 44)
    l32i    a2, sp, 44      # a2 = P1
    ssai    27
    src     a3, a2, a2
    ssai    18
    src     a2, a2, a2
    xor     a2, a3, a2
    xor     a6, a6, a2      # A02 ^= E2
    xor     a10, a10, a2    # A12 ^= E2
    xor     a14, a14, a2    # A22 ^= E2

    # Apply E3 to Col 3: using P2 (sp + 48)
    l32i    a2, sp, 48      # a2 = P2
    ssai    27
    src     a3, a2, a2
    ssai    18
    src     a2, a2, a2
    xor     a2, a3, a2
    xor     a7, a7, a2      # A03 ^= E3
    xor     a11, a11, a2    # A13 ^= E3
    xor     a15, a15, a2    # A23 ^= E3

    # -------------------------------------------------------------
    # Rho-west: Plane Shift & Rotate Row 2
    # -------------------------------------------------------------
    # Rotate Row 2 (a12, a13, a14, a15) by 11 bits (right by 21)
    ssai    21
    src     a12, a12, a12
    src     a13, a13, a13
    src     a14, a14, a14
    src     a15, a15, a15

    # Shift Row 1 (a8, a9, a10, a11) by 1 lane
    mov     a2, a11         # Temp = A13
    mov     a11, a10        # A13 = A12
    mov     a10, a9         # A12 = A11
    mov     a9, a8          # A11 = A10
    mov     a8, a2          # A10 = Temp

    # -------------------------------------------------------------
    # Iota: Round Constant
    # -------------------------------------------------------------
    l32i    a2, sp, 36      # a2 = current RC pointer
    l32i    a3, a2, 0       # a3 = RC[i]
    addi    a2, a2, 4       # Advance RC pointer
    s32i    a2, sp, 36      # Save RC pointer
    xor     a4, a4, a3      # A00 ^= RC[i]

    # -------------------------------------------------------------
    # Chi: Non-linear Step (on Columns)
    # -------------------------------------------------------------
    movi    a3, -1          # Keep -1 in a3 for logical NOTs

    # Col 0: a4, a8, a12
    xor     a2, a8, a3      # a2 = ~A10
    and     a2, a2, a12     # a2 = ~A10 & A20
    xor     a4, a4, a2      # A00 ^= a2

    xor     a2, a12, a3     # a2 = ~A20
    and     a2, a2, a4      # a2 = ~A20 & A00 (uses new A00)
    xor     a8, a8, a2      # A10 ^= a2

    xor     a2, a4, a3      # a2 = ~A00
    and     a2, a2, a8      # a2 = ~A00 & A10 (uses new A10)
    xor     a12, a12, a2    # A20 ^= a2

    # Col 1: a5, a9, a13
    xor     a2, a9, a3      # a2 = ~A11
    and     a2, a2, a13     # a2 = ~A11 & A21
    xor     a5, a5, a2      # A01 ^= a2

    xor     a2, a13, a3     # a2 = ~A21
    and     a2, a2, a5      # a2 = ~A21 & A01 (uses new A01)
    xor     a9, a9, a2      # A11 ^= a2

    xor     a2, a5, a3      # a2 = ~A01
    and     a2, a2, a9      # a2 = ~A01 & A11 (uses new A11)
    xor     a13, a13, a2    # A21 ^= a2

    # Col 2: a6, a10, a14
    xor     a2, a10, a3     # a2 = ~A12
    and     a2, a2, a14     # a2 = ~A12 & A22
    xor     a6, a6, a2      # A02 ^= a2

    xor     a2, a14, a3     # a2 = ~A22
    and     a2, a2, a6      # a2 = ~A22 & A02 (uses new A02)
    xor     a10, a10, a2    # A12 ^= a2

    xor     a2, a6, a3      # a2 = ~A02
    and     a2, a2, a10     # a2 = ~A02 & A12 (uses new A12)
    xor     a14, a14, a2    # A22 ^= a2

    # Col 3: a7, a11, a15
    xor     a2, a11, a3     # a2 = ~A13
    and     a2, a2, a15     # a2 = ~A13 & A23
    xor     a7, a7, a2      # A03 ^= a2

    xor     a2, a15, a3     # a2 = ~A23
    and     a2, a2, a7      # a2 = ~A23 & A03 (uses new A03)
    xor     a11, a11, a2    # A13 ^= a2

    xor     a2, a7, a3      # a2 = ~A03
    and     a2, a2, a11     # a2 = ~A03 & A13 (uses new A13)
    xor     a15, a15, a2    # A23 ^= a2

    # -------------------------------------------------------------
    # Rho-east: Plane Shift & Rotate Rows
    # -------------------------------------------------------------
    # Rotate Row 1 by 1 bit (right by 31)
    ssai    31
    src     a8, a8, a8
    src     a9, a9, a9
    src     a10, a10, a10
    src     a11, a11, a11

    # Shift & Rotate Row 2 by 8 bits (right by 24)
    ssai    24
    src     a2, a15, a15    # Temp = ROTL(A23, 8)
    src     a15, a13, a13   # A23 = ROTL(A21, 8)
    mov     a13, a2         # A21 = Temp

    src     a2, a14, a14    # Temp = ROTL(A22, 8)
    src     a14, a12, a12   # A22 = ROTL(A20, 8)
    mov     a12, a2         # A20 = Temp

    # Loop termination check
    l32i    a2, sp, 36      # a2 = current RC pointer
    l32r    a3, .L_RC_end   # a3 = RC end pointer
    bltu    a2, a3, .L_round_loop

    # Save registers back to state
    l32i    a2, sp, 32      # a2 = state pointer
    s32i    a4, a2, 0
    s32i    a5, a2, 4
    s32i    a6, a2, 8
    s32i    a7, a2, 12
    s32i    a8, a2, 16
    s32i    a9, a2, 20
    s32i    a10, a2, 24
    s32i    a11, a2, 28
    s32i    a12, a2, 32
    s32i    a13, a2, 36
    s32i    a14, a2, 40
    s32i    a15, a2, 44

    # Epilogue & Return
    l32i    a8, sp, 0
    l32i    a9, sp, 4
    l32i    a10, sp, 8
    l32i    a11, sp, 12
    l32i    a12, sp, 16
    l32i    a13, sp, 20
    l32i    a14, sp, 24
    l32i    a15, sp, 28
    addi    sp, sp, 64
    ret.n

    .align  4
.global Xoodoo_Permute_6rounds
.type   Xoodoo_Permute_6rounds, @function
Xoodoo_Permute_6rounds:
    movi    a3, 6
    j       Xoodoo_Permute_Nrounds

    .align  4
.global Xoodoo_Permute_12rounds
.type   Xoodoo_Permute_12rounds, @function
Xoodoo_Permute_12rounds:
    movi    a3, 12
    j       Xoodoo_Permute_Nrounds
