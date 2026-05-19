#ifndef _Xoodyak_h_
#define _Xoodyak_h_

#include <stddef.h>
#include <stdint.h>
#include "Xoodoo.h"

#define Cyclist_ModeHash    1
#define Cyclist_ModeKeyed   2

#define Cyclist_PhaseDown   1
#define Cyclist_PhaseUp     2

typedef struct {
    Xoodoo_state    state;
    unsigned int    phase;
    unsigned int    mode;
    unsigned int    Rabsorb;
    unsigned int    Rsqueeze;
} Xoodyak_Instance;

void Xoodyak_Initialize(Xoodyak_Instance *instance, const uint8_t *K, size_t KLen, const uint8_t *ID, size_t IDLen, const uint8_t *counter, size_t counterLen);
void Xoodyak_Absorb(Xoodyak_Instance *instance, const uint8_t *X, size_t XLen);
void Xoodyak_Encrypt(Xoodyak_Instance *instance, const uint8_t *P, uint8_t *C, size_t PLen);
void Xoodyak_Decrypt(Xoodyak_Instance *instance, const uint8_t *C, uint8_t *P, size_t CLen);
void Xoodyak_Squeeze(Xoodyak_Instance *instance, uint8_t *Y, size_t YLen);
void Xoodyak_SqueezeKey(Xoodyak_Instance *instance, uint8_t *K, size_t KLen);
void Xoodyak_Ratchet(Xoodyak_Instance *instance);

#endif
