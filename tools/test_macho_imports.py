import struct
import unittest

from macho_imports import parse_bytes


def fixture(is64=True, late=True):
    # filetype=1 deliberately differs from ncmds=13; LC_SYMTAB comes last.
    padding = struct.pack('<II', 0x7777, 8) * (12 if late else 0)
    hsize = 32 if is64 else 28
    esize = 16 if is64 else 12
    entries = [(1, 1, 0, 0, 0), (4, 1, 0, 0, 16), (7, 0, 0, 0, 0), (10, 0xe1, 0, 0, 0)]
    strings = b'\0_x\0_c\0_l\0_d\0'
    symoff = hsize+len(padding)+24
    table = b''.join(struct.pack('<IBBHQ' if is64 else '<IBBHI', *e) for e in entries)
    symtab = struct.pack('<6I', 2, 24, symoff, len(entries), symoff+len(table), len(strings))
    header = struct.pack('<8I' if is64 else '<7I', *([0xfeedfacf if is64 else 0xfeedface,
        0x1000007 if is64 else 7, 3, 1, len(padding)//8+1, len(padding)+24, 0]+([0] if is64 else [])))
    return bytearray(header+padding+symtab+table+strings), symoff


class Imports(unittest.TestCase):
    def test_64_late_symtab_and_real_import_only(self):
        self.assertEqual(parse_bytes(fixture()[0]), ['_x'])

    def test_32(self):
        self.assertEqual(parse_bytes(fixture(False)[0]), ['_x'])

    def test_all_truncations_rejected(self):
        raw, _ = fixture()
        for length in range(len(raw)):
            with self.subTest(length=length), self.assertRaises(ValueError):
                parse_bytes(raw[:length])

    def test_bad_cmdsize(self):
        raw, _ = fixture()
        struct.pack_into('<I', raw, 36, 0)
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_count_size_mismatch(self):
        raw, _ = fixture()
        struct.pack_into('<I', raw, 16, 1)
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_duplicate_symtab(self):
        raw, symoff = fixture()
        raw[32:56] = raw[symoff-24:symoff]
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_name_outside_strsize(self):
        raw, symoff = fixture()
        struct.pack_into('<I', raw, symoff, 999)
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_terminator_outside_table(self):
        raw, symoff = fixture()
        struct.pack_into('<I', raw, symoff-4, len(b'\0_x'))
        raw.extend(b'\0')
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_symbol_table_bounds(self):
        raw, symoff = fixture()
        struct.pack_into('<I', raw, symoff-12, 9999)
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_overlap(self):
        raw, symoff = fixture()
        struct.pack_into('<I', raw, symoff-8, symoff)
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_strict_encoding(self):
        raw, _ = fixture()
        raw[-11] = 0xff
        with self.assertRaises(ValueError): parse_bytes(raw)

    def test_duplicate_import_rejected(self):
        raw, symoff = fixture()
        raw[symoff+16:symoff+32] = raw[symoff:symoff+16]
        with self.assertRaises(ValueError): parse_bytes(raw)


if __name__ == '__main__': unittest.main()
