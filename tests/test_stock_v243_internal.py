"""Fail-closed internal integration contracts; synthetic payloads stay in tests."""
import contextlib
import importlib
import io
import json
import lzma
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts/g1'))
gate = importlib.import_module('stock_v243_internal_link')


class InternalLinkContract(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_delta_requires_all_twelve_real_definitions(self):
        for missing in gate.NVKMS:
            with self.assertRaises(ValueError):
                gate.check_delta(gate.NVKMS, set(), gate.NVKMS-{missing}, gate.NVKMS, set())

    def test_nvlink_imports_cannot_be_silently_retained(self):
        with self.assertRaises(ValueError):
            gate.check_delta(gate.NVLINK, gate.NVLINK, gate.NVLINK, gate.NVLINK, {'_panic'})

    def test_new_dependencies_need_explicit_approval(self):
        with self.assertRaisesRegex(ValueError, 'unreviewed'):
            gate.check_delta(gate.NVKMS, {'_unreviewed'}, gate.NVKMS, gate.NVKMS, set())

    def test_optional_sha1_removal_requires_a_final_definition(self):
        with self.assertRaisesRegex(ValueError, 'unprovided'):
            gate.check_delta(gate.NVKMS|{'_SHA1Init'}, set(), gate.NVKMS,
                gate.NVKMS, set(), {'_SHA1Init'})
        delta = gate.check_delta(gate.NVKMS|{'_SHA1Init'}, set(), gate.NVKMS|{'_SHA1Init'},
            gate.NVKMS, set(), {'_SHA1Init'})
        self.assertIn('_SHA1Init', delta['removed'])

    def test_nvlink_exact_delta_with_fatal_path_import(self):
        delta = gate.check_delta(gate.NVLINK|{'_old'}, {'_old', '_panic'}, gate.NVLINK,
            gate.NVLINK, {'_panic'})
        self.assertEqual(delta['added'], ['_panic'])
        self.assertEqual(delta['removed'], sorted(gate.NVLINK))

    def test_lost_unrelated_import_is_rejected(self):
        with self.assertRaises(ValueError):
            gate.check_delta(gate.NVKMS|{'_lost'}, set(), gate.NVKMS|{'_lost'}, gate.NVKMS, set())

    def test_lock_tampering_is_rejected(self):
        source = self.root/'input'; source.write_bytes(b'tampered')
        with self.assertRaisesRegex(ValueError, 'locked input'):
            gate.require_identity(source, '0'*64)

    def test_patch_cannot_be_skipped_by_an_enclosing_repository(self):
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True, capture_output=True)
        child = self.root/'owned-candidate'; child.mkdir()
        source = child/'source.c'; source.write_bytes(b'old\n')
        patchfile = self.root/'change.patch'
        patchfile.write_bytes(b'diff --git a/source.c b/source.c\n--- a/source.c\n+++ b/source.c\n@@ -1 +1 @@\n-old\n+new\n')
        gate.base.checked_run(['git', '-c', 'core.autocrlf=false', 'apply', '--no-index', patchfile],
            child, self.root/'apply.txt', runner=gate.patch_run)
        self.assertEqual(source.read_bytes(), b'new\n')
        gate.base.checked_run(['git', '-c', 'core.autocrlf=false', 'apply', '--no-index', '-R', patchfile],
            child, self.root/'reverse.txt', runner=gate.patch_run)
        self.assertEqual(source.read_bytes(), b'old\n')

    def test_unchanged_patch_lock_is_rejected(self):
        original = self.root/'original'; original.mkdir()
        (original/'source.c').write_bytes(b'old\n')
        patchfile = self.root/'patch'; patchfile.write_bytes(b'unused')
        snapshot = {'source.c':gate.base.digest(original/'source.c')}
        lock = dict(recipes={}, patches=[dict(patch='patch', directory='',
            sha256=gate.base.digest(patchfile), before=snapshot, after=snapshot)])
        with patch.object(gate.base, 'tracked_snapshot', return_value=snapshot):
            with self.assertRaisesRegex(ValueError, 'no declared change'):
                gate.paired_candidate(self.root, original, self.root/'copy', self.root, lock)

    def test_manifest_requires_every_source_and_no_duplicate_object(self):
        component = self.root/'src/nvidia-modeset'; component.mkdir(parents=True)
        sources = [f'item{i}.c' for i in range(224)]
        (component/'srcs.mk').write_text('SRCS ?=\n'+''.join('SRCS += '+s+'\n' for s in sources))
        sources.append('_out/Darwin_x86_64/g_nvid_string.c')
        rows = [f'G1_SOURCE {s} _out/Darwin_x86_64/{Path(s).stem}.o' for s in sources]
        self.assertEqual(len(gate.parse_modeset_manifest('\n'.join(rows), self.root)), 225)
        with self.assertRaises(ValueError):
            gate.parse_modeset_manifest('\n'.join(rows[:-1]), self.root)
        rows[-1] = rows[0]
        with self.assertRaises(ValueError):
            gate.parse_modeset_manifest('\n'.join(rows), self.root)

    def shader_source(self):
        text = ''
        for arch in gate.SHADERS:
            raw = ('synthetic test payload '+arch).encode()
            dest = self.root/('src/nvidia-modeset/src/shaders/g_'+arch+'_shaders')
            dest.parent.mkdir(parents=True, exist_ok=True); dest.write_bytes(raw)
            payload = lzma.compress(raw)
            text += '__binary_'+arch+'_shaders_xz_start:\\n"\n'
            text += '".byte '+','.join(map(str, payload))+'\\n"\n'
            text += '".globl __binary_'+arch+'_shaders_xz_end\n'
        source = self.root/'fixture.cpp'; source.write_text(text)
        return source

    def test_shader_decompression_matches_all_five_fixed_inputs(self):
        source = self.shader_source()
        payloads, proof = gate.shader_payloads(source, self.root)
        self.assertEqual(set(payloads), set(gate.SHADERS))
        self.assertTrue(all(p['raw_bytes_equal'] for p in proof))

    def test_shader_wrong_bytes_rejected(self):
        source = self.shader_source()
        (self.root/'src/nvidia-modeset/src/shaders/g_ampere_shaders').write_bytes(b'wrong')
        with self.assertRaisesRegex(ValueError, 'differs'):
            gate.shader_payloads(source, self.root)

    def test_shader_duplicate_labels_rejected(self):
        source = self.shader_source()
        source.write_text(source.read_text()+'__binary_turing_shaders_xz_start:\\n"\n')
        with self.assertRaisesRegex(ValueError, 'not unique'):
            gate.shader_payloads(source, self.root)

    def test_shader_malformed_assembly_rejected(self):
        source = self.shader_source()
        source.write_text(source.read_text().replace('".byte ', '".long ', 1))
        with self.assertRaisesRegex(ValueError, 'unsupported'):
            gate.shader_payloads(source, self.root)

    def test_object_shader_bytes_and_bounds_are_checked(self):
        payloads = {a:bytes([i])*3 for i,a in enumerate(gate.SHADERS)}
        class Fixture:
            data = b''.join(payloads.values())
            sections = [dict(name='__TEXT,__const', addr=0, size=len(data), offset=0, nreloc=0)]
            symbols = [(f'__binary_{a}_shaders_xz_{s}', 0x0f, 1, i*3+e)
                for i,a in enumerate(gate.SHADERS) for s,e in (('start',0), ('end',3))]
        with patch.object(gate, 'MachO', return_value=Fixture):
            gate.verify_shader_object(self.root, payloads)
            wrong = dict(payloads, ampere=b'bad')
            with self.assertRaisesRegex(ValueError, 'bytes differ'):
                gate.verify_shader_object(self.root, wrong)
            Fixture.symbols[-1] = (*Fixture.symbols[-1][:3], 999)
            with self.assertRaisesRegex(ValueError, 'bounds'):
                gate.verify_shader_object(self.root, payloads)

    def test_incomplete_archive_is_never_built(self):
        dest = self.root/'not-created.a'
        with patch.object(gate.base, 'checked_run') as run:
            with self.assertRaises(ValueError):
                gate.archive_checked([], dest, self.root, self.root/'log')
            run.assert_not_called()
        self.assertFalse(dest.exists())

    def test_integration_failure_cannot_inherit_baseline_pass(self):
        logs = self.root/'logs'
        argv = ['gate', *[s for key in ('nm','nv','assets','out','work')
            for s in ('--'+key, str(logs if key=='out' else self.root))]]
        def baseline(args, report):
            report.update(status=gate.base.PASS, link={}, imports=[])
        with patch.object(sys, 'argv', argv), patch.object(gate.base, 'build', baseline), \
             patch.object(gate, 'integrate', side_effect=ValueError('injected failure')), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(gate.main(), 2)
        report = json.loads((logs/'report.json').read_text())
        self.assertEqual(report['status'], 'FAILED')
        self.assertEqual(report['same_run_baseline']['status'], gate.base.PASS)

    def test_workflow_is_manual_and_publishes_only_text(self):
        text = (ROOT/'.github/workflows/g1-stock-v243-internal-link.yml').read_text()
        self.assertIn('  workflow_dispatch:', text)
        self.assertNotIn('\n  push:', text)
        self.assertNotIn('\n  schedule:', text)
        self.assertIn('path: ${{ runner.temp }}/internal-text/', text)
        self.assertNotIn('continue-on-error', text)


if __name__ == '__main__':
    unittest.main(verbosity=2)
