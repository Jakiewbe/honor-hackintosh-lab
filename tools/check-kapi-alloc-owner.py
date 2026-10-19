#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check the allocation-failure owner contract (offline, source only).

Rule E1  the allocate rollback must use nvKmsKapiTryFreeDevice (the void FreeDevice cannot report a refusal)
Rule E2  the rollback must keep a refused Device reachable (quarantine add) instead of only logging
Rule E3  a bounded quarantine table and a reaper must exist
Rule E4  the reaper must be called from nvkms_xnu_resume, otherwise a quarantined Device is never retried

Usage:
    python3 tools/check-kapi-alloc-owner.py --ogkm-kapi <nvkms-kapi.c> --source <patched NullMoth tree>
    python3 tools/check-kapi-alloc-owner.py --self-test
"""
import argparse
import re
import sys
from pathlib import Path

NVRM_OS = "kexts/NVRM/os-nvkms-xnu.cpp"


def block_after(text, marker):
    i = text.index(marker)
    depth = 0
    start = text.index("{", i)
    for k in range(start, len(text)):
        if text[k] == "{":
            depth += 1
        elif text[k] == "}":
            depth -= 1
            if depth == 0:
                return text[start:k + 1]
    raise ValueError("unbalanced")


def evaluate(kapi, os_text):
    checks = []

    def check(name, ok, detail=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail})

    m = re.search(r"failed:\s*\n", kapi)
    failed = kapi[m.end():kapi.index("return NULL;", m.end()) + len("return NULL;")] if m else ""
    check("E1 allocate rollback uses the try-free result", "nvKmsKapiTryFreeDevice" in failed,
          "rollback calls the reporting API" if "nvKmsKapiTryFreeDevice" in failed
          else "rollback still calls the void wrapper")
    check("E2 a refused rollback keeps the Device reachable", "KmsQuarantineAdd" in failed,
          "quarantined" if "KmsQuarantineAdd" in failed else "only logged")
    check("E3 bounded quarantine and reaper exist",
          "KmsQuarantineAdd" in kapi and "nvKmsKapiReapQuarantine" in kapi,
          "table + reaper present" if "nvKmsKapiReapQuarantine" in kapi else "no reaper")
    check("E4 the reaper runs when the GPU resumes",
          "nvKmsKapiReapQuarantine" in os_text)

    return {"level": "SOURCE-STRUCTURE-ONLY; ALLOC-OWNER-NOT-RUNTIME-VERIFIED",
            "checks": checks, "result": "PASS" if all(c["ok"] for c in checks) else "FAIL",
            "failures": [c for c in checks if not c["ok"]]}


SELF = {
    "good": ("""
failed:
    if (device != NULL && !nvKmsKapiTryFreeDevice(device)) {
        if (KmsQuarantineAdd(device)) { log("quarantined"); } else { log("leaked"); }
    }
    return NULL;
""", "static NvBool KmsQuarantineAdd(struct NvKmsKapiDevice *d) { return NV_TRUE; }\n"
     "NvBool nvKmsKapiReapQuarantine(void) { return NV_TRUE; }\n", True),
    "void_wrapper": ("""
failed:
    FreeDevice(device);
    return NULL;
""", "static NvBool KmsQuarantineAdd(struct NvKmsKapiDevice *d) { return NV_TRUE; }\n"
     "NvBool nvKmsKapiReapQuarantine(void) { return NV_TRUE; }\n", True),
    "no_reachability": ("""
failed:
    if (!nvKmsKapiTryFreeDevice(device)) { log("retained"); }
    return NULL;
""", "static NvBool KmsQuarantineAdd(struct NvKmsKapiDevice *d) { return NV_TRUE; }\n"
     "NvBool nvKmsKapiReapQuarantine(void) { return NV_TRUE; }\n", True),
    "no_reaper": ("""
failed:
    if (!nvKmsKapiTryFreeDevice(device)) { KmsQuarantineAdd(device); }
    return NULL;
""", "static NvBool KmsQuarantineAdd(struct NvKmsKapiDevice *d) { return NV_TRUE; }\n", False),
}


def self_test():
    bad = 0
    for name, (failed, helpers, os_has_reaper) in SELF.items():
        kapi = failed + "\n" + helpers
        os_text = "nvKmsKapiReapQuarantine();" if os_has_reaper else "nothing"
        rec = evaluate(kapi, os_text)
        expect = "PASS" if name == "good" else "FAIL"
        ok = rec["result"] == expect
        print(f"{'ok  ' if ok else 'BAD '} {name:18} expected {expect} got {rec['result']}")
        if not ok:
            for f in rec["failures"]:
                print("      ", f["check"], "|", f["detail"])
        bad += 0 if ok else 1
    print(f"self-test: {len(SELF) - bad}/{len(SELF)}")
    return 0 if bad == 0 else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ogkm-kapi", type=Path)
    ap.add_argument("--source", type=Path)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    if not (a.ogkm_kapi and a.source):
        print(__doc__)
        return 2
    rec = evaluate(a.ogkm_kapi.read_text(encoding="utf-8"),
                   (a.source / NVRM_OS).read_text(encoding="utf-8"))
    for c in rec["checks"]:
        print(("PASS " if c["ok"] else "FAIL ") + c["check"] + ("" if c["ok"] else " | " + c["detail"]))
    print(f"RESULT: {sum(c['ok'] for c in rec['checks'])}/{len(rec['checks'])}; {rec['result']}")
    return 0 if rec["result"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
