
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

void NVRM::gpuSuspend()
{
    uint64_t t0 = mach_absolute_time();
    fPmCycles++;
    OSCompareAndSwap(kGpuPmRunning, kGpuPmSuspended, &fGpuPm);
    setProperty("nvrm-pm", "suspended");
    LOG("sleep #%u: suspending the GPU (NVKMS, then RM standby)", fPmCycles);
    notifyFramebuffers(0);
    // NVKMS first: once it is suspended no thread is inside it, so none can hold gKmsLock while it waits at the RM
    // gate (closing the gate first deadlocked against an NVKMS ioctl calling into RM).
    nvkms_xnu_suspend(fNv.gpu_id);
    const int busy = nv_xnu_pm_close(10000);
    if (busy) {
        // Never mutate RM power/channel state underneath calls that did not drain.
        // NVKMS and fGpuPm stay Suspended; do not relight framebuffers or reopen
        // the gate here. setPowerState cannot veto system sleep by returning an error.
        // This guard is NOT a safe-sleep or recovery contract; device use stays NO-GO.
        setProperty("nvrm-pm-violation", kOSBooleanTrue);
        LOG("sleep #%u: %d RM call(s) still active - RM channel stop and STANDBY skipped; sleep safety unverified",
            fPmCycles, busy);
        return;
    }
    // nv_preempt_user_channels(): with every VRAM allocation preserved, user channels must be idle and stopped
    // while their memory is copied out, and restarted once it is back.
    NV_STATUS cst = rm_stop_user_channels(NULL, &fNv);
    pciSaveForSleep();
    NV_STATUS st = rm_power_management(NULL, &fNv, NV_PM_ACTION_STANDBY);
    if (fIntSrc) fIntSrc->disable();
    uint64_t ns = 0; absolutetime_to_nanoseconds(mach_absolute_time() - t0, &ns);
    LOG("sleep #%u: user channels stopped -> 0x%x; rm_power_management(STANDBY) -> 0x%x in %llu ms%s", fPmCycles,
        (unsigned)cst, (unsigned)st, ns / 1000000ULL, st == NV_OK ? "" : " - resume will still be tried, as on Linux");
}

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
