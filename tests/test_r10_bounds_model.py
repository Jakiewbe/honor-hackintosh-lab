"""R1.0 safety-contract reference tests (model only, NOT driver validation).

No macOS, GPU or kext APIs are used.  Failing cases represent invariants that
future review-only driver patches must reject before reading MMIO or copying.
"""
import unittest

U64 = (1 << 64) - 1
MAX_DIM = 16384
# Highest 32-bit register read in four-pipe NMIntelFB probe:
# PLANE_SURF(3) = 0x7019C + 3 * 0x1000, plus four bytes.
MIN_BAR0_MAPPED = 0x731A0


def last_row_footprint(rows: int, pitch: int, row_bytes: int):
    """Return required mapped bytes, or None if invalid/overflowing u64."""
    if not all(isinstance(n, int) and 0 <= n <= U64 for n in (rows, pitch, row_bytes)):
        return None
    if rows == 0 or row_bytes == 0 or pitch < row_bytes:
        return None
    if (rows - 1) > (U64 - row_bytes) // pitch:
        return None
    return (rows - 1) * pitch + row_bytes


def copy_allowed(width, height, src_pitch, src_capacity, dst_pitch, dst_capacity):
    """Fail-closed geometry/capacity predicate, not copied from upstream."""
    vals = (width, height, src_pitch, src_capacity, dst_pitch, dst_capacity)
    if not all(isinstance(x, int) and 0 <= x <= U64 for x in vals):
        return False
    if not (1 <= width <= MAX_DIM and 1 <= height <= MAX_DIM):
        return False
    row_bytes = width * 4  # bounded by MAX_DIM
    if src_pitch % 4 or dst_pitch % 4:
        return False
    src_need = last_row_footprint(height, src_pitch, row_bytes)
    dst_need = last_row_footprint(height, dst_pitch, row_bytes)
    return (src_need is not None and dst_need is not None
            and src_capacity >= src_need and dst_capacity >= dst_need)


def bar0_read_set_safe(mapped_bytes: int):
    """Four-pipe candidate's entire fixed 32-bit MMIO read set must fit."""
    return isinstance(mapped_bytes, int) and MIN_BAR0_MAPPED <= mapped_bytes <= U64


class ScanoutContractTests(unittest.TestCase):
    def test_1080p_exact_capacity(self):
        self.assertTrue(copy_allowed(1920, 1080, 7680, 7680 * 1080,
                                     7680, 7680 * 1080))

    def test_nvintel_actual_size_zero_fails_closed(self):
        self.assertFalse(copy_allowed(1920, 1080, 7680, 7680 * 1080,
                                      7680, 0))

    def test_missing_last_destination_byte_rejected(self):
        need = last_row_footprint(2, 16, 8)
        self.assertEqual(need, 24)
        self.assertFalse(copy_allowed(2, 2, 16, 24, 16, 23))
        self.assertTrue(copy_allowed(2, 2, 16, 24, 16, 24))

    def test_missing_last_source_byte_rejected(self):
        self.assertFalse(copy_allowed(2, 2, 16, 23, 16, 24))

    def test_row_pitch_too_short(self):
        self.assertFalse(copy_allowed(3, 2, 8, 32, 16, 32))
        self.assertFalse(copy_allowed(3, 2, 16, 32, 8, 32))

    def test_unaligned_pitch(self):
        self.assertFalse(copy_allowed(2, 2, 9, 100, 16, 100))
        self.assertFalse(copy_allowed(2, 2, 16, 100, 9, 100))

    def test_bad_dimensions(self):
        for dim in (0, 16385, -1):
            self.assertFalse(copy_allowed(dim, 1, 8, 32, 8, 32))
            self.assertFalse(copy_allowed(1, dim, 8, 32, 8, 32))

    def test_uint64_multiplication_overflow(self):
        self.assertIsNone(last_row_footprint(3, 1 << 63, 4))
        self.assertFalse(copy_allowed(1, 3, 1 << 63, U64, 4, 12))

    def test_outside_uint64_inputs(self):
        self.assertFalse(copy_allowed(1, 1, 4, U64 + 1, 4, 4))
        self.assertFalse(copy_allowed(1, 1, 4, 4, 4, -1))

    def test_single_pixel_single_row(self):
        self.assertTrue(copy_allowed(1, 1, 4, 4, 4, 4))
        self.assertFalse(copy_allowed(1, 1, 4, 3, 4, 4))

    def test_padded_pitch_last_row_only(self):
        self.assertEqual(last_row_footprint(2, 64, 8), 72)
        self.assertTrue(copy_allowed(2, 2, 64, 72, 64, 72))

    def test_bar0_minimum(self):
        self.assertTrue(bar0_read_set_safe(MIN_BAR0_MAPPED))
        self.assertFalse(bar0_read_set_safe(MIN_BAR0_MAPPED - 1))

    def test_bar0_invalid_length(self):
        for n in (0, -1, U64 + 1):
            self.assertFalse(bar0_read_set_safe(n))


if __name__ == "__main__":
    unittest.main(verbosity=2)
