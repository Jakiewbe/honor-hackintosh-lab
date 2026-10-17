// Executes the actual candidate helper on real CPU buffers; no IOKit/GPU mocks.
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <vector>
#include "frame_copy_checked.h"
#include "frame_copy_checked.h"

static void require(bool ok, const char *name) {
    if (!ok) { std::fprintf(stderr, "FAIL: %s\n", name); std::exit(1); }
}

static void image(unsigned w, unsigned h) {
    constexpr unsigned guard = 16;
    const unsigned sp = w + 8, dp = w + 16;
    std::vector<unsigned> src(guard + sp * h + guard, 0x31313131u);
    std::vector<unsigned> dst(guard + dp * h + guard, 0xDEADBEEFu);
    for (unsigned y = 0; y < h; ++y)
        for (unsigned x = 0; x < w; ++x) src[guard + y * sp + x] = (y * 0x9E3779B9u) ^ x;
    const auto original = src;
    require(honorCopyFrame32(dst.data() + guard, (unsigned long long)dp * h * 4, dp * 4,
                             src.data() + guard, (unsigned long long)sp * h * 4, sp * 4, w, h), "valid padded image");
    for (unsigned i = 0; i < dst.size(); ++i) {
        if (i < guard || i >= guard + dp * h) require(dst[i] == 0xDEADBEEFu, "outer guard untouched");
        else {
            unsigned y = (i - guard) / dp, x = (i - guard) % dp;
            require(dst[i] == (x < w ? ((y * 0x9E3779B9u) ^ x) : 0xDEADBEEFu), "pixels exact, padding untouched");
        }
    }
    require(src == original, "source unchanged");
    std::printf("PASS: %ux%u exact pixels, row padding and guards\n", w, h);
}

int main() {
    image(2160, 1440);
    image(257, 131);
    std::vector<unsigned> src(128, 0x12345678u), dst(128, 0xA5A5A5A5u);
    const auto untouched = dst;
    require(!honorCopyFrame32(dst.data(), 512, 32, src.data(), 43, 32, 3, 2), "short source refused");
    require(!honorCopyFrame32(dst.data(), 43, 32, src.data(), 512, 32, 3, 2), "short destination refused");
    require(!honorCopyFrame32(dst.data(), 512, 8, src.data(), 512, 32, 3, 2), "short row refused");
    require(!honorCopyFrame32(dst.data(), 512, 33, src.data(), 512, 32, 3, 2), "unaligned pitch refused");
    require(!honorCopyFrame32(dst.data(), 512, 32, src.data(), 512, 32, 0, 2), "zero width refused");
    require(!honorCopyFrame32(dst.data(), 512, 32, nullptr, 512, 32, 3, 2), "null source refused");
    require(!honorCopyFrame32(dst.data(), 512, 32, dst.data() + 1, 508, 32, 3, 2), "overlap refused");
    require(!honorCopyFrame32(dst.data(), 512, 32,
                reinterpret_cast<const volatile unsigned *>(reinterpret_cast<const unsigned char *>(src.data()) + 1),
                511, 32, 3, 2), "unaligned source refused");
    require(!honorCopyFrame32(dst.data(), ~0ull, 0xfffffffcu, src.data(), ~0ull, 0xfffffffcu,
                             1, std::numeric_limits<unsigned>::max()), "address wrap refused");
    require(dst == untouched, "all rejected requests wrote nothing");
    require(honorCopyFrame32(dst.data(), 44, 32, src.data(), 44, 32, 3, 2), "exact last pixel boundary accepted");
    std::puts("PASS: nine invalid requests left destination unchanged; exact final-row boundary accepted");
    return 0;
}
