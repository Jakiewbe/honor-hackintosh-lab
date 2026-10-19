"""Unit wrapper: the free-order checker's own negative controls must pass.

The gate runs `unittest discover` over tools/, so wiring the checker's self-test here makes "the checker
still rejects incomplete / duplicated / comment-only / unguarded / reversed inputs" a blocking check
instead of something a human has to remember to run.
"""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_kapi_free_order",
                                              ROOT / "tools/check-kapi-free-order.py")


class FreeOrderCheckerTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(self.mod)

    def test_self_test_all_controls(self):
        self.assertEqual(self.mod.self_test(), 0)

    def test_incomplete_function_is_rejected(self):
        ok, problems, _ = self.mod.analyse(
            "static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device)"
            "{ nvkms_xnu_try_quiesce_kapi(device->pKmsOpen); }")
        self.assertFalse(ok)
        self.assertTrue(any("absent" in p for p in problems))

    def test_complete_function_is_accepted(self):
        ok, problems, _ = self.mod.analyse(
            "static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){"
            " if (!nvkms_xnu_try_quiesce_kapi(device->pKmsOpen)) return NV_FALSE;"
            " if (!nvkms_ioctl_from_kapi(device->pKmsOpen, NVKMS_IOCTL_FREE_DEVICE, 0, 0)) return NV_FALSE;"
            " nvKmsKapiFreeNisoSurface(device, &device->semaphore);"
            " nvKmsKapiFreeNisoSurface(device, &device->notifier);"
            " return NV_TRUE; }")
        self.assertTrue(ok, problems)


if __name__ == "__main__":
    unittest.main()
