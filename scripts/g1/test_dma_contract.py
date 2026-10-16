#!/usr/bin/env python3
"""No GPU: synthetic DMA contract and fault-injection checks."""
import unittest
from dma_contract import audit, callback, FakeDmaLedger, NO_GO

MAC = """
NvBool NV_API_CALL nv_requires_dma_remap(nv_state_t *nv) { TRC; return NV_FALSE; }
NV_STATUS NV_API_CALL nv_dma_map_alloc(nv_dma_device_t *dev, NvU64 n,
 NvU64 *a, NvBool contig, NvBool c, void **priv)
{ kprintf("brace { }"); /* comment { } */ *priv = NULL; return NV_OK; }
NV_STATUS NV_API_CALL nv_dma_unmap_alloc(nv_dma_device_t *dev, NvU64 n,
 NvU64 *a, void **priv) { TRC; return NV_OK; }
device->getPhysicalSegment(0, NULL, kIOMemoryMapperNone);
"""
LINUX = """
NV_STATUS NV_API_CALL nv_dma_map_alloc(nv_dma_device_t *dev, NvU64 n,
 NvU64 *a, NvBool c, NvBool r, void **p)
{ if (x) nv_dma_map_pages(); else nv_dma_map_sgt(); return NV_OK; }
NV_STATUS NV_API_CALL nv_dma_unmap_alloc(nv_dma_device_t *dev, NvU64 n,
 NvU64 *a, void **p)
{ if (x) nv_dma_unmap_pages(); else nv_dma_unmap_sgt(); return NV_OK; }
void extra() { dma_mapping_error(); nv_dma_is_addressable(); dma_unmap_page_attrs(); }
"""


class SourceContractTests(unittest.TestCase):
    def test_nested_braces_in_comments_strings(self):
        self.assertIn("*priv = NULL", callback(MAC, "nv_dma_map_alloc"))

    def test_audit_explicit_no_go(self):
        r = audit(MAC, LINUX)
        self.assertTrue(all(r["facts"].values()))
        self.assertEqual(r["runtime_verdict"], NO_GO)

    def test_changed_macos_semantics_block(self):
        with self.assertRaisesRegex(ValueError, "review"):
            audit(MAC.replace("*priv = NULL; return NV_OK;", "return NV_ERR_NOT_SUPPORTED;"), LINUX)

    def test_changed_linux_semantics_block(self):
        with self.assertRaisesRegex(ValueError, "review"):
            audit(MAC, LINUX.replace("dma_mapping_error()", "other_check()"))


class OwnershipTests(unittest.TestCase):
    def setUp(self):
        self.f = FakeDmaLedger("10de:25a9", 65535)

    def test_map_and_unmap(self):
        self.assertEqual(self.f.map("a", "10de:25a9", [0, 4096]), (0, 4096))
        self.assertEqual(self.f.unmap("a", "10de:25a9"), (0, 4096))

    def test_partial_failure_uncommitted(self):
        with self.assertRaises(RuntimeError):
            self.f.map("a", "10de:25a9", [0, 4096], fail_index=1)
        self.assertEqual(self.f.active, {})

    def test_wrong_device_unmap_denied(self):
        self.f.map("a", "10de:25a9", [4096])
        with self.assertRaises(ValueError):
            self.f.unmap("a", "other")
        self.assertIn("a", self.f.active)

    def test_bad_aperture_and_alignment(self):
        for bad in ([65536], [65535], [-4096]):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                self.f.map("a", "10de:25a9", bad)
        self.assertEqual(self.f.active, {})

    def test_double_unmap_and_duplicate(self):
        self.f.map("a", "10de:25a9", [0])
        with self.assertRaises(ValueError):
            self.f.map("a", "10de:25a9", [4096])
        self.f.unmap("a", "10de:25a9")
        with self.assertRaises(ValueError):
            self.f.unmap("a", "10de:25a9")

    def test_owner_and_page_geometry(self):
        with self.assertRaises(ValueError):
            self.f.map("a", "other", [0])
        with self.assertRaises(ValueError):
            self.f.map("a", "10de:25a9", [0], page=0)
        with self.assertRaises(ValueError):
            self.f.map("a", "10de:25a9", [])


if __name__ == "__main__":
    unittest.main()
