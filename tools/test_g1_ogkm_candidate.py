"""Candidate delta failure controls; synthetic trees are tool tests only."""
import unittest
from g1_ogkm_candidate import check_delta, tree_digest


class CandidateTests(unittest.TestCase):
    def test_exact_patch_delta_accepts_only_expected_bytes(self):
        before = {'a.c': 'old', 'header.h': 'unchanged'}
        after = {'a.c': 'new', 'header.h': 'unchanged'}
        spec = [{'source': 'a.c', 'original_sha256': 'old', 'candidate_sha256': 'new'}]
        check_delta(before, after, spec)
        for wrong in (before, dict(after, **{'header.h': 'drift'}),
                      {'a.c': 'new'}, dict(after, **{'extra.c': 'unreviewed'}),
                      dict(after, **{'a.c': 'unexpected'})):
            with self.subTest(wrong=wrong), self.assertRaises(ValueError):
                check_delta(before, wrong, spec)
        with self.assertRaises(ValueError):
            check_delta(dict(before, **{'a.c': 'different base'}), after, spec)

    def test_tree_digest_is_order_independent_but_binds_names_and_bytes(self):
        self.assertEqual(tree_digest({'a': '1', 'b': '2'}), tree_digest({'b': '2', 'a': '1'}))
        self.assertNotEqual(tree_digest({'a': '1'}), tree_digest({'b': '1'}))
        self.assertNotEqual(tree_digest({'a': '1'}), tree_digest({'a': '2'}))


if __name__ == '__main__': unittest.main()
