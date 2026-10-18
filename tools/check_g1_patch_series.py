#!/usr/bin/env python3
"""Check the native gate's NullMoth series in a temporary complete source copy.

Never checkout/reset/clean any input tree. Does not execute the native script.
"""
import argparse
import ast
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

NM_PIN = 'ac55984c473e746c2a8ebea7ba0913461aa7c393'
NM_TREE = '528e804da39cb6c358727455385563d414606a70'


def manifest(root):
    result = {}
    for folder, dirs, files in os.walk(root):
        dirs[:] = sorted(x for x in dirs if x != '.git')
        for name in sorted(files):
            p = Path(folder)/name
            if p.is_symlink():
                raise ValueError('symlink input requires separate handling')
            result[p.relative_to(root).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    return result


def digest(entries):
    return hashlib.sha256('\n'.join(f'{p}\0{entries[p]}' for p in sorted(entries)).encode()).hexdigest()


def series(script):
    found = []
    for node in ast.walk(ast.parse(script.read_text(encoding='utf-8'))):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id=='enumerate':
            try:
                values = ast.literal_eval(node.args[0])
            except (ValueError, TypeError):
                continue
            if isinstance(values, tuple) and values and values[0]=='gpu-safety-r1.patch':
                found.append(values)
    if len(found)!=1:
        raise ValueError('expected one explicit native NullMoth patch series')
    return found[0]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--nm',type=Path,required=True)
    p.add_argument('--nm-tree',type=Path)
    p.add_argument('--assets',type=Path,required=True)
    p.add_argument('--native-script',type=Path,required=True)
    p.add_argument('--expected-baseline',type=Path)
    p.add_argument('--out',type=Path,required=True)
    args=p.parse_args()
    args.out.mkdir(parents=True,exist_ok=False)
    original=manifest(args.nm)
    if args.nm_tree:
        data=json.loads(args.nm_tree.read_text(encoding='utf-8'))
        if data['sha']!=NM_TREE or data.get('truncated'):
            raise ValueError('wrong/truncated upstream tree')
        expected={x['path']:x['sha'] for x in data['tree'] if x['type']=='blob'}
        if set(expected)!=set(original):
            raise ValueError('source file list differs from fixed upstream tree')
        for name,sha in expected.items():
            b=(args.nm/name).read_bytes()
            if hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()!=sha:
                raise ValueError('modified upstream blob: '+name)
    else:
        head=subprocess.check_output(['git','-C',str(args.nm),'rev-parse','HEAD'],text=True).strip()
        tree=subprocess.check_output(['git','-C',str(args.nm),'rev-parse','HEAD^{tree}'],text=True).strip()
        dirty=subprocess.check_output(['git','-C',str(args.nm),'status','--porcelain','--untracked-files=all'],text=True).strip()
        if head!=NM_PIN or tree!=NM_TREE or dirty:
            raise ValueError('upstream must match clean fixed commit/tree')
    names=series(args.native_script)
    record={'level':'PATCH-APPLIED-COMPLETE-TREE','nm_commit':NM_PIN,'nm_tree':NM_TREE,
            'pristine_sha256':digest(original),'pristine_files':len(original),'patches':[]}
    with tempfile.TemporaryDirectory(prefix='g1-series-') as folder:
        candidate=Path(folder)/'candidate'
        shutil.copytree(args.nm,candidate,ignore=shutil.ignore_patterns('.git'))
        for n,name in enumerate(names):
            patch=(args.assets/name).resolve()
            for options in [['--check'], []]:
                proc=subprocess.run(['git','-c','core.autocrlf=false','apply',*options,
                    '--whitespace=error-all',str(patch)],cwd=candidate,capture_output=True,text=True)
                if proc.returncode:
                    raise ValueError(f'{name}: {proc.stderr}')
            record['patches'].append({'name':name,'sha256':hashlib.sha256(patch.read_bytes()).hexdigest()})
            if n==len(names)-2:
                baseline=manifest(candidate)
                record['baseline_sha256']=digest(baseline)
                if args.expected_baseline:
                    record['baseline_matches_existing']=baseline==manifest(args.expected_baseline)
                    if not record['baseline_matches_existing']:
                        raise ValueError('reconstructed baseline differs from supplied baseline')
                rel='kexts/NVRM/accel/nvrm-accel.cpp'
                record['baseline_accel_sha256']=baseline[rel]
        modified=manifest(candidate)
        record['candidate_sha256']=digest(modified)
        record['candidate_files']=len(modified)
        record['candidate_accel_sha256']=modified['kexts/NVRM/accel/nvrm-accel.cpp']
        for name in reversed(names):
            patch=(args.assets/name).resolve()
            subprocess.run(['git','-c','core.autocrlf=false','apply','--reverse',
                '--whitespace=error-all',str(patch)],cwd=candidate,check=True,capture_output=True)
        restored=manifest(candidate)
        record['restored_sha256']=digest(restored)
        record['result']='PASS' if restored==original else 'FAIL'
    (args.out/'report.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({key:record[key] for key in ['result','pristine_files','candidate_files','pristine_sha256','candidate_sha256','restored_sha256']}))
    return 0 if record['result']=='PASS' else 1


if __name__=='__main__':
    raise SystemExit(main())
