import hashlib
from pathlib import Path
import tempfile
import unittest

from g1_target_providers import load_imports, match_records, observe_allowlist, observe_binary, parse_allowlist, parse_globals


class TargetProviderTests(unittest.TestCase):
    def test_exact_spelling_and_data_distinct(self):
        got = parse_globals('00000001 T ___bzero\n00000002 S __ZTV9IOService\nffffff8000c1b204 D .constructors_used\n')
        self.assertEqual(got, {'___bzero': 'T', '__ZTV9IOService': 'S', '.constructors_used': 'D'})
        self.assertNotIn('_bzero', got)

    def test_reject_undefined_indirect_diagnostic_partial_and_duplicate(self):
        for bad in [' U _x', '0000 U _x', '0000 I _x (indirect for _y)', 'nm: failure',
                    '0000 T _x\nnot a symbol', '0000 T _x\n0001 T _x']:
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse_globals(bad)

    def test_frozen_real_472_inventory_and_byte_mutation(self):
        path = Path(__file__).resolve().parents[1]/'research/gpu-safety-r5/input-binding-evidence/full-source/full-nvrm-undefined.txt'
        self.assertEqual(len(load_imports(path)), 472)
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)/'imports.txt'
            p.write_bytes(path.read_bytes()+b'\n')
            with self.assertRaisesRegex(ValueError, 'hash mismatch'):
                load_imports(p)

    def test_observation_never_establishes_target_export_or_abi(self):
        providers = [{'id': 'kernel', 'level': 'GLOBAL_ONLY', 'observation': 'PARSED',
                      'matches': {'___bzero': 'T'}},
                     {'id': 'bad', 'level': 'GLOBAL_ONLY', 'observation': 'NM_FAILED',
                      'matches': {'_absent': 'T'}}]
        got = match_records(['___bzero', '_absent'], providers)
        self.assertEqual(got[0]['source_spelling'], '__bzero')
        self.assertEqual(got[0]['status'], 'GLOBAL_DEFINITION_OBSERVED_ONLY')
        self.assertEqual(got[1]['status'], 'NOT_OBSERVED_IN_SCANNED_INPUTS')
        self.assertTrue(all(r['abi'] == r['target_kpi_export'] == 'NOT_VERIFIED' for r in got))

    def test_failed_nm_and_provider_mutation_cannot_reuse_symbols(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            p = root/'fixture-not-a-driver'
            p.write_bytes(b'fixture')
            def failed(argv):
                self.assertEqual(argv[:5], ['xcrun', 'nm', '-arch', 'x86_64', '-gU'])
                return 1, b'0000 T _x\n', b'failure'
            row = observe_binary(p, 'failed', 'GLOBAL_ONLY', ['_x'], root, failed)
            self.assertEqual(row['observation'], 'NM_FAILED')
            self.assertEqual(row['matches'], {})
            def mutate(argv):
                p.write_bytes(b'changed')
                return 0, b'0000 T _x\n', b''
            row = observe_binary(p, 'changed', 'GLOBAL_ONLY', ['_x'], root, mutate)
            self.assertEqual(row['observation'], 'OBSERVATION_FAILED')
            self.assertEqual(row['matches'], {})

    def test_empty_missing_malformed_and_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            p = root/'fixture-not-a-driver'
            self.assertEqual(observe_binary(p, 'missing', 'GLOBAL_ONLY', ['_x'], root)['observation'], 'NOT_PRESENT')
            p.write_bytes(b'fixture')
            for ident, stdout, state in [('empty', b'', 'NO_GLOBAL_SYMBOLS'),
                ('malformed', b'0000 T _x\nerror', 'OBSERVATION_FAILED'),
                ('success', b'0000 T _x\n0001 T _xy\n', 'PARSED')]:
                row = observe_binary(p, ident, 'GLOBAL_ONLY', ['_x'], root, lambda argv: (0, stdout, b''))
                self.assertEqual(row['observation'], state)
                self.assertEqual(row['matches'], {'_x': 'T'} if state == 'PARSED' else {})
                self.assertEqual(row['sha256'], hashlib.sha256(b'fixture').hexdigest())

    def test_family_allowlist_is_not_implementation_or_target_acceptance(self):
        self.assertEqual(parse_allowlist('# comment\n__ZN3Foo\n_x # note\n'), {'__ZN3Foo', '_x'})
        for malformed in ['_x*', '_x _y', '_x:_y']:
            with self.subTest(malformed=malformed), self.assertRaises(ValueError):
                parse_allowlist(malformed)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            p = root/'family.exports'
            p.write_text('_x\n_xy\n')
            observed = observe_allowlist(p, 'family', ['_x'], root)
            records = match_records(['_x', '_xy'], [observed])
            self.assertEqual(records[0]['status'], 'FAMILY_EXPORT_ALLOWLIST_ONLY')
            self.assertEqual(records[0]['target_kpi_export'], 'NOT_VERIFIED')
            self.assertEqual(records[1]['status'], 'NOT_OBSERVED_IN_SCANNED_INPUTS')
            p.write_text('_x\n_bad*\n')
            observed = observe_allowlist(p, 'bad-list', ['_x'], root)
            self.assertEqual(observed['observation'], 'OBSERVATION_FAILED')
            self.assertFalse(observed['matches'])


if __name__ == '__main__':
    unittest.main()
