#!/usr/bin/env python3
"""Manual native object gate for a complete, fixed source tree and a clearly labelled candidate.
Never builds from released objects, never installs/loads a driver, never starts a GPU.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import struct
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'tools'))
from g1_compile_inputs import bound_compile

PINS = {"nm": "ac55984c473e746c2a8ebea7ba0913461aa7c393", "nv": "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb"}


def execute(argv, cwd, log):
    with log.open("w", encoding="utf-8") as stream:
        stream.write("ARGV=" + json.dumps(argv) + "\n")
        stream.flush()
        result = subprocess.run(argv, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT)
        stream.write("\nEXIT=" + str(result.returncode) + "\n")
    return result.returncode



def object_destination(directory, role, source_relative):
    # Include the complete source path, not just its basename.
    rel = Path(source_relative).as_posix()
    if Path(rel).is_absolute() or '..' in Path(rel).parts:
        raise ValueError("source key must be relative")
    key = hashlib.sha256(rel.encode()).hexdigest()[:16]
    return directory / (role + "-" + Path(rel).stem + "-" + key + ".o")


def link_object_list(baseline, additions):
    objects = [*baseline, *additions]
    resolved = [p.resolve() for p in objects]
    if len(set(resolved)) != len(resolved):
        raise ValueError("duplicate link object")
    if any(not p.is_file() for p in objects):
        raise ValueError("missing link object")
    return objects


def object_record(role, tree, source, obj, rc):
    entry = {"role": role, "source": str(source.relative_to(tree)),
             "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
             "object": str(obj), "compile_exit": rc}
    if rc == 0:
        data = obj.read_bytes()
        if len(data) < 32 or struct.unpack_from("<III", data)[:2] != (0xfeedfacf, 0x01000007) or struct.unpack_from("<I", data, 12)[0] != 1:
            raise ValueError("successful compile did not produce x86_64 MH_OBJECT")
        entry["object_sha256"] = hashlib.sha256(data).hexdigest()
    return entry


def import_set(path):
    return sorted({line.strip() for line in path.read_text(
        encoding="utf-8", errors="strict").splitlines() if line.strip().startswith("_")})


def macros_from_make(text):
    for line in text.splitlines():
        try:
            command = shlex.split(line.split(" && ", 1)[0])
        except ValueError:
            continue
        if "-c" in command and command[command.index("-c") + 1] == "arch/nvalloc/unix/src/osapi.c":
            definitions = [part for part in command if part.startswith("-D") and part not in ("-DNVRM", "-D_LANGUAGE_C")]
            if not definitions:
                raise ValueError("empty RM definition list")
            return definitions
    raise ValueError("fixed Makefile did not emit the real osapi.c command")



def unified_includes(includes, probe_root):
    probe_inc = ["-I" + str(p) for p in includes if Path(p).is_dir()]
    probe_inc += ["-I" + str(d) for d in (
        probe_root / "src/nvidia/arch/nvalloc/unix/include",
        probe_root / "src/nvidia",
        probe_root / "src/common/softfloat/nvidia",      # nv-softfloat.h lives here
        probe_root / "src/common/softfloat",
        probe_root / "src/common/softfloat/source/include",
        probe_root / "src/common/softfloat/source/8086-SSE",
        probe_root / "src/common/unix/nvidia-headsurface",
        probe_root / "src/common/softfloat/source",
        probe_root / "src/nvidia/src/libraries/libspdm/nvidia",
        probe_root / "src/nvidia/src/libraries/libspdm/3.5.0/include",
        probe_root / "src/nvidia/src/libraries/libspdm",
        probe_root / "src/nvidia-modeset/include") if d.is_dir()]
    return probe_inc


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--nm", required=True)
    parser.add_argument("--nv", required=True)
    parser.add_argument("--assets", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--caller-only", action="store_true", help="Nine real caller objects and IR only; no links or RM build")
    args = parser.parse_args()
    nm, nv, assets, out = [Path(getattr(args, key)).resolve() for key in ("nm", "nv", "assets", "out")]
    out.mkdir(parents=True, exist_ok=True)
    report = {"level": "DARWIN-COMPILE_CANDIDATE_NOT_YET_PASSED", "pins": PINS, "objects": [],
              "kext_link": "BLOCKED_NOT_ATTEMPTED_PRIVATE_FAMILY_ABI_AND_TARGET_KERNEL_EXPORTS_UNVERIFIED",
              "kext_load": "NO-GO", "gpu_runtime": "NOT_RUN", "display_runtime": "NOT_RUN", "build_manifest": [],
              "closure_acceptance": {"status": "NOT_ESTABLISHED", "target_kernel_exports": "NOT_VERIFIED"}}
    failures = []
    try:
        for key, tree in (("nm", nm), ("nv", nv)):
            actual = subprocess.check_output(["git", "-C", str(tree), "rev-parse", "HEAD"], text=True).strip()
            if actual != PINS[key]:
                raise ValueError(f"{key}: fixed commit mismatch")
        candidate = out.parent / "nullmoth-v2.3.3-gpu-safety-r5-candidate"
        shutil.copytree(nm, candidate, ignore=shutil.ignore_patterns(".git"))
        report["patches"] = []
        for number, name in enumerate(("gpu-safety-r1.patch", "gpu-safety-r2-kms-open.patch", "nullmoth-r3-thread-call-comment.patch", "nullmoth-r4-bridge-owner.patch", "nullmoth-r5-kms-close-deferred.patch", "nullmoth-r6-kms-close-reclaim.patch", "nullmoth-r7-kapi-device-rollback.patch", "nullmoth-r8-shared-device-lifetime.patch", "nullmoth-r9-pm-gated-device-teardown.patch", "nullmoth-r10-nvrmfb-production-lifetime.patch", "nullmoth-r11-orphan-device-recovery.patch", "nullmoth-r12-serialize-device-state.patch", "nullmoth-r14-orphan-ownership-fix.patch", "nullmoth-r15-pm-pin-teardown.patch", "nullmoth-r16-intel-bounded-vbl-teardown.patch", "nullmoth-r17-intel-owner-copy.patch", "nullmoth-r18-intel-restart-safety.patch", "nullmoth-r19-owner-copy-without-kva.patch", "nullmoth-r20-intel-register-dump.patch", "nullmoth-r21-deferred-close-instrumentation.patch", "nullmoth-r22-safety-convergence.patch", "nullmoth-r23-pm-pin-exclusion.patch", "nullmoth-r24-suspend-begin-commit.patch", "nullmoth-r25-vbl-single-owner.patch", "nullmoth-r26-drop-unused-const.patch", "nullmoth-r27-precheck-before-free.patch", "nullmoth-r29-explicit-aperture-offset-cast.patch", "nullmoth-r28-owner-copy-errors.patch", "nullmoth-r30-deferred-close-drain.patch"), 1):
            patch = assets / name
            for suffix in (["--check"], []):
                if execute(["git", "-c", "core.autocrlf=false", "apply", *suffix, "--whitespace=error-all", str(patch)], candidate,
                           out / (f"patch-{number}-check.txt" if suffix else f"patch-{number}-apply.txt")):
                    raise ValueError("complete-source sequential patch application failed")
            report["patches"].append({"name": name, "sha256": hashlib.sha256(patch.read_bytes()).hexdigest()})
        sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()
        khdr = Path(sdk) / "System/Library/Frameworks/Kernel.framework/Headers"
        if not (khdr / "IOKit").is_dir():
            raise ValueError("Kernel.framework headers unavailable")
        dryrun = out / "rm-make-dryrun.txt"
        rc = execute(["gmake", "-n", "TARGET_OS=Darwin", "TARGET_ARCH=x86_64", "CC=clang", "NV_VERBOSE=1",
                      "EXTRA_CFLAGS=-DNV_UNIX -DNV_LINUX"], nv / "src/nvidia", dryrun)
        if rc:
            raise ValueError("fixed Makefile configuration dry-run failed")
        definitions = macros_from_make(dryrun.read_text(encoding="utf-8", errors="replace"))
        report["candidate_rm_definitions"] = definitions
        report["sdk"] = sdk
        nvroot = nv / "src/nvidia"
        common = nv / "src/common"
        kms = nv / "src/nvidia-modeset"
        includes = [nvroot / p for p in ("arch/nvalloc/unix/include", "arch/nvalloc/common/inc", "arch/nvalloc/common/inc/gsp",
                    "inc", "inc/os", "inc/kernel", "kernel/inc", "interface", "inc/libraries", "src/libraries", "generated", "src/mm/uvm/interface")]
        includes += [common / p for p in ("sdk/nvidia/inc", "sdk/nvidia/inc/hw", "inc", "shared/inc", "nvlink/interface",
                     "inc/swref", "inc/swref/published", "uproc/os/libos-v2.0.0/include", "uproc/os/common/include",
                     "inc/displayport", "nvlink/inband/interface", "unix/nvidia-push/interface", "unix/common/inc",
                     "modeset", "unix/common/utils/interface")]
        includes += [kms / p for p in ("os-interface/include", "kapi/interface", "kapi/include", "interface", "include")]
        # Flag profile taken from the upstream build scripts, not invented here:
        # build/accel_build.sh uses exactly -Wall -Wno-unused-parameter
        # -Wno-inconsistent-missing-override -Wno-unused-function -O2 and never passes
        # -Wextra or -Werror. R4 added both, so the gate failed on the unmodified
        # original objects too (IOPCIDevice deprecation) and measured nothing about the
        # candidate. Warnings stay visible and are compared differentially below.
        common_flags = ["-arch", "x86_64", "-mmacosx-version-min=15.5", "-isysroot", sdk, "-fapple-kext", "-mkernel", "-nostdinc",
                        "-I" + str(khdr), "-DKERNEL", "-DKERNEL_PRIVATE", "-DDRIVER_PRIVATE", "-DAPPLE", "-DNeXT",
                        "-std=c++17", "-fno-rtti", "-fno-exceptions", "-fno-builtin", "-fno-common", "-O2",
                        "-Wall", "-Wno-unused-parameter", "-Wno-inconsistent-missing-override", "-Wno-unused-function"]
        if args.caller_only:
            # Reuse the exact ordered unified profile, without entering any link/probe path.
            from g1_kc8_callers import run as observe_callers
            flags = [*common_flags, *definitions, "-DNVRM", *unified_includes(includes, nv),
                     "-I" + str(candidate / "kexts/NVRM")]
            observe_callers(nv, candidate, out, flags, report, execute)
            return
        # Same selected compiler/profile for original and candidate; no use of published binary objects.
        # NVRMFB is included because R7/R8 change kexts/NVRM/fb/nvrm-fb.cpp: a gate that skips that
        # translation unit would report a green build for code it never compiled.
        for label, tree in (("original", nm), ("candidate", candidate)):
            for unit in ("NMIntelFB", "NMIntelFBVirtual", "NVAccel", "NVKMSOS", "NVRM", "NVRMFB", "NVRMFB_LEGACY"):
                if unit in ("NVAccel", "NVKMSOS", "NVRM", "NVRMFB", "NVRMFB_LEGACY"):
                    # NVRMFB is kexts/NVRMFB/fb: the released binary contains strings unique to that
                    # file and none unique to kexts/NVRM/fb. Both are compiled so neither is skipped.
                    relsource = {"NVAccel":"kexts/NVRM/accel/nvrm-accel.cpp",
                                 "NVKMSOS":"kexts/NVRM/os-nvkms-xnu.cpp",
                                 "NVRM":"kexts/NVRM/NVRM.cpp",
                                 "NVRMFB":"kexts/NVRMFB/fb/nvrm-fb.cpp",
                                 "NVRMFB_LEGACY":"kexts/NVRM/fb/nvrm-fb.cpp"}[unit]
                    source = tree / relsource
                    flags = [*common_flags, *definitions, *["-I" + str(p) for p in includes]]
                    flags += ["-I" + str(tree / "kexts/NVRM"), "-I" + str(source.parent),
                              "-I" + str(source.parent / "iofam"), "-I" + str(source.parent / "re")]
                else:
                    source = tree / "kexts/NMIntelFB/intelfb.cpp"
                    flags = [*common_flags, "-I" + str(source.parent)]
                    if unit.endswith("Virtual"):
                        flags.append("-DNMINTELFB_VIRTUAL")
                stem = label + "-" + unit
                obj = out.parent / (stem + ".o")
                command = ["xcrun", "clang++", *flags, "-MMD", "-MF", str(out / (stem + ".d")), "-c", str(source), "-o", str(obj)]
                rc = execute(command, tree, out / (stem + "-compile.txt"))
                entry = {"profile": label, "unit": unit, "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(), "compile_exit": rc}
                entry["warnings"] = (out / (stem + "-compile.txt")).read_text(encoding="utf-8", errors="replace").count("warning:")
                report["objects"].append(entry)
                if rc:
                    failures.append(stem)
                    continue
                data = obj.read_bytes()
                if struct.unpack_from("<II", data)[0:2] != (0xfeedfacf, 0x01000007) or struct.unpack_from("<I", data, 12)[0] != 1:
                    raise ValueError("unexpected native object format")
                entry["object_sha256"] = hashlib.sha256(data).hexdigest()
                for suffix, tool in (("undefined", ["xcrun", "nm", "-u"]), ("defined", ["xcrun", "nm", "-gU"])):
                    status = execute([*tool, str(obj)], tree, out / (stem + "-" + suffix + ".txt"))
                    if status:
                        failures.append(stem + "-" + suffix)
        # Differential warning gate: upstream's absolute warning count is irrelevant, but the
        # candidate must not add warnings to any unit it touches.
        counts = {}
        for entry in report["objects"]:
            if "warnings" in entry:
                counts[(entry["profile"], entry["unit"])] = entry["warnings"]
        for unit in ("NMIntelFB", "NMIntelFBVirtual", "NVAccel", "NVKMSOS", "NVRM", "NVRMFB", "NVRMFB_LEGACY"):
            before, after = counts.get(("original", unit)), counts.get(("candidate", unit))
            if before is not None and after is not None and after > before:
                failures.append(f"{unit}-new-warnings")
        report["warning_counts"] = {f"{k[0]}/{k[1]}": v for k, v in counts.items()}

        # Kext link for the accelerator. Upstream links without a deployment target, but the objects
        # above are built with -mmacosx-version-min=15.5, and linking at the default 15.0 made ld
        # report three "built for newer macOS version (15.5) than being linked (15.0)" warnings.
        # Passing the same target keeps the measured Mach-O consistent with the objects it came from.
        link_obj = out.parent / "candidate-NVAccel.o"
        link_out = out.parent / "NVAccel.kext/Contents/MacOS/NVAccel"
        link_out.parent.mkdir(parents=True, exist_ok=True)
        link = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                str(link_obj), "-o", str(link_out)]
        rc = execute(link, nm, out / "nvaccel-kext-link.txt")
        link_entry = {"command": link, "exit": rc,
                      "method": "upstream build/accel_build.sh link line plus the deployment target of its objects"}
        if rc:
            link_entry["status"] = "LINK_FAILED"
            failures.append("NVAccel-kext-link")
        else:
            data = link_out.read_bytes()
            if len(data) < 16 or struct.unpack_from("<I", data)[0] not in (0xfeedface, 0xfeedfacf):
                raise ValueError("unexpected kext Mach-O magic")
            link_entry.update({"artifact": str(link_out), "sha256": hashlib.sha256(data).hexdigest(),
                               "size": len(data), "status": "KEXT-LINK_ONLY_NOT_LOADED"})
        report["kext_link"] = link_entry

        # NVRMFB is a single translation unit, so it can be linked the same way. Upstream ships no
        # link line for it; this one is the NVAccel line with the object and bundle swapped, and it
        # is reported as its own level rather than folded into the accelerator result.
        fb_obj = out.parent / "candidate-NVRMFB.o"
        fb_out = out.parent / "NVRMFB.kext/Contents/MacOS/NVRMFB"
        fb_out.parent.mkdir(parents=True, exist_ok=True)
        fb_link = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                   "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                   str(fb_obj), "-o", str(fb_out)]
        rc = execute(fb_link, nm, out / "nvrmfb-kext-link.txt")
        fb_entry = {"command": fb_link, "exit": rc,
                    "method": "NVAccel link line with the NVRMFB object and bundle; upstream publishes none"}
        if rc:
            fb_entry["status"] = "LINK_FAILED"
            failures.append("NVRMFB-kext-link")
        else:
            data = fb_out.read_bytes()
            if len(data) < 16 or struct.unpack_from("<I", data)[0] not in (0xfeedface, 0xfeedfacf):
                raise ValueError("unexpected NVRMFB Mach-O magic")
            execute(["xcrun", "nm", "-gU", str(fb_out)], nm, out / "nvrmfb-kext-defined.txt")
            execute(["xcrun", "nm", "-u", str(fb_out)], nm, out / "nvrmfb-kext-undefined.txt")
            defined = (out / "nvrmfb-kext-defined.txt").read_text(encoding="utf-8", errors="replace").splitlines()
            undefined = (out / "nvrmfb-kext-undefined.txt").read_text(encoding="utf-8", errors="replace").splitlines()
            fb_entry.update({"artifact": str(fb_out), "sha256": hashlib.sha256(data).hexdigest(),
                             "size": len(data), "defined_symbols": len(defined),
                             "undefined_symbols": len(undefined),
                             "status": "KEXT-LINK_ONLY_NOT_LOADED"})
        report["kext_link_nvrmfb"] = fb_entry

        # NVRM itself: no published recipe, so build it from every root C++ TU and report what the
        # link says. The sibling kexts (accel/, agdc/, fb/) are separate bundles and are excluded.
        nvrm_units = ["NVRM.cpp", "os-xnu.cpp", "os-xnu2.cpp", "os-nvkms-xnu.cpp", "nv_xnu_stubs.cpp",
                      "nvrm_gpuva.cpp", "nvrm_fbinfo.cpp", "nvrm_surfshare.cpp", "nvkms_shaders.cpp",
                      "kms_deferred.cpp"]
        nvrm_objects, nvrm_compile = [], {}
        for name in nvrm_units:
            src = candidate / "kexts/NVRM" / name
            obj = out.parent / ("candidate-NVRM_" + name.replace(".", "_") + ".o")
            flags = [*common_flags, *definitions, *["-I" + str(p) for p in includes]]
            flags += ["-I" + str(candidate / "kexts/NVRM")]
            rc = execute(["xcrun", "clang++", *flags, "-c", str(src), "-o", str(obj)],
                         candidate, out / ("candidate-NVRM_" + name.replace(".", "_") + "-compile.txt"))
            report["build_manifest"].append(object_record("nvrm-baseline", candidate, src, obj, rc))
            nvrm_compile[name] = rc
            if rc == 0:
                nvrm_objects.append(obj)
        report["nvrm_units"] = nvrm_compile
        if len(nvrm_objects) != len(nvrm_units):
            report["kext_link_nvrm"] = {"status": "COMPILE_INCOMPLETE", "units": nvrm_compile}
            failures.append("NVRM-kext-compile")
        else:
            nvrm_out = out.parent / "NVRM.kext/Contents/MacOS/NVRM"
            nvrm_out.parent.mkdir(parents=True, exist_ok=True)
            nvrm_link = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                         "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                         *[str(o) for o in nvrm_objects], "-o", str(nvrm_out)]
            rc = execute(nvrm_link, nm, out / "nvrm-kext-link.txt")
            entry = {"command": nvrm_link, "exit": rc, "units": nvrm_units,
                     "method": "every root C++ TU of kexts/NVRM, NVRMFB link line; upstream publishes none"}
            if rc:
                entry["status"] = "LINK_FAILED"
                failures.append("NVRM-kext-link")
            else:
                data = nvrm_out.read_bytes()
                if len(data) < 16 or struct.unpack_from("<I", data)[0] not in (0xfeedface, 0xfeedfacf):
                    raise ValueError("unexpected NVRM Mach-O magic")
                execute(["xcrun", "nm", "-gU", str(nvrm_out)], nm, out / "nvrm-kext-defined.txt")
                execute(["xcrun", "nm", "-u", str(nvrm_out)], nm, out / "nvrm-kext-undefined.txt")
                defined = (out / "nvrm-kext-defined.txt").read_text(encoding="utf-8", errors="replace").splitlines()
                undefined = (out / "nvrm-kext-undefined.txt").read_text(encoding="utf-8", errors="replace").splitlines()
                # The link succeeds with only ~2% of the shipped symbol count, so this is reported as an
                # incomplete unit set, never as "NVRM links".
                entry.update({"artifact": str(nvrm_out), "sha256": hashlib.sha256(data).hexdigest(),
                              "size": len(data), "defined_symbols": len(defined),
                              "undefined_symbols": len(undefined), "status": "KEXT-LINK_INCOMPLETE_UNIT_SET"})
            report["kext_link_nvrm"] = entry

        # Isolated probe: can the cross-OS translation units that define the missing NVKMS/RM symbols be
        # compiled as Darwin objects? They feed separate diagnostic links; failures do not pass
        # complete-closure acceptance. The selected native gate remains a separate result.
        ogkm_probe = ["src/nvidia/arch/nvalloc/unix/src/unix_intr.c",
                      "src/nvidia/arch/nvalloc/unix/src/osapi.c",
                      "src/nvidia/arch/nvalloc/unix/src/dynamic-power.c",
                      "src/nvidia-modeset/src/nvkms.c",
                      "src/nvidia-modeset/kapi/src/nvkms-kapi.c",
                      "src/nvidia-modeset/kapi/src/nvkms-kapi-sync.c",
                      "src/nvidia-modeset/kapi/src/nvkms-kapi-notifiers.c",
                      "src/nvidia-modeset/lib/nvkms-format.c",
                      "src/nvidia-modeset/lib/nvkms-sync.c",
                      "src/nvidia/arch/nvalloc/unix/src/os-hypervisor.c",
                      "src/nvidia/generated/g_regs_pb.c",
                      "src/nvidia/generated/g_rpc_iom.c",
                      "src/nvidia/generated/g_ccsl_nvoc.c"]
        # nvroot is <ogkm>/src/nvidia; the tree root is two levels up
        probe_root = nvroot.parent.parent
        if not (probe_root / "src/nvidia").exists():
            probe_root = nvroot
        probe_inc = unified_includes(includes, probe_root)
        probe_results, probe_objs = {}, []
        for rel in ogkm_probe:
            srcp = probe_root / rel
            if not srcp.exists():
                probe_results[rel] = {"status": "MISSING"}
                continue
            obj = out.parent / ("probe-" + rel.replace("/", "_") + ".o")
            # These are C sources; drop the C++-only flags and compile as C.
            c_flags = [f for f in common_flags if f not in ("-std=c++17", "-fno-rtti", "-fno-exceptions")]
            compat = Path(__file__).resolve().parents[2] / "research/gpu-safety-r5/darwin-compat"
            compat_flags = []
            # With -DNVRM the platform header provides nv_dynamic_power_mode_t itself; the shim would now
            # only collide with it (redefinition of enumerator). Keep the shim out of this configuration.
            if False and (compat / "nv-darwin-compat.h").exists():
                compat_flags = ["-I" + str(compat), "-include", str(compat / "nv-darwin-compat.h")]
            # Reconstructed profile retains NV_LINUX plus the compiler's Apple selectors.
            # This is recorded evidence, not a verified platform/ABI configuration.
            # nv_state_t lives inside #ifdef NVRM (src/.../unix/include/nv.h:266), and the gate strips
            # -DNVRM from its own macro list. The probe puts it back and keeps the platform selector.
            probe_defs = list(definitions) + ["-DNVRM"]
            cmd = ["xcrun", "clang", "-x", "c", "-std=gnu11", *c_flags, *probe_defs, *probe_inc,
                   *compat_flags, "-I" + str(srcp.parent), "-c", str(srcp), "-o", str(obj)]
            log = out / ("probe-" + rel.replace("/", "_") + ".txt")
            rc = execute(cmd, probe_root, log)
            report["build_manifest"].append(object_record("ogkm-probe", probe_root, srcp, obj, rc))
            if rc == 0:
                probe_objs.append(obj)
            lines = log.read_text(encoding="utf-8", errors="replace").splitlines()
            errs = []
            for i, l in enumerate(lines):
                if "error:" in l:
                    errs.extend(x.strip() for x in lines[i:i + 6] if x.strip())
                    if len(errs) >= 12:
                        break
            probe_results[rel] = {"exit": rc, "first_errors": errs,
                                  "status": "COMPILED" if rc == 0 else "COMPILE_FAILED"}
        # The last gap family is our own: kexts/NVRM/nvrm_pageoff.c defines the seven _nvrm_* symbols. It is a
        # C file that includes NVIDIA headers, so it gets the same -DNVRM/-x c configuration as the probe.
        cand_files = ["kexts/NVRM/nvrm_pageoff.c", "kexts/NVRM/nvrm_kapi_fields.c"]
        cand_src = candidate / cand_files[0]
        cand_probe = {}
        c_flags = [f for f in common_flags if f not in ("-std=c++17", "-fno-rtti", "-fno-exceptions")]
        cinc = ["-I" + str(candidate / "kexts/NVRM")] + ["-I" + str(p) for p in includes if Path(p).is_dir()]
        for cf in cand_files:
            csrc = candidate / cf
            if not csrc.exists():
                cand_probe[cf] = {"status": "MISSING"}
                continue
            obj = out.parent / ("probe-cand-" + csrc.stem + ".o")
            log = out / ("probe-cand-" + csrc.stem + ".txt")
            cmd = ["xcrun", "clang", "-x", "c", "-std=gnu11", *c_flags, *definitions, "-DNVRM", *cinc,
                   "-c", str(csrc), "-o", str(obj)]
            rc, inputs, cmd = bound_compile(cmd, candidate, log, out/'input-snapshots', execute)
            row = object_record("candidate-c-probe", candidate, csrc, obj, rc)
            row.update({'compile_cwd':str(candidate), 'dependency_snapshot':inputs})
            report["build_manifest"].append(row)
            if rc == 0:
                probe_objs.append(obj)
            lines = log.read_text(encoding="utf-8", errors="replace").splitlines()
            errs = []
            for i, l in enumerate(lines):
                if "error:" in l:
                    errs.extend(x.strip() for x in lines[i:i + 4] if x.strip())
                    if len(errs) >= 8:
                        break
            cand_probe[cf] = {"exit": rc, "first_errors": errs,
                              "status": "COMPILED" if rc == 0 else "COMPILE_FAILED"}
        probe_results.update(cand_probe)
        report["ogkm_probe"] = probe_results

        # The old every-fifth-source sample is superseded by the complete official
        # source-list build in tools/g1_full_build.py, a separate workflow step.
        # Do not turn its absent counts into a zero-failure or closure claim.
        report["rm_sample"] = {"status": "SUPERSEDED_BY_COMPLETE_OFFICIAL_SOURCE_BUILD",
                               "report": "full-source/report.json"}

        # Experiment: link the nine baseline units together with successful probe objects and measure how many of
        # the provider-less imports disappear. Report-only; the production artifact above is untouched.
        # Explicit successful objects only; no filesystem glob can inherit old outputs.
        if probe_objs:
            mix_out = out.parent / "NVRM-ogkm.kext/Contents/MacOS/NVRM"
            mix_out.parent.mkdir(parents=True, exist_ok=True)
            mix_link = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                        "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                        *[str(o) for o in nvrm_objects], *[str(o) for o in probe_objs], "-o", str(mix_out)]
            mix_rc = execute(mix_link, nm, out / "nvrm-ogkm-link.txt")
            mix = {"exit": mix_rc, "objects": len(nvrm_objects) + len(probe_objs)}
            if mix_rc == 0:
                execute(["xcrun", "nm", "-u", str(mix_out)], nm, out / "nvrm-ogkm-undefined.txt")
                undef = [l.strip() for l in (out / "nvrm-ogkm-undefined.txt").read_text(
                    encoding="utf-8", errors="replace").splitlines() if l.strip().startswith("_")]
                gap = [s for s in undef if s.startswith(("_nvKms", "_rm_", "_nvrm_"))]
                mix.update({"status": "LINKED", "size": mix_out.stat().st_size,
                            "undefined_symbols": len(undef), "selected_prefix_gap_symbols_left": len(gap),
                            "gap_sample": gap[:10]})
            else:
                mix["status"] = "LINK_FAILED"
                mix["errors"] = [l for l in (out / "nvrm-ogkm-link.txt").read_text(
                    encoding="utf-8", errors="replace").splitlines() if "error:" in l][:5]
            report["kext_link_nvrm_ogkm"] = mix

        # Unification experiment: compile the original units with the same -DNVRM the probe uses, so the
        # whole set shares one platform configuration. Report-only; the production artifact is untouched.
        uni_objs, uni = [], {}
        for name in nvrm_units:
            srcp = candidate / "kexts/NVRM" / name
            obj = out.parent / ("uni-" + name.replace(".", "_") + ".o")
            log = out / ("uni-" + name.replace(".", "_") + ".txt")
            cmd = ["xcrun", "clang++", *common_flags, *definitions, "-DNVRM", *probe_inc,
                   "-I" + str(candidate / "kexts/NVRM"), "-c", str(srcp), "-o", str(obj)]
            rc, inputs, cmd = bound_compile(cmd, candidate, log, out/'input-snapshots', execute)
            text = log.read_text(encoding="utf-8", errors="replace")
            uni[name] = {"exit": rc, "warnings": text.count("warning:")}
            if rc == 0:
                uni_objs.append(obj)
            row = object_record("nvrm-unified", candidate, srcp, obj, rc)
            row.update({'compile_cwd':str(candidate), 'dependency_snapshot':inputs})
            report["build_manifest"].append(row)
        if len(uni_objs) == len(nvrm_units) and probe_objs:
            u_out = out.parent / "NVRM-unified.kext/Contents/MacOS/NVRM"
            u_out.parent.mkdir(parents=True, exist_ok=True)
            u_link = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                      "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                      *[str(o) for o in uni_objs], *[str(o) for o in probe_objs], "-o", str(u_out)]
            u_rc = execute(u_link, nm, out / "nvrm-unified-link.txt")
            entry = {"units": uni, "exit": u_rc, "objects": len(uni_objs) + len(probe_objs)}
            if u_rc == 0:
                if execute(["xcrun", "nm", "-u", str(u_out)], nm, out / "nvrm-unified-undefined.txt"):
                    raise ValueError("unified import inventory failed")
                und = [l.strip() for l in (out / "nvrm-unified-undefined.txt").read_text(
                    encoding="utf-8", errors="replace").splitlines() if l.strip().startswith("_")]
                gap = [s for s in und if s.startswith(("_nvKms", "_rm_", "_nvrm_"))]
                entry.update({"status": "LINKED", "size": u_out.stat().st_size,
                              "undefined_symbols": len(und), "selected_prefix_gap_symbols_left": len(gap)})
            else:
                entry["status"] = "LINK_FAILED"
            report["kext_link_nvrm_unified"] = entry

        # First controlled batch: compile every file that the symbol index says defines a gap symbol.
        # The list comes from research/gpu-safety-r5/rm-gap-index.json, so it is reproducible outside CI.
        idx_path = Path(__file__).resolve().parents[2] / "research/gpu-safety-r5/rm-gap-index.json"
        batch = {"attempted": 0, "compiled": 0, "failed": [], "missing": [], "excluded": [], "capped": False}
        batch_objs = []
        if idx_path.exists():
            import json as _json
            idx = _json.loads(idx_path.read_text(encoding="utf-8"))
            files = [f for f in idx.get("defining_files", []) if not f.startswith("kernel-open/")]
            CAP = 100
            if len(files) > CAP:
                files = files[:CAP]
                batch["capped"] = True
            bflags = [f for f in common_flags if f not in ("-std=c++17", "-fno-rtti", "-fno-exceptions")]
            # src/common/src holds user-space helpers (nv_smg.c needs pthread.h); they are not kext code.
            # Also drop any file that already contributed a probe object: linking both copies produced
            # duplicate symbols (_nvKmsKapiAllocateVideoMemory ...), and object names cannot be matched
            # back to sources, so the exclusion has to happen on paths.
            batch["excluded"] = [{"source": f, "reason": "user-space directory" if f.startswith("src/common/src/") else "already in probe"} for f in files if f.startswith("src/common/src/") or f in set(ogkm_probe)]
            files = [f for f in files if not f.startswith("src/common/src/") and f not in set(ogkm_probe)]
            for rel in files:
                srcp = probe_root / rel
                if not srcp.exists():
                    batch["missing"].append(rel)
                    continue
                batch["attempted"] += 1
                obj = object_destination(out.parent, "bat", rel)
                log = out / (obj.stem + ".txt")
                cmd = ["xcrun", "clang", "-x", "c", "-std=gnu11", *bflags, *definitions, "-DNVRM", *probe_inc,
                       "-I" + str(srcp.parent), "-c", str(srcp), "-o", str(obj)]
                rc = execute(cmd, probe_root, log)
                report["build_manifest"].append(object_record("rm-batch", probe_root, srcp, obj, rc))
                if rc == 0:
                    batch["compiled"] += 1
                    batch_objs.append(obj)
                else:
                    errs = [l for l in log.read_text(encoding="utf-8", errors="replace").splitlines()
                            if "error:" in l][:2]
                    batch["failed"].append({"file": rel, "errors": errs})
        else:
            batch["missing"].append(str(idx_path))
        report["rm_defs_batch"] = batch
        report["closure_acceptance"].update({
            "batch_compiler_failures": len(batch["failed"]),
            "batch_missing_sources": len(batch["missing"]),
            "batch_capped": batch["capped"],
            "probe_failures_or_missing": sum(v.get("status") != "COMPILED" for v in probe_results.values()),
            "reason": "selected batch is not a complete RM/modeset object inventory; external exports and full ABI remain unverified"})
        baseline_inputs = [*uni_objs, *probe_objs]
        if len(uni_objs) == len(nvrm_units) and probe_objs and batch_objs:
            inputs = link_object_list(baseline_inputs, batch_objs)
            b_out = out.parent / "NVRM-rmbatch.kext/Contents/MacOS/NVRM"
            b_out.parent.mkdir(parents=True, exist_ok=True)
            b_link = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                      "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                      *[str(o) for o in inputs], "-o", str(b_out)]
            b_rc = execute(b_link, nm, out / "nvrm-rmbatch-link.txt")
            entry = {"objects": len(inputs), "exit": b_rc,
                     "baseline_objects": [str(o) for o in baseline_inputs],
                     "added_objects": [str(o) for o in batch_objs],
                     "input_completeness": "INCOMPLETE" if batch["failed"] or batch["missing"] or batch["capped"] else "SELECTED_BATCH_COMPLETE"}
            if b_rc == 0:
                nm_rc = execute(["xcrun", "nm", "-u", str(b_out)], nm, out / "nvrm-rmbatch-undefined.txt")
                if nm_rc:
                    raise ValueError("batch import inventory failed")
                after = import_set(out / "nvrm-rmbatch-undefined.txt")
                entry.update({"status": "LINKED_PARTIAL_CLOSURE", "size": b_out.stat().st_size,
                              "undefined_symbols": len(after)})
                if report.get("kext_link_nvrm_unified", {}).get("exit") == 0:
                    before = import_set(out / "nvrm-unified-undefined.txt")
                    entry["comparison"] = {"basis": "same nine unified NVRM and explicit probe objects retained",
                                           "baseline_count": len(before), "candidate_count": len(after),
                                           "added_imports": sorted(set(after)-set(before)),
                                           "removed_imports": sorted(set(before)-set(after)),
                                           "convergence": "NOT_DETERMINED_BY_ONE_ITERATION"}
            else:
                entry["status"] = "LINK_FAILED"
                entry["errors"] = [l for l in (out / "nvrm-rmbatch-link.txt").read_text(
                    encoding="utf-8", errors="replace").splitlines() if "error:" in l][:5]
            report["kext_link_nvrm_rmbatch"] = entry

        # Intel side: NMIntelFB is a single TU compiled twice (real / virtual), each with its own
        # bundle. Linking both reports what the Intel kext actually becomes; it is not a GPU test.
        intel_links = {}
        for unit, bundle in (("NMIntelFB", "NMIntelFB.kext"), ("NMIntelFBVirtual", "NMIntelFBVirtual.kext")):
            obj = out.parent / ("candidate-" + unit + ".o")
            dest = out.parent / bundle / "Contents/MacOS" / bundle.replace(".kext", "")
            dest.parent.mkdir(parents=True, exist_ok=True)
            cmd = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                   "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                   str(obj), "-o", str(dest)]
            rc = execute(cmd, nm, out / (unit.lower() + "-kext-link.txt"))
            entry = {"command": cmd, "exit": rc,
                     "method": "NVRMFB link line with the Intel object and bundle; upstream publishes none"}
            if rc:
                entry["status"] = "LINK_FAILED"
                failures.append(unit + "-kext-link")
            else:
                data = dest.read_bytes()
                if len(data) < 16 or struct.unpack_from("<I", data)[0] not in (0xfeedface, 0xfeedfacf):
                    raise ValueError("unexpected " + unit + " Mach-O magic")
                execute(["xcrun", "nm", "-gU", str(dest)], nm, out / (unit.lower() + "-kext-defined.txt"))
                defined = (out / (unit.lower() + "-kext-defined.txt")).read_text(
                    encoding="utf-8", errors="replace").splitlines()
                entry.update({"artifact": str(dest), "sha256": hashlib.sha256(data).hexdigest(),
                              "size": len(data), "defined_symbols": len(defined),
                              "status": "KEXT-LINK_ONLY_NOT_LOADED"})
            intel_links[unit] = entry
        report["kext_link_intel"] = intel_links

        # Real complete KAPI C translation unit, with a reconstructed profile.
        # Literal Makefile lines only: conditional blocks are NOT evaluated.
        # Linux branch macros are an explicit candidate inference, not an upstream Darwin configuration.
        import re
        makefile = kms / "Makefile"
        include_dirs, make_defs = [], []
        for line in makefile.read_text(encoding='utf-8').splitlines():
            match = re.fullmatch(r"\s*CFLAGS\s*\+=\s*(-[ID])\s*(\S+)\s*", line)
            if match:
                flag = match.group(1) + match.group(2).replace("$(SRC_COMMON)", "../common")
                if "$" in flag:
                    raise ValueError("unresolved variable in modeset profile")
                if flag.startswith("-I"):
                    include_dirs.append("-I" + str((kms / flag[2:]).resolve()))
                else:
                    make_defs.append(flag)
        if not include_dirs or not make_defs:
            raise ValueError("empty modeset literal Makefile profile")
        kapi_path = Path("src/nvidia-modeset/kapi/src/nvkms-kapi.c")
        nv_candidate = out.parent / "ogkm-e4a5faa-kapi-null-free-r5-candidate"
        (nv_candidate / kapi_path).parent.mkdir(parents=True, exist_ok=False)
        shutil.copyfile(nv / kapi_path, nv_candidate / kapi_path)
        patch = assets / "ogkm-r3-kapi-null-free.patch"
        if execute(["git", "apply", "--check", "--whitespace=error-all", str(patch)], nv, out / "ogkm-full-check.txt"):
            raise ValueError("OGKM full original patch check failed")
        if execute(["git", "apply", "--whitespace=error-all", str(patch)], nv_candidate, out / "ogkm-overlay-apply.txt"):
            raise ValueError("OGKM sparse candidate patch apply failed")
        report["patches"].append({"name":patch.name,"sha256":hashlib.sha256(patch.read_bytes()).hexdigest()})
        report["kapi_profile"] = {"kind":"reconstructed candidate; literal Makefile -I/-D; conditional blocks not evaluated",
                                  "makefile_sha256":hashlib.sha256(makefile.read_bytes()).hexdigest(),
                                  "original_headers":str(nv), "platform_definitions":["NV_UNIX","NV_LINUX","NV_X86_64","NV_ARCH_BITS=64"]}
        cflags = ["-arch", "x86_64", "-mmacosx-version-min=15.5", "-isysroot", sdk,
                  "-mkernel", "-nostdinc", "-I"+str(khdr), "-DKERNEL", "-DKERNEL_PRIVATE",
                  "-std=gnu11", "-ffreestanding", "-fno-builtin", "-O2", "-Wall", "-Wextra", "-Werror",
                  "-Wno-unused-parameter", "-Wno-missing-field-initializers", "-Wno-sign-compare",
                  "-DNV_UNIX", "-DNV_LINUX", "-DNV_X86_64", "-DNV_ARCH_BITS=64",
                  *make_defs, *include_dirs, "-include", str(common / "sdk/nvidia/inc/cpuopsys.h")]
        for label, tree in (("original",nv),("candidate",nv_candidate)):
            source=tree/kapi_path
            stem=label+"-NVKAPI"
            obj=out.parent/(stem+".o")
            rc=execute(["xcrun","clang",*cflags,"-MMD","-MF",str(out/(stem+".d")),"-c",str(source),"-o",str(obj)],kms,out/(stem+"-compile.txt"))
            entry={"profile":label,"unit":"NVKAPI","source_sha256":hashlib.sha256(source.read_bytes()).hexdigest(),"compile_exit":rc}
            report["objects"].append(entry)
            if rc:
                failures.append(stem)
                continue
            data=obj.read_bytes()
            if len(data)<16 or struct.unpack_from("<II",data)!=(0xfeedfacf,0x01000007) or struct.unpack_from("<I",data,12)[0]!=1:
                raise ValueError("unexpected KAPI native object format")
            entry["object_sha256"]=hashlib.sha256(data).hexdigest()
            for suffix,tool in (("undefined",["xcrun","nm","-u"]),("defined",["xcrun","nm","-gU"])):
                status=execute([*tool,str(obj)],kms,out/(stem+"-"+suffix+".txt"))
                if status: failures.append(stem+"-"+suffix)
        if failures:
            report["failures"] = failures
            raise ValueError("one or more original/candidate native object checks failed")
        report["level"] = "SELECTED-DARWIN-OBJECTS-AND-CANDIDATE-LINK-FORMAT; COMPLETE-CLOSURE-NOT-ESTABLISHED"
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        (out / "native-report.json").write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(report["level"])


if __name__ == "__main__":
    main()


