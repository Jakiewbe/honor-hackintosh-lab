#!/usr/bin/env python3
"""G1-B2 evidence-only native probe. Does not link/install/load a kext or validate WP1."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

from macho_obj import MachO

NULLMOTH_PIN = "cd8e2bb04da48d2fa70cf1895879608f3588dbfb"
OGKM_PIN = "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb"
# These are pinned upstream candidates, NOT identified as WP1.
PATCHES = {
    "fsp-timer-double-destroy": ("610-fsp-timer-double-destroy.patch", "nvidia",
        ("src/nvidia/src/kernel/gpu/fsp/kern_fsp.c",
         "src/nvidia/src/kernel/gpu/timer/timer_ostimer.c")),
    "display-completion": ("610-display-completion.patch", "nvidia-modeset",
        ("src/nvidia-modeset/kapi/src/nvkms-kapi.c",)),
}
NVRM_CPP = ("NVRM.cpp", "os-xnu.cpp", "os-xnu2.cpp", "os-nvkms-xnu.cpp",
            "nv_xnu_stubs.cpp", "nvrm_gpuva.cpp", "nvrm_fbinfo.cpp",
            "nvrm_surfshare.cpp", "nvkms_shaders.cpp")
NVRM_C = ("nvrm_pageoff.c", "nvrm_kapi_fields.c")


def hash_bytes(b):
    return hashlib.sha256(b).hexdigest()


def command(argv, cwd, log):
    with log.open("w", encoding="utf-8") as f:
        f.write("ARGV=" + json.dumps(argv) + "\n")
        f.flush()
        p = subprocess.run(argv, cwd=cwd, stdout=f, stderr=subprocess.STDOUT,
                           check=False)
        f.write("\nRC=" + str(p.returncode) + "\n")
        return p.returncode


def make_command(log, src):
    hits = []
    for line in log.read_text(errors="replace").splitlines():
        part = line.split(" && ", 1)[0]
        try:
            t = shlex.split(part)
        except ValueError:
            continue
        if t.count("-c") == 1 and t[t.index("-c") + 1] == src:
            hits.append(t)
    if len(hits) != 1:
        raise ValueError(f"{src}: expected 1 original B1 compile command, got {len(hits)}")
    return hits[0]


def patched_probe(nm, nv, logs, scratch, report):
    for label, (patch_name, module, paths) in PATCHES.items():
        entry = {"label": "UPSTREAM_PATCH_CANDIDATE_NOT_WP1", "patch": patch_name, "results": []}
        report["patch_probes"][label] = entry
        patch = nm / "kexts/NVRM/patches" / patch_name
        try:
            raw = patch.read_bytes()
            entry["patch_sha256"] = hash_bytes(raw)
            targets = []
            for line in raw.decode().splitlines():
                if line.startswith("+++ "):
                    p = line[4:].split("\t", 1)[0]
                    if not p.startswith("b/") or p == "b/" or ".." in Path(p[2:]).parts:
                        raise ValueError("unsafe patch path")
                    targets.append(p[2:])
            if len(targets) != len(paths) or set(targets) != set(paths):
                raise ValueError("patch target contract changed")
            owned = scratch / label
            for rel in paths:
                source = nv / rel
                data = source.read_bytes()
                if data != subprocess.check_output(["git", "-C", str(nv),
                                                    "show", "HEAD:" + rel]):
                    raise ValueError("source differs from fixed Git blob: " + rel)
                target = owned / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
                entry["results"].append({"source": rel, "source_sha256": hash_bytes(data)})
            if command(["git", "apply", "--check", str(patch)], owned,
                       logs / (label + "-check.txt")):
                raise ValueError("patch cannot apply to fixed pristine sources")
            if command(["git", "apply", str(patch)], owned,
                       logs / (label + "-apply.txt")):
                raise ValueError("patch apply failed on owned copy")
            for item in entry["results"]:
                rel = item["source"]
                dst = owned / rel
                if hash_bytes(dst.read_bytes()) == item["source_sha256"]:
                    raise ValueError("patch target unchanged: " + rel)
                item["patched_sha256"] = hash_bytes(dst.read_bytes())
                b1src = rel[len("src/" + module + "/"):]
                argv = make_command(logs.parent / ("make-" + module + ".log"), b1src)
                outfile = owned / (Path(rel).name + ".o")
                for flag, replacement in (("-c", str(dst)), ("-o", str(outfile)),
                                          ("-MF", str(outfile) + ".d"),
                                          ("-MT", str(outfile))):
                    if argv.count(flag) != 1:
                        raise ValueError("ambiguous compiler flag " + flag)
                    argv[argv.index(flag) + 1] = replacement
                # A copied source loses quoted local-header resolution; add the
                # original pinned folder, recording this candidate-only delta.
                item["added_include"] = str((nv / rel).parent)
                argv.extend(["-I", item["added_include"]])
                item["compile_rc"] = command(argv, nv / "src" / module,
                                             logs / (label + "-" + Path(rel).name + ".txt"))
                if item["compile_rc"] == 0:
                    m = MachO(outfile)
                    item["verified_object"] = (
                        m.filetype == 1 and
                        int.from_bytes(m.data[4:8], "little") == 0x01000007)
                else:
                    item["verified_object"] = False
            entry["status"] = ("COMPILED_PROBE" if all(
                v.get("verified_object") for v in entry["results"]) else "COMPILE_FAILED")
        except Exception as exc:
            entry["status"] = "BLOCKED"
            entry["error"] = str(exc)


def nvrm_probe(nm, nv, logs, scratch, report):
    rec = {"label": "INFERRED_NVRM_SOURCE_PROBE_NOT_FULL_LINK", "objects": []}
    report["nvrm"] = rec
    sdk = Path(subprocess.check_output(["xcrun", "--sdk", "macosx",
                                        "--show-sdk-path"], text=True).strip())
    kh = sdk / "System/Library/Frameworks/Kernel.framework/Headers"
    need = ("IOKit/IOService.h", "kern/thread_call.h", "pexpert/pexpert.h")
    rec["kernel_header_probe"] = {p: (kh / p).is_file() for p in need}
    rec["sdk"] = str(sdk)
    if not all(rec["kernel_header_probe"].values()):
        rec["status"] = "BLOCKED_REQUIRED_KERNEL_HEADERS"
        return
    common = nv / "src/common"
    rm = nv / "src/nvidia"
    kms = nv / "src/nvidia-modeset"
    include = [kh, nm / "kexts/NVRM", rm / "arch/nvalloc/unix/include",
        rm / "arch/nvalloc/common/inc", rm / "arch/nvalloc/common/inc/gsp",
        rm / "kernel/inc", rm / "interface", rm / "inc", rm / "inc/os",
        rm / "inc/kernel", rm / "generated", rm / "src/mm/uvm/interface",
        rm / "inc/libraries", rm / "src/libraries", common / "sdk/nvidia/inc",
        common / "sdk/nvidia/inc/hw", common / "inc", common / "shared/inc",
        common / "inc/swref", common / "inc/swref/published",
        common / "nvlink/interface", common / "nvlink/inband/interface",
        common / "unix/common/inc", common / "unix/common/utils/interface",
        common / "unix/nvidia-push/interface", common / "uproc/os/libos-v2.0.0/include",
        common / "uproc/os/common/include", kms / "os-interface/include",
        kms / "kapi/interface", kms / "kapi/include", kms / "kapi/src",
        kms / "interface", kms / "include", kms / "generated", common / "modeset"]
    macros = ("KERNEL", "KERNEL_PRIVATE", "DRIVER_PRIVATE", "APPLE", "NeXT",
              "NV_UNIX", "NV_LINUX", "NV_X86_64", "NV_ARCH_BITS=64")
    rec["macros_inferred"] = list(macros)
    rec["missing_inferred_include_dirs"] = [str(p) for p in include if not p.is_dir()]
    base = ["-arch", "x86_64", "-fapple-kext", "-mkernel", "-nostdinc"] + [
        "-I" + str(p) for p in include] + ["-D" + d for d in macros] + [
        "-fno-common", "-fno-builtin", "-O2"]
    for src in NVRM_CPP + NVRM_C:
        item = {"source": src}
        rec["objects"].append(item)
        path = nm / "kexts/NVRM" / src
        if not path.is_file():
            item["error"] = "source missing"
            continue
        dest = scratch / ("NVRM-" + src + ".o")
        is_c = src in NVRM_C
        flags = (["-std=gnu11"] if is_c else [
            "-std=c++17", "-fno-rtti", "-fno-exceptions"])
        cmd = (["clang" if is_c else "clang++"] + base + flags +
               ["-c", str(path), "-o", str(dest)])
        item["compile_rc"] = command(cmd, scratch, logs / ("NVRM-" + src + ".txt"))
        if item["compile_rc"] == 0:
            obj = MachO(dest)
            item["verified_object"] = (obj.filetype == 1 and
                                       int.from_bytes(obj.data[4:8], "little") == 0x01000007)
    rec["status"] = "SOURCE_COMPILE_PROBE_ONLY_NOT_LINKED"


def main():
    p = argparse.ArgumentParser()
    for name in ("nullmoth", "ogkm", "b1-logs", "report"):
        p.add_argument("--" + name, required=True)
    a = p.parse_args()
    nm, nv, logroot = Path(a.nullmoth).resolve(), Path(a.ogkm).resolve(), Path(a.b1_logs).resolve()
    report = {"label": "G1_B2_DISCOVERY_ONLY", "status": "BLOCKED",
              "wp1": "UNDEFINED_IN_PINNED_REPO_AND_HANDOFF",
              "patch_probes": {}, "nvrm": {}, "source_pins": {
                  "NullMoth": NULLMOTH_PIN, "NVIDIA": OGKM_PIN}}
    report_path = Path(a.report).resolve()
    details = logroot / "b2-details"
    details.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="g1-b2-", dir=os.environ.get("RUNNER_TEMP")) as t:
        try:
            for repo, pin in ((nm, NULLMOTH_PIN), (nv, OGKM_PIN)):
                head = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"],
                                               text=True).strip()
                if head != pin:
                    raise ValueError("fixed source revision mismatch: " + str(repo))
            patched_probe(nm, nv, details, Path(t), report)
            nvrm_probe(nm, nv, details, Path(t), report)
            report["status"] = "BLOCKED_WP1_OR_NVRM_LINK_PROVENANCE"
        except Exception as exc:
            report["status"] = "BLOCKED_PREREQUISITE"
            report["error"] = str(exc)
        finally:
            report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("B2_REPORT=" + str(report_path))
    print("B2_VERDICT=" + report["status"] + " (native link and WP1 NOT accepted)")
    return 2


if __name__ == "__main__":
    sys.exit(main())
