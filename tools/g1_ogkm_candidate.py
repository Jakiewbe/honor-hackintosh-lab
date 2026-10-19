#!/usr/bin/env python3
"""Explicit OGKM candidate copy; immutable originals, exact two-source delta.

Only source inputs. Never loads a driver or replaces official-flag objects with
probe objects. Full tree comparison includes headers and rejects symlinks.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

SPECS = (
    {'patch': 'ogkm-r3-kapi-null-free.patch',
     'patch_sha256': '75a98868e878c00fc63698cfa04a2309777ed341cf0178a94c4dd5658570a3d5',
     'source': 'src/nvidia-modeset/kapi/src/nvkms-kapi.c',
     'original_sha256': '66437bc38d96d3b4f15546c3e6f7a8c0caccc158b35893c2406f80f2e6e8816b',
     'candidate_sha256': '7e5492e0a0961e45ea75f664d2a16c49c66d728b93b8e3e87dca3ae9ebe38200',
     'defined_symbol': '_nvKmsKapiGetFunctionsTableInternal'},
    {'patch': 'ogkm-niso-surface-owner.patch',
     'patch_sha256': 'e6f4293d09e6d24414a4cd1faba90be2a88ad8dc9f5b15817ab548ac207fb508',
     'source': 'src/nvidia-modeset/kapi/src/nvkms-kapi-notifiers.c',
     'original_sha256': '78d310ca74ab282beec5c18d2c208ab4862d1344566f3db088017c9fe972c641',
     'candidate_sha256': '527df580bab9c6c0226edfdcaf3663dc2ed9d42c2151bfbf7efbc80f586c098c',
     'defined_symbol': '_nvKmsKapiFreeNisoSurface'},
)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tree_files(root):
    files = {}
    for base, dirs, names in os.walk(root, followlinks=False):
        parent = Path(base)
        if parent == root and '.git' in dirs:
            dirs.remove('.git')
        for name in dirs + names:
            if (parent/name).is_symlink():
                raise ValueError('symlink forbidden in OGKM source input')
        for name in names:
            p = parent/name
            if parent == root and name == '.git':
                continue
            files[p.relative_to(root).as_posix()] = sha(p)
    if not files:
        raise ValueError('empty OGKM source tree')
    return files


def tree_digest(files):
    return hashlib.sha256(json.dumps(files, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def check_delta(original, candidate, expected):
    if original.keys() != candidate.keys():
        raise ValueError('candidate added or removed a source/header')
    changed = {name for name in original if original[name] != candidate[name]}
    if changed != {s['source'] for s in expected}:
        raise ValueError('candidate changes differ from exact approved source set')
    for spec in expected:
        if (original[spec['source']] != spec['original_sha256'] or
                candidate[spec['source']] != spec['candidate_sha256']):
            raise ValueError('candidate/original source hash differs: '+spec['source'])


def make_candidate(nv, candidate, assets, logs):
    if candidate.exists() or candidate == nv or nv in candidate.parents or candidate in nv.parents:
        raise ValueError('fresh, separate candidate path required')
    before = tree_files(nv)
    for spec in SPECS:
        if before.get(spec['source']) != spec['original_sha256'] or sha(assets/spec['patch']) != spec['patch_sha256']:
            raise ValueError('pinned OGKM source/patch identity differs')
    shutil.copytree(nv, candidate, ignore=lambda p,n: ['.git'] if Path(p) == nv and '.git' in n else [])
    if tree_files(candidate) != before:
        raise ValueError('candidate initial copy differs')
    env = dict(os.environ, GIT_CEILING_DIRECTORIES=str(candidate.parent))
    def apply(spec, reverse, stage):
        for check in (True, False):
            argv = ['git', '-c', 'core.autocrlf=false', 'apply', '--whitespace=error-all']
            if reverse: argv.append('--reverse')
            if check: argv.append('--check')
            argv.append(str((assets/spec['patch']).resolve()))
            log = logs/('ogkm-'+stage+'-'+spec['patch']+('-check' if check else '-apply')+'.txt')
            with log.open('w', encoding='utf-8', newline='\n') as stream:
                stream.write('ARGV='+json.dumps(argv)+'\n'); stream.flush()
                rc = subprocess.run(argv, cwd=candidate, env=env, stdout=stream, stderr=subprocess.STDOUT).returncode
                stream.write('\nEXIT='+str(rc)+'\n')
            if rc: raise ValueError('OGKM candidate patch failed: '+spec['patch'])
    for spec in SPECS: apply(spec, False, 'forward')
    after = tree_files(candidate)
    check_delta(before, after, SPECS)
    for spec in reversed(SPECS): apply(spec, True, 'reverse')
    if tree_files(candidate) != before:
        raise ValueError('OGKM reverse application did not restore exact original tree')
    for spec in SPECS: apply(spec, False, 'reapply')
    if tree_files(candidate) != after or tree_files(nv) != before:
        raise ValueError('candidate reapplication or original immutability failed')
    return {'schema': 'honor.g1.ogkm-candidate.v1', 'candidate_root': str(candidate),
            'original_root': str(nv), 'files': len(before), 'patches': list(SPECS),
            'original_tree_sha256': tree_digest(before), 'candidate_tree_sha256': tree_digest(after),
            'reverse_restores_original': True, 'exact_two_source_delta': True}


def verify_candidate(nv, candidate, manifest):
    before, after = tree_files(nv), tree_files(candidate)
    check_delta(before, after, SPECS)
    if (tree_digest(before) != manifest['original_tree_sha256'] or
            tree_digest(after) != manifest['candidate_tree_sha256']):
        raise ValueError('OGKM tree changed after candidate preparation')
