"""Missing fixture may skip; corrupted partial fixture must fail."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from source_cache_support import require_source_cache


class SourceCachePreflight(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.cache = Path(self.temp.name)
        self.lock = ROOT / 'research/independent-i915/source-lock.json'

    def test_absent_cache_is_explicit_skip(self):
        with self.assertRaisesRegex(unittest.SkipTest, 'Source verification NOT RUN'):
            require_source_cache(self, self.lock, self.cache)

    def test_corruption_is_not_hidden_by_other_missing_files(self):
        row = json.loads(self.lock.read_text(encoding='utf-8'))['files'][0]
        path = self.cache / row['component'] / row['path']
        path.parent.mkdir(parents=True)
        path.write_bytes(b'corrupted source evidence')
        with self.assertRaisesRegex(AssertionError, 'cache hash mismatch'):
            require_source_cache(self, self.lock, self.cache)

    def test_component_cannot_escape_cache_root(self):
        data = json.loads(self.lock.read_text(encoding='utf-8'))
        data['files'][0]['component'] = '../outside'
        lock = self.cache / 'bad-lock.json'
        lock.write_text(json.dumps(data), encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Unknown source-cache component'):
            require_source_cache(self, lock, self.cache)


if __name__ == '__main__':
    unittest.main()
