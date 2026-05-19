#include "Xoodyak.h"
#include <string.h>

#define MyMin(a, b) (((a) < (b)) ? (a) : (b))

#define Xoodyak_f_bPrime    48
#define Xoodyak_Rhash       16
#define Xoodyak_Rkin        44
#define Xoodyak_Rkout       24
#define Xoodyak_lRatchet    16

static void Xoodyak_Down(Xoodyak_Instance *instance, const uint8_t *Xi, unsigned int XiLen, uint8_t Cd)
{
    Xoodoo_AddBytes(&instance->state, Xi, 0, XiLen);
    Xoodoo_AddByte(&instance->state, 0x01, XiLen);
    Xoodoo_AddByte(&instance->state, (instance->mode == Cyclist_ModeHash) ? (Cd & 0x01) : Cd, Xoodyak_f_bPrime - 1);
    instance->phase = Cyclist_PhaseDown;
}

static void Xoodyak_Up(Xoodyak_Instance *instance, uint8_t *Yi, unsigned int YiLen, uint8_t Cu)
{
    if (instance->mode != Cyclist_ModeHash) {
        Xoodoo_AddByte(&instance->state, Cu, Xoodyak_f_bPrime - 1);
    }
    Xoodoo_Permute_12rounds(&instance->state);
    instance->phase = Cyclist_PhaseUp;
    Xoodoo_ExtractBytes(&instance->state, Yi, 0, YiLen);
}

static void Xoodyak_AbsorbAny(Xoodyak_Instance *instance, const uint8_t *X, size_t XLen, unsigned int r, uint8_t Cd)
{
    unsigned int splitLen;

    do {
        if (instance->phase != Cyclist_PhaseUp) {
            Xoodyak_Up(instance, NULL, 0, 0);
        }
        splitLen = (unsigned int)MyMin(XLen, r);
        Xoodyak_Down(instance, X, splitLen, Cd);
        Cd = 0;
        X    += splitLen;
        XLen -= splitLen;
    } while (XLen != 0);
}

static void Xoodyak_AbsorbKey(Xoodyak_Instance *instance, const uint8_t *K, size_t KLen, const uint8_t *ID, size_t IDLen, const uint8_t *counter, size_t counterLen)
{
    uint8_t KID[Xoodyak_Rkin];

    instance->mode     = Cyclist_ModeKeyed;
    instance->Rabsorb  = Xoodyak_Rkin;
    instance->Rsqueeze = Xoodyak_Rkout;
    if (KLen != 0) {
        memcpy(KID, K, KLen);
        memcpy(KID + KLen, ID, IDLen);
        KID[KLen + IDLen] = (uint8_t)IDLen;
        Xoodyak_AbsorbAny(instance, KID, KLen + IDLen + 1, instance->Rabsorb, 0x02);
        if (counterLen != 0) {
            Xoodyak_AbsorbAny(instance, counter, counterLen, 1, 0x00);
        }
    }
}

static void Xoodyak_SqueezeAny(Xoodyak_Instance *instance, uint8_t *Y, size_t YLen, uint8_t Cu)
{
    unsigned int len;

    len = (unsigned int)MyMin(YLen, instance->Rsqueeze);
    Xoodyak_Up(instance, Y, len, Cu);
    Y    += len;
    YLen -= len;
    while (YLen != 0) {
        Xoodyak_Down(instance, NULL, 0, 0);
        len = (unsigned int)MyMin(YLen, instance->Rsqueeze);
        Xoodyak_Up(instance, Y, len, 0);
        Y    += len;
        YLen -= len;
    }
}

static void Xoodyak_Crypt(Xoodyak_Instance *instance, const uint8_t *I, uint8_t *O, size_t IOLen, int decrypt)
{
    unsigned int splitLen;
    uint8_t      P[Xoodyak_Rkout];
    uint8_t      Cu = 0x80;

    do {
        splitLen = (unsigned int)MyMin(IOLen, Xoodyak_Rkout);
        if (decrypt != 0) {
            Xoodyak_Up(instance, NULL, 0, Cu);
            Xoodoo_ExtractAndAddBytes(&instance->state, I, O, 0, splitLen);
            Xoodyak_Down(instance, O, splitLen, 0x00);
        }
        else {
            memcpy(P, I, splitLen);
            Xoodyak_Up(instance, NULL, 0, Cu);
            Xoodoo_ExtractAndAddBytes(&instance->state, I, O, 0, splitLen);
            Xoodyak_Down(instance, P, splitLen, 0x00);
        }
        I     += splitLen;
        O     += splitLen;
        IOLen -= splitLen;
        Cu = 0x00;
    } while (IOLen != 0);
}

void Xoodyak_Initialize(Xoodyak_Instance *instance, const uint8_t *K, size_t KLen, const uint8_t *ID, size_t IDLen, const uint8_t *counter, size_t counterLen)
{
    Xoodoo_Initialize(&instance->state);
    instance->phase    = Cyclist_PhaseUp;
    instance->mode     = Cyclist_ModeHash;
    instance->Rabsorb  = Xoodyak_Rhash;
    instance->Rsqueeze = Xoodyak_Rhash;
    if (KLen != 0) {
        Xoodyak_AbsorbKey(instance, K, KLen, ID, IDLen, counter, counterLen);
    }
}

void Xoodyak_Absorb(Xoodyak_Instance *instance, const uint8_t *X, size_t XLen)
{
    Xoodyak_AbsorbAny(instance, X, XLen, instance->Rabsorb, 0x03);
}

void Xoodyak_Encrypt(Xoodyak_Instance *instance, const uint8_t *P, uint8_t *C, size_t PLen)
{
    Xoodyak_Crypt(instance, P, C, PLen, 0);
}

void Xoodyak_Decrypt(Xoodyak_Instance *instance, const uint8_t *C, uint8_t *P, size_t CLen)
{
    Xoodyak_Crypt(instance, C, P, CLen, 1);
}

void Xoodyak_Squeeze(Xoodyak_Instance *instance, uint8_t *Y, size_t YLen)
{
    Xoodyak_SqueezeAny(instance, Y, YLen, 0x40);
}

void Xoodyak_SqueezeKey(Xoodyak_Instance *instance, uint8_t *K, size_t KLen)
{
    Xoodyak_SqueezeAny(instance, K, KLen, 0x20);
}

void Xoodyak_Ratchet(Xoodyak_Instance *instance)
{
    uint8_t buffer[Xoodyak_lRatchet];

    Xoodyak_SqueezeAny(instance, buffer, sizeof(buffer), 0x10);
    Xoodyak_AbsorbAny(instance, buffer, sizeof(buffer), instance->Rabsorb, 0x00);
}
