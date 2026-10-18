from pathlib import Path
import tempfile
import unittest
from g1_text_diagnostics import prepare


class TextPublicationTests(unittest.TestCase):
    def test_dsym_and_objects_excluded_text_preserved(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); source = root/'logs'; source.mkdir()
            (source/'real.txt').write_text('evidence', encoding='utf-8')
            (source/'driver.o').write_bytes(b'object')
            dsym = source/'test.bin.dSYM/Contents/Resources/DWARF'
            dsym.mkdir(parents=True); (dsym/'test.bin').write_bytes(b'binary')
            r = prepare(source, root/'publish')
            self.assertEqual([x['path'] for x in r['included']], ['real.txt'])
            self.assertEqual(len(r['excluded']), 2)

    def test_macho_disguised_as_text_fails(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); source = root/'logs'; source.mkdir()
            (source/'fake.txt').write_bytes(bytes.fromhex('cffaedfe'))
            with self.assertRaises(ValueError):
                prepare(source, root/'publish')

    def test_nested_output_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            with self.assertRaises(ValueError):
                prepare(root, root/'publish')


if __name__ == '__main__':
    unittest.main()
