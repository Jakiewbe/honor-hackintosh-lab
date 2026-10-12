"""Fail-closed tests using copies of the real immutable survey evidence."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from acpi_static_validate_inputs import SURVEY, validate


class EvidenceValidation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.survey = Path(self.temp.name) / 'survey'
        shutil.copytree(SURVEY, self.survey)
        self.table = next((self.survey / 'evidence/acpi').glob('reg_DSDT_*.bin'))

    def test_real_evidence(self):
        self.assertEqual(validate(self.survey)['primary_count'], 16)

    def test_changed_byte(self):
        data = bytearray(self.table.read_bytes()); data[40] ^= 1
        self.table.write_bytes(data)
        with self.assertRaisesRegex(ValueError, 'hash mismatch'):
            validate(self.survey)

    def test_missing_table(self):
        self.table.unlink()
        with self.assertRaises(FileNotFoundError):
            validate(self.survey)

    def test_changed_metadata(self):
        p = self.survey / 'evidence/P40_acpi_tables.json'
        p.write_bytes(p.read_bytes() + b' ')
        with self.assertRaisesRegex(ValueError, 'metadata hash mismatch'):
            validate(self.survey)

    def test_duplicate_hash_entry(self):
        p = self.survey / 'FILES_SHA256.txt'
        data = p.read_bytes(); p.write_bytes(data.rstrip(b'\r\n') + b'\n' + data.splitlines()[0] + b'\n')
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            validate(self.survey)

    def test_cli_rejects_hash_mismatch(self):
        self.table.write_bytes(self.table.read_bytes()[:-1])
        p = subprocess.run([sys.executable, str(ROOT / 'scripts/acpi_static_validate_inputs.py'), '--survey', str(self.survey)], capture_output=True)
        self.assertNotEqual(p.returncode, 0)


if __name__ == '__main__':
    unittest.main()
