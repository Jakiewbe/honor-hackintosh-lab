#!/usr/bin/env python3
"""Same-run stock probe -> paired NVKMS -> real Darwin NVLink link integration.

Produces text evidence only. No installation, signing, loading or GPU execution.
The stock shader TU remains: its five payloads must equal the fixed OGKM data.
"""
import argparse
import hashlib
import json
import lzma
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

import stock_v243_kext_link as base
from stock_v243_import_audit import NVLINK, attribute
from macho_obj import MachO

PASS = 'PASS_INTERNAL_LINK_INTEGRATION_EXTERNAL_ABI_UNVERIFIED'
NVKMS = {'_nvKms'+s for s in ('Close', 'GetBacklight', 'Ioctl', 'KapiGetFunctionsTableInternal',
    'KapiHandleEventQueueChange', 'KapiProbe', 'KapiSuspendResume', 'ModuleLoad', 'Open',
    'Resume', 'SetBacklight', 'Suspend')}
SHADERS = ('turing', 'ampere', 'hopper', 'blackwell', 'gb20x')
ASSETS = Path(__file__).resolve().parents[2]/'research/stock-v243-once-20261021'
LOCK = ASSETS/'internal-link-lock.json'
BACKEND = Path(__file__).resolve().parents[2]/'research/gpu-safety-r5/darwin/nvlink_locks.cpp'


def require_identity(path, expected):
    if base.digest(path) != expected:
        raise ValueError('locked input differs: '+str(path))


def paired_candidate(nm, nv, dest, logs, lock):
    """Only named copies change; forward/reverse/replay must restore exact trees."""
    before = base.tracked_snapshot(nv)
    shutil.copytree(nv, dest, ignore=shutil.ignore_patterns('.git', '_out'))
    for rel, sha in lock['recipes'].items():
        require_identity(dest/rel, sha)
    steps = []

    def apply(spec, reverse, phase):
        patch = nm/spec['patch']
        require_identity(patch, spec['sha256'])
        expected = spec['after'] if reverse else spec['before']
        for rel, sha in expected.items():
            require_identity(dest/rel, sha)
        argv = ['git', '-c', 'core.autocrlf=false', 'apply', '--whitespace=error-all', '-p1']
        if spec['directory']:
            argv += ['--directory='+spec['directory']]
        if reverse:
            argv += ['-R']
        for suffix, flags in (('check', ['--check']), ('apply', [])):
            base.checked_run([*argv, *flags, patch], dest,
                logs/(phase+'-'+Path(spec['patch']).stem+'-'+suffix+'.txt'))
        for rel, sha in (spec['before'] if reverse else spec['after']).items():
            require_identity(dest/rel, sha)
        steps.append(dict(phase=phase, patch=spec['patch'], reverse=reverse))

    for spec in lock['patches']:
        apply(spec, False, 'forward')
    after = {p: base.digest(dest/p) for p in before}
    allowed = {p for s in lock['patches'] for p in s['after']}
    if {p for p in before if before[p] != after[p]} != allowed:
        raise ValueError('paired candidate changed unapproved files')
    for spec in reversed(lock['patches']):
        apply(spec, True, 'reverse')
    if {p: base.digest(dest/p) for p in before} != before:
        raise ValueError('paired candidate reverse did not restore original')
    for spec in lock['patches']:
        apply(spec, False, 'replay')
    if {p: base.digest(dest/p) for p in before} != after:
        raise ValueError('paired candidate replay differs')
    proof = dict(label='PAIRED_REBUILD_CANDIDATE_NOT_ORIGINAL_RELEASE',
        patches=lock['patches'], changed_files=sorted(allowed), steps=steps,
        reverse_restores_original=True, replay_identical=True)
    base.save(logs/'paired-candidate.json', proof)
    return after, proof


def parse_modeset_manifest(text, nv):
    component = nv/'src/nvidia-modeset'
    source_list = []
    for line in (component/'srcs.mk').read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line or line.startswith('#') or line in ('SRCS ?=', 'SRCS_CXX ?='):
            continue
        match = re.fullmatch(r'SRCS(?:_CXX)?\s*\+=\s*([A-Za-z0-9_./-]+\.(?:c|cpp))', line)
        if not match:
            raise ValueError('unsupported fixed modeset source list: '+line)
        source_list.append(match[1])
    source_list.append('_out/Darwin_x86_64/g_nvid_string.c')
    rows = []
    for line in text.splitlines():
        if not line.startswith('G1_SOURCE '):
            continue
        tokens = line.split()
        if len(tokens) != 3:
            raise ValueError('malformed modeset manifest')
        _, src, obj = tokens
        if obj != '_out/Darwin_x86_64/'+Path(src).stem+'.o':
            raise ValueError('unexpected modeset object mapping')
        if not (component/src).resolve().is_relative_to(nv.resolve()):
            raise ValueError('modeset source escapes input tree')
        rows.append(dict(source=src, object=str(component/obj)))
    if len(rows) != 225 or len(set(source_list)) != 225 or {r['source'] for r in rows} != set(source_list):
        raise ValueError('modeset needs exactly 224 fixed sources plus version TU')
    if len({r['object'] for r in rows}) != 225:
        raise ValueError('duplicate modeset object')
    return rows


def shader_payloads(source, nv):
    text = source.read_text(encoding='utf-8')
    payloads, proof = {}, []
    for arch in SHADERS:
        start = '__binary_'+arch+'_shaders_xz_start:\\n"\n'
        end = '".globl __binary_'+arch+'_shaders_xz_end'
        if text.count(start) != 1 or text.count(end) != 1:
            raise ValueError('shader labels not unique: '+arch)
        part = text.split(start, 1)[1].split(end, 1)[0]
        packed = bytearray()
        for line in part.strip().splitlines():
            match = re.fullmatch(r'"\.byte ([0-9,]+)\\n"', line)
            if not match:
                raise ValueError('unsupported shader assembly: '+arch)
            packed.extend(int(n) for n in match[1].split(','))
        decoder = lzma.LZMADecompressor()
        raw = decoder.decompress(bytes(packed))
        original = nv/('src/nvidia-modeset/src/shaders/g_'+arch+'_shaders')
        if not decoder.eof or decoder.unused_data or raw != original.read_bytes():
            raise ValueError('stock shader payload differs from fixed OGKM: '+arch)
        payloads[arch] = bytes(packed)
        proof.append(dict(arch=arch, compressed_size=len(packed), decompressed_size=len(raw),
            compressed_sha256=hashlib.sha256(packed).hexdigest(),
            source_sha256=base.digest(original), raw_bytes_equal=True))
    return payloads, proof


def verify_shader_object(path, payloads):
    obj = MachO(path)
    symbols = {}
    for name, kind, sect, value in obj.symbols:
        if name.startswith('__binary_'):
            symbols.setdefault(name, []).append((kind, sect, value))
    expected = {'__binary_'+a+'_shaders_xz_'+e for a in SHADERS for e in ('start', 'end')}
    if set(symbols) != expected or any(len(v) != 1 for v in symbols.values()):
        raise ValueError('stock shader object label inventory differs')
    for arch, payload in payloads.items():
        begin, end = [symbols['__binary_'+arch+'_shaders_xz_'+s][0] for s in ('start', 'end')]
        if begin[0] != 0x0f or end[:2] != begin[:2] or not 1 <= begin[1] <= len(obj.sections):
            raise ValueError('shader object label is not an external section definition')
        section = obj.sections[begin[1]-1]
        offset = begin[2]-section['addr']
        if section['name'] != '__TEXT,__const' or section['nreloc']:
            raise ValueError('shader object is not relocation-free readonly data')
        if offset < 0 or end[2]-begin[2] != len(payload) or offset+len(payload) > section['size']:
            raise ValueError('shader object bounds differ')
        if obj.data[section['offset']+offset:section['offset']+offset+len(payload)] != payload:
            raise ValueError('shader object bytes differ')


def symbols(product, logs, prefix):
    paths = {}
    for label, flag in (('undefined', '-u'), ('defined', '-gU')):
        path = logs/(prefix+'-'+label+'.txt')
        base.checked_run(['xcrun', 'nm', flag, product], product.parent, path)
        paths[label] = base.nm_names(path)
    return paths


def check_delta(before, after, defined, required, allowed_added, optional_removed=()):
    before, after, defined, required = map(set, (before, after, defined, required))
    removed, added = before-after, after-before
    if not required <= before or not required <= removed or required & after or not required <= defined:
        raise ValueError('required internal interfaces did not resolve to final definitions')
    if added-set(allowed_added):
        raise ValueError('unreviewed new imports: '+str(sorted(added-set(allowed_added))))
    if removed-required-set(optional_removed) or not removed <= defined:
        raise ValueError('unexpected or unprovided removed imports: '+str(sorted(removed-required)))
    return dict(removed=sorted(removed), added=sorted(added), remaining=len(after),
        acceptance='SYMBOL_NAME_CLOSURE_ONLY_NOT_LOADER_OR_ABI')


def archive_checked(rows, dest, work, log):
    if len(rows) != 225 or len({r['path'] for r in rows}) != 225:
        raise ValueError('paired modeset archive needs all 225 source objects')
    dest.unlink(missing_ok=True)
    try:
        base.checked_run(['xcrun', 'ar', 'rcs', dest, *[r['path'] for r in rows]], work, log)
        names = base.output(['xcrun', 'ar', '-t', dest]).splitlines()
        if names != [Path(r['path']).name for r in rows]:
            raise ValueError('archive member inventory differs')
    except Exception:
        dest.unlink(missing_ok=True)
        raise


def integrate(args, report):
    logs, work, nm, nv = [p.resolve() for p in (args.out, args.work, args.nm, args.nv)]
    report.update(status='FAILED', stage='internal-preflight', integration_lock_sha256=base.digest(LOCK))
    lock = json.loads(LOCK.read_text(encoding='utf-8'))
    if lock['pins'] != dict(nm=base.NM_PIN, nv=base.NV_PIN):
        raise ValueError('paired input pins differ')
    require_identity(BACKEND, lock['nvlink_sha256'])
    candidate = work/'ogkm-paired-candidate'
    expected, report['paired_candidate'] = paired_candidate(nm, nv, candidate, logs, lock)
    payloads, shader_proof = shader_payloads(work/'nm-candidate/kexts/NVRM/nvkms_shaders.cpp', nv)
    shader_row = next(r for r in report['tu_objects'] if r['source']=='kexts/NVRM/nvkms_shaders.cpp')
    verify_shader_object(Path(shader_row['path']), payloads)
    report['shaders'] = dict(policy='KEEP_VERIFIED_STOCK_TU_NO_DUPLICATE_PAYLOAD_OBJECTS',
        object_sha256=shader_row['sha256'], payloads=shader_proof)
    base.save(logs/'shader-equivalence.json', report['shaders'])
    report['stage'] = 'paired-modeset-objects'
    sdk = report['toolchain']['sdk']
    make = shutil.which('gmake')
    flags = ['TARGET_OS=Darwin', 'TARGET_ARCH=x86_64', 'CC=clang', 'CXX=clang++', 'NV_VERBOSE=1',
        'LD_HAS_FORCE_GROUP_ALLOCATION=0', 'SHADER_OBJS=',
        'EXTRA_CFLAGS=-DNV_UNIX -DNV_LINUX -isysroot '+sdk+' -mmacosx-version-min=15.5']
    component = candidate/'src/nvidia-modeset'
    helper = work/'manifest.mk'
    base.checked_run([make, '-f', 'Makefile', '-f', helper, *flags, 'g1-manifest'],
        component, logs/'modeset-manifest.txt')
    rows = parse_modeset_manifest((logs/'modeset-manifest.txt').read_text(encoding='utf-8'), candidate)
    goals = [str(Path(r['object']).relative_to(component)) for r in rows]
    base.checked_run([make, '-n', *flags, *goals], component, logs/'modeset-dryrun.txt')
    base.checked_run([make, '-j'+str(os.cpu_count() or 2), *flags, *goals], component,
        logs/'make-modeset.log', timeout=2400)
    identities = base.validate_set([Path(r['object']) for r in rows], component/'_out/Darwin_x86_64')
    for row, identity in zip(rows, identities):
        row.update(source_sha256=base.digest(component/row['source']), **identity)
    report['modeset_objects'] = rows
    base.save(logs/'modeset-objects.json', rows)
    archive = work/'libnvkms-paired.a'
    archive_checked(rows, archive, work, logs/'modeset-archive.txt')
    report['paired_archive'] = dict(sha256=base.digest(archive), members=225,
        payload_source='existing verified nvkms_shaders.cpp TU; no shader data member in this archive')
    report['stage'] = 'paired-rm-cleanup-objects'
    rm = candidate/'src/nvidia'
    replacements = []
    rm_sources = sorted(lock['patches'][-1]['after'])
    if len(rm_sources) != 2 or any(not p.startswith('src/nvidia/') or
            expected[p] == lock['patches'][-1]['before'][p] for p in rm_sources):
        raise ValueError('RM cleanup replacement inventory differs')
    for rel in sorted(rm_sources):
        source = candidate/rel
        obj = rm/'_out/Darwin_x86_64'/(source.stem+'.o')
        base.checked_run([make, *flags, obj.relative_to(rm)], rm, logs/(source.stem+'-make.txt'))
        replacements.append(dict(source=rel, source_sha256=base.digest(source), path=str(obj),
            **base.object_identity(obj)))
    base.validate_set([Path(r['path']) for r in replacements], rm/'_out/Darwin_x86_64')
    replaced = {Path(r['source']).stem:r for r in replacements}
    rm_rows = [replaced.get(Path(r['source']).stem, r) for r in report['rm_objects']]
    if sum(Path(r['path']).is_relative_to(candidate) for r in rm_rows) != 2:
        raise ValueError('expected two explicit RM object replacements')
    report['rm_replacements'] = replacements
    baseline_imports = set(report['imports'])
    original_rows = report['tu_objects'] + report['rm_objects']
    original_hashes = {r['path']:r['sha256'] for r in original_rows}
    inputs = report['tu_objects'] + rm_rows
    for row in inputs:
        require_identity(Path(row['path']), row['sha256'])
    report['stage'] = 'paired-nvkms-link'
    # Preserve the baseline argv/options and all twelve TU objects. Only two RM
    # cleanup objects are replaced, followed by the source-paired modeset archive.
    baseline_argv = json.loads((logs/'link-inputs.json').read_text())['argv']
    argv = [str(replaced[Path(a).stem]['path']) if a in {r['path'] for r in report['rm_objects']}
        and Path(a).stem in replaced else a for a in baseline_argv]
    paired = work/'NVRM-with-paired-nvkms'
    argv[-1] = str(paired)
    argv[argv.index('-o'):argv.index('-o')] = [str(archive)]
    report['paired_link'] = base.link_checked(argv, work, paired, logs/'paired-ld.txt')
    paired_symbols = symbols(paired, logs, 'paired')
    report['nvkms_delta'] = check_delta(baseline_imports, paired_symbols['undefined'],
        paired_symbols['defined'], NVKMS, lock['allowed_modeset_new_imports'],
        {'_SHA1Final', '_SHA1Init', '_SHA1Update'})
    report['stage'] = 'nvlink-provider'
    headers = Path(sdk)/'System/Library/Frameworks/Kernel.framework/Headers'
    obj = work/'nvlink-darwin.o'
    compile_argv = ['xcrun', 'clang++', '-std=c++17', '-O2', '-fno-rtti', '-fno-exceptions',
        '-arch', 'x86_64', '-mmacosx-version-min=15.5', '-isysroot', sdk,
        '-fapple-kext', '-mkernel', '-nostdinc', '-I'+str(headers), '-DKERNEL', '-DKERNEL_PRIVATE',
        '-DDRIVER_PRIVATE', '-DAPPLE', '-DNeXT', '-DNV_UNIX', '-DNV_LINUX',
        *['-I'+str(candidate/p) for p in ('src/common/nvlink/interface', 'src/common/inc',
        'src/common/sdk/nvidia/inc')], '-c', str(BACKEND), '-o', str(obj)]
    pre, post = logs/'nvlink-pre.d', logs/'nvlink-post.d'
    base.checked_run([*compile_argv[:-4], '-M', '-MT', 'bound', '-MF', pre, BACKEND], work, logs/'nvlink-deps.txt')
    deps = base.dependencies(pre, work)
    report['nvlink_object'] = base.compile_checked([*compile_argv, '-MD', '-MT', 'bound', '-MF', post],
        work, obj, logs/'nvlink-compile.txt')
    if deps != base.dependencies(post, work):
        raise ValueError('NVLink dependencies changed while compiling')
    if symbols(obj, logs, 'nvlink')['defined'] != NVLINK:
        raise ValueError('NVLink object must define exactly four real interfaces')
    report['stage'] = 'integrated-link'
    dest = work/'NVRM-internal-integration'
    argv[-1] = str(dest)
    argv[argv.index('-o'):argv.index('-o')] = [str(obj)]
    base.save(logs/'internal-link-inputs.json', dict(argv=argv, backend_argv=compile_argv,
        archive=report['paired_archive'], rm_replacements=replacements, shader_policy=report['shaders']['policy']))
    report['integrated_link'] = base.link_checked(argv, work, dest, logs/'integrated-ld.txt')
    final = symbols(dest, logs, 'integrated')
    report['nvlink_delta'] = check_delta(paired_symbols['undefined'], final['undefined'], final['defined'], NVLINK, {'_panic'})
    if (NVKMS | NVLINK) & final['undefined']:
        raise ValueError('known internal interfaces remain unresolved')
    report['stage'] = 'input-recheck'
    for name, root in (('nm', nm), ('nv', nv)):
        snapshot = json.loads((logs/'fixed-input-snapshots.json').read_text())[name]
        if base.tracked_snapshot(root) != snapshot:
            raise ValueError('original fixed source changed: '+name)
    if {p:base.digest(candidate/p) for p in expected} != expected:
        raise ValueError('paired source changed during integration')
    nm_inputs = json.loads((logs/'candidate-input-snapshots.json').read_text())
    if {p:base.digest(work/'nm-candidate'/p) for p in nm_inputs} != nm_inputs:
        raise ValueError('NullMoth candidate source changed during integration')
    for path, sha in original_hashes.items():
        require_identity(Path(path), sha)
    for row in replacements + rows:
        require_identity(Path(row['path']), row['sha256'])
    for row in rows:
        require_identity(component/row['source'], row['source_sha256'])
    for path, sha in deps.items():
        require_identity(Path(path), sha)
    require_identity(obj, report['nvlink_object']['sha256'])
    require_identity(archive, report['paired_archive']['sha256'])
    require_identity(BACKEND, lock['nvlink_sha256'])
    require_identity(LOCK, report['integration_lock_sha256'])
    report['final_imports'] = sorted(final['undefined'])
    report['final_attribution'] = attribute(report['final_imports'],
        Path(__file__).resolve().parents[2]/'research/gpu-safety-r5/target-provider-evidence/native')
    base.save(logs/'integrated-external-imports.json', report['final_attribution'])
    base.save(logs/'internal-import-delta.json', {k:report[k] for k in ('nvkms_delta', 'nvlink_delta', 'final_imports')})
    report.update(status=PASS, stage='complete', modeset='PAIRED_ARCHIVE_LINKED',
        level='INTERNAL_SYMBOL_LINK_INTEGRATION_ONLY')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ('nm', 'nv', 'assets', 'out', 'work'):
        parser.add_argument('--'+flag, type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    report = dict(status='FAILED', stage='preflight', kext_load='NO_GO',
        gpu_execution='NOT_RUN', external_imports='UNVERIFIED', safety_acceptance='NOT_ESTABLISHED')
    try:
        base.build(args, report)
        report['same_run_baseline'] = {k:report[k] for k in ('status', 'link', 'imports')}
        # A successful baseline can never mask a failed integration.
        report['status'] = 'FAILED'
        integrate(args, report)
    except Exception as error:
        report['status'] = 'FAILED'
        report['error'] = str(error)
        print('::error::INTERNAL_LINK_FAILED '+report['stage']+' :: '+str(error)[:350], flush=True)
    finally:
        base.save(args.out/'report.json', report)
    print(report['status'], report['stage'], report.get('error', ''), flush=True)
    return 0 if report['status'] == PASS else 2


if __name__ == '__main__':
    sys.exit(main())
