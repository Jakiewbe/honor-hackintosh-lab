#!/usr/bin/env python3
"""Parse existing HONOR read-only ACPI DMAR snapshot, never touch IOMMU registers."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

EXPECTED_SHA256 = "e84c886dfcc89640faf9c3386d5fbb4dc77483901c816eb38fdcb22a6c298f86"
VERDICT = "DMAR_TABLE_STRUCTURE_ONLY_RUNTIME_IOMMU_UNVERIFIED"


def scopes(data, start, end):
    found = []
    while start < end:
        if end - start < 6:
            raise ValueError("truncated DMAR device scope")
        typ, length, _, enum_id, bus = struct.unpack_from("<BBHBB", data, start)
        if length < 6 or (length - 6) % 2 or start + length > end:
            raise ValueError("invalid DMAR device scope length")
        path = [{"device": data[pos], "function": data[pos + 1]}
                for pos in range(start + 6, start + length, 2)]
        found.append({"type": typ, "enumeration_id": enum_id,
                      "start_bus": bus, "pci_path": path})
        start += length
    return found


def parse_dmar(data):
    if not isinstance(data, bytes) or len(data) < 48:
        raise ValueError("DMAR missing or shorter than mandatory ACPI header")
    if data[:4] != b"DMAR":
        raise ValueError("wrong ACPI table signature")
    total = struct.unpack_from("<I", data, 4)[0]
    if total != len(data) or total > 65536:
        raise ValueError("ACPI header length differs from captured table")
    if sum(data) % 256:
        raise ValueError("invalid ACPI checksum")
    records = []
    offset = 48
    while offset < total:
        if total - offset < 4:
            raise ValueError("incomplete DMAR remapping structure")
        kind, length = struct.unpack_from("<HH", data, offset)
        if length < 4 or offset + length > total:
            raise ValueError("invalid DMAR structure length")
        item = {"type": kind, "length": length}
        if kind == 0:  # DRHD
            if length < 16:
                raise ValueError("truncated DRHD")
            flags, _, segment, address = struct.unpack_from("<BBHQ", data, offset + 4)
            item.update({"kind": "DRHD", "include_all": bool(flags & 1),
                         "segment": segment, "register_base": hex(address),
                         "device_scopes": scopes(data, offset + 16, offset + length)})
        elif kind == 1:  # RMRR
            if length < 24:
                raise ValueError("truncated RMRR")
            _, segment, first, last = struct.unpack_from("<HHQQ", data, offset + 4)
            if first > last:
                raise ValueError("invalid RMRR reserved-memory range")
            item.update({"kind": "RMRR", "segment": segment,
                         "base": hex(first), "limit_inclusive": hex(last),
                         "device_scopes": scopes(data, offset + 24, offset + length)})
        elif kind == 2:  # ATSR
            if length < 8:
                raise ValueError("truncated ATSR")
            flags, _, segment = struct.unpack_from("<BBH", data, offset + 4)
            item.update({"kind": "ATSR", "all_ports": bool(flags & 1),
                         "segment": segment,
                         "device_scopes": scopes(data, offset + 8, offset + length)})
        else:
            item["kind"] = "UNINTERPRETED"
        records.append(item)
        offset += length
    return {
        "schema": "honor.g1.acpi-dmar.v1",
        "length": total,
        "oem_id": data[10:16].decode("ascii", errors="replace").strip(),
        "host_address_width_bits_reported": data[36] + 1,
        "interrupt_remapping_flag_reported": bool(data[37] & 1),
        "structures": records,
        "checksum_valid": True,
        "evidence_scope": "captured Windows firmware ACPI snapshot, NOT active OS DMA state",
        "gpu_10de_25a9_dma_mapping_proven": False,
        "device_iova_translation_proven": False,
        "gsp_dma_safety_proven": False,
        "device_activation": "NO_GO",
        "runtime_verdict": VERDICT,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    data = Path(args.input).read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest != EXPECTED_SHA256:
        raise ValueError("captured DMAR SHA256 mismatch; refuse unverified input")
    report = parse_dmar(data)
    report["provenance"] = {
        "source": args.input, "sha256": digest,
        "capture": "HONOR Windows P40 firmware read-only survey",
    }
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print("DMAR_EVIDENCE=" + str(out))
    print("DMAR_VERDICT=" + VERDICT)


if __name__ == "__main__":
    main()
