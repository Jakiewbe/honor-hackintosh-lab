"""Unit wrapper for the PM state-machine checker's negative controls."""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_pm_state_machine",
                                              ROOT / "tools/check-pm-state-machine.py")


class PmStateMachineTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)

    def test_self_test_all_controls(self):
        self.assertEqual(self.mod.self_test(), 0)

    def test_one_sided_rollback_is_rejected(self):
        nvrm, os_text, _ = self.mod.SELF_CASES["one_sided_rollback"]
        rec = self.mod.evaluate(nvrm, os_text)
        self.assertEqual(rec["result"], "FAIL")
        self.assertTrue(any("B3" in c["check"] for c in rec["failures"]))

    def test_abort_after_commit_is_rejected(self):
        nvrm, os_text, _ = self.mod.SELF_CASES["abort_after_commit"]
        rec = self.mod.evaluate(nvrm, os_text)
        self.assertEqual(rec["result"], "FAIL")
        self.assertTrue(any("A4" in c["check"] for c in rec["failures"]))

    def test_fallthrough_into_standby_is_rejected(self):
        nvrm, os_text, _ = self.mod.SELF_CASES["fallthrough"]
        rec = self.mod.evaluate(nvrm, os_text)
        self.assertEqual(rec["result"], "FAIL")
        self.assertTrue(any("B4" in c["check"] for c in rec["failures"]))


if __name__ == "__main__":
    unittest.main()
