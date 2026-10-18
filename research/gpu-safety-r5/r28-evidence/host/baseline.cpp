
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
#define NVIOP_FAIL(rc, fmt, ...) do { OSAddAtomic64(1, &gCntIopFail); NVIOPLOG(fmt, ##__VA_ARGS__); return (rc); } while (0)
IOReturn NVDisplayPipe::performTransaction(IOAccelDisplayPipeTransaction2 *txn)
{
    if (!gNvIop) return (IOReturn)0xe00002c7;
    if (!txn) NVIOP_FAIL(kIOReturnBadArgument, "performTransaction(NULL)");
    NVAccel *a = NVAccel::gAccel;
    unsigned head = 0;
    IOService *fb = a ? a->pipeFramebuffer(this, &head) : nullptr;
    if (!fb) NVIOP_FAIL(kIOReturnNotAttached, "no accelerator, or pipe %p drives a framebuffer that is none of ours", this);

    IOSurface *s  = txn->getPlaneIOSurface(0, 0);
    OSObject  *ro = txn->getPlaneResource(0, 0);
    if (!s && !ro) { OSAddAtomic64(1, &gCntIopEmpty); return kIOReturnSuccess; }

    const volatile unsigned int *src = nullptr; unsigned w = 0, h = 0, pitch = 0; bool fromRes = false;
    unsigned long long sourceBytes = 0;
    NVResource *res = OSDynamicCast(NVResource, ro);
    NVVidMemory *vm = res ? nvres_vidmem(res) : nullptr;
    static SInt32 gIopK6Logs;
    if (gIopK6Logs < 6) {
        OSIncrementAtomic(&gIopK6Logs);
        const unsigned char *kr = (const unsigned char *)res;
        ALOG("iop: K6 plane 0: surface %s id 0x%x %ux%u row %u fmt 0x%08x | resource %s w %u h %u +0xb8 %u +0xc0 %u vidmem %llu bytes kva %d scanout %d",
             s ? "yes" : "NO", s ? (unsigned)s->getSurfaceID() : 0u, s ? (unsigned)s->getWidth() : 0u, s ? (unsigned)s->getHeight() : 0u,
             s ? (unsigned)s->getBytesPerRow() : 0u, s ? (unsigned)s->getPixelFormat() : 0u,
             ro ? ro->getMetaClass()->getClassName() : "(none)",
             res ? (unsigned)*(const volatile unsigned short *)(kr + 0xb0) : 0u, res ? (unsigned)*(const volatile unsigned short *)(kr + 0xb2) : 0u,
             res ? *(const volatile unsigned int *)(kr + 0xb8) : 0u, res ? *(const volatile unsigned int *)(kr + 0xc0) : 0u,
             vm ? (unsigned long long)vm->fBytes : 0ull, (vm && vm->fKva) ? 1 : 0, vm ? (int)vm->fScanout : -1);
    }
    if (!s && vm && vm->fKva) {
        const unsigned char *rr = (const unsigned char *)res;
        w     = *(const volatile unsigned short *)(rr + 0xb0);
        h     = *(const volatile unsigned short *)(rr + 0xb2);
        pitch = *(const volatile unsigned int   *)(rr + 0xb8);
        if ((unsigned long long)pitch < 4ull * w) NVIOP_FAIL(kIOReturnBadArgument, "resource %ux%u: +0xb8 reads %u, which is not a row pitch (need >= %u) — not a surface buffer", w, h, pitch, 4u * w);
        if ((unsigned long long)h * pitch > vm->fBytes) NVIOP_FAIL(kIOReturnOverrun, "resource %ux%u pitch %u exceeds its %llu bytes", w, h, pitch, (unsigned long long)vm->fBytes);
        src = (const volatile unsigned int *)vm->fKva; fromRes = true; sourceBytes = vm->fBytes;
    } else if (s && nvAccelIopFlip(fb, head, s, this)) {
        OSAddAtomic64(1, &gCntIopSrcSurf); OSAddAtomic64(1, &gCntIopOk); OSAddAtomic64(1, &gCntIopOkHead[head]);
        return kIOReturnSuccess;
    } else if (s) {
        // A copied frame must come from the surface's newest pixels. Copying while they were still only in VRAM put a
        // stale, one-colour buffer on the panel every other frame: full-screen flicker, 5 of 40 flicker recordings
        // (1.13-1.14.1), nvaccel_iop_blank about half of every copied frame, never on machines whose frames all flip.
        // Such a frame now keeps the previous picture on the panel instead.
        if (!nvSurfWaitReady(s->getSurfaceID()))
            NVIOP_FAIL(kIOReturnNotReady, "surface 0x%x GPU completion unproven or timed out", s->getSurfaceID());
        if (!nvAccelSurfCopyReady(s, head))
            NVIOP_FAIL(kIOReturnNotReady, "surface 0x%x has no current CPU-visible contents", s->getSurfaceID());
        const unsigned fmt = s->getPixelFormat();
        if (fmt != 0x42475241u) NVIOP_FAIL(kIOReturnUnsupported, "surface 0x%x format 0x%08x is not BGRA", s->getSurfaceID(), fmt);
        const unsigned long long W = s->getWidth(), H = s->getHeight(), P = s->getBytesPerRow();
        if (!W || !H || P < 4 || W > 16384 || H > 16384 || P > 16384ull * 8) NVIOP_FAIL(kIOReturnBadArgument, "surface geometry %llux%llu pitch %llu", W, H, P);
        if (P < 4 * W || (P & 3)) NVIOP_FAIL(kIOReturnBadArgument, "surface %llux%llu: row pitch %llu is under 4*W or not word-aligned", W, H, P);
        IOMemoryDescriptor *md = s->getMemoryDescriptor();
        if (!md) NVIOP_FAIL(kIOReturnNoMemory, "surface 0x%x has no memory descriptor", s->getSurfaceID());
        src = (const volatile unsigned int *)iopMapSurface(s->getSurfaceID(), md, H * P);
        if (!src) NVIOP_FAIL(kIOReturnVMError, "surface 0x%x would not prepare/map %llu bytes", s->getSurfaceID(), H * P);
        w = (unsigned)W; h = (unsigned)H; pitch = (unsigned)P; sourceBytes = H * P;
    } else {
        NVIOP_FAIL(kIOReturnUnsupported, "plane resource %p is not an NVResource with a CPU mapping, and there is no IOSurface", ro);
    }
    if (!w || !h || pitch < 4) NVIOP_FAIL(kIOReturnBadArgument, "source geometry %ux%u pitch %u", w, h, pitch);

    struct NVRMVramRequest q;
    for (unsigned i = 0; i < sizeof q; i++) ((volatile unsigned char *)&q)[i] = 0;
    q.version = NVRM_VRAM_ABI_VERSION;
    IOReturn ret = a->askFramebufferForScanout(&q, fb);
    if (ret != kIOReturnSuccess) NVIOP_FAIL(kIOReturnNotReady, "framebuffer would not describe its scanout (0x%x)", (unsigned)ret);
    if (!q.width || !q.height) NVIOP_FAIL(kIOReturnNotReady, "scanout geometry is empty (%ux%u)", q.width, q.height);
    if (w != q.width || h != q.height) NVIOP_FAIL(kIOReturnBadArgument, "source %ux%u is not the scanout's %ux%u", w, h, q.width, q.height);

    // Owner-copy first: the panel copies into its own mapping under the lock its stop() also takes, so
    // the destination cannot be unmapped while this frame is in flight. This is the transaction the
    // display pipe actually performs; the kva path below stays as the fallback for a peer without the
    // copy entry.
    static const OSSymbol *symCopy = nullptr;
    if (!symCopy) symCopy = OSSymbol::withCStringNoCopy(NVRM_VRAM_FN_COPY);
    if (symCopy) {
        struct NVRMVramCopyRequest copyReq;
        for (unsigned i = 0; i < sizeof copyReq; i++) ((volatile unsigned char *)&copyReq)[i] = 0;
        copyReq.version = NVRM_VRAM_ABI_VERSION;
        copyReq.src = (const void *)(uintptr_t)src;
        copyReq.srcPitch = pitch;
        copyReq.width = w;
        copyReq.height = h;
        if (fb->callPlatformFunction(symCopy, false, &copyReq, nullptr, nullptr, nullptr) == kIOReturnSuccess) {
            OSAddAtomic64(1, fromRes ? &gCntIopSrcRes : &gCntIopSrcSurf);
            const SInt64 n = OSAddAtomic64(1, &gCntIopOk);
            OSAddAtomic64(1, &gCntIopOkHead[head]);
            ALOG("iop: K6 transaction #%lld (head %u) copied to the panel by owner-copy %ux%u pitch %u",
                 (long long)n, head, w, h, pitch);
            return kIOReturnSuccess;
        }
    }

    if (!q.kva || q.pitch < 4) NVIOP_FAIL(kIOReturnNotReady, "peer offers neither owner-copy nor a scanout mapping (kva %p pitch %u)", q.kva, q.pitch);

    nvAccelIopHome(fb, head);
    const unsigned spr = pitch / 4;
    volatile unsigned int *d = (volatile unsigned int *)q.kva;
    if (!honorCopyFrame32(d, q.actualSize, q.pitch, src, sourceBytes, pitch, w, h))
        NVIOP_FAIL(kIOReturnOverrun, "frame copy rejected: invalid pitches, mapping bounds or overlapping ranges");
    OSAddAtomic64(1, fromRes ? &gCntIopSrcRes : &gCntIopSrcSurf);
    const SInt64 n = OSAddAtomic64(1, &gCntIopOk);
    const SInt64 nh = OSAddAtomic64(1, &gCntIopOkHead[head]);
    unsigned nz = 0, varied = 0; const unsigned first = src[0] & 0xffffffu;
    for (unsigned i = 0; i < 8; i++) for (unsigned j = 0; j < 8; j++) {
        unsigned sx = (w * (2 * j + 1)) / 16; if (sx >= spr) sx = spr - 1;
        const unsigned v = src[(unsigned long)((h * (2 * i + 1)) / 16) * spr + sx] & 0xffffffu;
        if (v) nz++;
        if (v != first) varied++;
    }
    if (!varied) OSAddAtomic64(1, &gCntIopBlank);
    if ((n <= 3 || n == 600 || nh == 0) && gIopK6Logs < 12) {
        OSIncrementAtomic(&gIopK6Logs);
        ALOG("iop: K6 transaction #%lld (head %u #%lld) on the panel: %ux%u pitch %u from %s — 64 samples: nonzero %u varied %u", (long long)n, head, (long long)nh, w, h, pitch,
             fromRes ? "our VRAM resource" : "the IOSurface's memory", nz, varied);
    }
    return kIOReturnSuccess;
}

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
