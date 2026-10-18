import hashlib
import json
import unittest
from g1_provider_evidence import read_nm_log, symbolset_entries


class ProviderEvidenceTests(unittest.TestCase):
    def group(self, symbols, provider='com.apple.kpi.iokit'):
        return {'CFBundleIdentifier': provider, 'CFBundleVersion': '24.6.0',
                'OSBundleCompatibleVersion': '8.0.0b1', 'Symbols': symbols}

    def test_alias_checks_target_not_only_exported_name(self):
        value = {'SymbolsSets': [self.group([{'SymbolName': '_IOLockLock', 'AliasTarget': '_lck_mtx_lock'}])]}
        declared = {'com.apple.kpi.iokit': '8.0'}
        rows, _ = symbolset_entries(value, ['_IOLockLock'], {'_IOLockLock': 'T'}, declared)
        self.assertFalse(rows['_IOLockLock'][0]['target_global_observed'])
        rows, _ = symbolset_entries(value, ['_IOLockLock'], {'_lck_mtx_lock': 'T'}, declared)
        self.assertTrue(rows['_IOLockLock'][0]['target_global_observed'])

    def test_undeclared_private_provider_not_implicitly_allowed(self):
        value = {'SymbolsSets': [self.group([{'SymbolName': '_x'}], 'com.apple.kpi.private')]}
        rows, _ = symbolset_entries(value, ['_x'], {'_x': 'T'}, {'com.apple.kpi.iokit': '8.0'})
        self.assertFalse(rows['_x'][0]['source_declares_library_id'])

    def test_prefixes_not_fabricated_exact_entries_and_one_underscore(self):
        value = {'SymbolsSets': [self.group([{'SymbolPrefix': '__ZN3Foo'}, {'SymbolName': '___bzero'}])]}
        rows, prefixes = symbolset_entries(value, ['__ZN3Foo3barEv', '___bzero', '_bzero'], {'___bzero': 'T'}, {})
        self.assertEqual(rows['__ZN3Foo3barEv'], [])
        self.assertEqual(prefixes[0]['matching_imports'], ['__ZN3Foo3barEv'])
        self.assertEqual(len(rows['___bzero']), 1)
        self.assertEqual(rows['_bzero'], [])

    def test_ambiguous_or_unknown_syntax_rejected(self):
        for value in [{'SymbolSets': []},
            {'SymbolsSets': [self.group([{'SymbolName': '_x', 'Unknown': True}])]},
            {'SymbolsSets': [self.group([{'SymbolName': '_x'}, {'SymbolName': '_x'}])]},
            {'SymbolsSets': [self.group([]), self.group([])]}]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                symbolset_entries(value, ['_x'], {}, {})

    def test_real_trailing_space_metadata_does_not_become_a_trimmed_hit(self):
        name = '__ZN9IOService9resourcesEv'
        value = {'SymbolsSets': [self.group([{'SymbolName': name+' '}])]}
        rows, notes = symbolset_entries(value, [name], {name: 'T'}, {})
        self.assertEqual(rows[name], [])
        self.assertEqual(notes[0]['raw_entry']['SymbolName'], name+' ')

    def test_raw_nm_hash_argv_and_exit_are_all_required(self):
        argv = ['xcrun', 'nm', '-arch', 'x86_64', '-gU', '/kernel']
        stdout = '0000 T _x\n'
        digest = hashlib.sha256(stdout.encode()).hexdigest()
        text = 'ARGV='+json.dumps(argv)+'\n'+stdout+'\nEXIT=0\n'
        self.assertEqual(read_nm_log(text, argv, digest), {'_x': 'T'})
        for altered in [text.replace('EXIT=0', 'EXIT=1'), text.replace('_x', '_y'), text+'extra']:
            with self.subTest(text=altered), self.assertRaises(ValueError):
                read_nm_log(altered, argv, digest)
        with self.assertRaises(ValueError):
            read_nm_log(text, ['nm', '/other'], digest)


if __name__ == '__main__':
    unittest.main()
