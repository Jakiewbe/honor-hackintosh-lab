"""Synthetic compiler-service fixtures; never driver compilation evidence."""
import json
from pathlib import Path
import tempfile
import unittest

from g1_compile_inputs import (TARGET, bound_compile, check_inputs, command_with_dependencies,
    dep_paths, file_inputs, verify_diagnostic_dependencies, verify_snapshot)


def dependency_text(paths):
    def escape(p):
        return str(p).replace('\\','/').replace('$','$$').replace('#','\\#').replace(' ','\\ ')
    return TARGET+': '+(' '+chr(92)+'\n ').join(escape(p) for p in paths)+'\n'


def fixture_compiler(inputs, object_data=b'synthetic fixture object', mutate=None, rc=0):
    def execute(argv, cwd, log):
        log.write_text('ARGV='+json.dumps(argv)+'\nEXIT='+str(rc)+'\n', encoding='utf-8')
        if rc: return rc
        Path(argv[argv.index('-MF')+1]).write_text(dependency_text(inputs), encoding='utf-8')
        if '-c' in argv:
            Path(argv[-1]).write_bytes(object_data)
            if mutate: mutate()
        return 0
    return execute


class CompileInputTests(unittest.TestCase):
    def fixture(self, root):
        source, header = root/'a.cpp', root/'indirect.h'
        source.write_text('#include "indirect.h"\n')
        header.write_text('long rm_select(int);\n')
        obj, directory = root/'a.o', root/'inputs'
        argv = ['xcrun','clang++','-I','relative/include','-c',str(source),'-o',str(obj)]
        return source, header, obj, directory, argv

    def test_make_escaping_system_headers_and_continuation(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            paths = [root/'main.cpp', root/'SDK path'/'sys#name$.h']
            self.assertEqual(dep_paths(dependency_text(paths), root), sorted(paths,key=str))
            for text in [TARGET+':', 'other: a.h', TARGET+': a.h\nother: b.h',
                         TARGET+': $(HEADERS)', TARGET+': a#b.h']:
                with self.assertRaises(ValueError): dep_paths(text, root)
            self.assertEqual(dep_paths(TARGET+': a.h ./a.h a.h',root),[root/'a.h'])

    def test_md_keeps_system_headers_and_preserves_original_arguments(self):
        argv = ['xcrun','clang','-I','same','-c','src.c','-o','obj.o']
        actual = command_with_dependencies(argv, Path('/new/file.d'))
        self.assertIn('-MD', actual)
        self.assertNotIn('-MMD', actual)
        self.assertEqual(actual[-4:], argv[-4:])
        for extra in ['-MMD','-MFold','@old.rsp','-Wp,-MD,old.d']:
            with self.assertRaises(ValueError): command_with_dependencies(argv[:2]+[extra]+argv[2:], Path('/x'))

    def test_real_clang_parent_spelling_aliases_preserve_physical_identity(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp).resolve()
            child=root/'headers/child';child.mkdir(parents=True)
            direct=root/'headers/nvtiming.h';direct.write_text('same real input')
            spelled=child/'../nvtiming.h'
            paths=dep_paths(dependency_text([direct,spelled]),root)
            self.assertEqual(len(paths),2)
            records=file_inputs(paths)
            self.assertEqual(len({r['resolved_path'] for r in records}),1)
            self.assertEqual(len({r['sha256'] for r in records}),1)
            check_inputs(records)
            direct.write_text('changed')
            with self.assertRaises(ValueError): check_inputs(records)

    def test_header_only_change_is_rejected_with_source_and_object_unchanged(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, header, obj, directory, argv = self.fixture(root)
            rc, descriptor, actual = bound_compile(argv, root, root/'compile.txt', directory,
                fixture_compiler([source,header]))
            self.assertEqual(rc,0)
            from g1_compile_inputs import sha
            source_hash, object_hash = sha(source), sha(obj)
            verify_snapshot(descriptor,directory,source,obj,object_hash,actual)
            header.write_text('int rm_select(int);\n')
            self.assertEqual((sha(source),sha(obj)),(source_hash,object_hash))
            with self.assertRaisesRegex(ValueError,'transitive input changed'):
                verify_snapshot(descriptor,directory,source,obj,object_hash,actual)

    def test_persistent_change_during_compile_never_gets_snapshot(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, header, obj, directory, argv = self.fixture(root)
            with self.assertRaisesRegex(ValueError,'changed during'):
                bound_compile(argv,root,root/'compile.txt',directory,
                    fixture_compiler([source,header],mutate=lambda:header.write_text('changed')))
            self.assertFalse((directory/'a.json').exists())

    def test_missing_snapshot_dependency_rule_or_changed_argv_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, header, obj, directory, argv = self.fixture(root)
            _, descriptor, actual = bound_compile(argv,root,root/'compile.txt',directory,fixture_compiler([source,header]))
            from g1_compile_inputs import sha
            for bad in [None,dict(descriptor,sha256='old'),dict(descriptor,path=str(root/'old.json'))]:
                with self.assertRaises(ValueError): verify_snapshot(bad,directory,source,obj,sha(obj),actual)
            with self.assertRaises(ValueError): verify_snapshot(descriptor,directory,source,obj,sha(obj),actual+['-DOTHER'])
            (directory/'a.d').write_text(dependency_text([source]))
            with self.assertRaises(ValueError): verify_snapshot(descriptor,directory,source,obj,sha(obj),actual)

    def test_wrapper_must_use_exact_original_dependencies_plus_itself(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, header, obj, directory, argv = self.fixture(root)
            _, descriptor, actual = bound_compile(argv,root,root/'compile.txt',directory,fixture_compiler([source,header]))
            from g1_compile_inputs import sha
            record = verify_snapshot(descriptor,directory,source,obj,sha(obj),actual)
            wrapper = root/'wrapper.cpp'; wrapper.write_text('// diagnostic')
            dep = root/'wrapper.d'; dep.write_text(dependency_text([source,header,wrapper]))
            verify_diagnostic_dependencies(dep,root,record,wrapper)
            for paths in [[source,wrapper],[source,header,wrapper,root/'new.h']]:
                dep.write_text(dependency_text(paths))
                with self.assertRaises(ValueError): verify_diagnostic_dependencies(dep,root,record,wrapper)
            dep.write_text(dependency_text([source,header,wrapper]))
            header.write_text('changed')
            with self.assertRaises(ValueError): verify_diagnostic_dependencies(dep,root,record,wrapper)

    def test_failed_compiler_and_stale_outputs_never_produce_acceptance(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, header, obj, directory, argv = self.fixture(root)
            with self.assertRaisesRegex(ValueError,'discovery failed'):
                bound_compile(argv,root,root/'compile.txt',directory,fixture_compiler([source,header],rc=1))
            obj.write_bytes(b'old')
            with self.assertRaisesRegex(ValueError,'fresh'):
                bound_compile(argv,root,root/'compile.txt',directory,fixture_compiler([source,header]))

    def test_symlink_retarget_same_contents_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            one,two,link = root/'one.h',root/'two.h',root/'link.h'
            one.write_text('same');two.write_text('same')
            try: link.symlink_to(one)
            except OSError: self.skipTest('host has no symlink privilege; Darwin CI executes this control')
            records = file_inputs([link])
            link.unlink();link.symlink_to(two)
            with self.assertRaises(ValueError): check_inputs(records)

    def test_compile_source_and_object_through_directory_alias_are_canonical(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            actual,alias = root/'actual',root/'alias'
            actual.mkdir()
            try: alias.symlink_to(actual,target_is_directory=True)
            except OSError: self.skipTest('host has no directory symlink privilege; Darwin CI executes this control')
            source, header, obj, directory, argv = self.fixture(alias)
            _,descriptor,command = bound_compile(argv,alias,actual/'compile.txt',directory,fixture_compiler([source,header]))
            from g1_compile_inputs import sha
            record=verify_snapshot(descriptor,directory,source,obj,sha(obj),command)
            self.assertEqual(record['source'],str(source.resolve()))
            self.assertEqual(record['object'],str(obj.resolve()))


if __name__ == '__main__': unittest.main()
