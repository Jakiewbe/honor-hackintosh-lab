#!/usr/bin/env python3
"""Negative controls for genuine RM caller/OS callback source contract."""
import unittest
from dma_rm_path import inspect, routine, NO_GO

MAC = """
NV_STATUS NV_API_CALL nv_alloc_pages() { *priv_data = a; return NV_OK; }
NV_STATUS NV_API_CALL nv_dma_map_alloc() { *priv = NULL; return NV_OK; }
NV_STATUS NV_API_CALL nv_free_pages() { nv_xnu_alloc *a = (nv_xnu_alloc *)priv_data; return NV_OK; }
"""
RM = """
void osFreePagesInternal(MEMORY_DESCRIPTOR *pMemDesc) {
nv_free_pages(nv, osPageCount, contig, cached, memdescGetMemData(pMemDesc));
}
NV_STATUS osIovaMap(PIOVAMAPPING pIovaMapping) {
void *pPriv = memdescGetMemData(pIovaMapping->pPhysMemDesc);
status = nv_dma_map_alloc(dev, pages, array, contiguous, readOnly, &pPriv);
if (is_system) { pIovaMapping->pOsData = pPriv; }
else if (peer != nv) { pIovaMapping->pOsData = NULL; }
// pOsData must be NULL to distinguish a peer DMA mapping
}
void osIovaUnmap(PIOVAMAPPING pIovaMapping) {
if (flag) { return; }
pPriv = (void *)pIovaMapping->pOsData;
if (pPriv != NULL) {
status = nv_dma_unmap_alloc(nv->dma_dev, osPageCount, &pIovaMapping->iovaArray[0], &pPriv);
if (status != NV_OK) { NV_PRINTF(LEVEL_ERROR, "failed to unmap allocation"); }
} else { nv_dma_unmap_peer(nv->dma_dev, count, address); }
pIovaMapping->pOsData = NULL;
}
"""


class RmIovaPathTests(unittest.TestCase):
    def test_known_control_flow_is_blocked(self):
        report = inspect(MAC, RM)
        self.assertEqual(report["verdict"], NO_GO)
        self.assertTrue(all(report["facts"].values()))
        self.assertEqual(report["limitations"]["actual_gpu_branch_reached"], "UNVERIFIED")

    def test_unknown_mac_pointer_overwrite_fails_review(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC.replace("*priv = NULL;", "*priv = mapping;"), RM)

    def test_no_rm_peer_null_discriminator_fails_review(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC, RM.replace("if (pPriv != NULL)", "if (kind == SYSTEM)"))

    def test_no_rm_recorded_owner_fails_review(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC, RM.replace("pIovaMapping->pOsData = pPriv;", "/* no owner */"))

    def test_unmap_failure_retains_owner_requires_reaudit(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC, RM.replace("pIovaMapping->pOsData = NULL;", "/* ownership preserved */"))

    def test_original_allocation_is_separate_owner(self):
        r = inspect(MAC, RM)
        self.assertTrue(r["facts"]["rm_map_takes_local_copy_of_original_owner"])
        self.assertTrue(r["facts"]["rm_free_gets_memdesc_separate_owner"])

    def test_c_parser_skips_comment_braces(self):
        self.assertIn("return NV_OK", routine(
            "NV_STATUS NV_API_CALL nv_dma_map_alloc() {"
            ' /* { } */ const char *v = "}"; return NV_OK; }',
            r"\bNV_STATUS\s+NV_API_CALL\s+nv_dma_map_alloc\s*\("))

    def test_commented_owner_assignment_must_not_pass(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC, RM.replace("pIovaMapping->pOsData = pPriv;",
                                     "// pIovaMapping->pOsData = pPriv;"))

    def test_quoted_owner_assignment_must_not_pass(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC, RM.replace("pIovaMapping->pOsData = pPriv;",
                                     'const char *fake = "pIovaMapping->pOsData = pPriv;";'))

    def test_failed_unmap_with_early_return_requires_reaudit(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC, RM.replace('NV_PRINTF(LEVEL_ERROR, "failed to unmap allocation");',
                                     "return;"))

    def test_peer_null_assignment_in_comment_must_not_pass(self):
        with self.assertRaisesRegex(ValueError, "manually review"):
            inspect(MAC, RM.replace("else if (peer != nv) { pIovaMapping->pOsData = NULL;",
                                     "else if (peer != nv) { // pIovaMapping->pOsData = NULL;"))


if __name__ == "__main__":
    unittest.main()
