#!/usr/bin/env python3
"""Darwin candidate equivalent of OGKM's GNU binary-data object packaging.

Preserves the real five shader inputs, xz -ce -C none compression and binary
start/end/size symbols. Produces genuine read-only Mach-O data through clang's
assembler, then verifies every embedded byte and symbol before publishing .o.
This is a reconstruction adapter, not the original NullMoth build harness.
"""
import argparse
import hashlib
import json
import lzma
import os
import struct
import subprocess
from pathlib import Path

from macho_obj import MachO

PIN = "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb"
SHADERS = ("turing", "ampere", "hopper", "blackwell", "gb20x")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def symbol_base(arch):
    if arch not in SHADERS:
        raise ValueError("shader is not in the pinned Makefile")
    # C declares _binary_<arch>_shaders_xz_start/end; Mach-O adds one underscore.
    return f"__binary_{arch}_shaders_xz"


def assembly(arch, payload):
    name = symbol_base(arch)
    path = str(Path(payload).resolve())
    if any(c in path for c in ('"', "\n", "\r", "\\")):
        raise ValueError("unsupported assembler input path")
    return (f".section __TEXT,__const\n.p2align 0\n"
            f".globl {name}_start\n.globl {name}_end\n.globl {name}_size\n"
            f"{name}_start:\n.incbin \"{path}\"\n{name}_end:\n"
            f".set {name}_size, {name}_end - {name}_start\n")


def verify_object(path, arch, compressed):
    obj = MachO(path)
    if obj.filetype != 1 or struct.unpack_from("<I", obj.data, 4)[0] != 0x01000007:
        raise ValueError("not an x86_64 MH_OBJECT")
    index = obj.section_index("__TEXT,__const")
    if index is None:
        raise ValueError("missing read-only payload section")
    section = obj.sections[index - 1]
    if section["nreloc"]:
        raise ValueError("unexpected data relocations")
    symbols = {}
    for name, ntype, sect, value in obj.symbols:
        symbols.setdefault(name, []).append((ntype, sect, value))
    base = symbol_base(arch)
    expected = {base + "_start": (0x0f, index, section["addr"]),
                base + "_end": (0x0f, index, section["addr"] + len(compressed)),
                base + "_size": (0x03, 0, len(compressed))}
    for name, value in expected.items():
        if symbols.get(name) != [value]:
            raise ValueError(f"wrong/missing/nonunique payload symbol: {name}")
    data = obj.data[section["offset"]:section["offset"] + section["size"]]
    if section["size"] != len(compressed) or data != compressed:
        raise ValueError("embedded shader bytes differ from compressed input")
    return {"compressed_sha256": digest(data), "compressed_size": len(data),
            "object_sha256": digest(obj.data), "symbols_verified": sorted(expected)}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--ogkm", required=True)
    parser.add_argument("--out-report", required=True)
    parser.add_argument("--cc", default="clang")
    args = parser.parse_args()
    root = Path(args.ogkm).resolve()
    report = {"label": "REBUILD_CANDIDATE_SHADER_PACKAGING", "pin": PIN,
              "status": "incomplete", "shaders": []}
    try:
        actual = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
        if actual != PIN:
            raise ValueError("OGKM commit differs from fixed input")
        out = root / "src/nvidia-modeset/_out/Darwin_x86_64"
        out.mkdir(parents=True, exist_ok=True)
        for arch in SHADERS:
            relative = f"src/nvidia-modeset/src/shaders/g_{arch}_shaders"
            source = root / relative
            raw = source.read_bytes()
            expected_blob = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD:" + relative], text=True).strip()
            actual_blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
            if actual_blob != expected_blob:
                raise ValueError(f"shader input differs from fixed Git blob: {arch}")
            compressed = subprocess.run(["xz", "-ce", "-C", "none"], input=raw, capture_output=True, check=True).stdout
            if lzma.decompress(compressed) != raw:
                raise ValueError("xz round-trip differs from original shader bytes")
            payload = out / f"{arch}_shaders.xz"
            payload.write_bytes(compressed)
            asm = out / f"{arch}_shaders.xz.candidate.s"
            asm.write_text(assembly(arch, payload), encoding="utf-8")
            obj = out / f"{arch}_shaders.xz.o"
            temporary = out / f"{arch}_shaders.xz.o.tmp"
            # No generated C arrays, stand-in code or empty implementations: assembler embeds the real bytes.
            subprocess.run([args.cc, "-arch", "x86_64", "-c", "-x", "assembler", str(asm), "-o", str(temporary)], check=True)
            checked = verify_object(temporary, arch, compressed)
            os.replace(temporary, obj)
            report["shaders"].append({"arch": arch, "source": relative, "source_git_blob": actual_blob,
                                      "source_sha256": digest(raw), "source_size": len(raw), **checked})
            print(f"SHADER_DATA_VERIFIED {arch} source_bytes={len(raw)} compressed_bytes={len(compressed)}")
        report["status"] = "complete"
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        Path(args.out_report).write_text(json.dumps(report, indent=1), encoding="utf-8")
    print("REBUILD_CANDIDATE_SHADER_PACKAGING_COMPLETE (data objects only; no execution)")


if __name__ == "__main__":
    main()
