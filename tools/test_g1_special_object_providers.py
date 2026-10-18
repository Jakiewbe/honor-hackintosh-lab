import hashlib
from pathlib import Path
import struct
import tempfile
import unittest
from g1_dependency_audit import OGKM_PIN
from g1_special_object_providers import defined_symbols, observe, validate_object


class SpecialObjectTests(unittest.TestCase):
    def test_exact_export_spelling_not_substrings(self):
        self.assertEqual(defined_symbols('0000000000000010 T ___nvoc_dynamicCast\n'), {'___nvoc_dynamicCast'})
        self.assertNotIn('_nvoc_dynamicCast', defined_symbols('0000 T ___nvoc_dynamicCast'))
        self.assertEqual(defined_symbols('00000000 C _g_resServ'), {'_g_resServ'})

    def test_undefined_or_diagnostics_rejected(self):
        for text in [' U _symbol', '0000 U _symbol', 'nm: failed']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                defined_symbols(text)

    def test_object_hash_source_hash_architecture_and_location(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            obj = root/'candidate.o'
            # Synthetic header tests validation only, never native object evidence.
            raw = struct.pack('<IIIIIIII', 0xfeedfacf, 0x01000007, 3, 1, 0, 0, 0, 0)
            obj.write_bytes(raw)
            source = {'source_sha256': 'reviewed-source-hash'}
            entry = {'object': str(obj), 'compile_exit': 0, 'source_sha256': source['source_sha256'],
                     'object_sha256': hashlib.sha256(raw).hexdigest()}
            self.assertEqual(validate_object(entry, source, root), obj.resolve())
            for key, value in [('object_sha256', 'bad'), ('source_sha256', 'bad'), ('compile_exit', 1)]:
                with self.subTest(key=key), self.assertRaises(ValueError):
                    validate_object(dict(entry, **{key: value}), source, root)
            with self.assertRaises(ValueError):
                validate_object(entry, source, root/'other')
            obj.write_bytes(b'not Mach-O')
            entry['object_sha256'] = hashlib.sha256(obj.read_bytes()).hexdigest()
            with self.assertRaises(ValueError):
                validate_object(entry, source, root)

    def test_missing_and_failed_inputs_never_become_observed(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            records = [{'macho_symbol': '_data', 'source_spelling': 'data',
                        'source_candidate': {'path': 'data.c', 'kind': 'initialized-data-definition-candidate'}},
                       {'macho_symbol': '_pNV_KMS_ID', 'source_spelling': 'pNV_KMS_ID',
                        'source_candidate': {'path': 'src/nvidia-modeset/Makefile', 'kind': 'generated-data-recipe-only'}}]
            source = {'ogkm_pin': OGKM_PIN, 'records': records}
            native = {'pins': {'nv': OGKM_PIN}, 'build_manifest': []}
            def never(_argv):
                self.fail('must never run nm on a missing or failed build')
            result = observe(source, native, root, root, never)
            self.assertEqual(result['records'][0]['status'], 'NOT_BUILT')
            self.assertEqual(result['records'][1]['status'], 'GENERATION_RECIPE_ONLY_NO_OBJECT_NOMINATED')
            native['build_manifest'] = [{'source': 'data.c', 'compile_exit': 1, 'role': 'rm-batch'}]
            result = observe(source, native, root, root, never)
            self.assertEqual(result['records'][0]['status'], 'COMPILE_FAILED')
            self.assertEqual(result['closure_status'], 'NOT_ESTABLISHED')

    def test_missing_manifest_or_wrong_pin_rejected(self):
        source = {'ogkm_pin': OGKM_PIN}
        for native in [{'pins': {'nv': OGKM_PIN}}, {'pins': {'nv': 'wrong'}, 'build_manifest': []}]:
            with self.subTest(native=native), self.assertRaises(ValueError):
                observe(source, native, Path('.'), Path('.'), None)

    def test_shared_object_observed_once_for_exact_exports_and_nm_failure(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            obj = root/'runtime.o'
            raw = struct.pack('<IIIIIIII', 0xfeedfacf, 0x01000007, 3, 1, 0, 0, 0, 0)
            obj.write_bytes(raw)  # Synthetic parser fixture, not compiler output.
            candidate = {'path': 'runtime.c', 'kind': 'function-definition-candidate', 'source_sha256': 'reviewed'}
            source = {'ogkm_pin': OGKM_PIN, 'records': [
                {'macho_symbol': name, 'source_spelling': name[1:], 'source_candidate': candidate}
                for name in ['___nvoc_dynamicCast', '___nvoc_rtti_provider', '_absent']]}
            native = {'pins': {'nv': OGKM_PIN}, 'build_manifest': [
                {'source': 'runtime.c', 'source_sha256': 'reviewed', 'compile_exit': 0,
                 'object': str(obj), 'object_sha256': hashlib.sha256(raw).hexdigest()}]}
            calls = []
            def nm(argv):
                calls.append(argv)
                return 0, '0000 T ___nvoc_dynamicCast\n0010 D ___nvoc_rtti_provider\n', ''
            result = observe(source, native, root, root, nm)
            self.assertEqual(len(calls), 1)
            self.assertEqual([r['status'] for r in result['records']],
                             ['OBJECT_PROVIDER_OBSERVED', 'OBJECT_PROVIDER_OBSERVED', 'COMPILED_WITHOUT_TARGET_EXPORT'])
            with self.assertRaises(ValueError):
                observe(source, native, root, root, lambda _: (1, '', 'nm failed'))


if __name__ == '__main__':
    unittest.main()
