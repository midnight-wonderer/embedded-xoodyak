#include "Xoodyak.h"
#include <stdio.h>
#include <string.h>

int main(void) {
    Xoodyak_Instance instance;
    uint8_t hash[32];
    const uint8_t msg[] = "Hello Embedded World!";

    Xoodyak_Initialize(&instance, NULL, 0, NULL, 0, NULL, 0);
    Xoodyak_Absorb(&instance, msg, sizeof(msg) - 1);
    Xoodyak_Squeeze(&instance, hash, sizeof(hash));

    printf("Xoodyak(\"Hello Embedded World!\") = ");
    for(size_t i = 0; i < sizeof(hash); ++i) {
        printf("%02x", hash[i]);
    }
    printf("\n");

    return 0;
}
