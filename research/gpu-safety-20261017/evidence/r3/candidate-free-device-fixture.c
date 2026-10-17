/*
 * SPDX-FileCopyrightText: Copyright (c) 2015-2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/* Test only: exact source bodies, teardown dependencies injected. No GPU execution. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned NvU32;
typedef int NvBool;
#define NV_TRUE 1
#define NVKMS_IOCTL_FREE_DEVICE 7
struct nvkms_per_open { int tag; };
struct NvKmsKapiDevice {
 int semaphore,notifier;
 unsigned hKmsDevice,hKmsDisp;
 struct nvkms_per_open *pKmsOpen;
 unsigned gpuId;
 void *pSema;
};
struct NvKmsFreeDeviceParams { struct { unsigned deviceHandle; } request; };
static char order[32];static unsigned pos;
static void mark(char x) { if(pos>=sizeof(order)-1)abort();order[pos++]=x; }
static void nvKmsKapiFreeNisoSurface(struct NvKmsKapiDevice *d,int *p) {
 if(!d||!p)abort();mark(p==&d->semaphore?'S':'N');
}
static NvBool nvkms_ioctl_from_kapi(struct nvkms_per_open *p,unsigned cmd,void *params,size_t size) {
 if(!p||cmd!=NVKMS_IOCTL_FREE_DEVICE||!params||size!=sizeof(struct NvKmsFreeDeviceParams))abort();mark('I');return 1;
}
static void nvkms_close_from_kapi(struct nvkms_per_open *p) { if(!p)abort();mark('C'); }
static void RmFreeDevice(struct NvKmsKapiDevice *d) { if(!d)abort();mark('R'); }
static void nvkms_close_gpu(unsigned id,NvBool flag) { if(id!=42||flag!=NV_TRUE)abort();mark('G'); }
static void nvkms_sema_free(void *p) { if(!p)abort();mark('M'); }
static void nvKmsKapiFree(void *p) { if(!p)abort();mark('F'); }

static void KmsFreeDevice(struct NvKmsKapiDevice *device)
{
    /* Free notifier and semaphore memory */

    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->notifier);

    /* Free NVKMS device */

    if (device->hKmsDevice != 0x0)  {
        struct NvKmsFreeDeviceParams paramsFree = { };

        paramsFree.request.deviceHandle = device->hKmsDevice;

        nvkms_ioctl_from_kapi(device->pKmsOpen,
                              NVKMS_IOCTL_FREE_DEVICE,
                              &paramsFree, sizeof(paramsFree));

        device->hKmsDevice = device->hKmsDisp = 0x0;
    }

    /* Close NVKMS */

    if (device->pKmsOpen != NULL) {
        nvkms_close_from_kapi(device->pKmsOpen);
        device->pKmsOpen = NULL;
    }
}
static void FreeDevice(struct NvKmsKapiDevice *device)
{
    /* AllocateDevice() also reaches this path when its first allocation fails. */
    if (device == NULL) {
        return;
    }

    /* Free NVKMS objects allocated for NvKmsKapiDevice */

    KmsFreeDevice(device);

    /* Free RM objects allocated for NvKmsKapiDevice */

    RmFreeDevice(device);

    /* Lower the reference count of gpu. */

    nvkms_close_gpu(device->gpuId, NV_TRUE /* reset_aware */);

    if (device->pSema != NULL) {
        nvkms_sema_free(device->pSema);
    }

    nvKmsKapiFree(device);
}

int main(int argc,char **argv) {
 if(argc!=2)return 2;
 if(strcmp(argv[1],"null")==0) {
  FreeDevice(NULL);
  if(pos!=0)return 3;
  puts("PASS: actual FreeDevice(NULL) returns before any teardown dependency");return 0;
 }
 struct nvkms_per_open handle={1};
 struct NvKmsKapiDevice d={0};d.gpuId=42;
 if(strcmp(argv[1],"populated")==0) {
  d.hKmsDevice=3;d.hKmsDisp=4;d.pKmsOpen=&handle;d.pSema=&handle;
  FreeDevice(&d);
  if(strcmp(order,"SNICRGMF")||d.hKmsDevice||d.hKmsDisp||d.pKmsOpen)return 4;
  puts("PASS: actual FreeDevice/KmsFreeDevice preserve populated teardown order");return 0;
 }
 if(strcmp(argv[1],"partial")==0) {
  FreeDevice(&d);
  if(strcmp(order,"SNRGF"))return 5;
  puts("PASS: actual FreeDevice/KmsFreeDevice preserve partial allocation teardown order");return 0;
 }
 return 2;
}
