import importlib.util
from pathlib import Path
import unittest
from g1_symbol_identity import identity, parse_nm_undefined, source_spelling

spec = importlib.util.spec_from_file_location('classify_imports', Path(__file__).with_name('classify-imports.py'))
classifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(classifier)


class SymbolIdentityTests(unittest.TestCase):
    def test_one_abi_prefix_only(self):
        self.assertEqual(source_spelling('___nvoc_dynamicCast'), '__nvoc_dynamicCast')
        self.assertEqual(source_spelling('__f32_add'), '_f32_add')
        self.assertEqual(source_spelling('_g_pSys'), 'g_pSys')

    def test_distinct_identifiers_never_merge(self):
        symbols = ['_target', '__target', '___target']
        self.assertEqual(len({source_spelling(s) for s in symbols}), 3)

    def test_cpp_identity(self):
        self.assertEqual(identity('__ZN8OSObject7releaseEv')['source_spelling'], '_ZN8OSObject7releaseEv')
        self.assertEqual(identity('__ZN8OSObject7releaseEv')['name_kind'], 'itanium-cxx-mangled')

    def test_both_undefined_formats_and_duplicates(self):
        text = 'ARGV=["xcrun", "nm", "-u", "candidate"]\n___nvoc_dynamicCast\n U _g_pSys\n_g_pSys\n\nEXIT=0\n'
        self.assertEqual(parse_nm_undefined(text), ['___nvoc_dynamicCast', '_g_pSys', '_g_pSys'])

    def test_defined_nm_and_diagnostics_fail_closed(self):
        for text in ['0000000000000010 T _target', 'nm: error: bad file', 'archive.a(member.o):', '_ok\nbad']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse_nm_undefined(text)

    def test_wrong_command_empty_or_unprefixed_rejected(self):
        for text in ['ARGV=["nm", "-gU", "a"]\n_target', '', 'bare_name']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse_nm_undefined(text)
        with self.assertRaises(ValueError):
            source_spelling('bare_name')

    def test_failed_truncated_or_trailing_wrapped_inventory_rejected(self):
        prefix = 'ARGV=["xcrun", "nm", "-u", "candidate"]\n_target\n'
        for text in [prefix, prefix+'EXIT=1\n', prefix+'EXIT=0\n_other\n', '_target\nEXIT=0\n']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse_nm_undefined(text)

    def test_runtime_and_iokit_heuristics_preserve_spelling(self):
        self.assertEqual(classifier.classify('___cxa_pure_virtual'), 'c++ runtime')
        self.assertEqual(classifier.classify('__Znwm'), 'c++ runtime')
        self.assertEqual(classifier.classify('__ZN8OSObject7releaseEv'), 'iokit/libkern')
        self.assertEqual(classifier.classify('___nvoc_dynamicCast'), 'ogkm-rm-core')


if __name__ == '__main__':
    unittest.main()
