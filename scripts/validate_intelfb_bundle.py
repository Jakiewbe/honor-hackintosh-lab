#!/usr/bin/env python3
"""R0.9: validate a never-loaded NMIntelFB.kext package and pinned source matching.

No on-device probing, no driver installation, no kernel code execution.
"""
import argparse
import json
import plistlib
import re
from pathlib import Path

PINNED_INTEL_ID = 0x46A6
PINNED_DISPLAY_VERSION = 13
PINNED_INTEL_BLOB = "03fc18f018be25593fd60966799822e5f5d97b1e"

def git_blob_sha(raw: bytes) -> str:
    import hashlib
    return hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()

def validate(source: Path, bundle: Path) -> dict:
    source = source.resolve(strict=True)
    bundle = bundle.resolve(strict=True)
    info_path = bundle / "Contents/Info.plist"
    executable = bundle / "Contents/MacOS/NMIntelFB"
    ids_path = source / "display_ids.inc"
    with info_path.open("rb") as f:
        info = plistlib.load(f)
    ids_raw = ids_path.read_bytes()
    ids = ids_raw.decode("utf-8", errors="strict")
    entries = re.findall(r"\{\s*(0x[0-9a-fA-F]+)\s*,\s*(\d+)\s*\}", ids)
    matches = [int(ver) for devid, ver in entries if int(devid, 16) == PINNED_INTEL_ID]
    personalities = info.get("IOKitPersonalities", {})
    personality = personalities.get("NMIntelFB", {})
    checks = {
        "bundle_executable_file": executable.is_file() and not executable.is_symlink(),
        "bundle_package_type": info.get("CFBundlePackageType") == "KEXT",
        "bundle_identifier": info.get("CFBundleIdentifier") == "com.nullmoth.NMIntelFB",
        "bundle_executable_name": info.get("CFBundleExecutable") == "NMIntelFB",
        "provider_class": personality.get("IOProviderClass") == "IOPCIDevice",
        "io_class": personality.get("IOClass") == "NMIntelFB",
        "intel_vendor_personality": personality.get("IOPCIMatch") == "0x00008086&0x0000ffff",
        "display_class_personality": personality.get("IOPCIClassMatch") == "0x03000000&0xff000000",
        "device_46a6_in_pinned_table": matches == [PINNED_DISPLAY_VERSION],
        "device_table_blob_integrity": git_blob_sha(ids_raw) == PINNED_INTEL_BLOB,
    }
    return {"result": "PASS" if all(checks.values()) else "BLOCKED", "checks": checks,
            "note": "Only static package/source checks. No signature, load, panel, or Metal claim."}

if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source", type=Path, required=True)
    p.add_argument("--bundle", type=Path, required=True)
    args = p.parse_args()
    try:
        results = validate(args.source, args.bundle)
    except (OSError, ValueError, TypeError) as exc:
        results = {"result": "BLOCKED", "error": str(exc)}
    print(json.dumps(results, indent=2, ensure_ascii=False))
    raise SystemExit(0 if results["result"] == "PASS" else 2)
