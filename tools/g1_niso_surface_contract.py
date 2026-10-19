#!/usr/bin/env python3
"""Actual OGKM NISO cleanup body, success-only CPU services. No memory deletion/GPU.

Checks parameter identity and repeat cleanup. Does not accept failure propagation,
shared layouts, kernel/runtime safety, or a complete Device destructor.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from g1_kms_close_contract import function

PREFIX=r'''
// NVIDIA original function copyright and MIT license follow separately.
#include <cstddef>
#include <cstdint>
#include <cstdio>
using NvBool = int;
using NvU32 = uint32_t;
using NV_STATUS = int;
enum { NV_FALSE = 0, NV_OK = 0, NVOS_STATUS_SUCCESS = 0, NVKMS_IOCTL_UNREGISTER_SURFACE = 1 };
struct NvKmsKapiNisoSurface { NvU32 hKmsHandle; bool mapped; NvU32 hRmHandle; void *pLinearAddress; };
struct NvKmsKapiDevice {
    NvKmsKapiNisoSurface semaphore, notifier;
    NvU32 hKmsDevice, hRmClient, hRmSubDevice, hRmDevice;
    void *pKmsOpen; int handleAllocator;
};
struct NvKmsUnregisterSurfaceParams { struct { NvU32 deviceHandle, surfaceHandle; } request; };
static int unregisters, unmaps, rm_frees, allocator_frees;
static NvBool nvkms_ioctl_from_kapi(void *, int, void *, size_t) { ++unregisters; return 1; }
static NV_STATUS nvRmApiUnmapMemory(NvU32,NvU32,NvU32,void *,int) { ++unmaps; return NV_OK; }
static NvU32 nvRmApiFree(NvU32,NvU32,NvU32) { ++rm_frees; return NVOS_STATUS_SUCCESS; }
static void nvFreeUnixRmHandle(int *,NvU32) { ++allocator_frees; }
static void nvKmsKapiLogDeviceDebug(NvKmsKapiDevice *,const char *,...) {}
'''
SUFFIX=r'''
int main() {
    NvKmsKapiDevice d = {};
    d.semaphore = {11,true,21,nullptr}; d.notifier = {12,true,22,nullptr};
    nvKmsKapiFreeNisoSurface(&d,&d.semaphore);
    bool identity = d.semaphore.hKmsHandle == 0 && !d.semaphore.mapped && d.semaphore.hRmHandle == 0 &&
                    d.notifier.hKmsHandle == 12 && d.notifier.mapped && d.notifier.hRmHandle == 22;
    std::printf("parameter_identity %s semaphore(kms=%u,mapped=%d) notifier(kms=%u,mapped=%d)\n",
        identity ? "PASS" : "FAIL",d.semaphore.hKmsHandle,d.semaphore.mapped,d.notifier.hKmsHandle,d.notifier.mapped);
    nvKmsKapiFreeNisoSurface(&d,&d.notifier);
    bool both = unregisters == 2 && unmaps == 2 && rm_frees == 2 && allocator_frees == 2;
    std::printf("sequential_cleanup %s unregister=%d unmap=%d rm_free=%d allocator_free=%d\n",
        both ? "PASS" : "FAIL",unregisters,unmaps,rm_frees,allocator_frees);
    const int before_unreg = unregisters, before_unmap = unmaps, before_rm = rm_frees, before_allocator = allocator_frees;
    nvKmsKapiFreeNisoSurface(&d,&d.semaphore);
    bool repeated = unregisters == before_unreg && unmaps == before_unmap &&
                    rm_frees == before_rm && allocator_frees == before_allocator;
    std::printf("repeat_cleanup %s unregister=%d unmap=%d\n",repeated ? "PASS" : "FAIL",unregisters,unmaps);
    return identity && both && repeated ? 0 : 1;
}
'''


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--cxx',default='g++')
    args=p.parse_args(); args.out.mkdir(parents=True,exist_ok=False)
    text=args.source.read_text(encoding='utf-8')
    name='void nvKmsKapiFreeNisoSurface(struct NvKmsKapiDevice *device,'
    body=function(text,name)
    source=args.out/'fixture.cpp'
    source.write_text(text[:text.index('*/')+2]+'\n'+PREFIX+'\n'+body+'\n'+SUFFIX,encoding='utf-8')
    binary=args.out/'fixture'
    command=[args.cxx,'-std=c++17','-Wall','-Wextra','-Werror',str(source),'-o',str(binary)]
    run=subprocess.run(command,capture_output=True,text=True,timeout=60)
    (args.out/'compile.txt').write_text(run.stdout+run.stderr,encoding='utf-8')
    report={'level':'ACTUAL_C_FUNCTION_CPU_SUCCESS_ONLY_NOT_FAILURE_PROPAGATION',
        'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest(),
        'fixture_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'compile_argv':command,'compile_exit':run.returncode,'run_exit':None,'status':'COMPILE_FAILED'}
    if run.returncode==0 and binary.is_file():
        run=subprocess.run([str(binary)],capture_output=True,text=True,timeout=10)
        output=run.stdout+run.stderr
        (args.out/'run.txt').write_text(output,encoding='utf-8')
        report.update(run_exit=run.returncode,output=output,status='PASS_CPU_ONLY' if run.returncode==0 else 'CONTRACT_FAIL')
    (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 0 if report['status']=='PASS_CPU_ONLY' else 1


if __name__=='__main__': raise SystemExit(main())
