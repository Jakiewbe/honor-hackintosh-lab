"""R1.2-G: hypothetical out-of-FB-gate VBL delivery contract, MODEL ONLY.

No IOKit implementation. The model deliberately rejects callback-initiated
synchronous stop: moving the callback off the controller gate removes one
ABBA route but may introduce self-join, framebuffer private-state races and
unbounded callback latency. Do NOT treat this as a deployable driver design.
"""
from collections import deque
from dataclasses import dataclass, replace
import unittest


@dataclass(frozen=True)
class Contract:
    phase: str = "ACTIVE"                 # ACTIVE, QUIESCING, FINALIZED
    slot: bool = True
    enabled: bool = True
    epoch: int = 0
    timer_gate: bool = False              # controller FB gate held by timer
    ticket: bool = False                  # queued callback owns target+owner refs
    ticket_epoch: int = -1
    delivering: bool = False              # callback execution OUTSIDE FB gate
    pinned_target: int = 0
    pinned_owner: int = 0
    retired_target_pending: bool = False
    retired_target_released: bool = False
    deliveries: int = 0
    skipped: int = 0
    finalizations: int = 0

    def timer_capture(self):
        if (self.phase != "ACTIVE" or self.ticket or self.delivering or self.timer_gate):
            return self
        # Simulated FB gate: snapshot & retain; no external callback invoked.
        if not self.slot or not self.enabled:
            return self
        return replace(self, timer_gate=True, ticket=True,
                       ticket_epoch=self.epoch, pinned_target=1, pinned_owner=1)

    def timer_exit(self):
        if not self.timer_gate:
            return self
        return replace(self, timer_gate=False)

    def unregister(self):
        # Atomic slot mutation under FB; no target final release under gate.
        if not self.slot:
            return self
        return replace(self, slot=False, epoch=self.epoch + 1,
                       retired_target_pending=True)

    def set_enabled(self, value):
        if not self.slot or self.phase != "ACTIVE" or self.enabled == value:
            return self
        return replace(self, enabled=value, epoch=self.epoch + 1)

    def dispatch_or_drop(self):
        # A real worker must revalidate under synchronization while ensuring
        # its external callback is invoked with neither SYS nor FB gate held.
        if not self.ticket or self.timer_gate or self.delivering:
            return self
        if self.phase == "ACTIVE" and self.slot and self.enabled and self.ticket_epoch == self.epoch:
            return replace(self, ticket=False, delivering=True)
        return replace(self, ticket=False, ticket_epoch=-1,
                       pinned_target=0, pinned_owner=0, skipped=self.skipped + 1)

    def callback_return(self):
        if not self.delivering:
            return self
        return replace(self, delivering=False, ticket_epoch=-1,
                       pinned_target=0, pinned_owner=0, deliveries=self.deliveries + 1)

    def stop_requested_by_other_thread(self):
        # Quiesce is not IOService::stop completion; the caller must still
        # be provided a proven synchronous drain/finalization protocol.
        if self.phase != "ACTIVE":
            return self
        return replace(self, phase="QUIESCING", slot=False, epoch=self.epoch + 1,
                       retired_target_pending=self.retired_target_pending or self.slot)

    def callback_requests_synchronous_stop(self):
        if self.delivering:
            return "BLOCKED_SELF_JOIN_AND_SHARED_STATE_UNPROVEN"
        return "NOT_IN_CALLBACK"

    def retire_target_outside_gates(self):
        if not self.retired_target_pending or self.timer_gate:
            return self
        # Safe retirement is only abstractly modeled: a true final release may
        # reenter IOService lifecycle and needs a stable independent executor.
        return replace(self, retired_target_pending=False, retired_target_released=True)

    def finalize_external(self):
        if (self.phase != "QUIESCING" or self.timer_gate or self.ticket or self.delivering
                or self.pinned_target or self.pinned_owner or self.retired_target_pending):
            return self
        return replace(self, phase="FINALIZED", finalizations=self.finalizations + 1)


def invariant(s):
    assert s.phase in {"ACTIVE", "QUIESCING", "FINALIZED"}
    assert not (s.ticket and s.delivering)
    assert s.pinned_owner == s.pinned_target == int(s.ticket or s.delivering)
    assert s.finalizations <= 1
    if s.timer_gate:
        assert s.ticket
    if s.retired_target_pending:
        assert not s.slot
    if s.phase == "FINALIZED":
        assert not s.ticket and not s.delivering
        assert not s.timer_gate and s.pinned_owner == 0
        assert not s.retired_target_pending


class VblOutOfGateContractTests(unittest.TestCase):
    def test_ticket_captures_under_fb_then_releases_gate_before_dispatch(self):
        s = Contract().timer_capture()
        self.assertTrue(s.timer_gate)
        self.assertFalse(s.dispatch_or_drop().delivering)
        s = s.timer_exit().dispatch_or_drop()
        self.assertTrue(s.delivering)
        self.assertFalse(s.timer_gate)

    def test_only_one_outstanding_ticket(self):
        s = Contract().timer_capture()
        self.assertEqual(s.timer_capture(), s)
        self.assertEqual(s.pinned_owner, 1)

    def test_unregister_before_dispatch_invalidates_old_ticket(self):
        s = Contract().timer_capture().timer_exit().unregister().dispatch_or_drop()
        self.assertEqual(s.skipped, 1)
        self.assertEqual(s.deliveries, 0)
        self.assertEqual(s.pinned_target, 0)

    def test_disable_before_dispatch_invalidates_old_ticket(self):
        s = Contract().timer_capture().timer_exit().set_enabled(False).dispatch_or_drop()
        self.assertEqual(s.skipped, 1)
        self.assertFalse(s.delivering)

    def test_reenable_does_not_resurrect_pre_disable_ticket(self):
        s = (Contract().timer_capture().timer_exit().set_enabled(False)
             .set_enabled(True).dispatch_or_drop())
        self.assertEqual(s.skipped, 1)

    def test_unregistration_during_delivery_preserves_pinned_target(self):
        s = Contract().timer_capture().timer_exit().dispatch_or_drop().unregister()
        self.assertEqual((s.pinned_target, s.delivering), (1, True))
        s = s.callback_return()
        self.assertEqual((s.pinned_target, s.deliveries), (0, 1))

    def test_stop_while_ticket_queued_drops_ticket_and_can_finalize(self):
        s = (Contract().timer_capture().timer_exit().stop_requested_by_other_thread()
             .dispatch_or_drop().retire_target_outside_gates().finalize_external())
        self.assertEqual(s.phase, "FINALIZED")
        self.assertEqual(s.skipped, 1)

    def test_stop_during_active_callback_must_not_finalize_early(self):
        s = Contract().timer_capture().timer_exit().dispatch_or_drop()
        s = s.stop_requested_by_other_thread().retire_target_outside_gates()
        self.assertEqual(s.finalize_external().finalizations, 0)
        self.assertEqual(s.callback_return().finalize_external().finalizations, 1)

    def test_sync_stop_from_callback_is_explicit_blocker(self):
        s = Contract().timer_capture().timer_exit().dispatch_or_drop()
        self.assertEqual(s.callback_requests_synchronous_stop(),
                         "BLOCKED_SELF_JOIN_AND_SHARED_STATE_UNPROVEN")

    def test_target_final_release_not_in_timer_gate(self):
        s = Contract().timer_capture().unregister()
        self.assertEqual(s.retire_target_outside_gates(), s)
        self.assertTrue(s.timer_exit().retire_target_outside_gates().retired_target_released)

    def test_no_new_ticket_after_stop(self):
        s = Contract().stop_requested_by_other_thread()
        self.assertEqual(s.timer_capture(), s)

    def test_duplicate_stop_finalize_idempotent(self):
        s = (Contract().stop_requested_by_other_thread().stop_requested_by_other_thread()
             .retire_target_outside_gates().finalize_external().finalize_external())
        self.assertEqual(s.finalizations, 1)

    def test_normal_callback_releases_pins_and_can_requeue(self):
        s = Contract().timer_capture().timer_exit().dispatch_or_drop().callback_return()
        self.assertEqual((s.deliveries, s.pinned_owner, s.pinned_target), (1, 0, 0))
        self.assertTrue(s.timer_capture().ticket)

    def test_disabled_slot_never_creates_ticket(self):
        s = Contract().set_enabled(False)
        self.assertFalse(s.timer_capture().ticket)

    def test_stop_cannot_finalize_with_pending_target_retirement(self):
        s = Contract().stop_requested_by_other_thread()
        self.assertEqual(s.finalize_external(), s)

    def test_state_space_to_depth_8(self):
        moves = (
            lambda s: s.timer_capture(), lambda s: s.timer_exit(),
            lambda s: s.unregister(), lambda s: s.set_enabled(False),
            lambda s: s.set_enabled(True), lambda s: s.dispatch_or_drop(),
            lambda s: s.callback_return(), lambda s: s.stop_requested_by_other_thread(),
            lambda s: s.retire_target_outside_gates(), lambda s: s.finalize_external(),
        )
        start = Contract()
        seen = {start}
        queue = deque([(start, 0)])
        while queue:
            state, depth = queue.popleft()
            invariant(state)
            if depth == 8:
                continue
            for move in moves:
                nxt = move(state)
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append((nxt, depth + 1))
        print("R12G_STATE_SPACE", len(seen))
        self.assertGreater(len(seen), 70)


if __name__ == "__main__":
    unittest.main(verbosity=2)
