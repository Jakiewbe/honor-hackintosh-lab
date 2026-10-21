#!/usr/bin/env python3
"""Offline contract for the v2.4.3 THREAD_CALL_OPTIONS_ONCE backport.

This does not compile a kext. It checks the reviewed patch shape, the source
identities, the one new kernel import, and the retain/release invariant that
the NVRMFB scheduleCall()/stop() pair relies on. A native two-TU run is still
required before any admission claim.
"""
import hashlib
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "research" / "stock-v243-once-20261021"
PATCH = ASSETS / "stock-v243-converged.patch"
OVERLAY = ASSETS / "stock-v243-once-overlay.patch"
LOCK = ASSETS / "source-lock.json"
FINAL_FB = ASSETS / "nvrm-fb-once.cpp"

EXPECTED_SITES = 12
NEW_FB_SHA256 = "69df8a943ef5ea1f0fce87eceee7287d4814d3f5768117340596ea9b56f98f78"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def added_lines(patch: Path):
    return [line[1:] for line in patch.read_text(encoding="utf-8").splitlines()
            if line.startswith("+") and not line.startswith("+++")]


def removed_lines(patch: Path):
    return [line[1:] for line in patch.read_text(encoding="utf-8").splitlines()
            if line.startswith("-") and not line.startswith("---")]


class OnceBackportContract(unittest.TestCase):
    def setUp(self):
        self.lock = json.loads(LOCK.read_text(encoding="utf-8"))
        self.patch_text = PATCH.read_text(encoding="utf-8")
        self.overlay_text = OVERLAY.read_text(encoding="utf-8")
        self.final_text = FINAL_FB.read_text(encoding="utf-8")

    def test_fixed_pin_is_unchanged(self):
        self.assertEqual(self.lock["upstream_commit"],
                         "272ccd9da04ff5de95c2791b902fe17a3fa77ce7")
        self.assertEqual(self.lock["ogkm_commit"],
                         "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb")
        self.assertEqual(self.lock["patch"], "stock-v243-converged.patch")

    def test_patch_binds_to_lock(self):
        self.assertEqual(sha(PATCH.read_bytes()), self.lock["patch_sha256"])
        self.assertEqual(sha(OVERLAY.read_bytes()), self.lock["overlay_sha256"])
        self.assertEqual(sha(FINAL_FB.read_bytes()), NEW_FB_SHA256)
        for row in self.lock["files"]:
            if row["path"] == "kexts/NVRMFB/fb/nvrm-fb.cpp":
                self.assertEqual(row["candidate_sha256"], NEW_FB_SHA256)
            else:
                self.assertEqual(row["candidate_sha256"],
                                 "ac0c75180a36a9b17b9350b4e39cd68e19496c7af276f3267060a1b9a0db9404")

    def test_combined_patch_scope_is_the_two_tus(self):
        paths = []
        for line in self.patch_text.splitlines():
            if line.startswith("+++ b/") or line.startswith("--- a/"):
                path = line[6:].strip()
                if path != "/dev/null" and path not in paths:
                    paths.append(path)
        self.assertEqual(sorted(paths), ["kexts/NVRM/NVRM.cpp", "kexts/NVRMFB/fb/nvrm-fb.cpp"])

    def test_overlay_converts_all_twelve_sites_like_the_release(self):
        adds = [line for line in added_lines(OVERLAY)
                if "thread_call_allocate_with_options(" in line]
        removes = [line for line in removed_lines(OVERLAY)
                   if "thread_call_allocate(" in line and "with_options" not in line]
        self.assertEqual(len(adds), EXPECTED_SITES)
        self.assertEqual(len(removes), EXPECTED_SITES)
        for line in adds:
            self.assertIn("THREAD_CALL_PRIORITY_HIGH, THREAD_CALL_OPTIONS_ONCE", line)
        # Release 47f818b routes all twelve allocations through nvrmfbCall() with ONCE,
        # including both gConnectNotify sites. A first draft excluded those two; reading
        # XNU thread_call.c showed a plain call object is also one queue element, so both
        # modes merge while pending and ONCE cannot lose an extra notification. The
        # backport therefore matches the release and does not carry the helper.
        self.assertEqual(self.final_text.count("thread_call_allocate("), 0)
        self.assertEqual(self.final_text.count(
            "gConnectNotify = thread_call_allocate_with_options(connectNotifyFire, nullptr"), 2)
        for line in added_lines(OVERLAY):
            if "gConnectNotify" in line:
                self.assertIn("THREAD_CALL_OPTIONS_ONCE", line)

    def test_one_new_kernel_import_is_approved(self):
        approved = [entry for entry in self.lock["integration_symbols"]["approved_new_undefined"]
                    if entry["path"] == "kexts/NVRMFB/fb/nvrm-fb.cpp"]
        self.assertEqual([entry["symbol"] for entry in approved],
                         ["_thread_call_allocate_with_options"])
        self.assertIn("runner-kernel-nm-raw.txt:20704", approved[0]["evidence"])
        # Every allocation now goes through the new options call, so the old import is
        # expected to disappear; that removal is recorded, not silently tolerated.
        removed = self.lock["integration_symbols"]["approved_removed_undefined"]
        self.assertEqual([entry["symbol"] for entry in removed], ["_thread_call_allocate"])

    def test_no_third_party_pr_is_present(self):
        # The lock documents the exclusion by number; the code-bearing patches must not carry it.
        text = self.patch_text + self.overlay_text
        for marker in ("#317", "#318", "PR 317", "PR 318"):
            self.assertNotIn(marker, text)

    def test_once_serializes_same_call_but_does_not_drain_on_cancel(self):
        # Fixed XNU: running enter sets RESCHEDULE, not a cancellable queue item.
        # This is a reference model, not execution of XNU or proof of driver safety.
        state = dict(pending=False, reschedule=False, running=0, retains=0, stopping=False)

        def schedule():
            if state["stopping"]:
                return
            state["retains"] += 1
            if state["pending"] or state["reschedule"]:
                state["retains"] -= 1   # folded into the one pending run
            elif state["running"]:
                state["reschedule"] = True
            else:
                state["pending"] = True

        def start():
            assert state["pending"]
            assert state["running"] == 0
            state["pending"] = False
            state["running"] += 1

        def finish():
            assert state["running"] > 0
            state["running"] -= 1
            state["retains"] -= 1       # NVRMCallReference
            if state["reschedule"]:
                state["reschedule"] = False
                state["pending"] = True

        def cancel():
            if state["pending"]:
                state["pending"] = False
                state["retains"] -= 1   # stop()'s compensation
                return True
            return False

        schedule()                       # R1, pending
        schedule()                       # folded, R2 released
        self.assertEqual(state["retains"], 1)
        start()                           # running, pending cleared
        schedule()                       # R2 is deferred until finish
        schedule()                       # further enter folds, no extra retain
        self.assertEqual((state["running"], state["pending"], state["reschedule"],
                          state["retains"]), (1, False, True, 2))
        self.assertFalse(cancel())        # cancel does not clear RESCHEDULE
        self.assertEqual(state["retains"], 2)
        finish()                          # release R1
        self.assertEqual((state["running"], state["pending"], state["retains"]), (0, True, 1))
        start()
        finish()
        self.assertEqual(state["retains"], 0)
        schedule()                       # ordinary pending run
        state["stopping"] = True          # scheduleCall refuses after this
        schedule()
        self.assertTrue(cancel())
        self.assertEqual(state["retains"], 0)
        self.assertGreaterEqual(state["retains"], 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
