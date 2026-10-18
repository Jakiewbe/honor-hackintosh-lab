#!/usr/bin/env python3
"""Parser/action-isolation contracts; synthetic IR never represents driver evidence."""
import copy
from pathlib import Path
import tempfile
import unittest

from g1_rm_abi import (TABLE,CPP_PROFILES,RM_SOURCES,altstack_conflicts,compare_layouts,diagnostic_base,
                      first_argument_end,layout_expressions,parse_layout,source_audit,wrapper)


def ir(values=None,triple='x86_64-apple-macosx15.5.0'):
    values=values if values is not None else list(range(1,len(layout_expressions())+1))
    return f'target triple = "{triple}"\n@{TABLE} = global [{len(values)} x i64] ['+', '.join(f'i64 {v}' for v in values)+'], align 16\n'


class AbiTests(unittest.TestCase):
    def test_exact_numeric_table(self):
        triple,values=parse_layout(ir())
        self.assertEqual(triple,'x86_64-apple-macosx15.5.0')
        self.assertEqual(list(values),[x[0] for x in layout_expressions()])
        self.assertEqual(values['nv_state_t.sizeof'],1)

    def test_missing_duplicate_and_short_tables_rejected(self):
        for text in ['target triple = "x86_64-apple-darwin"\n',ir()+ir(),ir([1])]:
            with self.subTest(text=text[:70]),self.assertRaises(ValueError):
                parse_layout(text)

    def test_wrong_target_and_unresolved_values_rejected(self):
        for text in [ir(triple='x86_64-unknown-linux-gnu'),ir().replace('i64 1,','i64 undef,',1)]:
            with self.assertRaises(ValueError):
                parse_layout(text)

    def test_flags_preserved_and_dependency_outputs_removed(self):
        source=Path('sample.cpp')
        argv=['xcrun','clang++','-DNV_LINUX','-DNV_UNIX','-I/some/include','-O2','-MMD','-MF','old.d','-c',str(source),'-o','old.o']
        before=list(argv)
        base,removed=diagnostic_base(argv,source)
        self.assertEqual(argv,before)
        self.assertEqual(base,['xcrun','clang++','-DNV_LINUX','-DNV_UNIX','-I/some/include','-O2'])
        self.assertEqual(removed,['-MMD','-MF','old.d','-c',str(source),'-o','old.o'])

    def test_wrong_source_response_file_and_existing_action_rejected(self):
        for argv in [
            ['xcrun','clang','-c','wrong.c','-o','x.o'],
            ['xcrun','clang','@flags','-c','sample.c','-o','x.o'],
            ['xcrun','clang','-E','-c','sample.c','-o','x.o']]:
            with self.assertRaises(ValueError):
                diagnostic_base(argv,Path('sample.c'))

    def test_wrapper_includes_unchanged_complete_source_without_macros(self):
        with tempfile.TemporaryDirectory() as folder:
            source=Path(folder)/'source.cpp'
            source.write_text('int original;\n')
            before=source.read_bytes()
            generated=wrapper(source)
            self.assertIn('#include "'+source.resolve().as_posix()+'"',generated)
            self.assertNotIn('#define',generated)
            self.assertEqual(source.read_bytes(),before)
            source.write_text('int '+TABLE+';')
            with self.assertRaises(ValueError):
                wrapper(source)

    def test_compare_reports_specific_field_differences(self):
        _,values=parse_layout(ir())
        profiles=['probe-'+rel.replace('/','_') for rel in RM_SOURCES]+[x[0] for x in CPP_PROFILES]
        units=[{'profile':name,'layout':dict(values)} for name in profiles]
        self.assertEqual(compare_layouts(units)['status'],'SELECTED_LAYOUT_MATCH')
        units[-1]['layout']['nv_state_t.gpu_id.offset']+=8
        result=compare_layouts(units)
        self.assertEqual(result['status'],'SELECTED_LAYOUT_MISMATCH')
        self.assertEqual([x['key'] for x in result['differences']],['nv_state_t.gpu_id.offset'])

    def test_missing_or_duplicate_profiles_never_match(self):
        _,values=parse_layout(ir())
        profiles=['probe-'+rel.replace('/','_') for rel in RM_SOURCES]+[x[0] for x in CPP_PROFILES]
        units=[{'profile':name,'layout':dict(values)} for name in profiles]
        self.assertEqual(compare_layouts(units[:-1])['status'],'INCOMPLETE')
        units[-1]=copy.deepcopy(units[0])
        self.assertEqual(compare_layouts(units)['status'],'INCOMPLETE')

    def test_nested_commas_do_not_split_first_argument(self):
        text='f((a,b), c)'
        end=first_argument_end(text,1,len(text)-1)
        self.assertEqual(text[2:end],'(a,b)')

    def test_altstack_conflict_requires_matching_provider_and_null_caller(self):
        profiles=['probe-'+rel.replace('/','_') for rel in RM_SOURCES]
        units=[{'profile':p,'altstack_defined':i==0} for i,p in enumerate(profiles)]
        audit={'runtime_targets':[{'name':'rm_a','path':RM_SOURCES[0]},{'name':'rm_b','path':RM_SOURCES[1]}],
               'occurrences':[{'name':'rm_b','literal_null':True}]}
        self.assertEqual(altstack_conflicts(units,audit),[])
        audit['occurrences'].append({'name':'rm_a','literal_null':True})
        result=altstack_conflicts(units,audit)
        self.assertEqual(result,[{'profile':profiles[0],'symbols_with_literal_null_calls':['rm_a']}])

    def test_source_audit_retains_all_hits_and_ignores_comments(self):
        with tempfile.TemporaryDirectory() as folder:
            nv=Path(folder)/'nv';nm=Path(folder)/'nm'
            for rel in RM_SOURCES:
                path=nv/rel;path.parent.mkdir(parents=True,exist_ok=True)
                path.write_text('int rm_test(void *sp) { NV_ENTER_RM_RUNTIME(sp,fp); return 0; }\n')
            path=nm/'kexts/NVRM/test.cpp';path.parent.mkdir(parents=True)
            path.write_text('// rm_test(NULL);\nvoid run() { rm_test(NULL); rm_test((a,b)); rm_test(nullptr); }\n')
            result=source_audit(nv,nm,{'rm_test'})
            self.assertEqual(len(result['runtime_targets']),3)
            self.assertEqual(len(result['occurrences']),3)
            self.assertEqual(result['literal_null_count'],2)
            self.assertEqual(result['occurrences'][1]['first_argument'],'(a,b)')
            self.assertEqual(len(result['manifest']),1)


if __name__=='__main__':
    unittest.main()
