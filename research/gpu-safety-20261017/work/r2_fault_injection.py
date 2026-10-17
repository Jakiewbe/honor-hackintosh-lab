#!/usr/bin/env python3
"""Run exact production open/close/event bodies with injected platform dependencies.
Single-threaded fault injection only; never claims IOKit or GPU execution.
"""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'evidence/r2'

def block(text, marker):
    start=text.index(marker)
    opening=text.index('{',start)
    depth=1
    i=opening+1
    while depth:
        if text[i]=='{': depth+=1
        elif text[i]=='}': depth-=1
        i+=1
    return text[start:i]

shim = r"""
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstdarg>
#include <vector>
#include <algorithm>
using NvU32=unsigned;
using NvBool=int;
constexpr int NV_TRUE=1;
enum NvKmsClientType { NVKMS_CLIENT_USER_SPACE, NVKMS_CLIENT_KERNEL_SPACE };
struct NvKmsKapiDevice { int tag; };
using thread_call_param_t=void *;
struct Call { void *arg; };
using thread_call_t=Call *;
using IOLock=int;
static int lockValue;
static IOLock *gKmsLock=&lockValue;
constexpr int THREAD_CALL_PRIORITY_KERNEL=1, THREAD_CALL_OPTIONS_ONCE=1, THREAD_UNINT=1;
static const uint32_t kKmsPmWaitMs=30000;
static int gKmsPmState=0;
static const char *const kKmsPmName[]={"running","suspended","lost"};
static bool failWrapper,failWorker,failNvOpen,failCallFree;
static int opens,workers,enters,closes,logs,lockDepth,wrapperFrees,callFrees;
static std::vector<void*> wrappers;
static std::vector<Call*> calls;
static void check(bool ok,const char *msg) { if(!ok) {std::fprintf(stderr,"HARNESS ERROR: %s\n",msg);std::abort();} }
static void *nvkms_alloc(size_t n,NvBool zero) {
    if(failWrapper) return nullptr;
    void *p=zero?std::calloc(1,n):std::malloc(n); check(p,"host allocation");wrappers.push_back(p);return p;
}
static void nvkms_free(void *p,size_t) {
    const auto it=std::find(wrappers.begin(),wrappers.end(),p);check(it!=wrappers.end(),"wrapper double free");
    wrappers.erase(it);std::free(p);++wrapperFrees;
}
static void kms_kapi_event_fire(thread_call_param_t,thread_call_param_t) {
    check(false,"injected scheduler must not execute a platform callback");
}
static thread_call_t thread_call_allocate_with_options(void (*fn)(void*,void*),void *p,int,int) {
    check(fn==kms_kapi_event_fire,"callback identity");++workers;
    if(failWorker)return nullptr;
    auto *c=new Call{p};calls.push_back(c);return c;
}
static bool thread_call_free(thread_call_t c) {
    check(lockDepth==0,"free outside gKmsLock");
    if(failCallFree)return false;
    const auto it=std::find(calls.begin(),calls.end(),c);check(it!=calls.end(),"call double free");
    calls.erase(it);delete c;++callFrees;return true;
}
static void thread_call_enter(thread_call_t c) { check(c!=nullptr,"enter requires call");++enters; }
static bool thread_call_cancel(thread_call_t) { check(false,"cancellation not exercised");return false; }
static void IOLockLock(IOLock*) { check(lockDepth==0,"nested platform lock");++lockDepth; }
static void IOLockUnlock(IOLock*) { check(lockDepth==1,"unlock ownership");--lockDepth; }
static int IOLockSleep(IOLock*,void*,int) {check(false,"test must not wait");return -1;}
static bool kms_pm_wait_locked(bool,uint32_t) { check(lockDepth==1,"PM lock");return true; }
static void *nvKmsOpen(NvU32,NvKmsClientType,void*) {
    check(lockDepth==1,"open lock");++opens;return failNvOpen?nullptr:reinterpret_cast<void*>(0x1234);
}
static void nvKmsClose(void*) {check(lockDepth==1,"close lock");++closes;}
static void kprintf(const char*,...) {++logs;}
"""

harness=r"""
static int failures,total;
static void expect(bool ok,const char *name) {
    ++total;if(!ok){++failures;std::printf("FAIL: %s\n",name);}else std::printf("PASS: %s\n",name);
}
static void reset() {
    // Test-fixture cleanup only, including deliberately retained wrappers.
    for(auto *c:calls) { delete c; }
    calls.clear();
    for(void *p:wrappers) { std::free(p); }
    wrappers.clear();
    check(lockDepth==0,"balanced locks");
    failWrapper=failWorker=failNvOpen=failCallFree=false;
    opens=workers=enters=closes=logs=wrapperFrees=callFrees=0;
}
int main() {
    NvKmsKapiDevice dev{1};
    failWrapper=true;
    expect(!kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,&dev,1)&&opens==0&&workers==0,"wrapper allocation failure has no downstream side effects");
    reset();failWorker=true;
    auto *p=kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,&dev,1);
    expect(!p&&opens==0&&wrapperFrees==1,"worker allocation failure rejects open before nvKmsOpen");
    reset();failNvOpen=true;
    p=kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,&dev,1);
    expect(!p&&workers==1&&callFrees==1&&wrapperFrees==1,"nvKmsOpen failure rolls back preallocated call and wrapper");
    reset();failNvOpen=failCallFree=true;
    p=kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,&dev,1);
    expect(!p&&logs==1&&wrapperFrees==0&&calls.size()==1&&wrappers.size()==1,"rollback call-free failure reports and retains callback argument");
    reset();p=kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,&dev,1);
    expect(p&&p->eventCall&&opens==1&&workers==1,"KAPI open acquires worker and actual per-open handle");
    p->closing=true;nvkms_event_queue_changed(p,1);
    expect(enters==0,"closing KAPI client rejects new worker submission");p->closing=false;
    nvkms_event_queue_changed(p,1);nvkms_event_queue_changed(p,1);
    expect(enters==1&&p->eventBusy&&p->eventWanted,"KAPI event submissions coalesce");
    reset();p=kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,nullptr,42);
    expect(p&&p->type==NVKMS_CLIENT_KERNEL_SPACE&&!p->eventCall&&workers==0,"ioctl bridge keeps kernel semantics without KAPI worker");
    nvkms_event_queue_changed(p,1);
    expect(p->eventsAvailable==1&&enters==0,"ioctl bridge exposes queued events to polling caller");
    nvkms_event_queue_changed(p,0);
    expect(p->eventsAvailable==0,"ioctl bridge clears poll availability after dequeue");
    reset();p=kms_open_common(NVKMS_CLIENT_USER_SPACE,nullptr,42);
    nvkms_event_queue_changed(p,1);
    expect(p&&p->eventsAvailable==1&&workers==0,"existing user-space event polling preserved");
    reset();p=kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,&dev,1);failCallFree=true;
    kms_close_common(p);
    expect(closes==1&&logs==1&&wrapperFrees==0&&wrappers.size()==1,"close call-free failure retains closing callback argument");
    reset();p=kms_open_common(NVKMS_CLIENT_KERNEL_SPACE,&dev,1);kms_close_common(p);
    expect(closes==1&&wrapperFrees==1&&callFrees==1&&wrappers.empty()&&calls.empty(),"ordinary idle KAPI close frees each resource once");
    reset();std::printf("RESULT: %d/%d passed (platform dependencies injected; no concurrency or GPU proof)\n",total-failures,total);
    return failures?1:0;
}
"""
records={}
for label,dirname in [('r1','nullmoth-v2.3.3-gpu-safety-r1'),('r2','nullmoth-v2.3.3-gpu-safety-r2')]:
    source=ROOT/'candidate'/dirname/'kexts/NVRM/os-nvkms-xnu.cpp'
    text=source.read_text(encoding='utf-8')
    markers=['struct nvkms_per_open {','static struct nvkms_per_open *kms_open_common(',
             'static void kms_close_common(', 'void nvkms_event_queue_changed(']
    bodies=[block(text,m) for m in markers]
    bodies[0]+=';\nusing nvkms_per_open_handle_t=nvkms_per_open;'
    dest=OUT/(label+'-actual-functions.cpp')
    dest.write_text(shim+'\n'+'\n'.join(bodies)+'\n'+harness,encoding='utf-8')
    records[label]={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                    'extracted_markers':markers,'fixture_sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}
(OUT/'fault-injection-inputs.json').write_text(json.dumps(records,indent=1),encoding='utf-8')
print('exact production function fixtures generated; injected platform boundary explicit')
