#!/usr/bin/env python3
"""Review-only R1.1 patch guards.

Reads exact upstream files AFTER git apply. These checks do not demonstrate
runtime safety or macOS loadability, and never install or execute a kext.
"""
import argparse
import json
from pathlib import Path

def inspect(root: Path):
    intel = (root / "kexts/NMIntelFB/intelfb.cpp").read_text()
    accel = (root / "kexts/NVRM/accel/nvrm-accel.cpp").read_text()
    display_start = accel.index("IOReturn NVDisplayPipe::performTransaction(")
    display_end = accel.index("static int nvacceliop_sysctl", display_start)
    transaction = accel[display_start:display_end]
    flip_start = accel.index("static bool nvAccelIopFlip(IOService *fb", display_end)
    # First declaration after main path precedes definition: only check that
    # the unsafely enqueued call has been removed across the entire file.
    checks = {
        "bar0_mapping_size_guard": "fMMIO->getLength() < (uint64_t)PLANE_SURF(3) + sizeof(uint32_t)" in intel,
        "bar0_nonnull_virtual_address": "if (!fMMIO->getVirtualAddress() ||" in intel,
        "intel_scanout_capacity_reported": "r->phys = 0; r->actualSize = mappedBytes;" in intel,
        "intel_scanout_real_mapping_length": "const uint64_t mappedBytes = fSurfMap->getLength();" in intel,
        "intel_scanout_geometry_guard": "(uint64_t)fRowBytes < pixelBytes || mappedBytes < bytesNeeded" in intel,
        "intel_scanout_unbounded_size_removed": "r->phys = 0; r->actualSize = 0;" not in intel,
        "nvidia_copy_dst_capacity_gate": "!q.actualSize || q.actualSize < dstNeeded" in transaction,
        "nvidia_copy_src_resource_gate": "vm->fBytes < srcNeeded" in transaction,
        "nvidia_copy_active_pixels_only": "const unsigned words = w;" in transaction,
        "nvidia_copy_unbounded_row_pitch_removed": "(((pitch < q.pitch) ? pitch : q.pitch) & ~3u) / 4" not in transaction,
        "unsafe_async_enqueue_disabled": "if (gIopAsync && pipe) return nvAccelIopAsyncStart(" not in accel,
        "synchronous_flip_still_present": 'fb->callPlatformFunction(sym, false, &f, nullptr, nullptr, nullptr)' in accel[flip_start:],
    }
    return {"status": "PASS" if all(checks.values()) else "BLOCKED",
            "checks": checks, "kind": "source-invariant inspection only"}

if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source", required=True, type=Path)
    args = p.parse_args()
    try:
        result = inspect(args.source)
    except (OSError, ValueError) as error:
        result = {"status": "BLOCKED", "reason": str(error)}
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result["status"] == "PASS" else 2)
