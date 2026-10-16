#!/usr/bin/env python3
"""Synthetic ACPI DMAR structure/validation tests. No PCI or IOMMU access."""
import struct
import unittest
from dmar_evidence import parse_dmar


def table(*parts):
    buf = bytearray(48)
    buf[:4] = b"DMAR"
    buf[10:16] = b"HONOR "
    buf[36] = 38
    buf[37] = 1
    buf.extend(b"".join(parts))
    struct.pack_into("<I", buf, 4, len(buf))
    buf[9] = (-sum(buf)) % 256
    return bytes(buf)


class DmarEvidenceTests(unittest.TestCase):
    def test_drhd_include_all(self):
        drhd = struct.pack("<HHBBHQ", 0, 16, 1, 0, 0, 0xfed90000)
        report = parse_dmar(table(drhd))
        self.assertTrue(report["structures"][0]["include_all"])
        self.assertEqual(report["structures"][0]["register_base"], "0xfed90000")
        self.assertFalse(report["device_iova_translation_proven"])

    def test_rmrr_device_scope(self):
        scope = struct.pack("<BBHBB", 1, 8, 0, 0, 0) + bytes([2, 0])
        region = struct.pack("<HHHHQQ", 1, 24 + len(scope), 0, 0,
                             0x1000, 0x1fff) + scope
        report = parse_dmar(table(region))
        self.assertEqual(report["structures"][0]["device_scopes"][0]["pci_path"],
                         [{"device": 2, "function": 0}])
        self.assertEqual(report["device_activation"], "NO_GO")

    def test_bad_checksum(self):
        blob = bytearray(table())
        blob[10] ^= 1
        with self.assertRaisesRegex(ValueError, "checksum"):
            parse_dmar(bytes(blob))

    def test_wrong_declared_length(self):
        blob = bytearray(table())
        struct.pack_into("<I", blob, 4, 60)
        with self.assertRaisesRegex(ValueError, "length"):
            parse_dmar(bytes(blob))

    def test_zero_structure_length(self):
        with self.assertRaisesRegex(ValueError, "structure length"):
            parse_dmar(table(struct.pack("<HH", 0, 0)))

    def test_broken_scope_length(self):
        scope = struct.pack("<BBHBB", 1, 7, 0, 0, 0) + b"\x01"
        drhd = struct.pack("<HHBBHQ", 0, 16 + len(scope), 0, 0,
                           0, 0xfed90000) + scope
        with self.assertRaisesRegex(ValueError, "scope length"):
            parse_dmar(table(drhd))


if __name__ == "__main__":
    unittest.main()
