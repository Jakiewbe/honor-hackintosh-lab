#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Run every offline acceptance gate and report one verdict.

Usage:
    python tools/verify-all.py [--workspace D:\\Hactk\\gpu-r5-20261017] [--skip-host]

Gates (in dependency order):
    1. bundle     - Info.plist vs linked binary, identifiers, provider classes   (no device)
    2. structure  - NVIDIA lifetime contract + Intel teardown contract           (no device)
    3. roundtrip  - the whole patch series applies and reverses cleanly          (needs git)
    4. publish    - published patches/docs match the recorded evidence            (no device)
    5. host       - extracted function bodies under ASan                          (needs WSL + g++)

Anything that needs the actual machine (KEXT-LOAD and above) is out of scope by design: this script
only proves what can be proven without it.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DEFAULT_WS = Path(os.environ.get("GPU_WORKSPACE", r"D:\Hactk\gpu-r5-20261017"))


def run(name, cmd, cwd, timeout=1800):
    started = time.time()
    try:
        p = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, timeout=timeout,
                           encoding="utf-8", errors="replace")
        out, code = (p.stdout or "") + (p.stderr or ""), p.returncode
    except FileNotFoundError as e:
        out, code = f"missing executable: {e}", 127
    except subprocess.TimeoutExpired:
        out, code = "timeout", 124
    return {"gate": name, "command": " ".join(str(c) for c in cmd), "exit": code,
            "seconds": round(time.time() - started, 1), "tail": out.strip().splitlines()[-6:]}


def wsl_path(p: Path) -> str:
    """Map a Windows drive path (D:/x) to its WSL mount path (/mnt/d/x)."""
    s = str(p).replace("\\", "/")
    if len(s) > 1 and s[1] == ":":
        return "/mnt/" + s[0].lower() + s[2:]
    return s


def series_from_roundtrip(ws: Path):
    """Import roundtrip_r5 and use its SERIES, so the order (including the r1..r4 patches that live in
    another directory) is never duplicated here."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("roundtrip_r5", ws / "work/roundtrip_r5.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)          # definitions only; its main() is under __main__
    return [Path(path) for _name, path in mod.SERIES]


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--workspace", default=str(DEFAULT_WS))
    ap.add_argument("--skip-host", action="store_true", help="skip the ASan host test")
    args = ap.parse_args()
    ws = Path(args.workspace)
    py = sys.executable

    # The structure gates read the *patched* tree, so the series is applied first and reversed at the
    # end. The round-trip gate then does its own apply+reverse as an independent check.
    src = ws / "src"

    results = []

    def step(name, cmd, cwd, timeout=600):
        r = run(name, cmd, cwd, timeout)
        results.append(r)
        return r

    step("bundle", [py, str(REPO / "tools/check-bundles.py")], REPO)
    # start from a verifiably clean tree: the series only applies to the pristine root commit
    root0 = ""
    rr = run("root-commit", ["git", "rev-list", "--max-parents=0", "HEAD"], src)
    if rr["exit"] == 0 and rr["tail"]:
        root0 = rr["tail"][-1].strip()
    if root0:
        step("reset-before-apply", ["git", "checkout", "-f", "--detach", "-q", root0], src)
        step("clean-before-apply", ["git", "clean", "-fdq"], src)
    # Apply through roundtrip_r5 --keep-applied: one validated apply path, then the structure gates read
    # exactly that tree, then the tree is reset.
    applied = step("apply-series", [py, str(ws / "work/roundtrip_r5.py"), "--keep-applied"], ws, 1800)
    if applied["exit"] == 0:
        step("structure-nvidia", [py, str(ws / "work/check_r11_lifetime.py")], ws)
        step("structure-intel", [py, str(ws / "work/check_intel_stop.py")], ws)
        step("structure-pm", [py, str(REPO / "tools/check-pm-exclusion.py"),
                             "--source", str(src), "--out",
                             str(ws / "evidence" / ("pm-structure-" + str(time.time_ns())))], REPO)
        # regenerate the lifetime test from the patched tree: never run a previously generated file
        step("gen-lifetime", [py, str(ws / "work/r11_fixture.py")], ws)
        if not args.skip_host:
            step("vbl-host", ["wsl", "-e", "bash", "-c",
                              f"GPU_R27_WORK={wsl_path(ws)} GPU_R27_OUT={wsl_path(ws)}/evidence/r27 "
                              f"bash {wsl_path(REPO)}/tools/run-r27-test.sh"], ws, 1800)
            step("pm-host", ["wsl", "-e", "bash", "-c",
                              f"GPU_R24_WORK={wsl_path(ws)} GPU_R24_OUT={wsl_path(ws)}/evidence/r24 "
                              f"bash {wsl_path(REPO)}/tools/run-r24-test.sh"], ws, 1800)
    root = ""
    r = run("root-commit", ["git", "rev-list", "--max-parents=0", "HEAD"], src)
    if r["exit"] == 0 and r["tail"]:
        root = r["tail"][-1].strip()
    if root:
        step("reset-pristine", ["git", "checkout", "-f", "--detach", "-q", root], src)
        step("clean-pristine", ["git", "clean", "-fdq"], src)
    step("roundtrip", [py, str(ws / "work/roundtrip_r5.py")], ws, 1800)
    step("publish", [py, str(REPO / "tools/verify-publish.py")], REPO)

    if not args.skip_host:
        step("host-asan", ["wsl", "-e", "bash", "-c", f"bash {wsl_path(ws)}/work/run-r11-test.sh"], ws, 1800)

    ok = all(r["exit"] == 0 for r in results)

    width = max(len(r["gate"]) for r in results)
    print(f"{'gate'.ljust(width)}  exit  time    last line")
    for r in results:
        last = r["tail"][-1] if r["tail"] else ""
        print(f"{r['gate'].ljust(width)}  {r['exit']:>4}  {r['seconds']:>5}s  {last[:96]}")

    record = {"level": "OFFLINE-ACCEPTANCE (bundle + structure + roundtrip + publish + host)",
              "workspace": str(ws), "result": "PASS" if ok else "FAIL", "gates": results,
              "not_covered": ["KEXT-LOAD", "GPU-RUNTIME", "DISPLAY-RUNTIME", "ACCELERATED-DESKTOP"],
              "note": "passing here proves offline consistency only; none of it is runtime evidence"}
    out_dir = ws / "evidence" / "verify-all"
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "summary.json").write_text(json.dumps(record, indent=1), encoding="utf-8")
    print(f"\nRESULT: {'PASS' if ok else 'FAIL'} | not covered: KEXT-LOAD and above (needs the machine)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())

