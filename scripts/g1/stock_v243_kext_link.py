#!/usr/bin/env python3
"""Fail-closed NVRM link probe; text evidence only, no driver execution."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import struct
import subprocess
import sys

from stock_v243_once_native import (NM_PIN, NV_PIN, dependencies, macros_from_make,
                                   nm_names, object_identity, prepare, validate_lock)
from stock_v243_import_audit import attribute

TUS = tuple('kexts/NVRM/' + n for n in (
    'NVRM.cpp', 'nv_xnu_power.cpp', 'nv_xnu_stubs.cpp', 'nvkms_shaders.cpp',
    'nvrm_fbinfo.cpp', 'nvrm_gpuva.cpp', 'nvrm_surfshare.cpp', 'os-nvkms-xnu.cpp',
    'os-xnu.cpp', 'os-xnu2.cpp', 'nvrm_kapi_fields.c', 'nvrm_pageoff.c'))
RM_FILES = {
    'src/nvidia/Makefile': '3bc31a7f4e9841d2dfb231862b64639815c8314ae42a6ef454ad745c45c55dd6',
    'src/nvidia/srcs.mk': '6ea9e2a8e31b790029d3d5119629d7a3acff28734ddc92ad966d5c11cb63dee3',
    'utils.mk': 'd1371cf992e486b6863e1d6200727a6f5591e2ff298db08cf79981b90dfdd047'}
PASS = 'PASS_NVRM_LINK_PROBE_EXTERNAL_IMPORTS_UNVERIFIED'


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')


def output(argv, cwd=None, missing_ok=False):
    # Command Line Tools provide clang, git, make and the SDK but not xcodebuild; a missing optional
    # tool must not abort a build that does not need it.
    try:
        return subprocess.check_output(list(map(str, argv)), cwd=cwd, text=True).strip()
    except (FileNotFoundError, subprocess.CalledProcessError):
        if missing_ok:
            return ''
        raise


def run(argv, cwd, log, timeout=600):
    argv = list(map(str, argv))
    with log.open('w', encoding='utf-8') as stream:
        stream.write('ARGV=' + json.dumps(argv) + '\n'); stream.flush()
        result = subprocess.run(argv, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
        stream.write('\nEXIT=' + str(result.returncode) + '\n')
    return result.returncode


def checked_run(argv, cwd, log, runner=run, timeout=600):
    rc = runner(argv, cwd, log, timeout=timeout)
    if rc:
        raise ValueError(f'{log.name}: exit={rc}')


def compile_checked(argv, cwd, obj, log, runner=run):
    obj.unlink(missing_ok=True)
    try:
        checked_run(argv, cwd, log, runner)
        return object_identity(obj)
    except Exception:
        obj.unlink(missing_ok=True)
        raise


def validate_set(expected, directory):
    expected = list(map(Path, expected))
    if not expected or len(expected) != len(set(expected)):
        raise ValueError('empty or duplicate object manifest')
    actual = set(directory.glob('*.o'))
    if actual != set(expected):
        raise ValueError('object set mismatch: missing=' + str(sorted(str(p) for p in set(expected)-actual)) +
                         ', extra=' + str(sorted(str(p) for p in actual-set(expected))))
    return [dict(path=str(p), **object_identity(p)) for p in expected]


def link_checked(argv, cwd, dest, log, runner=run):
    dest.unlink(missing_ok=True)
    try:
        checked_run(argv, cwd, log, runner)
        raw = dest.read_bytes()
        if len(raw) < 32 or struct.unpack_from('<II', raw) != (0xfeedfacf, 0x01000007):
            raise ValueError('link product is not x86_64 Mach-O')
        if struct.unpack_from('<I', raw, 12)[0] != 11:
            raise ValueError('link product is not MH_KEXT_BUNDLE')
        return dict(size=len(raw), sha256=digest(dest), format='x86_64_MH_KEXT_BUNDLE')
    except Exception:
        dest.unlink(missing_ok=True)
        raise


def parse_manifest(text, nv):
    base = nv / 'src/nvidia'
    sources = []
    for line in (base / 'srcs.mk').read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line or line.startswith('#') or line in ('SRCS ?=', 'SRCS_CXX ?='):
            continue
        match = re.fullmatch(r'SRCS(?:_CXX)?\s*\+=\s*([A-Za-z0-9_./-]+\.(?:c|cpp))', line)
        if not match:
            raise ValueError('unsupported fixed source-list syntax: ' + line)
        sources.append(match[1])
    sources.append('_out/Darwin_x86_64/g_nvid_string.c')
    rows = []
    for line in text.splitlines():
        if line.startswith('G1_SOURCE '):
            tokens = line.split()
            if len(tokens) != 3:
                raise ValueError('malformed make manifest')
            src, obj = tokens[1:]
            if obj != '_out/Darwin_x86_64/' + Path(src).stem + '.o':
                raise ValueError('unexpected official object mapping: ' + line)
            if not (base/src).resolve().is_relative_to(nv.resolve()):
                raise ValueError('source escapes fixed tree')
            rows.append(dict(source=src, object=str(base/obj)))
    if len(rows) != 1055 or len(sources) != 1055 or {r['source'] for r in rows} != set(sources):
        raise ValueError('official RM manifest differs from all 1054 sources plus version TU')
    if len({r['object'] for r in rows}) != len(rows):
        raise ValueError('colliding RM object names')
    return rows


def tracked_snapshot(root):
    names = subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z']).decode().split('\0')
    return {p: digest(root/p) for p in names if p}


def negative_controls(work, logs):
    """Real failures through production acceptance functions, never driver stubs."""
    directory = work / 'negative'; directory.mkdir()
    src = directory / 'invalid.cpp'; obj = directory / 'invalid.o'
    src.write_text('DELIBERATE_INVALID_NATIVE_SOURCE !!!\n', encoding='utf-8')
    obj.write_bytes(b'STALE_OBJECT_MUST_NOT_BE_CONSUMED')
    results = {}
    try:
        compile_checked(['xcrun', 'clang++', '-arch', 'x86_64', '-c', src, '-o', obj],
                        directory, obj, logs/'negative-compile.txt')
    except ValueError as error:
        results['compiler_failure'] = dict(rejected=True, error=str(error), stale_removed=not obj.exists())
    else:
        raise ValueError('negative compiler control was accepted')
    if obj.exists():
        raise ValueError('negative compiler control retained stale object')
    try:
        validate_set([obj], directory)
    except ValueError as error:
        results['missing_object'] = dict(rejected=True, error=str(error))
    else:
        raise ValueError('negative missing-object control was accepted')
    # Isolated non-driver data fixture ensures clang actually invokes ld. Never linked into NVRM.
    link_src = directory/'link-input.c'; link_obj = directory/'link-input.o'
    link_src.write_text('int g1_negative_control_data = 1;\n', encoding='utf-8')
    compile_checked(['xcrun', 'clang', '-arch', 'x86_64', '-c', link_src, '-o', link_obj],
                    directory, link_obj, logs/'negative-link-input.txt')
    dest = directory / 'invalid-link'; dest.write_bytes(b'STALE_LINK_PRODUCT')
    try:
        link_checked(['xcrun', 'clang++', '-Wl,-g1_deliberate_invalid_link_option', '-nostdlib',
                      link_obj, '-o', dest], directory, dest, logs/'negative-link.txt')
    except ValueError as error:
        results['linker_failure'] = dict(rejected=True, error=str(error), stale_removed=not dest.exists())
    else:
        raise ValueError('negative linker control was accepted')
    if dest.exists():
        raise ValueError('negative linker control retained stale product')
    if 'ld:' not in (logs/'negative-link.txt').read_text(encoding='utf-8'):
        raise ValueError('link failure control did not reach the real linker')
    return results


def build(args, report):
    nm, nv, assets, logs, work = [p.resolve() for p in (args.nm, args.nv, args.assets, args.out, args.work)]
    if platform.system() != 'Darwin' or platform.machine() != 'x86_64':
        raise ValueError('native Intel macOS required')
    for root, pin in ((nm, NM_PIN), (nv, NV_PIN)):
        if output(['git', '-C', root, 'rev-parse', 'HEAD']) != pin:
            raise ValueError('fixed source commit differs')
        if output(['git', '-C', root, 'status', '--porcelain', '--untracked-files=all']):
            raise ValueError('clean new fixed input required')
    for path, expected in RM_FILES.items():
        if digest(nv/path) != expected:
            raise ValueError('fixed Makefile identity differs: ' + path)
    sdk = output(['xcrun', '--show-sdk-path'])
    report['toolchain'] = dict(sdk=sdk, sdk_version=output(['xcrun', '--show-sdk-version']),
        deployment_target='15.5', clang=output(['xcrun', 'clang', '--version']),
        xcode=output(['xcodebuild', '-version'], missing_ok=True) or 'xcodebuild absent (Command Line Tools only)',
        system=output(['sw_vers']))
    if report['toolchain']['sdk_version'] != '15.5':
        raise ValueError('SDK 15.5 required')
    work.mkdir(exist_ok=False)
    report['stage'] = 'negative-controls'
    report['negative_controls'] = negative_controls(work, logs)
    report['stage'] = 'candidate'
    lock = json.loads((assets/'source-lock.json').read_text(encoding='utf-8'))
    patch, _, _ = validate_lock(lock, assets)
    candidate = work/'nm-candidate'; prepare(nm, candidate, lock, patch, logs)
    snapshots = {name: tracked_snapshot(root) for name, root in (('nm', nm), ('nv', nv))}
    save(logs/'fixed-input-snapshots.json', snapshots)
    candidate_inputs = {p: digest(candidate/p) for p in snapshots['nm'] if (candidate/p).is_file()}
    save(logs/'candidate-input-snapshots.json', candidate_inputs)
    report['stage'] = 'rm-manifest'
    base = nv/'src/nvidia'; rmout = base/'_out/Darwin_x86_64'
    if rmout.exists():
        raise ValueError('RM output directory must not already exist')
    make = shutil.which('gmake')
    if not make:
        raise ValueError('GNU make unavailable')
    helper = work/'manifest.mk'
    helper.write_text('.PHONY: g1-manifest\ng1-manifest:\n\t$(foreach src,$(ALL_SRCS),$(info G1_SOURCE $(src) $(call BUILD_OBJECT_LIST,$(src))))\n\t@:\n', encoding='utf-8')
    # Object-only goals avoid the unsupported GNU/ELF link. No nonzero make is accepted.
    flags = ['TARGET_OS=Darwin', 'TARGET_ARCH=x86_64', 'CC=clang', 'NV_VERBOSE=1',
             'EXTRA_CFLAGS=-DNV_UNIX -DNV_LINUX -isysroot '+sdk+' -mmacosx-version-min=15.5']
    checked_run([make, '-f', 'Makefile', '-f', helper, *flags, 'g1-manifest'], base, logs/'rm-manifest.txt')
    rows = parse_manifest((logs/'rm-manifest.txt').read_text(encoding='utf-8'), nv)
    goals = [str(Path(r['object']).relative_to(base)) for r in rows]
    checked_run([make, '-n', *flags, *goals], base, logs/'rm-dryrun.txt')
    definitions = macros_from_make((logs/'rm-dryrun.txt').read_text(encoding='utf-8'))
    report['rm_shared_definitions'] = definitions
    report['stage'] = 'rm-objects'
    checked_run([make, '-j'+str(os.cpu_count() or 2), *flags, *goals], base, logs/'make-nvidia.log', timeout=6500)
    objects = validate_set([Path(r['object']) for r in rows], rmout)
    for row, obj in zip(rows, objects):
        row.update(source_sha256=digest(base/row['source']), **obj)
    report['rm_objects'] = rows
    save(logs/'rm-objects.json', rows)
    report['stage'] = 'nvrm-objects'
    actual_tus = {p.relative_to(candidate).as_posix() for p in (candidate/'kexts/NVRM').iterdir()
                  if p.suffix in ('.c', '.cpp')}
    if actual_tus != set(TUS):
        raise ValueError('fixed 12-TU inventory differs')
    headers = Path(sdk)/'System/Library/Frameworks/Kernel.framework/Headers'
    cm = nv/'src/common'; kms = nv/'src/nvidia-modeset'
    includes = [base/v for v in ('arch/nvalloc/unix/include', 'arch/nvalloc/common/inc', 'arch/nvalloc/common/inc/gsp',
        'inc', 'inc/os', 'inc/kernel', 'kernel/inc', 'interface', 'inc/libraries', 'src/libraries', 'generated', 'src/mm/uvm/interface')]
    includes += [cm/v for v in ('sdk/nvidia/inc', 'sdk/nvidia/inc/hw', 'inc', 'shared/inc', 'nvlink/interface',
        'inc/swref', 'inc/swref/published', 'uproc/os/libos-v2.0.0/include', 'uproc/os/common/include',
        'inc/displayport', 'nvlink/inband/interface', 'unix/nvidia-push/interface', 'unix/common/inc', 'modeset', 'unix/common/utils/interface')]
    includes += [kms/v for v in ('os-interface/include', 'kapi/interface', 'kapi/include', 'interface', 'include')]
    common = ['-arch', 'x86_64', '-mmacosx-version-min=15.5', '-isysroot', sdk, '-fapple-kext', '-mkernel',
        '-nostdinc', '-I'+str(headers), '-DKERNEL', '-DKERNEL_PRIVATE', '-DDRIVER_PRIVATE', '-DAPPLE', '-DNeXT',
        '-DNVRM', '-fno-builtin', '-fno-common', '-O2', '-Wall', '-Wno-unused-parameter', '-Wno-unused-function',
        *definitions, *['-I'+str(p) for p in includes], '-I'+str(candidate/'kexts/NVRM'), '-I'+str(candidate)]
    objdir = work/'tu-objects'; objdir.mkdir()
    report['tu_objects'] = []
    for rel in TUS:
        source = candidate/rel; obj = objdir/(source.stem+'.o')
        cc = 'clang' if source.suffix == '.c' else 'clang++'
        lang = ['-std=gnu11', '-D_LANGUAGE_C'] if cc == 'clang' else [
            '-std=c++17', '-fno-rtti', '-fno-exceptions', '-Wno-inconsistent-missing-override']
        argv = ['xcrun', cc, *common, *lang]
        pre, post = logs/(source.name+'-pre.d'), logs/(source.name+'-post.d')
        checked_run([*argv, '-M', '-MT', 'bound', '-MF', pre, source], candidate, logs/(source.name+'-deps.txt'))
        before = dependencies(pre, candidate)
        identity = compile_checked([*argv, '-MD', '-MT', 'bound', '-MF', post, '-c', source, '-o', obj],
            candidate, obj, logs/('tu-'+source.name+'.txt'))
        if before != dependencies(post, candidate):
            raise ValueError('TU input changed during compilation: '+rel)
        report['tu_objects'].append(dict(source=rel, source_sha256=digest(source), path=str(obj),
            compile_exit=0, dependencies=before, **identity))
    validate_set([Path(r['path']) for r in report['tu_objects']], objdir)
    report['stage'] = 'input-consistency'
    for name, root in (('nm', nm), ('nv', nv)):
        if tracked_snapshot(root) != snapshots[name]:
            raise ValueError('fixed tracked input changed: '+name)
    if {p: digest(candidate/p) for p in candidate_inputs} != candidate_inputs:
        raise ValueError('candidate input changed during build')
    for row in report['tu_objects']:
        if any(digest(p) != sha for p, sha in row['dependencies'].items()):
            raise ValueError('TU dependency changed before link: '+row['source'])
    for row in lock['files']:
        if digest(candidate/row['path']) != row['candidate_sha256']:
            raise ValueError('locked candidate changed during build')
    for row in report['tu_objects'] + rows:
        if digest(Path(row['path'])) != row['sha256']:
            raise ValueError('link input changed: '+row['path'])
    report['stage'] = 'link'
    dest = work/'NVRM'
    argv = ['xcrun', 'clang++', '-arch', 'x86_64', '-mmacosx-version-min=15.5', '-isysroot', sdk,
        '-fapple-kext', '-nostdlib', '-Xlinker', '-kext', '-lkmodc++', '-lkmod', '-lcc_kext',
        *[r['path'] for r in report['tu_objects']], *[r['path'] for r in rows], '-o', dest]
    save(logs/'link-inputs.json', dict(argv=list(map(str, argv)), tu_count=12, rm_count=1055))
    report['link'] = dict(exit=0, **link_checked(argv, work, dest, logs/'ld.txt'))
    checked_run(['xcrun', 'nm', '-u', dest], work, logs/'NVRM-undefined.txt')
    imports = sorted(nm_names(logs/'NVRM-undefined.txt'))
    report['link']['undefined'] = len(imports)
    report['imports'] = imports
    report['nvkms_unresolved'] = [s for s in imports if s.startswith('_nvKms')]
    report['import_attribution'] = attribute(imports, Path(__file__).resolve().parents[2]/
        'research/gpu-safety-r5/target-provider-evidence/native')
    save(logs/'external-imports.json', report['import_attribution'])
    report.update(status=PASS, stage='complete')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ('nm', 'nv', 'assets', 'out', 'work'):
        parser.add_argument('--'+flag, type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    report = dict(status='FAILED', stage='preflight', level='NVRM_LINK_PROBE_ONLY',
        kext_load='NO_GO', gpu_execution='NOT_RUN', modeset='NOT_LINKED',
        external_imports='UNVERIFIED', safety_acceptance='NOT_ESTABLISHED')
    try:
        build(args, report)
    except Exception as error:
        report['error'] = str(error)
        print('::error::LINK_GATE_FAILED '+report['stage']+' :: '+str(error)[:350], flush=True)
    finally:
        save(args.out/'report.json', report)
    print(report['status'], report['stage'], report.get('error', ''), flush=True)
    return 0 if report['status'] == PASS else 2


if __name__ == '__main__':
    sys.exit(main())
