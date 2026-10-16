// Host-only contract tests: real compiler + CPU, no Apple/GPU APIs.
#include "dma_page_array.hpp"
#include <cstdio>

struct Segment {
    unsigned long long fIOVMAddr;
    unsigned long long fLength;
};

static int errors = 0;
static int cases = 0;

static void check(bool ok, const char *name)
{
    ++cases;
    if (!ok) {
        ++errors;
        std::printf("FAIL %s\n", name);
    }
}

int main()
{
    const Segment whole[] = {{0x20001000ULL, 3 * 4096ULL}};
    unsigned long long out[4] = {9, 9, 9, 9};
    check(g1dma::flatten(whole, 1, 3, 64, false, out, 4) == g1dma::PASS &&
          out[0] == 0x20001000 && out[1] == 0x20002000 &&
          out[2] == 0x20003000 && out[3] == 9, "one-segment scatter expands pages");

    const Segment scatter[] = {{0x1000ULL, 4096ULL},
                               {0x9000ULL, 8192ULL}};
    check(g1dma::flatten(scatter, 2, 3, 64, false, out, 3) == g1dma::PASS &&
          out[0] == 0x1000 && out[1] == 0x9000 &&
          out[2] == 0xA000, "noncontiguous scatter accepted");

    const Segment adjacent[] = {{0x4000ULL, 4096ULL}, {0x5000ULL, 8192ULL}};
    check(g1dma::flatten(adjacent, 2, 3, 64, true, out, 1) == g1dma::PASS &&
          out[0] == 0x4000, "adjacent segments coalesce for RM contig");

    out[0] = 987;
    check(g1dma::flatten(scatter, 2, 3, 64, true, out, 1) ==
          g1dma::NONCONTIGUOUS && out[0] == 987,
          "RM contiguous cannot accept disjoint bus runs");
    check(g1dma::flatten(whole, 1, 2, 64, false, out, 4) ==
          g1dma::LENGTH_MISMATCH && out[0] == 987,
          "segment total longer than allocation must fail atomically");
    check(g1dma::flatten(whole, 1, 4, 64, false, out, 4) ==
          g1dma::LENGTH_MISMATCH && out[0] == 987,
          "segment total shorter than allocation must fail atomically");

    const Segment notAligned[] = {{0x1001ULL, 4096ULL}};
    check(g1dma::flatten(notAligned, 1, 1, 64, false, out, 4) ==
          g1dma::ADDRESS_UNREACHABLE && out[0] == 987,
          "unaligned device IOVA refused");
    const Segment partialPage[] = {{0x1000ULL, 4095ULL}};
    check(g1dma::flatten(partialPage, 1, 1, 64, false, out, 4) ==
          g1dma::ADDRESS_UNREACHABLE && out[0] == 987,
          "partial page segment refused");
    const Segment empty[] = {{0x1000ULL, 0}};
    check(g1dma::flatten(empty, 1, 1, 64, false, out, 4) ==
          g1dma::ADDRESS_UNREACHABLE && out[0] == 987,
          "zero-length segment refused");
    check(g1dma::flatten(whole, 1, 3, 64, false, out, 2) ==
          g1dma::OUTPUT_TOO_SMALL && out[0] == 987,
          "insufficient RM page array capacity fails without write");

    const Segment beyond32[] = {{0x100000000ULL, 4096ULL}};
    check(g1dma::flatten(beyond32, 1, 1, 32, false, out, 4) ==
          g1dma::ADDRESS_UNREACHABLE && out[0] == 987,
          "32-bit device address aperture enforced");
    const Segment top32[] = {{0xFFFFF000ULL, 4096ULL}};
    check(g1dma::flatten(top32, 1, 1, 32, false, out, 4) ==
          g1dma::PASS && out[0] == 0xFFFFF000,
          "last valid device page is accepted");

    out[0] = 987;
    const Segment overflow[] = {{0xFFFFFFFFFFFFF000ULL, 8192ULL}};
    check(g1dma::flatten(overflow, 1, 2, 64, true, out, 1) ==
          g1dma::ADDRESS_UNREACHABLE && out[0] == 987,
          "64-bit IOVA overflow blocked");
    check(g1dma::flatten(whole, 1, 3, 0, false, out, 4) ==
          g1dma::INVALID_INPUT && out[0] == 987,
          "unknown device address bits blocked");
    check(g1dma::flatten(whole, 1, 3, 65, false, out, 4) ==
          g1dma::INVALID_INPUT && out[0] == 987,
          "invalid 65-bit device aperture blocked");
    check(g1dma::flatten<Segment, unsigned long long>(nullptr, 1, 3, 64,
                                                      false, out, 4) ==
          g1dma::INVALID_INPUT && out[0] == 987,
          "missing segments refused");
    check(g1dma::flatten(whole, 1, ~0ULL, 64, false, out, 4) ==
          g1dma::INVALID_INPUT && out[0] == 987,
          "page-count multiplication overflow refused");

    std::printf("G1_DMA_PAGE_ARRAY_HOST_CASES=%d FAILURES=%d\n", cases, errors);
    return errors == 0 ? 0 : 1;
}
