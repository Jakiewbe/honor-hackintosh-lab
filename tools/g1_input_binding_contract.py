#!/usr/bin/env python3
"""Real CPU compiler reproduction of header-only ABI drift; no driver/device."""
import argparse
import json
from pathlib import Path

from g1_compile_inputs import bound_compile, verify_snapshot, sha
from g1_full_abi import function_record
from g1_full_build import run


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    report = {'level':'CPU_COMPILER_FIXTURE_NOT_DRIVER', 'result':'INCOMPLETE',
        'gpu_execution':'NOT_RUN','kext_load':'NO-GO'}
    try:
        source, middle, header, obj = [out/x for x in ['caller.c','middle.h','indirect.h','caller.o']]
        header.write_text('long long rm_select(int);\n', encoding='utf-8')
        middle.write_text('#include "indirect.h"\n', encoding='utf-8')
        source.write_text('#include "middle.h"\nlong long caller(void) { return rm_select(7); }\n', encoding='utf-8')
        argv = ['xcrun','clang','-O2','-c',str(source),'-o',str(obj)]
        rc, descriptor, actual = bound_compile(argv,out,out/'original-compile.txt',out/'inputs',run)
        if rc: raise ValueError('original fixture compilation failed')
        record = verify_snapshot(descriptor,out/'inputs',source,obj,sha(obj),actual)
        report['captured_input_files'] = len(record['inputs'])
        source_hash, object_hash = sha(source), sha(obj)
        ir = out/'original.ll'
        if run(['xcrun','clang','-O2','-S','-emit-llvm',str(source),'-o',str(ir)],out,out/'original-ir.txt'):
            raise ValueError('original fixture IR failed')
        report['original_caller_abi'] = function_record(ir.read_text(),'rm_select')['abi']
        header.write_text('int rm_select(int);\n', encoding='utf-8')
        wrapper = out/'wrapper.c'
        wrapper.write_text('#include "caller.c"\n', encoding='utf-8')
        ir = out/'changed-wrapper.ll'
        if run(['xcrun','clang','-O2','-S','-emit-llvm',str(wrapper),'-o',str(ir)],out,out/'changed-wrapper-ir.txt'):
            raise ValueError('changed fixture IR failed')
        report['changed_wrapper_abi'] = function_record(ir.read_text(),'rm_select')['abi']
        provider = out/'provider.c'
        provider.write_text('int rm_select(int x) { return x; }\n', encoding='utf-8')
        ir = out/'provider.ll'
        if run(['xcrun','clang','-O2','-S','-emit-llvm',str(provider),'-o',str(ir)],out,out/'provider-ir.txt'):
            raise ValueError('provider fixture IR failed')
        report['provider_abi'] = function_record(ir.read_text(),'rm_select',require_definition=True)['abi']
        assert report['original_caller_abi']['return_type'] == 'i64'
        assert report['changed_wrapper_abi']['return_type'] == report['provider_abi']['return_type'] == 'i32'
        assert (sha(source),sha(obj)) == (source_hash,object_hash)
        report['source_object_unchanged'] = True
        try:
            verify_snapshot(descriptor,out/'inputs',source,obj,object_hash,actual)
        except ValueError as error:
            if 'transitive input changed' not in str(error): raise
            report['header_only_drift_rejected'] = str(error)
        else: raise ValueError('header-only ABI drift was accepted')
        # Separate fresh source: preprocessing succeeds, actual compilation fails.
        broken, broken_obj = out/'broken.c', out/'broken.o'
        broken.write_text('this is deliberately invalid C syntax;\n', encoding='utf-8')
        rc, rejected, _ = bound_compile(['xcrun','clang','-c',str(broken),'-o',str(broken_obj)],
            out,out/'negative-compile.txt',out/'negative-inputs',run)
        assert rc != 0 and rejected is None and not broken_obj.exists()
        assert not (out/'negative-inputs/broken.json').exists()
        report['negative_compile'] = {'exit':rc,'object_exists':False,'snapshot_exists':False,'run':'NOT_RUN'}
        report['result'] = 'CPU_INPUT_BINDING_CONTRACT_PASS'
    except Exception as error:
        report['error'] = type(error).__name__+': '+str(error)
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 0 if report['result'] == 'CPU_INPUT_BINDING_CONTRACT_PASS' else 2


if __name__ == '__main__': raise SystemExit(main())
