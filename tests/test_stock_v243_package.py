"""Synthetic parser fixtures and dependency counterexamples; never GPU evidence."""
import importlib
from pathlib import Path
import struct
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts/g1'))
gate = importlib.import_module('stock_v243_package')


def fixture(name='com.nullmoth.test', version='0.1', minimum=0x000f0500):
    data = bytearray(1024)
    struct.pack_into('<8I', data, 0, 0xfeedfacf, 0x01000007, 3, 11, 3, 192, 0, 0)
    struct.pack_into('<II16sQQQQIIII', data, 32, 0x19, 152, b'__DATA', 0, 1024, 0, 1024, 3, 3, 1, 0)
    struct.pack_into('<16s16sQQIIIIIIII', data, 104, b'__data', b'__DATA', 256, 200, 256, 3, 0, 0, 0, 0, 0, 0)
    names = b'\0_kmod_info\0__realmain\0__antimain\0'
    struct.pack_into('<6I', data, 184, 2, 24, 480, 3, 560, len(names))
    struct.pack_into('<4I', data, 208, 0x24, 16, minimum, 0x000f0500)
    data[272:272+len(name)] = name.encode()
    data[336:336+len(version)] = version.encode()
    for i,(index,value) in enumerate(((1,256),(12,408),(23,416))):
        struct.pack_into('<IBBHQ', data, 480+i*16, index, 0xf, 1, 0, value)
    data[560:560+len(names)] = names
    return data


class PackageContracts(unittest.TestCase):
    def parse(self, data):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'fixture'; path.write_bytes(data)
            return gate.binary_metadata(path, {'CFBundleIdentifier':'com.nullmoth.test', 'CFBundleVersion':'0.1'})

    def test_identity_and_deployment_fixture(self):
        self.assertEqual(self.parse(fixture())['minimum_macos'], '15.5')

    def test_wrong_kmod_rejected(self):
        for raw in (fixture(name='com.bad'), fixture(version='0.2')):
            with self.assertRaisesRegex(ValueError, 'identity mismatch'):
                self.parse(raw)

    def test_wrong_target_rejected(self):
        with self.assertRaisesRegex(ValueError, 'deployment'):
            self.parse(fixture(minimum=0x000f0000))

    def test_truncated_or_malformed_rejected(self):
        for size in (0, 31, 200, 600):
            with self.assertRaises((ValueError, struct.error)):
                self.parse(fixture()[:size])
        data = fixture(); struct.pack_into('<I', data, 36, 0)
        with self.assertRaises(ValueError):
            self.parse(data)

    def test_symbol_bounds_rejected(self):
        data = fixture(); struct.pack_into('<I', data, 480, 1000)
        with self.assertRaisesRegex(ValueError, 'string bounds'):
            self.parse(data)

    def test_version_order_and_missing_compatibility(self):
        seq = ['1.0.0d1','1.0.0a1','1.0.0b1','1.0.0fc1','1.0','1.0.1','2.0','10.0']
        self.assertEqual(seq, sorted(seq, key=gate.version))
        self.assertFalse(gate.compatible('1.0', {'CFBundleVersion':'2.0'}))
        self.assertTrue(gate.compatible('1.0', {'CFBundleVersion':'2.0','OSBundleCompatibleVersion':'1.0.0b1'}))
        for bad in ('', 'latest', '1.0.0.1', '1.0b256'):
            with self.assertRaises(ValueError): gate.version(bad)

    def audit(self, declared=None, actual=None, required='8.0'):
        sets = {'SymbolsSets':[{'CFBundleIdentifier':'kpi', 'CFBundleVersion':'24.6.0',
            'OSBundleCompatibleVersion':'8.0.0b1', 'Symbols':[{'SymbolName':'_s','AliasTarget':'_t'}]}]}
        return gate.audit_imports(['_s'], declared if declared is not None else {'kpi':required},
            sets, actual if actual is not None else {'_t'}, {}, {})

    def test_exact_declared_version_alias_definition(self):
        self.assertEqual(self.audit()['unresolved'], [])
        self.assertEqual(self.audit()['rows'][0]['providers'][0]['target'], '_t')

    def test_missing_declaration_or_definition_rejected(self):
        self.assertEqual(self.audit(declared={})['unresolved'], ['_s'])
        self.assertEqual(self.audit(actual=set())['unresolved'], ['_s'])
        self.assertEqual(self.audit(required='25.0')['unresolved'], ['_s'])

    def test_family_definition_is_not_export_claim(self):
        family = {'f':{'info':{'CFBundleVersion':'2.0','OSBundleCompatibleVersion':'1.0'},'definitions':['_s']}}
        report = gate.audit_imports(['_s'], {'f':'1.0'}, {'SymbolsSets':[]}, set(), family, {})
        self.assertEqual(report['rows'][0]['providers'][0]['explicit_export'], 'UNVERIFIED')
        self.assertEqual(gate.audit_imports(['_s'], {'other':'1.0'}, {'SymbolsSets':[]}, set(), family, {})['unresolved'], ['_s'])


if __name__ == '__main__': unittest.main()
