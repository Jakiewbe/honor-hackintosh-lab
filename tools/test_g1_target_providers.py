import hashlib
from pathlib import Path
import tempfile
import unittest
import copy
import contextlib
import io
import json
from types import SimpleNamespace
from unittest.mock import patch

from g1_target_providers import (load_imports, match_records, observe_allowlist, observe_binary,
    observe_symbolsets, parse_allowlist, parse_globals, section_bounds,
    required_evidence_gate, run_collection)
import plistlib
import struct


class TargetProviderTests(unittest.TestCase):
    def gate_report(self):
        return {'status': 'DISCOVERY_COMPLETE_NOT_TARGET_KPI_OR_ABI_ACCEPTANCE', 'counts': {},
            'kernel_symbolsets': {'observation': 'PLIST_DECODED'},
            'providers': [
                {'id': 'runner-kernel', 'observation': 'PARSED', 'global_symbol_count': 1},
                {'id': 'IOPCIFamily-kext-allowlist', 'observation': 'PARSED', 'exported_name_count': 1},
                {'id': 'IOACPIFamily-kext-allowlist', 'observation': 'PARSED', 'exported_name_count': 1},
                {'id': 'family-standalone-binary', 'observation': 'NOT_PRESENT'}]}

    def test_gate_does_not_require_standalone_family_binary(self):
        self.assertEqual(required_evidence_gate(self.gate_report())['status'], 'PASSED')

    def test_each_required_failure_returns_nonzero_and_preserves_report(self):
        cases = []
        for i in range(3):
            for state in ['NOT_PRESENT', 'NM_FAILED', 'OBSERVATION_FAILED', 'NO_GLOBAL_SYMBOLS']:
                r = self.gate_report()
                r['providers'][i]['observation'] = state
                cases.append(r)
        for state in ['FAILED', 'OTOOL_FAILED']:
            r = self.gate_report()
            r['kernel_symbolsets']['observation'] = state
            cases.append(r)
        # Exercise the production run_collection entry, not just a model of it.
        for report in cases:
            with self.subTest(report=report), tempfile.TemporaryDirectory() as tmp:
                args = SimpleNamespace(out=Path(tmp)/'observations')
                with patch('g1_target_providers.collect', return_value=report), contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(run_collection(args), 2)
                saved = json.loads((args.out/'report.json').read_text())
                self.assertEqual(saved['required_evidence_gate']['status'], 'FAILED')
                self.assertEqual(saved['status'], 'DISCOVERY_INCOMPLETE_REQUIRED_EVIDENCE_FAILED')
                self.assertEqual(saved['providers'], report['providers'])

    def test_missing_duplicate_or_empty_required_provider_rejected(self):
        r = self.gate_report()
        for alteration in ['missing', 'duplicate', 'empty']:
            bad = copy.deepcopy(r)
            if alteration == 'missing':
                bad['providers'].pop(0)
            elif alteration == 'duplicate':
                bad['providers'].append(bad['providers'][0])
            else:
                bad['providers'][0]['global_symbol_count'] = 0
            self.assertEqual(required_evidence_gate(bad)['status'], 'FAILED')

    def test_success_entry_and_exception_do_not_erase_evidence(self):
        for failed in [False, True]:
            with tempfile.TemporaryDirectory() as tmp:
                args = SimpleNamespace(out=Path(tmp)/'observations')
                def collect_fixture(args, out):
                    (out/'partial.txt').write_text('retained')
                    if failed:
                        raise ValueError('injected collection failure')
                    return self.gate_report()
                with patch('g1_target_providers.collect', side_effect=collect_fixture), contextlib.redirect_stdout(io.StringIO()):
                    if failed:
                        with self.assertRaisesRegex(ValueError, 'injected'):
                            run_collection(args)
                        self.assertTrue((args.out/'failure.json').is_file())
                    else:
                        self.assertEqual(run_collection(args), 0)
                self.assertEqual((args.out/'partial.txt').read_text(), 'retained')

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

    def test_real_otool_section_shape_duplicate_and_bounds(self):
        text = 'Load command 11\nSection\n  sectname __symbolsets\n   segname __LINKINFO\n      addr 0xffffff8000fbd000\n      size 0x000000000004c55a\n    offset 15056896\n     align 2^0 (1)\nLoad command 12\n'
        self.assertEqual(section_bounds(text, '__LINKINFO', '__symbolsets', 18349264), (15056896, 312666))
        for wrong, length in [(text+text, 18349264), (text, 40), (text.replace('__LINKINFO', '__OTHER'), 18349264)]:
            with self.assertRaises(ValueError):
                section_bounds(wrong, '__LINKINFO', '__symbolsets', length)

    def test_symbolset_bytes_bound_to_exact_kernel_not_abi_proof(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            p = root/'synthetic-header-fixture'
            raw = struct.pack('<IIIIIIII', 0xfeedfacf, 0x01000007, 3, 2, 0, 0, 0, 0)
            payload = plistlib.dumps({'fixture': ['_x']})
            p.write_bytes(raw+payload)
            h = hashlib.sha256(p.read_bytes()).hexdigest()
            text = 'Section\nsectname __symbolsets\nsegname __LINKINFO\noffset 32\nsize '+hex(len(payload))+'\n'
            row = observe_symbolsets(p, text, h, root)
            self.assertEqual(row['observation'], 'PLIST_DECODED')
            self.assertIn('NOT_ABI', row['level'])
            self.assertEqual(plistlib.loads((root/'kernel-symbolsets-decoded.txt').read_bytes()), {'fixture': ['_x']})
            p.write_bytes(raw+payload+b'changed')
            self.assertEqual(observe_symbolsets(p, text, h, root)['observation'], 'FAILED')


if __name__ == '__main__':
    unittest.main()
