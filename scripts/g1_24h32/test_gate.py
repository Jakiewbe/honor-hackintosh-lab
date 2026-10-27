"""HOST ONLY: orchestration fixtures never count as native compiler evidence."""
import hashlib
import copy
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile

HERE=Path(__file__).resolve().parent
import native_gate as gate


class FakeTools:
    def __init__(self,root,mode='ok'):
        self.root=root; self.mode=mode; self.commands=[]

    def capture(self,argv,cwd,name):
        self.commands.append(argv)
        if '--show-sdk-path' in argv: return str(self.root/'sdk')
        if '--find' in argv: return str(self.root/'clang++')
        if name=='compiler-version': return 'HOST FIXTURE COMPILER - NOT DARWIN'
        if name=='xcode': return 'HOST FIXTURE XCODE - NOT DARWIN'
        if name=='sdk-version': return 'HOST FIXTURE SDK - NOT DARWIN'
        if name=='darwin-macros': return '#define NVOS_IS_LINUX '+('1' if self.mode=='linux-macro' else '0')
        if '-j' in argv:
            if 'baseline' in Path(argv[-1]).name: return '_method'+ ('\n_inherited_bad' if self.mode=='inherited-bad' else '')
            if self.mode=='inherited-bad': return '_vtable\n_inherited_bad'
            if self.mode=='linked-extra' and 'linked' in name: return '_vtable\n_unexpected_link_import'
            if self.mode=='remaining-import': return '_method\n_vtable'
            if self.mode=='unknown-import': return '_surprise'
            return '_vtable'
        return 'HOST FIXTURE DIAGNOSTIC'

    def execute(self,argv,cwd,log):
        self.commands.append(argv)
        log.write_text('HOST TEST INJECTED SERVICE\n',encoding='utf-8')
        if '-M' in argv or '-c' in argv:
            source=Path(argv[-1] if '-M' in argv else argv[argv.index('-c')+1])
            dep=Path(argv[argv.index('-MF')+1])
            dep.write_text('honor_g1_inputs: '+source.as_posix().replace(' ','\\ ')+'\n',encoding='utf-8')
            if '-M' in argv: return 0
            if self.mode=='compile-fail': return 19
            if self.mode=='missing-output': return 0
            if self.mode=='input-drift': source.write_text('changed by host fixture',encoding='utf-8')
            kind=1
        else:
            if self.mode=='link-fail': return 23
            kind=11
        obj=Path(argv[argv.index('-o')+1])
        obj.write_bytes(struct.pack('<8I',0xfeedfacf,0x01000007,3,kind,0,0,0,0))
        if self.mode=='invalid-object' and kind==1: obj.write_bytes(b'HOST INVALID OBJECT')
        return 0


class NativeGateHostTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(prefix='gate host ')
        self.root=Path(self.tmp.name); self.pkg=self.root/'package'; self.out=self.root/'run'
        self.pkg.mkdir(); self.out.mkdir()
        for name in ['sdk/System/Library/Frameworks/Kernel.framework/Headers/IOKit/IOService.h','clang++']:
            p=self.root/name; p.parent.mkdir(parents=True,exist_ok=True); p.write_text('HOST FIXTURE',encoding='utf-8')
        files={
            'inputs/nm/kexts/NVRM/accel/nvrm-accel.cpp':b'BASELINE HOST FIXTURE\n',
            'forwarder-candidate/src/kexts/NVRM/accel/nvrm-accel.cpp':b'CANDIDATE HOST FIXTURE\n',
            'PROFILE.json':json.dumps(dict(rm_definitions=['-DNV_UNIX'],rm_include_dirs=['src/common'],
                nvaccel_extra_include_dirs=[],make_include_directories_absent=[])).encode(),
            'route-proof.json':json.dumps(dict(routes=[dict(symbol='_method')],vtables=dict(v=dict(symbol='_vtable',external_section_observed=True)),collection_sha256='HOST_FIXTURE')).encode()}
        (self.pkg/'inputs/ogkm/src/common').mkdir(parents=True)
        definition=dict(collection='HOST_FIXTURE_KC',collection_sha256='HOST_SHA',
            status='KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI',n_type=15,n_sect=1,
            value=100,section=dict(ordinal=1,address=100,size=8))
        contract=dict(schema='honor.target-section-import-contract.v1',expected_imports=['_vtable'],
            collections=[dict(name='HOST_FIXTURE_KC',sha256='HOST_SHA')],
            definitions={'_vtable':[definition]},enum_renames={})
        files['target-symbols.json']=json.dumps(contract).encode()
        raw=files['forwarder-candidate/src/kexts/NVRM/accel/nvrm-accel.cpp']
        files['forwarder-candidate/MANIFEST.json']=json.dumps(dict(files=[dict(path='kexts/NVRM/accel/nvrm-accel.cpp',sha256=hashlib.sha256(raw).hexdigest())],
            target_symbol_contract_sha256=hashlib.sha256(files['target-symbols.json']).hexdigest())).encode()
        rows=[]
        for name,raw in files.items():
            p=self.pkg/name; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(raw)
            rows.append(dict(path=name,bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
        (self.pkg/'PACKAGE-MANIFEST.json').write_text(json.dumps(dict(files=rows)),encoding='utf-8')

    def tearDown(self): self.tmp.cleanup()

    def run_mode(self,mode='ok'):
        self.tools=FakeTools(self.root,mode)
        result=gate.run_gate(self.pkg,self.out,self.tools)
        self.assertTrue((self.out/'RESULT.json').is_file())
        with zipfile.ZipFile(self.out/'native-build-result.zip') as z:
            self.assertIsNone(z.testzip()); self.assertIn('RESULT.json',z.namelist())
            self.assertFalse(any(n.endswith(('.o','-NVAccel','.cpp')) for n in z.namelist()))
        self.assertFalse(result['go_authorized'])
        return result

    def test_complete_orchestration_is_host_fixture_only(self):
        r=self.run_mode(); self.assertEqual(r['status'],'OBJECT_LINK_AND_IMPORT_DELTA_PASS_NOT_GO')
        self.assertEqual(r['import_delta']['added'],['_vtable']); self.assertEqual(r['import_delta']['removed'],['_method'])
        self.assertEqual(len(r['objects']),2); self.assertEqual(len(r['links']),2)
        self.assertTrue(all('HOST FIXTURE' in v for v in [r['compiler']['version'],r['xcode']]))

    def test_missing_source_rejected_before_tools(self):
        (self.pkg/'inputs/nm/kexts/NVRM/accel/nvrm-accel.cpp').unlink()
        self.assertEqual(self.run_mode()['status'],'FAILED'); self.assertFalse(self.tools.commands)

    def test_tampered_source_rejected_before_tools(self):
        (self.pkg/'PROFILE.json').write_bytes(b'{}')
        self.assertEqual(self.run_mode()['status'],'FAILED'); self.assertFalse(self.tools.commands)

    def test_extra_input_rejected(self):
        (self.pkg/'extra').write_bytes(b'x'); self.assertEqual(self.run_mode()['status'],'FAILED')

    def test_compile_failure_preserves_evidence_and_never_links(self):
        r=self.run_mode('compile-fail'); self.assertEqual(r['status'],'FAILED')
        self.assertEqual(r['compiler_failures'],2); self.assertFalse(r['links'])

    def test_link_failure_preserves_both_results(self):
        r=self.run_mode('link-fail'); self.assertEqual(r['status'],'FAILED'); self.assertEqual([l['exit'] for l in r['links']],[23,23])

    def test_success_exit_without_object_rejected(self):
        r=self.run_mode('missing-output'); self.assertEqual(r['status'],'FAILED'); self.assertFalse(r['links'])

    def test_transitive_content_drift_rejected(self):
        r=self.run_mode('input-drift'); self.assertEqual(r['status'],'FAILED'); self.assertFalse(r['links'])
        self.assertTrue(any('input set/content changed' in e for e in r['errors']))

    def test_stale_object_not_reused(self):
        (self.out/'baseline.o').write_bytes(b'stale'); r=self.run_mode(); self.assertEqual(r['status'],'FAILED')
        self.assertTrue(any('fresh object' in e for e in r['errors']))

    def test_remaining_private_method_rejected(self):
        r=self.run_mode('remaining-import'); self.assertEqual(r['status'],'FAILED')
        self.assertEqual(r['import_delta']['methods_still_undefined'],['_method'])

    def test_unexpected_new_import_rejected(self):
        r=self.run_mode('unknown-import'); self.assertEqual(r['status'],'FAILED')
        self.assertEqual(r['import_delta']['added_without_source_provider_observation'],['_surprise'])

    def test_missing_kernel_sdk_rejected(self):
        (self.root/'sdk/System/Library/Frameworks/Kernel.framework/Headers/IOKit/IOService.h').unlink()
        r=self.run_mode(); self.assertEqual(r['status'],'FAILED'); self.assertEqual(r['missing'],1)

    def test_invalid_object_format_rejected(self):
        r=self.run_mode('invalid-object'); self.assertEqual(r['status'],'FAILED')
        self.assertTrue(any('invalid x86_64 Mach-O' in e for e in r['errors']))

    def test_malformed_manifest_still_has_result_zip(self):
        (self.pkg/'PACKAGE-MANIFEST.json').write_text('{}',encoding='utf-8')
        self.assertEqual(self.run_mode()['status'],'FAILED')

    def test_inherited_unmatched_import_rejected_even_with_clean_delta(self):
        r=self.run_mode('inherited-bad')
        self.assertEqual(r['status'],'FAILED')
        self.assertEqual(r['import_delta']['added_without_source_provider_observation'],[])
        self.assertEqual(r['target_import_observation']['unobserved'],['_inherited_bad'])

    def test_actual_linux_macro_rejected(self):
        r=self.run_mode('linux-macro'); self.assertEqual(r['status'],'FAILED')
        self.assertFalse(r['objects'])

    def test_linked_extra_import_rejected(self):
        r=self.run_mode('linked-extra'); self.assertEqual(r['status'],'FAILED')
        self.assertTrue(any('linked/object import set differs' in e for e in r['errors']))


class ImportContractTests(unittest.TestCase):
    def setUp(self):
        self.contract=dict(schema='honor.target-section-import-contract.v1',expected_imports=['_new'],
            enum_renames={'_old':'_new'},collections=[dict(name='KC',sha256='SHA')],
            definitions={'_new':[dict(collection='KC',collection_sha256='SHA',
                status='KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI',n_type=15,n_sect=1,
                value=100,section=dict(ordinal=1,address=100,size=8))]})

    def test_exact_replacement_has_same_import_count(self):
        r=gate.check_imports({'_new'},self.contract)
        self.assertTrue(r['passed']); self.assertEqual(r['actual_count'],1)
        self.assertEqual(r['full_abi'],'UNVERIFIED')

    def test_restored_typedef_signature_fails(self):
        r=gate.check_imports({'_old'},self.contract)
        self.assertFalse(r['passed']); self.assertEqual(r['old_enum_imports_retained'],['_old'])

    def test_deleted_reference_fails_expected_set(self):
        r=gate.check_imports(set(),self.contract)
        self.assertFalse(r['passed']); self.assertEqual(r['omitted'],['_new'])

    def test_unknown_inherited_name_fails(self):
        self.assertFalse(gate.check_imports({'_new','_inherited'},self.contract)['passed'])

    def test_local_or_undefined_provider_rejected(self):
        for typ in (0,1,14,31):
            c=copy.deepcopy(self.contract); c['definitions']['_new'][0]['n_type']=typ
            with self.assertRaises(ValueError): gate.check_imports({'_new'},c)

    def test_wrong_collection_identity_rejected(self):
        c=copy.deepcopy(self.contract); c['definitions']['_new'][0]['collection_sha256']='OTHER'
        with self.assertRaises(ValueError): gate.check_imports({'_new'},c)

    def test_definition_value_outside_section_rejected(self):
        c=copy.deepcopy(self.contract); c['definitions']['_new'][0]['value']=108
        with self.assertRaises(ValueError): gate.check_imports({'_new'},c)

    def test_empty_observation_rejected(self):
        c=copy.deepcopy(self.contract); c['definitions']['_new']=[]
        with self.assertRaises(ValueError): gate.check_imports({'_new'},c)


if __name__=='__main__': unittest.main()
