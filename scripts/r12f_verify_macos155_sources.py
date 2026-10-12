#!/usr/bin/env python3
"""R1.2-F: verify macOS 15.5 Apple OSS lock-order evidence.

Offline, read-only and fail-closed. Input dirs contain ONLY public Apple source
files at the exact macOS 15.5 published Git SHAs. This checks lexical source
contracts, NOT binary/runtime synchronization, hardware or driver loadability.
"""
import argparse
import hashlib
import json
from pathlib import Path

APPLE_DISTRIBUTION = "macos-155"
APPLE_REFS = {
    "IOGraphics": {
        "tag": "IOGraphics-599",
        "commit": "4d3fd008c80d1414c9da8f02ea67d534b47158c2",
        "files": {
            "IOGraphicsFamily/IOFramebuffer.cpp": "4763b2fc53cbcaeb2ad5c94531727975d6bc0ff8",
        },
    },
    "xnu": {
        "tag": "xnu-11417.121.6",
        "commit": "a1e26a70f38d1d7daa7b49b258e2f8538ad81650",
        "files": {
            "iokit/Kernel/IOWorkLoop.cpp": "1d93f463c39d7bb688d7311ef411ed5ef916a147",
            "iokit/Kernel/IOTimerEventSource.cpp": "0ee1fe90653d0babb85e71c84d35ad8db8160fdf",
            "iokit/Kernel/IOEventSource.cpp": "8323ce3120ac913e6b35dade31472653cf61af77",
        },
    },
}
MANIFEST_BLOB = "7ee09a21ebfbf9b55ebba981a5cfe83c11c288c8"


def blob_id(payload: bytes) -> str:
    """Git SHA-1 blob object id, not plain file SHA-1."""
    prefix = b"blob " + str(len(payload)).encode("ascii") + b"\x00"
    return hashlib.sha1(prefix + payload).hexdigest()


def region(src: str, start: str, end: str) -> str:
    start_pos = src.find(start)
    if start_pos < 0:
        raise ValueError("Missing required symbol " + start)
    end_pos = src.find(end, start_pos + len(start))
    if end_pos < 0:
        raise ValueError("Missing end marker " + end)
    return src[start_pos:end_pos]


def in_order(src: str, first: str, second: str) -> bool:
    p = src.find(first)
    q = src.find(second)
    return p >= 0 and q >= 0 and p < q


def inspect(manifest: Path, graphics: Path, xnu: Path):
    observations = {}
    checksum = {}
    data = manifest.read_bytes()
    checksum["apple_release_json"] = blob_id(data) == MANIFEST_BLOB
    metadata = json.loads(data)
    project_tags = {entry["project"]: entry["tag"] for entry in metadata["projects"]}
    observations["official_macos_15_5_manifest"] = (
        metadata.get("release") == "macOS 15.5"
        and metadata.get("major_release") == "macOS 15"
        and project_tags.get("IOGraphics") == APPLE_REFS["IOGraphics"]["tag"]
        and project_tags.get("xnu") == APPLE_REFS["xnu"]["tag"]
    )
    sources = {}
    for name, root in (("IOGraphics", graphics), ("xnu", xnu)):
        for path, expected in APPLE_REFS[name]["files"].items():
            payload = (root / path).read_bytes()
            checksum[name + "/" + path] = blob_id(payload) == expected
            sources[name + "/" + path] = payload.decode("utf-8")

    fb = sources["IOGraphics/IOGraphicsFamily/IOFramebuffer.cpp"]
    wl = sources["xnu/iokit/Kernel/IOWorkLoop.cpp"]
    timer = sources["xnu/iokit/Kernel/IOTimerEventSource.cpp"]
    event = sources["xnu/iokit/Kernel/IOEventSource.cpp"]

    stop = region(fb, "void IOFramebuffer::stop(", "void IOFramebuffer::free()")
    terminate = region(fb, "bool IOFramebuffer::terminate(", "bool IOFramebuffer::willTerminate(")
    workloop = region(fb, "IOWorkLoop * IOFramebuffer::getWorkLoop(", "void IOFramebuffer::setCaptured(")
    timeout = region(timer, "IOTimerEventSource::timeoutAndRelease(", "void\nIOTimerEventSource::timeoutSignaled(")
    runaction = region(wl, "IOWorkLoop::runAction(Action inAction,", "IOWorkLoop::_maintRequest(")
    remove = region(wl, "case mRemoveEvent:", "\n\tdefault:")
    cancel = region(timer, "IOTimerEventSource::cancelTimeout()", "void\nIOTimerEventSource::enable()")
    init = region(event, "IOEventSource::init(OSObject *inOwner,", "void\nIOEventSource::free(")

    observations.update({
        "stop_acquires_sys_then_fb": in_order(
            stop, "SYSGATEGUARD(sysgated);", "FBGATEGUARD(ctrlgated, this);"
        ),
        "terminate_acquires_sys_then_fb": in_order(
            terminate, "SYSGATEGUARD(sysgated);", "FBGATEGUARD(ctrlgated, this);"
        ),
        "sys_gate_is_system_workloop": (
            "#define SYSGATEGUARD(guardname) IOGraphicsWorkLoop::GateGuard" in fb
            and "guardname(gIOFBSystemWorkLoop, \"S\", __FUNCTION__)" in fb
        ),
        "fb_gate_is_controller_workloop": (
            "#define FBWL(fb)" in fb and "fb->__private->controller->fWl" in fb
            and "guardname(FBWL(fb), (fb)->thisName, __FUNCTION__)" in fb
        ),
        "get_workloop_is_controller": "__private->controller->fWl" in workloop,
        "timer_callback_runs_inside_workloop_gate": in_order(
            timeout, "wl->closeGate();", "me->invokeAction(doit, me, me->owner, me->workLoop);"
        ) and in_order(
            timeout, "me->invokeAction(doit, me, me->owner, me->workLoop);",
            "wl->openGate();"
        ),
        "run_action_holds_recursive_gate": in_order(
            runaction, "closeGate();", "res = (*inAction)(target, arg0, arg1, arg2, arg3);"
        ) and in_order(
            runaction, "res = (*inAction)(target, arg0, arg1, arg2, arg3);", "openGate();"
        ),
        "remove_event_source_drops_ownership": in_order(
            remove, "inEvent->setWorkLoop(NULL);", "inEvent->release();"
        ),
        "timer_default_is_passive_priority_high": (
            "kIOTimerEventSourceOptionsPriorityKernelHigh" in
            region(timer, "IOTimerEventSource::timerEventSource(OSObject", "void\nIOTimerEventSource::free()")
        ) and ("thread_call_cancel((tc))" in timer),
        "timer_cancel_does_not_imply_callback_drain": (
            "_thread_call_cancel((thread_call_t) calloutEntry)" in cancel
        ),
        "event_source_owner_not_retained_in_init": (
            "owner = inOwner;" in init and "inOwner->retain()" not in init
            and "owner->retain()" not in init
        ),
    })
    complete = all(checksum.values()) and all(observations.values())
    return {
        "status": "PASS" if complete else "BLOCKED",
        "source_distribution": APPLE_DISTRIBUTION,
        "apple_pinned_references": {key: {"tag": value["tag"], "commit": value["commit"]}
                                   for key, value in APPLE_REFS.items()},
        "git_blob_integrity": checksum,
        "version_specific_source_contracts": observations,
        "risk_decision": "RUNTIME_NO_GO",
        "limitations": [
            "Source release exact-match checks, NOT macOS 15.5 kernel binary verification.",
            "SYS->FB in stop/terminate plus FB-held external timer callbacks admits an ABBA schedule IF external callback reenters stop/terminate and another thread owns SYS.",
            "No proof that actual callback targets reenter stop, or that real hardware deadlocks.",
            "No safe IOService::stop executor or target destruction handoff is implemented.",
            "No macOS kext loading, Intel scanout, NVAccel, RTX 2050 or Metal tests."
        ],
    }


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--manifest", required=True, type=Path)
    p.add_argument("--graphics", required=True, type=Path)
    p.add_argument("--xnu", required=True, type=Path)
    args = p.parse_args()
    try:
        result = inspect(args.manifest, args.graphics, args.xnu)
    except (KeyError, UnicodeDecodeError, ValueError, OSError) as ex:
        result = {"status": "BLOCKED", "error": str(ex), "risk_decision": "RUNTIME_NO_GO"}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(0 if result["status"] == "PASS" else 2)
