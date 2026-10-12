"""R1.2-D: deterministic two-gate ABBA deadlock witness (reference only).

Models the lock ordering observed in public IOGraphics/IOFramebuffer.cpp:
  IOFramebuffer::stop(): SYS -> FB
and the callback context in the pinned R1.2-C NMIntelFB patch:
  VBL action already holds FB, then external callback MAY invoke stop().

It does NOT execute XNU, macOS 15.5 IOFramebuffer or any kext.
A cycle is conditional on a particular interleaving, not proof of an
observed deadlock or proof of the shipping macOS 15.5 implementation.
"""
from dataclasses import dataclass, field
import unittest


@dataclass
class Gates:
    owner: dict = field(default_factory=lambda: {"SYS": None, "FB": None})
    depth: dict = field(default_factory=lambda: {"SYS": 0, "FB": 0})
    waiting: dict = field(default_factory=dict)

    def acquire(self, thread, gate):
        assert gate in self.owner
        current = self.owner[gate]
        if current is None or current == thread:
            self.owner[gate] = thread
            self.depth[gate] += 1
            self.waiting.pop(thread, None)
            return True
        self.waiting[thread] = gate
        return False

    def release(self, thread, gate):
        if self.owner[gate] != thread:
            raise ValueError("releasing an unowned gate")
        self.depth[gate] -= 1
        if self.depth[gate] == 0:
            self.owner[gate] = None

    def blocked_by(self, thread):
        gate = self.waiting.get(thread)
        return self.owner[gate] if gate else None

    def wait_cycle(self):
        for start in self.waiting:
            seen = set()
            node = start
            while node in self.waiting:
                if node in seen:
                    return True
                seen.add(node)
                node = self.blocked_by(node)
                if node is None:
                    break
        return False


def interleaved_system_stop_and_callback_stop():
    g = Gates()
    assert g.acquire("callback", "FB")
    assert g.acquire("system_stop", "SYS")
    assert not g.acquire("system_stop", "FB")
    assert not g.acquire("callback", "SYS")
    return g


def safe_deferred_stop_order():
    g = Gates()
    assert g.acquire("callback", "FB")
    # External callback only requests later teardown. It does NOT call stop().
    g.release("callback", "FB")
    assert g.acquire("deferred_stop", "SYS")
    assert g.acquire("deferred_stop", "FB")
    g.release("deferred_stop", "FB")
    g.release("deferred_stop", "SYS")
    return g


class LockOrderWitnessTests(unittest.TestCase):
    def test_conditional_abba_interleaving_is_cycle(self):
        g = interleaved_system_stop_and_callback_stop()
        self.assertTrue(g.wait_cycle())
        self.assertEqual(g.blocked_by("callback"), "system_stop")
        self.assertEqual(g.blocked_by("system_stop"), "callback")

    def test_reentrant_same_gate_does_not_break_cross_gate_cycle(self):
        g = interleaved_system_stop_and_callback_stop()
        self.assertTrue(g.acquire("callback", "FB"))
        self.assertTrue(g.wait_cycle())
        g.release("callback", "FB")

    def test_extra_refcounts_do_not_break_lock_wait_cycle(self):
        g = interleaved_system_stop_and_callback_stop()
        owner_references, timer_references = 4, 3
        self.assertGreater(owner_references, 0)
        self.assertGreater(timer_references, 0)
        self.assertTrue(g.wait_cycle())

    def test_callback_only_uses_fb_gate_no_cycle(self):
        g = Gates()
        self.assertTrue(g.acquire("callback", "FB"))
        self.assertTrue(g.acquire("callback", "FB"))
        self.assertFalse(g.wait_cycle())
        g.release("callback", "FB")
        g.release("callback", "FB")

    def test_system_to_fb_acquisition_is_acyclic_without_reverse_wait(self):
        g = Gates()
        self.assertTrue(g.acquire("system_stop", "SYS"))
        self.assertTrue(g.acquire("system_stop", "FB"))
        self.assertFalse(g.wait_cycle())

    def test_ordered_stop_blocks_until_callback_releases_gate(self):
        g = Gates()
        g.acquire("callback", "FB")
        g.acquire("system_stop", "SYS")
        self.assertFalse(g.acquire("system_stop", "FB"))
        self.assertFalse(g.wait_cycle())
        g.release("callback", "FB")
        self.assertTrue(g.acquire("system_stop", "FB"))
        self.assertFalse(g.wait_cycle())

    def test_deferred_stop_only_after_callback_returns_has_no_cycle(self):
        g = safe_deferred_stop_order()
        self.assertFalse(g.wait_cycle())
        self.assertEqual(g.owner, {"SYS": None, "FB": None})

    def test_callback_target_destructor_synchronously_entering_stop_recreates_cycle(self):
        # A target's final release is a potential reentrant external call.
        # The model does not assert that every destructor behaves this way.
        g = interleaved_system_stop_and_callback_stop()
        self.assertTrue(g.wait_cycle())

    def test_releasing_unowned_gate_rejected(self):
        g = Gates()
        g.acquire("callback", "FB")
        with self.assertRaises(ValueError):
            g.release("system_stop", "FB")

    def test_system_gate_remains_separate_from_fb_gate(self):
        g = Gates()
        g.acquire("callback", "FB")
        self.assertIsNone(g.owner["SYS"])
        self.assertEqual(g.owner["FB"], "callback")

    def test_no_cycle_when_one_side_is_not_waiting(self):
        g = Gates()
        g.acquire("callback", "FB")
        g.acquire("system_stop", "SYS")
        self.assertFalse(g.acquire("system_stop", "FB"))
        self.assertFalse(g.wait_cycle())

    def test_gate_recursion_count_is_balanced(self):
        g = Gates()
        g.acquire("callback", "FB")
        g.acquire("callback", "FB")
        g.release("callback", "FB")
        self.assertEqual(g.owner["FB"], "callback")
        g.release("callback", "FB")
        self.assertIsNone(g.owner["FB"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
