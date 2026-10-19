"""Candidate delta failure controls; synthetic trees are tool tests only."""
import unittest
from g1_ogkm_candidate import SPECS, CHAIN, approved_specs, check_delta, tree_digest
import copy


class CandidateTests(unittest.TestCase):
    def test_pinned_chain_folds_final_source_and_rejects_drift(self):
        self.assertEqual(approved_specs(list(SPECS)), list(SPECS))
        good = list(SPECS) + list(CHAIN)
        folded = approved_specs(good)
        self.assertEqual(folded[0]['original_sha256'], SPECS[0]['original_sha256'])
        self.assertEqual(folded[0]['candidate_sha256'], CHAIN[0]['post_sha256'])
        self.assertEqual(folded[0]['defined_symbol'], '_nvKmsKapiTryFreeDevice')
        for field in ('pre_sha256', 'post_sha256', 'patch_sha256', 'defined_symbol'):
            bad = copy.deepcopy(good); bad[-1][field] = 'unreviewed'
            with self.subTest(field=field), self.assertRaises(ValueError):
                approved_specs(bad)
        for bad in (good[::-1], good[:-2], good + list(CHAIN)):
            with self.assertRaises(ValueError): approved_specs(bad)

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
