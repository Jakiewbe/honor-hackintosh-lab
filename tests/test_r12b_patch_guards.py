#!/usr/bin/env python3
"""R1.2-B source-invariant gates for a review-only VBL patch.

These are intentionally not XNU scheduling/lifetime proofs or driver load tests.
Invoke against a temporary checkout AFTER R1.1 and R1.2-B have been applied.
"""
import argparse
import json
from pathlib import Path

def inspect(root: Path) -> dict:
    source = (root / "kexts/NMIntelFB/intelfb.cpp").read_text(encoding="utf-8")
    accel = (root / "kexts/NVRM/accel/nvrm-accel.cpp").read_text(encoding="utf-8")
    def contains(fragment: str) -> bool:
        return fragment in source
    checks = {
        "vbl_uses_iotimer_event_source": contains("IOTimerEventSource *fVblTimer = nullptr;"),
        "raw_vbl_thread_call_removed": not contains("thread_call_allocate(vblFire, this)"),
        "vbl_gate_uses_xnu_run_action": contains("wl->runAction(registerGate, this, &update)"),
        "interrupt_unregistration_is_not_noop": contains("wl->runAction(unregisterGate, this, cookie)"),
        "interrupt_enable_disable_is_not_noop": contains("wl->runAction(stateGate, this, cookie"),
        "callback_snapshots_interrupt_handler": contains("const Irq snapshot = me->fVbl;"),
        "callback_protects_target_lifetime": contains("if (snapshot.target) snapshot.target->retain();")
            and contains("if (snapshot.target) snapshot.target->release();"),
        "slot_retains_registered_target": contains("u->target->retain();"),
        "timer_callback_only_rearms_while_armed": contains("me->fVblPhase != kVblArmed || me->fVblTimer != timer"),
        "timer_schedule_failure_rejects": contains('IFBLOG("VBL reschedule failed; refusing subsequent callbacks")'),
        "start_failure_is_fail_closed_both_builds": source.count("if (!armVbl()) {") == 2
            and source.count("disarmVbl();") >= 3,
        "stop_cancels_timer_before_surface_release": source.index("    disarmVbl();", source.index("void NMIntelFB::stop("))
            < source.index("    OSSafeReleaseNULL(fSurfMap);", source.index("void NMIntelFB::stop(")),
        "same_gate_clears_slots": contains("unregisterGate(owner, &me->fVbl"),
        "timer_teardown_removes_event_source": contains("wl->removeEventSource(timer);"),
        "r11_intel_capacity_guard_still_present": contains("r->phys = 0; r->actualSize = mappedBytes;"),
        "r11_accel_dst_capacity_guard_still_present": "!q.actualSize || q.actualSize < dstNeeded" in accel,
        "r11_unsafe_async_enqueue_still_disabled": "if (gIopAsync && pipe) return nvAccelIopAsyncStart" not in accel,
    }
    return {
        "status": "PASS" if all(checks.values()) else "BLOCKED",
        "checks": checks,
        "limitations": [
            "String-level source assertions, not a verified kernel concurrency proof.",
            "stop invoked synchronously from a VBL callback remains UNPROVEN.",
            "IOFramebuffer callback ownership/reentrancy and actual loadability remain UNPROVEN.",
            "NVAccel native compilation and RTX 2050 Metal acceleration NOT TESTED.",
        ],
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = inspect(args.source)
    except (OSError, ValueError) as exc:
        result = {"status": "BLOCKED", "error": str(exc)}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(0 if result["status"] == "PASS" else 2)
