# Embedded Xoodyak Library

A portable, lightweight, and zero-allocation C library implementing the **Xoodyak** cryptographic scheme (based on the Cyclist construction and the **Xoodoo** permutation). 

This library is designed specifically for resource-constrained embedded systems and microcontrollers (e.g., ESP8266, ARM Cortex-M, AVR).

## Features
- **Zero Allocations:** No heap usage (`malloc`/`free`); all state structure memory is allocated by the caller.
- **No dependencies:** Standard-library independent (no `libc` required, only `stdint.h` and `stddef.h`).
- **Target-Specific Optimizations:** Highly optimized assembly implementations for key microcontroller architectures, along with a fallback portable C implementation.

---

## Directory Structure

```
embedded-xoodyak/
├── include/
│   ├── Xoodoo.h           # Public API for Xoodoo permutation layer
│   └── Xoodyak.h          # Public API for Xoodyak cyclist layer
└── src/
    ├── Xoodyak.c          # Portable C implementation of Xoodyak cyclist layer
    ├── Xoodoo-portable.c  # Portable plain C fallback implementation of Xoodoo
    ├── Xoodoo-lx106.c     # Helper C functions for ESP8266
    ├── Xoodoo-lx106.S     # Optimized Xtensa LX106 assembly permutation (ESP8266)
    ├── Xoodoo-armv6m.S    # Optimized ARMv6-M assembly permutation (Cortex-M0/M0+)
    ├── Xoodoo-armv7m.S    # Optimized ARMv7-M assembly permutation (Cortex-M3/M4/M7)
    └── Xoodoo-avr8.S      # Optimized AVR8 assembly permutation (Atmel AVR)
```

---

## How to Build / Integrate

To use this library, add `include/` to your header search paths, and compile `src/Xoodyak.c` along with **one** of the Xoodoo implementations, depending on your target platform:

### 1. Portable C (Generic Fallback)
Compile the following files:
* `src/Xoodyak.c`
* `src/Xoodoo-portable.c`

### 2. Xtensa LX106 (ESP8266 / NodeMCU)
Compile the following files (using your `xtensa-lx106-elf-*` toolchain):
* `src/Xoodyak.c`
* `src/Xoodoo-lx106.c`
* `src/Xoodoo-lx106.S`

### 3. ARM Cortex-M0 / Cortex-M0+ (ARMv6-M)
Compile the following files:
* `src/Xoodyak.c`
* `src/Xoodoo-armv6m.S`

### 4. ARM Cortex-M3 / M4 / M7 (ARMv7-M)
Compile the following files:
* `src/Xoodyak.c`
* `src/Xoodoo-armv7m.S`

### 5. AVR8 (e.g., ATmega328P / Arduino Uno)
Compile the following files:
* `src/Xoodyak.c`
* `src/Xoodoo-avr8.S`

---

## API Usage Example

Here is a simple example showing how to initialize Xoodyak, absorb a message, and squeeze a hash:

```c
#include "Xoodyak.h"
#include <stdio.h>

void hash_example(void) {
    Xoodyak_Instance instance;
    uint8_t hash[32];
    const uint8_t msg[] = "Hello Embedded World!";

    // 1. Initialize in Hashing Mode (no key)
    Xoodyak_Initialize(&instance, NULL, 0, NULL, 0, NULL, 0);

    // 2. Absorb data
    Xoodyak_Absorb(&instance, msg, sizeof(msg) - 1);

    // 3. Squeeze digest output
    Xoodyak_Squeeze(&instance, hash, sizeof(hash));

    // Print hash
    for(size_t i = 0; i < sizeof(hash); ++i) {
        printf("%02x", hash[i]);
    }
    printf("\n");
}
```

### Keyed mode (encryption/decryption):
```c
#include "Xoodyak.h"

void encrypt_example(void) {
    Xoodyak_Instance instance;
    const uint8_t key[16] = "MySecretKey12345";
    const uint8_t nonce[16] = "UniqueNonce54321";
    
    const uint8_t plaintext[] = "Confidential data";
    uint8_t ciphertext[sizeof(plaintext)];
    uint8_t tag[16];

    // Initialize with Key and Nonce (ID)
    Xoodyak_Initialize(&instance, key, sizeof(key), nonce, sizeof(nonce), NULL, 0);

    // Encrypt
    Xoodyak_Encrypt(&instance, plaintext, ciphertext, sizeof(plaintext));

    // Squeeze out Authentication Tag
    Xoodyak_Squeeze(&instance, tag, sizeof(tag));
}
```
