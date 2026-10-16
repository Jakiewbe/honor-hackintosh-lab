/*
 * Apple kernel-SDK *compile-only* contract for IODMACommand::Segment64
 * -> RM NvU64 va_array. No KEXT class, no device, no entry or runtime call.
 *
 * This intentionally does NOT create or own an IODMACommand or IOMMU map.
 * A caller-supplied command must be prepared for exactly the requested
 * IOBufferMemoryDescriptor-backed range and device-specific IOMapper.
 * That ownership/call context is unverified and NOT implemented here.
 */
#include <IOKit/IODMACommand.h>
#include <IOKit/IOMemoryDescriptor.h>
#include "dma_page_array.hpp"

static_assert(sizeof(IODMACommand::Segment64) == 16,
              "unexpected Darwin IOVM64 segment layout");

extern "C" IOReturn honor_g1_dma_segments_compile_only(
    IODMACommand *preparedCommand,
    UInt64 requiredPages,
    unsigned deviceAddressBits,
    bool rmContiguous,
    UInt64 *rmPageArray,
    UInt64 rmArrayCapacity)
{
    if (!preparedCommand || !rmPageArray || !requiredPages ||
        requiredPages > (~0ULL / g1dma::kPageBytes)) {
        return kIOReturnBadArgument;
    }

    const IOMemoryDescriptor *backing = preparedCommand->getMemoryDescriptor();
    const UInt64 requiredBytes = requiredPages * g1dma::kPageBytes;
    if (!backing || backing->getLength() != requiredBytes) {
        return kIOReturnBadArgument;
    }

    // Bounded scratch. Larger/more fragmented mappings are rejected rather
    // than publishing an incomplete address list or truncating segments.
    IODMACommand::Segment64 segmentScratch[32];
    UInt64 nextOffset = 0;
    UInt32 segmentCapacity = 32;
    IOReturn status = preparedCommand->gen64IOVMSegments(
        &nextOffset, segmentScratch, &segmentCapacity);
    if (status != kIOReturnSuccess && status != kIOReturnOverrun) {
        return status;
    }
    if (!segmentCapacity || nextOffset != requiredBytes) {
        return kIOReturnNoSpace;
    }

    const g1dma::Status result = g1dma::flatten(
        segmentScratch, segmentCapacity, requiredPages,
        deviceAddressBits, rmContiguous, rmPageArray, rmArrayCapacity);
    return result == g1dma::PASS ? kIOReturnSuccess : kIOReturnBadArgument;
}
