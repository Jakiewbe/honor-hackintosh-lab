"""ABI parser and current-run binding rejection tests; synthetic headers are fixtures."""
import copy
import json
from pathlib import Path
import struct
import tempfile
import unittest

from g1_full_abi import (PREFIX, RETAIN, compare_signatures, full_wrapper, function_record,
    parameter_abi, profiles, rm_profile, signatures, split_parameters, successful_argv)
from g1_full_build import darwin_command
from g1_rm_abi import (CPP_PROFILES, RM_SOURCES, altstack_conflicts, compare_layouts,
    layout_expressions, sha)


class FullAbiTests(unittest.TestCase):
    def test_actual_clang_style_return_range_is_not_a_calling_convention_difference(self):
        provider = ('define zeroext range(i8 0, 2) i8 @rm_a(ptr nocapture noundef readnone %0, '
                    'i32 noundef %1) local_unnamed_addr #0 {\n ret i8 1\n}\n')
        caller = 'declare zeroext i8 @rm_a(ptr noundef, i32 noundef) local_unnamed_addr #2\n'
        self.assertEqual(function_record(provider, 'rm_a')['abi'], function_record(caller, 'rm_a')['abi'])
        self.assertEqual(function_record(provider, 'rm_a')['kind'], 'define')
        with self.assertRaises(ValueError):
            function_record(caller, 'rm_a', require_definition=True)

    def test_extension_calling_convention_and_width_are_preserved(self):
        text = 'declare signext i8 @rm_a(ptr, i32 zeroext)\n'
        base = function_record(text, 'rm_a')['abi']
        for changed in [text.replace('signext', 'zeroext'), text.replace('i32 zeroext', 'i64 zeroext'),
                        text.replace('signext i8', 'fastcc signext i8'), text.replace('i32 zeroext', 'i32 signext')]:
            self.assertNotEqual(base, function_record(changed, 'rm_a')['abi'])

    def test_unknown_abi_types_or_attributes_never_silently_match(self):
        for param in ['ptr byval(%struct.x) align 8 %0', 'ptr sret(%struct.x) %0',
                      '{ i32, i64 } %0', 'float %0', 'ptr invented %0']:
            with self.subTest(param=param), self.assertRaises(ValueError):
                parameter_abi(param)
        for text in ['define internal i32 @rm_a() {\nret i32 0\n}\n',
                     'declare float @rm_a()\n']:
            with self.assertRaises(ValueError): function_record(text, 'rm_a')

    def test_function_scope_is_exact_and_stack_asm_is_visible(self):
        text = ('define i32 @rm_a(ptr %0) #0 {\ncall void asm sideeffect "movq $0,%rbp", "r"(ptr %0)\nret i32 0\n}\n'
                'define internal void @rm_a.cold.1() {\nret void\n}\n')
        record = function_record(text, 'rm_a', require_definition=True)
        self.assertEqual(len(record['direct_stack_register_asm']), 1)
        for bad in [text+text, text.split('\n}')[0], 'declare i32 @rm_b(ptr)\n']:
            with self.assertRaises(ValueError): function_record(bad, 'rm_a')

    def test_parameter_nesting_variadic_and_marker_identity(self):
        self.assertEqual(split_parameters('ptr, ptr byval({i32, i64}), i32'), ['ptr', 'ptr byval({i32, i64})', 'i32'])
        text = '@'+RETAIN+'rm_a = global ptr @rm_a, align 8\ndeclare i32 @rm_a(ptr, ...)\n'
        self.assertTrue(signatures(text, ['rm_a'])['rm_a']['abi']['variadic'])
        for bad in [text.replace('@rm_a,', '@rm_b,'), text+text, text.split('\n', 1)[1]]:
            with self.assertRaises(ValueError): signatures(bad, ['rm_a'])

    def test_wrapper_uses_real_typeof_no_redeclared_function_or_flag(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)/'source.c'
            path.write_text('int real_input;\n')
            raw = path.read_bytes()
            text = full_wrapper(path, ['rm_a', 'rm_b'])
            self.assertEqual(path.read_bytes(), raw)
            self.assertIn('__typeof__(&rm_a)', text)
            self.assertNotIn('#define', text)
            self.assertNotIn('rm_a(', text)
            for targets in [[], ['rm_a', 'rm_a'], ['not-rm']]:
                with self.assertRaises(ValueError): full_wrapper(path, targets)

    def test_full_profiles_cannot_accidentally_compare_as_probe_profiles(self):
        values = {key: 1 for key, _ in layout_expressions()}
        units = [{'profile': PREFIX+r.replace('/', '_'), 'layout': values} for r in RM_SOURCES]
        units += [{'profile': name, 'layout': values} for name, _ in CPP_PROFILES]
        self.assertEqual(compare_layouts(units)['status'], 'INCOMPLETE')
        self.assertEqual(compare_layouts(units, rm_prefix=PREFIX)['status'], 'SELECTED_LAYOUT_MATCH')
        units[0]['altstack_defined'] = True
        audit = {'runtime_targets': [{'path': RM_SOURCES[0], 'name': 'rm_a'}],
                 'occurrences': [{'name': 'rm_a', 'literal_null': True}]}
        self.assertEqual(len(altstack_conflicts(units, audit, rm_prefix=PREFIX)), 1)

    def test_signature_mismatch_missing_profile_and_definition_rejected(self):
        audit = {'runtime_targets': [{'path': RM_SOURCES[0], 'name': 'rm_a'}]}
        names = [PREFIX+r.replace('/', '_') for r in RM_SOURCES]+[name for name, _ in CPP_PROFILES]
        proto = function_record('declare i32 @rm_a(ptr)\n', 'rm_a')
        units = [{'profile': name, 'signatures': {'rm_a': copy.deepcopy(proto)}} for name in names]
        units[0]['signatures']['rm_a']['kind'] = 'define'
        self.assertEqual(compare_signatures(units, audit)['status'], 'SELECTED_SIGNATURE_MATCH')
        self.assertEqual(compare_signatures(units[:-1], audit)['status'], 'INCOMPLETE')
        units[-1]['signatures']['rm_a']['abi']['return_type'] = 'i64'
        self.assertEqual(compare_signatures(units, audit)['status'], 'SELECTED_SIGNATURE_MISMATCH')
        units[0]['signatures']['rm_a']['kind'] = 'declare'
        with self.assertRaises(ValueError): compare_signatures(units, audit)

    def test_compile_log_requires_complete_unique_success(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)/'compile.txt'
            good = 'ARGV=["xcrun", "clang", "-c", "a.c", "-o", "a.o"]\nEXIT=0\n'
            path.write_text(good)
            self.assertEqual(successful_argv(path)[-1], 'a.o')
            for bad in [good.replace('EXIT=0', 'EXIT=1'), good+'EXIT=0\n',
                        good.replace('EXIT=0', ''), good+'error: after success\n']:
                path.write_text(bad)
                with self.assertRaises(ValueError): successful_argv(path)

    def test_rm_recipe_binds_cwd_flags_source_object_log_and_no_probe_fallback(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            nv, full, sdk = root/'nv', root/'full', root/'sdk'
            source = nv/RM_SOURCES[0]
            source.parent.mkdir(parents=True)
            source.write_text('int real_input;\n')
            obj = full/'objects/current.o'
            obj.parent.mkdir(parents=True)
            obj.write_bytes(struct.pack('<8I', 0xfeedfacf, 0x01000007, 3, 1, 0, 0, 0, 0))
            cwd = (nv/'src/nvidia').resolve()
            official = ['clang', '-I', 'relative/include', '-DKEEP=1', '-c', 'arch/nvalloc/unix/src/unix_intr.c', '-o', 'ignored.o']
            argv = darwin_command(official, source, obj, sdk, sdk/'System/Library/Frameworks/Kernel.framework/Headers')
            row = {'source': RM_SOURCES[0], 'source_sha256': sha(source), 'component': 'nvidia',
                'object': str(obj), 'object_sha256': sha(obj), 'compile_exit': 0,
                'compile_cwd': str(cwd), 'official_argv': official, 'candidate_argv': argv, 'log': 'compile.txt'}
            log = full/'compile.txt'
            log.write_text('ARGV='+json.dumps(argv)+'\nEXIT=0\n')
            item = rm_profile(row, nv, full, sdk)
            self.assertEqual(item['cwd'], cwd)
            self.assertEqual(item['argv'], argv)
            for key, value in [('compile_cwd', str(nv)), ('compile_exit', 1),
                    ('source_sha256', 'old'), ('object_sha256', 'old'), ('object', str(root/'old.o')),
                    ('log', '../old.txt'), ('candidate_argv', argv[:-2]+['different.o'])]:
                bad = copy.deepcopy(row); bad[key] = value
                with self.subTest(key=key), self.assertRaises((ValueError, OSError)):
                    rm_profile(bad, nv, full, sdk)
            log.write_text('ARGV='+json.dumps(argv+['-DOTHER=1'])+'\nEXIT=0\n')
            with self.assertRaises(ValueError): rm_profile(row, nv, full, sdk)

    def test_report_from_other_run_directory_is_rejected_before_read(self):
        with self.assertRaises(ValueError):
            profiles(Path('/nv'), Path('/nm'), Path('/this/run'), Path('/old/run/full-source/report.json'))


if __name__ == '__main__':
    unittest.main()
