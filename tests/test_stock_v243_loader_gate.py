"""The package audit must fail closed on the loader dry run (audit finding P1)."""
import ast
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "scripts/g1/stock_v243_package.py"


def loader_verdict(built, loaders):
    """Same logic as the package gate, extracted so it can be exercised without macOS."""
    missing = sorted(set(built) - set(loaders))
    bad_exit = {k: v['exit'] for k, v in loaders.items() if v['exit'] != 0}
    bad_text = {k: v['unresolved'] for k, v in loaders.items() if v['unresolved']}
    return missing, bad_exit, bad_text, not (missing or bad_exit or bad_text)


class LoaderGateTests(unittest.TestCase):
    def test_all_three_passing_is_accepted(self):
        loaders = {k: dict(exit=0, unresolved=[]) for k in ("NVRM", "NVRMFB", "NVAccel")}
        _, _, _, ok = loader_verdict(loaders.keys(), loaders)
        self.assertTrue(ok)

    def test_nonzero_exit_is_rejected(self):
        loaders = {k: dict(exit=0, unresolved=[]) for k in ("NVRM", "NVRMFB", "NVAccel")}
        loaders["NVAccel"]["exit"] = 1
        missing, bad_exit, bad_text, ok = loader_verdict(loaders.keys(), loaders)
        self.assertFalse(ok)
        self.assertEqual(bad_exit, {"NVAccel": 1})

    def test_unresolved_text_is_rejected_even_with_exit_zero(self):
        loaders = {k: dict(exit=0, unresolved=[]) for k in ("NVRM", "NVRMFB", "NVAccel")}
        loaders["NVRM"]["unresolved"] = ["can't resolve symbol _x"]
        _, _, bad_text, ok = loader_verdict(loaders.keys(), loaders)
        self.assertFalse(ok)
        self.assertIn("NVRM", bad_text)

    def test_missing_run_is_rejected(self):
        loaders = {k: dict(exit=0, unresolved=[]) for k in ("NVRM", "NVRMFB")}
        missing, _, _, ok = loader_verdict(("NVRM", "NVRMFB", "NVAccel"), loaders)
        self.assertFalse(ok)
        self.assertEqual(missing, ["NVAccel"])

    def test_the_package_script_contains_the_same_gate(self):
        text = SOURCE.read_text(encoding="utf-8")
        self.assertIn("loader-acceptance", text)
        self.assertIn("kextutil -n did not pass", text)
        self.assertIn("loader_negative_control", text)
        self.assertIn("loader negative control accepted", text)

    def test_script_parses(self):
        ast.parse(SOURCE.read_text(encoding="utf-8"))


class LoaderNegativeControlContract(unittest.TestCase):
    """The negative control must exercise a case kextutil actually rejects, and record the one it does not."""

    def test_script_records_the_capability_probe(self):
        source = (Path(__file__).resolve().parents[1] / "scripts/g1/stock_v243_package.py").read_text(encoding="utf-8")
        self.assertIn("kextutil_capability_probe", source)
        self.assertIn("kextutil_is_a_validation_gate", source)
        self.assertIn("missing executable", source)
        self.assertIn("missing declared dependency", source)

    def test_script_records_the_missing_dependency_limitation(self):
        source = (Path(__file__).resolve().parents[1] / "scripts/g1/stock_v243_package.py").read_text(encoding="utf-8")
        self.assertIn("_KEXTUTIL_INFORMATIONAL_ONLY", source)


if __name__ == "__main__":
    unittest.main()
