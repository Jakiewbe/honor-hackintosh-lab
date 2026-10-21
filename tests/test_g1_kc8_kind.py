"""The KC parser's function/data hint must cover vtables and C globals, not only metaClass."""
import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
SPEC = importlib.util.spec_from_file_location('g1_kc8_kind', ROOT / 'tools/g1_kc8.py')


class KernelDataSymbolClassification(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)

    def test_metaclass_is_data(self):
        self.assertTrue(self.mod.expects_data('__ZN13IOFramebuffer10gMetaClassE'))
        self.assertTrue(self.mod.expects_data('__ZN11IOPCIDevice9metaClassE'))

    def test_vtables_and_typeinfo_are_data(self):
        for name in ('__ZTV13IOFramebuffer', '__ZTI13IOFramebuffer', '__ZTS13IOFramebuffer',
                     '__ZTV25IODisplayParameterHandler'):
            self.assertTrue(self.mod.expects_data(name), name)

    def test_c_globals_are_data(self):
        for name in ('_gIODisplayBrightnessKey', '_gIODisplayParametersKey'):
            self.assertTrue(self.mod.expects_data(name), name)

    def test_methods_are_code(self):
        for name in ('__ZN13IOFramebuffer10getVBLTimeEPyS0_', '__ZNK13IOFramebuffer11getWorkLoopEv',
                     '__ZN11IOPCIDevice19extendedConfigRead8Ey'):
            self.assertFalse(self.mod.expects_data(name), name)


if __name__ == '__main__':
    unittest.main()
