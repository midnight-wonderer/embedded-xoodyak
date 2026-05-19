#ifndef _Xoodoo_h_
#define _Xoodoo_h_

#include <stdint.h>
#include <stddef.h>

typedef struct {
    uint32_t A[12];
} Xoodoo_state;

void Xoodoo_Initialize(Xoodoo_state *state);
void Xoodoo_AddBytes(Xoodoo_state *state, const uint8_t *data, unsigned int offset, unsigned int length);
void Xoodoo_OverwriteBytes(Xoodoo_state *state, const uint8_t *data, unsigned int offset, unsigned int length);
void Xoodoo_OverwriteWithZeroes(Xoodoo_state *state, unsigned int byteCount);
void Xoodoo_ExtractBytes(const Xoodoo_state *state, uint8_t *data, unsigned int offset, unsigned int length);
void Xoodoo_ExtractAndAddBytes(const Xoodoo_state *state, const uint8_t *input, uint8_t *output, unsigned int offset, unsigned int length);
void Xoodoo_Permute_6rounds(Xoodoo_state *state);
void Xoodoo_Permute_12rounds(Xoodoo_state *state);
void Xoodoo_Permute_Nrounds(Xoodoo_state *state, unsigned int nrounds);

#define Xoodoo_AddByte(state, data, offset)    ((uint8_t*)(state))[offset] ^= (data)

#endif
