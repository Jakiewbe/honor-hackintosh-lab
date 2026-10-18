#!/usr/bin/env python3
"""Inspect the five existing probe objects using their exact recorded flags.

Only preprocesses and lists symbols: never executes, links or changes an object.
Full macro dumps/include dependencies remain text diagnostics beside the report.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

SOURCES = ["src/nvidia/arch/nvalloc/unix/src/unix_intr.c",
           "src/nvidia/arch/nvalloc/unix/src/osapi.c",
           "src/nvidia/arch/nvalloc/unix/src/dynamic-power.c",
           "src/nvidia-modeset/src/nvkms.c",
           "src/nvidia-modeset/kapi/src/nvkms-kapi.c"]
PIN = "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb"


def derive_preprocess(argv, source):
    if argv[:2] != ["xcrun", "clang"] or argv.count("-c") != 1 or argv.count("-o") != 1:
        raise ValueError("unexpected compile command")
    ci, oi = argv.index("-c"), argv.index("-o")
    if Path(argv[ci + 1]).resolve() != source.resolve() or oi != len(argv) - 2:
        raise ValueError("source/output mismatch")
    base = [v for i, v in enumerate(argv) if i not in {ci, ci + 1, oi, oi + 1}]
    return base, Path(argv[oi + 1])


def run(argv, cwd, dest):
    err = dest.with_suffix(dest.suffix + ".stderr.txt")
    with dest.open("w", encoding="utf-8") as stdout, err.open("w", encoding="utf-8") as stderr:
        try:
            p = subprocess.run(argv, cwd=cwd, stdout=stdout, stderr=stderr, timeout=180)
            return p.returncode
        except subprocess.TimeoutExpired:
            stderr.write("TIMEOUT after 180 seconds\n")
            return 124


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--nv", type=Path, required=True)
    ap.add_argument("--logs", type=Path, required=True)
    ap.add_argument("--definitions", type=Path, required=True)
    args = ap.parse_args()
    nv, logs = args.nv.resolve(), args.logs.resolve()
    actual = subprocess.check_output(["git", "-C", str(nv), "rev-parse", "HEAD"], text=True).strip()
    if actual != PIN:
        raise ValueError("OGKM pin mismatch")
    names = set(json.loads(args.definitions.read_text(encoding="utf-8"))["found"])
    report = {"schema": "honor.g1.probe-object-inventory.v1", "ogkm_pin": PIN,
              "level": "OBJECT-SYMBOLS-AND-EXACT-PREPROCESSOR-CONFIG-NOT-ABI",
              "units": [], "failures": [], "kext_load": "NO-GO"}
    for rel in SOURCES:
        source = nv / rel
        stem = "probe-" + rel.replace("/", "_")
        entry = {"source": rel, "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest()}
        report["units"].append(entry)
        try:
            compile_text = (logs / (stem + ".txt")).read_text(encoding="utf-8")
            if not compile_text.startswith("ARGV=") or not re.search(r"^EXIT=0\s*$", compile_text, re.M):
                raise ValueError("compile did not report success")
            argv = json.loads(compile_text.splitlines()[0][5:])
            base, obj = derive_preprocess(argv, source)
            if obj.resolve().parent != logs.parent or obj.name != stem + ".o":
                raise ValueError("unexpected probe object location")
            raw = obj.read_bytes()
            if len(raw) < 32 or struct.unpack_from("<III", raw)[:2] != (0xfeedfacf, 0x01000007) or struct.unpack_from("<I", raw, 12)[0] != 1:
                raise ValueError("not an x86_64 Mach-O object")
            entry.update({"compile_argv": argv, "object_sha256": hashlib.sha256(raw).hexdigest(),
                          "object_bytes": len(raw), "filetype": "MH_OBJECT"})
            commands = {"macros": [*base, "-E", "-dM", str(source)],
                        "includes": [*base, "-M", str(source)],
                        "defined": ["xcrun", "nm", "-gU", str(obj)],
                        "undefined": ["xcrun", "nm", "-u", str(obj)]}
            entry["diagnostics"] = {}
            for label, cmd in commands.items():
                dest = logs / (stem + "-" + label + ".txt")
                rc = run(cmd, nv, dest)
                entry["diagnostics"][label] = {"command": cmd, "exit": rc, "file": dest.name,
                    "sha256": hashlib.sha256(dest.read_bytes()).hexdigest()}
                if rc:
                    report["failures"].append(rel + ":" + label)
            macro_text = (logs / (stem + "-macros.txt")).read_text(encoding="utf-8")
            macros = dict(re.findall(r"^#define[ \t]+(\w+)[ \t]*([^\n]*)$", macro_text, re.M))
            keys = ["__use_altstack__", "QA_BUILD", "NVCPU_X86_64", "NVRM", "NV_UNIX", "NV_LINUX", "__APPLE__", "NVOS_IS_UNIX", "NVOS_IS_LINUX", "NVOS_IS_MACOSX"]
            entry["selected_macros"] = {key: macros.get(key) for key in keys}
            defined_text = (logs / (stem + "-defined.txt")).read_text(encoding="utf-8")
            symbol_set = {m.group(1) for m in re.finditer(r"^\s*[0-9a-fA-F]+\s+[A-Za-z]\s+_(\w+)\s*$", defined_text, re.M)}
            entry["audited_symbols_defined_in_object"] = sorted(names & symbol_set)
            entry["status"] = "INSPECTED" if not any(f.startswith(rel + ":") for f in report["failures"]) else "DIAGNOSTIC_FAILED"
        except (ValueError, OSError) as error:
            entry.update({"status": "INCOMPLETE", "error": str(error)})
            report["failures"].append(rel)
    covered = {n for u in report["units"] for n in u.get("audited_symbols_defined_in_object", [])}
    report["audited_symbols_defined"] = sorted(covered)
    report["audited_symbols_not_seen_defined"] = sorted(names - covered)
    (logs / "g1-probe-inventory.json").write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8")
    print(json.dumps({"units": len(report["units"]), "failures": report["failures"],
                      "kext_load": "NO-GO", "report": "g1-probe-inventory.json"}))
    return 2 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
