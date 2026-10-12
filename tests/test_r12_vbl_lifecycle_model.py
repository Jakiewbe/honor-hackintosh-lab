"""R1.2-A deterministic VBL callback lifetime reference model.

This is not kernel code. The model assumes a serialized workloop gate and
tracks when unregister/stop may acknowledge a request. It intentionally
excludes synchronous stop invoked reentrantly from the callback: that case
requires a separately proven teardown protocol before any kext patch.
"""
from dataclasses import dataclass, replace
from collections import deque
import unittest


@dataclass(frozen=True)
class Vbl:
    phase: str = 'NEW'          # NEW, ARMED, STOPPING, DRAINED, REJECTED
    registered: bool = False
    timer_pending: bool = False
    callback_active: bool = False
    callback_has_target: bool = False
    unregister_waiting: bool = False
    stop_waiting: bool = False
    unregister_ack: bool = False
    callbacks_started: int = 0
    callbacks_finished: int = 0
    late_callbacks: int = 0

    def start(self, timer_ok=True):
        if self.phase != 'NEW':
            return self
        if not timer_ok:
            return replace(self, phase='REJECTED')
        return replace(self, phase='ARMED', timer_pending=True)

    def register(self):
        if self.phase != 'ARMED' or self.unregister_waiting:
            return self
        return replace(self, registered=True, unregister_ack=False)

    def tick(self):
        if self.phase != 'ARMED' or not self.timer_pending or self.callback_active:
            return self
        # Callback takes the workloop gate. A pending stop/unregister cannot
        # return success while this gate is held.
        started = self.callbacks_started + int(self.registered)
        return replace(self, callback_active=True, callback_has_target=self.registered, timer_pending=False,
                       callbacks_started=started,
                       late_callbacks=self.late_callbacks + int(self.unregister_ack and self.registered))

    def unregister(self):
        if self.callback_active:
            return replace(self, unregister_waiting=True, unregister_ack=False)
        return replace(self, registered=False, unregister_waiting=False,
                       unregister_ack=True)

    def callback_done(self):
        if not self.callback_active:
            return self
        x = replace(self, callback_active=False, callback_has_target=False,
                    callbacks_finished=self.callbacks_finished + int(self.callback_has_target))
        if x.stop_waiting:
            # stop took the gate after the callback completed
            return replace(x, phase='STOPPING', registered=False, timer_pending=False,
                           unregister_waiting=False, stop_waiting=False)
        if x.unregister_waiting:
            x = replace(x, registered=False, unregister_waiting=False,
                        unregister_ack=True)
        if x.phase == 'ARMED':
            return replace(x, timer_pending=True)
        return x

    def stop(self):
        if self.phase in ('DRAINED', 'REJECTED'):
            return self
        if self.callback_active:
            return replace(self, stop_waiting=True)
        return replace(self, phase='STOPPING', timer_pending=False,
                       registered=False, unregister_waiting=False)

    def drain(self):
        if self.phase == 'STOPPING' and not self.callback_active and not self.timer_pending:
            return replace(self, phase='DRAINED')
        return self


def invariants(state):
    assert state.late_callbacks == 0
    assert state.callbacks_finished <= state.callbacks_started
    if state.phase in ('STOPPING', 'DRAINED', 'REJECTED'):
        assert not state.timer_pending
        assert not state.registered
    if state.unregister_ack:
        assert not state.registered
    if state.phase == 'DRAINED':
        assert not state.callback_active


class LifecycleTests(unittest.TestCase):
    def test_failed_timer_allocation_never_publishes(self):
        m = Vbl().start(timer_ok=False)
        self.assertEqual(m.phase, 'REJECTED')
        self.assertFalse(m.register().registered)

    def test_registration_rejected_before_arm(self):
        self.assertFalse(Vbl().register().registered)

    def test_armed_timer_invokes_then_rearms(self):
        m = Vbl().start().register().tick()
        self.assertTrue(m.callback_active)
        m = m.callback_done()
        self.assertTrue(m.timer_pending)
        self.assertEqual(m.callbacks_started, 1)

    def test_unregister_without_inflight_callback(self):
        m = Vbl().start().register().unregister()
        self.assertTrue(m.unregister_ack)
        self.assertEqual(m.tick().callbacks_started, 0)

    def test_unregister_during_callback_cannot_ack_early(self):
        m = Vbl().start().register().tick().unregister()
        self.assertFalse(m.unregister_ack)
        self.assertTrue(m.unregister_waiting)
        m = m.callback_done()
        self.assertTrue(m.unregister_ack)
        self.assertFalse(m.registered)
        self.assertEqual(m.tick().callbacks_started, 1)

    def test_stop_during_callback_waits_then_prevents_rearm(self):
        m = Vbl().start().register().tick().stop()
        self.assertEqual(m.phase, 'ARMED')
        self.assertTrue(m.stop_waiting)
        m = m.callback_done()
        self.assertEqual(m.phase, 'STOPPING')
        self.assertFalse(m.timer_pending)
        self.assertEqual(m.drain().phase, 'DRAINED')

    def test_stop_without_inflight_cancels_pending_timer(self):
        m = Vbl().start().register().stop().drain()
        self.assertEqual(m.phase, 'DRAINED')
        self.assertEqual(m.tick().callbacks_started, 0)

    def test_double_stop_remains_drained(self):
        m = Vbl().start().stop().drain()
        self.assertEqual(m.stop().drain(), m)

    def test_post_stop_register_does_not_resurrect(self):
        m = Vbl().start().stop().drain().register()
        self.assertFalse(m.registered)
        self.assertFalse(m.timer_pending)

    def test_state_space_exhaustive_to_depth_9(self):
        actions = (lambda m: m.start(True), lambda m: m.start(False),
                   lambda m: m.register(), lambda m: m.tick(),
                   lambda m: m.unregister(), lambda m: m.callback_done(),
                   lambda m: m.stop(), lambda m: m.drain())
        frontier = deque([(Vbl(), 0)])
        seen = {Vbl()}
        while frontier:
            state, depth = frontier.popleft()
            invariants(state)
            if depth == 9:
                continue
            for action in actions:
                next_state = action(state)
                if next_state not in seen:
                    seen.add(next_state)
                    frontier.append((next_state, depth + 1))
        self.assertGreater(len(seen), 35)
        print(f'EXHAUSTIVE_MODEL_STATES={len(seen)}')


if __name__ == '__main__':
    unittest.main(verbosity=2)
