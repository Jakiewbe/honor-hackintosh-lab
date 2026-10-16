/*
 * G1 DMA SDK signature probe ONLY, not a loadable kext or DMA adapter.
 * XNU 15.5: a1e26a70f38d1d7daa7b49b258e2f8538ad81650
 * IODMACommand.h blob: c9e75dc4df8b6446788c154a893a7c670d063fd1.
 * These functions have NO caller and are NEVER executed in CI.
 */
#include <IOKit/IODMACommand.h>
#include <IOKit/IOMemoryDescriptor.h>

static_assert(sizeof(IODMACommand::Segment64) == 2 * sizeof(UInt64),
              "IODMACommand 64-bit segment layout changed");

extern "C" IOReturn honor_g1_dma_compile_only_lifecycle(
    IODMACommand *command,
    const IOMemoryDescriptor *descriptor,
    UInt64 *offset,
    IODMACommand::Segment64 *segments,
    UInt32 *capacity)
{
    if (!command || !descriptor || !offset || !segments || !capacity) {
        return kIOReturnBadArgument;
    }
    // Explicit false prevents setMemoryDescriptor from auto-preparing.
    IOReturn result = command->setMemoryDescriptor(descriptor, false);
    if (result != kIOReturnSuccess) {
        return result;
    }
    result = command->prepare(0, 0, true, true);
    if (result != kIOReturnSuccess) {
        (void) command->clearMemoryDescriptor(false);
        return result;
    }
    result = command->gen64IOVMSegments(offset, segments, capacity);
    // Real drivers must first prove DMA is quiescent. Not exercised here.
    IOReturn completed = command->complete(true, true);
    IOReturn cleared = command->clearMemoryDescriptor(false);
    if (result != kIOReturnSuccess) {
        return result;
    }
    return completed != kIOReturnSuccess ? completed : cleared;
}

extern "C" bool honor_g1_dma_compile_only_factory(IOMapper *mapper)
{
    auto command = IODMACommand::withSpecification(
        kIODMACommandOutputHost64, 64, 0,
        IODMACommand::kMapped, 0, 4096, mapper, nullptr);
    return static_cast<bool>(command);
}
