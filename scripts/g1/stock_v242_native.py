#!/usr/bin/env python3
"""Native x86_64 object gate for TWO changed TUs, never links/loads/runs a driver.

Upstream scripts are read as provenance only. GNU make -n uses the already
reviewed fixed nv-compiler.sh compiler-identification helper, not an installer.

Diagnostics policy: the gate no longer claims "zero new warnings". It accepts a CLOSED list of reviewed
diagnostics recorded in source-lock.json, each bound to the locked candidate SHA, the exact file, line,
column, warning category, a message pattern and a count. Anything else new is rejected, and a recorded
exception that disappears is rejected too (the source identity would no longer describe the build).
"""
import argparse
import collections
import hashlib
import json
import platform
import re
import shlex
import shutil
import struct
import subprocess
from pathlib import Path

NM_PIN = '272ccd9da04ff5de95c2791b902fe17a3fa77ce7'
NV_PIN = 'e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb'
EXPECTED = ('kexts/NVRM/NVRM.cpp', 'kexts/NVRMFB/fb/nvrm-fb.cpp')
PASS_STATUS = 'PASS_DARWIN_TWO_TU_OBJECTS_WITH_ACCEPTED_DIAGNOSTICS'

# path:line:col: warning: message [-Wcategory]
DIAG = re.compile(r'^(?P<path>.+?):(?P<line>\d+):(?P<col>\d+): warning: (?P<msg>.*?)(?: \[(?P<cat>-W[^\]]+)\])?$')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def run(argv, cwd, log):
    with log.open('w', encoding='utf-8') as out:
        out.write('ARGV=' + json.dumps(list(map(str, argv))) + '\n'); out.flush()
        r = subprocess.run(list(map(str, argv)), cwd=cwd, stdout=out, stderr=subprocess.STDOUT, timeout=180)
        out.write('\nEXIT=' + str(r.returncode) + '\n')
    return r.returncode


def output(argv, cwd=None):
    return subprocess.check_output(list(map(str, argv)), cwd=cwd, text=True).strip()


def parse_diagnostics(text):
    """Every warning with its real position and category. Unparsable warning lines are kept as raw text."""
    found = []
    for raw in text.splitlines():
        m = DIAG.match(raw)
        if not m:
            continue
        found.append(dict(file=Path(m['path']).name, line=int(m['line']), column=int(m['col']),
                          message=m['msg'].strip(), category=m['cat'] or ''))
    return found


def _exception_matches(entry, diag):
    if entry['file'] != diag['file'] or entry['line'] != diag['line']:
        return False
    if entry['column'] != diag['column'] or entry['category'] != diag['category']:
        return False
    return re.search(entry['message_regex'], diag['message']) is not None


def classify_diagnostics(original, candidate, exceptions):
    """Split candidate diagnostics into pre-existing, accepted exceptions and unexpected.

    A pre-existing warning is matched by message text only, because line numbers shift between trees.
    An exception must match file+line+column+category+message pattern, and is consumed at most `count` times.
    """
    pool = collections.Counter(d['message'] for d in original)
    accepted, unexpected = [], []
    used = collections.Counter()
    for diag in candidate:
        # A reviewed exception is bound to an exact position in the locked candidate, so it is consumed first:
        # the same warning text may also exist elsewhere in the original tree, and that must not hide it.
        for index, entry in enumerate(exceptions):
            if used[index] < entry['count'] and _exception_matches(entry, diag):
                used[index] += 1
                accepted.append(dict(diag, exception=index))
                break
        else:
            if pool[diag['message']] > 0:
                pool[diag['message']] -= 1
                continue
            unexpected.append(diag)
    missing = [dict(entry, seen=used[index]) for index, entry in enumerate(exceptions)
               if used[index] != entry['count']]
    return dict(original=len(original), candidate=len(candidate), accepted=accepted,
                unexpected=unexpected, missing=missing,
                ok=not unexpected and not missing)


def run_negative_control(objects, logs, runner=run):
    """Compile a deliberately invalid source and require a non-zero exit with no object left behind.

    The stale object is written first on purpose: a gate that keeps consuming old products must fail here.
    """
    invalid = objects / 'invalid.cpp'
    badobj = objects / 'invalid.o'
    invalid.write_text('DELIBERATE_INVALID_NATIVE_SOURCE !!!\n', encoding='utf-8')
    badobj.write_bytes(b'STALE_OBJECT_MUST_NOT_SURVIVE')
    rc = runner(['xcrun', 'clang++', '-arch', 'x86_64', '-c', invalid, '-o', badobj], objects,
                logs / 'negative-compile.txt')
    record = dict(executed=True, exit=rc, stale_object_removed=not badobj.exists(),
                  object_exists=badobj.exists(), object_consumed=False)
    if badobj.exists():
        badobj.unlink()
    if rc == 0:
        raise ValueError('compile-failure control accepted an invalid source (exit 0)')
    if record['stale_object_removed'] is False:
        raise ValueError('compile-failure control left the pre-seeded stale object in place')
    return record


def validate_lock(lock, assets):
    if lock['upstream_commit'] != NM_PIN or lock['ogkm_commit'] != NV_PIN:
        raise ValueError('fixed source pin differs')
    if tuple(x['path'] for x in lock['files']) != EXPECTED:
        raise ValueError('scope must be exactly the two changed translation units')
    if lock['patch'] != 'stock-v242-converged.patch':
        raise ValueError('unexpected patch path')
    patch = assets / lock['patch']
    if sha(patch.read_bytes()) != lock['patch_sha256']:
        raise ValueError('patch byte identity differs (including CRLF changes)')
    exceptions = lock.get('diagnostics_exceptions', [])
    for entry in exceptions:
        for field in ('path', 'file', 'line', 'column', 'category', 'message_regex', 'count', 'reason'):
            if field not in entry:
                raise ValueError('diagnostics exception is missing ' + field)
        if entry['path'] not in EXPECTED:
            raise ValueError('diagnostics exception names an out-of-scope file')
        if entry['file'] != Path(entry['path']).name:
            raise ValueError('diagnostics exception file must match its path basename')
        if entry['count'] < 1:
            raise ValueError('diagnostics exception count must be positive')
        re.compile(entry['message_regex'])
    return patch, exceptions


def prepare(nm, candidate, lock, patch, logs):
    # Only local source copies. Never copy any upstream binary objects.
    for row in lock['files']:
        if sha((nm / row['path']).read_bytes()) != row['original_sha256']:
            raise ValueError('official source identity differs: ' + row['path'])
    def ignore(directory, names):
        return [n for n in names if n == '.git' or Path(n).suffix.lower() in
                {'.o', '.a', '.dylib', '.bin', '.kext', '.bundle', '.tar', '.gz', '.zip'}]
    shutil.copytree(nm, candidate, ignore=ignore)
    for flags, label in ((['--check'], 'check'), ([], 'apply')):
        if run(['git', '-c', 'core.autocrlf=false', 'apply', *flags, '--whitespace=error-all', patch],
               candidate, logs / ('patch-' + label + '.txt')):
            raise ValueError('fixed-source patch ' + label + ' failed')
    for row in lock['files']:
        if sha((candidate / row['path']).read_bytes()) != row['candidate_sha256']:
            raise ValueError('candidate output identity differs: ' + row['path'])


def macros_from_make(text):
    commands = []
    for line in text.splitlines():
        try: argv = shlex.split(line.split(' && ', 1)[0])
        except ValueError: continue
        if '-c' in argv and argv[argv.index('-c') + 1] == 'arch/nvalloc/unix/src/osapi.c':
            commands.append([x for x in argv if x.startswith('-D') and x not in ('-DNVRM', '-D_LANGUAGE_C')])
    if len(commands) != 1 or not commands[0]:
        raise ValueError('expected one real osapi.c recipe with RM definitions')
    return commands[0]


def dependencies(path, cwd):
    text = path.read_text(encoding='utf-8').replace('\\\n', ' ')
    if ': ' not in text:
        raise ValueError('invalid dependency output')
    names = shlex.split(text.split(': ', 1)[1])
    paths = sorted({str((cwd / p).resolve()) for p in names})
    if not paths:
        raise ValueError('empty transitive dependency set')
    return {p: sha(Path(p).read_bytes()) for p in paths}


def object_identity(path):
    raw = path.read_bytes()
    if len(raw) < 32:
        raise ValueError('compiler output has no complete Mach-O header')
    magic, cpu, subtype, kind = struct.unpack_from('<IIII', raw)
    if (magic, cpu, subtype & 0x00ffffff, kind) != (0xfeedfacf, 0x01000007, 3, 1):
        raise ValueError('compiler output is not x86_64 MH_OBJECT')
    return dict(size=len(raw), sha256=sha(raw), format='x86_64_MH_OBJECT')


def compile_one(role, tree, source, flags, logs, objects):
    stem = role + '-' + ('NVRM' if source == EXPECTED[0] else 'NVRMFB')
    obj = objects / (stem + '.o')
    obj.unlink(missing_ok=True)
    pre = logs / (stem + '-before.d'); post = logs / (stem + '-after.d')
    argv = ['xcrun', 'clang++', *flags, '-I' + str(tree / 'kexts/NVRM'),
            '-I' + str((tree / source).parent)]
    record = dict(role=role, source=source, source_sha256=sha((tree / source).read_bytes()),
                  compile_exit=None, object=None)
    if run([*argv, '-M', '-MT', 'bound', '-MF', pre, tree / source], tree, logs / (stem + '-deps.txt')):
        raise ValueError('dependency scan failed: ' + stem)
    before = dependencies(pre, tree)
    record['dependencies_before'] = before
    record['compile_exit'] = run([*argv, '-MD', '-MT', 'bound', '-MF', post, '-c', tree / source, '-o', obj],
                                tree, logs / (stem + '-compile.txt'))
    record['argv'] = list(map(str, [*argv, '-MD', '-MT', 'bound', '-MF', post, '-c', tree / source, '-o', obj]))
    if record['compile_exit']:
        obj.unlink(missing_ok=True)
        return record
    after = dependencies(post, tree)
    if before != after:
        obj.unlink(missing_ok=True)
        raise ValueError('source/header inputs changed across compilation: ' + stem)
    record['dependency_snapshot_sha256'] = sha(json.dumps(before, sort_keys=True).encode())
    record['object'] = object_identity(obj)
    for label, command in [('undefined', ['xcrun', 'nm', '-u']), ('defined', ['xcrun', 'nm', '-gU'])]:
        if run([*command, obj], tree, logs / (stem + '-' + label + '.txt')):
            raise ValueError('object inspection failed: ' + stem)
    record['diagnostics'] = parse_diagnostics((logs / (stem + '-compile.txt')).read_text(encoding='utf-8'))
    # Text evidence only. Never upload even these unlinked driver objects.
    obj.unlink()
    return record


def main():
    p = argparse.ArgumentParser(); p.add_argument('--nm', type=Path, required=True)
    p.add_argument('--nv', type=Path, required=True); p.add_argument('--assets', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True); args = p.parse_args()
    nm, nv, assets, logs = (x.resolve() for x in (args.nm, args.nv, args.assets, args.out))
    logs.mkdir(parents=True, exist_ok=False)
    report = dict(status='FAILED', stage='preflight', level='DARWIN_OBJECTS_ONLY', objects=[],
        staged_results={}, diagnostics={}, kext_link='NOT_RUN', kext_load='NO_GO',
        gpu_execution='NOT_RUN', safety_acceptance='NOT_ESTABLISHED',
        warnings_claim='ACCEPTED_EXCEPTIONS_ONLY (no zero-new-warning claim)')
    objects = logs.parent / (logs.name + '-objects')
    objects_created = False
    errors = []
    try:
        if platform.system() != 'Darwin' or platform.machine() != 'x86_64':
            raise ValueError('native Intel macOS runner required; cross compilation is not accepted')
        lock = json.loads((assets / 'source-lock.json').read_text(encoding='utf-8'))
        patch, exceptions = validate_lock(lock, assets); report['source_lock'] = lock
        report['diagnostics_exceptions'] = exceptions
        for name, tree, pin in [('nm', nm, NM_PIN), ('nv', nv, NV_PIN)]:
            if output(['git', '-C', tree, 'rev-parse', 'HEAD']) != pin:
                raise ValueError(name + ' fixed commit differs')
            if output(['git', '-C', tree, 'status', '--porcelain', '--untracked-files=no']):
                raise ValueError(name + ' tracked source has local changes')
        report['toolchain'] = dict(clang=output(['xcrun', 'clang++', '--version']),
            xcode=output(['xcodebuild', '-version']), system=output(['sw_vers']),
            sdk=output(['xcrun', '--show-sdk-path']), sdk_version=output(['xcrun', '--show-sdk-version']))
        khdr = Path(report['toolchain']['sdk']) / 'System/Library/Frameworks/Kernel.framework/Headers'
        if not (khdr / 'IOKit/IOService.h').is_file(): raise ValueError('Kernel.framework headers missing')
        if report['toolchain']['sdk_version'] != '15.5':
            raise ValueError('this frozen gate requires SDK 15.5 / Xcode 16.4')
        report['stage'] = 'prepare-two-tu-candidate'
        candidate = logs.parent / (logs.name + '-candidate'); prepare(nm, candidate, lock, patch, logs)
        report['stage'] = 'official-make-dryrun'
        gmake = shutil.which('gmake')
        if not gmake: raise ValueError('GNU make unavailable')
        report['toolchain']['gmake'] = output([gmake, '--version'])
        dryrun = logs / 'official-make-dryrun.txt'
        if run([gmake, '-n', 'TARGET_OS=Darwin', 'TARGET_ARCH=x86_64', 'CC=clang', 'NV_VERBOSE=1',
                'EXTRA_CFLAGS=-DNV_UNIX -DNV_LINUX'], nv / 'src/nvidia', dryrun):
            raise ValueError('fixed Makefile dry-run failed')
        definitions = macros_from_make(dryrun.read_text(encoding='utf-8')); report['rm_definitions'] = definitions
        nr, cm, kms = nv / 'src/nvidia', nv / 'src/common', nv / 'src/nvidia-modeset'
        includes = [nr / v for v in ('arch/nvalloc/unix/include', 'arch/nvalloc/common/inc', 'arch/nvalloc/common/inc/gsp',
            'inc', 'inc/os', 'inc/kernel', 'kernel/inc', 'interface', 'inc/libraries', 'src/libraries', 'generated', 'src/mm/uvm/interface')]
        includes += [cm / v for v in ('sdk/nvidia/inc', 'sdk/nvidia/inc/hw', 'inc', 'shared/inc', 'nvlink/interface',
            'inc/swref', 'inc/swref/published', 'uproc/os/libos-v2.0.0/include', 'uproc/os/common/include',
            'inc/displayport', 'nvlink/inband/interface', 'unix/nvidia-push/interface', 'unix/common/inc', 'modeset', 'unix/common/utils/interface')]
        includes += [kms / v for v in ('os-interface/include', 'kapi/interface', 'kapi/include', 'interface', 'include')]
        flags = ['-arch', 'x86_64', '-mmacosx-version-min=15.5', '-isysroot', report['toolchain']['sdk'],
            '-fapple-kext', '-mkernel', '-nostdinc', '-I' + str(khdr), '-DKERNEL', '-DKERNEL_PRIVATE',
            '-DDRIVER_PRIVATE', '-DAPPLE', '-DNeXT', '-std=c++17', '-fno-rtti', '-fno-exceptions',
            '-fno-builtin', '-fno-common', '-O2', '-Wall', '-Wno-unused-parameter',
            '-Wno-inconsistent-missing-override', '-Wno-unused-function', *definitions, '-DNVRM',
            *['-I' + str(x) for x in includes]]
        objects.mkdir(exist_ok=False)
        objects_created = True
        report['stage'] = 'object-compilation'
        for role, tree in [('original', nm), ('candidate', candidate)]:
            for source in EXPECTED:
                report['objects'].append(compile_one(role, tree, source, flags, logs, objects))
        failed = [x['source'] for x in report['objects'] if x['compile_exit'] != 0 or not x['object']]
        report['staged_results']['object_compilation'] = dict(ok=not failed, failed=failed)
        if failed:
            report.setdefault('failed_stage', report['stage'])
            errors.append('translation unit(s) failed to compile: ' + ', '.join(failed))
        else:
            report['stage'] = 'input-consistency'
            shared = {}
            for record in report['objects']:
                for path, digest in record['dependencies_before'].items():
                    if path in shared and shared[path] != digest:
                        raise ValueError('shared header changed BETWEEN translation units: ' + path)
                    shared[path] = digest
            for row in lock['files']:
                for tree, field in ((nm, 'original_sha256'), (candidate, 'candidate_sha256')):
                    if sha((tree / row['path']).read_bytes()) != row[field]:
                        raise ValueError('locked source changed during native gate: ' + row['path'])
            report['staged_results']['input_consistency'] = dict(ok=True, files=len(shared))
            report['stage'] = 'diagnostics-acceptance'
            diag_ok = True
            for index, source in enumerate(EXPECTED):
                original = report['objects'][index]['diagnostics']
                cand = report['objects'][index + 2]['diagnostics']
                scoped = [e for e in exceptions if e['path'] == source]
                verdict = classify_diagnostics(original, cand, scoped)
                report['diagnostics'][source] = verdict
                if not verdict['ok']:
                    diag_ok = False
            report['staged_results']['diagnostics_acceptance'] = dict(
                ok=diag_ok, accepted=sum(len(v['accepted']) for v in report['diagnostics'].values()),
                unexpected=sum(len(v['unexpected']) for v in report['diagnostics'].values()),
                missing=sum(len(v['missing']) for v in report['diagnostics'].values()))
            if not diag_ok:
                report.setdefault('failed_stage', report['stage'])
                errors.append('diagnostics not limited to the reviewed exceptions')
        report['stage'] = 'compiler-negative-control'
        try:
            report['compile_negative'] = run_negative_control(objects, logs)
            report['staged_results']['compiler_negative_control'] = dict(
                ok=True, exit=report['compile_negative']['exit'])
        except Exception as control_error:
            report['staged_results']['compiler_negative_control'] = dict(ok=False, error=str(control_error))
            report.setdefault('failed_stage', report['stage'])
            errors.append('compiler negative control failed: ' + str(control_error))
        if errors:
            raise ValueError('; '.join(errors))
        report.update(status=PASS_STATUS, stage='complete')
    except Exception as e:
        report['error'] = str(e)
        report['stage'] = 'failed'
    finally:
        if objects_created:
            # Our new exact output directory only, never traverse another workspace.
            for obj in objects.glob('*.o'): obj.unlink()
        (logs / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    # Annotations survive the missing-artifact channel: name the failing stage and the exact diagnostics.
    if report['status'] != PASS_STATUS:
        print('::error::GATE_FAILED_STAGE ' + str(report.get('failed_stage', report['stage'])) +
              ' :: ' + str(report.get('error', ''))[:300], flush=True)
        for source, verdict in (report.get('diagnostics') or {}).items():
            for d in verdict.get('unexpected', [])[:4]:
                print('::error::DIAG_UNEXPECTED %s:%d:%d [%s] %s' %
                      (d['file'], d['line'], d['column'], d['category'], d['message'][:160]), flush=True)
            for entry in verdict.get('missing', [])[:4]:
                print('::error::DIAG_MISSING %s:%d:%d seen=%d expected=%d' %
                      (entry['file'], entry['line'], entry['column'], entry['seen'], entry['count']),
                      flush=True)
    print(report['status'], report['stage'], report.get('error', ''))
    return 0 if report['status'] == PASS_STATUS else 2


if __name__ == '__main__':
    raise SystemExit(main())
