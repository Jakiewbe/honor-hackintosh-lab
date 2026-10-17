"""Read-only archive inventory, metadata, and selected driver member hashes; no extraction."""
import pathlib,tarfile,json,hashlib,plistlib
HERE=pathlib.Path(__file__).resolve().parent
BASE=HERE.parent.parent
EXPECTED={'v2.3.1':'3522e2f5481b70a88ead5abcaeea7e236f01cc08088000e74ccab2be42ca6429','v2.3.2':'33bf069592903c59a52de7393fc2c4104298d9820c378c9287ae39cfa3944a4e','v2.3.3':'869a3f34f5d1c4350d09347f876967821156091c8c8d677234f25c57ea001122'}
def hashstream(f):
    h=hashlib.sha256()
    for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()
allresults={}
for tag,expected in EXPECTED.items():
    path=BASE/'downloads'/('release-'+tag+'.tar.gz')
    with path.open('rb') as f: archivehash=hashstream(f)
    if archivehash!=expected:raise ValueError((tag,archivehash,'unexpected archive SHA256'))
    inventory=[];metadata={};drivers={}
    with tarfile.open(path,'r:gz') as tar:
        for m in tar:
            inventory.append({'path':m.name,'size':m.size,'type':m.type.decode('ascii',errors='replace'),'linkname':m.linkname})
            if not m.isfile():continue
            p=pathlib.PurePosixPath(m.name)
            # Firmware is never opened; it is listed only.
            if any('firmware' in part.lower() or part.lower()=='nvfw' for part in p.parts):continue
            meta=(p.suffix.lower() in ('.json','.plist') or p.name in ('VERSION','SHA256SUMS') or ('manifest' in p.name.lower()))
            driver=('/Contents/MacOS/' in m.name or p.suffix.lower() in ('.dylib','.so') or '.so.' in p.name or p.name.startswith('libvulkan') or p.name in ('air-opt','nvvmdrive','nullmoth-runtime-check'))
            if meta:
                if m.size>2*1024*1024:raise ValueError(('oversized metadata',m.name))
                b=tar.extractfile(m).read()
                if p.suffix.lower()=='.plist':
                    try:value=plistlib.loads(b)
                    except Exception:value={'raw':b.decode('utf-8',errors='replace')}
                elif p.suffix.lower()=='.json':
                    try:value=json.loads(b)
                    except Exception:value={'raw':b.decode('utf-8',errors='replace')}
                else:value=b.decode('utf-8',errors='replace')
                metadata[m.name]={'sha256':hashlib.sha256(b).hexdigest(),'value':value}
            if driver:
                with tar.extractfile(m) as f:sha=hashstream(f)
                drivers[m.name]={'size':m.size,'sha256':sha}
    result={'archive_sha256':archivehash,'inventory':inventory,'metadata':metadata,'drivers':drivers}
    (HERE/(tag+'-archive-audit.json')).write_text(json.dumps(result,indent=2,default=str),encoding='utf-8')
    allresults[tag]=result
    print(tag,'members',len(inventory),'metadata',len(metadata),'drivers',len(drivers),flush=True)
def normalized(drivers):
    return {'/'.join(path.split('/')[1:]):v for path,v in drivers.items()}
a=normalized(allresults['v2.3.1']['drivers']);b=normalized(allresults['v2.3.3']['drivers'])
comparison={p:{'v2.3.1':a.get(p),'v2.3.3':b.get(p),'equal':a.get(p)==b.get(p)} for p in sorted(a.keys()|b.keys())}
(HERE/'package-driver-comparison.json').write_text(json.dumps(comparison,indent=2),encoding='utf-8')
print('Compared',len(comparison),'driver/runtime members; changed:',*[p for p,v in comparison.items() if not v['equal']],sep='\n')

versions={tag:normalized(result['drivers']) for tag,result in allresults.items()}
paths=sorted(set().union(*(set(v) for v in versions.values())))
threeway={p:{tag:v.get(p) for tag,v in versions.items()} for p in paths}
(HERE/'package-driver-threeway.json').write_text(json.dumps(threeway,indent=2),encoding='utf-8')
for left,right in [('v2.3.1','v2.3.2'),('v2.3.2','v2.3.3')]:
    changed=[p for p in paths if versions[left].get(p)!=versions[right].get(p)]
    print(left+'..'+right, 'changed',len(changed),changed)
