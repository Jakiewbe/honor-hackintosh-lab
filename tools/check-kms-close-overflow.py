#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Structural guard for the deferred-close overflow path (regression guard, not runtime evidence).

Rules
  R1  kms_close_remember_locked links a wrapper that does not fit the table onto the overflow list
  R2  a drain walks that list and frees through kms_deferred_try_free_impl, unlinking on success
  R3  every kms_deferred_drain() call site also drains the overflow list in the same function

Why: the table holds KMS_DEFERRED_CAPACITY entries. Before R43 an overflowed close was only logged, so the
wrapper could never be reclaimed. The runtime behaviour is covered by the CPU scenario `overflow-reclaim`;
these rules keep the shape from silently reverting.

Usage:
    python3 tools/check-kms-close-overflow.py --source <patched NullMoth tree>
    python3 tools/check-kms-close-overflow.py --self-test
"""
import argparse
import re
import sys
from pathlib import Path

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
    raise ValueError("unbalanced")


def evaluate(os_text):
    checks = []

    def check(name, ok, detail=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail})

    remember = braces(os_text, os_text.index("static void kms_close_remember_locked"))
    check("R1 a close that does not fit the table is linked, not just logged",
          "nextOverflow = gKmsCloseOverflow" in remember and "gKmsCloseOverflow = popen" in remember,
          "linked" if "nextOverflow" in remember else "only logged")

    m = re.search(r"static void (kms_close_overflow_drain_locked|kms_close_overflow_drain)\(void\)", os_text)
    if not m:
        check("R2 an overflow drain frees through the deferred try-free", False, "no drain function")
    else:
        drain = braces(os_text, m.start())
        check("R2 an overflow drain frees through the deferred try-free",
              "kms_deferred_try_free_impl" in drain and "nextOverflow" in drain,
              "walks the list")

    calls = [(m.start(), m.group(0)) for m in re.finditer(r"kms_deferred_drain\s*\(", os_text)]
    companion = re.search(r"kms_close_overflow_drain(_locked)?\s*\(\s*\)", os_text)
    check("R3 every deferred drain also drains the overflow list",
          bool(companion) and len(calls) >= 1,
          f"{len(calls)} queue drain call(s), overflow drain present={bool(companion)}")

    return {"level": "SOURCE-STRUCTURE-ONLY; OVERFLOW-RUNTIME-COVERED-BY-CPU-SCENARIO",
            "checks": checks, "result": "PASS" if all(c["ok"] for c in checks) else "FAIL",
            "failures": [c for c in checks if not c["ok"]]}


GOOD = """
static struct nvkms_per_open *gKmsCloseOverflow;
static unsigned gKmsCloseOverflowCount;
static void kms_close_overflow_drain_locked(void)
{
    struct nvkms_per_open **link = &gKmsCloseOverflow;
    while (*link != NULL) {
        struct nvkms_per_open *popen = *link;
        if (kms_deferred_try_free_impl(popen, NULL) != 0) {
            *link = popen->nextOverflow; gKmsCloseOverflowCount--; continue;
        }
        link = &popen->nextOverflow;
    }
}
static void kms_close_remember_locked(struct nvkms_per_open *popen)
{
    if (kms_deferred_push(popen, popen->data) != 0) {
        popen->nextOverflow = gKmsCloseOverflow;
        gKmsCloseOverflow = popen;
    }
}
static void kms_close_retry_fire(void)
{
    kms_deferred_drain(&kKmsDeferredOps, 1, NULL);
    kms_close_overflow_drain_locked();
}
"""

BAD_LOG_ONLY = GOOD.replace("popen->nextOverflow = gKmsCloseOverflow;\n        gKmsCloseOverflow = popen;",
                            'kprintf("table full; retained without a slot");')
BAD_NO_COMPANION = GOOD.replace("    kms_close_overflow_drain_locked();\n", "")


def self_test():
    cases = {"good": (GOOD, True), "log_only": (BAD_LOG_ONLY, False), "no_companion": (BAD_NO_COMPANION, False)}
    bad = 0
    for name, (text, expect) in cases.items():
        rec = evaluate(text)
        ok = (rec["result"] == "PASS") == expect
        print(f"{'ok  ' if ok else 'BAD '} {name:14} expected {'PASS' if expect else 'FAIL'} got {rec['result']}")
        if not ok:
            for f in rec["failures"]:
                print("      ", f["check"], "|", f["detail"])
        bad += 0 if ok else 1
    print(f"self-test: {len(cases) - bad}/{len(cases)}")
    return 0 if bad == 0 else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", type=Path)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    if not a.source:
        print(__doc__)
        return 2
    rec = evaluate((a.source / OS).read_text(encoding="utf-8"))
    for c in rec["checks"]:
        print(("PASS " if c["ok"] else "FAIL ") + c["check"] + ("" if c["ok"] else " | " + c["detail"]))
    print(f"RESULT: {sum(c['ok'] for c in rec['checks'])}/{len(rec['checks'])}; {rec['result']}")
    return 0 if rec["result"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
