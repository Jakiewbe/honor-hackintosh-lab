#!/usr/bin/env python3
"""CPU-only contract test of the complete, extracted performTransaction function.

No IOKit/GPU execution. Each case is a fresh process (including the static symbol).
The platform stubs model responses; the transaction and copy helper are real input.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

REL = Path('kexts/NVRM/accel/nvrm-accel.cpp')
PREFIX = r'''
// CPU harness for a function extracted from the input NullMoth driver.
// Extracted function: Copyright (c) 2026 NullMoth Systems.
// Extracted function SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "nvrm_vram_abi.h"
#include "frame_copy_checked.h"
using IOReturn = uint32_t;
using SInt64 = int64_t;
using SInt32 = int32_t;
// Distinct model statuses: tests establish propagation, not Darwin ABI values.
constexpr IOReturn kIOReturnSuccess=0, kIOReturnUnsupported=0xe00002c7,
 kIOReturnNoMemory=0xe00002bd, kIOReturnBadArgument=0xe00002c2,
 kIOReturnNotReady=0xe00002d8, kIOReturnNotAttached=0xe00002d9,
 kIOReturnOverrun=0xe00002e8, kIOReturnVMError=0xe00002d0;
static bool symbolFails=false, waitReady=true, copyReady=true;
static IOReturn ownerStatus=0, scanoutStatus=0;
static int peerCalls=0, fallbackCalls=0, waitCalls=0;
static unsigned pixels[4]={0x12345678,0xaabbccdd,0x11223344,0xff8899aa};
static unsigned dest[4]={0xdeadbeef,0xdeadbeef,0xdeadbeef,0xdeadbeef};
static NVRMVramRequest scanout;
struct Meta { const char *getClassName() { return "fixture"; } };
struct OSObject { virtual ~OSObject()=default; Meta *getMetaClass() { static Meta m; return &m; } };
struct IOMemoryDescriptor {};
struct IOSurface {
 unsigned format=0x42475241u;
 unsigned getSurfaceID() { return 1; }
 unsigned getWidth() { return 2; }
 unsigned getHeight() { return 2; }
 unsigned getBytesPerRow() { return 8; }
 unsigned getPixelFormat() { return format; }
 IOMemoryDescriptor *getMemoryDescriptor() { static IOMemoryDescriptor m; return &m; }
};
struct NVVidMemory { unsigned long long fBytes=0; void *fKva=nullptr; int fScanout=0; };
struct NVResource : OSObject {};
static NVVidMemory *nvres_vidmem(NVResource *) { return nullptr; }
#define OSDynamicCast(type, value) dynamic_cast<type *>(value)
struct OSSymbol {
 static const OSSymbol *withCStringNoCopy(const char *) {
  static OSSymbol s; return symbolFails ? nullptr : &s;
 }
};
struct IOService {
 IOReturn callPlatformFunction(const OSSymbol *, bool, void *p, void *, void *, void *) {
  ++peerCalls;
  const auto &q=*static_cast<NVRMVramCopyRequest *>(p);
  if (q.version!=NVRM_VRAM_ABI_VERSION || q.src!=pixels || q.srcPitch!=8 || q.width!=2 || q.height!=2)
   std::abort();
  return ownerStatus;
 }
};
struct NVDisplayPipe;
struct NVAccel {
 static NVAccel *gAccel;
 IOService fb;
 IOService *pipeFramebuffer(NVDisplayPipe *, unsigned *head) { *head=0; return &fb; }
 IOReturn askFramebufferForScanout(NVRMVramRequest *q, IOService *) { *q=scanout; return scanoutStatus; }
};
NVAccel *NVAccel::gAccel=nullptr;
struct IOAccelDisplayPipeTransaction2 {
 IOSurface surface;
 IOSurface *getPlaneIOSurface(int,int) { return &surface; }
 OSObject *getPlaneResource(int,int) { return nullptr; }
};
struct NVDisplayPipe { IOReturn performTransaction(IOAccelDisplayPipeTransaction2 *); };
static bool nvAccelIopFlip(IOService *,unsigned,IOSurface *,void *) { return false; }
static bool nvSurfWaitReady(unsigned) { ++waitCalls; return waitReady; }
static bool nvAccelSurfCopyReady(IOSurface *,unsigned) { return copyReady; }
static void *iopMapSurface(unsigned,IOMemoryDescriptor *,unsigned long long) { return pixels; }
static void nvAccelIopHome(IOService *,unsigned) { ++fallbackCalls; }
static SInt64 OSAddAtomic64(SInt64 n,SInt64 *p) { const auto old=*p; *p+=n; return old; }
static void OSIncrementAtomic(SInt32 *p) { ++*p; }
static int gNvIop=1;
static SInt64 gCntIopOk=0,gCntIopFail=0,gCntIopEmpty=0,gCntIopSrcRes=0,
 gCntIopSrcSurf=0,gCntIopBlank=0,gCntIopOkHead[5]={};
#define ALOG(...) ((void)0)
#define NVIOPLOG(...) ((void)0)
'''
SUFFIX = r'''
static int failed=0;
static void check(bool condition,const char *message) {
 if (!condition) { std::fprintf(stderr,"FAIL: %s\n",message); ++failed; }
}
int main(int argc,char **argv) {
 if(argc!=2) return 2;
 const int c=std::atoi(argv[1]);
 NVAccel a; NVAccel::gAccel=&a; NVDisplayPipe pipe; IOAccelDisplayPipeTransaction2 txn;
 scanout.version=NVRM_VRAM_ABI_VERSION; scanout.width=2; scanout.height=2;
 scanout.kva=dest; scanout.pitch=8; scanout.actualSize=sizeof(dest);
 IOReturn expected=kIOReturnSuccess;
 bool expectFallback=false; int expectPeer=1, expectOk=1, expectFail=0;
 if(c==0) { symbolFails=true; expected=kIOReturnNoMemory; expectPeer=0; expectOk=0; expectFail=1; }
 if(c==1) scanout.kva=nullptr;
 if(c==2) { scanout.kva=reinterpret_cast<void *>(uintptr_t(4)); scanout.pitch=0; }
 if(c==3) { ownerStatus=kIOReturnUnsupported; expectFallback=true; }
 if(c==4) { ownerStatus=kIOReturnUnsupported; scanout.kva=nullptr; expected=kIOReturnNotReady; expectOk=0; expectFail=1; }
 if(c==5) { ownerStatus=kIOReturnUnsupported; scanout.actualSize=4; expected=kIOReturnOverrun; expectFallback=true; expectOk=0; expectFail=1; }
 if(c>=6 && c<=10) {
  const IOReturn errors[]={kIOReturnNotReady,kIOReturnBadArgument,kIOReturnNoMemory,0xe00002d6u,0x81234567u};
  ownerStatus=errors[c-6]; expected=ownerStatus; expectOk=0; expectFail=1;
 }
 if(c==11) { ownerStatus=kIOReturnNotReady; scanout.kva=nullptr; expected=ownerStatus; expectOk=0; expectFail=1; }
 if(c==12) { waitReady=false; expected=kIOReturnNotReady; expectPeer=0; expectOk=0; expectFail=1; }
 if(c==13) { copyReady=false; expected=kIOReturnNotReady; expectPeer=0; expectOk=0; expectFail=1; }
 if(c==14) { txn.surface.format=0; expected=kIOReturnUnsupported; expectPeer=0; expectOk=0; expectFail=1; }
 if(c<0 || c>14) return 2;
 const IOReturn actual=pipe.performTransaction(&txn);
 check(actual==expected,"exact transaction return status");
 check(peerCalls==expectPeer,"peer invocation count");
 check(fallbackCalls==(expectFallback?1:0),"fallback entry count");
 check(gCntIopOk==expectOk && gCntIopOkHead[0]==expectOk,"success and per-head counters");
 check(gCntIopFail==expectFail,"failure counter");
 check(gCntIopSrcSurf==expectOk && gCntIopSrcRes==0,"source counters");
 check(waitCalls==1,"source completion check preserved");
 const bool copied=c==3;
 for(unsigned i=0;i<4;++i) check(dest[i]==(copied?pixels[i]:0xdeadbeefu),"fallback pixels or untouched destination");
 if(!failed) std::printf("PASS case %d (CPU contract only)\n",c);
 return failed?1:0;
}
'''


def fixture(tree):
    text = (tree / REL).read_text(encoding='utf-8')
    start = text.index('IOReturn NVDisplayPipe::performTransaction(')
    end = text.index('\nstatic int nvacceliop_sysctl', start)
    body = text[start:end]
    macro = re.search(r'^#define NVIOP_FAIL\(.*$', text, re.M).group(0)
    if body.count('{') != body.count('}'):
        raise ValueError('incomplete function extraction')
    return PREFIX + macro + '\n' + body + SUFFIX, body


def execute(argv, log, env=None):
    with log.open('w', encoding='utf-8') as stream:
        stream.write('ARGV=' + json.dumps(argv) + '\n')
        stream.flush()
        proc = subprocess.run(argv, stdout=stream, stderr=subprocess.STDOUT, env=env)
        stream.write('\nEXIT=' + str(proc.returncode) + '\n')
    return proc.returncode


def run(args):
    out = args.out.resolve()
    # A new directory is mandatory: no old executable can be inherited.
    out.mkdir(parents=True, exist_ok=False)
    compiler = shutil.which(args.cxx)
    if not compiler:
        raise SystemExit('compiler unavailable')
    leak_check = '0' if sys.platform == 'darwin' else '1'
    env = dict(os.environ, ASAN_OPTIONS=f'detect_leaks={leak_check}:abort_on_error=1', UBSAN_OPTIONS='halt_on_error=1')
    report = {'level':'CPU-EXTRACTED-FUNCTION-CONTRACT', 'compiler':compiler, 'profiles':{},
              'device_access':False, 'gpu_runtime':'NOT_RUN'}
    execute([compiler, '--version'], out / 'compiler.txt')
    for label, tree in [('baseline',args.baseline.resolve()), ('candidate',args.candidate.resolve())]:
        generated, body = fixture(tree)
        source = out / (label + '.cpp')
        source.write_text(generated, encoding='utf-8')
        binary = out / (label + '.bin')
        binary.unlink(missing_ok=True)
        headers = tree / 'kexts/NVRM'
        platform_flags = ['-fno-pie','-no-pie'] if sys.platform.startswith('linux') else []
        command = [compiler,'-std=c++17','-O1','-g','-fsanitize=address,undefined',
                   '-fno-omit-frame-pointer',*platform_flags, '-I'+str(headers),
                   '-I'+str(headers/'accel'),str(source),'-o',str(binary)]
        rc = execute(command, out/(label+'-compile.txt'))
        entry = {'source_sha256':hashlib.sha256((tree/REL).read_bytes()).hexdigest(),
                 'function_sha256':hashlib.sha256(body.encode()).hexdigest(),
                 'fixture_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                 'header_sha256':{str(q.relative_to(tree)):hashlib.sha256(q.read_bytes()).hexdigest()
                     for q in [headers/'nvrm_vram_abi.h',headers/'accel/frame_copy_checked.h']},
                 'compile_exit':rc, 'cases':[]}
        report['profiles'][label] = entry
        if rc or not binary.is_file():
            binary.unlink(missing_ok=True)
            (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
            raise SystemExit(f'{label}: compile failed; no tests executed')
        for case in range(15):
            rc = execute([str(binary),str(case)], out/f'{label}-case-{case}.txt',env)
            entry['cases'].append({'case':case,'exit':rc})
        # Text-only evidence: executables must never be uploaded.
        binary.unlink()
    # Compile failure negative control uses the same flags and an invalid candidate.
    source.write_text(generated+'\n#error R28_COMPILE_FAILURE_CONTROL\n',encoding='utf-8')
    badrc = execute(command,out/'negative-compile.txt')
    negative = {'compile_exit':badrc,'binary_exists':binary.exists(),'executed':False}
    binary.unlink(missing_ok=True)
    report['negative_control'] = negative
    failed = [x['case'] for x in report['profiles']['baseline']['cases'] if x['exit']]
    candidate_ok = all(x['exit']==0 for x in report['profiles']['candidate']['cases'])
    # Exact regression set: allocation plus five execution failures, with valid kva.
    report['expected_baseline_failures'] = [0,6,7,8,9,10]
    report['baseline_failures'] = failed
    report['result'] = 'PASS' if candidate_ok and failed==[0,6,7,8,9,10] and badrc!=0 and not negative['binary_exists'] else 'FAIL'
    source.write_text(generated,encoding='utf-8')
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'result':report['result'],'candidate_passed':sum(x['exit']==0 for x in report['profiles']['candidate']['cases']),
                      'baseline_failures':failed,'negative_control':negative}))
    return 0 if report['result']=='PASS' else 1


def main():
    p = argparse.ArgumentParser(description=__doc__)
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument('--baseline', type=Path)
    group.add_argument('--patch', type=Path, help='Reverse this patch in a temporary source copy to obtain the baseline')
    p.add_argument('--candidate', required=True, type=Path)
    p.add_argument('--out', required=True, type=Path)
    p.add_argument('--cxx', default='c++')
    args = p.parse_args()
    with tempfile.TemporaryDirectory(prefix='r28-owner-copy-') as folder:
        if args.patch:
            args.baseline = Path(folder)
            shutil.copytree(args.candidate.resolve()/'kexts/NVRM', args.baseline/'kexts/NVRM')
            patch = args.patch.resolve()
            for options in [['--check'], []]:
                subprocess.run(['git','-c','core.autocrlf=false','apply','--reverse',*options,
                                '--whitespace=error-all',str(patch)], cwd=args.baseline,check=True)
        return run(args)


if __name__=='__main__':
    raise SystemExit(main())
