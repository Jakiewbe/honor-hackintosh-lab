import importlib
from pathlib import Path
import plistlib
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/g1'))
tool=importlib.import_module('predevice_diagnostics')


class PredeviceTests(unittest.TestCase):
    def test_registry_sanitization_and_target_filter(self):
        raw=plistlib.dumps([dict(**{'vendor-id':b'\xde\x10\0\0','device-id':b'\xa9\x25\0\0',
            'IOPlatformSerialNumber':'MUST_NOT_BE_SAVED','IORegistryEntryChildren':[
                {'vendor-id':b'\x86\x80','device-id':b'\xa6\x46'},
                {'vendor-id':b'\x86\x80','device-id':b'\xff\xff'}]})])
        rows=tool.pci_summary(raw)
        self.assertEqual({r['device'] for r in rows},{'25a9','46a6'})
        self.assertNotIn('MUST_NOT_BE_SAVED',str(rows))

    def test_unknown_pci_id_not_filled_with_zero(self):
        self.assertEqual(tool.pci_summary(plistlib.dumps([{'vendor-id':b'\xde\x10'}])),[])


if __name__=='__main__':unittest.main()
