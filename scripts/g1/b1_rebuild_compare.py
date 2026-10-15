#!/usr/bin/env python3
"""G1 B1 rebuild-candidate acceptance: compare OGKM Darwin objects built with an inferred configuration against the
released NullMoth v1.15.0 NVRM (static, read-only). Report only; the verdict is for human review.

Checks per module (nvidia = RM, nvidia-modeset = KMS):
  closure    archive-pull model: roots = OGKM globals named in NullMoth kexts/NVRM sources; the closure must equal the
             set of candidate objects whose functions appear in NVRM (released link observed 954/954 and 189/189).
  functions  for every function name defined once in NVRM and once among candidate objects: byte-identical after
             masking the candidate's relocation fields and trailing alignment padding.
  markers    endbr64 at entry, .cold.N outlined parts, imports of ___bzero / ___stack_chk_fail / retpoline thunks."""
import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from macho_obj import MachO  # noqa: E402

ENDBR64 = b"\xf3\x0f\x1e\xfa"
NOP_HEX = ("90", "cc", "6690", "0f1f00", "0f1f4000", "0f1f440000", "660f1f440000", "0f1f8000000000",
           "0f1f840000000000", "660f1f840000000000", "662e0f1f840000000000", "66662e0f1f840000000000",
           "6666662e0f1f840000000000", "666666662e0f1f840000000000", "66666666662e0f1f840000000000",
           "6666666666662e0f1f840000000000", "666666666666662e0f1f840000000000")
NOPS = sorted((bytes.fromhex(h) for h in NOP_HEX), key=len, reverse=True)
WATCH_IMPORTS = ("___bzero", "___stack_chk_fail", "___stack_chk_guard", "_memset", "_memcpy")


def strip_padding(body):
    changed = True
    while changed and body:
        changed = False
        for n in NOPS:
            if body.endswith(n):
                body = body[:-len(n)]
                changed = True
                break
    return body


def same(cand, cmask, ref):
    # Preserve the shared range, including instruction immediates and relocation bytes.
    # Only the excess suffix of the longer body may be alignment padding.
    size = min(len(cand), len(ref))
    if not size:
        return False
    if any(cand[i] != ref[i] for i in range(size) if i not in cmask):
        return False
    longer = cand if len(cand) > len(ref) else ref
    return not strip_padding(longer[size:])


def idents(src_dir):
    out = set()
    for p in Path(src_dir).rglob("*"):
        if p.is_file() and p.suffix in (".c", ".cpp", ".inc", ".h", ".mm", ".m"):
            out |= set(re.findall(r"[A-Za-z_]\w*", p.read_text(encoding="latin-1")))
    return out


def module_report(objdir, nvrm, nvrm_funcs, nvrm_defined, roots_src, derived_output=None):
    # The pinned OGKM Makefile may successfully link its 230 modeset inputs
    # into nv-modeset-kernel.o. That *output* is not a 231st archive member:
    # including it duplicates every definition and invalidates comparison.
    all_objs = sorted(p for p in Path(objdir).glob("*.o") if p.is_file())
    excluded = [p for p in all_objs if p.name == derived_output]
    objs = [p for p in all_objs if p.name != derived_output]
    if not objs:
        return {"objects": 0, "error": f"no input objects in {objdir}"}
    parsed, bad = {}, []
    # Still parse-check the excluded aggregate; do not silently hide a bad .o.
    for p in excluded:
        try:
            aggregate = MachO(p)
            if aggregate.filetype != 1:
                raise ValueError("derived output is not an MH_OBJECT")
        except Exception as e:
            bad.append(f"derived {p.name}: {e}")
    for p in objs:
        try:
            parsed[p.name] = MachO(p)
        except Exception as e:  # report, do not hide
            bad.append(f"{p.name}: {e}")
    defs, undefs = {}, {}
    for name, m in parsed.items():
        defs[name] = {n for n, t, s, v in m.defined() if t & 0x01}
        undefs[name] = m.undefined()
    provider = defaultdict(set)
    for o, s in defs.items():
        for n in s:
            provider[n].add(o)
    roots = {n for n in provider if n.lstrip("_") in roots_src}
    pulled, need, seen = set(), list(roots), set()
    while need:
        n = need.pop()
        if n in seen:
            continue
        seen.add(n)
        for o in provider.get(n, ()):
            if o not in pulled:
                pulled.add(o)
                need.extend(undefs[o])
    observed = {o for o, m in parsed.items()
                if any(n in nvrm_defined for n, t, s, v in m.defined() if not n.startswith(("l", "L")))}

    cand_funcs = defaultdict(list)
    for o, m in parsed.items():
        for n, bodies in m.functions().items():
            for body, mask in bodies:
                cand_funcs[n].append((o, body, mask))
    stats = Counter()
    per_obj = defaultdict(Counter)
    markers = Counter()
    for n, entries in cand_funcs.items():
        if len(entries) != 1 or len(nvrm_funcs.get(n, ())) != 1:
            stats["ambiguous_or_absent"] += 1
            continue
        o, body, mask = entries[0]
        ref = nvrm_funcs[n][0][0]
        stats["compared"] += 1
        ok = same(body, mask, ref)
        stats["identical" if ok else "different"] += 1
        per_obj[o]["identical" if ok else "different"] += 1
        if ".cold." not in n:
            markers["cand_entry"] += 1
            markers["cand_endbr64"] += body.startswith(ENDBR64)
            markers["nvrm_endbr64_same_functions"] += ref.startswith(ENDBR64)
        else:
            markers["cold_split_functions"] += 1
    imports = Counter()
    for o in pulled:
        for n in undefs[o]:
            if n in WATCH_IMPORTS or "indirect_thunk" in n:
                imports[n] += 1
    worst = sorted(((c["different"], o) for o, c in per_obj.items() if c["different"]), reverse=True)[:25]
    return {
        "objects": len(objs), "objects_on_disk": len(all_objs),
        "excluded_derived_outputs": [p.name for p in excluded], "unparsable": bad,
        "closure": {"roots": len(roots), "predicted_pulled": len(pulled), "observed_in_nvrm": len(observed),
                    "agree": len(pulled & observed), "predicted_not_observed": sorted(pulled - observed)[:50],
                    "observed_not_predicted": sorted(observed - pulled)[:50]},
        "functions": dict(stats),
        "identical_rate": round(stats["identical"] / stats["compared"], 4) if stats["compared"] else None,
        "markers": dict(markers),
        "imports_by_pulled_objects": dict(imports),
        "most_different_objects": [{"object": o, "different": d, "identical": per_obj[o]["identical"]} for d, o in worst],
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--nvrm", required=True, help="released NVRM.kext/Contents/MacOS/NVRM")
    ap.add_argument("--nullmoth-nvrm-src", required=True, help="NullMoth kexts/NVRM directory at the pinned commit")
    ap.add_argument("--rm-objs", required=True, help="candidate src/nvidia/_out/Darwin_x86_64")
    ap.add_argument("--kms-objs", required=True, help="candidate src/nvidia-modeset/_out/Darwin_x86_64")
    ap.add_argument("--label", default="", help="free text recorded in the report (toolchain, flags)")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    nvrm = MachO(a.nvrm)
    nvrm_defined = {n for n, t, s, v in nvrm.defined()}
    nvrm_funcs = nvrm.functions()
    roots_src = idents(a.nullmoth_nvrm_src)
    report = {"label": a.label, "nvrm": a.nvrm, "nvrm_functions": len(nvrm_funcs),
              "reference_link": {"nvidia": "954/954 pulled objects observed", "nvidia-modeset": "189/189"},
              "nvidia": module_report(a.rm_objs, nvrm, nvrm_funcs, nvrm_defined, roots_src),
              "nvidia-modeset": module_report(a.kms_objs, nvrm, nvrm_funcs, nvrm_defined, roots_src,
                                              derived_output="nv-modeset-kernel.o")}
    Path(a.out).write_text(json.dumps(report, indent=1), encoding="utf-8")
    incomplete = False
    for m in ("nvidia", "nvidia-modeset"):
        r = report[m]
        if "error" in r:
            print(f"{m}: {r['error']}")
            incomplete = True
            continue
        if r["unparsable"] or not r["functions"].get("compared"):
            incomplete = True
        c = r["closure"]
        print(f"{m}: input objects {r['objects']} (disk {r['objects_on_disk']}, "
              f"derived excluded {r['excluded_derived_outputs']}) unparsable {len(r['unparsable'])}; "
              f"closure agree {c['agree']} "
              f"(pulled {c['predicted_pulled']}, observed {c['observed_in_nvrm']}); functions {r['functions']} "
              f"identical_rate {r['identical_rate']}; markers {r['markers']}; imports {r['imports_by_pulled_objects']}")

    if incomplete:
        print("DIAGNOSTICS_INCOMPLETE: missing/unparsable objects or no comparable functions; not acceptance evidence")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
