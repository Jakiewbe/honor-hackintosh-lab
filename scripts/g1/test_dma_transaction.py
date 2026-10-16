#!/usr/bin/env python3
"""No-hardware DMA mapping publication and failure state machine tests."""
import unittest
from dma_transaction import DmaError, FakeBackend, Poisoned, TransactionalDma


class TransactionTests(unittest.TestCase):
    def setUp(self):
        self.backend = FakeBackend()
        self.model = TransactionalDma("10de:25a9", 0xffffffff, self.backend)

    def test_scatter_commit_replaces_addresses_and_priv(self):
        addresses, priv = [4096, 8192], ["initial"]
        token = self.model.map("10de:25a9", addresses, priv, 2)
        self.assertIs(priv[0], token)
        self.assertEqual(addresses, [0x20001000, 0x20002000])
        self.assertEqual(token.host, (4096, 8192))

    def test_contiguous_one_base_and_n_pages(self):
        addresses, priv = [4096], [None]
        self.model.map("10de:25a9", addresses, priv, 3, contiguous=True)
        self.assertEqual(next(iter(self.backend.active.values()))[2], 3 * 4096)
        self.model.unmap("10de:25a9", addresses, priv, 3)
        self.assertEqual(self.backend.active, {})

    def test_partial_map_failure_atomic_rollback(self):
        addresses, priv = [4096, 8192], ["old"]
        self.backend.fail_map_at = 1
        with self.assertRaises(DmaError):
            self.model.map("10de:25a9", addresses, priv, 2)
        self.assertEqual(addresses, [4096, 8192])
        self.assertEqual(priv, ["old"])
        self.assertFalse(self.backend.active)
        self.assertFalse(self.model.poisoned)

    def test_failed_rollback_quarantines_and_poison(self):
        addresses, priv = [4096, 8192], [None]
        self.backend.fail_map_at, self.backend.fail_unmap_at = 1, 0
        with self.assertRaises(Poisoned):
            self.model.map("10de:25a9", addresses, priv, 2)
        self.assertEqual(addresses, [4096, 8192])
        self.assertIsNone(priv[0])
        self.assertTrue(self.model.quarantined)
        with self.assertRaises(Poisoned):
            self.model.map("10de:25a9", [4096], [None], 1)

    def test_partial_unmap_retains_exact_outstanding_handle(self):
        addresses, priv = [4096, 8192], [None]
        token = self.model.map("10de:25a9", addresses, priv, 2)
        self.backend.fail_unmap_at = 1
        with self.assertRaises(Poisoned):
            self.model.unmap("10de:25a9", addresses, priv, 2)
        self.assertIs(priv[0], token)
        self.assertEqual(len(token.leases), 1)
        self.assertEqual(len(self.backend.active), 1)
        self.backend.fail_unmap_at = None
        self.model.retry_unmap_synthetic("10de:25a9", addresses, priv, 2)
        self.assertFalse(self.backend.active)
        self.assertIsNone(priv[0])

    def test_cross_device_unmap_rejected(self):
        addresses, priv = [4096], [None]
        self.model.map("10de:25a9", addresses, priv, 1)
        with self.assertRaises(DmaError):
            self.model.unmap("other", addresses, priv, 1)
        self.assertEqual(len(self.backend.active), 1)

    def test_mismatched_count_cannot_release(self):
        addresses, priv = [4096], [None]
        self.model.map("10de:25a9", addresses, priv, 3, contiguous=True)
        with self.assertRaises(DmaError):
            self.model.unmap("10de:25a9", addresses, priv, 2)
        self.assertEqual(len(self.backend.active), 1)

    def test_modified_iova_cannot_release(self):
        addresses, priv = [4096], [None]
        self.model.map("10de:25a9", addresses, priv, 1)
        addresses[0] += 4096
        with self.assertRaises(DmaError):
            self.model.unmap("10de:25a9", addresses, priv, 1)

    def test_double_unmap_detected(self):
        addresses, priv = [4096], [None]
        self.model.map("10de:25a9", addresses, priv, 1)
        self.model.unmap("10de:25a9", addresses, priv, 1)
        with self.assertRaises(DmaError):
            self.model.unmap("10de:25a9", addresses, priv, 1)

    def test_bad_page_shapes_and_addresses(self):
        for a, count, contig in (([4097], 1, False),
                                 ([4096], 2, False),
                                 ([4096, 8192], 2, True),
                                 ([], 0, False), ([-4096], 1, False)):
            with self.subTest(a=a, count=count), self.assertRaises(DmaError):
                self.model.map("10de:25a9", a, [None], count, contig)
        self.assertFalse(self.backend.active)

    def test_iova_aperture_failure_undoes_backend(self):
        self.model.limit = 0x20000fff
        addresses, priv = [4096, 8192], [None]
        with self.assertRaises(DmaError):
            self.model.map("10de:25a9", addresses, priv, 2)
        self.assertEqual(addresses, [4096, 8192])
        self.assertFalse(self.backend.active)

    def test_existing_receipt_not_reusable(self):
        a, p = [4096], [None]
        self.model.map("10de:25a9", a, p, 1)
        with self.assertRaises(DmaError):
            self.model.map("10de:25a9", a, p, 1)

    def test_unmap_does_not_claim_physical_address_restoration(self):
        a, p = [4096], [None]
        self.model.map("10de:25a9", a, p, 1)
        mapped = a[:]
        self.model.unmap("10de:25a9", a, p, 1)
        self.assertEqual(a, mapped)
        self.assertFalse(self.model.receipts)


if __name__ == "__main__":
    unittest.main()
