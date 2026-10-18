#!/usr/bin/env python3
"""Compile six SDK method calls to IR; compare observed historical caller types."""
import argparse
import hashlib
import json
from pathlib import Path
import re

from g1_full_abi import function_record
from g1_target_providers import command, write
from g1_kc8 import TARGETS


def source():
    text = '#include <IOKit/pci/IOPCIDevice.h>\n#include <IOKit/acpi/IOACPIPlatformDevice.h>\n'
    for bits in (8, 16, 32):
        text += ('extern "C" auto kc_read'+str(bits)+'(IOPCIDevice* p, IOByteCount o) '
                 '{ return p->extendedConfigRead'+str(bits)+'(o); }\n')
        text += ('extern "C" void kc_write'+str(bits)+'(IOPCIDevice* p, IOByteCount o, UInt'+str(bits)+' v) '
                 '{ p->extendedConfigWrite'+str(bits)+'(o, v); }\n')
    text += 'extern "C" const void* kc_pci_meta() { return &IOPCIDevice::metaClass; }\n'
    text += 'extern "C" const void* kc_acpi_meta() { return &IOACPIPlatformDevice::metaClass; }\n'
    return text


def compare(ir, caller):
    records = []
    for name in TARGETS['com.apple.iokit.IOPCIFamily'][:6]:
        # Mach-O has one additional leading underscore relative to LLVM/C++.
        llvm = name[1:]
        observed = function_record(ir, llvm)
        prior = caller['declarations'].get(llvm)
        expected = function_record(prior['line'], llvm) if prior else None
        records.append({'macho_symbol': name, 'sdk_declaration': observed,
            'historical_caller_declaration': expected,
            'status': ('SDK_CALLER_TYPE_MATCH' if observed['abi'] == expected['abi'] else 'SDK_CALLER_TYPE_MISMATCH')
                if expected else 'HISTORICAL_CALLER_IR_NOT_OBSERVED',
            'level': 'COMPILER_CALL_ABI_SHAPE_ONLY_NOT_PROVIDER_IMPLEMENTATION_ABI'})
    return records


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out', required=True, type=Path)
    p.add_argument('--caller', required=True, type=Path)
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    caller_bytes = args.caller.read_bytes()
    caller = json.loads(caller_bytes)
    abi_report = Path('research/gpu-safety-r5/input-binding-evidence/full-flags-abi/full-abi-report.json')
    prior = json.loads(abi_report.read_text(encoding='utf-8'))
    unit = next(r for r in prior['units'] if r['profile'] == 'uni-NVRM_cpp')
    if unit['llvm_sha256'] != caller['original_ir_sha256']:
        raise ValueError('historical caller selection differs from fixed full-flags ABI record')
    rc, stdout, stderr = command(['xcrun', '--show-sdk-path'])
    if rc:
        raise ValueError('SDK identity unavailable')
    sdk = Path(stdout.decode().strip())
    environment = {}
    for name, cmd in [('sdk_version', ['xcrun', '--show-sdk-version']),
        ('xcode', ['xcodebuild', '-version']), ('compiler', ['xcrun', 'clang++', '--version']),
        ('os', ['sw_vers']), ('kernel', ['uname', '-r'])]:
        code, data, diagnostic = command(cmd)
        environment[name] = {'argv': cmd, 'exit': code, 'stdout': data.decode(), 'stderr': diagnostic.decode()}
        if code:
            raise ValueError('toolchain identity failed: '+name)
    if environment['sdk_version']['stdout'].strip() != '15.5':
        raise ValueError('this diagnostic requires fixed SDK15.5')
    src, ir, deps = [args.out/name for name in ['sdk-methods.cpp', 'sdk-methods.ll', 'sdk-methods.d']]
    src.write_text(source(), encoding='utf-8')
    kernel = sdk/'System/Library/Frameworks/Kernel.framework/Headers'
    header_paths = [kernel/rel for rel in ['IOKit/pci/IOPCIDevice.h', 'IOKit/acpi/IOACPIPlatformDevice.h']]
    before = {str(path): path.read_bytes() for path in header_paths}
    argv = ['xcrun', 'clang++', '-arch', 'x86_64', '-mmacosx-version-min=15.5',
        '-isysroot', str(sdk), '-fapple-kext', '-mkernel', '-nostdinc', '-I'+str(kernel),
        '-DKERNEL', '-DKERNEL_PRIVATE', '-DDRIVER_PRIVATE', '-DAPPLE', '-DNeXT',
        '-std=c++17', '-fno-rtti', '-fno-exceptions', '-fno-builtin', '-fno-common',
        '-O2', '-MD', '-MF', str(deps), '-S', '-emit-llvm', str(src), '-o', str(ir)]
    rc, stdout, stderr = command(argv)
    compile_row = {'argv': argv, 'exit': rc, 'stdout': stdout.decode(), 'stderr': stderr.decode()}
    write(args.out/'sdk-compile.json', compile_row)
    if rc or not ir.is_file():
        raise ValueError('SDK method IR compile failed')
    text = ir.read_text(encoding='utf-8')
    rows = compare(text, caller)
    # Exact header content is hashed, not published as an Apple SDK copy.
    headers = []
    for path in header_paths:
        raw = path.read_bytes()
        if raw != before[str(path)]:
            raise ValueError('primary SDK header changed during diagnostic compile')
        headers.append({'path': str(path), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)})
    failed = any(r['status'] == 'SDK_CALLER_TYPE_MISMATCH' for r in rows)
    report = {'status': 'MISMATCH' if failed else 'SELECTED_SDK_CALL_SHAPES_OBSERVED',
        'records': rows, 'headers': headers, 'environment': environment,
        'ir_sha256': hashlib.sha256(ir.read_bytes()).hexdigest(),
        'caller_selection_sha256': hashlib.sha256(caller_bytes).hexdigest(),
        'historical_full_abi_report_sha256': hashlib.sha256(abi_report.read_bytes()).hexdigest(),
        'historical_caller': {k: v for k, v in caller.items() if k not in ['declarations', 'calls']},
        'data_symbols': [line for line in text.splitlines() if 'metaClassE =' in line],
        'limitations': ['six SDK declarations do not establish provider return/semantic ABI',
            'historical diagnostic IR is not this-run rebuilt candidate',
            'one unobserved historical method stays unknown', 'pointee/class layout and vtable not accepted'],
        'full_abi': 'NOT_VERIFIED', 'kext_load': 'NO-GO'}
    write(args.out/'sdk-report.json', report)
    print(json.dumps({'status': report['status'], 'methods': [r['status'] for r in rows]}))
    return 2 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
