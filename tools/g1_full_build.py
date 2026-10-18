#!/usr/bin/env python3
"""Attempt every official RM/modeset TU under a recorded Darwin reconstruction.

No installation, signing, loading or device execution. Incomplete inputs/failed
compiles never produce a partial archive presented as complete. Kernel exports,
full ABI and GPU operation remain separate acceptance requirements.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import lzma
from pathlib import Path
import platform
import re
import shlex
import struct
import subprocess
import sys

from g1_dependency_audit import OGKM_PIN, NM_PIN
from g1_symbol_identity import parse_nm_undefined
from g1_special_object_providers import defined_symbols
from g1_compile_inputs import BOUND_RM, bound_compile, verify_snapshot

COMPONENTS = ('nvidia', 'nvidia-modeset')
SHADERS = ('turing', 'ampere', 'hopper', 'blackwell', 'gb20x')
NVLINK_EXPORTS = {'_nvlink_'+name+'Lock' for name in ('alloc', 'acquire', 'release', 'free')}
NVLINK_NEW_IMPORTS = {'_panic'}  # Deliberate fatal invariant path; target export/ABI still unverified.
BASELINE_CPP = {'kexts/NVRM/'+name for name in (
    'NVRM.cpp', 'os-xnu.cpp', 'os-xnu2.cpp', 'os-nvkms-xnu.cpp', 'nv_xnu_stubs.cpp',
    'nvrm_gpuva.cpp', 'nvrm_fbinfo.cpp', 'nvrm_surfshare.cpp', 'nvkms_shaders.cpp',
                                            'kms_deferred.cpp')}
BASELINE_C = {'kexts/NVRM/nvrm_pageoff.c', 'kexts/NVRM/nvrm_kapi_fields.c'}


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8', newline='\n')


def source_list(text):
    """Fixed srcs.mk uses literal assignments only; unknown syntax is an error."""
    sources = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith('#') or line in ('SRCS ?=', 'SRCS_CXX ?='):
            continue
        match = re.fullmatch(r'SRCS(?:_CXX)?\s*\+=\s*([A-Za-z0-9_./-]+\.(?:c|cpp))', line)
        if not match:
            raise ValueError('unsupported official source-list syntax: '+line)
        sources.append(match.group(1))
    if not sources or len(sources) != len(set(sources)):
        raise ValueError('empty or duplicate official source inventory')
    return sources


def inventory(nv):
    result = {}
    for component in COMPONENTS:
        base = nv/'src'/component
        rows = []
        for rel in source_list((base/'srcs.mk').read_text(encoding='utf-8')):
            path = (base/rel).resolve()
            if not path.is_relative_to(nv.resolve()) or not path.is_file():
                raise ValueError('missing or escaping required source: '+rel)
            rows.append({'make_source': rel, 'source': path.relative_to(nv.resolve()).as_posix(),
                         'source_sha256': digest(path.read_bytes())})
        result[component] = rows
    return result


def fixed_input(nv):
    for command, expected in [('rev-parse HEAD', OGKM_PIN), ('status --porcelain --untracked-files=all', '')]:
        actual = subprocess.check_output(['git', '-C', str(nv), *command.split()], text=True).strip()
        if actual != expected:
            raise ValueError('fixed clean OGKM required')


def object_path(root, component, source):
    return root/(component+'-'+Path(source).stem+'-'+digest(source.encode())[:16]+'.o')


def compile_plan(text, cwd, expected):
    found = {}
    for line in text.replace('\\\n', ' ').splitlines():
        if not re.match(r'^clang(?:\+\+)?\s', line):
            continue
        argv = shlex.split(line)
        if argv.count('-c') != 1 or argv.count('-o') != 1 or any(t in argv for t in ('&&', ';', '|', '>', '<')):
            raise ValueError('ambiguous official compile command')
        if argv.index('-c')+1 >= len(argv) or argv.index('-o')+1 >= len(argv):
            raise ValueError('missing compile operand')
        source = (cwd/argv[argv.index('-c')+1]).resolve()
        if source in found:
            raise ValueError('duplicate source compile command')
        found[source] = argv
    if set(found) != set(expected):
        raise ValueError('official command/source mismatch: missing='+str(sorted(str(p) for p in set(expected)-set(found)))+
                         ', extra='+str(sorted(str(p) for p in set(found)-set(expected))))
    return found


def darwin_command(argv, source, obj, sdk, headers):
    ci, oi = argv.index('-c'), argv.index('-o')
    flags = [v for i, v in enumerate(argv) if i not in (0, ci, ci+1, oi, oi+1)]
    bridge = ['-arch', 'x86_64', '-mmacosx-version-min=15.5', '-isysroot', str(sdk),
              '-fapple-kext', '-mkernel', '-nostdinc', '-I'+str(headers),
              '-DKERNEL', '-DKERNEL_PRIVATE', '-DDRIVER_PRIVATE', '-DAPPLE', '-DNeXT']
    return ['xcrun', argv[0], *flags, *bridge, '-c', str(source), '-o', str(obj)]


def validate_object(path):
    raw = path.read_bytes()
    if (len(raw) < 32 or struct.unpack_from('<II', raw) != (0xfeedfacf, 0x01000007)
            or struct.unpack_from('<I', raw, 12)[0] != 1):
        raise ValueError('successful compile did not produce x86_64 MH_OBJECT')
    return digest(raw)


def validate_kext(path):
    raw = path.read_bytes()
    if (len(raw) < 32 or struct.unpack_from('<II', raw) != (0xfeedfacf, 0x01000007)
            or struct.unpack_from('<I', raw, 12)[0] != 11):
        raise ValueError('link did not produce x86_64 MH_KEXT_BUNDLE')
    return digest(raw)


def run(argv, cwd, log, timeout=180):
    with log.open('w', encoding='utf-8', newline='\n') as stream:
        stream.write('ARGV='+json.dumps([str(x) for x in argv])+'\n')
        stream.flush()
        try:
            result = subprocess.run(argv, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
            rc = result.returncode
        except subprocess.TimeoutExpired:
            stream.write('\nTIMEOUT\n')
            rc = 124
        stream.write('\nEXIT='+str(rc)+'\n')
    return rc


def generated_id(nv, component, build, logs):
    """Execute only the reviewed public ID macro with no object prerequisites."""
    utils = (nv/'utils.mk').read_text(encoding='utf-8')
    macros = re.findall(r'^define GENERATE_NVIDSTRING\n[\s\S]*?^endef', utils, re.M)
    if len(macros) != 1:
        raise ValueError('ID generator changed')
    version = (nv/'version.mk').read_text(encoding='utf-8')
    match = re.search(r'^NVIDIA_NVID_VERSION\s*=\s*([0-9.]+)\s*$', version, re.M)
    if not match:
        raise ValueError('version metadata missing')
    symbol, module = ('NVRM_ID', 'UNIX Open Kernel Module') if component == 'nvidia' else (
        'NV_KMS_ID', 'UNIX Open Kernel Mode Setting Driver')
    dest = build/'g_nvid_string.c'
    if re.search(r'[^A-Za-z0-9_./-]', str(build)):
        raise ValueError('safe absolute generated-output path required')
    makefile = build/'id-generator.mk'
    text = ('NVIDSTRING := '+str(dest)+'\nVERSION_MK := '+str(nv/'version.mk')+
            '\nTARGET_ARCH := x86_64\nNVIDIA_NVID_VERSION := '+match.group(1)+
            '\nNVIDSTRING_BUILD_TYPE_STRING := Release Build\nNVIDIA_NVID_EXTRA := HONOR-G1-REBUILD-CANDIDATE'+
            '\nNV_BUILD_USER := g1\nNV_BUILD_HOST := ci\nMKDIR := mkdir -p\nECHO := echo'+
            '\nDATE := printf 2026-10-18T00:00:00Z\n'+macros[0]+
            '\n$(eval $(call GENERATE_NVIDSTRING,'+symbol+','+module+',))\n')
    makefile.write_text(text, encoding='utf-8', newline='\n')
    if run(['gmake', '--no-print-directory', '-f', str(makefile), str(dest)], build,
           logs/(component+'-id-generation.txt')):
        raise ValueError('official ID generation failed')
    output = dest.read_text(encoding='utf-8')
    if f'const char *const p{symbol} = {symbol} + 11;' not in output or 'HONOR-G1-REBUILD-CANDIDATE' not in output:
        raise ValueError('ID output does not match the reviewed public recipe')
    (build/'version.h').write_text('#define NVIDIA_VERSION "'+match.group(1)+'"\n', encoding='utf-8')
    return dest


def shader_assembly(raw, family, xz_path):
    if family not in SHADERS or re.search(r'[^A-Za-z0-9_./-]', str(xz_path)):
        raise ValueError('invalid shader input')
    packed = lzma.compress(raw, format=lzma.FORMAT_XZ, check=lzma.CHECK_NONE,
                           preset=6 | lzma.PRESET_EXTREME)
    if lzma.decompress(packed) != raw:
        raise ValueError('shader compression roundtrip failed')
    name = '__binary_'+family+'_shaders_xz'
    asm = ('.section __TEXT,__const\n.p2align 4\n.globl '+name+'_start\n'+name+'_start:\n'+
           '.incbin "'+str(xz_path)+'"\n.globl '+name+'_end\n'+name+'_end:\n'+
           '.globl '+name+'_size\n.set '+name+'_size, '+name+'_end - '+name+'_start\n')
    return packed, asm


def archive_allowed(rows, expected):
    if not rows or len(rows) != expected or any(r.get('compile_exit') != 0 or not r.get('object_sha256') for r in rows):
        raise ValueError('complete successful object set required; partial archive forbidden')
    if len({r['object'] for r in rows}) != len(rows):
        raise ValueError('duplicate object input')


def baseline_objects(native, candidate, object_root, input_root=None):
    if native.get('pins') != {'nm': NM_PIN, 'nv': OGKM_PIN}:
        raise ValueError('native baseline pins differ')
    selected = [r for r in native.get('build_manifest', []) if r['role'] in ('nvrm-unified', 'candidate-c-probe')]
    if ({r['source'] for r in selected if r['role']=='nvrm-unified'} != BASELINE_CPP or
            {r['source'] for r in selected if r['role']=='candidate-c-probe'} != BASELINE_C):
        raise ValueError('exact nine NVRM plus two local C baseline sources required')
    archive_allowed(selected, 11)
    input_root = input_root or object_root/'gpu-safety-r5-logs/input-snapshots'
    for row in selected:
        source = (candidate/row['source']).resolve()
        obj = Path(row['object'])
        if not source.is_relative_to(candidate.resolve()) or digest(source.read_bytes()) != row['source_sha256']:
            raise ValueError('baseline candidate source changed')
        if obj.is_symlink() or obj.resolve().parent != object_root.resolve() or validate_object(obj) != row['object_sha256']:
            raise ValueError('baseline object changed or outside current run')
        snapshot = verify_snapshot(row.get('dependency_snapshot'),
            input_root, source, obj, row['object_sha256'])
        if snapshot['cwd'] != str(candidate.resolve()) or row.get('compile_cwd') != snapshot['cwd']:
            raise ValueError('baseline dependency compile cwd mismatch')
    return selected


def read_defined_log(path):
    lines = path.read_text(encoding='utf-8').splitlines()
    if not lines or not lines[0].startswith('ARGV=') or lines[-1] != 'EXIT=0':
        raise ValueError('incomplete defined-symbol log')
    argv = json.loads(lines[0][5:])
    if 'nm' not in argv or '-gU' not in argv:
        raise ValueError('expected defined nm command')
    return defined_symbols('\n'.join(lines[1:-1]))


def nvlink_delta(before, after, defined):
    before, after = set(before), set(after)
    removed, added = before-after, after-before
    if not NVLINK_EXPORTS <= before or removed != NVLINK_EXPORTS:
        raise ValueError('same-run baseline must lose exactly the four NVLink imports')
    if not NVLINK_EXPORTS <= defined or NVLINK_EXPORTS & after:
        raise ValueError('four NVLink definitions must survive final link')
    if added - NVLINK_NEW_IMPORTS:
        raise ValueError('unexpected new imports: '+str(sorted(added-NVLINK_NEW_IMPORTS)))
    return {'removed_imports': sorted(removed), 'added_imports': sorted(added),
            'added_import_policy': '_panic is a deliberate fatal invariant path; no target export/ABI acceptance',
            'remaining_import_count': len(after), 'target_exports_abi': 'NOT_VERIFIED'}


def compile_nvlink(nv, out, sdk, headers, report):
    source = Path(__file__).resolve().parents[1]/'research/gpu-safety-r5/darwin/nvlink_locks.cpp'
    obj = out/'objects/nvlink-darwin-locks.o'
    argv = ['xcrun', 'clang++', '-std=c++17', '-O2', '-fno-rtti', '-fno-exceptions',
            '-arch', 'x86_64', '-mmacosx-version-min=15.5', '-isysroot', str(sdk),
            '-fapple-kext', '-mkernel', '-nostdinc', '-I'+str(headers),
            '-DKERNEL', '-DKERNEL_PRIVATE', '-DDRIVER_PRIVATE', '-DAPPLE', '-DNeXT',
            '-DNV_UNIX', '-DNV_LINUX']
    for rel in ('src/common/nvlink/interface', 'src/common/inc', 'src/common/sdk/nvidia/inc'):
        argv.append('-I'+str(nv/rel))
    argv += ['-c', str(source), '-o', str(obj)]
    row = {'source': 'research/gpu-safety-r5/darwin/nvlink_locks.cpp',
           'source_sha256': digest(source.read_bytes()), 'object': str(obj), 'candidate_argv': argv,
           'role': 'explicit Darwin semaphore provider; OGKM archives unchanged'}
    report['extra_objects'] = [row]
    rc = run(argv, out, out/'nvlink-compile.txt')
    row['compile_exit'] = rc
    if rc:
        raise ValueError('NVLink Darwin lock provider compile failed')
    row['object_sha256'] = validate_object(obj)
    symbols = out/'nvlink-defined.txt'
    if run(['xcrun', 'nm', '-gU', str(obj)], out, symbols):
        raise ValueError('NVLink object nm failed')
    exports = read_defined_log(symbols)
    row['defined_symbols'] = sorted(exports)
    if exports != NVLINK_EXPORTS:
        raise ValueError('NVLink provider must export exactly four real interfaces')
    return obj


def build(args, report):
    nv, out = args.nv.resolve(), args.out.resolve()
    if platform.system() != 'Darwin' or platform.machine() != 'x86_64':
        raise ValueError('native macOS Intel runner required; no cross-build substitute')
    sources = inventory(nv)
    sdk = subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-path'], text=True).strip()
    headers = Path(sdk)/'System/Library/Frameworks/Kernel.framework/Headers'
    if not (headers/'IOKit').is_dir():
        raise ValueError('Kernel SDK unavailable')
    report.update({'source_inventory': sources, 'sdk': sdk,
                   'profile': 'official per-TU gmake expansion + NV_UNIX/NV_LINUX + recorded Darwin kernel bridge; reconstructed candidate, ABI unaccepted'})
    objects = out/'objects'
    objects.mkdir()
    compile_jobs = []
    for component in COMPONENTS:
        base = nv/'src'/component
        generated = out/(component+'-generated')
        generated.mkdir()
        id_source = generated_id(nv, component, generated, out)
        expected = {(base/r['make_source']).resolve() for r in sources[component]} | {id_source}
        dryrun = out/(component+'-make-dryrun.txt')
        argv = ['gmake', '-n', '-B', '--no-print-directory', 'all', 'TARGET_OS=Darwin', 'TARGET_ARCH=x86_64',
                'CC=clang', 'CXX=clang++', 'NV_VERBOSE=1', 'NV_AUTO_DEPEND=0', 'LD_HAS_FORCE_GROUP_ALLOCATION=0',
                'EXTRA_CFLAGS=-DNV_UNIX -DNV_LINUX', 'OUTPUTDIR='+str(generated),
                'OUTPUTDIR_ABSOLUTE='+str(generated),
                'NV_BUILD_USER=g1', 'NV_BUILD_HOST=ci', 'NVIDIA_NVID_EXTRA=HONOR-G1-REBUILD-CANDIDATE']
        if run(argv, base, dryrun):
            raise ValueError(component+' official dry-run failed')
        commands = compile_plan(dryrun.read_text(encoding='utf-8'), base, expected)
        for source, original in commands.items():
            key = source.relative_to(nv).as_posix() if source.is_relative_to(nv) else component+'/generated/g_nvid_string.c'
            obj = object_path(objects, component, key)
            command = darwin_command(original, source, obj, sdk, headers)
            compile_jobs.append((component, source, obj, command, base, out/(obj.stem+'.txt'), original, key))
    report['required_c_translation_units'] = len(compile_jobs)
    write_json(out/'report.json', report)

    def compile_one(job):
        component, source, obj, argv, cwd, log, original, key = job
        inputs = None
        if key in BOUND_RM:
            rc, inputs, argv = bound_compile(argv, cwd, log, out/'input-snapshots', run)
        else:
            rc = run(argv, cwd, log)
        row = {'component': component, 'source': key, 'source_sha256': digest(source.read_bytes()),
               'object': str(obj), 'compile_exit': rc, 'official_argv': original, 'candidate_argv': argv,
               'compile_cwd': str(cwd), 'log': log.name}
        if key in BOUND_RM:
            row['dependency_snapshot'] = inputs
        if rc == 0:
            try:
                row['object_sha256'] = validate_object(obj)
            except (OSError, ValueError) as error:
                row.update({'compile_exit': 125, 'object_error': str(error)})
        if row['compile_exit']:
            row['first_errors'] = [l for l in log.read_text(encoding='utf-8').splitlines() if 'error:' in l][:3]
        return row

    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for index, row in enumerate(pool.map(compile_one, compile_jobs), 1):
            report['objects'].append(row)
            if index % 50 == 0:
                print(f'compiled attempts {index}/{len(compile_jobs)}', flush=True)
                write_json(out/'report.json', report)
    report['compiler_failures'] = sum(r['compile_exit'] != 0 for r in report['objects'])
    report['component_results'] = {component: {
        'required': len(sources[component])+1,
        'attempted': sum(r['component']==component for r in report['objects']),
        'failed': sum(r['component']==component and r['compile_exit']!=0 for r in report['objects'])}
        for component in COMPONENTS}
    print(json.dumps({'component_results': report['component_results'],
        'first_failed_units': [{'source': r['source'], 'exit': r['compile_exit'], 'first_errors': r.get('first_errors', [])}
            for r in report['objects'] if r['compile_exit']][:10]}), flush=True)
    if report['compiler_failures']:
        report['status'] = 'FULL_SOURCE_COMPILE_FAILED_NO_ARCHIVES_OR_LINK'
        return 2

    for family in SHADERS:
        raw_source = nv/'src/nvidia-modeset/src/shaders'/('g_'+family+'_shaders')
        raw = raw_source.read_bytes()
        packed_path = out/'nvidia-modeset-generated'/(family+'_shaders.xz')
        packed, assembly = shader_assembly(raw, family, packed_path)
        packed_path.write_bytes(packed)
        asm = packed_path.with_suffix('.S')
        asm.write_text(assembly, encoding='utf-8', newline='\n')
        obj = object_path(objects, 'nvidia-modeset', family+'_shaders.xz')
        argv = ['xcrun', 'clang', '-arch', 'x86_64', '-c', str(asm), '-o', str(obj)]
        rc = run(argv, out, out/(family+'-shader-embed.txt'))
        row = {'component': 'nvidia-modeset', 'source': raw_source.relative_to(nv).as_posix(),
               'source_sha256': digest(raw), 'xz_sha256': digest(packed), 'xz_bytes': len(packed),
               'generation': 'XZ check-none preset6 extreme + Darwin read-only start/end/size labels; raw bytes preserved',
               'object': str(obj), 'compile_exit': rc}
        if rc == 0:
            row['object_sha256'] = validate_object(obj)
        report['objects'].append(row)
        if rc:
            report['status'] = 'SHADER_EMBED_FAILED_NO_ARCHIVES_OR_LINK'
            return 2
    archives = []
    for component in COMPONENTS:
        rows = [r for r in report['objects'] if r['component']==component]
        expected_count = len(sources[component])+1+(len(SHADERS) if component=='nvidia-modeset' else 0)
        archive_allowed(rows, expected_count)
        archive = out/('lib'+component+'.a')
        if run(['xcrun', 'ar', 'rcs', str(archive), *[r['object'] for r in rows]], out,
               out/(component+'-archive.txt')):
            raise ValueError(component+' archive failed')
        report['archives'].append({'component': component, 'objects': len(rows), 'sha256': digest(archive.read_bytes())})
        archives.append(archive)
    native = json.loads((args.native_logs/'native-report.json').read_text(encoding='utf-8'))
    baseline = baseline_objects(native, args.candidate.resolve(), args.native_logs.resolve().parent,
        args.native_logs/'input-snapshots')
    # The public NullMoth shader TU embeds the same ten start/end labels. Replace
    # that input explicitly with all five fixed OGKM payload objects, never both.
    replaced = [r for r in baseline if r['source']=='kexts/NVRM/nvkms_shaders.cpp']
    baseline = [r for r in baseline if r not in replaced]
    dest = out/'NVRM-complete-source-candidate.kext/Contents/MacOS/NVRM'
    dest.parent.mkdir(parents=True)
    argv = ['xcrun', 'clang++', '-arch', 'x86_64', '-mmacosx-version-min=15.5', '-fapple-kext',
            '-isysroot', sdk, '-nostdlib', '-Xlinker', '-kext', '-Wl,-why_load',
            *[r['object'] for r in baseline], *map(str, archives), '-lkmodc++', '-lkmod', '-lcc_kext', '-o', str(dest)]
    # Observe the no-addon link in the SAME run before adding the real provider.
    original_dest = dest.with_name('NVRM-without-nvlink-provider')
    baseline_argv = [*argv[:-1], str(original_dest)]
    baseline_rc = run(baseline_argv, out, out/'before-nvlink-link.txt')
    report['before_nvlink'] = {'link_exit': baseline_rc}
    if baseline_rc:
        raise ValueError('same-run no-addon baseline link failed')
    report['before_nvlink']['artifact_sha256'] = validate_kext(original_dest)
    before_nm = out/'before-nvlink-undefined.txt'
    if run(['xcrun', 'nm', '-u', str(original_dest)], out, before_nm):
        raise ValueError('same-run baseline nm failed')
    before = parse_nm_undefined(before_nm.read_text(encoding='utf-8'))
    report['before_nvlink']['undefined_symbols'] = before
    addon = compile_nvlink(nv, out, sdk, headers, report)
    argv.insert(argv.index('-lkmodc++'), str(addon))
    rc = run(argv, out, out/'full-nvrm-link.txt')
    report['link'] = {'exit': rc, 'baseline_objects': [r['object'] for r in baseline],
                       'archive_order': list(map(str, archives)),
                       'replaced_baseline_inputs': [{'source': r['source'], 'object_sha256': r['object_sha256'],
                           'reason': 'explicit replacement of embedded shader labels by five fixed OGKM payload objects'}
                           for r in replaced]}
    if rc:
        report['status'] = 'COMPLETE_ARCHIVES_LINK_FAILED'
        return 2
    for label, flags in [('undefined', ['-u']), ('defined', ['-gU'])]:
        if run(['xcrun', 'nm', *flags, str(dest)], out, out/('full-nvrm-'+label+'.txt')):
            raise ValueError('linked symbol inventory failed')
    report['link']['undefined_symbols'] = parse_nm_undefined((out/'full-nvrm-undefined.txt').read_text(encoding='utf-8'))
    report['link']['extra_objects'] = [str(addon)]
    report['link']['nvlink_delta'] = nvlink_delta(before, report['link']['undefined_symbols'],
                                                 read_defined_log(out/'full-nvrm-defined.txt'))
    report['link']['artifact_sha256'] = validate_kext(dest)
    fixed_input(nv)
    report['status'] = 'COMPLETE_SOURCE_CANDIDATE_LINKED_NOT_CLOSURE_OR_ABI_ACCEPTED'
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--nv', type=Path, required=True)
    parser.add_argument('--candidate', type=Path)
    parser.add_argument('--native-logs', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=2, choices=range(1, 5))
    parser.add_argument('--inventory-only', action='store_true')
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    report = {'schema': 'honor.g1.full-source-build.v1', 'pins': {'nv': OGKM_PIN, 'nm': NM_PIN},
              'status': 'STARTED', 'objects': [], 'archives': [], 'link': None,
              'dependency_closure': 'NOT_ACCEPTED_KERNEL_EXPORTS_AND_FULL_ABI_UNVERIFIED',
              'candidate_identity': 'HONOR G1 REBUILD CANDIDATE', 'kext_load': 'NO-GO', 'gpu_execution': False}
    rc = 2
    try:
        fixed_input(args.nv.resolve())
        if args.inventory_only:
            report.update({'status': 'SOURCE_INVENTORY_ONLY_NOT_COMPILED', 'source_inventory': inventory(args.nv.resolve())})
            rc = 0
        elif not args.candidate or not args.native_logs:
            raise ValueError('current native candidate and logs required')
        else:
            rc = build(args, report)
    except Exception as error:
        report.update({'status': 'FAILED', 'error': type(error).__name__+': '+str(error)})
    finally:
        write_json(args.out/'report.json', report)
    print(json.dumps({'status': report['status'], 'attempts': len(report['objects']),
                      'compiler_failures': report.get('compiler_failures'), 'dependency_closure': report['dependency_closure']}))
    return rc


if __name__ == '__main__':
    raise SystemExit(main())
