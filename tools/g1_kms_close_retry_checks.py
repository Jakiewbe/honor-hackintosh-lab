#!/usr/bin/env python3
"""Negative controls and integration structure checks for R32. CPU/source only."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
from g1_kms_close_contract import function


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--cxx', default='g++')
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    tool = Path(__file__).with_name('g1_kms_close_retry_contract.py')
    unit = args.candidate/'kexts/NVRM'
    os_text = (unit/'os-nvkms-xnu.cpp').read_text(encoding='utf-8')
    pm = (unit/'NVRM.cpp').read_text(encoding='utf-8')
    resume = function(pm, 'void NVRM::gpuResume()')
    load = function(os_text, 'NvBool nvkms_xnu_load(void)')
    commit = function(os_text, 'NvBool nvkms_xnu_suspend_commit(NvU32 gpuId, uint32_t seq, uint32_t waitMs)')
    structural = {
        'reap_after_rm_open': resume.count('nvkms_xnu_reap_closes();') == 1 and
            resume.index('nv_xnu_pm_open();') < resume.index('nvkms_xnu_reap_closes();'),
        'worker_allocated_before_module_load': load.index('gKmsCloseWorker = thread_call_allocate_with_options(') <
            load.index('NvBool ok = nvKmsModuleLoad();'),
        'allocation_failure_refuses_load': 'if (!gKmsCloseWorker) return NV_FALSE;' in load,
        'commit_closes_retry_before_suspend': commit.index('gKmsCloseRetryReady = false;') < commit.index('nvKmsSuspend(gpuId);'),
    }
    cases = [('compile-failure', None, None, '--negative-compile')]
    cases += [
        ('missing-owner', 'if (!kms_deferred_try_free_impl(popen, NULL)) kms_close_remember_locked(popen);',
         '(void)kms_deferred_try_free_impl(popen, NULL);', None),
        ('gate-bypass', 'if (gKmsCloseRetryReady && !gKmsSuspendPending && gKmsPmState == kKmsPmRunning)',
         'if (!gKmsSuspendPending && gKmsPmState == kKmsPmRunning)', None),
        ('counter-drift', 'if (popen->deferredCounted && gKmsCloseDeferred) gKmsCloseDeferred--;',
         'if (gKmsCloseDeferred) gKmsCloseDeferred--;', None),
    ]
    records = []
    for name, old, new, flag in cases:
        candidate = args.out/(name+'-candidate')
        target = candidate/'kexts/NVRM'
        target.mkdir(parents=True)
        for filename in ('os-nvkms-xnu.cpp','NVRM.cpp','kms_deferred.cpp','kms_deferred.h'):
            shutil.copyfile(unit/filename, target/filename)
        if old:
            if os_text.count(old) != 1: raise ValueError('mutation context differs: '+name)
            (target/'os-nvkms-xnu.cpp').write_text(os_text.replace(old,new), encoding='utf-8')
        out = args.out/name
        command = [sys.executable,str(tool),'--candidate',str(candidate),'--out',str(out),'--cxx',args.cxx]
        if flag: command.append(flag)
        run = subprocess.run(command,capture_output=True,text=True,timeout=60)
        (args.out/(name+'-console.txt')).write_text(run.stdout+run.stderr,encoding='utf-8')
        result = json.loads((out/'report.json').read_text(encoding='utf-8'))
        if flag:
            rejected = run.returncode != 0 and result['compile_exit'] != 0 and not result['binary_exists'] and not result['scenarios']
        else:
            rejected = run.returncode != 0 and result['compile_exit'] == 0 and any(r['exit'] != 0 for r in result['scenarios'])
        records.append({'case':name,'tool_exit':run.returncode,'compile_exit':result['compile_exit'],
            'failed_scenarios':[r['scenario'] for r in result['scenarios'] if r['exit'] != 0],
            'control_rejected':rejected})
    report = {'level':'CPU_MUTATION_AND_SOURCE_STRUCTURE_NOT_KERNEL', 'structural':structural,'controls':records,
        'source_sha256':{n:hashlib.sha256((unit/n).read_bytes()).hexdigest() for n in ('os-nvkms-xnu.cpp','NVRM.cpp')},
        'status':'PASS' if all(structural.values()) and all(r['control_rejected'] for r in records) else 'FAIL'}
    (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 0 if report['status']=='PASS' else 1


if __name__=='__main__': raise SystemExit(main())
