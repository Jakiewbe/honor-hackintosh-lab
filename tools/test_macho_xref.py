import struct
import unittest

from macho_xref import observe


def fixture():
    strings=b'\0_target\0__ZTV7Example\0_after\0'
    # Four commands, whereas filetype=11. LC_DYSYMTAB is last.
    segment_size=72+80
    cmds=segment_size+72+24+80
    base=32+cmds;dataoff=base;tableoff=base+24
    symoff=tableoff;stroff=symoff+3*16;reloff=stroff+len(strings)
    size=reloff+8
    def segment(name,vm,off,filesize,nsects=0):
        return struct.pack('<II16sQQQQIIII',0x19,72+80*nsects,name,vm,filesize,off,filesize,3,3,nsects,0)
    # __TEXT also contains the tiny data section for this parser fixture.
    section=struct.pack('<16s16sQQIIIIIIII',b'__const',b'__TEXT',dataoff,24,dataoff,3,0,0,0,0,0,0)
    a=segment(b'__TEXT',0,0,tableoff,1)+section
    b=segment(b'__LINKEDIT',tableoff,tableoff,size-tableoff,0)
    sym=struct.pack('<6I',2,24,symoff,3,stroff,len(strings))
    fields=[0,0,0,2,2,1,0,0,0,0,0,0,0,0,reloff,1,0,0]
    dys=struct.pack('<20I',0xb,80,*fields)
    commands=a+b+sym+dys
    h=struct.pack('<8I',0xfeedfacf,0x1000007,3,11,4,len(commands),0,0)
    table=(struct.pack('<IBBHQ',9,15,1,0,dataoff)+struct.pack('<IBBHQ',23,15,1,0,dataoff+24)
           +struct.pack('<IBBHQ',1,1,0,0,0))
    raw=bytearray(h+commands+b'\0'*24+table+strings+struct.pack('<iI',dataoff+8,2|(3<<25)|(1<<27)))
    return raw,reloff


class ExternalReferences(unittest.TestCase):
    def test_exact_data_relocation_not_a_call(self):
        raw,_=fixture();d=observe(raw,'_target')
        self.assertEqual(d['load_command_count'],4)
        self.assertEqual(d['references'][0]['offset_in_container'],8)
        self.assertEqual(d['references'][0]['classification'],'DATA_REFERENCE_NOT_A_DIRECT_CALL')
        self.assertEqual(d['references'][0]['container_symbols'][0]['name'],'__ZTV7Example')

    def test_relocation_table_truncated(self):
        raw,_=fixture()
        with self.assertRaises(ValueError):observe(raw[:-1],'_target')

    def test_symbol_index_outside_table(self):
        raw,off=fixture();struct.pack_into('<I',raw,off+4,99|(3<<25)|(1<<27))
        with self.assertRaises(ValueError):observe(raw,'_target')

    def test_local_relocation_in_external_table(self):
        raw,off=fixture();struct.pack_into('<I',raw,off+4,2|(3<<25))
        with self.assertRaises(ValueError):observe(raw,'_target')

    def test_outside_section(self):
        raw,off=fixture();struct.pack_into('<i',raw,off,1)
        with self.assertRaises(ValueError):observe(raw,'_target')

    def test_import_name_identity(self):
        raw,_=fixture()
        with self.assertRaises(ValueError):observe(raw,'target')

    def test_wrong_filetype(self):
        raw,_=fixture();struct.pack_into('<I',raw,12,1)
        with self.assertRaises(ValueError):observe(raw,'_target')


if __name__=='__main__':unittest.main()
