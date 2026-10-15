/* G1 offscreen validator: CPU reference values and readback comparison. Must stay bit-identical to gen_spirv.py. */
#ifndef G1_REF_H
#define G1_REF_H

#include <stddef.h>
#include <stdint.h>

#define G1_GOLDEN 0x9E3779B9u

static inline uint32_t g1_hash(uint32_t v)
{
    v ^= v >> 16;
    v *= 0x7feb352du;
    v ^= v >> 15;
    v *= 0x846ca68bu;
    v ^= v >> 16;
    return v;
}

static inline uint32_t g1_value(uint32_t index, uint32_t nonce)
{
    return g1_hash(index * G1_GOLDEN + nonce);
}

typedef struct { uint32_t x, y, w, h; } g1_rect;

typedef struct {
    size_t mismatches;
    size_t unwritten;      /* mismatching words that still hold the sentinel/clear value */
    size_t first_bad;      /* index of the first mismatch, valid when mismatches > 0 */
    uint32_t first_got, first_want;
} g1_cmp;

/* Pixel (x,y) after a full-screen draw with nonce_full and a second draw scissored to r with nonce_rect. */
uint32_t g1_expected_pixel(uint32_t x, uint32_t y, uint32_t width, uint32_t nonce_full, uint32_t nonce_rect, g1_rect r);

g1_cmp g1_check_compute(const uint32_t *got, size_t n, uint32_t nonce, uint32_t sentinel);
g1_cmp g1_check_image(const uint32_t *got, uint32_t width, uint32_t height, uint32_t nonce_full, uint32_t nonce_rect,
                      g1_rect r, uint32_t sentinel, uint32_t clear);

uint64_t g1_fnv1a64(const void *data, size_t len);

#endif
