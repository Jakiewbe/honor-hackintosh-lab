"""Validate explicit conflict selection against the immutable real table set."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from acpi_static_external_plan import build_plan, select_externals, CONFLICT_GROUPS


class ExternalSelection(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plan = build_plan()
        cls.tables = [row['target'] for row in cls.plan['runs']]

    def test_every_original_is_a_target(self):
        self.assertEqual(len(self.tables), 16)
        self.assertEqual(len(set(self.tables)), 16)

    def test_only_declared_conflicts_are_excluded(self):
        for row in self.plan['runs']:
            self.assertEqual(len(row['externals']), 13)
            self.assertNotIn(row['target'], row['externals'])
            self.assertEqual(set(row['externals']) | {x['file'] for x in row['excluded']},
                             set(self.tables) - {row['target']})
            for group in CONFLICT_GROUPS:
                self.assertEqual(len(set(group) & set(row['externals'])),
                                 0 if row['target'] in group else 1)

    def test_target_group_excludes_counterpart(self):
        for group in CONFLICT_GROUPS:
            for target in group:
                row = select_externals(self.tables, target)
                self.assertTrue(set(group).isdisjoint(row['externals']))

    def test_touchpad_collision_avoided_without_extra_exclusions(self):
        dsdt = CONFLICT_GROUPS[1][1]
        ssd9 = CONFLICT_GROUPS[0][1]
        for row in self.plan['runs']:
            loaded = set(row['externals']) | {row['target']}
            self.assertFalse({dsdt, ssd9} <= loaded)
            self.assertEqual(len(row['excluded']), 2)

    def test_missing_conflict_input_rejected(self):
        tables = self.tables.copy()
        tables[tables.index(CONFLICT_GROUPS[0][0])] = 'unknown.bin'
        with self.assertRaisesRegex(ValueError, 'Missing conflict'):
            select_externals(tables, tables[0])

    def test_unknown_target_and_duplicate_set_rejected(self):
        with self.assertRaises(ValueError):
            select_externals(self.tables, 'unknown.bin')
        with self.assertRaises(ValueError):
            select_externals(self.tables[:-1] + [self.tables[0]], self.tables[0])


if __name__ == '__main__':
    unittest.main()
