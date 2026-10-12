"""R1.2-E source-only deployment gate for the stacked R1.2-C candidate.

Scans exact known high-risk patterns after R1.1 + R1.2-B + R1.2-C patches.
This is a fail-closed REVIEW GATE, not a proof of the absence of races.
Never loads or builds a kext.

Default exit:
  0: scanner completed and emitted decision; NO_GO means do not deploy.
  2: --enforce-go demanded a safe gate but risk/uncertainty remains.
"""
import argparse
import json
from pathlib import Path


def inspect(root: Path):
    source = (root / "kexts/NMIntelFB/intelfb.cpp").read_text(encoding="utf-8")
    required = ["    static IOReturn registerGate(",
                "    static IOReturn unregisterGate(",
                "    static void vblFire(OSObject *owner, IOTimerEventSource *timer) {",
                "    void disarmVbl()",
                "void NMIntelFB::stop(IOService *provider)"]
    if any(marker not in source for marker in required):
        return {"decision": "NO_GO", "confidence": "unknown candidate or malformed source",
                "reason": "Required patch structure not found. Never approve by absence."}

    def region(start, end):
        return source[source.index(start):source.index(end, source.index(start))]

    register = region("    static IOReturn registerGate(", "    static IOReturn unregisterGate(")
    unregister = region("    static IOReturn unregisterGate(", "    static IOReturn stateGate(")
    vbl = region("    static void vblFire(OSObject *owner, IOTimerEventSource *timer) {",
                 "    bool armVbl()")
    stop = region("void NMIntelFB::stop(IOService *provider)",
                  "IODeviceMemory *NMIntelFB::getApertureRange(")
    observations = {
        "callback_dispatch_inside_timer_action": "snapshot.proc(snapshot.target, snapshot.ref)" in vbl,
        "registered_target_release_inside_gate": "previous->release();" in register,
        "unregistered_target_release_inside_gate": "previous->release();" in unregister,
        "snapshot_target_release_inside_callback_gate": "snapshot.target->release();" in vbl,
        "direct_sync_super_stop_still_called": "IOFramebuffer::stop(provider);" in stop,
        "owner_and_sender_pin_present":
            "me->retain();" in vbl and "timer->retain();" in vbl,
    }
    return {
        "decision": "NO_GO",
        "confidence": "observed lexical risk markers" if all(observations.values())
                      else "markers changed, human review required",
        "observations": observations,
        "blocking_conditions": [
            "External callback can request stop while FB gate is held; SYS->FB stop has ABBA risk.",
            "Final target releases under FB gate may reenter IOGraphics lifecycle.",
            "No proven outside-FB-gate finalizer with an IOService::stop-compatible contract.",
            "Version-matched macOS 15.5 IOGraphics lifecycle is unverified.",
        ],
        "note": "A clean build or missing string must never upgrade NO_GO to GO."
    }


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source", required=True, type=Path)
    p.add_argument("--enforce-go", action="store_true",
                   help="Return failure while runtime deployment is not approved.")
    args = p.parse_args()
    try:
        result = inspect(args.source)
    except (OSError, ValueError) as err:
        result = {"decision": "NO_GO", "reason": str(err)}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(2 if args.enforce_go else 0)
