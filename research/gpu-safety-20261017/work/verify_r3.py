from pathlib import Path
import subprocess,shutil,hashlib,json
r=Path(r'D:\Hactk\gpu-mainline-20261017'); ev=r/'evidence/r3'
nv=Path(r'D:\Hactk\g1-dev-20261015\upstream\open-gpu-kernel-modules')
nm=r/'upstream/nullmoth-v2.3.3-ac55984/nvidia-macos-driver-ac55984c473e746c2a8ebea7ba0913461aa7c393'
report={'steps':[],'darwin_compile':'NOT_RUN','kext_link':'BLOCKED','runtime':'NO-GO'}
def run(args,cwd):
 p=subprocess.run(args,cwd=cwd,capture_output=True,text=True);report['steps'].append({'argv':args,'exit':p.returncode,'stdout':p.stdout,'stderr':p.stderr});assert p.returncode==0,p.stderr
def apply(root,patch,extra=()): run(['git','-c','core.autocrlf=false','apply',*extra,'--whitespace=error-all',str(r/'patches'/patch)],root)
def hashes(root): return {str(p.relative_to(root)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
patch='ogkm-r3-kapi-null-free.patch';apply(nv,patch,('--check',))
sparse=r/'validation/ogkm-r3-sparse-roundtrip';path=Path('src/nvidia-modeset/kapi/src/nvkms-kapi.c');(sparse/path).parent.mkdir(parents=True,exist_ok=False);shutil.copyfile(nv/path,sparse/path);before=hashes(sparse);apply(sparse,patch);assert (sparse/path).read_bytes()==(r/'candidate/ogkm-e4a5faa-kapi-null-free-r3'/path).read_bytes();apply(sparse,patch,('--reverse',));assert hashes(sparse)==before
report['ogkm']='full fixed tree check; actual apply/reverse on one-file sparse copy only'
full=r/'validation/full-apply-roundtrip-v2.3.3-r3';shutil.copytree(nm,full);before=hashes(full)
seq=['gpu-safety-r1.patch','gpu-safety-r2-kms-open.patch','nullmoth-r3-thread-call-comment.patch']
for p in seq: apply(full,p,('--check',));apply(full,p)
actual=hashes(full);candidate=hashes(r/'candidate/nullmoth-v2.3.3-gpu-safety-r3');assert all(candidate.get(k)==v for k,v in actual.items());report['nullmoth_files_compared']=len(actual)
for p in reversed(seq): apply(full,p,('--reverse',))
assert hashes(full)==before;report['nullmoth_roundtrip']='PASS full source sequential apply/candidate comparison/reverse'
def symbols(label): return sorted(line.strip().split()[-1] for line in (ev/(label+'-kapi-undefined.txt')).read_text().splitlines() if line.strip())
a,b=symbols('original'),symbols('candidate');report['undefined_symbols']={'original':len(a),'candidate':len(b),'added':sorted(set(b)-set(a)),'removed':sorted(set(a)-set(b))};assert a==b
report['patches']={p:hashlib.sha256((r/'patches'/p).read_bytes()).hexdigest() for p in seq+[patch]}
(ev/'verification.json').write_text(json.dumps(report,indent=1),encoding='utf-8')
print('PASS complete NullMoth roundtrip; OGKM full check + sparse roundtrip; no added external symbols')
