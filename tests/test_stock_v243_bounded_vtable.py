"""Class boundary counterexample: never label adjacent objects as the same vtable."""
import importlib
from pathlib import Path
import struct
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
tool=importlib.import_module('g1_kc_vtable_bounded')


class BoundedVtableTests(unittest.TestCase):
    def fixture(self):
        raw=bytearray(256)
        struct.pack_into('<Q',raw,16,0x4000000000000080)
        struct.pack_into('<Q',raw,24,0x4000000000000090)
        struct.pack_into('<Q',raw,48,0x40000000000000a0)
        sec=dict(address=0x1000,offset=0,size=128,flags=0,name='__const',segment='__DATA')
        member=dict(sections=[sec])
        rows=[dict(name='__ZTV1A',value=0x1000,section=1),
              dict(name='__ZTV1B',value=0x1020,section=1),
              dict(name='__ZN1A1fEv',value=0x80,section=2),
              dict(name='__ZN1A1gEv',value=0x90,section=2),
              dict(name='__ZN1B1hEv',value=0xa0,section=2)]
        return raw,member,rows

    def test_adjacent_class_not_scanned_as_current(self):
        raw,member,rows=self.fixture()
        result=tool.class_observation(raw,member,rows,'A')
        self.assertEqual([s['slot_relative_to_class'] for s in result['slots']],[0,1])
        self.assertEqual(result['upper_bound'],'0x1020')
        self.assertEqual(result['exports'],'UNVERIFIED')

    def test_absent_or_multiple_vtable_addresses_are_unknown(self):
        raw,member,rows=self.fixture()
        self.assertEqual(tool.class_observation(raw,member,rows,'C')['status'],'VTABLE_ADDRESS_ABSENT_OR_AMBIGUOUS')
        rows.append(dict(name='__ZTV1A',value=0x1060,section=1))
        self.assertEqual(tool.class_observation(raw,member,rows,'A')['status'],'VTABLE_ADDRESS_ABSENT_OR_AMBIGUOUS')

    def test_truncated_collection_rejected(self):
        raw,member,rows=self.fixture()
        with self.assertRaises(ValueError):tool.class_observation(raw[:20],member,rows,'A')


if __name__=='__main__':unittest.main()
