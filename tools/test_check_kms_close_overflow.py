"""Unit wrapper for the overflow-path structural guard."""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_kms_close_overflow",
                                              ROOT / "tools/check-kms-close-overflow.py")


class OverflowGuardTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)

    def test_self_test_all_controls(self):
        self.assertEqual(self.mod.self_test(), 0)

    def test_log_only_overflow_is_rejected(self):
        rec = self.mod.evaluate(self.mod.BAD_LOG_ONLY)
        self.assertEqual(rec["result"], "FAIL")
        self.assertTrue(any("R1" in c["check"] for c in rec["failures"]))

    def test_missing_companion_drain_is_rejected(self):
        rec = self.mod.evaluate(self.mod.BAD_NO_COMPANION)
        self.assertEqual(rec["result"], "FAIL")
        self.assertTrue(any("R3" in c["check"] for c in rec["failures"]))

    def test_companion_in_another_function_is_rejected(self):
        # Presence anywhere in the file is not enough: the queue drain and the overflow drain must meet.
        rec = self.mod.evaluate(self.mod.BAD_SPLIT)
        self.assertEqual(rec["result"], "FAIL")
        self.assertTrue(any("R3" in c["check"] for c in rec["failures"]))

    def test_good_shape_is_accepted(self):
        rec = self.mod.evaluate(self.mod.GOOD)
        self.assertEqual(rec["result"], "PASS", [c for c in rec["failures"]])


if __name__ == "__main__":
    unittest.main()
