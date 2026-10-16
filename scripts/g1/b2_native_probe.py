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


def verified_fsp_replacements(nv, scratch, logs, report, original_rm_objects):
    """Exactly two fixed-upstream FSP source objects replace their own RM members.

    The already-compiled patch objects come from patched_probe() operating on
    pinned, pristine copies, using each original B1 compile command. This
    function cannot silently accept another patch, another source or a
    generated stub. The display patch is intentionally excluded.
    """
    rec = report.get("patch_probes", {}).get("fsp-timer-double-destroy", {})
    if rec.get("status") != "COMPILED_PROBE":
        raise ValueError("FSP upstream patch compilation has not passed")
    if rec.get("patch") != "610-fsp-timer-double-destroy.patch":
        raise ValueError("unexpected FSP patch identity")
    if rec.get("patch_sha256") != "2998eb54ae95310724b12d24f99e92b34cd4f6812bf9236cd0ba8249832784f0":
        raise ValueError("pinned FSP patch SHA256 changed")
    required = {
        "src/nvidia/src/kernel/gpu/fsp/kern_fsp.c",
        "src/nvidia/src/kernel/gpu/timer/timer_ostimer.c",
    }
    entries = rec.get("results", [])
    if len(entries) != 2 or {x.get("source") for x in entries} != required:
        raise ValueError("FSP patch inputs differ from fixed two-source contract")
    rm_root = nv / "src/nvidia"
    expected_originals = {p.resolve() for p in original_rm_objects}
    replaced = {}
    evidence = []
    for entry in entries:
        rel = entry["source"]
        if not entry.get("verified_object") or entry.get("compile_rc") != 0:
            raise ValueError("patched FSP compile result not accepted: " + rel)
        rel_rm = rel[len("src/nvidia/"):]
        argv = make_command(logs.parent / "make-nvidia.log", rel_rm)
        if argv.count("-o") != 1:
            raise ValueError("FSP original B1 object output ambiguous: " + rel)
        original = (rm_root / argv[argv.index("-o") + 1]).resolve()
        patched = scratch / "fsp-timer-double-destroy" / (Path(rel).name + ".o")
        if original not in expected_originals:
            raise ValueError("original FSP member missing from exactly 1055 RM inputs: " + rel)
        if original in replaced:
            raise ValueError("FSP original RM member reused")
        if not patched.is_file():
            raise ValueError("compiled patched FSP object is missing: " + str(patched))
        orig_obj, patched_obj = MachO(original), MachO(patched)
        for path, obj in ((original, orig_obj), (patched, patched_obj)):
            if obj.filetype != 1 or int.from_bytes(obj.data[4:8], "little") != 0x01000007:
                raise ValueError("FSP replacement not x86_64 MH_OBJECT: " + str(path))
        original_sha, patched_sha = hash_bytes(original.read_bytes()), hash_bytes(patched.read_bytes())
        if original_sha == patched_sha:
            raise ValueError("patch unexpectedly produced byte-identical source objects")
        replaced[original] = patched
        evidence.append({
            "source": rel,
            "original_member": original.name,
            "patched_member": patched.name,
            "original_object_sha256": original_sha,
            "patched_object_sha256": patched_sha,
            "pinned_patch_sha256": rec["patch_sha256"],
            "patched_source_sha256": entry.get("patched_sha256"),
        })
    if len(replaced) != 2:
        raise ValueError("expected exactly two replaced FSP members")
    return replaced, evidence


def fsp_link_map_proof(map_content, replacement_evidence):
    """Parse ld64's indexed # Object files table, not arbitrary substrings.

    This proves archive member selection only, not hardware patch effectiveness.
    """
    import re
    entries = []
    in_object_section = False
    seen_header = False
    seen_footer = False
    for line in map_content.splitlines():
        if line.strip() == "# Object files:":
            if seen_header:
                return "BLOCKED_AMBIGUOUS_LINK_MAP", {"reason": "duplicate object table"}
            seen_header = in_object_section = True
            continue
        if in_object_section and line.startswith("# "):
            if line.strip() == "# Sections:":
                seen_footer = True
                break
            return "BLOCKED_LINK_MAP_UNEXPECTED_SECTION", {"reason": line.strip()}
        if in_object_section:
            m = re.match(r"^\s*\[\s*\d+\s*\]\s+(.+?)\s*$", line)
            if m:
                entries.append(m.group(1))
            elif line.strip():
                return "BLOCKED_LINK_MAP_PARSE", {"unexpected": line.strip()[:200]}
    if not seen_header or not seen_footer or not entries:
        return "BLOCKED_LINK_MAP_PARSE", {
            "object_table_found": seen_header,
            "section_end_found": seen_footer,
            "object_row_count": len(entries),
        }
    proof = {
        "link_map_object_rows": len(entries),
        "RM_archive": "libnvkernel-candidate.a",
        "members": {},
    }
    archived = [e for e in entries if "libnvkernel-candidate.a(" in e]
    for item in replacement_evidence:
        original = "libnvkernel-candidate.a(" + item["original_member"] + ")"
        patched = "libnvkernel-candidate.a(" + item["patched_member"] + ")"
        original_rows = [x for x in archived if x.endswith(original)]
        patched_rows = [x for x in archived if x.endswith(patched)]
        proof["members"][item["source"]] = {
            "original_member": item["original_member"],
            "patched_member": item["patched_member"],
            "original_selected_count": len(original_rows),
            "patched_selected_count": len(patched_rows),
        }
        if original_rows:
            return "BLOCKED_UNPATCHED_FSP_MEMBER_IN_LINK_MAP", proof
        if len(patched_rows) != 1:
            return "BLOCKED_PATCHED_FSP_MEMBER_SELECTION_NOT_EXACTLY_ONE", proof
    if len(replacement_evidence) != 2:
        return "BLOCKED_FSP_REPLACEMENT_COUNT", proof
    return "FSP_PATCH_MEMBERS_SELECTED", proof


def native_nvrm_link_candidate(nv, scratch, logs, report, nvrm_override=None, report_key="native_link_candidate"):
    """Link the FSP-cleanup-patched RM plus baseline KMS and 11 NVRM objects.

    Only two pinned and separately compiled FSP objects replace their
    original B1 archive members. No WP1, display flip patch, NVAccel or
    framebuffer implementation is silently included. Never install/load.
    """
    record = {
        "status": "NOT_RUN",
        "label": "FSP_CLEANUP_PATCHED_NVRM_NATIVE_LINK_CANDIDATE",
        "wp1_included": False,
        "upstream_patch_objects_included": ["610-fsp-timer-double-destroy.patch"],
        "excluded_upstream_patch": "610-display-completion.patch (requires paired NVRMFB/NVAccel qualification)",
        "sign_or_load": False,
        "binary_uploaded": False,
        "acceptance": "LINK_RESULT_ONLY_NOT_GPU_HARDWARE_VALIDATION",
        "toolchain": "selected Xcode / xcrun libtool + clang++",
        "static_libraries_order": ["libnvkernel-candidate.a", "libnvkms-candidate.a"],
        "link_flags_source": "pinned NullMoth build/accel_build.sh (NVAccel pattern, adapted to NVRM)",
    }
    report[report_key] = record
    # Actual candidate identity is established from the selected source object
    # below; B6 must not be mislabeled as B4.
    source_count = len(NVRM_CPP + NVRM_C)
    nr = report.get("nvrm", {})
    if nr.get("compiled_objects") != source_count or nr.get("required_objects") != source_count:
        record["status"] = "BLOCKED_NVRM_OBJECTS_INCOMPLETE"
        return
    # B3/B4/B5/B6 must each retain a distinct native Mach-O and link map.
    variant = ("b9" if nvrm_override is not None and Path(nvrm_override).name.endswith(".b9.o")
               else "b8" if nvrm_override is not None and Path(nvrm_override).name.endswith(".b8.o")
               else "b7" if nvrm_override is not None and Path(nvrm_override).name.endswith(".b7.o")
               else "b6" if nvrm_override is not None and Path(nvrm_override).name.endswith(".b6.o")
               else "b5" if nvrm_override is not None and Path(nvrm_override).name.endswith(".b5.o")
               else "b4" if nvrm_override else "b3")
    out = scratch / ("nvrm-link-candidate-" + variant)
    record["source_variant"] = {"b3": "B3_BASELINE_NVRM_CPP",
                                "b4": "B4_PATCHED_NVRM_CPP",
                                "b5": "B5_PATCHED_NVRM_CPP",
                                "b6": "B6_PATCHED_NVRM_CPP",
                                "b7": "B7_PATCHED_NVRM_CPP",
                                "b8": "B8_PATCHED_NVRM_CPP",
                                "b9": "B9_PATCHED_NVRM_CPP"}[variant]
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
    if nvrm_override is not None:
        nvrm_objs[0] = Path(nvrm_override)
        if nvrm_objs[0].resolve() == (scratch / "NVRM-NVRM.cpp.o").resolve():
            raise ValueError("B4 cannot reuse baseline NVRM.cpp object")
    for p in nvrm_objs:
        parsed = MachO(p)
        if parsed.filetype != 1 or int.from_bytes(parsed.data[4:8], "little") != 0x01000007:
            raise ValueError(f"{p.name}: invalid NVRM x86_64 MH_OBJECT")
    record["input_counts"] = {"nvidia": 1055, "nvidia-modeset": 230, "NVRM": source_count}

    # Replace the known original RM members *before* archiving. Using the
    # original plus a patched extra object would create duplicate definitions,
    # and could silently link the unpatched implementation.
    try:
        rm_inputs = next(objects for mod, objects in inputs if mod == "nvidia")
        replacements, record["fsp_replacement_evidence"] = verified_fsp_replacements(
            nv, scratch, logs, report, rm_inputs)
        inputs = [(module, [replacements.get(p.resolve(), p) for p in objects])
                  if module == "nvidia" else (module, objects)
                  for module, objects in inputs]
        if sum(p in set(replacements.values()) for m, objs in inputs for p in objs) != 2:
            raise ValueError("two FSP replacement objects were not included exactly once")
        if any(p in {x.resolve() for x in rm_inputs}
               for m, objs in inputs for p in objs if p in replacements):
            raise ValueError("unpatched FSP member remains in archive input list")
    except Exception as exc:
        record["status"] = "BLOCKED_FSP_REPLACEMENT_PROVENANCE"
        record["error"] = str(exc)
        return

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
    # This is a CI-only link floor, not a claim about the installed macOS
    # version on the HONOR laptop. Align the link deployment target to the
    # actual selected SDK's kmod libraries to eliminate the previous warnings.
    sdk_version = subprocess.check_output(
        ["xcrun", "--sdk", "macosx", "--show-sdk-version"], text=True).strip()
    if not sdk_version or not all(x.isdigit() for x in sdk_version.split(".")):
        record["status"] = "BLOCKED_UNKNOWN_SDK_VERSION"
        return
    record["native_sdk_version"] = sdk_version
    record["ci_only_link_min_macos"] = sdk_version
    link_map = out / "nvrm-link-map.txt"
    args = ["xcrun", "clang++", "-arch", "x86_64", "-fapple-kext",
            "-mmacosx-version-min=" + sdk_version,
            "-nostdlib", "-Xlinker", "-kext",
            "-Xlinker", "-map", "-Xlinker", str(link_map),
            "-o", str(linked)]
    args += [str(p) for p in nvrm_objs]
    args += [str(p) for p in archives]
    args += ["-lkmodc++", "-lkmod", "-lcc_kext"]
    record["link_argv_without_absolute_object_paths"] = [
        "xcrun clang++ -arch x86_64 -fapple-kext -nostdlib -Xlinker -kext",
        "11 NVRM native MH_OBJECTs", "libnvkernel-candidate.a (2 FSP members replaced)", "libnvkms-candidate.a",
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
    if not link_map.is_file():
        record["status"] = "BLOCKED_LINK_MAP_UNAVAILABLE"
        return
    map_content = link_map.read_text(errors="replace")
    status, proof = fsp_link_map_proof(
        map_content, record["fsp_replacement_evidence"])
    record["link_map_patch_evidence"] = proof
    if status != "FSP_PATCH_MEMBERS_SELECTED":
        record["status"] = status
        return
    if nvrm_override is not None:
        import re
        objects_section = map_content.split("# Object files:\n", 1)
        if len(objects_section) != 2 or "# Sections:\n" not in objects_section[1]:
            record["status"] = "BLOCKED_OVERRIDE_LINK_MAP_PARSE"
            return
        object_rows = re.findall(r"^\s*\[\s*\d+\s*\]\s+(.+?)\s*$",
                                 objects_section[1].split("# Sections:\n", 1)[0], re.M)
        needle = str(Path(nvrm_override).resolve())
        hits = [row for row in object_rows if row == needle]
        baseline_hits = [row for row in object_rows
                         if row == str((scratch / "NVRM-NVRM.cpp.o").resolve())]
        record["selected_override_object_link_map_count"] = len(hits)
        record["baseline_source_object_link_map_count"] = len(baseline_hits)
        record["selected_override_object_name"] = Path(nvrm_override).name
        if len(hits) != 1 or baseline_hits:
            record["status"] = "BLOCKED_OVERRIDE_SOURCE_OBJECT_NOT_EXACTLY_ONCE"
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
    record["status"] = "FSP_PATCHED_NVRM_NATIVE_LINK_COMPLETE_NOT_LOADABLE_EVIDENCE"


def b4_patch_has_fixed_contract(text):
    """Validate the two file headers separately from six unified-diff hunks.

    The original implementation counted the mandatory second +++ header as
    an unexpected extra file, preventing *every* B4 compilation attempt.
    """
    import re
    lines = text.splitlines()
    if lines[:2] != ["--- a/kexts/NVRM/NVRM.cpp",
                     "+++ b/kexts/NVRM/NVRM.cpp"]:
        return False
    if sum(line.startswith("--- ") for line in lines) != 1:
        return False
    if sum(line.startswith("+++ ") for line in lines) != 1:
        return False
    hunks = [line for line in lines if line.startswith("@@ ")]
    if len(hunks) != 6 or any(not re.fullmatch(
            r"@@ -\d+(?:,\d+)? \+\d+(?:,\d+)? @@(?:.*)?", h)
            for h in hunks):
        return False
    if any(line.startswith(("diff --git ", "Index: ")) for line in lines):
        return False
    return True


def b4_compile_and_link(nm, nv, scratch, logs, report, patch_arg):
    """Opt-in B4 patched NVRM.cpp: pristine-source apply, compile, real link.

    Preserve the B3 candidate in the same run. No temporary Mach-O or
    archive leaves the runner. No kernel-level execution.
    """
    rec = {"label": "B4_MANUAL_GO_MSI_PREFLIGHT_CANDIDATE_NOT_LOADABLE",
           "status": "NOT_RUN", "source": "kexts/NVRM/NVRM.cpp",
           "patch": "b4_nvrm_manual_go_msi_preflight.patch",
           "binary_uploaded": False}
    report["b4_source_patch"] = rec
    try:
        patch = Path(patch_arg).resolve()
        if patch.name != rec["patch"] or not patch.is_file():
            raise ValueError("B4 source patch path/filename not found")
        raw = patch.read_bytes()
        rec["patch_sha256"] = hash_bytes(raw)
        text = raw.decode("utf-8")
        if rec["patch_sha256"] != "deed09545b1a3a54096ab36a7f4809a0b891fea5eef8d5ca1615bbd2bb9b5e44":
            raise ValueError("B4 source patch SHA256 differs from validated candidate")
        if not b4_patch_has_fixed_contract(text):
            raise ValueError("B4 patch changed its single-target six-hunk contract")
        upstream = nm / rec["source"]
        original = upstream.read_bytes()
        if original != subprocess.check_output(
                ["git", "-C", str(nm), "show", "HEAD:" + rec["source"]]):
            raise ValueError("B4 source differs from upstream pinned Git blob")
        own = scratch / "b4-pristine-source"
        dest = own / rec["source"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(original)
        rec["upstream_source_sha256"] = hash_bytes(original)
        check = command(["git", "apply", "--check", str(patch)], own,
                        logs / "b4-git-apply-check.txt")
        if check != 0:
            raise ValueError("B4 git apply --check failed on pristine upstream source")
        apply_rc = command(["git", "apply", str(patch)], own,
                           logs / "b4-git-apply.txt")
        if apply_rc != 0:
            raise ValueError("B4 git apply failed on pristine upstream source")
        patched = dest.read_bytes()
        if patched == original:
            raise ValueError("B4 patch left NVRM.cpp unchanged")
        rec["patched_source_sha256"] = hash_bytes(patched)
        txt = patched.decode("utf-8")
        start = txt.index("bool NVRM::start(IOService *provider)")
        go = txt.index("IOReturn NVRM::go(uint32_t pass)")
        if ("manualGo ? false : placeLargeBar1()" not in txt[start:go]
                or "if (manualGo)" not in txt[start:go]
                or "fAdapterInitFailed = true;" not in txt[go:]):
            raise ValueError("B4 manually gated start and sticky failure postcondition absent")
        before_adapter = txt[go:txt.index("rm_init_adapter(NULL, nv)", go)]
        if not (before_adapter.index("if (msi < 0)")
                < before_adapter.index("addEventSource(fIntSrc)")
                < before_adapter.index("fPCI->setMemoryEnable(true)")
                < before_adapter.index("fPCI->setBusMasterEnable(true)")):
            raise ValueError("B4 MSI-before-PCI-enable ordering not satisfied")

        # Reuse exact successful B2 clang++ flags and pinned include paths.
        # Only source and object output change; no invented compiler flags.
        log = logs / "NVRM-NVRM.cpp.txt"
        original_log = log.read_text(encoding="utf-8").splitlines()[0]
        if not original_log.startswith("ARGV="):
            raise ValueError("missing original native NVRM clang invocation")
        argv = json.loads(original_log[len("ARGV="):])
        if not isinstance(argv, list) or argv.count("-c") != 1 or argv.count("-o") != 1:
            raise ValueError("ambiguous NVRM original clang flags")
        original_compiled = (scratch / "NVRM-NVRM.cpp.o").resolve()
        if Path(argv[argv.index("-o") + 1]).resolve() != original_compiled:
            raise ValueError("NVRM original compiler output path drift")
        if Path(argv[argv.index("-c") + 1]).resolve() != upstream.resolve():
            raise ValueError("NVRM original compiler input path drift")
        b4_object = scratch / "NVRM-NVRM.cpp.b4.o"
        argv[argv.index("-c") + 1] = str(dest)
        argv[argv.index("-o") + 1] = str(b4_object)
        rec["compile_rc"] = command(argv, scratch, logs / "b4-NVRM-compile.txt")
        if rec["compile_rc"] != 0:
            rec["first_error"] = first_compiler_error(logs / "b4-NVRM-compile.txt")
            rec["status"] = "B4_NATIVE_COMPILE_FAILED"
            return
        compiled = MachO(b4_object)
        if compiled.filetype != 1 or int.from_bytes(compiled.data[4:8], "little") != 0x01000007:
            raise ValueError("B4 patched output not a native x86_64 MH_OBJECT")
        rec["compiled_object_sha256"] = hash_bytes(b4_object.read_bytes())
        rec["status"] = "B4_NATIVE_COMPILE_PASS_NOT_LINKED"
        native_nvrm_link_candidate(nv, scratch, logs, report,
                                   nvrm_override=b4_object,
                                   report_key="b4_native_link_candidate")
        rec["link_status"] = report["b4_native_link_candidate"]["status"]
        rec["status"] = ("B4_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"
                         if rec["link_status"] ==
                         "FSP_PATCHED_NVRM_NATIVE_LINK_COMPLETE_NOT_LOADABLE_EVIDENCE"
                         else "B4_NATIVE_LINK_CANDIDATE_BLOCKED")
    except Exception as exc:
        rec["status"] = "B4_BLOCKED_PREREQUISITE"
        rec["error"] = str(exc)


def b5_compile_and_link(nm, nv, scratch, logs, report, patch_arg, b4_arg):
    """Patch B4-derived pinned NVRM.cpp and link a separate B5 candidate."""
    rec = {"label": "B5_BAR_ROLLBACK_EXPERIMENTAL_NOT_LOADABLE",
           "status": "NOT_RUN", "binary_uploaded": False,
           "base": "B4_SOURCE_PATCH_APPLIED_FIRST"}
    report["b5_source_patch"] = rec
    try:
        b4 = Path(b4_arg).resolve()
        b5 = Path(patch_arg).resolve()
        if b5.name != "b5_nvrm_bar_rollback.patch":
            raise ValueError("unexpected B5 patch filename")
        if not b4.is_file() or not b5.is_file():
            raise ValueError("missing B4/B5 patches")
        upstream = nm / "kexts/NVRM/NVRM.cpp"
        source = upstream.read_bytes()
        if source != subprocess.check_output(
                ["git", "-C", str(nm), "show", "HEAD:kexts/NVRM/NVRM.cpp"]):
            raise ValueError("pinned B5 source not pristine")
        own = scratch / "b5-staged-source"
        dest = own / "kexts/NVRM/NVRM.cpp"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(source)
        rec["b4_patch_sha256"] = hash_bytes(b4.read_bytes())
        rec["b5_patch_sha256"] = hash_bytes(b5.read_bytes())
        if rec["b4_patch_sha256"] != "deed09545b1a3a54096ab36a7f4809a0b891fea5eef8d5ca1615bbd2bb9b5e44":
            raise ValueError("B4 parent patch pin changed")
        for tag, path in (("b4", b4), ("b5", b5)):
            if command(["git", "apply", "--check", str(path)], own,
                       logs / (tag + "-b5-check.txt")) != 0:
                raise ValueError(tag + " patch not applicable to B5 staging")
            if command(["git", "apply", str(path)], own,
                       logs / (tag + "-b5-apply.txt")) != 0:
                raise ValueError(tag + " patch application failed")
        updated = dest.read_bytes()
        rec["patched_source_sha256"] = hash_bytes(updated)
        txt = updated.decode("utf-8")
        bar = txt[txt.index("bool NVRM::placeLargeBar1()"):
                  txt.index("void NVRM::readBARs()")]
        start = txt[txt.index("bool NVRM::start(IOService *provider)"):
                    txt.index("extern \"C\" int sysctlbyname")]
        if not (bar.index("OSArray *arr =") < bar.index(
                "fPCI->configWrite16(0x04, cmd & ~0x2)")
                and "auto restoreBarConfiguration" in bar
                and "fBar1RollbackFailed = true;" in bar
                and "if (fBar1RollbackFailed)" in start):
            raise ValueError("B5 expected safety postconditions absent")

        # Exactly the B4 successful native compiler invocation, changing
        # only the source path and destination object in runner temp.
        compile_log = logs / "b4-NVRM-compile.txt"
        line = compile_log.read_text(errors="replace").splitlines()[0]
        if not line.startswith("ARGV="):
            raise ValueError("B4 original compiler invocation absent")
        argv = json.loads(line[5:])
        if not isinstance(argv, list) or argv.count("-c") != 1 or argv.count("-o") != 1:
            raise ValueError("ambiguous B4 compiler flags")
        if Path(argv[argv.index("-c") + 1]).name != "NVRM.cpp":
            raise ValueError("B4 original compiler source drift")
        b5_obj = scratch / "NVRM-NVRM.cpp.b5.o"
        argv[argv.index("-c") + 1] = str(dest)
        argv[argv.index("-o") + 1] = str(b5_obj)
        rec["compile_rc"] = command(argv, scratch, logs / "b5-NVRM-compile.txt")
        if rec["compile_rc"] != 0:
            rec["status"] = "B5_NATIVE_COMPILE_FAILED"
            rec["first_error"] = first_compiler_error(logs / "b5-NVRM-compile.txt")
            return
        obj = MachO(b5_obj)
        if obj.filetype != 1 or int.from_bytes(obj.data[4:8], "little") != 0x01000007:
            raise ValueError("B5 did not produce native x86_64 MH_OBJECT")
        rec["compiled_object_sha256"] = hash_bytes(b5_obj.read_bytes())
        native_nvrm_link_candidate(
            nv, scratch, logs, report, nvrm_override=b5_obj,
            report_key="b5_native_link_candidate")
        rec["link_status"] = report["b5_native_link_candidate"]["status"]
        rec["status"] = ("B5_LINK_CANDIDATE_PASS_NOT_LOADABLE"
                         if rec["link_status"] ==
                         "FSP_PATCHED_NVRM_NATIVE_LINK_COMPLETE_NOT_LOADABLE_EVIDENCE"
                         else "B5_LINK_BLOCKED")
    except Exception as exc:
        rec["status"] = "B5_BLOCKED_PREREQUISITE"
        rec["error"] = str(exc)


def b6_compile_and_link(nm, nv, scratch, logs, report, b6_arg, b5_arg, b4_arg):
    """Compile pinned B4+B5+B6 NVRM.cpp, link without runtime activation.

    This is evidence for a modified native source candidate only. Restoring
    PCI on real hardware remains NO-GO until concurrent stop/GSP quiescence
    and PCI root-port ownership are independently demonstrated.
    """
    rec = {"label": "B6_BAR_STOP_OWNERSHIP_EXPERIMENTAL_NOT_LOADABLE",
           "status": "NOT_RUN", "binary_uploaded": False,
           "activation": "NEVER", "source_patches": ["B4", "B5", "B6"]}
    report["b6_source_patch"] = rec
    try:
        patches = [Path(p).resolve() for p in (b4_arg, b5_arg, b6_arg)]
        expected_names = [
            "b4_nvrm_manual_go_msi_preflight.patch",
            "b5_nvrm_bar_rollback.patch",
            "b6_nvrm_bar_stop_ownership.patch",
        ]
        if [p.name for p in patches] != expected_names or not all(p.is_file() for p in patches):
            raise ValueError("B6 patch identities missing or changed")
        # Hard stop if the checked-in experimental B6 source patch drifts.
        b6_blob = subprocess.check_output(
            ["git", "hash-object", str(patches[2])], text=True).strip()
        if b6_blob != "9fe603c6b1a84831ef9904471ddfd27378d6927b":
            raise ValueError("B6 experimental patch Git blob differs from reviewed source")
        rec["patches_sha256"] = {tag: hash_bytes(p.read_bytes())
                                  for tag, p in zip(("B4", "B5", "B6"), patches)}
        if rec["patches_sha256"]["B4"] != "deed09545b1a3a54096ab36a7f4809a0b891fea5eef8d5ca1615bbd2bb9b5e44":
            raise ValueError("B4 parent patch pin changed")
        upstream = nm / "kexts/NVRM/NVRM.cpp"
        original = upstream.read_bytes()
        if original != subprocess.check_output(
                ["git", "-C", str(nm), "show", "HEAD:kexts/NVRM/NVRM.cpp"]):
            raise ValueError("pinned upstream source not pristine")
        staging = scratch / "b6-staged-source"
        dest = staging / "kexts/NVRM/NVRM.cpp"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(original)
        rec["upstream_source_sha256"] = hash_bytes(original)
        for label, patch in zip(("b4", "b5", "b6"), patches):
            if command(["git", "apply", "--check", str(patch)], staging,
                       logs / (label + "-b6-check.txt")):
                raise ValueError(label + " git apply --check failed in B6 staging")
            if command(["git", "apply", str(patch)], staging,
                       logs / (label + "-b6-apply.txt")):
                raise ValueError(label + " git apply failed in B6 staging")
        patched = dest.read_bytes()
        if patched == original:
            raise ValueError("B6 applied source still byte-identical to upstream")
        txt = patched.decode("utf-8")
        rec["patched_source_sha256"] = hash_bytes(patched)
        begin = txt.index("bool NVRM::placeLargeBar1()")
        end = txt.index("void NVRM::readBARs()", begin)
        bar = txt[begin:end]
        start = txt[txt.index("bool NVRM::start(IOService *provider)"):begin]
        stop = txt[txt.index("void NVRM::stop(IOService *provider)"):
                   txt.index("#undef super", txt.index("void NVRM::stop(IOService *provider)"))]
        if not ("explicitRelocate ? placeLargeBar1() : false" in start
                and "fBarOriginalMemory = mem;" in bar
                and "fBarRootPort = rp;" in bar
                and "bool NVRM::restorePlacedBar1ForStop()" in txt
                and "if (fAdapterInitFailed || fAdapter)" in txt
                and "if (currentCommand & 0x4)" in txt
                and "restorePlacedBar1ForStop()" in stop):
            raise ValueError("B6 BAR transaction/stop preconditions incomplete")

        # Reuse B5's actual successful native NVRM.cpp compiler invocation.
        native_compile_log = logs / "b5-NVRM-compile.txt"
        first_line = native_compile_log.read_text(errors="replace").splitlines()[0]
        if not first_line.startswith("ARGV="):
            raise ValueError("B5 native compilation did not capture argv")
        argv = json.loads(first_line[5:])
        if (not isinstance(argv, list) or argv.count("-c") != 1
                or argv.count("-o") != 1
                or Path(argv[argv.index("-c") + 1]).name != "NVRM.cpp"):
            raise ValueError("B5 compiler provenance changed")
        output = scratch / "NVRM-NVRM.cpp.b6.o"
        argv[argv.index("-c") + 1] = str(dest)
        argv[argv.index("-o") + 1] = str(output)
        rec["compile_rc"] = command(argv, scratch, logs / "b6-NVRM-compile.txt")
        if rec["compile_rc"]:
            rec["status"] = "B6_NATIVE_COMPILE_FAILED"
            rec["first_error"] = first_compiler_error(logs / "b6-NVRM-compile.txt")
            return
        obj = MachO(output)
        if obj.filetype != 1 or int.from_bytes(obj.data[4:8], "little") != 0x01000007:
            raise ValueError("B6 object is not native x86_64 MH_OBJECT")
        rec["compiled_object_sha256"] = hash_bytes(output.read_bytes())
        native_nvrm_link_candidate(nv, scratch, logs, report, nvrm_override=output,
                                   report_key="b6_native_link_candidate")
        rec["link_status"] = report["b6_native_link_candidate"]["status"]
        rec["status"] = ("B6_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"
                         if rec["link_status"] ==
                            "FSP_PATCHED_NVRM_NATIVE_LINK_COMPLETE_NOT_LOADABLE_EVIDENCE"
                         else "B6_NATIVE_LINK_CANDIDATE_BLOCKED")
    except Exception as exc:
        rec["status"] = "B6_BLOCKED_PREREQUISITE"
        rec["error"] = str(exc)


def b7_compile_and_link(nm, nv, scratch, logs, report, b7_patch):
    """Layer B7 on the B6 source already verified/built in the same CI job."""
    rec = {
        "label": "B7_RM_STAGED_EVENT_LOCKS_SOURCE_CANDIDATE",
        "status": "NOT_RUN",
        "binary_uploaded": False,
        "hardware_activation": "NEVER",
        "previous_candidate": "B6_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE",
    }
    report["b7_source_patch"] = rec
    try:
        path = Path(b7_patch).resolve()
        if path.name != "b7_nvrm_rm_preflight_event_locks.patch" or not path.is_file():
            raise ValueError("B7 reviewed patch not found")
        blob = subprocess.check_output(
            ["git", "hash-object", str(path)], text=True).strip()
        if blob != "3a47f85508017fcd8d56a88c81dd85899b72d9c5":
            raise ValueError("B7 patch Git blob differs from reviewed source")
        rec["patch_git_blob"] = blob
        rec["patch_sha256"] = hash_bytes(path.read_bytes())

        prior = report.get("b6_source_patch", {})
        if prior.get("status") != rec["previous_candidate"]:
            raise ValueError("B6 native link prerequisite not independently verified")
        b6 = scratch / "b6-staged-source/kexts/NVRM/NVRM.cpp"
        if not b6.is_file():
            raise ValueError("B6 source in original temporary build is missing")
        original = b6.read_bytes()
        if hash_bytes(original) != prior.get("patched_source_sha256"):
            raise ValueError("B6 source digest mismatch: refusing to build B7")
        stage = scratch / "b7-staged-source"
        source = stage / "kexts/NVRM/NVRM.cpp"
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(original)
        rec["base_b6_source_sha256"] = hash_bytes(original)
        if command(["git", "apply", "--check", str(path)], stage,
                   logs / "b7-source-apply-check.txt"):
            raise ValueError("B7 patch not applicable to B6 source")
        if command(["git", "apply", str(path)], stage,
                   logs / "b7-source-apply.txt"):
            raise ValueError("B7 patch failed on B6 source")
        content = source.read_bytes()
        if content == original:
            raise ValueError("B7 patch did not change NVRM.cpp")
        rec["patched_source_sha256"] = hash_bytes(content)
        txt = content.decode("utf-8")
        go = txt[txt.index("IOReturn NVRM::go(uint32_t pass)"):
                 txt.index("bool NVRM::interruptFilter(IOFilterInterruptEventSource *src)")]
        if not ("static bool gRmCtlEventLocksReady = false;" in txt
                and "bool         fGpuEventLocksReady = false;" in txt
                and "bool         fRmPreflightFailed = false;" in txt
                and "if (fRmPreflightFailed)" in go
                and "fRmPreflightFailed = true;" in go
                and go.index("if (!gRmCtlEventLocksReady)")
                    < go.index("if (!fGpuEventLocksReady)")
                    < go.index("rm_init_private_state()")
                    < go.index("if (pass >= 2 && fPassDone < 2)")
                and "rm_init_adapter(NULL, nv)" in go):
            raise ValueError("B7 RM staged event-lock invariants not satisfied")

        # Reuse B6's captured Xcode command, only changing -c and -o.
        line = (logs / "b6-NVRM-compile.txt").read_text(
            errors="replace").splitlines()[0]
        if not line.startswith("ARGV="):
            raise ValueError("original B6 native compile command unavailable")
        argv = json.loads(line[5:])
        if (not isinstance(argv, list) or argv.count("-c") != 1
                or argv.count("-o") != 1
                or Path(argv[argv.index("-c") + 1]).resolve() != b6.resolve()):
            raise ValueError("B6 native compile flags/source provenance drift")
        obj = scratch / "NVRM-NVRM.cpp.b7.o"
        argv[argv.index("-c") + 1] = str(source)
        argv[argv.index("-o") + 1] = str(obj)
        rec["compile_rc"] = command(argv, scratch, logs / "b7-NVRM-compile.txt")
        if rec["compile_rc"]:
            rec["status"] = "B7_NATIVE_COMPILE_FAILED"
            rec["first_error"] = first_compiler_error(logs / "b7-NVRM-compile.txt")
            return
        macho = MachO(obj)
        if macho.filetype != 1 or int.from_bytes(macho.data[4:8], "little") != 0x01000007:
            raise ValueError("B7 did not emit a native x86_64 MH_OBJECT")
        rec["compiled_object_sha256"] = hash_bytes(obj.read_bytes())
        native_nvrm_link_candidate(
            nv, scratch, logs, report, nvrm_override=obj,
            report_key="b7_native_link_candidate")
        rec["link_status"] = report["b7_native_link_candidate"]["status"]
        rec["status"] = ("B7_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"
                         if rec["link_status"] ==
                            "FSP_PATCHED_NVRM_NATIVE_LINK_COMPLETE_NOT_LOADABLE_EVIDENCE"
                         else "B7_NATIVE_LINK_CANDIDATE_BLOCKED")
    except Exception as exc:
        rec["status"] = "B7_BLOCKED_PREREQUISITE"
        rec["error"] = str(exc)


def b8_compile_and_link(nv, scratch, logs, report, b8_patch):
    """Add pinned B8 to previously native-compiled B7; build/link only.

    This is NOT evidence that a running go() has drained at stop, that MSI
    callbacks are quiescent, or that GSP/PCI teardown is safe on a laptop.
    """
    rec = {"status": "NOT_RUN", "label": "B8_RM_GLOBAL_FAIL_STOP_NOT_LOADABLE",
           "binary_uploaded": False, "hardware_activation": "NEVER"}
    report["b8_source_patch"] = rec
    try:
        patch = Path(b8_patch).resolve()
        if patch.name != "b8_nvrm_global_rm_stop_gate.patch" or not patch.is_file():
            raise ValueError("missing pinned B8 patch")
        blob = subprocess.check_output(
            ["git", "hash-object", str(patch)], text=True).strip()
        if blob != "ca6f45d20df3c2b7b2ff260499d42ddcda3d4e9e":
            raise ValueError("B8 patch Git blob deviates from source-reviewed candidate")
        rec["patch_git_blob"] = blob
        rec["patch_sha256"] = hash_bytes(patch.read_bytes())

        parent = report.get("b7_source_patch", {})
        if parent.get("status") != "B7_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE":
            raise ValueError("independent B7 native-link prerequisite absent")
        b7_source = scratch / "b7-staged-source/kexts/NVRM/NVRM.cpp"
        if (not b7_source.is_file() or
            hash_bytes(b7_source.read_bytes()) != parent.get("patched_source_sha256")):
            raise ValueError("B7 compiled source missing or sha256 mismatch")
        rec["parent_b7_source_sha256"] = hash_bytes(b7_source.read_bytes())
        stage = scratch / "b8-staged-source"
        src = stage / "kexts/NVRM/NVRM.cpp"
        src.parent.mkdir(parents=True, exist_ok=True)
        src.write_bytes(b7_source.read_bytes())
        if command(["git", "apply", "--check", str(patch)], stage,
                   logs / "b8-apply-check.txt"):
            raise ValueError("B8 git apply --check failed")
        if command(["git", "apply", str(patch)], stage,
                   logs / "b8-apply.txt"):
            raise ValueError("B8 git apply failed")
        source = src.read_text()
        if source.encode("utf-8") == b7_source.read_bytes():
            raise ValueError("B8 source unchanged")
        rec["patched_source_sha256"] = hash_bytes(src.read_bytes())
        go = source[source.index("IOReturn NVRM::go(uint32_t pass)"):
                    source.index("bool NVRM::interruptFilter(", source.index("IOReturn NVRM::go(uint32_t pass)"))]
        stop = source[source.index("void NVRM::stop(IOService *provider)"):
                      source.index("#undef super", source.index("void NVRM::stop(IOService *provider)"))]
        start = source[source.index("bool NVRM::start(IOService *provider)"):
                       source.index("void NVRM::autoGo(")]
        if not (
            "static bool gRmGlobalPreflightFailed = false;" in source
            and go.count("gRmGlobalPreflightFailed = true;") == 2
            and "if (gRmGlobalPreflightFailed)" in go
            and "stopping = fStopping != 0;" in go
            and "fStopping = 1;" in stop
            and "explicitAutoGo = !manualGo" in start
            and "if (!explicitAutoGo)" in start
            and "if (s->fStopping) break;" in source
            and 's->releaseBootHold("auto-go canceled by stop")' in source):
            raise ValueError("B8 source preflight and stop-gate contracts missing")

        original = (logs / "b7-NVRM-compile.txt").read_text(
            errors="replace").splitlines()[0]
        if not original.startswith("ARGV="):
            raise ValueError("B7 Apple clang++ invocation unavailable")
        argv = json.loads(original[5:])
        if (not isinstance(argv, list) or argv.count("-c") != 1
                or argv.count("-o") != 1):
            raise ValueError("B7 compiler command ambiguous")
        if Path(argv[argv.index("-c") + 1]).resolve() != b7_source.resolve():
            raise ValueError("B7 native clang input is not the verified source")
        b8_object = scratch / "NVRM-NVRM.cpp.b8.o"
        argv[argv.index("-c") + 1] = str(src)
        argv[argv.index("-o") + 1] = str(b8_object)
        rec["compile_rc"] = command(argv, scratch, logs / "b8-NVRM-compile.txt")
        if rec["compile_rc"] != 0:
            rec["status"] = "B8_NATIVE_COMPILE_FAILED"
            rec["first_error"] = first_compiler_error(logs / "b8-NVRM-compile.txt")
            return
        compiled = MachO(b8_object)
        if compiled.filetype != 1 or int.from_bytes(compiled.data[4:8], "little") != 0x01000007:
            raise ValueError("B8 object is not an x86_64 MH_OBJECT")
        rec["compiled_object_sha256"] = hash_bytes(b8_object.read_bytes())
        native_nvrm_link_candidate(
            nv, scratch, logs, report, nvrm_override=b8_object,
            report_key="b8_native_link_candidate")
        rec["link_status"] = report["b8_native_link_candidate"]["status"]
        rec["status"] = (
            "B8_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"
            if rec["link_status"] ==
                "FSP_PATCHED_NVRM_NATIVE_LINK_COMPLETE_NOT_LOADABLE_EVIDENCE"
            else "B8_NATIVE_LINK_CANDIDATE_BLOCKED")
    except Exception as exc:
        rec["status"] = "B8_BLOCKED_PREREQUISITE"
        rec["error"] = str(exc)


def b9_compile_and_link(nv, scratch, logs, report, b9_arg):
    """Strictly isolated native link of the B9 go-stop admission candidate.

    This does not establish runtime MSI, DMA, GSP, asynchronous autoGo or
    user-client quiescence; it must never enable installation or loading.
    """
    rec = {"status": "NOT_RUN", "label": "B9_GO_STOP_BOUNDED_DRAIN_NOT_LOADABLE",
           "binary_uploaded": False, "hardware_activation": "NEVER"}
    report["b9_source_patch"] = rec
    try:
        patch = Path(b9_arg).resolve()
        if not patch.is_file() or patch.name != "b9_nvrm_go_stop_drain.patch":
            raise ValueError("B9 expected source patch not found")
        blob = subprocess.check_output(
            ["git", "hash-object", str(patch)], text=True).strip()
        if blob != "fa6ee96cc0da18a923ceb33204c360d48ef6cf7b":
            raise ValueError("B9 reviewed patch differs from pinned Git object")
        rec["patch_git_blob"] = blob
        rec["patch_sha256"] = hash_bytes(patch.read_bytes())

        parent = report.get("b8_source_patch", {})
        if parent.get("status") != "B8_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE":
            raise ValueError("B8 native prerequisite has not passed")
        old = scratch / "b8-staged-source/kexts/NVRM/NVRM.cpp"
        if not old.is_file() or hash_bytes(old.read_bytes()) != parent.get("patched_source_sha256"):
            raise ValueError("B8 compiler input digest mismatch")
        rec["parent_b8_source_sha256"] = hash_bytes(old.read_bytes())
        stage = scratch / "b9-staged-source"
        new = stage / "kexts/NVRM/NVRM.cpp"
        new.parent.mkdir(parents=True, exist_ok=True)
        new.write_bytes(old.read_bytes())
        if command(["git", "apply", "--check", str(patch)], stage,
                   logs / "b9-patch-check.txt") != 0:
            raise ValueError("B9 patch cannot apply to B8 source")
        if command(["git", "apply", str(patch)], stage,
                   logs / "b9-patch-apply.txt") != 0:
            raise ValueError("B9 patch failed to apply")
        body = new.read_text()
        if new.read_bytes() == old.read_bytes():
            raise ValueError("B9 patch did not change the candidate")
        rec["patched_source_sha256"] = hash_bytes(new.read_bytes())
        go = body[body.index("IOReturn NVRM::go(uint32_t pass)"):
                  body.index("bool NVRM::interruptFilter(", body.index("IOReturn NVRM::go(uint32_t pass)"))]
        stop = body[body.index("void NVRM::stop(IOService *provider)"):
                    body.index("#undef super", body.index("void NVRM::stop(IOService *provider)"))]
        if not (
            "bool fGoInFlight = false;" in body
            and "bool fGoStopTimedOut = false;" in body
            and "fGoInFlight = true;" in go
            and "retain();" in go
            and "owner->fGoInFlight = false;" in go
            and "owner->release();" in go
            and go.index("fGoInFlight = true;") < go.index("IOLockUnlock(gNvClientsLock);")
            and stop.index("fStopping = 1;") < stop.index("active = fGoInFlight;")
            and stop.index("if (active) {") < stop.index("rm_shutdown_adapter(NULL, &fNv);")
            and stop.index("if (fAdapterInitFailed) {") < stop.index("rm_shutdown_adapter(NULL, &fNv);")
            and "IOSleep(10);" in stop
            and 'setProperty("nvrm-stop-quiescence", "BLOCKED: go in flight / missing lock")' in stop
        ):
            raise ValueError("B9 ownership, timeout or unknown RM state contract missing")

        line = (logs / "b8-NVRM-compile.txt").read_text(
            errors="replace").splitlines()[0]
        if not line.startswith("ARGV="):
            raise ValueError("B8 verified compiler command missing")
        argv = json.loads(line[5:])
        if not isinstance(argv, list) or argv.count("-c") != 1 or argv.count("-o") != 1:
            raise ValueError("ambiguous B8 compiler flags")
        if Path(argv[argv.index("-c") + 1]).resolve() != old.resolve():
            raise ValueError("B8 compiler source provenance drift")
        target = scratch / "NVRM-NVRM.cpp.b9.o"
        argv[argv.index("-c") + 1] = str(new)
        argv[argv.index("-o") + 1] = str(target)
        rec["compile_rc"] = command(argv, scratch, logs / "b9-NVRM-compile.txt")
        if rec["compile_rc"] != 0:
            rec["status"] = "B9_NATIVE_COMPILE_FAILED"
            rec["first_error"] = first_compiler_error(logs / "b9-NVRM-compile.txt")
            return
        macho = MachO(target)
        if macho.filetype != 1 or int.from_bytes(macho.data[4:8], "little") != 0x01000007:
            raise ValueError("B9 object not native x86_64 MH_OBJECT")
        rec["compiled_object_sha256"] = hash_bytes(target.read_bytes())
        native_nvrm_link_candidate(
            nv, scratch, logs, report, nvrm_override=target,
            report_key="b9_native_link_candidate")
        rec["link_status"] = report["b9_native_link_candidate"]["status"]
        rec["status"] = (
            "B9_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"
            if rec["link_status"] ==
                "FSP_PATCHED_NVRM_NATIVE_LINK_COMPLETE_NOT_LOADABLE_EVIDENCE"
            else "B9_NATIVE_LINK_CANDIDATE_BLOCKED")
    except Exception as exc:
        rec["status"] = "B9_BLOCKED_PREREQUISITE"
        rec["error"] = str(exc)


def main():
    p = argparse.ArgumentParser()
    for name in ("nullmoth", "ogkm", "b1-logs", "report"):
        p.add_argument("--" + name, required=True)
    p.add_argument("--b4-patch", help="Optional pinned manual-go/MSI patch (compile and link only)")
    p.add_argument("--b5-patch", help="Optional B5 BAR rollback patch (requires B4)")
    p.add_argument("--b6-patch", help="Optional B6 BAR stop ownership patch (requires B4+B5)")
    p.add_argument("--b7-patch", help="Optional B7 RM event-lock preflight patch (requires B6)")
    p.add_argument("--b8-patch", help="Optional B8 global RM/stop-admission patch (requires B7)")
    p.add_argument("--b9-patch", help="Optional B9 go-stop ownership patch (requires B8)")
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
            if a.b4_patch:
                b4_compile_and_link(nm, nv, Path(t), details, report, a.b4_patch)
            if a.b5_patch:
                if not a.b4_patch or report.get("b4_source_patch", {}).get("status") != "B4_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE":
                    report["b5_source_patch"] = {"status": "BLOCKED_REQUIRES_SUCCESSFUL_B4_LINK"}
                else:
                    b5_compile_and_link(nm, nv, Path(t), details, report, a.b5_patch, a.b4_patch)
            if a.b6_patch:
                if (not a.b4_patch or not a.b5_patch or
                    report.get("b5_source_patch", {}).get("status") !=
                    "B5_LINK_CANDIDATE_PASS_NOT_LOADABLE"):
                    report["b6_source_patch"] = {"status": "BLOCKED_REQUIRES_SUCCESSFUL_B5_LINK"}
                else:
                    b6_compile_and_link(nm, nv, Path(t), details, report,
                                        a.b6_patch, a.b5_patch, a.b4_patch)
            if a.b7_patch:
                if (not a.b6_patch or
                    report.get("b6_source_patch", {}).get("status") !=
                    "B6_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"):
                    report["b7_source_patch"] = {"status": "BLOCKED_REQUIRES_SUCCESSFUL_B6_LINK"}
                else:
                    b7_compile_and_link(nm, nv, Path(t), details, report, a.b7_patch)
            if a.b8_patch:
                if (not a.b7_patch or
                    report.get("b7_source_patch", {}).get("status") !=
                    "B7_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"):
                    report["b8_source_patch"] = {
                        "status": "BLOCKED_REQUIRES_SUCCESSFUL_B7_LINK"}
                else:
                    b8_compile_and_link(nv, Path(t), details, report, a.b8_patch)
            if a.b9_patch:
                if (not a.b8_patch or
                    report.get("b8_source_patch", {}).get("status") !=
                    "B8_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE"):
                    report["b9_source_patch"] = {
                        "status": "BLOCKED_REQUIRES_SUCCESSFUL_B8_LINK"}
                else:
                    b9_compile_and_link(nv, Path(t), details, report, a.b9_patch)
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
