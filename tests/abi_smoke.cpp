// Host-only x86_64 ABI smoke test. Does not compile or load a macOS kext.
#include "nvrm_vram_abi.h"  // sourced from exactly pinned upstream on the GitHub runner
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <type_traits>

static_assert(sizeof(void *) == 8, "64-bit ABI required");
static_assert(NVRM_VRAM_ABI_VERSION == 2u, "Unexpected upstream ABI version");
static_assert(std::is_standard_layout<NVRMVramRequest>::value, "ABI not standard layout");
static_assert(sizeof(NVRMVramRequest) == 80, "x86_64 ABI structure size changed");
static_assert(offsetof(NVRMVramRequest, kva) == 32, "kva ABI offset changed");
static_assert(offsetof(NVRMVramRequest, width) == 56, "width ABI offset changed");
static_assert(offsetof(NVRMVramRequest, allocationCookie) == 72, "ABI cookie offset changed");

static bool valid(const NVRMVramRequest &r) {
    if (r.version != NVRM_VRAM_ABI_VERSION || !r.kva || !r.size || !r.width || !r.height || !r.pitch) return false;
    if ((r.pitch & 3) != 0 || (std::uint64_t)r.width * 4u > r.pitch) return false;
    return (std::uint64_t)r.pitch * r.height <= r.size;
}

int main() {
    std::uint32_t frame[32] = {};
    NVRMVramRequest r = {};
    r.version = NVRM_VRAM_ABI_VERSION;
    r.kva = frame; r.size = sizeof(frame); r.width = 8; r.height = 4; r.pitch = 32;
    if (!valid(r)) return 1;
    r.size -= 1;
    if (valid(r)) return 2;
    r.size += 1; r.width = 9;
    if (valid(r)) return 3;
    std::cout << "PINNED_SOURCE_ABI_SMOKE_PASS (host only)\n";
}
