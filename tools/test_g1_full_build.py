"""Full-input build contracts. Synthetic headers are parser fixtures, not driver evidence."""
import copy
import json
import lzma
from pathlib import Path, PurePosixPath
import struct
import tempfile
import unittest

from g1_full_build import (BASELINE_C, BASELINE_CPP, COMPONENTS, NM_PIN, OGKM_PIN,
    archive_allowed, baseline_objects, compile_plan, darwin_command, digest,
    inventory, object_path, shader_assembly, source_list, validate_kext, validate_object)


def header(kind=1):
    return struct.pack('<8I', 0xfeedfacf, 0x01000007, 3, kind, 0, 0, 0, 0)


class FullBuildTests(unittest.TestCase):
    def test_source_list_rejects_missing_duplicates_or_unknown_make_semantics(self):
        self.assertEqual(source_list('SRCS ?=\nSRCS += a.c\nSRCS_CXX += b.cpp\n'), ['a.c', 'b.cpp'])
        for text in ['', 'SRCS += a.c\nSRCS += a.c', 'SRCS += $(wildcard *.c)',
                     'include other.mk', 'SRCS := a.c', 'SRCS += a.c b.c']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                source_list(text)

    def test_inventory_keeps_all_listed_directories_and_rejects_missing_input(self):
        with tempfile.TemporaryDirectory() as folder:
            nv = Path(folder)
            for component in COMPONENTS:
                base = nv/'src'/component
                base.mkdir(parents=True)
                (base/'srcs.mk').write_text('SRCS += generated/a.c\nSRCS += src/odd/b.c\n')
                for rel in ['generated/a.c', 'src/odd/b.c']:
                    path = base/rel
                    path.parent.mkdir(parents=True)
                    path.write_text('int real_source;\n')
            rows = inventory(nv)
            self.assertEqual([len(rows[c]) for c in COMPONENTS], [2, 2])
            self.assertEqual(rows['nvidia'][1]['source'], 'src/nvidia/src/odd/b.c')
            (nv/'src/nvidia/generated/a.c').unlink()
            with self.assertRaises(ValueError):
                inventory(nv)

    def test_official_plan_preserves_per_source_flags_and_quoted_macro(self):
        cwd = Path('/source').resolve()
        text = ('mkdir -p out\nclang -DFIRST=1 -D"VALUE=<header.h>" '+chr(92)+'\n -c a.c -o out/a.o\nclang++ -DSECOND=2 -I path -c b.cpp -o out/b.o\n')
        result = compile_plan(text, cwd, {cwd/'a.c', cwd/'b.cpp'})
        self.assertIn('-DVALUE=<header.h>', result[cwd/'a.c'])
        cmd = darwin_command(result[cwd/'b.cpp'], cwd/'b.cpp', Path('/new/b.o'), '/sdk', '/kernel')
        self.assertIn('-DSECOND=2', cmd)
        self.assertNotIn('-DFIRST=1', cmd)
        self.assertNotIn('out/b.o', cmd)
        self.assertEqual(cmd[-4:], ['-c', str(cwd/'b.cpp'), '-o', str(Path('/new/b.o'))])
        self.assertEqual(cmd[:2], ['xcrun', 'clang++'])

    def test_missing_extra_duplicate_and_shell_compiles_rejected(self):
        cwd = Path('/src').resolve()
        good = 'clang -O2 -c a.c -o a.o\n'
        for text in ['', good+good, good+'clang -c b.c -o b.o',
                     good.rstrip()+' && sed x', 'clang -c a.c -o']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                compile_plan(text, cwd, {cwd/'a.c'})

    def test_object_names_do_not_alias_same_basename(self):
        self.assertNotEqual(object_path(Path('/out'), 'nvidia', 'one/a.c'),
                            object_path(Path('/out'), 'nvidia', 'two/a.c'))

    def test_partial_failed_unhashed_or_duplicate_objects_cannot_archive(self):
        good = [{'compile_exit': 0, 'object_sha256': 'hash', 'object': 'one.o'}]
        archive_allowed(good, 1)
        for rows, count in [([], 0), (good, 2), (good*2, 2),
                            ([dict(good[0], compile_exit=1)], 1),
                            ([dict(good[0], object_sha256='')], 1)]:
            with self.assertRaises(ValueError):
                archive_allowed(rows, count)

    def test_shader_bytes_roundtrip_and_exact_symbols(self):
        raw = bytes(range(256))*8
        packed, asm = shader_assembly(raw, 'ampere', PurePosixPath('/out/ampere_shaders.xz'))
        self.assertEqual(lzma.decompress(packed), raw)
        self.assertEqual(lzma.LZMADecompressor().check, lzma.CHECK_UNKNOWN)
        decoder = lzma.LZMADecompressor()
        decoder.decompress(packed)
        self.assertEqual(decoder.check, lzma.CHECK_NONE)
        for suffix in ['start', 'end', 'size']:
            self.assertIn('.globl __binary_ampere_shaders_xz_'+suffix, asm)
        self.assertIn('.section __TEXT,__const', asm)
        for family, path in [('invented', Path('/out/a')), ('ampere', Path('/out/with space'))]:
            with self.assertRaises(ValueError):
                shader_assembly(raw, family, path)

    def test_wrong_macho_type_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)/'object.o'
            path.write_bytes(header())
            validate_object(path)
            with self.assertRaises(ValueError):
                validate_kext(path)
            path.write_bytes(header(11))
            validate_kext(path)
            with self.assertRaises(ValueError):
                validate_object(path)
            path.write_bytes(b'old binary')
            with self.assertRaises(ValueError):
                validate_object(path)

    def test_baseline_requires_exact_sources_current_hashes_and_paths(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            candidate, objroot = root/'candidate', root/'objects'
            objroot.mkdir()
            report = {'pins': {'nm': NM_PIN, 'nv': OGKM_PIN}, 'build_manifest': []}
            for index, rel in enumerate(sorted(BASELINE_CPP | BASELINE_C)):
                source = candidate/rel
                source.parent.mkdir(parents=True, exist_ok=True)
                source.write_text('int source_'+str(index)+';\n')
                obj = objroot/(str(index)+'.o')
                obj.write_bytes(header())
                report['build_manifest'].append({'role': 'nvrm-unified' if rel in BASELINE_CPP else 'candidate-c-probe',
                    'source': rel, 'source_sha256': digest(source.read_bytes()), 'object': str(obj),
                    'object_sha256': digest(obj.read_bytes()), 'compile_exit': 0})
            self.assertEqual(len(baseline_objects(report, candidate, objroot)), 11)
            for kind in ['wrong-source', 'duplicate', 'wrong-pin', 'failed', 'source-hash', 'object-hash', 'outside']:
                bad = copy.deepcopy(report)
                row = bad['build_manifest'][0]
                if kind == 'wrong-source': row['source'] = 'kexts/NVRM/other.cpp'
                if kind == 'duplicate': bad['build_manifest'].append(dict(row))
                if kind == 'wrong-pin': bad['pins']['nv'] = 'different'
                if kind == 'failed': row['compile_exit'] = 1
                if kind == 'source-hash': row['source_sha256'] = 'old'
                if kind == 'object-hash': row['object_sha256'] = 'old'
                if kind == 'outside': row['object'] = str(root/'outside.o')
                with self.subTest(kind=kind), self.assertRaises((ValueError, OSError)):
                    baseline_objects(bad, candidate, objroot)


if __name__ == '__main__':
    unittest.main()
