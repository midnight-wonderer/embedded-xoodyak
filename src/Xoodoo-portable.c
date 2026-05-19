#include "Xoodoo.h"
#include <string.h>

#define MAXROUNDS   12

static const uint32_t RC[12] = {
    0x00000058, 0x00000038, 0x000003C0, 0x000000D0,
    0x00000120, 0x00000014, 0x00000060, 0x0000002C,
    0x00000380, 0x000000F0, 0x000001A0, 0x00000012
};

#define ROTL32(a, offset)   ((((uint32_t)a) << ((offset)%32)) ^ (((uint32_t)a) >> ((32-(offset))%32)))

void Xoodoo_Initialize(Xoodoo_state *state)
{
    memset(state->A, 0, sizeof(state->A));
}

void Xoodoo_AddBytes(Xoodoo_state *state, const uint8_t *data, unsigned int offset, unsigned int length)
{
    uint8_t *stateBytes = (uint8_t*)state->A;
    for (unsigned int i = 0; i < length; i++) {
        stateBytes[offset + i] ^= data[i];
    }
}

void Xoodoo_OverwriteBytes(Xoodoo_state *state, const uint8_t *data, unsigned int offset, unsigned int length)
{
    uint8_t *stateBytes = (uint8_t*)state->A;
    for (unsigned int i = 0; i < length; i++) {
        stateBytes[offset + i] = data[i];
    }
}

void Xoodoo_OverwriteWithZeroes(Xoodoo_state *state, unsigned int byteCount)
{
    uint8_t *stateBytes = (uint8_t*)state->A;
    memset(stateBytes, 0, byteCount);
}

void Xoodoo_ExtractBytes(const Xoodoo_state *state, uint8_t *data, unsigned int offset, unsigned int length)
{
    const uint8_t *stateBytes = (const uint8_t*)state->A;
    memcpy(data, stateBytes + offset, length);
}

void Xoodoo_ExtractAndAddBytes(const Xoodoo_state *state, const uint8_t *input, uint8_t *output, unsigned int offset, unsigned int length)
{
    const uint8_t *stateBytes = (const uint8_t*)state->A;
    for (unsigned int i = 0; i < length; i++) {
        output[i] = input[i] ^ stateBytes[offset + i];
    }
}

static void Xoodoo_Round(Xoodoo_state *state, uint32_t rc)
{
    uint32_t P[4];
    uint32_t E[4];
    
    // Theta: Column Parity Mixer
    for (int i = 0; i < 4; i++) {
        P[i] = state->A[i] ^ state->A[i+4] ^ state->A[i+8];
    }
    for (int i = 0; i < 4; i++) {
        uint32_t p_prev = P[(i+3)%4];
        E[i] = ROTL32(p_prev, 5) ^ ROTL32(p_prev, 14);
    }
    for (int i = 0; i < 4; i++) {
        state->A[i] ^= E[i];
        state->A[i+4] ^= E[i];
        state->A[i+8] ^= E[i];
    }

    // Rho-west: Plane Shift
    uint32_t tmp_r1[4];
    tmp_r1[0] = state->A[7]; // A13
    tmp_r1[1] = state->A[4]; // A10
    tmp_r1[2] = state->A[5]; // A11
    tmp_r1[3] = state->A[6]; // A12
    for (int i = 0; i < 4; i++) {
        state->A[i+4] = tmp_r1[i];
    }
    for (int i = 0; i < 4; i++) {
        state->A[i+8] = ROTL32(state->A[i+8], 11);
    }

    // Iota: Round Constant
    state->A[0] ^= rc;

    // Chi: non-linear step
    for (int i = 0; i < 4; i++) {
        uint32_t a0 = state->A[i];
        uint32_t a1 = state->A[i+4];
        uint32_t a2 = state->A[i+8];
        a0 ^= ~a1 & a2;
        a1 ^= ~a2 & a0;
        a2 ^= ~a0 & a1;
        state->A[i] = a0;
        state->A[i+4] = a1;
        state->A[i+8] = a2;
    }

    // Rho-east: Plane Shift
    for (int i = 0; i < 4; i++) {
        state->A[i+4] = ROTL32(state->A[i+4], 1);
    }
    uint32_t r2_0 = state->A[8];
    uint32_t r2_1 = state->A[9];
    uint32_t r2_2 = state->A[10];
    uint32_t r2_3 = state->A[11];
    state->A[8] = ROTL32(r2_2, 8);  // A20
    state->A[9] = ROTL32(r2_3, 8);  // A21
    state->A[10] = ROTL32(r2_0, 8); // A22
    state->A[11] = ROTL32(r2_1, 8); // A23
}

void Xoodoo_Permute_Nrounds(Xoodoo_state *state, unsigned int nrounds)
{
    for (unsigned int i = 12 - nrounds; i < 12; i++) {
        Xoodoo_Round(state, RC[i]);
    }
}

void Xoodoo_Permute_6rounds(Xoodoo_state *state)
{
    Xoodoo_Permute_Nrounds(state, 6);
}

void Xoodoo_Permute_12rounds(Xoodoo_state *state)
{
    Xoodoo_Permute_Nrounds(state, 12);
}
