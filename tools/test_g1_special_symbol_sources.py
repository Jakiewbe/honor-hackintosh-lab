import unittest
from g1_special_symbol_sources import REVIEWED, anchor, summary


class SpecialSourceTests(unittest.TestCase):
    def test_extern_is_not_definition(self):
        for name, text in [('g_pSys', 'extern OBJSYS *g_pSys;'),
                           ('g_resServ', 'extern RsServer g_resServ;'),
                           ('__nvoc_class_def_Memory', 'extern const struct NVOC_CLASS_DEF __nvoc_class_def_Memory;')]:
            path, pattern, kind = REVIEWED[name]
            with self.subTest(name=name), self.assertRaises(ValueError):
                anchor(path, text, pattern, kind)

    def test_comment_only_anchor_rejected(self):
        path, pattern, kind = REVIEWED['g_resServ']
        with self.assertRaises(ValueError):
            anchor(path, '/*\nRsServer g_resServ;\n*/', pattern, kind)

    def test_exact_spelling_required(self):
        path, pattern, kind = REVIEWED['__nvoc_rtti_provider']
        with self.assertRaises(ValueError):
            anchor(path, 'const struct NVOC_RTTI_PROVIDER nvoc_rtti_provider = { 0 };', pattern, kind)

    def test_data_and_tentative_definitions(self):
        for name, text in [('g_pSys', 'OBJSYS *g_pSys = NULL;'), ('g_resServ', 'RsServer g_resServ;')]:
            path, pattern, kind = REVIEWED[name]
            result = anchor(path, text, pattern, kind)
            self.assertEqual(result['line'], 1)
            self.assertIn('data-definition', result['kind'])

    def test_ambiguous_anchor_rejected(self):
        path, pattern, kind = REVIEWED['g_resServ']
        with self.assertRaises(ValueError):
            anchor(path, 'RsServer g_resServ;\nRsServer g_resServ;', pattern, kind)

    def test_summary_hash_covers_all_hits_and_manifest(self):
        report = {'source_manifest': [{'path': 'a', 'sha256': 'x'}],
                  'records': [{'raw_text_occurrences': ['a:1'], 'macho_symbol': '_a'}]}
        first = summary(report)
        report['records'][0]['raw_text_occurrences'].append('b:2')
        self.assertNotEqual(first['full_canonical_sha256'], summary(report)['full_canonical_sha256'])
        self.assertNotIn('raw_text_occurrences', first['records'][0])


if __name__ == '__main__':
    unittest.main()
