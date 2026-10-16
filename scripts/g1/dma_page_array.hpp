// G1 P0-DMA: pure C++ page-IOVA translation contract (no hardware).
// Converts ordered IODMACommand::Segment64-style segments into NVIDIA RM's
// page-based va_array. No Apple headers, no allocations, no locks, no DMA.
// Device mapper, original allocation owner, and RM mapping owner are
// deliberately OUTSIDE this type/contract.
#ifndef G1_DMA_PAGE_ARRAY_H
#define G1_DMA_PAGE_ARRAY_H

namespace g1dma {

typedef unsigned long long U64;

enum Status {
    PASS = 0,
    INVALID_INPUT = 1,
    LENGTH_MISMATCH = 2,
    ADDRESS_UNREACHABLE = 3,
    NONCONTIGUOUS = 4,
    OUTPUT_TOO_SMALL = 5
};

static const U64 kPageBytes = 4096ULL;

// Out has *no modifications* unless every segment passes validation.
// Segments must enumerate a complete prepared IOVM range in memory order;
// ordering and mapping authenticity are the caller's obligations.
// A contiguous RM allocation requires ONE bus-contiguous IOVA base, even
// when Apple emitted multiple adjacent bus segments. Scatter RM wants exactly
// one bus-visible address per PAGE, not one address per IODMACommand segment.
template <typename Segment, typename Address>
Status flatten(const Segment *segments, U64 segmentCount, U64 pageCount,
               unsigned deviceAddressBits, bool contiguous,
               Address *out, U64 outCapacity)
{
    if (sizeof(Address) != 8 || !segments || !out ||
        !segmentCount || !pageCount || !deviceAddressBits ||
        deviceAddressBits > 64 || pageCount > (~0ULL) / kPageBytes) {
        return INVALID_INPUT;
    }
    const U64 needed = contiguous ? 1 : pageCount;
    if (outCapacity < needed) {
        return OUTPUT_TOO_SMALL;
    }
    const U64 maxBus = (deviceAddressBits == 64)
                     ? ~0ULL : ((1ULL << deviceAddressBits) - 1);
    const U64 requested = pageCount * kPageBytes;
    U64 total = 0;
    U64 next = 0;
    bool havePrevious = false;

    for (U64 i = 0; i < segmentCount; ++i) {
        const U64 address = static_cast<U64>(segments[i].fIOVMAddr);
        const U64 length = static_cast<U64>(segments[i].fLength);
        if (!length || address % kPageBytes || length % kPageBytes ||
            address > maxBus || length - 1 > maxBus - address) {
            return ADDRESS_UNREACHABLE;
        }
        if (length > requested - total) {
            return LENGTH_MISMATCH;
        }
        if (contiguous && havePrevious && address != next) {
            return NONCONTIGUOUS;
        }
        total += length;
        if (contiguous && i + 1 < segmentCount) {
            if (address > ~0ULL - length) {
                return ADDRESS_UNREACHABLE;
            }
            next = address + length;
        }
        havePrevious = true;
    }
    if (total != requested) {
        return LENGTH_MISMATCH;
    }

    // Two-pass publication: the caller's output buffer is never touched
    // for failures above. Caller must supply distinct stable segments/out.
    if (contiguous) {
        out[0] = static_cast<Address>(segments[0].fIOVMAddr);
        return PASS;
    }
    U64 outputIndex = 0;
    for (U64 i = 0; i < segmentCount; ++i) {
        U64 address = static_cast<U64>(segments[i].fIOVMAddr);
        const U64 length = static_cast<U64>(segments[i].fLength);
        for (U64 off = 0; off < length; off += kPageBytes) {
            out[outputIndex++] = static_cast<Address>(address + off);
        }
    }
    return PASS;
}
} // namespace g1dma

#endif // G1_DMA_PAGE_ARRAY_H
