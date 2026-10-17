#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pre-load bundle check: does each kext's Info.plist agree with what the gate builds?

A kext that links but whose CFBundleExecutable names a different file, or whose identifier collides with
another bundle, will not load - and that failure would look like "the driver is broken" at KEXT-LOAD
time. This check is offline and needs no device.
"""
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

W = Path(r"D:\Hactk\gpu-r5-20261017")
SRC = W / "src"
OUT = W / "evidence" / "preload"
OUT.mkdir(parents=True, exist_ok=True)

# bundle -> (plist path relative to src, executable the gate produces)
BUNDLES = {
    "NVRM": ("kexts/NVRM/Info.plist", "NVRM"),
    "NVRMFB": ("kexts/NVRMFB/fb/Info.plist", "NVRMFB"),
    "NVAccel": ("kexts/NVRM/accel/Info.plist", "NVAccel"),
    "NVRMAGDC": ("kexts/NVRM/agdc/Info.plist", "NVRMAGDC"),
    "NMIntelFB": ("kexts/NMIntelFB/Info.plist", "NMIntelFB"),
    "NMIntelFBVirtual": ("kexts/NMIntelFB/Info-virtual.plist", "NMIntelFBVirtual"),
}


def plist_dict(path):
    """Flatten the first-level plist dict; enough for the keys we check."""
    root = ET.parse(path).getroot()
    d = root.find("dict")
    out = {}
    if d is None:
        return out
    key = None
    for child in d:
        if child.tag == "key":
            key = child.text
        elif key is not None:
            out[key] = child
            key = None
    return out


def text_of(node):
    return (node.text or "").strip() if node is not None else ""


def main():
    checks, fails = [], []

    def check(name, ok, detail=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail})
        if not ok:
            fails.append(name)

    ids = {}
    for bundle, (rel, exe) in BUNDLES.items():
        p = SRC / rel
        if not p.exists():
            check(f"{bundle}: plist exists", False, rel)
            continue
        d = plist_dict(p)
        ident = text_of(d.get("CFBundleIdentifier"))
        declared = text_of(d.get("CFBundleExecutable"))
        ids.setdefault(ident, []).append(bundle)
        check(f"{bundle}: CFBundleExecutable matches the linked binary", declared == exe,
              f"plist says {declared!r}, gate links {exe!r}")
        check(f"{bundle}: identifier is non-empty and namespaced", ident.count(".") >= 2, ident)
        check(f"{bundle}: bundle is a kext (OSBundleLibraries present or an IOKit personality)",
              "OSBundleLibraries" in d or "IOKitPersonalities" in d)

    dup = {k: v for k, v in ids.items() if len(v) > 1}
    check("no two bundles share an identifier", not dup, json.dumps(dup))

    # the virtual variant must be distinguishable from the real one even though both build intelfb.cpp
    real = text_of(plist_dict(SRC / BUNDLES["NMIntelFB"][0]).get("CFBundleIdentifier"))
    virt = text_of(plist_dict(SRC / BUNDLES["NMIntelFBVirtual"][0]).get("CFBundleIdentifier"))
    check("the virtual Intel bundle has its own identifier", real != virt, f"{real} vs {virt}")

    # every personality's IOProviderClass must be a class the tree can supply (documented, not invented)
    builtin = {"IOPCIDevice", "IOFramebuffer", "IOService", "IOPlatformDevice", "IOResources"}
    # classes the tree itself declares (e.g. NVRMDisplay) are legitimate providers too
    declared = set()
    for src_file in SRC.rglob("*.cpp") if hasattr(SRC, "rglob") else []:
        try:
            txt = src_file.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        declared.update(re.findall(r"class\s+(NVRM\w+|NM\w+)\b", txt))
        declared.update(re.findall(r"OSDefineMetaClassAndStructors\(\s*(\w+)", txt))
    known_providers = builtin | declared
    for bundle, (rel, exe) in BUNDLES.items():
        p = SRC / rel
        if not p.exists():
            continue
        d = plist_dict(p)
        pers = d.get("IOKitPersonalities")
        if pers is None:
            continue
        for node in pers.iter():
            if node.tag == "key" and node.text == "IOProviderClass":
                continue
        raw = p.read_text(encoding="utf-8")
        for cls in set(re.findall(r"<key>IOProviderClass</key>\s*<string>([^<]+)</string>", raw)):
            check(f"{bundle}: IOProviderClass {cls} is a known IOKit class", cls in known_providers, cls)

    # NVRMDisplay is published programmatically (OSTypeAlloc + publish in NVRM.cpp), not by a plist
    # personality. What matters is that the class exists there and the dependent plists name it.
    nvrm_src = (SRC / "kexts/NVRM/NVRM.cpp").read_text(encoding="utf-8")
    fbs_raw = (SRC / "kexts/NVRMFB/fb/Info.plist").read_text(encoding="utf-8")
    if "NVRMDisplay" in fbs_raw:
        check("NVRMFB's provider class NVRMDisplay is defined by NVRM",
              "class NVRMDisplay : public IOService" in nvrm_src
              and "OSDefineMetaClassAndStructors(NVRMDisplay" in nvrm_src)
        check("NVRM publishes that nub at start (so NVRM must load before NVRMFB)",
              "OSTypeAlloc(NVRMDisplay)" in nvrm_src and "publish" in nvrm_src)

    rec = {"level": "PRE-LOAD (bundle/plist consistency, offline)",
           "checks": checks, "result": "PASS" if not fails else "FAIL", "failures": fails}
    (OUT / "bundle-consistency.json").write_text(json.dumps(rec, indent=1), encoding="utf-8")
    for c in checks:
        print(("PASS " if c["ok"] else "FAIL ") + c["check"] + (("  [" + c["detail"] + "]") if c["detail"] and not c["ok"] else ""))
    print(f"RESULT: {len(checks) - len(fails)}/{len(checks)} checks; {rec['result']}")
    return 0 if not fails else 1


if __name__ == "__main__":
    raise SystemExit(main())
