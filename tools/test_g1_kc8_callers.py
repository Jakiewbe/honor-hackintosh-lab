import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import hashlib

from g1_kc8_callers import calls, method_observation, METHODS, historic_check, object_imports

NAME = METHODS[3]
LLVM = NAME[1:]
DECL = 'declare void @'+LLVM+'(ptr noundef, i64 noundef, i8 noundef zeroext)\n'
IR = ('define void @actual_os_write(ptr %p, i64 %off, i8 %val) {\n'
      '  tail call void @'+LLVM+'(ptr noundef %p, i64 noundef %off, i8 noundef zeroext %val) #1\n'
      '  ret void\n}\n'+DECL)


class CallerContract(unittest.TestCase):
    def test_real_empty_nm_still_requires_exact_object_and_success(self):
        with tempfile.TemporaryDirectory() as folder:
            obj, log = Path(folder)/'actual.o', Path(folder)/'nm.txt'
            good = 'ARGV='+json.dumps(['xcrun','nm','-u',str(obj)])+'\n\nEXIT=0\n'
            log.write_text(good)
            self.assertEqual(object_imports(log,obj),set())
            for bad in [good.replace('EXIT=0','EXIT=1'),good.replace('actual.o','other.o'),
                        good.replace('EXIT=0\n',''),good+'EXIT=0\n', '\n']:
                log.write_text(bad)
                with self.assertRaises(ValueError): object_imports(log,obj)

    def historical_fixture(self, folder):
        root = Path(folder).resolve()
        candidate, nv, sdk = [root/x for x in ['candidate','nv','sdk']]
        rel = 'kexts/NVRM/test.cpp'
        source = candidate/rel
        source.parent.mkdir(parents=True)
        source.write_text('int actual_source;\n')
        old_candidate, old_nv, old_sdk = [root/x for x in ['old-candidate','old-nv','old-sdk']]
        old_source = old_candidate/rel
        old = ['xcrun','clang++','-isysroot',str(old_sdk),'-DFIXED=1',
            '-I'+str(old_nv/'src/nvidia/arch/nvalloc/unix/include'),'-I'+str(old_candidate),
            '-c',str(old_source),'-o',str(root/'old.o')]
        path=root/'research/gpu-safety-r5/input-binding-evidence/input-snapshots/uni-test_cpp.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps({'source':str(old_source),'cwd':str(old_candidate),'compile_argv':old,
            'inputs':[{'resolved_path':str(old_source),'sha256':hashlib.sha256(source.read_bytes()).hexdigest()}]}))
        argv = ['xcrun','clang++','-isysroot',str(sdk),'-DFIXED=1',
            '-I'+str(nv/'src/nvidia/arch/nvalloc/unix/include'),'-I'+str(candidate),
            '-c',str(source),'-o',str(root/'new.o')]
        return root, candidate, nv, sdk, rel, argv

    def test_exact_historical_profile_and_source_after_relocation(self):
        with tempfile.TemporaryDirectory() as folder:
            root, candidate, nv, sdk, rel, argv = self.historical_fixture(folder)
            with patch('g1_kc8_callers.ROOT',root):
                self.assertIn('MATCH',historic_check(rel,argv,candidate,nv,sdk)['status'])

    def test_historical_flag_change_refused(self):
        with tempfile.TemporaryDirectory() as folder:
            root, candidate, nv, sdk, rel, argv = self.historical_fixture(folder)
            argv[argv.index('-DFIXED=1')]='-DFIXED=2'
            with patch('g1_kc8_callers.ROOT',root), self.assertRaisesRegex(ValueError,'profile differs'):
                historic_check(rel,argv,candidate,nv,sdk)

    def test_historical_source_change_refused(self):
        with tempfile.TemporaryDirectory() as folder:
            root, candidate, nv, sdk, rel, argv = self.historical_fixture(folder)
            (candidate/rel).write_text('int changed_source;\n')
            with patch('g1_kc8_callers.ROOT',root), self.assertRaisesRegex(ValueError,'TU changed'):
                historic_check(rel,argv,candidate,nv,sdk)

    def test_real_call_object_and_sdk(self):
        row = method_observation(IR, NAME, {NAME}, DECL)
        self.assertIn('MATCH', row['status'])
        self.assertIn('@actual_os_write', row['calls'][0]['owner'])

    def test_declaration_only_not_a_call(self):
        row = method_observation(DECL, NAME, {NAME}, DECL)
        self.assertEqual(row['status'], 'NOT_OBSERVED_IN_THIS_TU')

    def test_missing_object_import_refused(self):
        with self.assertRaisesRegex(ValueError, 'absent'): method_observation(IR, NAME, set(), DECL)

    def test_changed_sdk_extension_refused(self):
        with self.assertRaisesRegex(ValueError, 'mismatch'): method_observation(IR, NAME, {NAME}, DECL.replace('zeroext','signext'))

    def test_changed_call_extension_refused(self):
        bad = IR.replace('zeroext %val','signext %val')
        with self.assertRaisesRegex(ValueError, 'mismatch'): method_observation(bad, NAME, {NAME}, DECL)

    def test_scalar_constants(self):
        text = IR.replace('%off, i8 noundef zeroext %val)', '0, i8 noundef zeroext 17)')
        self.assertEqual(len(calls(text, LLVM)), 1)

    def test_unknown_operand_refused(self):
        with self.assertRaises(ValueError): calls(IR.replace('%val)', 'getelementptr (i8, ptr %p, i64 1))'), LLVM)

    def test_retired_probe_real_subprocess_is_nonzero(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)/'out'
            proc = subprocess.run([sys.executable,str(Path(__file__).with_name('g1_full_rm_probe.py')),
                '--nv',str(Path(folder)/'does-not-exist'),'--out',str(out)], capture_output=True, text=True)
            self.assertEqual(proc.returncode,2)
            self.assertEqual(sorted(p.name for p in out.iterdir()),['report.json'])
            report = json.loads((out/'report.json').read_text())
            self.assertEqual(report['link'],'NOT_ATTEMPTED')
            again = subprocess.run([sys.executable,str(Path(__file__).with_name('g1_full_rm_probe.py')),
                '--out',str(out)], capture_output=True)
            self.assertNotEqual(again.returncode,0)


if __name__ == '__main__': unittest.main()
