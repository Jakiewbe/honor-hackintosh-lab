#!/usr/bin/env python3
"""Read-only integrity qualification for exact NullMoth upstream files.

This tool intentionally does not apply patches, install kexts or execute upstream code.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

COMMIT = "0960b2ef5dbc4a573056d4c8e042a5bd2e15d651"
BLOBS = {
    "kexts/NVRM/accel/nvrm-accel.cpp": "86fee4f16b393fabe94ae28ecc747a2d03ac4bed",
    "kexts/NMIntelFB/intelfb.cpp": "d3891a3884a1ab14c295b74ad34c980b5f1ea7f1",
    "kexts/NVRMFB/fb/Info.plist": "81c8adf1e091b00e3a9f3bab7bfad41fed61cfaf",
    "kexts/NVRM/fb/Info.plist": "81c8adf1e091b00e3a9f3bab7bfad41fed61cfaf",
    "kexts/NVRM/nvrm_vram_abi.h": "430fcb431ad443c4ca82b041c4e8d3462c787fcf",
    "kexts/NVRMFB/nvrm_vram_abi.h": "430fcb431ad443c4ca82b041c4e8d3462c787fcf",
    "kexts/NMIntelFB/nvrm_vram_abi.h": "430fcb431ad443c4ca82b041c4e8d3462c787fcf",
}

def sha_git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\x00" + data).hexdigest()

def check(repo: Path) -> dict:
    repo = repo.resolve(strict=True)
    def git(*args):
        return subprocess.check_output(["git", "-C", str(repo), *args], text=True, timeout=20).strip()
    head = git("rev-parse", "HEAD")
    status = git("status", "--porcelain")
    outcomes = {"commit": head == COMMIT, "clean": not status}
    for rel, expected in BLOBS.items():
        p = repo / rel
        if not p.is_file() or p.is_symlink() or not p.resolve().is_relative_to(repo):
            outcomes[rel] = False
        else:
            outcomes[rel] = sha_git_blob(p.read_bytes()) == expected
    return {"expected_commit": COMMIT, "observed_commit": head, "checks": outcomes,
            "status": "PASS" if all(outcomes.values()) else "BLOCKED"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True, type=Path)
    args = parser.parse_args()
    try:
        result = check(args.repo)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        raise SystemExit(0 if result["status"] == "PASS" else 2)
    except (OSError, subprocess.CalledProcessError, ValueError) as exc:
        print(json.dumps({"status": "BLOCKED", "error": str(exc)}))
        raise SystemExit(2)
