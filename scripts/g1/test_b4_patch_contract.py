#!/usr/bin/env python3
"""B4 source patch contract regression tests; no macOS toolchain needed."""
import hashlib
import unittest
from pathlib import Path

from b2_native_probe import b4_patch_has_fixed_contract

HERE = Path(__file__).resolve().parent
PATCH = HERE / "patches" / "b4_nvrm_manual_go_msi_preflight.patch"
EXPECTED_SHA256 = "deed09545b1a3a54096ab36a7f4809a0b891fea5eef8d5ca1615bbd2bb9b5e44"


class B4PatchContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = PATCH.read_bytes()
        cls.text = cls.raw.decode("utf-8")

    def test_committed_patch_sha256_is_fixed(self):
        self.assertEqual(hashlib.sha256(self.raw).hexdigest(), EXPECTED_SHA256)

    def test_real_six_hunk_patch_accepted(self):
        self.assertTrue(b4_patch_has_fixed_contract(self.text))

    def test_second_file_header_not_mistaken_for_extra_target(self):
        self.assertEqual(self.text.count("\\n+++ "), 1)
        self.assertTrue(b4_patch_has_fixed_contract(self.text))

    def test_second_target_rejected(self):
        tampered = self.text + "\\n--- a/other.cpp\\n+++ b/other.cpp\\n"
        self.assertFalse(b4_patch_has_fixed_contract(tampered))

    def test_missing_hunk_rejected(self):
        tampered = self.text.replace("@@ -116,3 +116,5 @@", "@ -116,3 +116,5 @@", 1)
        self.assertFalse(b4_patch_has_fixed_contract(tampered))

    def test_extra_hunk_rejected(self):
        self.assertFalse(b4_patch_has_fixed_contract(
            self.text + "\\n@@ -1,1 +1,1 @@\\n"))

    def test_wrong_target_rejected(self):
        self.assertFalse(b4_patch_has_fixed_contract(
            self.text.replace("--- a/kexts/NVRM/NVRM.cpp",
                              "--- a/kexts/NVRM/other.cpp", 1)))


if __name__ == "__main__":
    unittest.main()
