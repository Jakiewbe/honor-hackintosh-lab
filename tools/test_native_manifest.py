"""Negative controls for real native link input selection; no driver is compiled."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1]/'scripts/gpu-safety-r5/native_compile.py'
spec = importlib.util.spec_from_file_location('native_compile', SCRIPT)
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)


class ManifestTests(unittest.TestCase):
    def test_same_basename_never_aliases(self):
        a = native.object_destination(Path('out'), 'batch', 'src/first/os.c')
        b = native.object_destination(Path('out'), 'batch', 'src/second/os.c')
        self.assertNotEqual(a, b)
        self.assertEqual(a, native.object_destination(Path('out'), 'batch', 'src/first/os.c'))

    def test_parent_escape_rejected(self):
        with self.assertRaises(ValueError):
            native.object_destination(Path('out'), 'batch', '../os.c')

    def test_baseline_kept_and_stale_file_excluded(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            before = [root/'nvrm.o', root/'probe.o']
            after = [root/'batch.o']
            for p in [*before, *after, root/'stale.o']:
                p.write_text('unit-test placeholder, not native evidence')
            result = native.link_object_list(before, after)
            self.assertEqual(result[:len(before)], before)
            self.assertNotIn(root/'stale.o', result)

    def test_duplicate_or_missing_object_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            p = Path(folder)/'present.o'
            p.touch()
            with self.assertRaises(ValueError):
                native.link_object_list([p], [p])
            with self.assertRaises(ValueError):
                native.link_object_list([p], [p.with_name('missing.o')])

    def test_success_without_native_object_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            src, obj = root/'source.c', root/'source.o'
            src.write_text('int fixture;')
            obj.write_text('old or invalid object')
            with self.assertRaises(ValueError):
                native.object_record('unit-test', root, src, obj, 0)
            self.assertNotIn('object_sha256', native.object_record('unit-test', root, src, obj, 1))


if __name__ == '__main__':
    unittest.main()
