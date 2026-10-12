"""R1.2-E: abstract two-stage quiesce/finalize state machine.

This is a NON-KERNEL reference model. It assumes a separate executor that can
run outside both IOGraphics SYS/FB gates. The implementation of such an
executor and its legality for synchronous IOService::stop are NOT established.
No driver or hardware operations occur here.
"""
from dataclasses import dataclass, replace
from collections import deque
import unittest


@dataclass(frozen=True)
class StopState:
    phase: str = "ACTIVE"  # ACTIVE, QUIESCING, DRAINED, FINALIZED
    inside_fb_callback: bool = False
    target_slot: bool = True
    target_inflight: bool = False
    target_release_pending: bool = False
    target_release_count: int = 0
    completed_callbacks: int = 0
    stop_finalizations: int = 0
    stop_request_count: int = 0
    unsafe_early_ack: bool = False
    forbidden_gate_release: bool = False

    def callback_enter(self):
        if self.phase != "ACTIVE" or self.inside_fb_callback:
            return self
        return replace(self, inside_fb_callback=True, target_inflight=self.target_slot)

    def quiesce_request(self):
        # Never claim synchronous IOService::stop returned successfully here.
        if self.phase == "FINALIZED":
            return self
        phase = "QUIESCING" if self.inside_fb_callback else "DRAINED"
        return replace(self, phase=phase,
                       stop_request_count=self.stop_request_count + 1,
                       target_slot=False,
                       target_release_pending=self.target_release_pending or self.target_slot)

    def unregister(self):
        if not self.target_slot:
            return self
        # Do NOT call the target's potentially reentrant destructor under FB.
        return replace(self, target_slot=False, target_release_pending=True)

    def callback_exit(self):
        if not self.inside_fb_callback:
            return self
        newphase = "DRAINED" if self.phase == "QUIESCING" else self.phase
        return replace(self, phase=newphase, inside_fb_callback=False,
                       target_inflight=False,
                       completed_callbacks=self.completed_callbacks + 1)

    def retire_targets_outside_gate(self):
        if self.inside_fb_callback or not self.target_release_pending:
            return self
        return replace(self, target_release_pending=False,
                       target_release_count=self.target_release_count + 1)

    def finalize_external(self):
        # A separate, lifetime-safe SYS->FB executor is ASSUMED, not built.
        if self.phase != "DRAINED" or self.inside_fb_callback or self.target_release_pending:
            return self
        return replace(self, phase="FINALIZED",
                       stop_finalizations=self.stop_finalizations + 1)

    def synchronous_stop_in_callback(self):
        # Cannot silently defer and return from a real IOService::stop().
        if self.inside_fb_callback:
            return "BLOCKED_UNPROVEN_SYNC_IOKIT_STOP"
        return "NOT_IN_CALLBACK"

    def next_vbl_allowed(self):
        return self.phase == "ACTIVE" and not self.inside_fb_callback


def invariants(s):
    assert not s.unsafe_early_ack
    assert not s.forbidden_gate_release
    assert s.stop_finalizations <= 1
    assert s.target_release_count <= 1
    if s.phase == "FINALIZED":
        assert not s.inside_fb_callback
        assert not s.target_release_pending
        assert not s.target_slot
    if s.phase != "ACTIVE":
        assert not s.next_vbl_allowed()


class StopContractTests(unittest.TestCase):
    def test_normal_start_and_vbl(self):
        s = StopState()
        self.assertTrue(s.next_vbl_allowed())
        self.assertTrue(s.callback_enter().inside_fb_callback)

    def test_request_quiesce_inside_callback_blocks_rearm(self):
        s = StopState().callback_enter().quiesce_request()
        self.assertFalse(s.next_vbl_allowed())
        self.assertEqual(s.phase, "QUIESCING")

    def test_true_sync_stop_inside_callback_is_not_faked(self):
        s = StopState().callback_enter()
        self.assertEqual(s.synchronous_stop_in_callback(),
                         "BLOCKED_UNPROVEN_SYNC_IOKIT_STOP")

    def test_stop_cannot_finalize_inside_callback(self):
        s = StopState().callback_enter().quiesce_request()
        self.assertEqual(s.finalize_external(), s)

    def test_stop_after_callback_exit_and_target_retirement(self):
        s = (StopState().callback_enter().quiesce_request().callback_exit()
             .retire_targets_outside_gate().finalize_external())
        self.assertEqual(s.phase, "FINALIZED")
        self.assertEqual(s.stop_finalizations, 1)

    def test_target_final_release_cannot_happen_in_callback(self):
        s = StopState().callback_enter().unregister()
        self.assertEqual(s.retire_targets_outside_gate().target_release_count, 0)
        self.assertTrue(s.target_release_pending)

    def test_unregister_and_stop_double_retirement_idempotent(self):
        s = (StopState().callback_enter().unregister().quiesce_request()
             .callback_exit().retire_targets_outside_gate().retire_targets_outside_gate())
        self.assertEqual(s.target_release_count, 1)

    def test_stop_twice_one_finalize(self):
        s = (StopState().quiesce_request().quiesce_request()
             .retire_targets_outside_gate().finalize_external().finalize_external())
        self.assertEqual(s.stop_finalizations, 1)

    def test_start_never_resurrected_after_stop(self):
        s = StopState().quiesce_request().retire_targets_outside_gate().finalize_external()
        self.assertFalse(s.callback_enter().inside_fb_callback)

    def test_owner_stop_outside_callback_uses_same_contract(self):
        s = StopState().quiesce_request()
        self.assertEqual(s.synchronous_stop_in_callback(), "NOT_IN_CALLBACK")
        # Does NOT mean this model implements IOService::stop.

    def test_target_retirement_ensures_gate_released(self):
        s = (StopState().callback_enter().quiesce_request().callback_exit()
             .retire_targets_outside_gate())
        self.assertFalse(s.inside_fb_callback)
        self.assertFalse(s.target_release_pending)

    def test_space_exhaustive_to_depth_8(self):
        actions = (lambda s: s.callback_enter(), lambda s: s.quiesce_request(),
                   lambda s: s.unregister(), lambda s: s.callback_exit(),
                   lambda s: s.retire_targets_outside_gate(),
                   lambda s: s.finalize_external())
        queue = deque([(StopState(), 0)])
        seen = {StopState()}
        while queue:
            state, depth = queue.popleft()
            invariants(state)
            if depth == 8:
                continue
            for action in actions:
                nxt = action(state)
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append((nxt, depth + 1))
        print("R12E_STATE_SPACE", len(seen))
        self.assertGreater(len(seen), 20)


if __name__ == "__main__":
    unittest.main(verbosity=2)
