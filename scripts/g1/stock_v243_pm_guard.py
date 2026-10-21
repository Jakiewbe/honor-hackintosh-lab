#!/usr/bin/env python3
"""One-source RM-busy guard, actual-function CPU contract and same-run relink.

The CPU harness mocks call boundaries only. It proves call ordering, not GPU
behaviour, PM mutual exclusion, XNU sleep cancellation or recovery.
"""
import argparse
import json
from pathlib import Path
import shutil
import sys

import stock_v243_kext_link as base
from stock_v243_internal_link import PASS as INTERNAL_PASS, patch_run, symbols
from stock_v243_package import binary_metadata

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT/'research/stock-v243-pm-20261021'
PASS = 'PASS_RM_BUSY_GUARD_CALL_CONTRACT_AND_NATIVE_LINK_NOT_SAFE_SLEEP'


def function(text):
    start = text.index('void NVRM::gpuSuspend()\n{')
    end = text.index('\n}\n', start)+3
    return text[start:end]


HARNESS = r'''
/* Extracted NullMoth function: Copyright (c) 2026 NullMoth Systems
 * (https://nullmothsystems.com), SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0.
 * Surrounding code is only a CPU call-boundary fixture, never a driver provider.
 */
#include <cstdint>
#include <cstdio>
#include <vector>
using SInt32 = int; using NV_STATUS = int;
static const int NV_OK=0, NV_PM_ACTION_STANDBY=1, kGpuPmRunning=0, kGpuPmSuspended=1;
static const void *kOSBooleanTrue=(void*)1;
static int busy; static std::vector<int> calls;
static uint64_t mach_absolute_time(){ return 1; }
static void absolutetime_to_nanoseconds(uint64_t, uint64_t *out){ *out=1; }
static bool OSCompareAndSwap(int before,int after, volatile int *v){ if(*v!=before)return false;*v=after;return true; }
static void nvkms_xnu_suspend(int){calls.push_back(2);}
static int nv_xnu_pm_close(uint32_t){calls.push_back(3);return busy;}
static int rm_stop_user_channels(void*,void*){calls.push_back(4);return 0;}
static int rm_power_management(void*,void*,int){calls.push_back(6);return 0;}
#define LOG(...) ((void)0)
class NVRM {
public:
    unsigned fPmCycles=0; volatile int fGpuPm=kGpuPmRunning;
    struct {int gpu_id=1;} fNv;
    struct IRQ{void disable(){calls.push_back(7);}} irq;
    IRQ *fIntSrc=&irq;
    bool violation=false;
    void setProperty(const char*, const char*){}
    void setProperty(const char*, const void*){violation=true; calls.push_back(8);}
    void notifyFramebuffers(uintptr_t state){calls.push_back(state==0?1:99);}
    void pciSaveForSleep(){calls.push_back(5);}
    void gpuSuspend();
};
'''


def harness(body):
    return HARNESS+'\n'+body+r'''
int main(){
    int passed=0, total=0;
    for(int held : {0,1,2,17}){
        calls.clear();busy=held;NVRM rm;rm.gpuSuspend();
        const std::vector<int> expected=held?std::vector<int>{1,2,3,8}:std::vector<int>{1,2,3,4,5,6,7};
        bool result=calls==expected;
        passed+=result; ++total;
        std::printf("busy=%d ordered-effects=%s\n",held,result?"PASS":"FAIL");
        result=rm.fGpuPm==kGpuPmSuspended && rm.fPmCycles==1 && rm.violation==(held!=0);
        passed+=result; ++total;
        std::printf("busy=%d state-and-marker=%s\n",held,result?"PASS":"FAIL");
    }
    std::printf("%d/%d CPU call contracts; no device; no sleep-veto proof\n",passed,total);
    return passed==total?0:1;
}
'''


def accept_cpu(role, rc, text):
    total=2 if role=='baseline' else 8
    expected_exit=1 if role=='baseline' else 0
    rows=[line for line in text.splitlines() if line.startswith('busy=')]
    expected=[]
    for busy in (0,1,2,17):
        status='FAIL' if role=='baseline' and busy else 'PASS'
        expected.extend([f'busy={busy} ordered-effects={status}', f'busy={busy} state-and-marker={status}'])
    summary=f'{total}/8 CPU call contracts; no device; no sleep-veto proof'
    if rc!=expected_exit or rows!=expected or summary not in text or 'Sanitizer' in text:
        raise ValueError('CPU contract observations differ: '+role)


def prepare(tree, dest, logs):
    lock = json.loads((ASSETS/'lock.json').read_text())
    patch = ASSETS/'rm-busy-guard.patch'
    source = lock['source']
    if base.digest(patch) != lock['patch_sha256'] or base.digest(tree/source) != lock['before_sha256']:
        raise ValueError('PM guard input identity differs')
    shutil.copytree(tree, dest)
    snapshot = {p.relative_to(dest).as_posix():base.digest(p) for p in dest.rglob('*') if p.is_file()}
    for flags, phase in ((['--check'],'check'), ([], 'forward'), (['-R'], 'reverse'), ([], 'replay')):
        base.checked_run(['git','-c','core.autocrlf=false','apply','--no-index','--whitespace=error-all',
            *flags,patch], dest, logs/('patch-'+phase+'.txt'), runner=patch_run)
        expected = lock['before_sha256'] if phase in ('check','reverse') else lock['after_sha256']
        if base.digest(dest/source) != expected:
            raise ValueError('PM guard patch did not produce locked bytes: '+phase)
    current = {p.relative_to(dest).as_posix():base.digest(p) for p in dest.rglob('*') if p.is_file()}
    if set(current) != set(snapshot) or {p for p in current if current[p]!=snapshot[p]} != {source}:
        raise ValueError('PM guard changed files outside its one-source contract')
    base.save(logs/'guard-inputs.json', dict(lock=lock, baseline_inputs=snapshot,
        candidate_source_sha256=base.digest(dest/source), patch_forward_reverse_replay=True))
    return lock


def cpu_contract(tree, candidate, out, compiler):
    results = {}
    products=out.parent/(out.name+'-cpu-products');products.mkdir(exist_ok=False)
    for role, source in (('baseline',tree),('candidate',candidate)):
        text = (source/'kexts/NVRM/NVRM.cpp').read_text()
        src=out/(role+'-cpu.cpp'); obj=products/(role+'-cpu')
        src.write_text(harness(function(text)), encoding='utf-8', newline='\n')
        obj.unlink(missing_ok=True)
        base.checked_run([*compiler,'-std=c++17','-O1','-g','-fsanitize=address,undefined',src,'-o',obj],out,out/(role+'-cpu-compile.txt'))
        rc=base.run([obj],out,out/(role+'-cpu-result.txt'))
        accept_cpu(role,rc,(out/(role+'-cpu-result.txt')).read_text())
        results[role]=dict(exit=rc, generated_sha256=base.digest(src),
            source_sha256=base.digest(source/'kexts/NVRM/NVRM.cpp'))
    # Real compiler failure: clear an old output and never run it.
    src=out/'invalid-cpu.cpp'; obj=products/'invalid-cpu'
    src.write_text('DELIBERATELY_INVALID_SOURCE !!!\n'); obj.write_bytes(b'STALE')
    obj.unlink()
    rc=base.run([*compiler,'-std=c++17',src,'-o',obj],out,out/'invalid-cpu-compile.txt')
    if not rc or obj.exists():
        raise ValueError('compiler failure control did not fail closed')
    results['invalid']=dict(exit=rc,binary_exists=False,executed=False)
    base.save(out/'cpu-contract.json',results)
    return results


def run(args, report):
    baseline=json.loads((args.internal_text/'report.json').read_text())
    if baseline['status']!=INTERNAL_PASS:
        raise ValueError('same-run internal link unavailable')
    tree=args.work/'nm-candidate'; dest=args.work/'nm-pm-guard'
    report['stage']='source-overlay'; lock=prepare(tree,dest,args.out)
    report['stage']='cpu-contract'
    report['cpu']=cpu_contract(tree,dest,args.out,['xcrun','clang++'])
    original=next(r for r in baseline['tu_objects'] if r['source']==lock['source'])
    if base.digest(Path(original['path']))!=original['sha256']:
        raise ValueError('same-run original object changed')
    argv=json.loads((args.internal_text/'tu-NVRM.cpp.txt').read_text().splitlines()[0].removeprefix('ARGV='))
    argv=[v.replace(str(tree),str(dest)) for v in argv[:argv.index('-MD')]]
    source=dest/lock['source']; obj=args.work/'NVRM-pm-guard.o'
    pre,post=args.out/'native-pre.d',args.out/'native-post.d'
    report['stage']='native-object'
    base.checked_run([*argv,'-M','-MT','bound','-MF',pre,source],dest,args.out/'native-deps.txt')
    before=base.dependencies(pre,dest)
    report['object']=base.compile_checked([*argv,'-MD','-MT','bound','-MF',post,'-c',source,'-o',obj],dest,obj,args.out/'native-compile.txt')
    if before!=base.dependencies(post,dest):
        raise ValueError('native PM guard inputs changed')
    report['stage']='same-run-link'
    argv=json.loads((args.internal_text/'internal-link-inputs.json').read_text())['argv']
    if argv.count(original['path'])!=1:
        raise ValueError('original NVRM object must occur exactly once')
    known={r['path']:r['sha256'] for r in baseline['tu_objects']+baseline['rm_objects']+baseline['rm_replacements']}
    known[str(args.work/'nvlink-darwin.o')]=baseline['nvlink_object']['sha256']
    known[str(args.work/'libnvkms-paired.a')]=baseline['paired_archive']['sha256']
    consumed={v:known[v] for v in argv if Path(v).suffix in ('.o','.a')}
    if len(consumed)!=1069 or any(base.digest(p)!=sha for p,sha in consumed.items()):
        raise ValueError('same-run linked object/archive inventory differs')
    output=args.work/'NVRM-pm-guard'
    argv=[str(obj) if v==original['path'] else v for v in argv]; argv[-1]=str(output)
    base.save(args.out/'link-inputs.json',dict(argv=argv,replaced_object=original,
        unchanged_inputs={p:sha for p,sha in consumed.items() if p!=original['path']}))
    report['link']=base.link_checked(argv,dest,output,args.out/'ld.txt')
    observed=symbols(output,args.out,'guard')
    if observed['undefined']!=set(baseline['final_imports']):
        raise ValueError('PM guard changed external import inventory')
    info=__import__('plistlib').loads((dest/'kexts/NVRM/Info.plist').read_bytes())
    report['metadata']=binary_metadata(output,info)
    if any(base.digest(p)!=sha for p,sha in before.items()):
        raise ValueError('native PM inputs changed after link')
    if any(base.digest(p)!=sha for p,sha in consumed.items()):
        raise ValueError('same-run linked input changed after guard link')
    if base.digest(dest/lock['source'])!=lock['after_sha256'] or base.digest(tree/lock['source'])!=lock['before_sha256']:
        raise ValueError('frozen baseline or guard source changed')
    report.update(status=PASS,stage='complete',lock=lock,
        scope='ONLY_RM_BUSY_PREVENTS_CHANNEL_STOP_AND_STANDBY',sleep_safety='UNVERIFIED',
        pm_mutual_exclusion='UNVERIFIED',sleep_veto=False,wake_recovery='UNVERIFIED',kext_load='NO_GO',gpu='NOT_RUN')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for k in ('internal-text','work','out'):p.add_argument('--'+k,required=True,type=Path)
    args=p.parse_args();args.out.mkdir(parents=True,exist_ok=False)
    report=dict(status='FAILED',stage='preflight',kext_load='NO_GO',gpu='NOT_RUN')
    try:run(args,report)
    except Exception as error:
        report['error']=str(error)
        print('::error::PM_GUARD_FAILED '+report['stage']+' :: '+str(error)[:300])
    finally:base.save(args.out/'pm-report.json',report)
    print(report['status'],report['stage'],report.get('error',''))
    return 0 if report['status']==PASS else 2


if __name__=='__main__':raise SystemExit(main())
