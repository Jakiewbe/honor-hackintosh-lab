#!/usr/bin/env python3
"""B3 fail-closed ld64 map parser regression tests (no native driver required)."""
import unittest

from b2_native_probe import fsp_link_map_proof

FSP = [
    {"source": "src/nvidia/src/kernel/gpu/fsp/kern_fsp.c",
     "original_member": "kern_fsp.o", "patched_member": "kern_fsp.c.o"},
    {"source": "src/nvidia/src/kernel/gpu/timer/timer_ostimer.c",
     "original_member": "timer_ostimer.o", "patched_member": "timer_ostimer.c.o"},
]


def map_text(*objects, trailer=""):
    body = "\n".join(f"[{i:3}] {o}" for i, o in enumerate(objects))
    return ("# Path: /tmp/NVRM-link-candidate\n# Arch: x86_64\n"
            "# Object files:\n" + body + "\n# Sections:\n"
            "# Address\tSize\tSegment\tSection\n# Symbols:\n" + trailer + "\n")


class FSPLinkMapTests(unittest.TestCase):
    def verify(self, document, expected):
        status, proof = fsp_link_map_proof(document, FSP)
        self.assertEqual(status, expected, proof)
        return proof

    def test_patched_members_unique_and_original_absent(self):
        proof = self.verify(map_text(
            "linker synthesized",
            "/tmp/libnvkernel-candidate.a(kern_fsp.c.o)",
            "/tmp/libnvkernel-candidate.a(timer_ostimer.c.o)",
            "/tmp/libnvkms-candidate.a(kern_fsp.o)"),
            "FSP_PATCH_MEMBERS_SELECTED")
        for item in proof["members"].values():
            self.assertEqual(item["patched_selected_count"], 1)
            self.assertEqual(item["original_selected_count"], 0)

    def test_unpatched_original_is_never_accepted(self):
        self.verify(map_text(
            "/tmp/libnvkernel-candidate.a(kern_fsp.o)",
            "/tmp/libnvkernel-candidate.a(kern_fsp.c.o)",
            "/tmp/libnvkernel-candidate.a(timer_ostimer.c.o)"),
            "BLOCKED_UNPATCHED_FSP_MEMBER_IN_LINK_MAP")

    def test_missing_patched_is_never_accepted(self):
        self.verify(map_text(
            "/tmp/libnvkernel-candidate.a(kern_fsp.c.o)"),
            "BLOCKED_PATCHED_FSP_MEMBER_SELECTION_NOT_EXACTLY_ONE")

    def test_repeated_patched_is_never_accepted(self):
        self.verify(map_text(
            "/tmp/libnvkernel-candidate.a(kern_fsp.c.o)",
            "/tmp/libnvkernel-candidate.a(kern_fsp.c.o)",
            "/tmp/libnvkernel-candidate.a(timer_ostimer.c.o)"),
            "BLOCKED_PATCHED_FSP_MEMBER_SELECTION_NOT_EXACTLY_ONE")

    def test_name_in_symbol_section_does_not_count(self):
        self.verify(map_text("linker synthesized",
                             trailer="0x1000 0x10 [ 0] libnvkernel-candidate.a(kern_fsp.c.o)"),
                    "BLOCKED_PATCHED_FSP_MEMBER_SELECTION_NOT_EXACTLY_ONE")

    def test_map_must_have_an_object_table(self):
        self.verify("# Symbols:\nlibnvkernel-candidate.a(kern_fsp.c.o)\n",
                    "BLOCKED_LINK_MAP_PARSE")

    def test_duplicate_object_tables_blocked(self):
        self.verify("# Object files:\n[ 1] fake\n# Object files:\n[ 2] fake\n# Sections:\n",
                    "BLOCKED_AMBIGUOUS_LINK_MAP")

    def test_unexpected_row_blocked(self):
        self.verify("# Object files:\nnot a valid indexed row\n# Sections:\n",
                    "BLOCKED_LINK_MAP_PARSE")


if __name__ == "__main__":
    unittest.main()
