#!/usr/bin/env python3
"""No-hardware ABI parser and fail-closed decision tests."""
import struct
import tempfile
import unittest
from pathlib import Path
from abi_contract import EXPORT_SCHEMA, NO_GO, collect, compare, write_json


def mock_macho(path, imported):
    labels = imported + ["_defined"]
    stringtable = bytearray(b"\0")
    entries = []
    for i, label in enumerate(labels):
        off = len(stringtable)
        stringtable.extend(label.encode("ascii") + b"\0")
        entries.append(struct.pack("<IBBhQ", off, 1 if i < len(imported) else 15,
                                   0 if i < len(imported) else 1, 0, 0))
    header = struct.pack("<IiiIIIII", 0xfeedfacf, 0x01000007, 3, 11, 1, 24, 0, 0)
    str_offset = 56 + len(entries) * 16
    symtab = struct.pack("<IIIIII", 2, 24, 56, len(entries), str_offset, len(stringtable))
    Path(path).write_bytes(header + symtab + b"".join(entries) + stringtable)


class ABIContractTests(unittest.TestCase):
    def setUp(self):
        root = tempfile.TemporaryDirectory()
        self.addCleanup(root.cleanup)
        self.root = Path(root.name)
        self.bin = self.root / "test.macho"
        mock_macho(self.bin, ["_foo", "_bar"])

    def test_collect_name_sorting_and_no_go(self):
        r = collect(self.bin, 2)
        self.assertEqual(r["imports"], ["_bar", "_foo"])
        self.assertEqual(len(r["candidate_sha256"]), 64)
        self.assertEqual(r["runtime_abi_status"], NO_GO)

    def test_reject_wrong_count(self):
        with self.assertRaisesRegex(ValueError, "baseline"):
            collect(self.bin, 462)

    def test_reject_wrong_macho_type(self):
        b = bytearray(self.bin.read_bytes())
        struct.pack_into("<I", b, 12, 1)
        self.bin.write_bytes(b)
        with self.assertRaisesRegex(ValueError, "MH_KEXT_BUNDLE"):
            collect(self.bin)

    def check(self, symbols):
        a, b = self.root / "imports.json", self.root / "exports.json"
        write_json(a, collect(self.bin))
        write_json(b, {"schema": EXPORT_SCHEMA, "target_os_build": "24G123",
                       "origin": "untrusted test fixture", "exports": symbols})
        return compare(a, b)

    def test_missing_names(self):
        r = self.check(["_bar"])
        self.assertEqual(r["missing_symbols"], ["_foo"])
        self.assertEqual(r["runtime_abi_status"], NO_GO)

    def test_all_names_match_still_no_go(self):
        r = self.check(["_bar", "_foo"])
        self.assertEqual(r["missing_count"], 0)
        self.assertEqual(r["export_inventory_authenticity"], "UNVERIFIED")
        self.assertEqual(r["runtime_abi_status"], NO_GO)

    def test_unsorted_and_duplicate_export_names(self):
        for names in (["_foo", "_bar"], ["_foo", "_foo"]):
            with self.subTest(names=names), self.assertRaisesRegex(ValueError, "sorted"):
                self.check(names)

    def test_unknown_export_origin(self):
        a, b = self.root / "imports.json", self.root / "exports.json"
        write_json(a, collect(self.bin))
        write_json(b, {"schema": EXPORT_SCHEMA, "target_os_build": "24G123",
                       "exports": ["_bar", "_foo"]})
        with self.assertRaisesRegex(ValueError, "origin"):
            compare(a, b)


if __name__ == "__main__":
    unittest.main()
