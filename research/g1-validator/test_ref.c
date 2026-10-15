/* Unit tests for the CPU reference and comparator. With "kat" as argument, prints value(i, nonce) for the KAT grid. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "g1_ref.h"

static int fails;
#define CHECK(cond) do { if (!(cond)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #cond); fails++; } } while (0)

static const uint32_t kat_index[] = { 0, 1, 2, 63, 64, 65535, 65536, 0x7fffffffu, 0xffffffffu };
static const uint32_t kat_nonce[] = { 0, 1, 0xdeadbeefu, 0xffffffffu };

int main(int argc, char **argv)
{
    if (argc > 1 && !strcmp(argv[1], "kat")) {
        for (size_t a = 0; a < sizeof kat_index / sizeof *kat_index; a++)
            for (size_t b = 0; b < sizeof kat_nonce / sizeof *kat_nonce; b++)
                printf("%u %u %u\n", kat_index[a], kat_nonce[b], g1_value(kat_index[a], kat_nonce[b]));
        return 0;
    }

    enum { N = 4096, W = 61, H = 37 };
    static uint32_t buf[N], img[W * H];
    const uint32_t sentinel = 0x5E5E5E5Eu, clear = 0xC1EAC1EAu, nc = 0x1234567u, na = 0xabcdefu, nb = 0x13579bdu;
    const g1_rect r = { W / 4, H / 3, W / 2, H / 4 };

    for (uint32_t i = 0; i < N; i++)
        buf[i] = g1_value(i, nc);
    g1_cmp c = g1_check_compute(buf, N, nc, sentinel);
    CHECK(c.mismatches == 0);
    c = g1_check_compute(buf, N, nc + 1, sentinel);
    CHECK(c.mismatches > N - 4 && c.unwritten == 0);

    buf[0] ^= 1;
    buf[N - 1] = sentinel;
    c = g1_check_compute(buf, N, nc, sentinel);
    CHECK(c.mismatches == 2 && c.unwritten == 1 && c.first_bad == 0 && c.first_got == (g1_value(0, nc) ^ 1));
    CHECK(c.first_want == g1_value(0, nc));

    for (uint32_t y = 0; y < H; y++)
        for (uint32_t x = 0; x < W; x++)
            img[y * W + x] = g1_expected_pixel(x, y, W, na, nb, r);
    c = g1_check_image(img, W, H, na, nb, r, sentinel, clear);
    CHECK(c.mismatches == 0);

    /* rectangle edges: inside uses the rect nonce, one pixel outside on each side uses the full nonce */
    CHECK(g1_expected_pixel(r.x, r.y, W, na, nb, r) == g1_value(r.y * W + r.x, nb));
    CHECK(g1_expected_pixel(r.x + r.w - 1, r.y + r.h - 1, W, na, nb, r) == g1_value((r.y + r.h - 1) * W + r.x + r.w - 1, nb));
    CHECK(g1_expected_pixel(r.x - 1, r.y, W, na, nb, r) == g1_value(r.y * W + r.x - 1, na));
    CHECK(g1_expected_pixel(r.x + r.w, r.y, W, na, nb, r) == g1_value(r.y * W + r.x + r.w, na));
    CHECK(g1_expected_pixel(r.x, r.y - 1, W, na, nb, r) == g1_value((r.y - 1) * W + r.x, na));
    CHECK(g1_expected_pixel(r.x, r.y + r.h, W, na, nb, r) == g1_value((r.y + r.h) * W + r.x, na));

    /* a rect drawn with the full nonce (second draw lost) is caught, pixel for pixel */
    uint32_t saved = img[r.y * W + r.x];
    img[r.y * W + r.x] = g1_value(r.y * W + r.x, na);
    c = g1_check_image(img, W, H, na, nb, r, sentinel, clear);
    CHECK(c.mismatches == 1 && c.unwritten == 0 && c.first_bad == r.y * W + r.x);
    img[r.y * W + r.x] = saved;

    img[W * H - 1] = clear;
    img[5] = sentinel;
    c = g1_check_image(img, W, H, na, nb, r, sentinel, clear);
    CHECK(c.mismatches == 2 && c.unwritten == 2 && c.first_bad == 5);

    /* a whole image that was never drawn: every pixel is unwritten */
    for (uint32_t i = 0; i < W * H; i++)
        img[i] = clear;
    c = g1_check_image(img, W, H, na, nb, r, sentinel, clear);
    CHECK(c.mismatches == W * H && c.unwritten == W * H);

    CHECK(g1_fnv1a64("", 0) == 0xcbf29ce484222325ull);
    CHECK(g1_fnv1a64("a", 1) == 0xaf63dc4c8601ec8cull);

    printf("%s (%d failures)\n", fails ? "FAIL" : "OK", fails);
    return fails ? 1 : 0;
}
