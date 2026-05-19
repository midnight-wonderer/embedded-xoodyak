#if defined(__XTENSA__) || defined(__xtensa__) || \
    defined(__ARM_ARCH_6M__) || \
    defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__)

#include "Xoodoo.h"
#include <string.h>

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

#endif
