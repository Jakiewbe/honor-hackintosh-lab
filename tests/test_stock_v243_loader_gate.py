"""Exercise production diagnostic checks, including actual subprocess failures."""
import copy
import importlib
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/g1'))
gate=importlib.import_module('stock_v243_package')

class LoaderGateTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.products=Path(self.temp.name)/'products';self.products.mkdir()
        self.out=Path(self.temp.name)/'logs';self.out.mkdir()
        for name in gate.SPECS:
            contents=self.products/(name+'.kext')/'Contents';(contents/'MacOS').mkdir(parents=True)
            (contents/'MacOS'/name).write_bytes(b'IDENTITY_FIXTURE_NOT_EXECUTED')
            (contents/'Info.plist').write_bytes(plistlib.dumps(dict(CFBundleExecutable=name,CFBundleIdentifier='test.'+name)))
        self.expected={n:gate.bundle_identity(self.products/(n+'.kext')) for n in gate.SPECS}
        self.records={n:dict(exit=0,unresolved=[],**r) for n,r in self.expected.items()}

    def runner(self, rc=0, message=''):
        def run(argv,cwd,log):
            self.assertEqual(argv[:3],['xcrun','kextutil','-n'])
            self.assertEqual(Path(argv[3]).parent,self.products.resolve())
            return gate.base.run([sys.executable,'-c','import sys;print('+repr(message)+');sys.exit('+str(rc)+')'],cwd,log)
        return run

    def test_success_is_only_diagnostic_acceptance(self):
        records,result=gate.loader_diagnostics(self.products,self.out,runner=self.runner())
        self.assertEqual(set(records),set(gate.SPECS))
        self.assertEqual(result['loader_acceptance'],'UNVERIFIED')
        self.assertEqual(result['exclusive_candidate_dependency_binding'],'UNVERIFIED')

    def test_actual_subprocess_exit_failure_rejected_and_preserved(self):
        records={}
        with self.assertRaisesRegex(ValueError,'diagnostic failed'):
            gate.loader_diagnostics(self.products,self.out,records,runner=self.runner(7))
        self.assertEqual(records['NVAccel']['exit'],7)
        self.assertIn('EXIT=7',(self.out/'NVAccel-kextutil.txt').read_text())

    def test_actual_subprocess_unresolved_with_zero_exit_rejected(self):
        for message in ("can't resolve symbol _x",'Undefined symbol: _x','UNRESOLVED dependency'):
            with self.subTest(message=message),self.assertRaisesRegex(ValueError,'diagnostic failed'):
                gate.loader_diagnostics(self.products,self.out,runner=self.runner(0,message))

    def test_missing_and_extra_run_rejected(self):
        for records in ({n:r for n,r in self.records.items() if n!='NVAccel'},dict(self.records,extra=self.records['NVAccel'])):
            with self.assertRaisesRegex(ValueError,'inventory'):
                gate.accept_loader_diagnostics(records,self.expected)

    def test_unknown_or_boolean_exit_is_not_zero(self):
        for value in (None,False,'0',-1):
            records=copy.deepcopy(self.records);records['NVRM']['exit']=value
            with self.assertRaises(ValueError):gate.accept_loader_diagnostics(records,self.expected)

    def test_foreign_candidate_identity_rejected(self):
        for key in ('bundle','executable','bundle_sha256','plist_sha256','bundle_id'):
            records=copy.deepcopy(self.records);records['NVAccel'][key]='FOREIGN'
            with self.subTest(key=key),self.assertRaisesRegex(ValueError,'identity differs'):
                gate.accept_loader_diagnostics(records,self.expected)

    def test_missing_executable_rejected_before_tool(self):
        (self.products/'NVAccel.kext/Contents/MacOS/NVAccel').unlink()
        with patch.object(gate.base,'run') as runner,self.assertRaises(FileNotFoundError):
            gate.loader_diagnostics(self.products,self.out)
        runner.assert_not_called()

    def test_plist_mutation_during_tool_rejected(self):
        def runner(argv,cwd,log):
            gate._add_missing_dependency(Path(argv[3]));log.write_text('EXIT=0');return 0
        with self.assertRaisesRegex(ValueError,'candidate changed'):
            gate.loader_diagnostics(self.products,self.out,runner=runner)

    def test_replacement_before_tool_differs_from_compiled_inventory(self):
        bindings={n:dict(sha256=r['bundle_sha256'],plist_sha256=r['plist_sha256']) for n,r in self.expected.items()}
        (self.products/'NVRM.kext/Contents/MacOS/NVRM').write_bytes(b'REPLACED')
        with patch.object(gate.base,'run') as runner,self.assertRaisesRegex(ValueError,'compiled bundle'):
            gate.loader_diagnostics(self.products,self.out,bindings=bindings)
        runner.assert_not_called()

    def test_undeclared_local_definition_not_accepted(self):
        family={'f':dict(info=None,definitions=[],local_definitions=['_s'])}
        self.assertEqual(gate.audit_imports(['_s'],{},dict(SymbolsSets=[]),set(),family,{})['unresolved'],['_s'])

    def test_vtable_target_does_not_resolve_external_import(self):
        with patch.object(gate,'VTABLE_HELPERS',{'_s':322}):
            result=gate.audit_imports(['_s'],{},dict(SymbolsSets=[]),set(),{},{});
        self.assertEqual(result['unresolved'],['_s'])

    def test_pass_prefix_does_not_accept_unknown_status(self):
        self.assertFalse(gate.accepted_status(gate.PASS+'_UNREVIEWED'))
        self.assertTrue(gate.accepted_status(gate.static_status({})))
        self.assertIn('LOCAL_ONLY',gate.static_status(dict(local_only_imports={'NVAccel':['_s']})))
        self.assertTrue(gate.static_status({}).endswith('_KEXTUTIL_INFORMATIONAL_ONLY'))

    def test_unused_missing_dependency_is_rejected_by_production_checker(self):
        bundle=self.products/'NVAccel.kext'
        gate._add_missing_dependency(bundle)
        info=plistlib.loads((bundle/'Contents/Info.plist').read_bytes())
        with self.assertRaisesRegex(ValueError,'DEPENDENCY_ABSENT'):
            gate.accept_declared_dependencies(info['OSBundleLibraries'],dict(SymbolsSets=[]),{})

    def test_missing_family_version_stays_unverified(self):
        result=gate.accept_declared_dependencies({'f':'1.0'},dict(SymbolsSets=[]),
            {'f':dict(info=None,present_in_collection=True)})
        self.assertEqual(result['unverified'][0]['status'],'IDENTITY_OBSERVED_VERSION_UNVERIFIED')
        with self.assertRaises(ValueError):
            gate.accept_declared_dependencies({'f':'1.0'},dict(SymbolsSets=[]),
                {'f':dict(info=None,present_in_collection=False)})

if __name__=='__main__':unittest.main()
