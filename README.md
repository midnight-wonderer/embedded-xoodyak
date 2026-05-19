# Embedded Xoodyak Library

A portable, lightweight, and zero-allocation C library implementing the **Xoodyak** cryptographic scheme (based on the Cyclist construction and the **Xoodoo** permutation). 

This library is designed specifically for resource-constrained embedded systems and microcontrollers (e.g., ESP8266, ARM Cortex-M).

---

## How to Build / Integrate

To use this library, add `include/` to your header search paths.

### 1. Automatic Selection (Recommended)
You can simply compile all source files in the `src/` directory:
* `src/Xoodyak.c`
* `src/Xoodoo-portable.c`
* `src/Xoodoo-helpers.c`
* `src/Xoodoo-lx106.S`
* `src/Xoodoo-armv6m.S`
* `src/Xoodoo-armv7m.S`

The library uses built-in C preprocessor macros to automatically select the most optimized implementation for your target CPU architecture (Xtensa, ARMv6-M, ARMv7-M) and disable the others at compile time.

### 2. Manual Selection
Alternatively, you can compile `src/Xoodyak.c` along with only the files for your target platform:

* **Portable C (Generic Fallback)**: Compile `src/Xoodyak.c` and `src/Xoodoo-portable.c`.
* **Xtensa LX106 (ESP8266 / NodeMCU)**: Compile `src/Xoodyak.c`, `src/Xoodoo-helpers.c`, and `src/Xoodoo-lx106.S`.
* **ARM Cortex-M0 / M0+ (ARMv6-M)**: Compile `src/Xoodyak.c`, `src/Xoodoo-helpers.c`, and `src/Xoodoo-armv6m.S`.
* **ARM Cortex-M3 / M4 / M7 (ARMv7-M)**: Compile `src/Xoodyak.c`, `src/Xoodoo-helpers.c`, and `src/Xoodoo-armv7m.S`.

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

## License
This project is dedicated to the public domain under the Creative Commons CC0 1.0 Universal Public Domain Dedication, matching the licensing of the underlying XKCP source components. See the `LICENSE.md` file for details.


