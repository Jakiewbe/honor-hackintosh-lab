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

PINS = {"nm": "ac55984c473e746c2a8ebea7ba0913461aa7c393", "nv": "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb"}


def execute(argv, cwd, log):
    with log.open("w", encoding="utf-8") as stream:
        stream.write("ARGV=" + json.dumps(argv) + "\n")
        stream.flush()
        result = subprocess.run(argv, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT)
        stream.write("\nEXIT=" + str(result.returncode) + "\n")
    return result.returncode


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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--nm", required=True)
    parser.add_argument("--nv", required=True)
    parser.add_argument("--assets", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    nm, nv, assets, out = [Path(getattr(args, key)).resolve() for key in ("nm", "nv", "assets", "out")]
    out.mkdir(parents=True, exist_ok=True)
    report = {"level": "DARWIN-COMPILE_CANDIDATE_NOT_YET_PASSED", "pins": PINS, "objects": [],
              "kext_link": "BLOCKED_NOT_ATTEMPTED_PRIVATE_FAMILY_ABI_AND_TARGET_KERNEL_EXPORTS_UNVERIFIED",
              "kext_load": "NO-GO", "gpu_runtime": "NOT_RUN", "display_runtime": "NOT_RUN"}
    failures = []
    try:
        for key, tree in (("nm", nm), ("nv", nv)):
            actual = subprocess.check_output(["git", "-C", str(tree), "rev-parse", "HEAD"], text=True).strip()
            if actual != PINS[key]:
                raise ValueError(f"{key}: fixed commit mismatch")
        candidate = out.parent / "nullmoth-v2.3.3-gpu-safety-r2-candidate"
        shutil.copytree(nm, candidate, ignore=shutil.ignore_patterns(".git"))
        report["patches"] = []
        for number, name in enumerate(("gpu-safety-r1.patch", "gpu-safety-r2-kms-open.patch"), 1):
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
        common_flags = ["-arch", "x86_64", "-mmacosx-version-min=15.5", "-isysroot", sdk, "-fapple-kext", "-mkernel", "-nostdinc",
                        "-I" + str(khdr), "-DKERNEL", "-DKERNEL_PRIVATE", "-DDRIVER_PRIVATE", "-DAPPLE", "-DNeXT",
                        "-std=c++17", "-fno-rtti", "-fno-exceptions", "-fno-builtin", "-fno-common", "-O2",
                        "-Wall", "-Wextra", "-Werror", "-Wno-unused-parameter", "-Wno-inconsistent-missing-override", "-Wno-unused-function"]
        # Same selected compiler/profile for original and candidate; no use of published binary objects.
        for label, tree in (("original", nm), ("candidate", candidate)):
            for unit in ("NMIntelFB", "NMIntelFBVirtual", "NVAccel", "NVKMSOS"):
                if unit in ("NVAccel", "NVKMSOS"):
                    source = tree / ("kexts/NVRM/accel/nvrm-accel.cpp" if unit == "NVAccel" else "kexts/NVRM/os-nvkms-xnu.cpp")
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
        if failures:
            report["failures"] = failures
            raise ValueError("one or more original/candidate native object checks failed")
        report["level"] = "DARWIN-COMPILE_ONLY (original and candidate); NOT KEXT-LINK or GPU-RUNTIME"
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        (out / "native-report.json").write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(report["level"])


if __name__ == "__main__":
    main()
