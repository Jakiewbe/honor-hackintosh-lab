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


def b1_rm_compile_contract(nv, make_log):
    """Reuse real B1 RM portability defines; never synthesize NvPort types."""
    original = make_command(make_log, "arch/nvalloc/unix/src/osapi.c")
    includes = [original[i + 1] for i, arg in enumerate(original[:-1])
                if arg == "-include"]
    if includes != ["../common/sdk/nvidia/inc/cpuopsys.h"]:
        raise ValueError("unexpected B1 osapi.c forced-include contract")
    header = nv / "src/common/sdk/nvidia/inc/cpuopsys.h"
    if not header.is_file():
        raise ValueError("B1 forced include is missing in pinned OGKM")

    # Do not transplant C-only language toggles into Darwin C++.
    # Keep the verified B1 portability/RM macro contracts instead of inventing
    # typedefs or defining away errors in an adapter header.
    omit = {"_LANGUAGE_C", "__NO_CTYPE", "NV_UNIX", "NV_LINUX",
            "NV_X86_64", "NV_ARCH_BITS"}
    defines = []
    found = {}
    for arg in original:
        if not arg.startswith("-D") or len(arg) <= 2:
            continue
        name, _, value = arg[2:].partition("=")
        if name in omit:
            continue
        if name in found and found[name] != value:
            raise ValueError("conflicting B1 compiler define " + name)
        if name not in found:
            found[name] = value
            defines.append(arg)
    must_match = {"PORT_IS_KERNEL_BUILD": "1",
                  "PORT_IS_CHECKED_BUILD": "0",
                  "PORT_MODULE_atomic": "1",
                  "PORT_MODULE_memory": "1",
                  "PORT_MODULE_core": "1"}
    for key, expected in must_match.items():
        if found.get(key) != expected:
            raise ValueError(f"B1 portability macro drift: {key}={found.get(key)}")
    return ["-include", str(header)] + defines, {
        "reference_source": "arch/nvalloc/unix/src/osapi.c",
        "source": "B1_MAKE_LOG_RECONSTRUCTION_CANDIDATE",
        "forced_include": str(header),
        "forced_include_sha256": hash_bytes(header.read_bytes()),
        "transplanted_macros": defines,
        "excluded_c_only_or_duplicate_macros": sorted(omit),
    }


def first_compiler_error(path):
    for line in path.read_text(errors="replace").splitlines():
        if "error:" in line or "fatal error:" in line:
            return line.strip()[:1000]
    return None


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
    try:
        b1_contract, rec["b1_portability_provenance"] = b1_rm_compile_contract(
            nv, logs.parent / "make-nvidia.log")
    except Exception as exc:
        rec["status"] = "BLOCKED_B1_PORTABILITY_PROVENANCE"
        rec["error"] = str(exc)
        return
    base = ["-arch", "x86_64", "-fapple-kext", "-mkernel", "-nostdinc"] + [
        "-I" + str(p) for p in include] + ["-D" + d for d in macros] + [
        "-fno-common", "-fno-builtin", "-O2"] + b1_contract
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
        compile_log = logs / ("NVRM-" + src + ".txt")
        item["compile_rc"] = command(cmd, scratch, compile_log)
        item["verified_object"] = False
        if item["compile_rc"] == 0:
            try:
                obj = MachO(dest)
                item["verified_object"] = (obj.filetype == 1 and
                                           int.from_bytes(obj.data[4:8], "little") == 0x01000007)
                if not item["verified_object"]:
                    item["error"] = "compiled output is not an x86_64 MH_OBJECT"
            except Exception as exc:
                item["error"] = "object parse failure: " + str(exc)
        else:
            item["first_error"] = first_compiler_error(compile_log)
    rec["compiled_objects"] = sum(bool(x.get("verified_object")) for x in rec["objects"])
    rec["required_objects"] = len(NVRM_CPP + NVRM_C)
    rec["status"] = ("SOURCE_COMPILE_PROBE_COMPLETE_NOT_LINKED"
                     if rec["compiled_objects"] == rec["required_objects"]
                     else "SOURCE_COMPILE_INCOMPLETE_NOT_LINKED")


def link_symbol_inventory(nv, scratch, report):
    """Text-only symbol inventory; NOT an ld run or a proof of NVRM linkability.

    Unresolved externals can legitimately be provided by macOS kernel exports.
    Duplicate providers may be weak; this reader does not decode n_desc.
    Never substitute unresolved symbols or count the KMS aggregate twice.
    """
    rec = {"label": "B2_CANDIDATE_STATIC_SYMBOL_INVENTORY_NOT_LINKED",
           "status": "NOT_RUN",
           "rules": ["All 11 NVRM compiled MH_OBJECTs required",
                     "Pinned RM 1055 and KMS 230 inputs required",
                     "nv-modeset-kernel.o aggregate excluded",
                     "Undefined imports are NOT automatically link errors",
                     "Weak vs strong symbol binding not classified here"]}
    report["link_symbol_inventory"] = rec
    objdata = []
    try:
        nvrm = report["nvrm"]
        if nvrm.get("compiled_objects") != 11 or nvrm.get("required_objects") != 11:
            rec["status"] = "BLOCKED_NVRM_COMPILE_INCOMPLETE"
            return
        for filename in NVRM_CPP + NVRM_C:
            objdata.append(("NVRM", scratch / ("NVRM-" + filename + ".o")))
        expected = (("nvidia", 1055), ("nvidia-modeset", 230))
        for module, count in expected:
            objdir = nv / "src" / module / "_out/Darwin_x86_64"
            found = sorted(p for p in objdir.glob("*.o") if p.is_file()
                           and not (module == "nvidia-modeset" and
                                    p.name == "nv-modeset-kernel.o"))
            if len(found) != count:
                rec["status"] = "BLOCKED_INPUT_OBJECT_COUNT"
                rec["error"] = f"{module}: found {len(found)}, required {count}"
                return
            objdata.extend((module, p) for p in found)

        from collections import defaultdict
        defined, undefined, provider = {}, {}, defaultdict(set)
        for module, path in objdata:
            key = module + "/" + path.name
            obj = MachO(path)
            if obj.filetype != 1 or int.from_bytes(obj.data[4:8], "little") != 0x01000007:
                raise ValueError("not an x86_64 MH_OBJECT: " + key)
            defs = {n for n, t, sec, v in obj.defined() if t & 1}
            defined[key], undefined[key] = defs, obj.undefined()
            for symbol in defs:
                provider[symbol].add(key)

        # NVRM objects are always linked explicitly. Only pull external RM/KMS
        # objects by actual undefined symbols, not by broad source-text names.
        selected = {k for k in defined if k.startswith("NVRM/")}
        encountered = set()
        missing = set()
        ambiguous = {}
        todo = [sym for key in selected for sym in undefined[key]]
        while todo:
            symbol = todo.pop()
            if symbol in encountered:
                continue
            encountered.add(symbol)
            if any(symbol in defined[k] for k in selected):
                continue
            candidates = provider.get(symbol, set()) - selected
            if len(candidates) == 1:
                key = next(iter(candidates))
                selected.add(key)
                todo.extend(undefined[key])
            elif len(candidates) > 1:
                ambiguous[symbol] = sorted(candidates)
            else:
                missing.add(symbol)

        # A root may have been classified as unresolved before a later input
        # introduced its provider; recompute unresolved from the final selection.
        resolved = set().union(*(defined[k] for k in selected))
        residual = set().union(*(undefined[k] for k in selected)) - resolved
        ambiguous_final = {n: sorted(provider[n] - selected) for n in residual
                           if len(provider.get(n, set()) - selected) > 1}
        unique_available = {n for n in residual
                            if len(provider.get(n, set()) - selected) == 1}
        external = residual - set(ambiguous_final) - unique_available
        rec.update({
            "status": "STATIC_SYMBOL_INVENTORY_COMPLETE_NOT_LINKED",
            "input_objects": {"NVRM": len(NVRM_CPP + NVRM_C),
                              "nvidia": 1055, "nvidia-modeset": 230},
            "selected_count": {m: sum(k.startswith(m + "/") for k in selected)
                               for m in ("NVRM", "nvidia", "nvidia-modeset")},
            "distinct_undefined_in_selected": len(set().union(*(undefined[k] for k in selected))),
            "unprovided_by_selected": len(residual),
            "possible_ambiguous_input_providers": len(ambiguous_final),
            "ambiguous_examples": dict(sorted(ambiguous_final.items())[:60]),
            "unique_provider_not_selected": len(unique_available),
            "external_or_system_provider_unknown": len(external),
            "external_symbol_examples": sorted(external)[:120],
            "warning": "Candidate static selection only; no Darwin ld, archive ordering, "
                       "weak/strong classification, kernel export resolution or WP1 validation."
        })
    except Exception as exc:
        rec["status"] = "BLOCKED_STATIC_INVENTORY"
        rec["error"] = str(exc)


def native_nvrm_link_candidate(nv, scratch, logs, report):
    """Attempt an actual Apple ld kext link, never sign/install/load/upload it.

    This intentionally links the *unmodified B1 OGKM inputs* with the 11
    compiled NVRM sources. The two separately probed upstream patches and
    the undefined WP1 work package are NOT silently injected.
    """
    record = {
        "status": "NOT_RUN",
        "label": "UNPATCHED_OGKM_INFERRED_NVRM_LINK_CANDIDATE",
        "wp1_included": False,
        "upstream_patch_objects_included": False,
        "sign_or_load": False,
        "binary_uploaded": False,
        "acceptance": "LINK_RESULT_ONLY_NOT_GPU_HARDWARE_VALIDATION",
        "toolchain": "selected Xcode / xcrun libtool + clang++",
        "static_libraries_order": ["libnvkernel-candidate.a", "libnvkms-candidate.a"],
        "link_flags_source": "pinned NullMoth build/accel_build.sh (NVAccel pattern, adapted to NVRM)",
    }
    report["native_link_candidate"] = record
    source_count = len(NVRM_CPP + NVRM_C)
    nr = report.get("nvrm", {})
    if nr.get("compiled_objects") != source_count or nr.get("required_objects") != source_count:
        record["status"] = "BLOCKED_NVRM_OBJECTS_INCOMPLETE"
        return
    out = scratch / "nvrm-link-candidate"
    out.mkdir(exist_ok=True)
    inputs = []
    for module, count in (("nvidia", 1055), ("nvidia-modeset", 230)):
        objdir = nv / "src" / module / "_out/Darwin_x86_64"
        objs = sorted(
            p for p in objdir.glob("*.o") if p.is_file()
            and not (module == "nvidia-modeset" and p.name == "nv-modeset-kernel.o")
        )
        if len(objs) != count:
            record["status"] = "BLOCKED_INPUT_OBJECT_COUNT"
            record["error"] = f"{module}: {len(objs)} != expected {count}"
            return
        for p in objs:
            parsed = MachO(p)
            if parsed.filetype != 1 or int.from_bytes(parsed.data[4:8], "little") != 0x01000007:
                raise ValueError(f"{p.name}: not x86_64 MH_OBJECT")
        inputs.append((module, objs))
    nvrm_objs = [scratch / ("NVRM-" + name + ".o") for name in NVRM_CPP + NVRM_C]
    for p in nvrm_objs:
        parsed = MachO(p)
        if parsed.filetype != 1 or int.from_bytes(parsed.data[4:8], "little") != 0x01000007:
            raise ValueError(f"{p.name}: invalid NVRM x86_64 MH_OBJECT")
    record["input_counts"] = {"nvidia": 1055, "nvidia-modeset": 230, "NVRM": source_count}

    archives = []
    for module, objs in inputs:
        name = "libnvkernel-candidate.a" if module == "nvidia" else "libnvkms-candidate.a"
        dst = out / name
        # Use a libtool filelist (not a GNU archive or an ELF aggregate).
        # The list and the archive remain inside the ephemeral scratch directory.
        filelist = out / (module + "-archive-inputs.txt")
        filelist.write_text("".join(str(p) + "\n" for p in objs), encoding="utf-8")
        cmd = ["xcrun", "libtool", "-static", "-o", str(dst), "-filelist", str(filelist)]
        rc = command(cmd, nv / "src" / module, logs / (module + "-archive-create.txt"))
        if rc:
            record["status"] = "ARCHIVE_CREATE_FAILED"
            record["failed_archive"] = module
            record["first_error"] = first_compiler_error(logs / (module + "-archive-create.txt"))
            record["archive_return_code"] = rc
            return
        if not dst.is_file() or dst.stat().st_size == 0:
            record["status"] = "ARCHIVE_MISSING_AFTER_SUCCESSFUL_TOOL_EXIT"
            return
        archives.append(dst)
    record["archives_created"] = [p.name for p in archives]

    # Link directly against original, verified RM/KMS archive candidates.
    # Do not suppress undefined externals, inject replacement symbols, force
    # load duplicate object definitions or link any previously released binary.
    linked = out / "NVRM-link-candidate"
    args = ["xcrun", "clang++", "-arch", "x86_64", "-fapple-kext",
            "-nostdlib", "-Xlinker", "-kext", "-o", str(linked)]
    args += [str(p) for p in nvrm_objs]
    args += [str(p) for p in archives]
    args += ["-lkmodc++", "-lkmod", "-lcc_kext"]
    record["link_argv_without_absolute_object_paths"] = [
        "xcrun clang++ -arch x86_64 -fapple-kext -nostdlib -Xlinker -kext",
        "11 NVRM native MH_OBJECTs", "libnvkernel-candidate.a", "libnvkms-candidate.a",
        "-lkmodc++ -lkmod -lcc_kext",
    ]
    linklog = logs / "nvrm-real-link.txt"
    code = command(args, out, linklog)
    record["link_return_code"] = code
    if code:
        record["status"] = "NVRM_NATIVE_LINK_FAILED"
        record["first_error"] = first_compiler_error(linklog)
        if not record["first_error"]:
            for line in linklog.read_text(errors="replace").splitlines():
                if any(word in line.lower() for word in
                       ("ld:", "not found", "undefined", "duplicate", "unable")):
                    record["first_error"] = line.strip()[:1200]
                    break
        return
    if not linked.is_file() or linked.stat().st_size == 0:
        record["status"] = "BLOCKED_NO_LINK_OUTPUT"
        return
    result = MachO(linked)
    record.update({
        "macho_cputype": int.from_bytes(result.data[4:8], "little"),
        "macho_filetype": result.filetype,
        "size_bytes": linked.stat().st_size,
        "sha256": hash_bytes(linked.read_bytes()),
        "undefined_symbols_count": len(result.undefined()),
    })
    if record["macho_cputype"] != 0x01000007 or result.filetype != 11:
        record["status"] = "LINKED_WRONG_MACHO_FORMAT"
        return
    record["status"] = "NVRM_NATIVE_LINK_CANDIDATE_CREATED_NOT_LOADABLE_EVIDENCE"


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
            link_symbol_inventory(nv, Path(t), report)
            # The real Apple kext link is diagnostic until WP1 and system
            # symbol provenance are established; it never changes B1 verdict.
            try:
                native_nvrm_link_candidate(nv, Path(t), details, report)
            except Exception as exc:
                report.setdefault("native_link_candidate", {})["status"] = "LINK_PROBE_EXCEPTION"
                report["native_link_candidate"]["error"] = str(exc)
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
