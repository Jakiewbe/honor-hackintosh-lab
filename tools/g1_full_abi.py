#!/usr/bin/env python3
"""Observe selected ABI with this run's full official per-TU candidate commands.

No probe-flag fallback, no driver execution, no additional linked driver object.
Opaque LLVM pointers do not establish pointee, callback or ownership contracts.
"""
import argparse
import json
from pathlib import Path
import re

from g1_full_build import (NM_PIN, OGKM_PIN, archive_allowed, baseline_objects,
    darwin_command, fixed_input, validate_kext, validate_object)
from g1_rm_abi import (CPP_PROFILES, RM_SOURCES, SELECTORS, altstack_conflicts,
    compare_layouts, diagnostic_base, execute, parse_layout, sha, source_audit, wrapper)

PREFIX = 'full-'
RETAIN = 'honor_g1_full_sig_'
STATUS = 'COMPLETE_SOURCE_CANDIDATE_LINKED_NOT_CLOSURE_OR_ABI_ACCEPTED'
TYPE = r'(?:void|i[1-9][0-9]*|ptr(?: addrspace\([0-9]+\))?)'
OPT_ATTR = re.compile(r'\b(?:noundef|nocapture|nonnull|readonly|readnone|writeonly|returned|noalias|nofree|immarg)\b|'
                      r'\b(?:dereferenceable(?:_or_null)?|range|captures)\([^()]*\)')


def successful_argv(path):
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()
    if (not lines or not lines[0].startswith('ARGV=') or lines[-1] != 'EXIT=0'
            or re.findall(r'^EXIT=(-?\d+)\s*$', text, re.M) != ['0']):
        raise ValueError('compile log missing a unique final success')
    argv = json.loads(lines[0][5:])
    if not isinstance(argv, list) or not all(isinstance(x, str) for x in argv):
        raise ValueError('invalid compile argv')
    return argv


def rm_profile(row, nv, full_dir, sdk):
    rel = row['source']
    if rel not in RM_SOURCES or row.get('component') != 'nvidia':
        raise ValueError('not a selected full RM source')
    source = (nv/rel).resolve()
    obj = Path(row['object'])
    cwd = (nv/'src/nvidia').resolve()
    if row.get('compile_exit') != 0 or row.get('source_sha256') != sha(source):
        raise ValueError('full RM source/compile mismatch')
    if row.get('compile_cwd') != str(cwd):
        raise ValueError('explicit official compile cwd required; no probe fallback')
    if obj.is_symlink() or obj.resolve().parent != (full_dir/'objects').resolve():
        raise ValueError('RM object outside current full run')
    if validate_object(obj) != row.get('object_sha256'):
        raise ValueError('RM object hash mismatch')
    official = row['official_argv']
    if official.count('-c') != 1 or (cwd/official[official.index('-c')+1]).resolve() != source:
        raise ValueError('official source does not match selected TU')
    headers = Path(sdk)/'System/Library/Frameworks/Kernel.framework/Headers'
    expected = darwin_command(official, source, obj, sdk, headers)
    if expected != row.get('candidate_argv'):
        raise ValueError('candidate argv differs from recorded official transformation')
    log = full_dir/row['log']
    if log.resolve().parent != full_dir.resolve() or successful_argv(log) != expected:
        raise ValueError('full compile log differs from manifest')
    return {'profile': PREFIX+rel.replace('/', '_'), 'source': source, 'cwd': cwd,
            'argv': expected, 'object': str(obj), 'object_sha256': row['object_sha256'],
            'source_sha256': row['source_sha256'], 'compile_log_sha256': sha(log),
            'origin': 'full-source/report.json candidate_argv; exact official transformation'}


def profiles(nv, nm, logs, full_path):
    if full_path.resolve() != (logs/'full-source/report.json').resolve():
        raise ValueError('full report must belong to the same native logs directory')
    full = json.loads(full_path.read_text(encoding='utf-8'))
    if (full.get('status') != STATUS or full.get('pins') != {'nv': OGKM_PIN, 'nm': NM_PIN}
            or full.get('compiler_failures') != 0 or full.get('link', {}).get('exit') != 0):
        raise ValueError('successful fixed full-source candidate required')
    archive_allowed(full['objects'], 1285)
    if full.get('component_results') != {
            'nvidia': {'required': 1055, 'attempted': 1055, 'failed': 0},
            'nvidia-modeset': {'required': 225, 'attempted': 225, 'failed': 0}}:
        raise ValueError('full source cardinalities mismatch')
    full_dir = full_path.parent.resolve()
    if validate_kext(full_dir/'NVRM-complete-source-candidate.kext/Contents/MacOS/NVRM') != full['link']['artifact_sha256']:
        raise ValueError('current full candidate bytes differ from report')
    expected_archives = [str(full_dir/('lib'+c+'.a')) for c in ['nvidia', 'nvidia-modeset']]
    if full['link'].get('archive_order') != expected_archives:
        raise ValueError('full link does not contain both official archives')
    for component, count in [('nvidia', 1055), ('nvidia-modeset', 230)]:
        rows = [r for r in full['archives'] if r['component'] == component]
        if len(rows) != 1 or rows[0]['objects'] != count or sha(full_dir/('lib'+component+'.a')) != rows[0]['sha256']:
            raise ValueError('archive inventory or current bytes mismatch')
    result = []
    for rel in RM_SOURCES:
        found = [r for r in full['objects'] if r['source'] == rel]
        if len(found) != 1:
            raise ValueError('missing/duplicate official RM profile: '+rel)
        result.append(rm_profile(found[0], nv, full_dir, full['sdk']))
    native = json.loads((logs/'native-report.json').read_text(encoding='utf-8'))
    baseline = baseline_objects(native, nm, logs.parent)
    for profile, rel in CPP_PROFILES:
        row, = [r for r in baseline if r['source'] == rel]
        if full['link']['baseline_objects'].count(row['object']) != 1:
            raise ValueError('C++ object not included exactly once in full candidate link')
        log = logs/(profile+'.txt')
        argv = successful_argv(log)
        diagnostic_base(argv, nm/rel)
        if argv[-1] != row['object']:
            raise ValueError('C++ compile object/log mismatch')
        result.append({'profile': profile, 'source': (nm/rel).resolve(), 'cwd': nm,
            'argv': argv, 'object': row['object'], 'object_sha256': row['object_sha256'],
            'source_sha256': row['source_sha256'], 'compile_log_sha256': sha(log),
            'origin': 'native-report manifest + actual unified TU compile log + full link input'})
    return full, result


def full_wrapper(source, targets):
    if not targets or len(targets) != len(set(targets)) or any(not re.fullmatch(r'rm_[a-z0-9_]+', t) for t in targets):
        raise ValueError('unique explicit RM boundary symbols required')
    if RETAIN in source.read_text(encoding='utf-8'):
        raise ValueError('diagnostic retention symbol collision')
    text = wrapper(source)
    text += '\n#ifdef __cplusplus\nextern "C" {\n#endif\n'
    for name in sorted(targets):
        text += '__attribute__((used)) __typeof__(&'+name+') '+RETAIN+name+' = &'+name+';\n'
    return text+'#ifdef __cplusplus\n}\n#endif\n'


def split_parameters(text):
    result, start, depth = [], 0, 0
    for i, char in enumerate(text):
        if char in '([{<': depth += 1
        elif char in ')]}>': depth -= 1
        elif char == ',' and depth == 0:
            result.append(text[start:i].strip())
            start = i+1
        if depth < 0: raise ValueError('unbalanced parameter list')
    if depth: raise ValueError('unbalanced parameter list')
    if text.strip(): result.append(text[start:].strip())
    return result


def parameter_abi(text):
    match = re.match('^('+TYPE+r')\b', text)
    if not match or match[1] == 'void':
        raise ValueError('unsupported LLVM parameter type: '+text)
    rest = text[match.end():]
    # Values and optimizer-derived promises are not ABI distinctions.
    rest = re.sub(r'%[-A-Za-z$._0-9]+\s*$', '', rest)
    rest = OPT_ATTR.sub('', rest)
    attributes = re.findall(r'\b(?:zeroext|signext|inreg|nest|swiftself|swifterror)\b', rest)
    rest = re.sub(r'\b(?:zeroext|signext|inreg|nest|swiftself|swifterror)\b', '', rest)
    # Unknown ABI constructs (e.g. byval/sret aggregates) must not silently match.
    if rest.strip():
        raise ValueError('unhandled LLVM parameter attributes: '+rest.strip())
    return {'type': match[1], 'abi_attributes': sorted(attributes)}


def function_record(ir, name, require_definition=False):
    matches = list(re.finditer(r'^(define|declare) ([^\n]*?)@'+re.escape(name)+r'\(([^\n]*)\)[^\n]*$', ir, re.M))
    if len(matches) != 1:
        raise ValueError('missing/duplicate LLVM C symbol: '+name)
    match = matches[0]
    kind, prefix, params = match[1], match[2].strip(), match[3]
    # The greedy parameter group may include trailing function attributes with ():
    # re-find the matching argument-list close rather than accepting the last ')'.
    opening = ir.index('(', match.start()+match[0].index('@'+name))
    depth, closing = 1, opening+1
    while depth and closing < len(ir):
        if ir[closing] == '(': depth += 1
        elif ir[closing] == ')': depth -= 1
        closing += 1
    if depth: raise ValueError('incomplete LLVM function arguments')
    params = ir[opening+1:closing-1]
    ret = re.search('('+TYPE+r')$', prefix)
    if not ret: raise ValueError('unsupported LLVM return type: '+prefix)
    before = prefix[:ret.start()]
    before = OPT_ATTR.sub('', before)
    cc = re.findall(r'\b(?:[a-zA-Z_][a-zA-Z_0-9]*cc|cc\s+[0-9]+)\b', before)
    if len(cc) > 1: raise ValueError('ambiguous LLVM calling convention')
    ret_attrs = re.findall(r'\b(?:zeroext|signext|inreg)\b', before)
    remainder = re.sub(r'\b(?:zeroext|signext|inreg|dso_local|dso_preemptable|hidden|protected|default|external)\b', '', before)
    if cc: remainder = remainder.replace(cc[0], '')
    if remainder.strip(): raise ValueError('unhandled LLVM return/linkage attributes: '+remainder.strip())
    parts = split_parameters(params)
    varargs = bool(parts and parts[-1] == '...')
    if varargs: parts.pop()
    abi = {'return_type': ret[1], 'return_attributes': sorted(ret_attrs),
           'calling_convention': cc[0] if cc and cc[0] != 'ccc' else 'ccc',
           'parameters': [parameter_abi(p) for p in parts], 'variadic': varargs}
    body, asm = None, []
    if kind == 'define':
        end = ir.find('\n}', closing)
        if end < 0: raise ValueError('truncated LLVM function definition')
        body = ir[closing:end]
        asm = [line.strip() for line in body.splitlines() if re.search(r'\basm\b', line)]
    if require_definition and body is None:
        raise ValueError('provider is only a declaration: '+name)
    return {'kind': kind, 'abi': abi, 'inline_asm': asm,
            'direct_stack_register_asm': [line for line in asm if re.search(r'\b(?:r[bs]p|e[bs]p)\b', line)]}


def signatures(ir, names):
    result = {}
    for name in names:
        markers = re.findall(r'^@'+re.escape(RETAIN+name)+r' = [^\n]*@'+re.escape(name)+r'(?=,|\s|$)[^\n]*$', ir, re.M)
        if len(markers) != 1:
            raise ValueError('typed retention reference missing/ambiguous: '+name)
        result[name] = function_record(ir, name)
    return result


def compare_signatures(units, audit):
    expected = {PREFIX+rel.replace('/', '_') for rel in RM_SOURCES} | {p for p, _ in CPP_PROFILES}
    names = {r['name'] for r in audit['runtime_targets']}
    if (len(units) != 6 or {u['profile'] for u in units} != expected
            or any(set(u.get('signatures', {})) != names for u in units)):
        return {'status': 'INCOMPLETE', 'symbols': len(names), 'differences': []}
    differences = []
    for target in audit['runtime_targets']:
        name = target['name']
        provider = next(u for u in units if u['profile'] == PREFIX+target['path'].replace('/', '_'))
        if provider['signatures'][name]['kind'] != 'define':
            raise ValueError('real provider definition missing: '+name)
        observed = {u['profile']: u['signatures'][name]['abi'] for u in units}
        if any(value != provider['signatures'][name]['abi'] for value in observed.values()):
            differences.append({'symbol': name, 'profiles': observed})
    return {'status': 'SELECTED_SIGNATURE_MISMATCH' if differences else 'SELECTED_SIGNATURE_MATCH',
            'symbols': len(names), 'differences': differences}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--nv', type=Path, required=True)
    p.add_argument('--candidate', type=Path, required=True)
    p.add_argument('--logs', type=Path, required=True)
    p.add_argument('--full-report', type=Path, required=True)
    p.add_argument('--definitions', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    nv, nm, logs, out = [x.resolve() for x in [args.nv, args.candidate, args.logs, args.out]]
    out.mkdir(parents=True, exist_ok=False)
    report = {'schema': 'honor.g1.full-flags-abi.v1', 'result': 'INCOMPLETE', 'units': [],
        'failures': [], 'full_report_sha256': sha(args.full_report),
        'native_report_sha256': sha(logs/'native-report.json'),
        'scope': 'three official full RM commands vs three actual NVRM C++ commands; selected layouts and 20 scalar/opaque-pointer function ABI shapes',
        'full_abi_acceptance': 'NOT_ESTABLISHED', 'kext_load': 'NO-GO', 'gpu_runtime': 'NOT_RUN',
        'limitations': ['opaque pointer pointees, callback signatures, nested and unlisted fields not verified',
            'C atomic vs C++ volatile ownership/ordering is not validated by equal layout',
            'wrapper includes unchanged full TU; base file/include level differs from production',
            'end-of-TU macros are not header-time traces; direct inline-asm evidence is selected function IR only']}
    try:
        fixed_input(nv)
        full, plan = profiles(nv, nm, logs, args.full_report.resolve())
        names = set(json.loads(args.definitions.read_text(encoding='utf-8'))['found'])
        audit = source_audit(nv, nm, names)
        targets = [r['name'] for r in audit['runtime_targets']]
        if len(targets) != 20 or len(set(targets)) != 20:
            raise ValueError('fixed 20 runtime boundary definitions required')
        (out/'source-inputs.json').write_text(json.dumps(audit, indent=2)+'\n', encoding='utf-8')
        report['candidate_sha256'] = full['link']['artifact_sha256']
        for item in plan:
            entry = {key: str(value) if isinstance(value, Path) else value for key, value in item.items()}
            report['units'].append(entry)
            profile, source, cwd = item['profile'], item['source'], item['cwd']
            try:
                base, removed = diagnostic_base(item['argv'], source)
                entry['removed_action_arguments'] = removed
                generated = out/(profile+source.suffix)
                generated.write_text(full_wrapper(source, targets), encoding='utf-8')
                entry['wrapper_sha256'] = sha(generated)
                ir = out/(profile+'.ll')
                command = [*base, '-S', '-emit-llvm', str(generated), '-o', str(ir)]
                entry['llvm_command'] = command
                entry['llvm_exit'] = execute(command, cwd, out/(profile+'-ir.stdout.txt'), out/(profile+'-ir.stderr.txt'))
                if entry['llvm_exit']:
                    raise ValueError('full command LLVM diagnostic compile failed')
                entry['llvm_sha256'] = sha(ir)
                ir_text = ir.read_text(encoding='utf-8')
                entry['target_triple'], entry['layout'] = parse_layout(ir_text)
                layouts = re.findall(r'^target datalayout = "([^"]+)"$', ir_text, re.M)
                if len(layouts) != 1: raise ValueError('missing/duplicate LLVM target datalayout')
                entry['target_datalayout'] = layouts[0]
                entry['signatures'] = signatures(ir_text, targets)
                macros_path = out/(profile+'-macros.txt')
                command = [*base, '-E', '-dM', str(generated)]
                entry['macro_command'] = command
                entry['macro_exit'] = execute(command, cwd, macros_path, out/(profile+'-macros.stderr.txt'))
                if entry['macro_exit']: raise ValueError('full command macro observation failed')
                entry['macro_sha256'] = sha(macros_path)
                macros = dict(re.findall(r'^#define[ \t]+(\w+)[ \t]*([^\n]*)$', macros_path.read_text(encoding='utf-8'), re.M))
                entry['selectors'] = {key: macros.get(key) for key in SELECTORS}
                entry['altstack_defined'] = '__use_altstack__' in macros
                entry['status'] = 'OBSERVED'
            except (OSError, ValueError) as error:
                entry.update({'status': 'INCOMPLETE', 'error': str(error)})
                report['failures'].append(profile)
        report['layouts'] = compare_layouts(report['units'], rm_prefix=PREFIX)
        report['signatures'] = compare_signatures(report['units'], audit)
        report['altstack_null_conflicts'] = altstack_conflicts(report['units'], audit, rm_prefix=PREFIX)
        report['stack_asm_observations'] = []
        for target in audit['runtime_targets']:
            unit = next(u for u in report['units'] if u['profile'] == PREFIX+target['path'].replace('/', '_'))
            record = unit.get('signatures', {}).get(target['name'])
            report['stack_asm_observations'].append({'symbol': target['name'], 'profile': unit['profile'],
                'kind': record['kind'] if record else 'NOT_OBSERVED',
                'direct_stack_register_asm': record['direct_stack_register_asm'] if record else None})
        stack_ok = all(r['kind'] == 'define' and r['direct_stack_register_asm'] == [] for r in report['stack_asm_observations'])
        report['target_environment_match'] = (len(report['units']) == 6 and
            len({(u.get('target_triple'), u.get('target_datalayout')) for u in report['units']}) == 1
            and all(u.get('target_datalayout') for u in report['units']))
        if (not report['failures'] and report['layouts']['status'] == 'SELECTED_LAYOUT_MATCH'
                and report['signatures']['status'] == 'SELECTED_SIGNATURE_MATCH'
                and not report['altstack_null_conflicts'] and stack_ok and report['target_environment_match']):
            report['result'] = 'OBSERVED_SELECTED_FULL_FLAGS_CONTRACT_MATCH'
        fixed_input(nv)
    except (OSError, ValueError, KeyError) as error:
        report['error'] = type(error).__name__+': '+str(error)
    (out/'full-abi-report.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'result': report['result'], 'profiles': len(report['units']), 'failures': report['failures'],
                      'layouts': report.get('layouts', {}).get('status'), 'signatures': report.get('signatures', {}).get('status')}))
    return 0 if report['result'] == 'OBSERVED_SELECTED_FULL_FLAGS_CONTRACT_MATCH' else 2


if __name__ == '__main__':
    raise SystemExit(main())
