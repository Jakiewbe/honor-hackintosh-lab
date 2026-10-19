/*
 * SPDX-FileCopyrightText: Copyright (c) 2016 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

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

void nvKmsKapiFreeNisoSurface(struct NvKmsKapiDevice *device,
                              struct NvKmsKapiNisoSurface *surface)
{
    if (surface->hKmsHandle != 0) {
        struct NvKmsUnregisterSurfaceParams paramsUnreg = { };
        NvBool status;

        paramsUnreg.request.deviceHandle  = device->hKmsDevice;
        paramsUnreg.request.surfaceHandle = surface->hKmsHandle;

        status = nvkms_ioctl_from_kapi(device->pKmsOpen,
                                       NVKMS_IOCTL_UNREGISTER_SURFACE,
                                       &paramsUnreg, sizeof(paramsUnreg));

        if (!status) {
            nvKmsKapiLogDeviceDebug(
                device,
                "NVKMS_IOCTL_UNREGISTER_SURFACE failed");
        }

        surface->hKmsHandle = 0;
    }

    if (surface->mapped) {
        NV_STATUS status;

        status = nvRmApiUnmapMemory(device->hRmClient,
                                    device->hRmSubDevice,
                                    surface->hRmHandle,
                                    surface->pLinearAddress,
                                    0);

        if (status != NV_OK) {
            nvKmsKapiLogDeviceDebug(
                device,
                "UnmapMemory failed with error code 0x%08x",
                status);
        }

        surface->mapped = NV_FALSE;
    }

    if (surface->hRmHandle != 0) {
        NvU32 status;

        status = nvRmApiFree(device->hRmClient,
                             device->hRmDevice,
                             surface->hRmHandle);

        if (status != NVOS_STATUS_SUCCESS) {
            nvKmsKapiLogDeviceDebug(
                device,
                "RmFree failed with error code 0x%08x",
                status);
        }

        nvFreeUnixRmHandle(&device->handleAllocator, surface->hRmHandle);
        surface->hRmHandle = 0;
    }
}

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
