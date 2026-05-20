#include "unity.h"
#include "Xoodyak.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>

void setUp(void) {
    // Set up routine if needed before each test
}

void tearDown(void) {
    // Tear down routine if needed after each test
}

/* Helper functions for AEAD matching Rust-Xoodyak API behavior */

static int aead_encrypt(Xoodyak_Instance *instance, const uint8_t *bin, size_t bin_len, uint8_t *out, size_t out_len) {
    if (out_len < bin_len + 16) {
        return -1; // buffer too small
    }
    Xoodyak_Encrypt(instance, bin, out, bin_len);
    Xoodyak_Squeeze(instance, out + bin_len, 16);
    return 0;
}

static int aead_decrypt(Xoodyak_Instance *instance, const uint8_t *bin, size_t bin_len, uint8_t *out, size_t out_len) {
    if (bin_len < 16) {
        return -1; // input too small to contain tag
    }
    size_t ct_len = bin_len - 16;
    if (out_len < ct_len) {
        return -2; // output buffer too small
    }
    
    Xoodyak_Decrypt(instance, bin, out, ct_len);
    
    uint8_t computed_tag[16];
    Xoodyak_Squeeze(instance, computed_tag, 16);
    
    int mismatch = 0;
    for (int i = 0; i < 16; i++) {
        mismatch |= (bin[ct_len + i] ^ computed_tag[i]);
    }
    if (mismatch != 0) {
        memset(out, 0, ct_len);
        return -3; // Tag mismatch
    }
    return 0;
}

static int aead_encrypt_in_place(Xoodyak_Instance *instance, uint8_t *in_out, size_t total_len) {
    if (total_len < 16) return -1;
    size_t ct_len = total_len - 16;
    Xoodyak_Encrypt(instance, in_out, in_out, ct_len);
    Xoodyak_Squeeze(instance, in_out + ct_len, 16);
    return 0;
}

static int aead_decrypt_in_place(Xoodyak_Instance *instance, uint8_t *in_out, size_t total_len) {
    if (total_len < 16) return -1;
    size_t ct_len = total_len - 16;
    uint8_t expected_tag[16];
    memcpy(expected_tag, in_out + ct_len, 16);
    Xoodyak_Decrypt(instance, in_out, in_out, ct_len);
    uint8_t computed_tag[16];
    Xoodyak_Squeeze(instance, computed_tag, 16);
    
    int mismatch = 0;
    for (int i = 0; i < 16; i++) {
        mismatch |= (expected_tag[i] ^ computed_tag[i]);
    }
    if (mismatch != 0) {
        memset(in_out, 0, ct_len);
        return -2; // Tag mismatch
    }
    return 0; // Success
}

static int aead_encrypt_detached(Xoodyak_Instance *instance, const uint8_t *bin, size_t bin_len, uint8_t *out, size_t out_len, uint8_t *auth_tag) {
    if (out_len < bin_len) {
        return -1;
    }
    Xoodyak_Encrypt(instance, bin, out, bin_len);
    Xoodyak_Squeeze(instance, auth_tag, 16);
    return 0;
}

static int aead_decrypt_detached(Xoodyak_Instance *instance, const uint8_t *bin, size_t bin_len, const uint8_t *auth_tag, uint8_t *out, size_t out_len) {
    if (out_len < bin_len) {
        return -1;
    }
    Xoodyak_Decrypt(instance, bin, out, bin_len);
    uint8_t computed_tag[16];
    Xoodyak_Squeeze(instance, computed_tag, 16);
    
    int mismatch = 0;
    for (int i = 0; i < 16; i++) {
        mismatch |= (auth_tag[i] ^ computed_tag[i]);
    }
    if (mismatch != 0) {
        memset(out, 0, bin_len);
        return -2;
    }
    return 0;
}

/* Test cases */

static void test_hello_world(void) {
    Xoodyak_Instance instance;
    uint8_t hash[32];
    const uint8_t msg[] = "Hello Embedded World!";

    Xoodyak_Initialize(&instance, NULL, 0, NULL, 0, NULL, 0);
    Xoodyak_Absorb(&instance, msg, sizeof(msg) - 1);
    Xoodyak_Squeeze(&instance, hash, sizeof(hash));

    const uint8_t expected[32] = {
        0x38, 0xa2, 0x48, 0x25, 0xae, 0xd6, 0xec, 0xc8, 0xc3, 0x2b, 0xe7, 0x5d, 0xa9, 0x16, 0x7d, 0x49,
        0xc4, 0x13, 0x29, 0xd5, 0x9e, 0x77, 0x9c, 0xac, 0x47, 0xee, 0xf2, 0xdf, 0xbd, 0x8f, 0x43, 0xf6
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected, hash, 32);
}

static void test_keyed_empty(void) {
    Xoodyak_Instance st;
    Xoodyak_Initialize(&st, (const uint8_t *)"key", 3, NULL, 0, NULL, 0);
    uint8_t out[32];
    Xoodyak_Squeeze(&st, out, 32);
    
    const uint8_t expected[32] = {
        106, 247, 180, 176, 207, 217, 130, 200, 237, 113, 163, 185, 224, 53, 120, 137, 251,
        126, 216, 3, 87, 45, 239, 214, 41, 201, 246, 56, 83, 55, 18, 108
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected, out, 32);
}

static void test_unkeyed_empty(void) {
    Xoodyak_Instance st;
    Xoodyak_Initialize(&st, NULL, 0, NULL, 0, NULL, 0);
    uint8_t out[32];
    Xoodyak_Squeeze(&st, out, 32);
    
    const uint8_t expected1[32] = {
        141, 216, 213, 137, 191, 252, 99, 169, 25, 45, 35, 27, 20, 160, 165, 255, 204, 246,
        41, 214, 87, 39, 76, 114, 39, 130, 131, 52, 124, 189, 128, 53
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected1, out, 32);

    Xoodyak_Initialize(&st, NULL, 0, NULL, 0, NULL, 0);
    Xoodyak_Absorb(&st, NULL, 0);
    Xoodyak_Squeeze(&st, out, 32);
    
    const uint8_t expected2[32] = {
        234, 21, 47, 43, 71, 188, 226, 78, 251, 102, 196, 121, 212, 173, 241, 123, 211, 36,
        216, 6, 232, 95, 247, 94, 227, 105, 238, 80, 220, 143, 139, 209
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected2, out, 32);
}

static void test_encrypt(void) {
    Xoodyak_Instance st;
    Xoodyak_Initialize(&st, (const uint8_t *)"key", 3, NULL, 0, NULL, 0);
    Xoodyak_Instance st0 = st;
    const uint8_t m[7] = {'m', 'e', 's', 's', 'a', 'g', 'e'};
    uint8_t c[7];
    Xoodyak_Encrypt(&st, m, c, 7);

    st = st0;
    uint8_t m2[7];
    Xoodyak_Decrypt(&st, c, m2, 7);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(m, m2, 7);

    st = st0;
    Xoodyak_Ratchet(&st);
    uint8_t m3[7];
    Xoodyak_Decrypt(&st, c, m3, 7);
    
    int match = 1;
    for (size_t i = 0; i < 7; ++i) {
        if (m3[i] != m[i]) {
            match = 0;
            break;
        }
    }
    TEST_ASSERT_FALSE(match);

    uint8_t c0[7];
    memcpy(c0, c, 7);
    
    st = st0;
    Xoodyak_Decrypt(&st, c, c, 7);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(m, c, 7);

    st = st0;
    Xoodyak_Encrypt(&st, c, c, 7);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(c0, c, 7);

    uint8_t tag[32];
    Xoodyak_Squeeze(&st, tag, 32);
    const uint8_t expected_tag[32] = {
        10, 175, 140, 82, 142, 109, 23, 111, 201, 232, 32, 52, 122, 46, 254, 206, 236, 54,
        97, 165, 40, 85, 166, 91, 124, 88, 26, 144, 100, 250, 243, 157
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected_tag, tag, 32);
}

static void test_unkeyed_hash(void) {
    Xoodyak_Instance st;
    Xoodyak_Initialize(&st, NULL, 0, NULL, 0, NULL, 0);
    const char *m = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.";
    size_t m_len = strlen(m);
    
    Xoodyak_Absorb(&st, (const uint8_t *)m, m_len);
    uint8_t hash[32];
    Xoodyak_Squeeze(&st, hash, 32);
    
    const uint8_t expected_hash1[32] = {
        144, 82, 141, 27, 59, 215, 34, 104, 197, 106, 251, 142, 112, 235, 111, 168, 19, 6,
        112, 222, 160, 168, 230, 38, 27, 229, 248, 179, 94, 227, 247, 25
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected_hash1, hash, 32);

    Xoodyak_Absorb(&st, (const uint8_t *)m, m_len);
    Xoodyak_Squeeze(&st, hash, 32);
    const uint8_t expected_hash2[32] = {
        102, 50, 250, 132, 79, 91, 248, 161, 121, 248, 225, 33, 105, 159, 111, 230, 135, 252,
        43, 228, 152, 41, 58, 242, 211, 252, 29, 234, 181, 0, 196, 220
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected_hash2, hash, 32);
}

static void test_aead(void) {
    const uint8_t nonce[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    Xoodyak_Instance st;
    Xoodyak_Initialize(&st, (const uint8_t *)"key", 3, nonce, 16, NULL, 0);
    Xoodyak_Instance st0 = st;
    
    const uint8_t m[7] = {'m', 'e', 's', 's', 'a', 'g', 'e'};
    const uint8_t ad[2] = {'a', 'd'};
    
    Xoodyak_Absorb(&st, ad, 2);
    uint8_t c[7 + 16];
    
    int res = aead_encrypt(&st, m, 7, c, sizeof(c));
    TEST_ASSERT_EQUAL_INT(0, res);
    
    st = st0;
    Xoodyak_Absorb(&st, ad, 2);
    uint8_t m2[7];
    res = aead_decrypt(&st, c, sizeof(c), m2, 7);
    TEST_ASSERT_EQUAL_INT(0, res);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(m, m2, 7);
    
    st = st0;
    res = aead_decrypt(&st, m, 7, m2, 7);
    TEST_ASSERT_LESS_THAN(0, res);

    Xoodyak_Initialize(&st, (const uint8_t *)"Another key", 11, nonce, 16, NULL, 0);
    res = aead_decrypt(&st, m, 7, m2, 7);
    TEST_ASSERT_LESS_THAN(0, res);
}

static void test_aead_in_place(void) {
    const uint8_t nonce[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    Xoodyak_Instance st;
    Xoodyak_Initialize(&st, (const uint8_t *)"key", 3, nonce, 16, NULL, 0);
    Xoodyak_Instance st0 = st;
    
    const uint8_t m[7] = {'m', 'e', 's', 's', 'a', 'g', 'e'};
    Xoodyak_Absorb(&st, (const uint8_t *)"ad", 2);
    
    uint8_t buf[7 + 16];
    memcpy(buf, m, 7);
    memset(buf + 7, 0, 16);
    
    int res = aead_encrypt_in_place(&st, buf, sizeof(buf));
    TEST_ASSERT_EQUAL_INT(0, res);
    
    st = st0;
    uint8_t buf2[7 + 16];
    memcpy(buf2, buf, sizeof(buf));
    res = aead_decrypt_in_place(&st, buf2, sizeof(buf2));
    TEST_ASSERT_LESS_THAN(0, res);
    
    st = st0;
    Xoodyak_Absorb(&st, (const uint8_t *)"ad", 2);
    res = aead_decrypt_in_place(&st, buf, sizeof(buf));
    TEST_ASSERT_EQUAL_INT(0, res);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(m, buf, 7);
}

static void test_aead_detached(void) {
    const uint8_t nonce[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    Xoodyak_Instance st;
    Xoodyak_Initialize(&st, (const uint8_t *)"key", 3, nonce, 16, NULL, 0);
    Xoodyak_Instance st0 = st;
    const uint8_t m[7] = {'m', 'e', 's', 's', 'a', 'g', 'e'};
    Xoodyak_Absorb(&st, (const uint8_t *)"ad", 2);
    
    uint8_t c[7];
    uint8_t auth_tag[16];
    int res = aead_encrypt_detached(&st, m, 7, c, 7, auth_tag);
    TEST_ASSERT_EQUAL_INT(0, res);
    
    st = st0;
    const uint8_t expected_tag[16] = {
        12, 91, 0, 120, 191, 214, 119, 66, 122, 225, 184, 239, 213, 214, 247, 57
    };
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected_tag, auth_tag, 16);
    
    Xoodyak_Absorb(&st, (const uint8_t *)"ad", 2);
    uint8_t m2[7];
    res = aead_decrypt_detached(&st, c, 7, expected_tag, m2, 7);
    TEST_ASSERT_EQUAL_INT(0, res);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(m, m2, 7);
}

int main(void) {
    UNITY_BEGIN();

    RUN_TEST(test_hello_world);
    RUN_TEST(test_keyed_empty);
    RUN_TEST(test_unkeyed_empty);
    RUN_TEST(test_encrypt);
    RUN_TEST(test_unkeyed_hash);
    RUN_TEST(test_aead);
    RUN_TEST(test_aead_in_place);
    RUN_TEST(test_aead_detached);

    return UNITY_END();
}
