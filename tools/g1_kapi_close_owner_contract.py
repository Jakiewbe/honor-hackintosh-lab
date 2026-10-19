#!/usr/bin/env python3
"""Expose the OPEN Device-owner boundary using real OGKM FreeDevice/event bodies.

All allocation/free and OS services are injected; memory is never deleted. The
event ioctl boundary injects a concurrent teardown after an event was obtained.
Reports either early Device release (R32a) or the unbounded normal join (R32b).
The backend-refused scenario separately exposes known P0-4: Device destruction
continues after KMS refusal. All are contract FAIL and return 1, not observed
kernel UAF/deadlock.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from g1_kms_close_contract import function
from g1_kms_close_retry_contract import PREFIX, NAMES

TYPES = r'''
struct nvkms_per_open;
struct NvKmsKapiEvent;
struct NvKmsKapiDevice {
    int semaphore, notifier, hKmsDevice, hKmsDisp, gpuId;
    void *pSema, *privateData;
    nvkms_per_open *pKmsOpen;
    void (*eventCallback)(NvKmsKapiEvent *);
};
struct NvKmsFreeDeviceParams { struct { int deviceHandle; } request; };
struct NvKmsGetNextEventParams {
    struct { bool valid; struct { int eventType; struct {
        struct { int dpyId; } dpyChanged, dynamicDpyConnected;
        struct { int head, layer; } flipOccurred;
    } u; } event; } reply;
};
struct NvKmsKapiEvent {
    int type; NvKmsKapiDevice *device; void *privateData;
    struct { struct { int display; } displayChanged, dynamicDisplayConnected;
             struct { int head, layer; } flipOccurred; } u;
};
enum { NVKMS_IOCTL_FREE_DEVICE, NVKMS_IOCTL_GET_NEXT_EVENT,
       NVKMS_EVENT_TYPE_DPY_CHANGED, NVKMS_EVENT_TYPE_DYNAMIC_DPY_CONNECTED,
       NVKMS_EVENT_TYPE_FLIP_OCCURRED };
static int device_frees, rm_frees, downstream_events, niso_frees;
static int nvkms_ioctl_from_kapi(nvkms_per_open *, int, void *, size_t);
static void nvkms_close_from_kapi(nvkms_per_open *);
static void nvKmsKapiFreeNisoSurface(NvKmsKapiDevice *, int *) { ++niso_frees; }
static void RmFreeDevice(NvKmsKapiDevice *) { ++rm_frees; }
static void nvkms_close_gpu(int, int) {}
static void nvkms_sema_free(void *) {}
static void nvKmsKapiFree(NvKmsKapiDevice *) { ++device_frees; } // Counts, no deletion.
static int nvDpyIdToNvU32(int x) { return x; }
static void nvKmsKapiLogDeviceDebug(NvKmsKapiDevice *, const char *) {}
static void nvAssert(bool ok) { if (!ok) throw std::runtime_error("OGKM assertion"); }
'''

TAIL = r'''
static NvKmsKapiDevice device;
static nvkms_per_open node;
static bool refusal_mode, teardown_refused;
static void nvkms_close_from_kapi(nvkms_per_open *p) { kms_close_common(p); }
static int nvkms_ioctl_from_kapi(nvkms_per_open *, int cmd, void *params, size_t) {
    if (cmd == NVKMS_IOCTL_FREE_DEVICE) {
        if (refusal_mode) { teardown_refused = true; return 0; }
        return 1;
    }
    require(cmd == NVKMS_IOCTL_GET_NEXT_EVENT, "unexpected ioctl");
    // The event was already fetched. Teardown races before the handler consumes it.
    FreeDevice(&device);
    auto *event = static_cast<NvKmsGetNextEventParams *>(params);
    event->reply.valid = true;
    event->reply.event.eventType = NVKMS_EVENT_TYPE_DPY_CHANGED;
    return 1;
}
static void checked_event(NvKmsKapiEvent *) {
    ++downstream_events;
    require(device_frees == 0, "DEVICE_FREED_BEFORE_ACTIVE_EVENT_FINISHED");
}
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int data;
    gKmsCloseWorker = &worker_id;
    node.data = &data; node.eventCall = &data; node.eventBusy = true; node.device = &device;
    device.pKmsOpen = &node; device.eventCallback = checked_event;
    (void)kms_close_retry_fire;
    try {
        if (std::strcmp(argv[1], "backend-refused") == 0) {
            refusal_mode = true; gKmsPmState = kKmsPmLost;
            node.eventBusy = false; device.hKmsDevice = 1;
            FreeDevice(&device);
            require(!(teardown_refused && (rm_frees || device_frees)), "DEVICE_DESTROYED_AFTER_KMS_REFUSAL");
        } else {
            require(std::strcmp(argv[1], "active-event") == 0, "unknown scenario");
            kms_kapi_event_fire(&node, nullptr);
        }
        std::printf("UNEXPECTED_PASS\n");
        return 0;
    } catch (const std::exception &error) {
        std::printf("CONTRACT_FAIL %s backend_close=%d wrapper_free=%d queued=%u device_free=%d rm_free=%d events=%d sleeps=%d\n",
            error.what(), backend_closes, wrapper_frees, kms_deferred_count(), device_frees,
            rm_frees, downstream_events, sleeps);
        return 1;
    }
}
'''


def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate',type=Path,required=True)
    p.add_argument('--ogkm-kapi',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--cxx',default='g++')
    p.add_argument('--scenario',choices=('active-event','backend-refused'),default='active-event')
    args = p.parse_args()
    args.out.mkdir(parents=True,exist_ok=False)
    kapi_sha=sha(args.ogkm_kapi)
    accepted={
        '66437bc38d96d3b4f15546c3e6f7a8c0caccc158b35893c2406f80f2e6e8816b':'FIXED_ORIGINAL',
        '7e5492e0a0961e45ea75f664d2a16c49c66d728b93b8e3e87dca3ae9ebe38200':'R3_NULL_GUARD_CANDIDATE'}
    if kapi_sha not in accepted:
        raise ValueError('OGKM fixed KAPI source mismatch')
    unit=args.candidate/'kexts/NVRM'
    os_text=(unit/'os-nvkms-xnu.cpp').read_text(encoding='utf-8')
    kapi=args.ogkm_kapi.read_text(encoding='utf-8')
    license_header=kapi[:kapi.index('*/')+2]
    prefix=PREFIX.replace('struct NvKmsKapiDevice {};', TYPES)
    prefix=prefix.replace('static void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *) { ++event_runs; }',
                          'void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *);')
    prefix=prefix.replace('schedules, event_runs, lock_depth','schedules, lock_depth')
    declarations=[]
    for start in ('static thread_call_t gKmsCloseWorker;', 'static bool gKmsCloseRetryReady',
                  'static bool gKmsCloseRetryArmed;', 'static const uint32_t kKmsCloseRetryMs'):
        matches=[line for line in os_text.splitlines() if line.startswith(start)]
        if len(matches)!=1: raise ValueError('state differs')
        declarations+=matches
    prefix=prefix.replace('// RETRY_STATE_FROM_SOURCE','\n'.join(declarations))
    start=os_text.index('struct nvkms_per_open {'); end=os_text.index('\n};',start)+3
    bodies=[function(os_text,name) for name in NAMES]
    start_ops=os_text.index('static const struct kms_deferred_ops kKmsDeferredOps = {')
    bodies.insert(4,os_text[start_ops:os_text.index('\n};',start_ops)+3])
    actual=[function(kapi,'static void KmsFreeDevice(struct NvKmsKapiDevice *device)'),
            function(kapi,'static void FreeDevice(struct NvKmsKapiDevice *device)'),
            function(kapi,'void nvKmsKapiHandleEventQueueChange\n(')]
    source=args.out/'fixture.cpp'
    source.write_text(license_header+'\n'+prefix+'\n'+os_text[start:end]+'\n'+'\n\n'.join(bodies+actual)+'\n'+TAIL,encoding='utf-8')
    binary=args.out/'fixture'
    command=[args.cxx,'-std=c++17','-Wall','-Wextra','-Werror','-I'+str(unit),
             str(unit/'kms_deferred.cpp'),str(source),'-o',str(binary)]
    result=subprocess.run(command,capture_output=True,text=True,timeout=60)
    (args.out/'compile.txt').write_text(result.stdout+result.stderr,encoding='utf-8')
    report={'level':'REAL_OGKM_AND_DRIVER_BODIES_INJECTED_CPU_ONLY',
        'binding':'LOCAL_SOURCE_ONLY','os_sha256':sha(unit/'os-nvkms-xnu.cpp'),
        'ogkm_sha256':kapi_sha,'ogkm_input':accepted[kapi_sha],'fixture_sha256':sha(source),
        'scenario':args.scenario,'compile_argv':command,'compile_exit':result.returncode,'run_exit':None,'status':'COMPILE_FAILED'}
    if result.returncode==0 and binary.is_file():
        result=subprocess.run([str(binary),args.scenario],capture_output=True,text=True,timeout=10)
        output=result.stdout+result.stderr
        (args.out/'run.txt').write_text(output,encoding='utf-8')
        report.update(run_exit=result.returncode,output=output,
                      status='CONTRACT_FAIL' if result.returncode else 'UNEXPECTED_PASS_REVIEW_REQUIRED')
    (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 1 # This diagnostic cannot authorize either candidate.


if __name__=='__main__': raise SystemExit(main())
