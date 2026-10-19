#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Structural checks for the GPU suspend/resume state machine (offline, no device).

They encode the contract written in R37-PM-STATE-MACHINE-20261019.md, so a busy-gate fix cannot be written
by moving one flag and leaving the other three truths inconsistent.

Rules
  A1  gpuSuspend marks the GPU suspended before nvkms_xnu_suspend_commit()
  A2  gpuResume resumes NVKMS and marks the GPU running
  A3  gKmsPmState is set to Suspended only inside nvkms_xnu_suspend_commit()
  A4  suspend_abort() is never called after a successful commit in the same function (it is a no-op then)
  B1  the RM-busy branch does not reach rm_power_management()
  B2  the RM-busy branch does not call suspend_abort()
  B3  if the busy branch changes fGpuPm it must also resume NVKMS (no one-sided rollback)
  C1  setPowerState wakes the GPU when the ordinal is non-zero and the GPU was suspended

Usage:
    python3 tools/check-pm-state-machine.py --source <fully patched NullMoth tree>
    python3 tools/check-pm-state-machine.py --self-test
"""
import argparse
import json
import re
import sys
from pathlib import Path

NVRM = "kexts/NVRM/NVRM.cpp"
OS = "kexts/NVRM/os-nvkms-xnu.cpp"


def braces(text, start):
    i = text.index("{", start)
    depth = 0
    for k in range(i, len(text)):
        if text[k] == "{":
            depth += 1
        elif text[k] == "}":
            depth -= 1
            if depth == 0:
                return text[i:k + 1]
    raise ValueError("unbalanced braces")


def body(text, signature):
    if signature not in text:
        raise KeyError(signature)
    return braces(text, text.index(signature))


def evaluate(nvrm, os_text):
    checks = []

    def check(name, ok, detail=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail})

    suspend = body(nvrm, "bool NVRM::gpuSuspend()")
    resume = body(nvrm, "void NVRM::gpuResume()")
    setpm = body(nvrm, "IOReturn NVRM::setPowerState(unsigned long ordinal, IOService *device)")
    commit = body(os_text, "NvBool nvkms_xnu_suspend_commit(NvU32 gpuId, uint32_t seq, uint32_t waitMs)")

    # A1 / A2
    susp_before_commit = (suspend.find("kGpuPmSuspended") < suspend.find("nvkms_xnu_suspend_commit(")
                          if "nvkms_xnu_suspend_commit(" in suspend else False)
    check("A1 gpuSuspend marks the GPU suspended before the NVKMS commit", susp_before_commit)
    check("A2 gpuResume resumes NVKMS and marks the GPU running",
          "nvkms_xnu_resume(" in resume and "kGpuPmRunning" in resume)

    # A3: Suspended state only in the commit function
    offenders = []
    for name, text in (("NVRM.cpp", nvrm), ("os-nvkms-xnu.cpp", os_text)):
        for m in re.finditer(r"gKmsPmState\s*=\s*kKmsPmSuspended", text):
            line_start = text.rfind("\n", 0, m.start()) + 1
            line = text[line_start:text.find("\n", m.start())]
            inside_commit = (name == "os-nvkms-xnu.cpp" and m.start() > os_text.index(commit)
                             and m.start() < os_text.index(commit) + len(commit))
            if not inside_commit:
                offenders.append(f"{name}: {line.strip()}")
    check("A3 only the NVKMS commit sets gKmsPmState = Suspended", not offenders, "; ".join(offenders[:3]))

    # A4: abort after commit is a no-op
    if "nvkms_xnu_suspend_abort(" in suspend and "nvkms_xnu_suspend_commit(" in suspend:
        ok = suspend.find("nvkms_xnu_suspend_abort(") < suspend.find("nvkms_xnu_suspend_commit(")
        check("A4 suspend_abort is not called after the commit", ok,
              "abort before commit" if ok else "abort would be a no-op here")
    else:
        check("A4 suspend_abort is not called after the commit", True, "no abort call in gpuSuspend")

    # Busy branch: the statement guarded by `if (busy)` … up to the next blank-line block boundary
    m = re.search(r"if\s*\(\s*busy\s*\)", suspend)
    busy_segment = ""
    if m:
        start = m.end()
        # take the guarded statement, or the braced block
        rest = suspend[start:].lstrip()
        if rest.startswith("{"):
            busy_segment = braces(suspend, suspend.index("{", start))
        else:
            busy_segment = suspend[start:suspend.find(";", start) + 1]
    tail_after_busy = suspend[m.end():] if m else ""

    check("B1 the RM-busy branch does not reach rm_power_management",
          "rm_power_management" not in busy_segment,
          "busy branch is a log/assignment only" if "rm_power_management" not in busy_segment
          else "busy branch calls rm_power_management")
    check("B2 the RM-busy branch does not call suspend_abort",
          "nvkms_xnu_suspend_abort" not in busy_segment)
    changes_pm = "kGpuPmRunning" in busy_segment
    resumes = "nvkms_xnu_resume(" in busy_segment
    check("B3 a busy branch that clears the suspended flag also resumes NVKMS",
          (not changes_pm) or resumes,
          "no flag change" if not changes_pm else ("resume present" if resumes else "one-sided rollback"))

    # B4: the busy path must be terminal - it must not fall through into standby
    terminal = bool(re.search(r"return\s+false\s*;|goto\s+\w+", busy_segment))
    fallthrough_standby = (not terminal) and ("rm_power_management" in tail_after_busy)
    check("B4 a timed-out gate does not fall through into STANDBY", not fallthrough_standby,
          "terminates before standby" if not fallthrough_standby
          else "logs, then continues to rm_power_management(STANDBY)")

    # C1: wake path
    wake = "ordinal != 0" in setpm and "gpuResume()" in setpm
    check("C1 setPowerState resumes when the GPU was suspended", wake)

    result = "PASS" if all(c["ok"] for c in checks) else "FAIL"
    return {"level": "SOURCE-STRUCTURE-ONLY; PM-STATE-MACHINE-NOT-ACCEPTED", "checks": checks,
            "result": result, "failures": [c for c in checks if not c["ok"]]}


SELF_CASES = {
    "consistent": ("""
bool NVRM::gpuSuspend() {
    OSCompareAndSwap(kGpuPmRunning, kGpuPmSuspended, &fGpuPm);
    nvkms_xnu_suspend_commit(0, seq, 1000);
    const int busy = nv_xnu_pm_close(10000);
    if (busy) { LOG("busy"); return false; }
    rm_power_management(NULL, &fNv, NV_PM_ACTION_STANDBY);
    return true;
}
void NVRM::gpuResume() { nvkms_xnu_resume(1); OSCompareAndSwap(kGpuPmSuspended, kGpuPmRunning, &fGpuPm); }
IOReturn NVRM::setPowerState(unsigned long ordinal, IOService *device) {
    if (ordinal == 0) gpuSuspend(); else if (ordinal != 0) gpuResume();
    return kIOPMAckImplied; }
""", """
NvBool nvkms_xnu_suspend_commit(NvU32 gpuId, uint32_t seq, uint32_t waitMs) { gKmsPmState = kKmsPmSuspended; return true; }
""", True),
    "fallthrough": ("""
bool NVRM::gpuSuspend() {
    OSCompareAndSwap(kGpuPmRunning, kGpuPmSuspended, &fGpuPm);
    nvkms_xnu_suspend_commit(0, seq, 1000);
    const int busy = nv_xnu_pm_close(10000);
    if (busy) LOG("busy, continue");
    rm_power_management(NULL, &fNv, NV_PM_ACTION_STANDBY);
    return true;
}
void NVRM::gpuResume() { nvkms_xnu_resume(1); OSCompareAndSwap(kGpuPmSuspended, kGpuPmRunning, &fGpuPm); }
IOReturn NVRM::setPowerState(unsigned long ordinal, IOService *device) {
    if (ordinal != 0) gpuResume(); return kIOPMAckImplied; }
""", """
NvBool nvkms_xnu_suspend_commit(NvU32 gpuId, uint32_t seq, uint32_t waitMs) { gKmsPmState = kKmsPmSuspended; return true; }
""", False),
    "abort_after_commit": ("""
bool NVRM::gpuSuspend() {
    OSCompareAndSwap(kGpuPmRunning, kGpuPmSuspended, &fGpuPm);
    nvkms_xnu_suspend_commit(0, seq, 1000);
    const int busy = nv_xnu_pm_close(10000);
    if (busy) { nvkms_xnu_suspend_abort(seq); return false; }
    rm_power_management(NULL, &fNv, NV_PM_ACTION_STANDBY);
    return true;
}
void NVRM::gpuResume() { nvkms_xnu_resume(1); OSCompareAndSwap(kGpuPmSuspended, kGpuPmRunning, &fGpuPm); }
IOReturn NVRM::setPowerState(unsigned long ordinal, IOService *device) {
    if (ordinal != 0) gpuResume(); return kIOPMAckImplied; }
""", """
NvBool nvkms_xnu_suspend_commit(NvU32 gpuId, uint32_t seq, uint32_t waitMs) { gKmsPmState = kKmsPmSuspended; return true; }
""", False),
    "one_sided_rollback": ("""
bool NVRM::gpuSuspend() {
    OSCompareAndSwap(kGpuPmRunning, kGpuPmSuspended, &fGpuPm);
    nvkms_xnu_suspend_commit(0, seq, 1000);
    const int busy = nv_xnu_pm_close(10000);
    if (busy) { OSCompareAndSwap(kGpuPmSuspended, kGpuPmRunning, &fGpuPm); return false; }
    rm_power_management(NULL, &fNv, NV_PM_ACTION_STANDBY);
    return true;
}
void NVRM::gpuResume() { nvkms_xnu_resume(1); OSCompareAndSwap(kGpuPmSuspended, kGpuPmRunning, &fGpuPm); }
IOReturn NVRM::setPowerState(unsigned long ordinal, IOService *device) {
    if (ordinal != 0) gpuResume(); return kIOPMAckImplied; }
""", """
NvBool nvkms_xnu_suspend_commit(NvU32 gpuId, uint32_t seq, uint32_t waitMs) { gKmsPmState = kKmsPmSuspended; return true; }
""", False),
}


def self_test():
    bad = 0
    for name, (nvrm, os_text, expected) in SELF_CASES.items():
        rec = evaluate(nvrm, os_text)
        ok = rec["result"] == ("PASS" if expected else "FAIL")
        print(f"{'ok  ' if ok else 'BAD '} {name:20} expected {'PASS' if expected else 'FAIL'} got {rec['result']}")
        if not ok:
            for f in rec["failures"]:
                print("      ", f["check"], "|", f["detail"])
        bad += 0 if ok else 1
    print(f"self-test: {len(SELF_CASES) - bad}/{len(SELF_CASES)}")
    return 0 if bad == 0 else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", type=Path)
    ap.add_argument("--out", type=Path)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    if not a.source:
        print(__doc__)
        return 2
    nvrm = (a.source / NVRM).read_text(encoding="utf-8")
    os_text = (a.source / OS).read_text(encoding="utf-8")
    rec = evaluate(nvrm, os_text)
    if a.out:
        a.out.mkdir(parents=True, exist_ok=True)
        (a.out / "pm-state.json").write_text(json.dumps(rec, indent=2) + "\n", encoding="utf-8")
    for c in rec["checks"]:
        print(("PASS " if c["ok"] else "FAIL ") + c["check"] + ("" if c["ok"] else " | " + c["detail"]))
    print(f"RESULT: {sum(c['ok'] for c in rec['checks'])}/{len(rec['checks'])}; {rec['result']}")
    return 0 if rec["result"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
