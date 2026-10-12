#!/usr/bin/env python3
"""R1.2-G pinned IOGraphics-599 VBL consumer contract audit (source-only).

Required source: official macOS 15.5 IOGraphics submodule commit
4d3fd008c80d1414c9da8f02ea67d534b47158c2.
A PASS means these hazards are present in the expected source; it never means
safe external callback dispatch or a runnable graphics driver.
"""
import argparse
import hashlib
import json
from pathlib import Path

EXPECTED_GIT_BLOB = "4763b2fc53cbcaeb2ad5c94531727975d6bc0ff8"


def inspect(path: Path) -> dict:
    payload = path.read_bytes()
    blob = hashlib.sha1(
        b"blob " + str(len(payload)).encode("ascii") + b"\x00" + payload
    ).hexdigest()
    if blob != EXPECTED_GIT_BLOB:
        return {"status": "BLOCKED", "reason": "Apple IOGraphics source blob mismatch",
                "actual_blob": blob, "expected_blob": EXPECTED_GIT_BLOB,
                "runtime_decision": "NO_GO"}
    src = payload.decode("utf-8")

    def between(begin, end):
        a = src.index(begin)
        return src[a:src.index(end, a + len(begin))]

    registration = between("// vbl events", "// connect events")
    consumer = between("void IOFramebuffer::handleVBL(", "void IOFramebuffer::resetCursor(")
    stop = between("void IOFramebuffer::stop(", "void IOFramebuffer::free()")
    conditions = {
        "vbl_callback_is_ioframebuffer_handleVBL":
            "registerForInterruptType( kIOFBVBLInterruptType" in registration
            and "(IOFBInterruptProc) &handleVBL" in registration,
        "callback_target_is_this":
            "this, priv, &__private->vblInterrupt" in registration,
        "handleVBL_reads_framebuffer_private_memory":
            "GetShmem(inst)" in consumer and "inst->__private->actualVBLCount" in consumer,
        "handleVBL_modifies_shared_timestamp":
            "shmem->vblTime  = now;" in consumer,
        "handleVBL_modifies_shared_counter":
            "shmem->vblCount++;" in consumer,
        "handleVBL_signals_waiters":
            "semaphore_signal_all(inst->vblSemaphore)" in consumer,
        "handleVBL_can_schedule_another_timer":
            "inst->__private->vblUpdateTimer->setTimeoutMS" in consumer,
        "stop_unregisters_vbl_callback":
            "UNREGISTER_INTERRUPT(__private->vblInterrupt)" in stop,
        "stop_destroys_vbl_event_source":
            "RELEASE_EVENT_SOURCE(FBWL(this), __private->vblUpdateTimer)" in stop,
        "stop_can_release_shared_cursor":
            "OSSafeReleaseNULL(sharedCursor)" in stop,
    }
    return {
        "status": "PASS" if all(conditions.values()) else "BLOCKED",
        "source": "IOGraphics-599, macOS 15.5 public source",
        "source_git_blob": blob,
        "contracts": conditions,
        "runtime_decision": "NO_GO",
        "reason": (
            "Moving IOFramebuffer::handleVBL outside the controller gate also "
            "exposes shared-memory and stop-time object lifetime contracts; "
            "source checks do not establish an implementation."
        ),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ioframebuffer", required=True, type=Path)
    args = parser.parse_args()
    try:
        result = inspect(args.ioframebuffer)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        result = {"status": "BLOCKED", "error": str(exc), "runtime_decision": "NO_GO"}
    print(json.dumps(result, indent=2, ensure_ascii=False))
    raise SystemExit(0 if result["status"] == "PASS" else 2)
