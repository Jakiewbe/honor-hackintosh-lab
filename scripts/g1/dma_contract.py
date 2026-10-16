#!/usr/bin/env python3
"""Read-only pinned DMA source audit. Audit success NEVER enables GPU use."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

PINS = {
    "nullmoth": ("cd8e2bb04da48d2fa70cf1895879608f3588dbfb",
                 "kexts/NVRM/os-xnu2.cpp",
                 "c1fe41e9ff30649c6d02827aee5995f8eaa944b3"),
    "nvidia": ("e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb",
               "kernel-open/nvidia/nv-dma.c",
               "f3541a6bf629ce9400ce60dd8a7e09786db337ea"),
}
NO_GO = "BLOCKED_DEVICE_DMA_MAPPING_UNVERIFIED"


def callback(text, name):
    match = re.search(r"\b(?:NV_STATUS|NvBool)\s+NV_API_CALL\s+" +
                      re.escape(name) + r"\s*\(", text)
    if match is None:
        raise ValueError("missing callback: " + name)
    start = text.find("{", match.end())
    if start < 0:
        raise ValueError("missing callback body: " + name)
    depth, i, state = 0, start, "code"
    while i < len(text):
        c = text[i]
        n = text[i + 1] if i + 1 < len(text) else ""
        if state == "line":
            if c == "\n": state = "code"
        elif state == "block":
            if c == "*" and n == "/": state = "code"; i += 1
        elif state in ("str", "chr"):
            if c == "\\": i += 1
            elif c == ('"' if state == "str" else "'"): state = "code"
        elif c == "/" and n == "/": state = "line"; i += 1
        elif c == "/" and n == "*": state = "block"; i += 1
        elif c == '"': state = "str"
        elif c == "'": state = "chr"
        elif c == "{": depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return text[start + 1:i]
        i += 1
    raise ValueError("unclosed callback: " + name)


def audit(mac, linux):
    mmap = callback(mac, "nv_dma_map_alloc")
    munmap = callback(mac, "nv_dma_unmap_alloc")
    remap = callback(mac, "nv_requires_dma_remap")
    lmap = callback(linux, "nv_dma_map_alloc")
    lunmap = callback(linux, "nv_dma_unmap_alloc")
    facts = {
        "mac_map_success_without_ownership":
            bool(re.search(r"\*\s*priv\s*=\s*NULL\s*;\s*return\s+NV_OK\s*;", mmap)),
        "mac_unmap_success_without_unmap":
            bool(re.search(r"^\s*TRC\s*;\s*return\s+NV_OK\s*;\s*$", munmap)),
        "mac_hardcoded_no_dma_remapping":
            bool(re.search(r"^\s*TRC\s*;\s*return\s+NV_FALSE\s*;\s*$", remap)),
        "mac_physical_segment_without_iomapper":
            bool(re.search(r"getPhysicalSegment\s*\([^;]+kIOMemoryMapperNone\s*\)", mac)),
        "linux_map_uses_dma_pages_or_sgt":
            "nv_dma_map_pages(" in lmap or "nv_dma_map_sgt(" in lmap,
        "linux_unmap_calls_dma_reverse":
            "nv_dma_unmap_pages(" in lunmap and "nv_dma_unmap_sgt(" in lunmap,
        "linux_checks_mapping_failure_and_range":
            all(key in linux for key in ("dma_mapping_error(",
                                          "nv_dma_is_addressable(",
                                          "dma_unmap_page_attrs(")),
    }
    if not all(facts.values()):
        raise ValueError("unexpected source behavior: manual review required")
    return {
        "schema": "honor.g1.dma-source-contract.v1",
        "facts": facts,
        "actual_macos_dma_mapping_proven": False,
        "real_device_iommu_translation_proven": False,
        "device_addressability_proven": False,
        "unmapping_and_rollback_proven": False,
        "gsp_dma_quiescence_proven": False,
        "device_activation": "NO_GO",
        "runtime_verdict": NO_GO,
        "evidence_scope": "pinned source only, not evidence of device failure",
    }


class FakeDmaLedger:
    """Host synthetic only. Not an actual IOVA allocator or macOS DMA API."""
    def __init__(self, owner, limit):
        if not owner or not 0 <= limit < 2**64:
            raise ValueError("bad device/limit")
        self.owner, self.limit, self.active = owner, limit, {}

    def map(self, handle, owner, addrs, page=4096, fail_index=None):
        if owner != self.owner or not isinstance(handle, str) or not handle:
            raise ValueError("device mismatch")
        if handle in self.active:
            raise ValueError("duplicate handle")
        if not addrs or page < 1 or page & (page - 1):
            raise ValueError("invalid page geometry")
        pending = []
        for i, address in enumerate(addrs):
            if (not isinstance(address, int) or address < 0 or
                    address % page or address > self.limit or
                    page - 1 > self.limit - address):
                raise ValueError("DMA aperture or alignment failure")
            if i == fail_index:
                raise RuntimeError("injected DMA failure")
            pending.append(address)
        self.active[handle] = tuple(pending)
        return self.active[handle]

    def unmap(self, handle, owner):
        if owner != self.owner or handle not in self.active:
            raise ValueError("wrong owner or already unmapped")
        return self.active.pop(handle)


def verify_pin(root, label):
    commit, relative_path, expected_blob = PINS[label]
    got_commit = subprocess.check_output(["git", "-C", str(root),
                                          "rev-parse", "HEAD"], text=True).strip()
    path = Path(root) / relative_path
    got_blob = subprocess.check_output(["git", "hash-object", str(path)],
                                       text=True).strip()
    if got_commit != commit or got_blob != expected_blob:
        raise ValueError("source pin/blob mismatch; fail closed")
    return path, {"commit": commit, "git_blob": got_blob,
                  "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--nullmoth", required=True)
    p.add_argument("--ogkm", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()
    m, mref = verify_pin(args.nullmoth, "nullmoth")
    l, lref = verify_pin(args.ogkm, "nvidia")
    result = audit(m.read_text(), l.read_text())
    result["provenance"] = {"nullmoth": mref, "nvidia": lref}
    path = Path(args.out)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print("P0_DMA_REPORT=" + str(path))
    print("P0_DMA_VERDICT=" + NO_GO)
    return 0  # Successful audit remains NO-GO for device activation.


if __name__ == "__main__":
    raise SystemExit(main())
