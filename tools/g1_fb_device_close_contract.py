#!/usr/bin/env python3
"""Real framebuffer -> OGKM -> OS close CPU contract, using injected services.

The two refusal scenarios currently FAIL. Success scenarios cannot mask them.
No kernel execution or real memory deletion; deterministic ioctl refusal is not
an observed HONOR race/UAF. Fresh output, checked compilation, no old binary.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from g1_kms_close_contract import function
from g1_kms_close_retry_contract import PREFIX, NAMES
from g1_kapi_close_owner_contract import TYPES

FB_SHA='4849c2f4fcdac03f25c221e72372dc7c9cf8bca9957b5c0d6689deb2e8df7453'
OS_SHA='7d86b6b96c0911b2aebd3fdc567fa5ba1dde1122630c515db28b271c3f1f4430'
KAPI_SHA='7e5492e0a0961e45ea75f664d2a16c49c66d728b93b8e3e87dca3ae9ebe38200'
SCENARIOS=('drop-success','orphan-success','drop-other-user','pin-refused',
           'orphan-other-users','drop-backend-refused','orphan-backend-refused')
FB_METHODS=('void NVRMNVDAFramebuffer::dropKapiDevice()',
            'void NVRMNVDAFramebuffer::finishOrphanedDevice()')

CALLERS=r'''
#define FBLOG(...) ((void)0)
using UInt32 = uint32_t;
class NVRMNVDAFramebuffer;
struct FakeKapi {
    void (*freeDevice)(NvKmsKapiDevice *);
    void (*releaseOwnership)(NvKmsKapiDevice *);
};
class NVRMNVDAFramebuffer {
public:
    bool fOwnsHead = true, fGrabbedOwnership = true;
    unsigned fHead = 0;
    NvKmsKapiDevice *fDev = nullptr;
    FakeKapi *fKms = nullptr;
    int releases = 0;
    void release() { ++releases; } // Counts only; no real object deletion.
    void dropKapiDevice();
    void finishOrphanedDevice();
};
struct NVRMDisplayGate { bool valid() const { return true; } };
static unsigned gHeadsTaken = 1;
// FB_SHARED_DECLARATIONS
static int ownership_releases;
static bool inject_backend_refusal;
static void checked_release(NvKmsKapiDevice *) { ++ownership_releases; }
static void nvkms_xnu_kms_close_deferred_count(uint32_t *total, uint32_t *lost) {
    if (total) *total = gKmsCloseDeferred;
    if (lost) *lost = gKmsCloseDeferredLost;
}
static void nvkms_close_from_kapi(nvkms_per_open *p) { kms_close_common(p); }
static int nvkms_ioctl_from_kapi(nvkms_per_open *, int cmd, void *params, size_t) {
    if (cmd == NVKMS_IOCTL_FREE_DEVICE) {
        // Injection after caller pin/running checks: equivalent to backend rejecting
        // the ioctl. We do not assert that PM suspend can bypass the real pin.
        if (inject_backend_refusal) { gKmsPmState = kKmsPmLost; return 0; }
        return 1;
    }
    require(cmd == NVKMS_IOCTL_GET_NEXT_EVENT, "unexpected ioctl");
    static_cast<NvKmsGetNextEventParams *>(params)->reply.valid = false;
    return 1;
}
'''

TAIL=r'''
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    (void)kms_close_retry_fire;
    (void)kms_kapi_event_fire;
    int data;
    NvKmsKapiDevice device = {};
    nvkms_per_open node = {};
    NVRMNVDAFramebuffer fb, creator;
    FakeKapi table = {FreeDevice, checked_release};
    gKmsCloseWorker = &worker_id;
    node.data = &data; node.device = &device;
    device.pKmsOpen = &node; device.hKmsDevice = 1;
    fb.fDev = gDev = &device; fb.fKms = &table;
    gDevUsers = 1; gDevCreator = &creator;
    const bool orphan = std::strncmp(argv[1], "orphan-", 7) == 0;
    const bool refused = std::strstr(argv[1], "backend-refused") != nullptr;
    if (orphan) { gDevUsers = 0; gDevOrphaned = true; gOrphanGrabs = 2; }
    if (std::strcmp(argv[1], "drop-other-user") == 0) gDevUsers = 2;
    if (std::strcmp(argv[1], "pin-refused") == 0) gKmsPmState = kKmsPmSuspended;
    if (std::strcmp(argv[1], "orphan-other-users") == 0) gDevUsers = 1;
    inject_backend_refusal = refused;
    try {
        if (orphan) fb.finishOrphanedDevice(); else fb.dropKapiDevice();
        require(gKmsPmPins == 0, "caller leaked its PM pin");
        if (refused) {
            require(gDev == &device && gDevCreator == &creator && creator.releases == 0 &&
                    rm_frees == 0 && device_frees == 0,
                    "CALLER_DROPPED_DEVICE_AND_CREATOR_AFTER_REFUSAL");
        } else if (std::strcmp(argv[1], "pin-refused") == 0) {
            require(gDev == &device && gDevOrphaned && gOrphanGrabs == 1 &&
                    !fb.fDev && gDevUsers == 0 && gDevCreator == &creator &&
                    creator.releases == 0 && ownership_releases == 0 && !device_frees && !rm_frees,
                    "pin refusal lost owner/debt");
        } else if (std::strstr(argv[1], "other-user") != nullptr) {
            require(gDev == &device && gDevUsers == 1 && gDevCreator == &creator &&
                    creator.releases == 0 && !device_frees && !rm_frees &&
                    ownership_releases == (orphan ? 2 : 1), "shared-device ownership lost");
        } else {
            require(!gDev && !gDevCreator && creator.releases == 1 &&
                    rm_frees == 1 && device_frees == 1 && backend_closes == 1 && wrapper_frees == 1 &&
                    ownership_releases == (orphan ? 2 : 1), "successful close not exactly once");
        }
        std::printf("PASS %s\n", argv[1]);
    } catch (const std::exception &e) {
        std::printf("FAIL %s %s\n", argv[1], e.what());
        std::printf("OBSERVATION gDev_retained=%d creator_retained=%d creator_release=%d RM_free=%d Device_free=%d backend_close=%d wrapper_free=%d queued=%u pin=%d ownership_release=%d\n",
          gDev == &device, gDevCreator == &creator, creator.releases, rm_frees, device_frees,
          backend_closes, wrapper_frees, kms_deferred_count(), gKmsPmPins, ownership_releases);
        return 1;
    }
    return 0;
}
'''


def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def generate(candidate, kapi_path):
    unit=candidate/'kexts/NVRM';fb_path=candidate/'kexts/NVRMFB/fb/nvrm-fb.cpp'
    hashes={'fb':sha(fb_path),'os':sha(unit/'os-nvkms-xnu.cpp'),'ogkm':sha(kapi_path)}
    if hashes!={'fb':FB_SHA,'os':OS_SHA,'ogkm':KAPI_SHA}:
        raise ValueError('requires exact accepted R33 baseline; add new candidate explicitly after review')
    os_text=(unit/'os-nvkms-xnu.cpp').read_text(encoding='utf-8')
    fb=fb_path.read_text(encoding='utf-8');kapi=kapi_path.read_text(encoding='utf-8')
    prefix=PREFIX.replace('struct NvKmsKapiDevice {};', TYPES)
    prefix=prefix.replace('device_frees, rm_frees, downstream_events','device_frees, rm_frees')
    prefix=prefix.replace('static void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *) { ++event_runs; }',
                          'void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *);')
    prefix=prefix.replace('schedules, event_runs, lock_depth','schedules, lock_depth')
    declarations=[]
    for name in ('static thread_call_t gKmsCloseWorker;', 'static bool gKmsCloseRetryReady',
                 'static bool gKmsCloseRetryArmed;', 'static const uint32_t kKmsCloseRetryMs'):
        lines=[line for line in os_text.splitlines() if line.startswith(name)]
        if len(lines)!=1: raise ValueError('OS state definition differs')
        declarations+=lines
    prefix=prefix.replace('// RETRY_STATE_FROM_SOURCE','\n'.join(declarations))
    start=os_text.index('struct nvkms_per_open {');end=os_text.index('\n};',start)+3
    bodies=[function(os_text,n) for n in NAMES]
    ops=os_text.index('static const struct kms_deferred_ops kKmsDeferredOps = {')
    bodies.insert(4,os_text[ops:os_text.index('\n};',ops)+3])
    bodies += [function(os_text,n) for n in ('NvBool nvkms_xnu_pm_pin(void)',
                'void nvkms_xnu_pm_unpin(void)','NvBool nvkms_xnu_pm_running(void)')]
    bodies += [function(kapi,n) for n in ('static void KmsFreeDevice(struct NvKmsKapiDevice *device)',
                'static void FreeDevice(struct NvKmsKapiDevice *device)',
                'void nvKmsKapiHandleEventQueueChange\n(')]
    shared=[]
    for name in ('static struct NvKmsKapiDevice *gDev;', 'static int gDevUsers;',
                 'static bool gDevOrphaned;', 'static int gOrphanGrabs;',
                 'static NVRMNVDAFramebuffer *gDevCreator;'):
        if fb.splitlines().count(name)!=1: raise ValueError('FB shared state definition differs')
        shared.append(name)
    callers=CALLERS.replace('// FB_SHARED_DECLARATIONS','\n'.join(shared))
    text=kapi[:kapi.index('*/')+2]+'\n'+prefix+'\n'+os_text[start:end]+'\n'+'\n\n'.join(bodies)
    text+='\n'+callers+'\n'+'\n\n'.join(function(fb,n) for n in FB_METHODS)+'\n'+TAIL
    return text,hashes


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate',type=Path,required=True);p.add_argument('--ogkm-kapi',type=Path,required=True)
    p.add_argument('--native-report',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
    p.add_argument('--negative-compile',action='store_true');p.add_argument('--cxx',default='g++')
    a=p.parse_args();a.out.mkdir(parents=True,exist_ok=False)
    text,hashes=generate(a.candidate,a.ogkm_kapi)
    native=json.loads(a.native_report.read_text(encoding='utf-8'))
    if sha(a.native_report)!='eb6cd2104952a8df3c9656fd48d5bf87eec8db9ddddf5db89b1adf21a3987c1d':
        raise ValueError('wrong independently accepted R33 native report')
    row,=[r for r in native['objects'] if r['unit']=='NVRMFB' and r['profile']=='candidate']
    osrow,=[r for r in native['build_manifest'] if r['role']=='nvrm-unified' and r['source']=='kexts/NVRM/os-nvkms-xnu.cpp']
    if row['compile_exit'] or row['source_sha256']!=hashes['fb'] or osrow['source_sha256']!=hashes['os']:
        raise ValueError('actual accepted native source hashes differ')
    source=a.out/'fixture.cpp';source.write_text(text+('\n#error COMPILE_NEGATIVE_CONTROL\n' if a.negative_compile else ''),encoding='utf-8')
    binary=a.out/'fixture';unit=a.candidate/'kexts/NVRM'
    argv=[a.cxx,'-std=c++17','-Wall','-Wextra','-Werror','-I'+str(unit),str(unit/'kms_deferred.cpp'),str(source),'-o',str(binary)]
    c=subprocess.run(argv,capture_output=True,text=True,timeout=60)
    (a.out/'compile.txt').write_text(c.stdout+c.stderr,encoding='utf-8')
    report={'level':'REAL_FB_OGKM_OS_BODIES_INJECTED_CPU_ONLY','source_sha256':hashes,
      'binding':'FB_AND_OS_SOURCE_MATCH_ACCEPTED_R33_NATIVE_REPORT;OGKM_FIXED_R3_SOURCE',
      'native_report_sha256':sha(a.native_report),'fixture_sha256':sha(source),
      'fb_methods':list(FB_METHODS),'compile_argv':argv,'compile_exit':c.returncode,
      'binary_exists':binary.is_file(),'scenarios':[],'status':'COMPILE_FAILED','gpu':'NOT_RUN','device':'NO-GO'}
    if c.returncode==0 and binary.is_file():
        for name in SCENARIOS:
            r=subprocess.run([str(binary),name],capture_output=True,text=True,timeout=10)
            output=r.stdout+r.stderr;(a.out/(name+'.txt')).write_text(output,encoding='utf-8')
            report['scenarios'].append({'name':name,'exit':r.returncode,'output':output})
        report['status']='CONTRACT_FAIL' if any(r['exit'] for r in report['scenarios']) else 'PASS_CPU_ONLY'
    (a.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 0 if report['status']=='PASS_CPU_ONLY' else 1


if __name__=='__main__': raise SystemExit(main())
