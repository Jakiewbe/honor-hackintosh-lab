"""Export fixed public trees and stage the same 24H32 source/profile for CI."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tarfile

HERE = Path(__file__).resolve().parent
PINS = {'nm':'272ccd9da04ff5de95c2791b902fe17a3fa77ce7',
        'ogkm':'e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb'}


def export(tree, pin, destination):
    actual = subprocess.check_output(['git','-C',str(tree),'rev-parse','HEAD'], text=True).strip()
    if actual != pin:
        raise ValueError('source HEAD differs from fixed pin')
    raw = subprocess.check_output(['git','-C',str(tree),'archive','--format=tar',pin])
    count = 0
    with tarfile.open(fileobj=io.BytesIO(raw)) as tar:
        for member in tar:
            p = PurePosixPath(member.name)
            if p.is_absolute() or '..' in p.parts or '\\' in member.name:
                raise ValueError('invalid source archive path')
            if member.isdir(): continue
            if not member.isfile(): raise ValueError('nonregular source input')
            target = destination/member.name
            if target.exists(): raise ValueError('duplicate source archive member')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(tar.extractfile(member).read())
            count += 1
    return count


def prepare(nm, ogkm, package):
    package.mkdir(parents=True, exist_ok=False)
    counts = {role:export(tree, PINS[role], package/'inputs'/role)
              for role,tree in [('nm',nm),('ogkm',ogkm)]}
    manifest = json.loads((HERE/'candidate-manifest.json').read_text(encoding='utf-8'))
    proof = (HERE/'route-proof.json').read_bytes()
    patch = HERE/'forwarders.patch'
    if manifest['source_pin'] != PINS['nm'] or hashlib.sha256(patch.read_bytes()).hexdigest() != manifest['patch_sha256']:
        raise ValueError('patch pin/digest mismatch')
    if hashlib.sha256(proof).hexdigest() != manifest['route_proof_sha256']:
        raise ValueError('target route proof changed')
    profile = json.loads((HERE/'PROFILE.json').read_text(encoding='utf-8'))
    if profile['pins'] != PINS: raise ValueError('profile pins changed')
    for rel,expected in manifest['baseline_blob_sha256'].items():
        if hashlib.sha256((package/'inputs/nm'/rel).read_bytes()).hexdigest() != expected:
            raise ValueError('patch baseline identity mismatch')
    changed = package/'patch-application'
    shutil.copytree(package/'inputs/nm',changed)
    for flags in (['--check'],[]):
        subprocess.run(['git','-c','core.autocrlf=false','apply',*flags,str(patch)],cwd=changed,check=True)
    destination = package/'forwarder-candidate'
    destination.mkdir()
    shutil.copyfile(HERE/'candidate-manifest.json',destination/'MANIFEST.json')
    shutil.copyfile(patch,destination/'nvaccel-24h32-forwarders.patch')
    shutil.copyfile(HERE/'LICENSE-NullMoth.txt',destination/'LICENSE-NullMoth.txt')
    for row in manifest['files']:
        raw = (changed/row['path']).read_bytes()
        if len(raw) != row['bytes'] or hashlib.sha256(raw).hexdigest() != row['sha256']:
            raise ValueError('patched source differs from reviewed candidate')
        target = destination/'src'/row['path']
        target.parent.mkdir(parents=True,exist_ok=True); target.write_bytes(raw)
    for name in ('native_gate.py','g1_compile_inputs.py','PROFILE.json','route-proof.json'):
        shutil.copyfile(HERE/name,package/name)
    files = []
    for p in sorted(package.rglob('*')):
        if p.is_file():
            raw=p.read_bytes(); files.append(dict(path=p.relative_to(package).as_posix(),bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
    result=dict(status='CI_BUILD_INPUTS_NOT_INSTALLABLE',pins=PINS,files=files,go_authorized=False)
    (package/'PACKAGE-MANIFEST.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(source_files=counts,package_files=len(files),source_candidate_files=len(manifest['files']),
        target_collection_sha256=manifest['target_collection_sha256'],go_authorized=False),indent=2))


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--nm',type=Path,required=True)
    p.add_argument('--ogkm',type=Path,required=True)
    p.add_argument('--package',type=Path,required=True)
    a=p.parse_args(); prepare(a.nm,a.ogkm,a.package)
