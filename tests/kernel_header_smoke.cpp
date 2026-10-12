// Compile-only kernel-header smoke test for the macOS x86_64 SDK.
// Not a loadable kernel extension and not linked or executed.
#include <IOKit/IOService.h>
#include <libkern/c++/OSObject.h>

static_assert(sizeof(void *) == 8, "x86_64 pointer size expected");
extern "C" IOReturn honor_r07_kernel_header_smoke(IOService *service)
{
    return service ? kIOReturnSuccess : kIOReturnBadArgument;
}
