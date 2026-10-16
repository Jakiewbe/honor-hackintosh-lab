#!/usr/bin/env python3
"""Read-only KEXT import inventory. NAME matches NEVER authorize driver loading."""
import argparse
import hashlib
import json
from pathlib import Path
from macho_obj import MachO

IMPORT_SCHEMA = "honor.g1.abi-imports.v1"
EXPORT_SCHEMA = "honor.g1.target-exports.v1"
NO_GO = "BLOCKED_RUNTIME_ABI_UNVERIFIED"


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def names_from(record, key):
    values = record.get(key)
    if not isinstance(values, list) or not values or any(
            not isinstance(x, str) or not x or "\n" in x or "\0" in x for x in values
    ) or values != sorted(set(values)):
        raise ValueError(key + " must contain nonempty unique sorted strings")
    return values


def write_json(path, record):
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(record, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def collect(candidate, expected_count=None):
    macho = MachO(candidate)
    if (macho.filetype != 11 or
            int.from_bytes(macho.data[4:8], "little") != 0x01000007):
        raise ValueError("candidate must be thin x86_64 MH_KEXT_BUNDLE")
    names = sorted(macho.undefined())
    if not names:
        raise ValueError("no external imports")
    if expected_count is not None and expected_count != len(names):
        raise ValueError("import count changed from frozen native-link baseline")
    return {
        "schema": IMPORT_SCHEMA,
        "candidate_sha256": sha256(candidate),
        "candidate_bytes": Path(candidate).stat().st_size,
        "arch": "x86_64",
        "macho_type": "MH_KEXT_BUNDLE",
        "import_count": len(names),
        "imports": names,
        "target_export_status": "NOT_PROVIDED",
        "runtime_abi_status": NO_GO,
        "device_activation": "NO_GO",
    }


def compare(imports_path, exports_path):
    imports = json.loads(Path(imports_path).read_text(encoding="utf-8"))
    exports = json.loads(Path(exports_path).read_text(encoding="utf-8"))
    if imports.get("schema") != IMPORT_SCHEMA or exports.get("schema") != EXPORT_SCHEMA:
        raise ValueError("manifest schema mismatch")
    imported = names_from(imports, "imports")
    provided = names_from(exports, "exports")
    if imports.get("import_count") != len(imported) or not imports.get("candidate_sha256"):
        raise ValueError("invalid import count or candidate fingerprint")
    for field in ("target_os_build", "origin"):
        if not isinstance(exports.get(field), str) or not exports[field].strip():
            raise ValueError("export inventory missing " + field)
    missing = sorted(set(imported) - set(provided))
    return {
        "schema": "honor.g1.abi-name-comparison.v1",
        "candidate_sha256": imports["candidate_sha256"],
        "target_os_build_claimed": exports["target_os_build"],
        "export_origin_claimed": exports["origin"],
        "target_exports_file_sha256": sha256(exports_path),
        "import_count": len(imported),
        "export_count": len(provided),
        "missing_symbols": missing,
        "missing_count": len(missing),
        "name_match_status": ("NO_MISSING_NAMES_IN_SUPPLIED_INVENTORY" if not missing
                              else "MISSING_NAMES_IN_SUPPLIED_INVENTORY"),
        "export_inventory_authenticity": "UNVERIFIED",
        "symbol_version_and_abi": "UNVERIFIED",
        "runtime_abi_status": NO_GO,
        "device_activation": "NO_GO",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    a = sub.add_parser("collect")
    a.add_argument("--candidate", required=True)
    a.add_argument("--out", required=True)
    a.add_argument("--expected-count", type=int)
    b = sub.add_parser("compare")
    b.add_argument("--imports", required=True)
    b.add_argument("--exports", required=True)
    b.add_argument("--out", required=True)
    opts = parser.parse_args()
    report = (collect(opts.candidate, opts.expected_count)
              if opts.action == "collect" else compare(opts.imports, opts.exports))
    write_json(opts.out, report)
    print("G1_ABI_REPORT=" + str(Path(opts.out).resolve()))
    print("G1_ABI_RUNTIME_VERDICT=" + NO_GO)
    return 0  # Evidence extracted; NEVER a kernel/driver acceptance result.


if __name__ == "__main__":
    raise SystemExit(main())
