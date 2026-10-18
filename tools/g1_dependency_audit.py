#!/usr/bin/env python3
"""Lexical, reproducible dependency inventory; never a preprocessor or ABI proof.

All definition candidates and call-like identifiers are retained. Includes are
inventoried for each whole translation unit, not inferred from path keywords.
Darwin same-name definitions are candidates, not compatible implementations.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

OGKM_PIN = "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb"
NM_PIN = "ac55984c473e746c2a8ebea7ba0913461aa7c393"
NM_TREE = "528e804da39cb6c358727455385563d414606a70"
EXTS = {".c", ".h", ".cc", ".cpp", ".hpp"}
CONTROL = {"if", "else", "for", "while", "switch", "return", "sizeof", "do", "alignof", "__alignof__", "typeof", "__typeof__"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git_blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args])


def mask(text):
    # Preserve offsets and newlines while removing comments and literals.
    pat = r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\[\s\S]|[^"\\])*"|\'(?:\\[\s\S]|[^\'\\])*\''
    return re.sub(pat, lambda m: re.sub(r"[^\n]", " ", m.group()), text)


def no_directives(text):
    lines = text.splitlines(keepends=True)
    result, continued = [], False
    for line in lines:
        directive = continued or line.lstrip().startswith("#")
        continued = directive and line.rstrip().endswith("\\")
        result.append(re.sub(r"[^\n]", " ", line) if directive else line)
    return "".join(result)


def balanced(text, pos, opening="(", closing=")"):
    depth = 0
    for i in range(pos, len(text)):
        if text[i] == opening:
            depth += 1
        elif text[i] == closing:
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("unbalanced source at offset " + str(pos))


def definitions(text, names):
    """Candidate definitions, with balanced params/body and no 600-byte limit."""
    clean = no_directives(mask(text))
    result = []
    for m in re.finditer(r"\b([A-Za-z_]\w*)\s*\(", clean):
        name = m.group(1)
        if name not in names or name in CONTROL:
            continue
        start = clean.rfind("\n", 0, m.start()) + 1
        prefix = clean[start:m.start()].strip()
        if prefix and (not re.fullmatch(r"[A-Za-z_][\w \t*]*", prefix) or set(prefix.split()) & CONTROL):
            continue
        paren = clean.index("(", m.start())
        end = balanced(clean, paren)
        brace = end + 1
        while brace < len(clean) and clean[brace].isspace():
            brace += 1
        if brace == len(clean) or clean[brace] != "{":
            continue
        tail = balanced(clean, brace, "{", "}")
        body = clean[brace + 1:tail]
        calls = []
        for call in re.finditer(r"\b([A-Za-z_]\w*)\s*\(", body):
            if call.group(1) not in CONTROL:
                offset = brace + 1 + call.start()
                calls.append({"name": call.group(1), "line": text.count("\n", 0, offset) + 1})
        result.append({"name": name, "line": text.count("\n", 0, m.start()) + 1,
                       "end_line": text.count("\n", 0, tail) + 1,
                       "parameters": text[paren + 1:end].strip(),
                       "body_sha256": digest(text[brace:tail + 1].encode()),
                       "call_like_occurrences": calls})
    return result


def refs(path, text, pattern):
    return [{"path": path, "line": text.count("\n", 0, m.start()) + 1,
             "text": text.splitlines()[text.count("\n", 0, m.start())].strip()}
            for m in re.finditer(pattern, text)]


def load_sources(root, manifest=None, pin=OGKM_PIN, prefix=None):
    if manifest is None:
        if git(root, "rev-parse", "HEAD").decode().strip() != pin:
            raise ValueError("source pin mismatch")
        if git(root, "status", "--porcelain", "--untracked-files=no").strip():
            raise ValueError("tracked inputs modified")
        paths = [p for p in git(root, "ls-files", "-z").decode().split("\0") if p]
        expected = None
    else:
        if manifest.get("truncated") or manifest["sha"] != NM_TREE:
            raise ValueError("NullMoth tree not complete/fixed")
        expected = {r["path"]: r["sha"] for r in manifest["tree"] if r["type"] == "blob"}
        paths = [p for p in expected if p.startswith("kexts/")]
    sources, hashes, all_text = {}, {}, {}
    for rel in sorted(paths):
        if prefix and not rel.startswith(prefix):
            continue
        if expected is None and Path(rel).suffix not in EXTS and not rel.endswith(("Makefile", ".mk")):
            continue
        if expected is not None and Path(rel).suffix not in EXTS:
            continue
        data = (root / rel).read_bytes()
        if expected is not None and git_blob(data) != expected[rel]:
            raise ValueError("NullMoth blob mismatch: " + rel)
        text = data.decode("utf-8", errors="strict")
        all_text[rel] = text
        if Path(rel).suffix in EXTS:
            sources[rel] = text
            hashes[rel] = digest(data)
    return sources, hashes, all_text


def audit(nv, nm, names, manifest):
    ogkm, ogkm_hashes, build_text = load_sources(nv)
    darwin, darwin_hashes, _ = load_sources(nm, manifest, pin=NM_PIN, prefix="kexts/")
    targets, tu_paths = {}, set()
    for path, text in ogkm.items():
        for hit in definitions(text, names):
            hit["path"] = path
            targets.setdefault(hit["name"], []).append(hit)
            tu_paths.add(path)
    missing = sorted(set(names) - set(targets))
    if missing:
        raise ValueError("definitions not found: " + repr(missing))
    dependencies = {c["name"] for hits in targets.values() for hit in hits for c in hit["call_like_occurrences"]}
    local_index = {}
    for path, text in darwin.items():
        for hit in definitions(text, dependencies):
            local_index.setdefault(hit["name"], []).append({"path": path, "line": hit["line"],
                "parameters": hit["parameters"], "source_sha256": darwin_hashes[path]})
    units = {}
    for path in sorted(tu_paths):
        text = ogkm[path]
        includes = []
        for m in re.finditer(r'^\s*#\s*include\s*[<"]([^>"\n]+)[>"]', text, re.M):
            includes.append({"name": m.group(1), "line": text.count("\n", 0, m.start()) + 1})
        units[path] = {"sha256": ogkm_hashes[path], "includes": includes,
                       "symbols": sorted(n for n, hits in targets.items() if any(h["path"] == path for h in hits))}
    for hits in targets.values():
        for hit in hits:
            hit["darwin_same_name_candidates"] = {n: local_index[n] for n in sorted({c["name"] for c in hit["call_like_occurrences"]}) if n in local_index}
    altstack = []
    for path, text in build_text.items():
        altstack.extend(refs(path, text, r"\b__use_altstack__\b"))
    # Keep every lexical call occurrence to an audited function, including non-NULL arguments.
    call_sites = []
    for path, text in darwin.items():
        clean = no_directives(mask(text))
        defined = {(h["name"], h["line"]) for h in definitions(text, names)}
        for m in re.finditer(r"\b([A-Za-z_]\w*)\s*\(", clean):
            name = m.group(1)
            if name not in names:
                continue
            paren = clean.index("(", m.start())
            end = balanced(clean, paren)
            line = text.count("\n", 0, m.start()) + 1
            tail = clean[end + 1:].lstrip()
            if (name, line) in defined:
                kind = "definition"
            elif re.fullmatch(r"[A-Za-z_][\w \t*]*", clean[clean.rfind("\n", 0, m.start()) + 1:m.start()].strip() or "0"):
                kind = "declaration_or_call_REVIEW"
            else:
                kind = "call_candidate"
            arguments = text[paren + 1:end].strip()
            call_sites.append({"path": path, "line": line, "symbol": name, "kind": kind,
                "arguments": arguments, "first_argument_literal_null": bool(re.match(r"^(?:NULL|nullptr|0)\s*(?:,|$)", arguments))})
    return {"schema": "honor.g1.lexical-dependencies.v1", "level": "SOURCE-LEXICAL-NOT-COMPILED-ABI",
        "pins": {"ogkm": OGKM_PIN, "nullmoth": NM_PIN, "nullmoth_tree": NM_TREE},
        "scope": {"ogkm_sources": len(ogkm), "ogkm_build_and_source_files": len(build_text), "darwin_kext_sources": len(darwin)},
        "limitations": ["No preprocessing: mutually exclusive definitions and inactive calls retained",
            "Call-like identifiers include macros, casts and indirect calls; not a linker dependency graph",
            "Same-name Darwin definitions do not prove signature, layout, behavior or ownership compatibility",
            "Includes belong to full TU; include count/path keywords do not bound transitive platform dependencies",
            "NullMoth baseline only; current patch series not applied to this source inventory"],
        "source_manifest": {"ogkm": ogkm_hashes, "nullmoth": darwin_hashes},
        "translation_units": units, "symbols": dict(sorted(targets.items())),
        "altstack_all_source_and_build_occurrences": altstack,
        "darwin_target_occurrences": call_sites, "kext_load": "NO-GO"}


def markdown(report):
    lines = ["# G1 逐符号依赖表（机器生成）", "", "仅为固定源码的词法审计；不是预处理、ABI 或运行验收。全部命中、参数、直接 include 和源哈希见 JSON。", "",
             "| 符号 | OGKM 定义 | RM runtime 宏 | Darwin 同名依赖候选 |", "|---|---|---|---|"]
    for name, hits in report["symbols"].items():
        for hit in hits:
            runtime = any(c["name"] == "NV_ENTER_RM_RUNTIME" for c in hit["call_like_occurrences"])
            candidates = ", ".join(hit["darwin_same_name_candidates"]) or "未命中（不等于实现不存在）"
            lines.append(f"| `{name}` | `{hit['path']}:{hit['line']}` | {'是' if runtime else '未直接调用'} | {candidates} |")
    lines += ["", "所有调用形标识符均保留在 JSON；同名候选尚未核对 ABI。", ""]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--nv", type=Path, required=True)
    ap.add_argument("--nm", type=Path, required=True)
    ap.add_argument("--nm-tree", type=Path, help="complete fixed GitHub tree JSON; omit for a clean fixed git checkout")
    ap.add_argument("--definitions", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    names = set(json.loads(args.definitions.read_text(encoding="utf-8"))["found"])
    manifest = json.loads(args.nm_tree.read_text(encoding="utf-8")) if args.nm_tree else None
    report = audit(args.nv, args.nm, names, manifest)
    args.out.mkdir(parents=True, exist_ok=False)
    (args.out / "dependencies.json").write_text(json.dumps(report, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    (args.out / "dependencies.md").write_text(markdown(report), encoding="utf-8")
    print(json.dumps({"symbols": len(report["symbols"]), "units": len(report["translation_units"]), "scope": report["scope"],
        "runtime_symbols": [n for n, hits in report["symbols"].items() if any(c["name"] == "NV_ENTER_RM_RUNTIME" for h in hits for c in h["call_like_occurrences"])],
        "null_argument_occurrences": sum(r["first_argument_literal_null"] for r in report["darwin_target_occurrences"]),
        "json_sha256": digest((args.out / "dependencies.json").read_bytes())}, indent=1))


if __name__ == "__main__":
    main()
