"""Host failure controls; synthetic headers never count as Darwin compilation."""
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import native


class FailureControls(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name)
    def tearDown(self): self.tmp.cleanup()

    def make_macho(self,kind=1,version=15<<16):
        p=self.root/'fixture'
        p.write_bytes(struct.pack('<8I',0xfeedfacf,0x01000007,3,kind,1,24,0,0)+
            struct.pack('<6I',0x32,24,1,version,0,0))
        return p

    def test_correct_format_is_only_host_metadata(self):
        self.assertEqual(native.macho(self.make_macho(),1,15<<16)['filetype'],1)
    def test_wrong_kind_rejected(self):
        with self.assertRaises(ValueError): native.macho(self.make_macho(8),1)
    def test_newer_minos_rejected(self):
        with self.assertRaises(ValueError): native.macho(self.make_macho(version=26<<16),1,15<<16)
    def test_empty_success_output_rejected(self):
        p=self.root/'fixture';p.write_bytes(b'')
        with self.assertRaises(ValueError): native.macho(p,1)
    def test_truncated_command_rejected(self):
        p=self.make_macho();p.write_bytes(p.read_bytes()[:-1])
        with self.assertRaises(ValueError): native.macho(p,1)

    def source_fixture(self):
        p=self.root/'source';p.write_bytes(b'HOST INPUT')
        inputs=dict(files=[dict(path='source',bytes=p.stat().st_size,sha256=native.sha(p))])
        (self.root/'INPUTS.json').write_text(json.dumps(inputs))
        return p,inputs

    def test_input_drift_rejected(self):
        p,inputs=self.source_fixture();p.write_bytes(b'OTHER BYTES')
        with self.assertRaises(ValueError): native.verify_inputs(self.root,inputs)
    def test_extra_input_rejected(self):
        _,inputs=self.source_fixture();(self.root/'extra').write_bytes(b'x')
        with self.assertRaises(ValueError): native.verify_inputs(self.root,inputs)

    def deps_fixture(self,omit=None):
        rows=[];deps=[]
        for name in ('nvmtl_vk.c','nvmtl_vk.h','NVMTLEventSync.m','nvmtl_submit_owner.h'):
            p=self.root/'candidate/plugin'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b'HOST '+name.encode())
            rows.append(dict(path='plugin/'+name,sha256=native.sha(p)))
            if name!=omit: deps.append(dict(resolved_path=str(p.resolve())))
        p=self.root/'snapshot.json';p.write_text(json.dumps(dict(inputs=deps)))
        return dict(path=str(p)),dict(files=rows)

    def test_all_four_patched_files_required_for_full_plugin(self):
        b,m=self.deps_fixture()
        self.assertEqual(len(native.check_patch_dependencies('candidate','plugin',b,m,self.root)),4)
    def test_eventsync_not_seen_by_actual_compiler_rejected(self):
        b,m=self.deps_fixture('NVMTLEventSync.m')
        with self.assertRaises(ValueError): native.check_patch_dependencies('candidate','plugin',b,m,self.root)
    def test_owner_header_not_seen_by_actual_compiler_rejected(self):
        b,m=self.deps_fixture('nvmtl_submit_owner.h')
        with self.assertRaises(ValueError): native.check_patch_dependencies('candidate','c',b,m,self.root)


if __name__=='__main__': unittest.main()
