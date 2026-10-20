"""Unit tests for the diagnostics policy and the compiler negative control.

These run on any host: they do not compile a driver and never need macOS. They exist to break the new logic
(accepted-exception matching, stage reporting, fail-closed control) rather than to re-assert a happy path.
"""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('stock_v242_native',
                                              ROOT / 'scripts/g1/stock_v242_native.py')

EXC = dict(path='kexts/NVRM/NVRM.cpp', file='NVRM.cpp', line=1579, column=13,
           category='-Wdeprecated-declarations', message_regex='IOPCIDevice.*deprecated', count=1)


def diag(file='NVRM.cpp', line=1579, column=13, message="'IOPCIDevice' is deprecated: use PCIDriverKit",
         category='-Wdeprecated-declarations'):
    return dict(file=file, line=line, column=column, message=message, category=category)


class DiagnosticsPolicyTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)

    def test_parse_keeps_position_and_category(self):
        text = ("/tmp/nm/kexts/NVRM/NVRM.cpp:1579:13: warning: 'IOPCIDevice' is deprecated: x "
                "[-Wdeprecated-declarations]\n"
                "/tmp/nm/kexts/NVRM/NVRM.cpp:1600:5: warning: unused variable 'v' [-Wunused-variable]\n"
                "not a diagnostic line\n")
        found = self.mod.parse_diagnostics(text)
        self.assertEqual(len(found), 2)
        self.assertEqual((found[0]['file'], found[0]['line'], found[0]['column']), ('NVRM.cpp', 1579, 13))
        self.assertEqual(found[0]['category'], '-Wdeprecated-declarations')
        self.assertEqual(found[1]['category'], '-Wunused-variable')

    def test_identical_warnings_are_not_new(self):
        rec = self.mod.classify_diagnostics([diag()], [diag()], [])
        self.assertTrue(rec['ok'])
        self.assertEqual(rec['accepted'], [])

    def test_reviewed_exception_is_accepted(self):
        rec = self.mod.classify_diagnostics([], [diag()], [EXC])
        self.assertTrue(rec['ok'])
        self.assertEqual(len(rec['accepted']), 1)

    def test_fourth_warning_is_rejected(self):
        extra = diag(line=1601, message="'IOPCIDevice' is deprecated: x")
        rec = self.mod.classify_diagnostics([], [diag(), extra], [EXC])
        self.assertFalse(rec['ok'])
        self.assertEqual(len(rec['unexpected']), 1)

    def test_wrong_line_is_rejected(self):
        rec = self.mod.classify_diagnostics([], [diag(line=1578)], [EXC])
        self.assertFalse(rec['ok'])
        self.assertEqual(len(rec['unexpected']), 1)
        self.assertEqual(rec['missing'][0]['seen'], 0)

    def test_wrong_column_is_rejected(self):
        rec = self.mod.classify_diagnostics([], [diag(column=12)], [EXC])
        self.assertFalse(rec['ok'])

    def test_wrong_category_is_rejected(self):
        rec = self.mod.classify_diagnostics([], [diag(category='-Wdeprecated-implementations')], [EXC])
        self.assertFalse(rec['ok'])

    def test_message_pattern_mismatch_is_rejected(self):
        rec = self.mod.classify_diagnostics([], [diag(message="'IOService' is deprecated: y")], [EXC])
        self.assertFalse(rec['ok'])

    def test_duplicate_at_same_position_exceeds_count(self):
        rec = self.mod.classify_diagnostics([], [diag(), diag()], [EXC])
        self.assertFalse(rec['ok'])
        self.assertEqual(len(rec['unexpected']), 1)

    def test_missing_exception_is_rejected(self):
        rec = self.mod.classify_diagnostics([], [], [EXC])
        self.assertFalse(rec['ok'])
        self.assertEqual(rec['missing'][0]['seen'], 0)

    def test_exception_wins_over_the_pre_existing_pool(self):
        # The same text also exists in the original tree. Position-bound review must still consume the
        # candidate warning, otherwise an unrelated old warning would silently mask the reviewed one.
        rec = self.mod.classify_diagnostics([diag()], [diag()], [EXC])
        self.assertTrue(rec['ok'])
        self.assertEqual(len(rec['accepted']), 1)

    def test_unrelated_old_warning_still_passes_without_exception(self):
        old = diag(line=900, message="'IOService' is deprecated: z")
        rec = self.mod.classify_diagnostics([old], [old], [EXC])
        self.assertFalse(rec['ok'])   # the reviewed exception is now missing
        self.assertEqual(rec['missing'][0]['seen'], 0)


class NegativeControlTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)
        self.tmp = Path(tempfile.mkdtemp())
        self.objects = self.tmp / 'objects'
        self.objects.mkdir()

    def test_accepting_runner_is_rejected(self):
        def runner(argv, cwd, log):
            Path(log).write_text('EXIT=0\n', encoding='utf-8')
            return 0
        with self.assertRaises(ValueError):
            self.mod.run_negative_control(self.objects, self.tmp, runner)

    def test_runner_that_leaves_the_object_is_rejected(self):
        def runner(argv, cwd, log):
            Path(log).write_text('EXIT=1\n', encoding='utf-8')
            return 1          # does not delete invalid.o
        with self.assertRaises(ValueError):
            self.mod.run_negative_control(self.objects, self.tmp, runner)

    def test_fail_closed_runner_is_accepted(self):
        def runner(argv, cwd, log):
            Path(log).write_text('EXIT=1\n', encoding='utf-8')
            (self.objects / 'invalid.o').unlink(missing_ok=True)
            return 1
        record = self.mod.run_negative_control(self.objects, self.tmp, runner)
        self.assertTrue(record['executed'])
        self.assertTrue(record['stale_object_removed'])
        self.assertFalse(record['object_exists'])


class LockValidationTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)
        self.lock = json.loads((ROOT / 'research/stock-v242-converged/source-lock.json')
                               .read_text(encoding='utf-8'))
        self.assets = ROOT / 'research/stock-v242-converged'

    def test_delivered_lock_is_accepted(self):
        patch, exceptions, integration = self.mod.validate_lock(dict(self.lock), self.assets)
        self.assertTrue(patch.is_file())
        self.assertEqual(len(exceptions), 3)
        self.assertIn('approved_new_undefined', integration)

    def test_exception_outside_the_two_files_is_rejected(self):
        bad = dict(self.lock)
        bad['diagnostics_exceptions'] = [dict(EXC, path='kexts/NVRM/osapi.cpp', file='osapi.cpp')]
        with self.assertRaises(ValueError):
            self.mod.validate_lock(bad, self.assets)

    def test_exception_missing_field_is_rejected(self):
        entry = dict(EXC)
        entry.pop('message_regex')
        bad = dict(self.lock)
        bad['diagnostics_exceptions'] = [entry]
        with self.assertRaises(ValueError):
            self.mod.validate_lock(bad, self.assets)

    def test_zero_count_is_rejected(self):
        bad = dict(self.lock)
        bad['diagnostics_exceptions'] = [dict(EXC, count=0)]
        with self.assertRaises(ValueError):
            self.mod.validate_lock(bad, self.assets)


if __name__ == '__main__':
    unittest.main()
