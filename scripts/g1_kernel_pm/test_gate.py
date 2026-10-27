"""Labelled host orchestration controls; synthetic Mach-O is NEVER native evidence."""
import copy
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

import gate

class HostOnlyTools:
    def __init__(self,sdk,case):self.sdk=sdk;self.case=case;self.calls=[]
    def capture(self,argv,cwd,name):
        self.calls.append(argv)
        if name=='sdk':return str(self.sdk)
        if name=='sdk-version':return '15.5'
        if name=='compiler-path':return '/HOST_FIXTURE/clang++'
        if name.endswith('-macros'):return '#define NVOS_IS_LINUX 1\n' if self.case=='linux' else '#define NVOS_IS_LINUX 0\n'
        if name.endswith('-undefined'):
            return '_expected_provider\n_extra\n' if self.case=='import-drift' and name=='candidate-undefined' else '_expected_provider\n'
        return 'HOST_FIXTURE_NOT_DARWIN'
    def execute(self,argv,cwd,log):
        self.calls.append(argv);log.write_text('HOST_FIXTURE_NOT_DARWIN\n')
        if self.case=='link-fail':return 1
        Path(argv[argv.index('-o')+1]).write_bytes(struct.pack('<8I',0xfeedfacf,0x01000007,0,11,0,0,0,0))
        return 0

class OrchestrationControls(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name)
        self.workspace=self.root/'workspace';self.out=self.root/'text';self.out.mkdir()
        self.sdk=self.root/'sdk';(self.sdk/'System/Library/Frameworks/Kernel.framework/Headers/IOKit').mkdir(parents=True)
        (self.sdk/'System/Library/Frameworks/Kernel.framework/Headers/IOKit/IOService.h').write_text('HOST')
        for name in ('nm','candidate'):
            p=self.workspace/name/gate.REL;p.parent.mkdir(parents=True);p.write_text(name)
        (self.workspace/'INPUTS.json').write_text(json.dumps(dict(source_files={'nm':0,'ogkm':0})))
        self.m=dict(baseline_sha256={gate.REL:gate.sha(self.workspace/'nm'/gate.REL)},
                    files=[dict(path=gate.REL,sha256=gate.sha(self.workspace/'candidate'/gate.REL))])
    def tearDown(self):self.tmp.cleanup()
    def exercise(self,case='success'):
        tools=HostOnlyTools(self.sdk,case)
        def bound(argv,tree,log,dep,execute):
            log.write_text('HOST_FIXTURE_NOT_DARWIN\n')
            rc=1 if case=='compile-fail' else 0
            if case!='missing-object':Path(argv[-1]).write_bytes(struct.pack('<8I',0xfeedfacf,0x01000007,0,1,0,0,0,0))
            dep.mkdir();p=dep/'snapshot.json'
            row=dict(resolved_path=str((tree/gate.REL).resolve()),sha256=gate.sha(tree/gate.REL))
            if case=='wrong-source':row['sha256']='0'*64
            p.write_text(json.dumps(dict(inputs=[] if case=='missing-source' else [row])))
            return rc,dict(path=str(p),sha256=gate.sha(p)),argv
        with patch.object(gate,'verify_inputs'),patch.object(gate,'patch_manifest',return_value=self.m),\
             patch.object(gate,'config',return_value=(dict(rm_definitions=[],make_include_directories_absent=[]),[])),\
             patch.object(gate,'bound_compile',side_effect=bound):
            result=gate.run(self.workspace,self.out,tools)
        return result,tools
    def rejected(self,case):
        r,_=self.exercise(case);self.assertEqual(r['status'],'FAILED');self.assertFalse(gate.complete(r));self.assertTrue(r['errors'])
        expected={'compile-fail':'actual TU compilation failed','missing-object':'baseline.o',
            'missing-source':'actual compiler did not see reviewed PM bytes','wrong-source':'actual compiler did not see reviewed PM bytes',
            'link-fail':'kext format link failed','linux':'Darwin preprocess selects Linux',
            'import-drift':'unexpected import change'}
        self.assertIn(expected[case],'\n'.join(r['errors']))
        self.assertTrue((self.out/'native-pm-text.zip').is_file())
    def test_labelled_host_fixture_only_reaches_format_status(self):
        r,t=self.exercise();self.assertTrue(gate.complete(r));self.assertEqual(r['complete_driver_link'],'NOT_ATTEMPTED')
        self.assertEqual(r['rm_admission_denial'],'NOT_IMPLEMENTED_BY_THIS_PATCH');self.assertFalse(r['go_authorized'])
        self.assertTrue(all('dynamic_lookup' not in a for c in t.calls for a in c))
    def test_compile_failure_keeps_failed_report(self):self.rejected('compile-fail')
    def test_missing_object_after_zero_exit_is_rejected(self):self.rejected('missing-object')
    def test_missing_actual_source_dependency_is_rejected(self):self.rejected('missing-source')
    def test_wrong_source_dependency_hash_is_rejected(self):self.rejected('wrong-source')
    def test_native_link_failure_is_rejected(self):self.rejected('link-fail')
    def test_linux_preprocessing_is_rejected(self):self.rejected('linux')
    def test_changed_imports_are_rejected(self):self.rejected('import-drift')
    def test_missing_candidate_is_not_success(self):
        r,_=self.exercise();r['objects'].pop();self.assertFalse(gate.complete(r))
    def test_missing_link_is_not_success(self):
        r,_=self.exercise();r['format_links'].pop();self.assertFalse(gate.complete(r))
    def test_unbound_source_is_not_success(self):
        r,_=self.exercise();r['objects'][1]['source_bound']=False;self.assertFalse(gate.complete(r))
    def test_duplicate_label_is_not_success(self):
        r,_=self.exercise();r['objects'][1]['label']='baseline';self.assertFalse(gate.complete(r))
    def test_archive_contains_text_only(self):
        import zipfile
        self.exercise()
        with zipfile.ZipFile(self.out/'native-pm-text.zip') as z:
            self.assertTrue(z.namelist());self.assertTrue(all(Path(n).suffix in ('.json','.txt','.d') for n in z.namelist()))

class IdentityControls(unittest.TestCase):
    def test_real_patch_manifest_identity(self):
        self.assertEqual([r['path'] for r in gate.patch_manifest()['files']],[gate.REL])
    def test_tampered_patch_rejected_without_editing_shared_profile(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            for n in ('pm.patch','pm-manifest.json'):(root/n).write_bytes((gate.PM/n).read_bytes())
            (root/'pm.patch').write_bytes((root/'pm.patch').read_bytes()+b'bad')
            with patch.object(gate,'PM',root),self.assertRaises(ValueError):gate.patch_manifest()
    def test_unchanged_darwin_configuration_has_no_nv_linux(self):
        p,_=gate.config();self.assertFalse(p['nv_linux_injected'])

if __name__=='__main__':unittest.main()
