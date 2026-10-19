#!/usr/bin/env python3
"""Extract candidate close-chain bodies; run real heap frees under AddressSanitizer.

Injected types/IOKit/NISO/RM services are CPU boundaries, not kernel/ABI proof.
The historical R35 handwritten fixture is used only as an ASan negative control.
"""
import argparse,hashlib,json,subprocess
from pathlib import Path
from g1_fb_device_close_contract import CALLERS,FB_METHODS
from g1_kapi_close_owner_contract import TYPES
from g1_kms_close_retry_contract import PREFIX,NAMES
from g1_kms_close_contract import function

EXPECTED={'fb':'f5e0f84db0c321739d8477bf81af5c96943e7e748b11763fce2a65269fab56dd',
 'os':'1e6e1dc8c3a03f258c9b5ef66f89e71b14cb906ac4406a610a13666609b74da1',
 'ogkm':'dc4397d8478aa6f9a88656f7f10852da943ee27289a7544d44549a10b3329a6e'}
SCENARIOS=('drop-success','orphan-success','drop-other-user','orphan-other-users','pin-refused',
 'drop-backend-refused','orphan-backend-refused','drop-close-refused','callback-active',
 'callback-free-refused','callback-retry','null-device')

TAIL=r'''
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    (void)kms_close_retry_fire; (void)kms_kapi_event_fire;
    (void)nvkms_close_from_kapi; (void)nvkms_xnu_kms_close_deferred_count;
    const char *name=argv[1];
    auto *heap = new NvKmsKapiDevice{};
    NvKmsKapiDevice &device = *heap;
    nvkms_per_open node = {}; int data;
    NVRMNVDAFramebuffer fb,creator;
    FakeKapi table={FreeDevice,checked_release};
    gKmsCloseWorker=&worker_id;node.data=&data;node.device=heap;
    device.pKmsOpen=&node;device.hKmsDevice=1;
    fb.fDev=gDev=heap;fb.fKms=&table;gDevCreator=&creator;gDevUsers=1;
    bool orphan=std::strncmp(name,"orphan-",7)==0;
    bool backend_refused=std::strstr(name,"backend-refused")!=nullptr;
    bool close_refused=std::strcmp(name,"drop-close-refused")==0;
    bool callback=std::strncmp(name,"callback-",9)==0;
    bool callback_retry=std::strcmp(name,"callback-retry")==0;
    if(orphan){gDevUsers=0;gDevOrphaned=true;gOrphanGrabs=2;}
    if(std::strcmp(name,"drop-other-user")==0)gDevUsers=2;
    if(std::strcmp(name,"orphan-other-users")==0)gDevUsers=1;
    if(std::strcmp(name,"pin-refused")==0)gKmsPmState=kKmsPmSuspended;
    if(callback){node.eventCall=&data;node.eventBusy=true;}
    if(std::strcmp(name,"callback-free-refused")==0){node.eventBusy=false;event_free_ok=false;}
    inject_backend_refusal=backend_refused;inject_close_refusal=close_refused;
    try {
        if(std::strcmp(name,"null-device")==0){
            require(nvKmsKapiTryFreeDevice(nullptr),"null close not completed");
            require(!device_frees&&!rm_frees&&!gKmsPmPins,"null close touched resource");
        } else {
            if(orphan)fb.finishOrphanedDevice();else fb.dropKapiDevice();
            require(gKmsPmPins==0,"PM pin leaked");
            if(backend_refused||close_refused||callback){
                require(gDev==heap&&gDevCreator==&creator&&gDevOrphaned&&
                  !creator.releases&&!rm_frees&&!device_frees&&!backend_closes&&!wrapper_frees&&
                  kms_deferred_count()==0,"incomplete close lost owner or queued wrapper alone");
                require(niso_frees==0,"NISO unmapped before the close was known to succeed");
                if(callback_retry){
                    node.eventBusy=false;event_free_ok=true;fb.finishOrphanedDevice();
                    require(!gDev&&!gDevCreator&&creator.releases==1&&device_frees==1&&rm_frees==1&&
                      backend_closes==1&&wrapper_frees==1&&!gKmsPmPins&&niso_frees==2,
                      "retry not completed exactly once or NISO not unmapped");
                }
            } else if(std::strcmp(name,"pin-refused")==0){
                require(gDev==heap&&gDevOrphaned&&gOrphanGrabs==1&&!fb.fDev&&gDevUsers==0&&
                  !device_frees&&!rm_frees&&!creator.releases&&niso_frees==0,"pin refusal lost ownership/debt");
            } else if(std::strstr(name,"other-user")){
                require(gDev==heap&&gDevUsers==1&&!creator.releases&&!device_frees&&!rm_frees&&
                  ownership_releases==(orphan?2:1),"shared device released");
            } else {
                require(!gDev&&!gDevCreator&&creator.releases==1&&device_frees==1&&rm_frees==1&&
                  backend_closes==1&&wrapper_frees==1&&ownership_releases==(orphan?2:1),
                  niso_frees==2,"successful free not exactly once or NISO not unmapped twice");
            }
        }
        if(!device_frees)delete heap; // Harness cleanup after all ownership observations.
        std::printf("PASS %s\n",name);return 0;
    }catch(const std::exception &e){std::printf("FAIL %s %s\n",name,e.what());return 1;}
}
'''

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def generate(nm,kapi):
    unit=nm/'kexts/NVRM';fbp=nm/'kexts/NVRMFB/fb/nvrm-fb.cpp'
    hashes={'fb':sha(fbp),'os':sha(unit/'os-nvkms-xnu.cpp'),'ogkm':sha(kapi)}
    if hashes!=EXPECTED:raise ValueError('unreviewed source identity')
    fb=fbp.read_text(encoding='utf-8');os=(unit/'os-nvkms-xnu.cpp').read_text(encoding='utf-8');k=kapi.read_text(encoding='utf-8')
    types=TYPES.replace('device_frees, rm_frees, downstream_events','device_frees, rm_frees')
    types=types.replace('static void nvKmsKapiFree(NvKmsKapiDevice *) { ++device_frees; }',
                        'static void nvKmsKapiFree(NvKmsKapiDevice *p) { ++device_frees; delete p; }')
    prefix=PREFIX.replace('struct NvKmsKapiDevice {};',types)
    prefix=prefix.replace('static void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *) { ++event_runs; }',
                          'void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *);')
    prefix=prefix.replace('schedules, event_runs, lock_depth','schedules, lock_depth')
    declarations=[]
    for name in ('static thread_call_t gKmsCloseWorker;', 'static bool gKmsCloseRetryReady',
                 'static bool gKmsCloseRetryArmed;', 'static const uint32_t kKmsCloseRetryMs', 'static const uint32_t kKmsCloseJoinMs'):
        rows=[r for r in os.splitlines() if r.startswith(name)]
        if len(rows)!=1:raise ValueError('state definition differs')
        declarations+=rows
    prefix=prefix.replace('// RETRY_STATE_FROM_SOURCE','\n'.join(declarations))
    start=os.index('struct nvkms_per_open {');end=os.index('\n};',start)+3
    bodies=[function(os,n) for n in NAMES]
    ops=os.index('static const struct kms_deferred_ops kKmsDeferredOps = {')
    bodies.insert(4,os[ops:os.index('\n};',ops)+3])
    bodies += [function(os,n) for n in ('NvBool nvkms_xnu_pm_pin(void)',
      'void nvkms_xnu_pm_unpin(void)','NvBool nvkms_xnu_pm_running(void)',
      'extern "C" NvBool nvkms_xnu_try_quiesce_kapi(struct nvkms_per_open *popen)',
      'extern "C" NvBool nvkms_xnu_try_close_kapi(struct nvkms_per_open *popen)')]
    bodies += [function(k,n) for n in ('static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device)',
      'NvBool nvKmsKapiTryFreeDevice(struct NvKmsKapiDevice *device)',
      'static void FreeDevice(struct NvKmsKapiDevice *device)','void nvKmsKapiHandleEventQueueChange\n(')]
    shared=[]
    for name in ('static struct NvKmsKapiDevice *gDev;', 'static int gDevUsers;',
      'static bool gDevOrphaned;', 'static int gOrphanGrabs;', 'static NVRMNVDAFramebuffer *gDevCreator;'):
        if fb.splitlines().count(name)!=1:raise ValueError('FB definition differs')
        shared.append(name)
    callers=CALLERS.replace('// FB_SHARED_DECLARATIONS','\n'.join(shared))
    callers=callers.replace('static bool inject_backend_refusal;','static bool inject_backend_refusal, inject_close_refusal;')
    callers=callers.replace('        return 1;\n    }','        if (inject_close_refusal) gKmsPmState = kKmsPmLost;\n        return 1;\n    }')
    return (k[:k.index('*/')+2]+'\n'+prefix+'\n'+os[start:end]+'\n'+'\n\n'.join(bodies)+'\n'+callers+
      '\n'+'\n\n'.join(function(fb,n) for n in FB_METHODS)+'\n'+TAIL),hashes

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate',type=Path,required=True);p.add_argument('--ogkm-kapi',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True);p.add_argument('--cxx',default='g++')
    p.add_argument('--native-report',type=Path);p.add_argument('--negative-compile',action='store_true')
    a=p.parse_args();a.out.mkdir(parents=True,exist_ok=False)
    text,hashes=generate(a.candidate,a.ogkm_kapi)
    if a.native_report:
        n=json.loads(a.native_report.read_text())
        row,=[r for r in n['objects'] if r['unit']=='NVRMFB' and r['profile']=='candidate']
        osrow,=[r for r in n['build_manifest'] if r['role']=='nvrm-unified' and r['source']=='kexts/NVRM/os-nvkms-xnu.cpp']
        if (row['compile_exit'] or osrow['compile_exit'] or row['source_sha256']!=hashes['fb'] or
                osrow['source_sha256']!=hashes['os']):
            raise ValueError('real native source binding differs')
    source=a.out/'fixture.cpp';source.write_text(text+('\n#error COMPILE_NEGATIVE_CONTROL\n' if a.negative_compile else ''),encoding='utf-8')
    exe=a.out/'fixture';unit=a.candidate/'kexts/NVRM'
    argv=[a.cxx,'-std=c++17','-O1','-g','-fsanitize=address','-fno-omit-frame-pointer','-Wall','-Wextra','-Werror',
      '-I'+str(unit),str(unit/'kms_deferred.cpp'),str(source),'-o',str(exe)]
    cp=subprocess.run(argv,capture_output=True,text=True,timeout=60)
    (a.out/'compile.txt').write_text(cp.stdout+cp.stderr,encoding='utf-8')
    report={'level':'REAL_SOURCE_BODIES_CPU_ASAN_NOT_KERNEL','source_sha256':hashes,'fixture_sha256':sha(source),
      'binding':'NATIVE_FB_OS_SOURCE_MATCH' if a.native_report else 'LOCAL_FIXED_SOURCE_ONLY',
      'native_report_sha256':sha(a.native_report) if a.native_report else None,
      'compile_argv':argv,'compile_exit':cp.returncode,'binary_exists':exe.is_file(),'scenarios':[],
      'injections':'IOKit/locks, NISO, RM, backend and counters; Device heap allocation/free are real',
      'status':'COMPILE_FAILED','device':'NO-GO','gpu':'NOT_RUN'}
    if cp.returncode==0 and exe.is_file():
        for name in SCENARIOS:
            r=subprocess.run([str(exe),name],capture_output=True,text=True,timeout=10)
            output=r.stdout+r.stderr;(a.out/(name+'.txt')).write_text(output,encoding='utf-8')
            report['scenarios'].append({'name':name,'exit':r.returncode,'output':output})
        report['status']='PASS_CPU_ASAN_ONLY' if all(r['exit']==0 for r in report['scenarios']) else 'CONTRACT_FAIL'
    (a.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    if report["status"]!="PASS_CPU_ASAN_ONLY":
        bad=[s for s in report["scenarios"] if s["exit"]]
        for s in bad[:4]:
            line=(s["output"].strip().splitlines() or ["(no output)"])[-1]
            print("::error::R36_SCENARIO "+s["name"]+": "+line[:240], flush=True)
        if not bad:
            print("::error::R36_COMPILE exit="+str(report["compile_exit"]), flush=True)
    return 0 if report["status"]=="PASS_CPU_ASAN_ONLY" else 1

if __name__=='__main__':
    try:
        raise SystemExit(main())
    except SystemExit:
        raise
    except Exception as error:  # annotations survive the missing log/artifact channel
        print('::error::R36_CONTRACT '+(type(error).__name__+': '+str(error))[:280], flush=True)
        raise
