"""R1.2-C deterministic callback-initiated stop/unregister fault injection.

REFERENCE MODEL ONLY. Simulates retain/release obligations when an external VBL
callback stops or unregisters its framebuffer. It does not execute IOKit code,
prove a reentrant IOFramebuffer::stop implementation, or test real devices.
"""
import unittest


class Ref:
    def __init__(self, name, refs=1):
        self.name = name
        self.refs = refs
        self.freed = 0

    def retain(self):
        self.assert_alive()
        self.refs += 1

    def release(self):
        self.assert_alive()
        self.refs -= 1
        if self.refs == 0:
            self.freed += 1

    def assert_alive(self):
        if self.refs <= 0:
            raise ReferenceError(f"UAF model: {self.name}")


class Framebuffer:
    def __init__(self):
        self.owner = Ref("NMIntelFB")
        self.sender = Ref("IOTimerEventSource")
        self.slot = None
        self.enabled = True
        self.phase = "ARMED"
        self.calls = 0
        self.rearmed = 0
        self.dropped = 0
        self.cleanup = 0
        self.after_external_callback_alive = []

    def register(self, target):
        if self.phase != "ARMED":
            return False
        target.retain()
        previous = self.slot
        self.slot = target
        if previous is not None:
            previous.release()
        return True

    def unregister(self):
        previous = self.slot
        self.slot = None
        if previous is not None:
            previous.release()

    def stop(self):
        if self.phase != "ARMED":
            return False
        self.phase = "STOPPING"
        self.unregister()
        self.sender.release()  # removeEventSource + local source reference
        self.owner.release()   # model the caller dropping its owner reference
        self.phase = "DRAINED"
        self.cleanup += 1
        return True

    def fire(self, callback):
        if self.phase != "ARMED":
            self.dropped += 1
            return False

        # Corresponds to R1.2-C's explicit owner/sender retains before
        # touching external code. Workloop gate serialization is assumed.
        self.owner.retain()
        self.sender.retain()
        snapshot = self.slot
        if snapshot is not None and self.enabled:
            snapshot.retain()
            self.calls += 1
            callback(self)
            snapshot.release()
            self.owner.assert_alive()
            self.sender.assert_alive()
            self.after_external_callback_alive.append(True)

        if self.phase == "ARMED":
            self.rearmed += 1
        self.sender.release()
        self.owner.release()  # last operation: owner can die here
        return True


class CallbackStopTests(unittest.TestCase):
    def test_stop_inside_callback_does_not_free_active_owner(self):
        fb = Framebuffer()
        target = Ref("listener")
        fb.register(target)
        fb.fire(lambda x: self.assertTrue(x.stop()))
        self.assertEqual(fb.phase, "DRAINED")
        self.assertEqual(fb.owner.refs, 0)
        self.assertEqual(fb.owner.freed, 1)
        self.assertEqual(fb.after_external_callback_alive, [True])

    def test_stop_inside_callback_does_not_free_active_sender(self):
        fb = Framebuffer()
        fb.register(Ref("listener"))
        fb.fire(lambda x: x.stop())
        self.assertEqual(fb.sender.refs, 0)
        self.assertEqual(fb.sender.freed, 1)

    def test_reentrant_stop_never_rearms(self):
        fb = Framebuffer()
        fb.register(Ref("listener"))
        fb.fire(lambda x: x.stop())
        self.assertEqual(fb.rearmed, 0)

    def test_no_callbacks_after_stopped(self):
        fb = Framebuffer()
        fb.register(Ref("listener"))
        fb.fire(lambda x: x.stop())
        self.assertFalse(fb.fire(lambda x: self.fail("late call")))
        self.assertEqual(fb.dropped, 1)

    def test_unregister_inside_callback_keeps_snapshot_alive(self):
        fb = Framebuffer()
        target = Ref("listener")
        fb.register(target)
        fb.fire(lambda x: x.unregister())
        self.assertEqual(target.refs, 1)
        self.assertEqual(target.freed, 0)
        self.assertIsNone(fb.slot)
        self.assertEqual(fb.rearmed, 1)

    def test_replacement_inside_callback_preserves_old_target(self):
        fb = Framebuffer()
        old = Ref("old")
        new = Ref("new")
        fb.register(old)
        fb.fire(lambda x: self.assertTrue(x.register(new)))
        self.assertIs(fb.slot, new)
        self.assertEqual(old.refs, 1)
        self.assertEqual(new.refs, 2)

    def test_stop_with_owner_as_callback_target(self):
        fb = Framebuffer()
        fb.register(fb.owner)
        fb.fire(lambda x: x.stop())
        self.assertEqual(fb.owner.refs, 0)
        self.assertEqual(fb.owner.freed, 1)

    def test_stop_outside_callback_cleans_up_once(self):
        fb = Framebuffer()
        fb.register(Ref("listener"))
        self.assertTrue(fb.stop())
        self.assertFalse(fb.stop())
        self.assertEqual(fb.cleanup, 1)

    def test_register_after_stop_fails(self):
        fb = Framebuffer()
        fb.stop()
        self.assertFalse(fb.register(Ref("late")))

    def test_callback_without_listener_does_not_retain_target(self):
        fb = Framebuffer()
        fb.fire(lambda x: self.fail("unregistered listener called"))
        self.assertEqual(fb.calls, 0)
        self.assertEqual(fb.rearmed, 1)
        self.assertEqual(fb.owner.refs, 1)

    def test_disabled_interrupt_is_not_delivered(self):
        fb = Framebuffer()
        fb.register(Ref("listener"))
        fb.enabled = False
        fb.fire(lambda x: self.fail("disabled callback called"))
        self.assertEqual(fb.calls, 0)

    def test_without_explicit_owner_retention_is_observably_invalid(self):
        # Negative control: old behavior if the external callback drops
        # the final owner ref and the caller accesses it on return.
        owner = Ref("unguarded-owner")
        owner.release()
        with self.assertRaises(ReferenceError):
            owner.assert_alive()

    def test_without_explicit_sender_retention_is_observably_invalid(self):
        sender = Ref("unguarded-timer")
        sender.release()
        with self.assertRaises(ReferenceError):
            sender.assert_alive()

    def test_retain_release_balance_with_normal_callback(self):
        fb = Framebuffer()
        target = Ref("listener")
        fb.register(target)
        fb.fire(lambda _: None)
        self.assertEqual((fb.owner.refs, fb.sender.refs, target.refs), (1, 1, 2))
        self.assertEqual(fb.rearmed, 1)
        self.assertEqual(fb.calls, 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
