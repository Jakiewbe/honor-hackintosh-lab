#include "g1_ref.h"

uint32_t g1_expected_pixel(uint32_t x, uint32_t y, uint32_t width, uint32_t nonce_full, uint32_t nonce_rect, g1_rect r)
{
    int in_rect = x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h;
    return g1_value(y * width + x, in_rect ? nonce_rect : nonce_full);
}

static void note(g1_cmp *c, size_t i, uint32_t got, uint32_t want, int unwritten)
{
    if (c->mismatches == 0) {
        c->first_bad = i;
        c->first_got = got;
        c->first_want = want;
    }
    c->mismatches++;
    if (unwritten)
        c->unwritten++;
}

g1_cmp g1_check_compute(const uint32_t *got, size_t n, uint32_t nonce, uint32_t sentinel)
{
    g1_cmp c = {0};
    for (size_t i = 0; i < n; i++) {
        uint32_t want = g1_value((uint32_t)i, nonce);
        if (got[i] != want)
            note(&c, i, got[i], want, got[i] == sentinel);
    }
    return c;
}

g1_cmp g1_check_image(const uint32_t *got, uint32_t width, uint32_t height, uint32_t nonce_full, uint32_t nonce_rect,
                      g1_rect r, uint32_t sentinel, uint32_t clear)
{
    g1_cmp c = {0};
    for (uint32_t y = 0; y < height; y++)
        for (uint32_t x = 0; x < width; x++) {
            size_t i = (size_t)y * width + x;
            uint32_t want = g1_expected_pixel(x, y, width, nonce_full, nonce_rect, r);
            if (got[i] != want)
                note(&c, i, got[i], want, got[i] == sentinel || got[i] == clear);
        }
    return c;
}

uint64_t g1_fnv1a64(const void *data, size_t len)
{
    const unsigned char *p = data;
    uint64_t h = 0xcbf29ce484222325ull;
    for (size_t i = 0; i < len; i++) {
        h ^= p[i];
        h *= 0x100000001b3ull;
    }
    return h;
}
