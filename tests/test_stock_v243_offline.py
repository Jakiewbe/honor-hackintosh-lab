"""Production preflight/path/report contracts. No GPU, driver or native-build execution."""
import argparse
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest import mock

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/g1'))
import offline_build as gate
import stock_v243_kext_link as base


class OfflineContracts(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.repo=self.root/'repo';self.nm=self.root/'nm';self.nv=self.root/'nv'
        for tree in (self.repo,self.nm,self.nv):
            tree.mkdir();self.git(tree,'init','-q');self.git(tree,'config','core.autocrlf','false')
            (tree/'input.txt').write_text('fixed input\n')
        for name in (*gate.ENTRY_FILES,
            'research/stock-v243-once-20261021/source-lock.json',
            'research/stock-v243-once-20261021/stock-v243-converged.patch',
            'research/stock-v243-offscreen-20261021/iofam-lock.json',
            'research/stock-v243-offscreen-20261021/iofam-enum-types.patch'):
            dest=self.repo/name;dest.parent.mkdir(parents=True,exist_ok=True)
            # Locked patch bytes are intentionally not normalized.
            shutil.copyfile(ROOT/name,dest)
        self.heads={}
        for tree in (self.repo,self.nm,self.nv):
            self.git(tree,'add','.');self.git(tree,'-c','user.name=fixture','-c','user.email=fixture@example.invalid','commit','-qm','input')
            self.heads[tree]=self.git(tree,'rev-parse','HEAD').strip()
        self.addCleanup(mock.patch.stopall)
        mock.patch.object(gate,'NM_PIN',self.heads[self.nm]).start()
        mock.patch.object(gate,'NV_PIN',self.heads[self.nv]).start()
        self.make=self.root/'fixture-make'
        self.make.write_text('#!'+sys.executable+'\nprint("GNU Make 4.4.1")\n')
        self.make.chmod(0o755)
        mock.patch.object(gate.shutil,'which',side_effect=lambda name:str(self.make) if name=='gmake' else None).start()
        self.args=argparse.Namespace(repo=self.repo,nm=self.nm,nv=self.nv,
            expected_commit=self.heads[self.repo],work=self.root/'dedicated',
            make_archive=self.root/'absent.tar.gz',min_free_bytes=0)
        self.sdk=self.root/'sdk'
        header=self.sdk/'System/Library/Frameworks/Kernel.framework/Headers/IOKit/IOService.h'
        header.parent.mkdir(parents=True);header.write_text('fixture only; no native compilation')

    def git(self,tree,*args):
        return subprocess.check_output(['git','-c','safe.directory='+str(tree),'-C',str(tree),*args],text=True)

    def query(self,argv,**kw):
        values={('uname','-s'):'Darwin',('uname','-m'):'x86_64',
            ('xcode-select','-p'):'/existing/CLT',('xcrun','--show-sdk-version'):'15.5',
            ('xcrun','--show-sdk-path'):str(self.sdk),
            ('xcrun','clang','--version'):'fixture clang',
            (str(self.make),'--version'):'GNU Make 4.4.1\nfixture'}
        if tuple(argv) not in values:raise ValueError('unexpected command: '+str(argv))
        return values[tuple(argv)]

    def test_preflight_is_readonly_and_has_stable_14_checks(self):
        before=list(self.root.iterdir())
        result=gate.preflight(self.args,self.query)
        self.assertEqual(result['status'],'PASS',result)
        self.assertEqual(result['check_count'],14)
        self.assertEqual(len({r['id'] for r in result['checks']}),14)
        self.assertEqual(list(self.root.iterdir()),before)
        self.assertFalse(self.args.work.exists())

    def test_command_nonzero_with_empty_stdout_is_not_clean(self):
        with self.assertRaises(ValueError):gate.command([sys.executable,'-c','raise SystemExit(7)'])
        original=gate.git
        def fail_status(root,*args):
            if args[0]=='status':raise ValueError('git failed with no stdout')
            return original(root,*args)
        with mock.patch.object(gate,'git',side_effect=fail_status):
            result=gate.preflight(self.args,self.query)
        self.assertEqual(result['status'],'FAILED')
        self.assertEqual(sum(r['status']=='FAIL' for r in result['checks']),3)

    def test_wrong_or_missing_expected_commit_and_dirty_repo_rejected(self):
        for commit in ('','0'*40):
            self.args.expected_commit=commit
            self.assertEqual(gate.preflight(self.args,self.query)['status'],'FAILED')
        self.args.expected_commit=self.heads[self.repo]
        (self.repo/'input.txt').write_text('changed')
        self.assertEqual(gate.preflight(self.args,self.query)['status'],'FAILED')

    def test_tracked_input_change_and_untracked_file_rejected(self):
        (self.nm/'input.txt').write_text('changed')
        self.assertEqual(gate.preflight(self.args,self.query)['status'],'FAILED')
        (self.nm/'input.txt').write_text('fixed input\n')
        (self.nv/'unknown.c').write_text('untracked')
        self.assertEqual(gate.preflight(self.args,self.query)['status'],'FAILED')

    def test_crlf_entry_and_patch_hash_corruption_rejected(self):
        entry=self.repo/gate.ENTRY_FILES[0]
        entry.write_bytes(entry.read_bytes().replace(b'\n',b'\r\n'))
        result=gate.preflight(self.args,self.query)
        self.assertIn('shell-lf',[r['id'] for r in result['checks'] if r['status']=='FAIL'])
        patch=self.repo/'research/stock-v243-once-20261021/stock-v243-converged.patch'
        patch.write_bytes(b'corrupt')
        result=gate.preflight(self.args,self.query)
        self.assertIn('assets',[r['id'] for r in result['checks'] if r['status']=='FAIL'])

    def test_missing_tools_empty_sdk_and_command_errors_rejected(self):
        for target,value in ((('xcrun','--show-sdk-version'),''),
                             (('xcode-select','-p'),''),
                             (('xcrun','clang','--version'),'')):
            def query(argv):return value if tuple(argv)==target else self.query(argv)
            self.assertEqual(gate.preflight(self.args,query)['status'],'FAILED')
        def error(argv):
            if argv[0]=='xcrun':raise FileNotFoundError('missing tool')
            return self.query(argv)
        self.assertEqual(gate.preflight(self.args,error)['status'],'FAILED')

    def test_sdk_version_cannot_be_waived(self):
        def newer(argv):return '26.0' if tuple(argv)==('xcrun','--show-sdk-version') else self.query(argv)
        self.assertEqual(gate.preflight(self.args,newer)['status'],'FAILED')

    def test_make4_needs_no_archive_old_make_cannot_be_shimmed(self):
        self.assertEqual(gate.preflight(self.args,self.query)['status'],'PASS')
        def old(argv):return 'GNU Make 3.81' if argv[0]==str(self.make) else self.query(argv)
        self.assertEqual(gate.preflight(self.args,old)['status'],'FAILED')

    def test_disk_empty_or_insufficient_is_failed(self):
        for free in (None,'',0):
            self.args.min_free_bytes=8*1024**3
            with mock.patch.object(gate.shutil,'disk_usage',return_value=argparse.Namespace(free=free)):
                result=gate.preflight(self.args,self.query)
            self.assertEqual(result['status'],'FAILED')

    def test_unowned_overlap_or_input_ancestor_work_rejected_without_deletion(self):
        unowned=self.root/'unowned';unowned.mkdir();keep=unowned/'keep';keep.write_text('keep')
        for work in (unowned,self.nm,self.nm/'child',self.root,self.repo/'build'):
            with self.assertRaises(ValueError):gate.workspace(work,(self.repo,self.nm,self.nv))
        self.assertEqual(keep.read_text(),'keep')

    @unittest.skipIf(os.name=='nt','symlink needs explicit Windows privilege; tested on native CI')
    def test_work_symlink_and_managed_marker_symlink_rejected(self):
        alias=self.root/'alias';alias.symlink_to(self.nm,target_is_directory=True)
        with self.assertRaises(ValueError):gate.workspace(alias,(self.repo,self.nm,self.nv))
        work=self.root/'managed';work.mkdir();(work/gate.MARKER).symlink_to(self.nm/'input.txt')
        with self.assertRaises(ValueError):gate.workspace(work,(self.repo,self.nm,self.nv))

    def test_all_failed_preconditions_block_the_real_build_entry(self):
        called=[]
        self.args.expected_commit='0'*40
        result=gate.build(self.args,self.query,lambda *a:called.append(a))
        self.assertEqual(result['status'],'FAILED');self.assertEqual(called,[])
        self.assertFalse(self.args.work.exists())

    @unittest.skipIf(os.name=='nt','POSIX utility fixture and symlink orchestration tested on native CI')
    def test_repeat_build_uses_fresh_sessions_and_failure_report_survives(self):
        calls=[]
        one=gate.build(self.args,self.query,lambda *a:calls.append(a))
        self.assertEqual(one['status'],'PASS_ORCHESTRATION_FIXTURE_NO_NATIVE_BUILD',one)
        keep=Path(one['session'])/'keep.txt';keep.write_text('preserved')
        def fail(*a):raise ValueError('injected compiler entry failure')
        two=gate.build(self.args,self.query,fail)
        self.assertEqual(two['status'],'FAILED');self.assertNotEqual(one['session'],two['session'])
        self.assertEqual(keep.read_text(),'preserved')
        self.assertIn('injected',json.loads((Path(two['session'])/'build-report.json').read_text())['error'])
        self.assertEqual(len(calls),1)

    def test_gnu_archive_hash_and_path_or_link_controls(self):
        for name,typ in (('make-4.4.1/good',tarfile.REGTYPE),('../escape',tarfile.REGTYPE),
                         ('make-4.4.1/link',tarfile.SYMTYPE)):
            path=self.root/'make.tar.gz'
            with tarfile.open(path,'w:gz') as out:
                member=tarfile.TarInfo(name);member.type=typ
                if typ==tarfile.REGTYPE:member.size=1;out.addfile(member,io.BytesIO(b'x'))
                else:member.linkname='/outside';out.addfile(member)
            if name.endswith('good'):self.assertEqual(gate.archive(path,gate.sha(path)),path)
            else:
                with self.assertRaises(ValueError):gate.archive(path,gate.sha(path))
            with self.assertRaisesRegex(ValueError,'SHA256'):gate.archive(path,'0'*64)

    def test_python39_report_save_and_exception_report(self):
        path=self.root/'saved.json'
        base.save(path,dict(error='failed build',value='中文'))
        self.assertEqual(json.loads(path.read_text(encoding='utf-8'))['error'],'failed build')
        self.assertNotIn(b'\r\n',path.read_bytes())

    @unittest.skipIf(os.name=='nt','native bash 3.2 contract is run in Actions')
    def test_shell_menu_direct_entry_and_install_cannot_bypass_gate(self):
        bash=os.environ.get('G1_TEST_BASH','/bin/bash')
        env=dict(os.environ,PYTHON=sys.executable,REPO=str(ROOT),G1_EXPECTED_COMMIT='0'*40,
                 WORK=str(self.args.work),NM_SRC=str(self.nm),NV_SRC=str(self.nv))
        folder=ROOT/'research/stock-v243-offscreen-20261021'
        for script,argv in (('g1-first-touch.command',['2']),('device-kextutil.sh',[str(ROOT),str(self.args.work)])):
            run=subprocess.run([bash,str(folder/script),*argv],env=env,capture_output=True,text=True)
            self.assertNotEqual(run.returncode,0,run.stdout+run.stderr)
            self.assertFalse(self.args.work.exists())
        for script,argv in (('g1-first-touch.command',['4']),('g1-first-touch.command',['6']),
                            ('first-touch.sh',['install']),('first-touch.sh',['rollback'])):
            run=subprocess.run([bash,str(folder/script),*argv],env=env,capture_output=True,text=True)
            self.assertEqual(run.returncode,42,run.stdout+run.stderr)
            self.assertIn('NO-GO',run.stdout)
        crlf=self.root/'crlf.command'
        crlf.write_bytes((folder/'g1-first-touch.command').read_bytes().replace(b'\n',b'\r\n'))
        run=subprocess.run([bash,str(crlf),'2'],env=env,capture_output=True,text=True)
        self.assertNotEqual(run.returncode,0)
        self.assertFalse(self.args.work.exists())


if __name__=='__main__':unittest.main()
