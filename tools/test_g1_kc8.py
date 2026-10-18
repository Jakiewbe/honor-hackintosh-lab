import copy
import struct
import unittest

from g1_kc8 import bounded, header, observe_symbols, TARGETS
from g1_kc8_sdk import compare


class Kc8Tests(unittest.TestCase):
    def sym_fixture(self, name=None, ntype=0x0f, section=1, address=0x1000, flags=0x80000400):
        name = name or TARGETS['com.apple.iokit.IOPCIFamily'][0]
        strings = b'\0'+name.encode()+b'\0'
        raw = b'\0'*128+struct.pack('<IBBHQ', 1, ntype, section, 0, address)+strings+b'\0'*128
        member = {'symtab': {'symoff': 128, 'nsyms': 1, 'stroff': 144, 'strsize': len(strings)},
            'segments': [{'name': '__LINKEDIT', 'fileoff': 128, 'filesize': 16+len(strings),
                          'vmaddr': 0x2000},
                         {'name': '__TEXT', 'fileoff': 0, 'filesize': 128, 'vmaddr': 0x1000}],
            'sections': [{'ordinal': 1, 'name': '__text', 'segment': '__TEXT',
                          'address': 0x1000, 'size': 128, 'offset': 0, 'flags': flags}]}
        return raw, member, [name]

    def test_bounded_header_and_unsupported_arch_fail_closed(self):
        raw = struct.pack('<8I', 0xfeedfacf, 0x01000007, 3, 12, 0, 0, 0, 0)
        self.assertEqual(header(raw)['filetype'], 12)
        for bad in [raw[:20], raw.replace(b'\x07\0\0\x01', b'\x0c\0\0\x01')]:
            with self.assertRaises(ValueError):
                header(bad)
        for offset, size in [(-1, 1), (1, -1), (32, 1)]:
            with self.assertRaises(ValueError):
                bounded(raw, offset, size)

    def test_fileset_member_offsets_uuid_and_command_bounds(self):
        ident = b'com.apple.iokit.IOPCIFamily\0'
        size = (32+len(ident)+7)//8*8
        command = struct.pack('<IIQQII', 0x80000035, size, 0x1000, 512, 32, 0)+ident
        command += b'\0'*(size-len(command))
        uuid = struct.pack('<II', 0x1b, 24)+b'\x11'*16
        raw = struct.pack('<8I', 0xfeedfacf, 0x01000007, 3, 12, 2, size+24, 0, 0)+command+uuid
        result = header(raw)
        self.assertEqual(result['entries'][0]['fileoff'], 512)
        self.assertEqual(result['uuid'], '11'*16)
        bad = bytearray(raw)
        struct.pack_into('<I', bad, 36, 8)
        with self.assertRaises(ValueError):
            header(bad)

    def test_external_section_definition_and_function_data_roles(self):
        raw, member, names = self.sym_fixture()
        row = observe_symbols(raw, member, names)['records'][0]
        self.assertEqual(row['observed_kind'], 'FUNCTION_SECTION')
        self.assertEqual(row['definition_file_offset'], 0)
        raw, member, names = self.sym_fixture(TARGETS['com.apple.iokit.IOPCIFamily'][-1], flags=0)
        self.assertEqual(observe_symbols(raw, member, names)['records'][0]['observed_kind'], 'DATA_SECTION')

    def test_undefined_private_stab_and_wrong_section_not_definitions(self):
        for ntype in [1, 0x1f, 0xef, 0x0e]:
            raw, member, names = self.sym_fixture(ntype=ntype)
            row = observe_symbols(raw, member, names)['records'][0]
            self.assertEqual(row['status'], 'NOT_A_PUBLIC_SECTION_DEFINITION')
        for kwargs in [{'section': 2}, {'address': 0x9000}, {'flags': 0}]:
            raw, member, names = self.sym_fixture(**kwargs)
            with self.assertRaises(ValueError):
                observe_symbols(raw, member, names)

    def test_linkedit_bounds_and_stripped_tables_never_use_allowlist(self):
        raw, member, names = self.sym_fixture()
        member['segments'][0]['filesize'] = 1
        with self.assertRaisesRegex(ValueError, '__LINKEDIT'):
            observe_symbols(raw, member, names)
        member['symtab'] = None
        self.assertEqual(observe_symbols(raw, member, names)['status'], 'KC_BINARY_SYMBOL_NOT_OBSERVABLE')

    def sdk_ir(self):
        declarations = {}
        for name in TARGETS['com.apple.iokit.IOPCIFamily'][:6]:
            llvm = name[1:]
            if 'Read8' in name:
                ret, params = 'zeroext i8', 'ptr noundef, i64 noundef'
            elif 'Read16' in name:
                ret, params = 'zeroext i16', 'ptr noundef, i64 noundef'
            elif 'Read32' in name:
                ret, params = 'i32', 'ptr noundef, i64 noundef'
            else:
                bits = '8' if 'Write8' in name else '16' if 'Write16' in name else '32'
                ret, params = 'void', 'ptr noundef, i64 noundef, i'+bits+(' zeroext' if bits != '32' else '')
            declarations[llvm] = {'line': 'declare '+ret+' @'+llvm+'('+params+')'}
        return '\n'.join(row['line'] for row in declarations.values()), {'declarations': declarations}

    def test_sdk_width_extension_and_calling_convention_mismatch_detected(self):
        ir, caller = self.sdk_ir()
        self.assertTrue(all(r['status'] == 'SDK_CALLER_TYPE_MATCH' for r in compare(ir, caller)))
        for changed in [ir.replace('zeroext i8 @', 'i8 @', 1), ir.replace('i64 noundef', 'i32 noundef', 1),
                        ir.replace('declare zeroext i8', 'declare fastcc zeroext i8', 1)]:
            self.assertEqual(compare(changed, caller)[0]['status'], 'SDK_CALLER_TYPE_MISMATCH')

    def test_missing_caller_stays_unknown_missing_sdk_fails(self):
        ir, caller = self.sdk_ir()
        caller['declarations'].pop(TARGETS['com.apple.iokit.IOPCIFamily'][3][1:])
        self.assertEqual(compare(ir, caller)[3]['status'], 'HISTORICAL_CALLER_IR_NOT_OBSERVED')
        with self.assertRaises(ValueError):
            compare(ir.split('\n', 1)[1], caller)


if __name__ == '__main__':
    unittest.main()
