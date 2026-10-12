"""Tampering tests: a green structure gate must not promote blocked evidence."""
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
from r14c01_validate_power_contract import BASE, validate
from source_cache_support import require_source_cache


class PowerEvidenceGate(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name) / 'c01'
        shutil.copytree(BASE, self.base)

    def mutate(self, name, action):
        p = self.base / name
        data = json.loads(p.read_text(encoding='utf-8'))
        action(data)
        p.write_text(json.dumps(data), encoding='utf-8')

    def rejected(self):
        with self.assertRaises((ValueError, KeyError, OSError)):
            validate(self.base)

    def test_real_structure_stays_blocked(self):
        require_source_cache(self, self.base / 'source-lock.json', ROOT / '.cache')
        result = validate(self.base)
        self.assertEqual((result['structure'], result['closure'], result['runtime']),
                         ('PASS', 'BLOCKED', 'RUNTIME_NO_GO'))

    def test_wrong_base_commit(self):
        self.mutate('source-lock.json', lambda d: d['components'][2].update(commit='0' * 40))
        self.rejected()

    def test_changed_source_blob(self):
        self.mutate('source-lock.json', lambda d: d['files'][0].update(blob_sha='0' * 40))
        self.rejected()

    def test_source_path_escape(self):
        self.mutate('source-lock.json', lambda d: d['files'][0].update(path='../secret'))
        self.rejected()

    def test_missing_source(self):
        self.mutate('source-lock.json', lambda d: d['files'].pop())
        self.rejected()

    def test_invented_xnu_tree_attestation(self):
        self.mutate('source-lock.json', lambda d: next(x for x in d['files'] if x['component'] == 'xnu').update(tree_verified=True))
        self.rejected()

    def test_missing_license_row(self):
        p = self.base / 'license-manifest.csv'
        lines = p.read_text(encoding='utf-8').splitlines()
        p.write_text('\n'.join(lines[:-1]) + '\n', encoding='utf-8')
        self.rejected()

    def test_license_claim_without_evidence(self):
        p = self.base / 'license-manifest.csv'
        with p.open(encoding='utf-8', newline='') as f:
            rows = list(csv.DictReader(f))
        rows[0].update(status='HEADER_OBSERVED_NOT_LEGAL_CLOSURE', evidence_line='1', evidence='MIT')
        with p.open('w', encoding='utf-8', newline='') as f:
            w = csv.DictWriter(f, fieldnames=rows[0]); w.writeheader(); w.writerows(rows)
        self.rejected()

    def test_fake_preprocessing(self):
        self.mutate('build-contract.json', lambda d: d.update(preprocessed=True))
        self.rejected()

    def test_incorrect_include_priority(self):
        self.mutate('build-contract.json', lambda d: d['append_order'].reverse())
        self.rejected()

    def test_missing_generator_input(self):
        self.mutate('build-contract.json', lambda d: d['generated'][0].update(input='sys/kern/invented.m'))
        self.rejected()

    def test_invented_generated_header(self):
        self.mutate('build-contract.json', lambda d: d['generated'][0].update(status='GENERATED'))
        self.rejected()

    def test_missing_interface_rule(self):
        self.mutate('build-contract.json', lambda d: d['generated'].pop())
        self.rejected()

    def test_fake_power_implementation(self):
        self.mutate('power-contracts.json', lambda d: d[1].update(implemented=True, status='READY'))
        self.rejected()

    def test_missing_failure_policy(self):
        self.mutate('power-contracts.json', lambda d: d[1].update(failure=''))
        self.rejected()

    def test_missing_required_contract(self):
        self.mutate('power-contracts.json', lambda d: d.pop())
        self.rejected()

    def test_fabricated_call(self):
        self.mutate('edges.json', lambda d: d[0].update(callee='setPowerState'))
        self.rejected()

    def test_missing_call_edge(self):
        self.mutate('edges.json', lambda d: d.pop())
        self.rejected()

    def test_false_include_provider(self):
        p = self.base / 'transitive-includes.csv'
        with p.open(encoding='utf-8', newline='') as f:
            rows = list(csv.DictReader(f))
        rows[0].update(candidates='freebsd-src/sys/fake.h', status='OBSERVED_CANDIDATE_NOT_PREPROCESSED')
        with p.open('w', encoding='utf-8', newline='') as f:
            w = csv.DictWriter(f, fieldnames=rows[0]); w.writeheader(); w.writerows(rows)
        self.rejected()

    def test_closure_exit_is_two(self):
        require_source_cache(self, BASE / 'source-lock.json', ROOT / '.cache')
        r = subprocess.run([sys.executable, str(ROOT / 'scripts/r14c01_validate_power_contract.py')], capture_output=True, text=True)
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)

    def test_wrong_header_absence_claim(self):
        self.mutate('compiler-types-absence.json', lambda d: d.update(relative_path='common/include/linux/pm_runtime.h'))
        self.rejected()


if __name__ == '__main__':
    unittest.main()
