"""Negative mutations of the REAL C0 evidence, never fake GPU/ABI success."""
import csv
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from r14c0_validate_dependency_baseline import inspect, function_region, safe_path
from source_cache_support import require_source_cache


class DependencyGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name) / 'baseline'
        shutil.copytree(ROOT / 'research/independent-i915', self.base)
        self.cache = ROOT / '.cache'

    def change_json(self, name, change):
        path = self.base / name
        value = json.loads(path.read_text(encoding='utf-8'))
        change(value)
        path.write_text(json.dumps(value), encoding='utf-8')

    def change_csv(self, name, change):
        path = self.base / name
        with path.open(encoding='utf-8', newline='') as f:
            reader = csv.DictReader(f); fields = reader.fieldnames; rows = list(reader)
        change(rows)
        with path.open('w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fields); writer.writeheader(); writer.writerows(rows)

    def rejects(self):
        with self.assertRaises((ValueError, OSError, KeyError)):
            inspect(self.base, self.cache)

    def test_recorded_slice_valid_but_closure_blocked(self):
        require_source_cache(self, self.base / 'source-lock.json', self.cache)
        result = inspect(self.base, self.cache)
        self.assertEqual(result['structure'], 'PASS')
        self.assertEqual(result['closure'], 'BLOCKED')
        self.assertEqual(result['objects_compiled'], 0)
        self.assertTrue(result['upstream_pm_empty_success_observed'])

    def test_missing_source_rejected(self):
        self.cache = Path(self.temp.name) / 'empty-cache'
        self.rejects()

    def test_changed_bytes_rejected(self):
        first = json.loads((self.base / 'source-lock.json').read_text())['files'][0]
        self.cache = Path(self.temp.name) / 'bad-cache'
        p = self.cache / first['component'] / first['path']; p.parent.mkdir(parents=True)
        p.write_text('corrupted evidence', encoding='utf-8')
        self.rejects()

    def test_missing_commit_rejected(self):
        self.change_json('source-lock.json', lambda x: x['files'][0].update(commit=''))
        self.rejects()

    def test_wrong_base_version_rejected(self):
        self.change_json('source-lock.json', lambda x: next(r for r in x['components'] if r['id']=='freebsd-src').update(commit='0'*40))
        self.rejects()

    def test_missing_blob_rejected(self):
        self.change_json('source-lock.json', lambda x: x['files'][0].update(blob_sha=''))
        self.rejects()

    def test_duplicate_source_rejected(self):
        self.change_json('source-lock.json', lambda x: x['files'].append(x['files'][0].copy()))
        self.rejects()

    def test_missing_license_row_rejected(self):
        self.change_csv('license-manifest.csv', lambda x: x.pop())
        self.rejects()

    def test_missing_license_evidence_rejected(self):
        self.change_csv('license-manifest.csv', lambda x: next(r for r in x if r['status']=='HEADER_OBSERVED').update(evidence=''))
        self.rejects()

    def test_license_for_wrong_blob_rejected(self):
        self.change_csv('license-manifest.csv', lambda x: x[0].update(blob_sha='0'*40))
        self.rejects()

    def test_duplicate_object_different_source_rejected(self):
        def mutate(rows):
            other = next(r for r in rows if r['path'] != rows[0]['path'])
            other['object_target'] = rows[0]['object_target']
        self.change_csv('symbol-inventory.csv', mutate)
        self.rejects()

    def test_missing_source_object_mapping_rejected(self):
        self.change_json('source-lock.json', lambda x: next(r for r in x['files'] if r['path'].endswith('.c')).update(object_target=None))
        self.rejects()

    def test_false_definition_line_rejected(self):
        self.change_csv('symbol-inventory.csv', lambda x: x[0].update(defined_line='1'))
        self.rejects()

    def test_symbol_for_wrong_blob_rejected(self):
        self.change_csv('symbol-inventory.csv', lambda x: x[0].update(blob_sha='0'*40))
        self.rejects()

    def test_non_boolean_api_status_rejected(self):
        self.change_json('api-contracts.json', lambda x: x[0].update(required='true'))
        self.rejects()

    def test_invented_symbol_rejected(self):
        self.change_csv('symbol-inventory.csv', lambda x: x[0].update(symbol='invented_alderfb_start'))
        self.rejects()

    def test_false_direct_call_rejected(self):
        self.change_json('callgraph-edges.json', lambda x: x[0].update(to='drm:icl_plane_update_arm'))
        self.rejects()

    def test_false_callback_binding_rejected(self):
        self.change_json('callgraph-edges.json', lambda x: next(r for r in x if r['kind']=='CALLBACK_ASSIGNMENT').update(assignment_pattern='unimplemented_binding'))
        self.rejects()

    def test_required_unimplemented_api_may_not_report_success(self):
        self.change_json('api-contracts.json', lambda x: x[0].update(success_allowed=True))
        self.rejects()

    def test_api_missing_provider_diagnostic_rejected(self):
        self.change_json('api-contracts.json', lambda x: x[0].update(source_refs=[]))
        self.rejects()

    def test_upstream_stub_may_not_be_claimed_as_xnu_implemented(self):
        self.change_json('api-contracts.json', lambda x: next(r for r in x if r['id']=='POWER_RUNTIME_PM').update(xnu_status='IMPLEMENTED'))
        self.rejects()

    def test_no_false_build_or_runtime_upgrade(self):
        self.change_json('source-lock.json', lambda x: x.update(runtime_decision='RUNTIME_GO'))
        self.rejects()

    def test_path_escape_rejected(self):
        for path in ('../outside', 'C:/outside', '/outside', 'folder\\outside'):
            with self.subTest(path=path), self.assertRaises(ValueError):
                safe_path(self.cache, path)

    def test_comments_strings_not_function_evidence(self):
        with self.assertRaises(ValueError):
            function_region('/* int x() { return 0; } */\nchar *s="int x() {}";', 'x')

    def test_cli_closure_fails_and_structure_passes(self):
        require_source_cache(self, self.base / 'source-lock.json', self.cache)
        script = ROOT / 'scripts/r14c0_validate_dependency_baseline.py'
        for mode, expected in [('structure', 0), ('closure', 2)]:
            p = subprocess.run([sys.executable, '-X', 'utf8', str(script), '--baseline', str(self.base),
                                '--cache', str(self.cache), '--mode', mode], capture_output=True, text=True, encoding='utf-8')
            self.assertEqual(p.returncode, expected, p.stdout + p.stderr)
            self.assertEqual(json.loads(p.stdout)['closure'], 'BLOCKED')


if __name__ == '__main__':
    unittest.main()
