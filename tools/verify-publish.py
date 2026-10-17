#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Verify the published state has not drifted from the evidence it claims.

Checks, all offline:
  * the gate's patch series lists patches that exist in research/gpu-safety-r5/
  * every patch in the repo matches the workspace copy byte for byte (when present)
  * the round-trip record's patch count matches the gate series length
  * latest run recorded in verification.json is referenced by the matrix document
Exit code is non-zero on any drift, so this can gate a publish.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

REPO = Path(r"D:\Hactk\honor-hackintosh-lab")
WS = Path(r"D:\Hactk\gpu-r5-20261017")


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    checks, fails = [], []

    def check(name, ok, detail=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail})
        if not ok:
            fails.append(name)

    gate = (REPO / "scripts/gpu-safety-r5/native_compile.py").read_text(encoding="utf-8")
    m = re.search(r"enumerate\(\((.*?)\), 1\):", gate, re.S)
    series = re.findall(r'"([^"]+\.patch)"', m.group(1)) if m else []
    check("the gate lists a patch series", len(series) >= 18, f"count={len(series)}")

    missing = [s for s in series if not (REPO / "research/gpu-safety-r5" / s).exists()]
    check("every patch in the gate exists in the repo", not missing, f"missing={missing}")

    drift = []
    for s in series:
        ws = WS / "patches" / s
        if not ws.exists():
            ws = Path(r"D:\Hactk\gpu-mainline-20261017\patches") / s
        if ws.exists() and sha(ws) != sha(REPO / "research/gpu-safety-r5" / s):
            drift.append(s)
    check("repo patches match the validated workspace copies", not drift, f"drift={drift}")

    rt = json.loads((WS / "evidence/roundtrip.json").read_text(encoding="utf-8"))
    check("the round-trip covered the whole series", rt.get("result") == "PASS" and len(rt.get("patches", [])) == len(series),
          f"roundtrip={rt.get('result')} patches={len(rt.get('patches', []))} series={len(series)}")

    v = json.loads((WS / "evidence/ci-r5/verification.json").read_text(encoding="utf-8"))
    runs = set()
    for k, val in v.items():
        if isinstance(val, dict):
            r = val.get("run")
            if isinstance(r, dict) and r.get("id"):
                runs.add(str(r["id"]))
            if val.get("id"):
                runs.add(str(val["id"]))
    matrix = (REPO / "research/gpu-safety-r5/ACCEPTANCE-MATRIX-20261018.md").read_text(encoding="utf-8")
    check("the matrix cites a recorded run", any(r in matrix for r in runs), f"runs={sorted(runs)[-3:]}")
    newest = max(runs) if runs else None
    check("the matrix cites the newest recorded run", newest in matrix if newest else False, f"newest={newest}")

    k2 = (REPO / "knowledge/02_CURRENT_STATE.md").read_text(encoding="utf-8")
    check("the knowledge base points at the matrix", "ACCEPTANCE-MATRIX-20261018" in k2[:3000])

    rec = {"level": "PUBLISH-CONSISTENCY (offline, no build)",
           "checks": checks, "result": "PASS" if not fails else "FAIL", "failures": fails}
    (WS / "evidence/publish").mkdir(parents=True, exist_ok=True)
    (WS / "evidence/publish/consistency.json").write_text(json.dumps(rec, indent=1), encoding="utf-8")
    for c in checks:
        print(("PASS " if c["ok"] else "FAIL ") + c["check"] + (("  [" + c["detail"] + "]") if c["detail"] and not c["ok"] else ""))
    print(f"RESULT: {len(checks) - len(fails)}/{len(checks)} checks; {rec['result']}")
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
