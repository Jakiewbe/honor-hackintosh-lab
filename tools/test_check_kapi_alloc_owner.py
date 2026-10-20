"""Unit wrapper for the allocation-owner checker: it must audit AllocateDevice, not the first `failed:`."""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_kapi_alloc_owner",
                                              ROOT / "tools/check-kapi-alloc-owner.py")


class AllocOwnerTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)

    def test_self_test_all_controls(self):
        self.assertEqual(self.mod.self_test(), 0)

    def test_decoy_failed_label_does_not_satisfy_the_rules(self):
        # A quarantine inside RmAllocateDevice's failed block must not make AllocateDevice look fixed.
        text = """
static void *RmAllocateDevice(void) {
failed:
    if (!nvKmsKapiTryFreeDevice(device)) { KmsQuarantineAdd(device); }
    return NULL;
}
static struct NvKmsKapiDevice *AllocateDevice(const void *params) {
failed:
    FreeDevice(device);
    return NULL;
}
"""
        rec = self.mod.evaluate(text, "nvKmsKapiReapQuarantine();")
        self.assertEqual(rec["result"], "FAIL")
        self.assertTrue(any("E1" in c["check"] for c in rec["failures"]))

    def test_missing_allocate_device_fails_closed(self):
        rec = self.mod.evaluate("static void *RmAllocateDevice(void) { failed: return 0; }", "x")
        self.assertEqual(rec["result"], "FAIL")


if __name__ == "__main__":
    unittest.main()
