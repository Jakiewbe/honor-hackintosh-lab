#!/usr/bin/env python3
"""Rebuild nine actual NVRM TUs, observe PCI calls, compare SDK call shapes.

No wrapper around the actual callers, no RM rebuild/link, no driver execution.
The historic complete-build command and transitive file hashes are checked;
this is selected caller ABI evidence, not full provider/loader/semantic ABI.
"""
import hashlib
import json
from pathlib import Path
import platform
import re
import subprocess

from g1_compile_inputs import bound_compile, check_inputs, dep_paths, TARGET, verify_snapshot
from g1_full_abi import function_record, split_parameters, parameter_abi
from g1_full_build import BASELINE_CPP, validate_object
from g1_kc8 import TARGETS
from g1_kc8_sdk import source as sdk_source
from g1_rm_abi import diagnostic_base
from g1_symbol_identity import parse_nm_undefined

METHODS = TARGETS['com.apple.iokit.IOPCIFamily'][:6]
ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, indent=2)+'\n', encoding='utf-8')


def calls(ir, name):
    """Keep exact direct call sites and enclosing function; parse call ABI too."""
    found, owner = [], None
    for line in ir.splitlines():
        if line.startswith('define '): owner = line
        if line == '}': owner = None
        match = re.search(r'\bcall ([^\n]*?)@'+re.escape(name)+r'\((.*)\)', line)
        if not match: continue
        # Matching close is needed when attributes or operands contain parentheses.
        rest = line[line.index('@'+name)+len(name)+2:]
        depth, stop = 1, 0
        while depth and stop < len(rest):
            if rest[stop] == '(': depth += 1
            if rest[stop] == ')': depth -= 1
            stop += 1
        if depth or not owner: raise ValueError('incomplete/out-of-function direct call')
        args = split_parameters(rest[:stop-1])
        stripped = []
        for arg in args:
            # Only scalar types/SSA or scalar constant values are supported here.
            cleaned = re.sub(r'(?:%[-A-Za-z$._0-9]+|-?\d+|null|undef|poison)\s*$', '', arg).strip()
            parameter_abi(cleaned)  # reject unexplained operands/ABI attributes
            stripped.append(cleaned)
        record = function_record('declare '+match[1]+'@'+name+'('+', '.join(stripped)+')', name)
        found.append({'owner': owner, 'line': line.strip(), 'abi': record['abi']})
    return found


def method_observation(ir, name, imports, sdk):
    llvm = name[1:]
    sites = calls(ir, llvm)
    if not sites:
        return {'macho_symbol': name, 'status': 'NOT_OBSERVED_IN_THIS_TU', 'calls': []}
    actual = function_record(ir, llvm)
    expected = function_record(sdk, llvm)
    if name not in imports:
        raise ValueError('IR call absent from real object import set: '+name)
    if actual['abi'] != expected['abi'] or any(s['abi'] != expected['abi'] for s in sites):
        raise ValueError('caller/declaration/SDK ABI shape mismatch: '+name)
    return {'macho_symbol': name, 'status': 'REAL_OBJECT_IMPORT_AND_DIRECT_CALL_SHAPE_MATCH',
        'declaration': actual, 'sdk_declaration': expected, 'calls': sites}


def normalize(argv, source, candidate, nv, sdk):
    base, removed = diagnostic_base(argv, source)
    # Do not infer flag equivalence. Preserve ordering, spelling and duplicates.
    return [v.replace(str(candidate), '$CANDIDATE').replace(str(nv), '$NV').replace(str(sdk), '$SDK') for v in base]


def historic_check(rel, argv, candidate, nv, sdk):
    path = ROOT/'research/gpu-safety-r5/input-binding-evidence/input-snapshots'/('uni-'+Path(rel).name.replace('.', '_')+'.json')
    old = json.loads(path.read_text(encoding='utf-8'))
    source = candidate/rel
    old_src, old_candidate = Path(old['source']), Path(old['cwd'])
    old_sdk = Path(old['compile_argv'][old['compile_argv'].index('-isysroot')+1])
    roots = {Path(v[2:]).parents[5] for v in old['compile_argv']
             if v.startswith('-I') and Path(v[2:]).as_posix().endswith('/src/nvidia/arch/nvalloc/unix/include')}
    if len(roots) != 1: raise ValueError('ambiguous/missing historical OGKM include root')
    prefix = roots.pop()
    # Historical POSIX paths must be interpreted on the Darwin runner, not Windows.
    expected = normalize(old['compile_argv'], old_src, old_candidate, Path(prefix), old_sdk)
    observed = normalize(argv, source, candidate, nv, sdk)
    if observed != expected:
        raise ValueError('current caller profile differs from actual historical linked TU: '+rel)
    source_hash = next(r['sha256'] for r in old['inputs'] if r['resolved_path'] == old['source'])
    if sha(source) != source_hash: raise ValueError('candidate TU changed since full build: '+rel)
    return {'snapshot': str(path.relative_to(ROOT)), 'snapshot_sha256': sha(path),
        'historical_source_sha256': source_hash, 'normalized_flags': observed,
        'status': 'EXACT_ORDERED_FLAGS_AND_SOURCE_MATCH_AFTER_ROOT_RELOCATION'}


def run(nv, candidate, out, flags, native_report, execute):
    report = {'status': 'INCOMPLETE', 'level': 'SELECTED_REAL_CALLER_ABI_SHAPE_ONLY',
        'methods': METHODS, 'units': [], 'failures': [], 'kext_load': 'NO-GO',
        'gpu_runtime': 'NOT_RUN', 'full_abi': 'NOT_VERIFIED',
        'historical_complete_run': 39127772586,
        'limitations': ['no provider implementation or loader export/version validation',
            'no class/vtable/ownership or PM semantics acceptance', 'no RM rebuild, kext link or execution']}
    try:
        if platform.system() != 'Darwin' or platform.machine() != 'x86_64':
            raise ValueError('native Darwin Intel required')
        sdk = Path(flags[flags.index('-isysroot')+1])
        env = {}
        for key, cmd in [('sdk_version', ['xcrun','--show-sdk-version']), ('xcode',['xcodebuild','-version']),
            ('compiler',['xcrun','clang++','--version']), ('os',['sw_vers']), ('host',['uname','-m'])]:
            env[key] = subprocess.check_output(cmd, text=True).strip()
        if env['sdk_version'] != '15.5': raise ValueError('SDK15.5 required')
        report['environment'] = env
        src, sdk_ir = out/'sdk-methods.cpp', out/'sdk-methods.ll'
        src.write_text(sdk_source(), encoding='utf-8')
        if execute(['xcrun','clang++',*flags,'-S','-emit-llvm',str(src),'-o',str(sdk_ir)], candidate, out/'sdk-compile.txt'):
            raise ValueError('SDK method diagnostic failed')
        sdk_text = sdk_ir.read_text(encoding='utf-8')
        report['sdk_ir_sha256'] = sha(sdk_ir)
        report['sdk_declarations'] = {n:function_record(sdk_text,n[1:]) for n in METHODS}
        for rel in sorted(BASELINE_CPP):
            stem = 'uni-'+Path(rel).name.replace('.', '_')
            source, obj = candidate/rel, out.parent/(stem+'.o')
            argv = ['xcrun','clang++',*flags,'-c',str(source),'-o',str(obj)]
            row = {'source': rel, 'source_sha256': sha(source)}
            report['units'].append(row)
            row['historical_profile'] = historic_check(rel, argv, candidate, nv, sdk)
            rc, descriptor, actual = bound_compile(argv, candidate, out/(stem+'.txt'), out/'input-snapshots', execute)
            row.update({'compile_exit': rc, 'compile_argv': actual, 'dependency_snapshot': descriptor})
            if rc: raise ValueError('actual caller object compile failed: '+rel)
            row['object_sha256'] = validate_object(obj)
            snapshot = verify_snapshot(descriptor, out/'input-snapshots', source, obj, row['object_sha256'], actual)
            # Same original TU, no synthetic wrapper; verify identical transitive dependencies.
            ir, dep = out/(stem+'.ll'), out/(stem+'-ir.d')
            base, _ = diagnostic_base(actual, source)
            ir_argv = [*base,'-MD','-MF',str(dep),'-MT',TARGET,'-S','-emit-llvm',str(source),'-o',str(ir)]
            row['ir_argv'] = ir_argv
            row['ir_exit'] = execute(ir_argv, candidate, out/(stem+'-ir.txt'))
            if row['ir_exit']: raise ValueError('actual caller IR compile failed: '+rel)
            check_inputs(snapshot['inputs'])
            if list(map(str, dep_paths(dep.read_text(encoding='utf-8'),candidate))) != [r['path'] for r in snapshot['inputs']]:
                raise ValueError('actual caller IR dependency set changed')
            row['ir_sha256'], row['ir_dependency_sha256'] = sha(ir), sha(dep)
            undef = out/(stem+'-undefined.txt')
            if execute(['xcrun','nm','-u',str(obj)], candidate, undef): raise ValueError('object nm failed')
            imports = set(parse_nm_undefined(undef.read_text(encoding='utf-8')))
            row['object_undefined_sha256'] = sha(undef)
            text = ir.read_text(encoding='utf-8')
            if not re.search(r'^target triple = "x86_64-apple-',text,re.M): raise ValueError('unexpected IR target')
            row['records'] = [method_observation(text,n,imports,sdk_text) for n in METHODS]
            row['status'] = 'OBSERVED'
        seen = {r['macho_symbol'] for u in report['units'] for r in u['records'] if r['calls']}
        report['unobserved_methods'] = sorted(set(METHODS)-seen)
        if report['unobserved_methods']: raise ValueError('required real caller methods still unobserved')
        report['status'] = 'SIX_METHOD_REAL_CALLER_SHAPES_MATCH_SDK'
        native_report['level'] = report['status']
    except (OSError, ValueError, KeyError, StopIteration, subprocess.CalledProcessError) as error:
        report['failures'].append(type(error).__name__+': '+str(error))
        raise
    finally:
        write(out/'caller-report.json', report)
    print(json.dumps({'status':report['status'], 'units':len(report['units']), 'unobserved':report['unobserved_methods']}))
