"""Actual export parser CLI controls on synthetic Mach-O data; no native program executed."""
from pathlib import Path
import json
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]


class ExportControls(unittest.TestCase):
    def run_fixture(self,*args,broken=False):
        with tempfile.TemporaryDirectory() as tmp:
            path=Path(tmp)/'fixture'
            edge=b'_g1_positive\0'
            trie=b'\0\1'+edge+bytes([2+len(edge)+1])+b'\2\0\0\0'
            if broken:trie=b'\xff'
            raw=struct.pack('<8I',0xfeedfacf,0x1000007,3,6,1,16,0,0)
            raw+=struct.pack('<4I',0x80000033,16,48,len(trie))+trie
            path.write_bytes(raw)
            proc=subprocess.run([sys.executable,str(ROOT/'tools/g1_kc_exports.py'),str(path),'fixture',
                '--plain',*args],capture_output=True,text=True)
            return proc,json.loads(proc.stdout)

    def test_real_cli_positive_and_negative_controls(self):
        proc,data=self.run_fixture('--require','g1_positive','--controls','absent')
        self.assertEqual(proc.returncode,0,proc.stderr)
        self.assertTrue(data['controls_passed'])
        self.assertEqual(data['external_runtime_resolution'],'UNVERIFIED')

    def test_absent_required_or_present_negative_control_fails(self):
        for args in (('--require','absent'),('--controls','g1_positive'),('--require','__g1_positive')):
            proc,data=self.run_fixture(*args)
            self.assertEqual(proc.returncode,2)
            self.assertFalse(data['controls_passed'])

    def test_malformed_trie_is_not_success(self):
        proc,data=self.run_fixture(broken=True)
        self.assertEqual(proc.returncode,2)
        self.assertEqual(data['verdict'],'FAILED_PARSE_OR_REQUIRED_CONTROLS')


if __name__=='__main__':unittest.main()
