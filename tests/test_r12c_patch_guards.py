#!/usr/bin/env python3
"""R1.2-C source guards for review-only explicit callback lifetime pins.

Static lexical constraints cannot establish IOKit kernel concurrency safety.
"""
import argparse
import json
from pathlib import Path


def check(root: Path):
    c = (root / "kexts/NMIntelFB/intelfb.cpp").read_text(encoding="utf-8")
    b = c[c.index("    static void vblFire(OSObject *owner, IOTimerEventSource *timer) {"):
          c.index("    bool armVbl()", c.index("    static void vblFire(OSObject *owner, IOTimerEventSource *timer) {"))]
    owner_retain = b.find("        me->retain();")
    timer_retain = b.find("        timer->retain();")
    external = b.find("            snapshot.proc(snapshot.target, snapshot.ref);")
    timer_release = b.rfind("        timer->release();")
    owner_release = b.rfind("        me->release();")
    pinned = b[owner_retain:owner_release] if owner_retain >= 0 and owner_release > owner_retain else ""
    checks = {
        "owner_sender_retain_before_external_callback":
            0 <= owner_retain < timer_retain < external,
        "both_released_after_last_external_callback":
            0 <= external < timer_release < owner_release,
        "owner_release_is_last_noncomment_statement":
            b.rstrip().endswith("me->release(); // Last use of me; it may be destroyed here.\n    }"),
        "no_early_returns_between_lifetime_pins":
            bool(pinned) and "return;" not in pinned,
        "snapshot_target_itself_is_retained":
            "if (snapshot.target) snapshot.target->retain();" in b and
            "if (snapshot.target) snapshot.target->release();" in b,
        "no_vbl_rearm_when_stopped":
            "if (me->fVblPhase == kVblArmed && me->fVblTimer == timer)" in b,
        "sender_identity_checked":
            "if (!me || !timer || me->fVblPhase != kVblArmed || me->fVblTimer != timer) return;" in b,
        "source_lifecycle_still_uses_workloop_gate":
            "wl->runAction(registerGate, this, &update)" in c and
            "wl->runAction(unregisterGate, this, cookie)" in c,
        "r11_scanout_size_still_preserved":
            "r->phys = 0; r->actualSize = mappedBytes;" in c,
    }
    return {
        "status": "PASS" if all(checks.values()) else "BLOCKED",
        "checks": checks,
        "known_unresolved": [
            "IOFramebuffer::stop reentrant destruction ordering, including IOCommandGate removal.",
            "Concurrent driver termination and target destructor reentrancy.",
            "Runtime VBL reschedule failure after display publication.",
            "NVAccel native compilation, real graphics hardware and Metal untested."
        ],
        "evidence_kind": "static lexical structure only"
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    try:
        data = check(args.source)
    except (OSError, ValueError) as exc:
        data = {"status": "BLOCKED", "exception": str(exc)}
    print(json.dumps(data, indent=2, ensure_ascii=False))
    raise SystemExit(0 if data["status"] == "PASS" else 2)
