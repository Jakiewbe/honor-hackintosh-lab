"""Acceptance-path negative controls; header fixtures are not driver build products."""
import contextlib
import importlib
import io
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts/g1'))
gate = importlib.import_module('stock_v243_kext_link')


class LinkGateContract(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def failed_tool(self, argv, cwd, log, **kwargs):
        log.write_text('error: deliberately failed\n')
        return 1

    def test_real_process_failure_is_not_hidden_by_error_text(self):
        with self.assertRaisesRegex(ValueError, 'exit=7'):
            gate.checked_run([sys.executable, '-c', 'print("error: injected"); raise SystemExit(7)'],
                             self.root, self.root/'process.txt')

    def test_compiler_failure_deletes_stale_object(self):
        obj = self.root/'old.o'; obj.write_bytes(b'old')
        with self.assertRaises(ValueError):
            gate.compile_checked([], self.root, obj, self.root/'compile.txt', self.failed_tool)
        self.assertFalse(obj.exists())

    def test_success_exit_without_object_is_rejected(self):
        with self.assertRaises(FileNotFoundError):
            gate.compile_checked([], self.root, self.root/'missing.o', self.root/'compile.txt',
                                 lambda *args, **kwargs: 0)

    def test_invalid_object_is_rejected_and_deleted(self):
        obj = self.root/'invalid.o'
        def writes_garbage(*args, **kwargs):
            obj.write_bytes(b'not Mach-O')
            return 0
        with self.assertRaises(ValueError):
            gate.compile_checked([], self.root, obj, self.root/'compile.txt', writes_garbage)
        self.assertFalse(obj.exists())

    def test_linker_failure_deletes_stale_binary(self):
        binary = self.root/'NVRM'; binary.write_bytes(b'old')
        with self.assertRaises(ValueError):
            gate.link_checked([], self.root, binary, self.root/'ld.txt', self.failed_tool)
        self.assertFalse(binary.exists())

    def test_wrong_macho_kind_cannot_pass_as_kext(self):
        binary = self.root/'fixture'
        def writes_object_header(*args, **kwargs):
            binary.write_bytes(struct.pack('<8I', 0xfeedfacf, 0x01000007, 3, 1, 0, 0, 0, 0))
            return 0
        with self.assertRaisesRegex(ValueError, 'MH_KEXT_BUNDLE'):
            gate.link_checked([], self.root, binary, self.root/'ld.txt', writes_object_header)
        self.assertFalse(binary.exists())

    def test_missing_object_rejected(self):
        with self.assertRaisesRegex(ValueError, 'missing='):
            gate.validate_set([self.root/'missing.o'], self.root)

    def test_unlisted_object_rejected(self):
        (self.root/'extra.o').write_bytes(b'fixture')
        with self.assertRaisesRegex(ValueError, 'extra='):
            gate.validate_set([self.root/'missing.o'], self.root)

    def test_duplicate_manifest_rejected(self):
        obj = self.root/'missing.o'
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            gate.validate_set([obj, obj], self.root)

    def test_short_make_manifest_rejected(self):
        base = self.root/'src/nvidia'; base.mkdir(parents=True)
        (base/'srcs.mk').write_text('SRCS ?=\nSRCS += x.c\n')
        with self.assertRaisesRegex(ValueError, '1054'):
            gate.parse_manifest('G1_SOURCE x.c _out/Darwin_x86_64/x.o', self.root)

    def test_make_manifest_duplicate_rejected_even_at_expected_count(self):
        base = self.root/'src/nvidia'; base.mkdir(parents=True)
        sources = [f'item{i}.c' for i in range(1054)]
        (base/'srcs.mk').write_text('SRCS ?=\n'+''.join('SRCS += '+s+'\n' for s in sources))
        rows = ['G1_SOURCE '+s+' _out/Darwin_x86_64/'+Path(s).stem+'.o' for s in sources]
        rows += ['G1_SOURCE _out/Darwin_x86_64/g_nvid_string.c _out/Darwin_x86_64/g_nvid_string.o']
        self.assertEqual(len(gate.parse_manifest('\n'.join(rows), self.root)), 1055)
        rows[-1] = rows[0]
        with self.assertRaises(ValueError):
            gate.parse_manifest('\n'.join(rows), self.root)

    def test_main_preserves_failure_report_and_nonzero_exit(self):
        logs = self.root/'logs'
        argv = ['gate', '--nm', str(self.root), '--nv', str(self.root), '--assets', str(self.root),
                '--out', str(logs), '--work', str(self.root/'work')]
        def failed_build(args, report):
            report['stage'] = 'link'
            raise ValueError('injected link failure')
        with patch.object(sys, 'argv', argv), patch.object(gate, 'build', failed_build), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(gate.main(), 2)
        report = json.loads((logs/'report.json').read_text())
        self.assertEqual(report['status'], 'FAILED')
        self.assertEqual(report['stage'], 'link')
        self.assertIn('injected', report['error'])

    def test_three_workflows_are_manual_and_upload_text_only(self):
        for name in ('g1-stock-v243-kext-link.yml', 'g1-stock-v243-once-native.yml', 'g1-iographics-exports.yml'):
            text = (ROOT/'.github/workflows'/name).read_text(encoding='utf-8')
            self.assertIn('  workflow_dispatch:', text)
            self.assertNotIn('\n  push:', text)
            self.assertNotIn('\n  schedule:', text)
        workflow = (ROOT/'.github/workflows/g1-stock-v243-kext-link.yml').read_text()
        self.assertIn('if: always()', workflow)
        self.assertIn('path: ${{ runner.temp }}/link-text/', workflow)
        self.assertNotIn('continue-on-error', workflow)

    def test_once_lock_has_no_obsolete_excluded_sites(self):
        lock = json.loads((ROOT/'research/stock-v243-once-20261021/source-lock.json').read_text())
        self.assertEqual(lock['excluded']['sites'], [])
        for entry in lock['integration_symbols']['approved_new_undefined']:
            self.assertNotIn('ten sites', entry['reason'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
