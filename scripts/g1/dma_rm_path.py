#!/usr/bin/env python3
"""Trace the pinned RM osIovaMap->nv_dma_map_alloc->osIovaUnmap ownership chain.

This is source-only evidence, not an executable RM driver or proof that these
branches run on HONOR hardware. A successful audit is still a hardware NO-GO.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

NM_COMMIT = "cd8e2bb04da48d2fa70cf1895879608f3588dbfb"
OGKM_COMMIT = "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb"
NM_BLOB = "c1fe41e9ff30649c6d02827aee5995f8eaa944b3"
OGKM_OS_BLOB = "b441a66fe735e834f830bae9344333c31b16c1f2"
NO_GO = "BLOCKED_RM_IOVA_OWNER_AND_DMA_UNVERIFIED"


def routine(source, regex):
    match = re.search(regex, source)
    if match is None:
        raise ValueError("expected entry signature missing: " + regex)
    i = source.find("{", match.end())
    if i < 0:
        raise ValueError("expected function body missing")
    first, depth, state = i, 0, "code"
    while i < len(source):
        c = source[i]
        n = source[i + 1] if i + 1 < len(source) else ""
        if state == "line":
            if c == "\n":
                state = "code"
        elif state == "block":
            if c == "*" and n == "/":
                i += 1
                state = "code"
        elif state in ("string", "char"):
            if c == "\\":
                i += 1
            elif c == ('"' if state == "string" else "'"):
                state = "code"
        elif c == "/" and n == "/":
            state = "line"
            i += 1
        elif c == "/" and n == "*":
            state = "block"
            i += 1
        elif c == '"':
            state = "string"
        elif c == "'":
            state = "char"
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return source[first + 1:i]
        i += 1
    raise ValueError("unterminated function body")


def inspect(nullmoth, ogkm):
    alloc = routine(nullmoth, r"\bNV_STATUS\s+NV_API_CALL\s+nv_alloc_pages\s*\(")
    macmap = routine(nullmoth, r"\bNV_STATUS\s+NV_API_CALL\s+nv_dma_map_alloc\s*\(")
    free = routine(nullmoth, r"\bNV_STATUS\s+NV_API_CALL\s+nv_free_pages\s*\(")
    rmmap = routine(ogkm, r"\bosIovaMap\s*\(\s*PIOVAMAPPING\s+pIovaMapping")
    rmunmap = routine(ogkm, r"\bosIovaUnmap\s*\(\s*PIOVAMAPPING\s+pIovaMapping")
    rmfree = routine(ogkm, r"\bosFreePagesInternal\s*\(\s*MEMORY_DESCRIPTOR\s*\*\s*pMemDesc")

    facts = {
        "alloc_returns_separate_private_allocation":
            bool(re.search(r"\*\s*priv_data\s*=\s*a\s*;", alloc)),
        "mac_map_destroys_local_mapping_priv_on_success":
            bool(re.search(r"\*\s*priv\s*=\s*NULL\s*;\s*return\s+NV_OK\s*;", macmap)),
        "mac_free_consumes_original_allocation_private":
            bool(re.search(r"nv_xnu_alloc\s*\*\s*a\s*=\s*\(nv_xnu_alloc\s*\*\)\s*priv_data", free)),
        "rm_map_takes_local_copy_of_original_owner":
            bool(re.search(r"void\s*\*\s*pPriv\s*=\s*memdescGetMemData\s*\(\s*pIovaMapping->pPhysMemDesc\s*\)\s*;", rmmap)),
        "rm_passes_local_slot_to_dma_map":
            bool(re.search(r"status\s*=\s*nv_dma_map_alloc\s*\([^;]*&pPriv\s*\)\s*;", rmmap, re.S)),
        "rm_records_returned_slot_as_mapping_owner":
            bool(re.search(r"pIovaMapping->pOsData\s*=\s*pPriv\s*;", rmmap)),
        "rm_intentionally_uses_null_as_peer_discriminator":
            "pOsData must be NULL to distinguish a peer DMA mapping" in rmmap,
        "rm_unmap_branches_on_null_mapping_owner":
            bool(re.search(r"if\s*\(\s*pPriv\s*!=\s*NULL\s*\)\s*\{[^}]*nv_dma_unmap_alloc\s*\(", rmunmap, re.S)) and
            bool(re.search(r"else\s*\{\s*nv_dma_unmap_peer\s*\(", rmunmap)),
        "rm_unmap_clears_owner_after_failed_unmap":
            bool(re.search(r"if\s*\(\s*status\s*!=\s*NV_OK\s*\)\s*\{[^}]*failed to unmap allocation[^}]*\}", rmunmap, re.S)) and
            rmunmap.rfind("pIovaMapping->pOsData = NULL;") > rmunmap.rfind("nv_dma_unmap_peer("),
        "rm_free_gets_memdesc_separate_owner":
            bool(re.search(r"nv_free_pages\s*\([^;]*memdescGetMemData\s*\(\s*pMemDesc\s*\)", rmfree, re.S)),
    }
    if not all(facts.values()):
        raise ValueError("pinned RM/OS call chain changed: stop and manually review")
    return {
        "schema": "honor.g1.rm-iova-owner-audit.v1",
        "facts": facts,
        "observed": {
            "system_map_success_returns_null_owner_from_macos_port": True,
            "rm_pOsData_is_null_on_that_branch": True,
            "subsequent_rm_unmap_chooses_peer_branch_if_reached": True,
            "rm_drops_mapping_owner_even_on_unmap_failure_if_reached": True,
            "main_rm_free_uses_separate_memdesc_owner": True,
        },
        "limitations": {
            "actual_gpu_branch_reached": "UNVERIFIED",
            "hardware_memory_leak_observed": "UNVERIFIED",
            "complete_other_callsite_audit": "UNVERIFIED",
            "device_iova_proven": False,
            "iommu_mapping_proven": False,
            "safe_unmap_proven": False,
            "firmware_gpu_execution_proven": False,
        },
        "verdict": NO_GO,
        "device_activation": "NO_GO",
        "scope": "fixed source control-flow, not execution or causality proof",
    }


def verify(root, ref, relative, blob):
    root = Path(root)
    head = subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
    target = root / relative
    digest = subprocess.check_output(
        ["git", "hash-object", str(target)], text=True).strip()
    if head != ref or digest != blob:
        raise ValueError("source SHA or Git blob mismatch; audit aborted")
    return target, {
        "commit": head,
        "git_blob": digest,
        "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
        "path": relative,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--nullmoth", required=True)
    parser.add_argument("--ogkm", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    nm, ninfo = verify(args.nullmoth, NM_COMMIT, "kexts/NVRM/os-xnu2.cpp", NM_BLOB)
    nv, vinfo = verify(args.ogkm, OGKM_COMMIT,
                       "src/nvidia/arch/nvalloc/unix/src/os.c", OGKM_OS_BLOB)
    report = inspect(nm.read_text(), nv.read_text())
    report["provenance"] = {"nullmoth": ninfo, "nvidia_rm": vinfo}
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print("RM_IOVA_OWNER_AUDIT=" + str(out))
    print("RM_IOVA_VERDICT=" + NO_GO)
    return 0  # verified source behavior remains hardware NO-GO


if __name__ == "__main__":
    raise SystemExit(main())
