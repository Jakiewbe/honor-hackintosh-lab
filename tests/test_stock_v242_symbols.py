"""Unit tests for the symbol-level link-integration contract (no compiler, no macOS)."""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('stock_v242_native_sym',
                                              ROOT / 'scripts/g1/stock_v242_native.py')


def obj(undefined=(), defined=()):
    return dict(undefined=set(undefined), defined=set(defined))


class SymbolIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)

    def test_unchanged_sets_pass(self):
        original = obj({'U1', 'U2'}, {'D1'})
        candidate = obj({'U1', 'U2'}, {'D1'})
        rec = self.mod.classify_symbols(original, candidate, set(), set())
        self.assertTrue(rec['ok'])

    def test_approved_new_undefined_passes(self):
        rec = self.mod.classify_symbols(obj({'U1'}, {'D1'}), obj({'U1', 'NEW'}, {'D1'}), {'NEW'}, set())
        self.assertTrue(rec['ok'])
        self.assertEqual(rec['new_undefined'], ['NEW'])

    def test_unapproved_new_undefined_fails(self):
        rec = self.mod.classify_symbols(obj({'U1'}, {'D1'}), obj({'U1', 'NEW'}, {'D1'}), set(), set())
        self.assertFalse(rec['ok'])
        self.assertEqual(rec['new_undefined'], ['NEW'])

    def test_missing_approved_undefined_fails(self):
        # The reviewed dependency disappeared: the record no longer describes the build.
        rec = self.mod.classify_symbols(obj({'U1', 'NEW'}, {'D1'}), obj({'U1'}, {'D1'}), {'NEW'}, set())
        self.assertFalse(rec['ok'])
        self.assertEqual(rec['missing_undefined'], ['NEW'])

    def test_removed_defined_symbol_fails(self):
        rec = self.mod.classify_symbols(obj({'U1'}, {'D1', 'D2'}), obj({'U1'}, {'D1'}), set(), set())
        self.assertFalse(rec['ok'])
        self.assertEqual(rec['missing_defined'], ['D2'])

    def test_unlisted_new_defined_symbol_fails(self):
        rec = self.mod.classify_symbols(obj({'U1'}, {'D1'}), obj({'U1'}, {'D1', 'D3'}), set(), set())
        self.assertFalse(rec['ok'])
        self.assertEqual(rec['new_defined'], ['D3'])

    def test_listed_new_defined_symbol_passes(self):
        rec = self.mod.classify_symbols(obj({'U1'}, {'D1'}), obj({'U1'}, {'D1', 'D3'}), set(), {'D3'})
        self.assertTrue(rec['ok'])

    def test_delivered_lock_lists_the_two_observed_dependencies(self):
        _, _, integration = self.mod.validate_lock(
            self.mod.json.loads((ROOT / 'research/stock-v242-converged/source-lock.json')
                                .read_text(encoding='utf-8')),
            ROOT / 'research/stock-v242-converged')
        syms = {e['symbol'] for e in integration['approved_new_undefined']}
        self.assertEqual(syms, {'__ZNK9IOService10isInactiveEv', '_rm_disable_adapter'})
        self.assertIn('evidence', integration['approved_new_undefined'][0])


if __name__ == '__main__':
    unittest.main()
