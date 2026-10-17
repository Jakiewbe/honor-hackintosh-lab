import pathlib, json, hashlib, difflib
HERE=pathlib.Path(__file__).resolve().parent
locks=json.loads((HERE.parent/'source-lock.json').read_text())
snapshots={}
for entry in locks:
    root=pathlib.Path(entry['source_root'])
    snapshots[entry['tag']]={p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file()}
(HERE/'source-files-sha256.json').write_text(json.dumps(snapshots,indent=2),encoding='utf-8')
summary={}
for a,b in [('v2.3.1','v2.3.2'),('v2.3.2','v2.3.3'),('v2.3.1','v2.3.3')]:
    sa,sb=snapshots[a],snapshots[b]
    changed=[p for p in sorted(sa.keys()&sb.keys()) if sa[p]!=sb[p]]
    summary[a+'..'+b]={'added':sorted(sb.keys()-sa.keys()),'removed':sorted(sa.keys()-sb.keys()),'changed':changed}
    ra=pathlib.Path(next(x['source_root'] for x in locks if x['tag']==a)); rb=pathlib.Path(next(x['source_root'] for x in locks if x['tag']==b))
    lines=[]
    for p in changed+sorted(sb.keys()-sa.keys())+sorted(sa.keys()-sb.keys()):
        ba=(ra/p).read_bytes() if p in sa else b''; bb=(rb/p).read_bytes() if p in sb else b''
        if b'\0' in ba or b'\0' in bb:
            lines.append(f'Binary differs: {p}\n'); continue
        lines.extend(difflib.unified_diff(ba.decode('utf-8',errors='replace').splitlines(True),bb.decode('utf-8',errors='replace').splitlines(True),fromfile=a+'/'+p,tofile=b+'/'+p))
    (HERE/(a+'..'+b+'.diff')).write_text(''.join(lines),encoding='utf-8')
(HERE/'source-diff-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2))
