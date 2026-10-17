# 固定输入的关闭调用链源码摘录

仅源码摘录；保留原许可。行号对应完整固定输入，摘录不是编译结果。

## src/nvidia-modeset/kapi/src/nvkms-kapi.c

完整源文件 SHA256：`66437bc38d96d3b4f15546c3e6f7a8c0caccc158b35893c2406f80f2e6e8816b`。

原文件许可头：

```text
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
```

[固定源 L422–L452](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia-modeset/kapi/src/nvkms-kapi.c#L422-L452)

```cpp
422: static void KmsFreeDevice(struct NvKmsKapiDevice *device)
423: {
424:     /* Free notifier and semaphore memory */
425: 
426:     nvKmsKapiFreeNisoSurface(device, &device->semaphore);
427:     nvKmsKapiFreeNisoSurface(device, &device->notifier);
428: 
429:     /* Free NVKMS device */
430: 
431:     if (device->hKmsDevice != 0x0)  {
432:         struct NvKmsFreeDeviceParams paramsFree = { };
433: 
434:         paramsFree.request.deviceHandle = device->hKmsDevice;
435: 
436:         nvkms_ioctl_from_kapi(device->pKmsOpen,
437:                               NVKMS_IOCTL_FREE_DEVICE,
438:                               &paramsFree, sizeof(paramsFree));
439: 
440:         device->hKmsDevice = device->hKmsDisp = 0x0;
441:     }
442: 
443:     /* Close NVKMS */
444: 
445:     if (device->pKmsOpen != NULL) {
446:         nvkms_close_from_kapi(device->pKmsOpen);
447:         device->pKmsOpen = NULL;
448:     }
449: }
450: 
451: /*
452:  * Helper function to allocate NVKMS objects for NvKmsKapiDevice.
```

[固定源 L625–L651](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia-modeset/kapi/src/nvkms-kapi.c#L625-L651)

```cpp
625: static void FreeDevice(struct NvKmsKapiDevice *device)
626: {
627:     /* Free NVKMS objects allocated for NvKmsKapiDevice */
628: 
629:     KmsFreeDevice(device);
630: 
631:     /* Free RM objects allocated for NvKmsKapiDevice */
632: 
633:     RmFreeDevice(device);
634: 
635:     /* Lower the reference count of gpu. */
636: 
637:     nvkms_close_gpu(device->gpuId, NV_TRUE /* reset_aware */);
638: 
639:     if (device->pSema != NULL) {
640:         nvkms_sema_free(device->pSema);
641:     }
642: 
643:     nvKmsKapiFree(device);
644: }
645: 
646: NvBool nvKmsKapiAllocateSystemMemory(struct NvKmsKapiDevice *device,
647:                                      NvU32 hRmHandle,
648:                                      enum NvKmsSurfaceMemoryLayout layout,
649:                                      NvU64 size,
650:                                      enum NvKmsKapiAllocationType type,
651:                                      NvU8 *compressible)
```

[固定源 L3823–L3896](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia-modeset/kapi/src/nvkms-kapi.c#L3823-L3896)

```cpp
3823: /*
3824:  * This executes without the nvkms_lock held. The lock will be grabbed
3825:  * during the kapi dispatching contained in this function.
3826:  */
3827: void nvKmsKapiHandleEventQueueChange
3828: (
3829:     struct NvKmsKapiDevice *device
3830: )
3831: {
3832:     if (device == NULL) {
3833:         return;
3834:     }
3835: 
3836:     /*
3837:      * If the callback is NULL, event interest declaration should be
3838:      * rejected, and no events would be reported.
3839:      */
3840:     nvAssert(device->eventCallback != NULL);
3841: 
3842:     do
3843:     {
3844:         struct NvKmsGetNextEventParams kmsEventParams = { };
3845:         struct NvKmsKapiEvent kapiEvent = { };
3846:         NvBool err = NV_FALSE;
3847: 
3848:         if (!nvkms_ioctl_from_kapi(device->pKmsOpen,
3849:                                    NVKMS_IOCTL_GET_NEXT_EVENT,
3850:                                    &kmsEventParams, sizeof(kmsEventParams))) {
3851:             break;
3852:         }
3853: 
3854:         if (!kmsEventParams.reply.valid) {
3855:             break;
3856:         }
3857: 
3858:         kapiEvent.type = kmsEventParams.reply.event.eventType;
3859: 
3860:         kapiEvent.device = device;
3861:         kapiEvent.privateData = device->privateData;
3862: 
3863:         switch (kmsEventParams.reply.event.eventType) {
3864:             case NVKMS_EVENT_TYPE_DPY_CHANGED:
3865:                 kapiEvent.u.displayChanged.display =
3866:                     nvDpyIdToNvU32(kmsEventParams.
3867:                                    reply.event.u.dpyChanged.dpyId);
3868:                 break;
3869:             case NVKMS_EVENT_TYPE_DYNAMIC_DPY_CONNECTED:
3870:                 kapiEvent.u.dynamicDisplayConnected.display =
3871:                     nvDpyIdToNvU32(kmsEventParams.
3872:                                    reply.event.u.dynamicDpyConnected.dpyId);
3873:                 break;
3874:             case NVKMS_EVENT_TYPE_FLIP_OCCURRED:
3875:                 kapiEvent.u.flipOccurred.head =
3876:                     kmsEventParams.reply.event.u.flipOccurred.head;
3877:                 kapiEvent.u.flipOccurred.layer =
3878:                     kmsEventParams.reply.event.u.flipOccurred.layer;
3879:                 break;
3880:             default:
3881:                 continue;
3882:         }
3883: 
3884:         if (err) {
3885:             nvKmsKapiLogDeviceDebug(
3886:                 device,
3887:                 "Error in conversion from "
3888:                 "NvKmsGetNextEventParams to NvKmsKapiEvent");
3889:             continue;
3890:         }
3891: 
3892:         device->eventCallback(&kapiEvent);
3893: 
3894:     } while(1);
3895: }
3896: 
```

## src/nvidia-modeset/os-interface/include/nvidia-modeset-os-interface.h

完整源文件 SHA256：`817e85a7fc04f9283e372151058261a68f74da1416302c5df160ef2b5dfddace`。

原文件许可头：

```text
/*
 * SPDX-FileCopyrightText: Copyright (c) 2015 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
```

[固定源 L330–L377](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia-modeset/os-interface/include/nvidia-modeset-os-interface.h#L330-L377)

```cpp
330: /*!
331:  * Check if OS supports syncpoints.
332:  */
333: NvBool nvkms_kernel_supports_syncpts(void);
334: 
335: /*!
336:  * Checks whether the fd is associated with an nvidia character device.
337:  */
338: NvBool nvkms_fd_is_nvidia_chardev(int fd);
339: 
340: /*!
341:  * NVKMS interface for kernel space NVKMS clients like KAPI
342:  */
343: 
344: struct nvkms_per_open;
345: 
346: struct nvkms_per_open* nvkms_open_from_kapi
347: (
348:     struct NvKmsKapiDevice *device
349: );
350: 
351: void nvkms_close_from_kapi(struct nvkms_per_open *popen);
352: 
353: NvBool nvkms_ioctl_from_kapi
354: (
355:     struct nvkms_per_open *popen,
356:     NvU32 cmd, void *params_address, const size_t params_size
357: );
358: 
359: /*!
360:  * Like nvkms_ioctl_from_kapi, but return NV_FALSE instead of waiting if the
361:  * power management read lock cannot be acquired.
362:  */
363: NvBool nvkms_ioctl_from_kapi_try_pmlock
364: (
365:     struct nvkms_per_open *popen,
366:     NvU32 cmd, void *params_address, const size_t params_size
367: );
368: 
369: /*!
370:  * APIs for locking.
371:  */
372: 
373: typedef struct nvkms_sema_t nvkms_sema_handle_t;
374: 
375: nvkms_sema_handle_t*
376:      nvkms_sema_alloc    (void);
377: void nvkms_sema_free     (nvkms_sema_handle_t *sema);
```

## src/nvidia-modeset/src/nvkms.c

完整源文件 SHA256：`9378da2e64db847802b6db11133edad506a3f921acdb0f25a721b6e34bd0134e`。

原文件许可头：

```text
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
```

[固定源 L5250–L5316](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia-modeset/src/nvkms.c#L5250-L5316)

```cpp
5250:  * Close callback.
5251:  *
5252:  * \param[in,out]  pOpenVoid    The per-open data, allocated by nvKmsOpen().
5253:  */
5254: void nvKmsClose(void *pOpenVoid)
5255: {
5256:     struct NvKmsPerOpen *pOpen = pOpenVoid;
5257: 
5258:     if (pOpen == NULL) {
5259:         return;
5260:     }
5261: 
5262:     /*
5263:      * First remove the pOpen from global tracking.  Otherwise, assertions can
5264:      * fail in the free paths below -- the assertions check that the object
5265:      * being freed is not tracked by any pOpen.
5266:      */
5267:     nvListDel(&pOpen->perOpenListEntry);
5268: 
5269:     if (pOpen->type == NvKmsPerOpenTypeIoctl) {
5270: 
5271:         struct NvKmsPerOpenEventListEntry *pEntry, *pEntryTmp;
5272:         struct NvKmsPerOpenDev *pOpenDev;
5273:         NvKmsGenericHandle dev;
5274: 
5275:         FOR_ALL_POINTERS_IN_EVO_API_HANDLES(&pOpen->ioctl.devHandles,
5276:                                             pOpenDev, dev) {
5277:             FreeDeviceReference(pOpen, pOpenDev);
5278:         }
5279: 
5280:         nvEvoDestroyApiHandles(&pOpen->ioctl.frameLockHandles);
5281: 
5282:         nvEvoDestroyApiHandles(&pOpen->ioctl.devHandles);
5283: 
5284:         nvListForEachEntry_safe(pEntry, pEntryTmp,
5285:                                 &pOpen->ioctl.eventList, eventListEntry) {
5286:             nvListDel(&pEntry->eventListEntry);
5287:             nvFree(pEntry);
5288:         }
5289: 
5290:         nvListDel(&pOpen->perOpenIoctlListEntry);
5291:     }
5292: 
5293:     if (pOpen->type == NvKmsPerOpenTypeGrantSurface) {
5294:         nvAssert(pOpen->grantSurface.pSurfaceEvo != NULL);
5295:         nvEvoDecrementSurfaceStructRefCnt(pOpen->grantSurface.pSurfaceEvo);
5296:     }
5297: 
5298:     if (pOpen->type == NvKmsPerOpenTypeGrantSwapGroup) {
5299:         nvAssert(pOpen->grantSwapGroup.pSwapGroup != NULL);
5300:         nvHsDecrementSwapGroupRefCnt(pOpen->grantSwapGroup.pSwapGroup);
5301:     }
5302: 
5303:     if (pOpen->type == NvKmsPerOpenTypeUnicastEvent) {
5304:         nvRemoveUnicastEvent(pOpen);
5305:     }
5306: 
5307:     nvFree(pOpen);
5308: }
5309: 
5310: 
5311: /*
5312:  *Frees all references to a device
5313:  */
5314: void nvRevokeDevice(NVDevEvoPtr pDevEvo)
5315: {
5316:     if (pDevEvo == NULL) {
```

[固定源 L5334–L5375](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia-modeset/src/nvkms.c#L5334-L5375)

```cpp
5334: }
5335: 
5336: /*!
5337:  * Open callback.
5338:  *
5339:  * Allocate, initialize, and return an opaque pointer to an NvKmsPerOpen.
5340:  *
5341:  * \return  If successful, return an NvKmsPerOpen pointer.  Otherwise,
5342:  *          return NULL.
5343:  */
5344: void *nvKmsOpen(
5345:     NvU32 pid,
5346:     enum NvKmsClientType clientType,
5347:     nvkms_per_open_handle_t *pOpenKernel)
5348: {
5349:     struct NvKmsPerOpen *pOpen = nvCalloc(1, sizeof(*pOpen));
5350: 
5351:     if (pOpen == NULL) {
5352:         goto fail;
5353:     }
5354: 
5355:     pOpen->pid = pid;
5356:     pOpen->clientType = clientType;
5357:     pOpen->type = NvKmsPerOpenTypeUndefined;
5358:     pOpen->pOpenKernel = pOpenKernel;
5359: 
5360:     nvListAppend(&pOpen->perOpenListEntry, &perOpenList);
5361: 
5362:     return pOpen;
5363: 
5364: fail:
5365:     nvKmsClose(pOpen);
5366:     return NULL;
5367: }
5368: 
5369: extern const char *const pNV_KMS_ID;
5370: 
5371: #if NVKMS_PROCFS_OBJECT_DUMP
5372: 
5373: static const char *ProcFsPerOpenTypeString(
5374:     enum NvKmsPerOpenType type)
5375: {
```

## kexts/NVRM/NVRM.cpp

完整源文件 SHA256：`99a555439bf7cc2295b761b7847cf16ace2fe53ecb95a1ddaf6029d77389f8ce`。

原文件许可头：

```text
/*
 * NullMoth NVIDIA driver for macOS
 * Copyright (c) 2026 NullMoth Systems.
 * SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
 */
```

[固定源 L1658–L1678](https://github.com/nullmoth/nvidia-macos-driver/blob/ac55984c473e746c2a8ebea7ba0913461aa7c393/kexts/NVRM/NVRM.cpp#L1658-L1678)

```cpp
1658:     IOLockLock(gNvClientsLock); nv_pm_open(fPm, fPid); IOLockUnlock(gNvClientsLock);
1659:     if (nv_xnu_chat()) kprintf("NVRM-xnu: client fd %d opened (%s)\n", fFd, fIsCtl ? "ctl" : "device");
1660:     return true;
1661: }
1662: nv_state_t *NVRMUserClient::nvState() { return fIsCtl ? nv_get_ctl_state() : &fOwner->fNv; }
1663: IOReturn NVRMUserClient::clientClose(void)
1664: {
1665:     if (!fCleaned) {
1666:         fCleaned = true;
1667:         if (gNvClientsLock && fFd >= 0) { IOLockLock(gNvClientsLock); gNvClients[fFd] = NULL; nv_pm_close(fPm); IOLockUnlock(gNvClientsLock); }
1668:         if (fKms) { nvkms_xnu_close(fKms); fKms = nullptr; }
1669:         if (fOwner) { NvXnuPmUse pmUse; rm_cleanup_file_private(NULL, nvState(), &fNvfp); }
1670:         if (fMmap.memArea.pRanges) { kern_os_free(fMmap.memArea.pRanges); fMmap.memArea.pRanges = NULL; }
1671:         if (nv_xnu_chat()) kprintf("NVRM-xnu: client fd %d closed\n", fFd);
1672:     }
1673:     terminate();
1674:     return kIOReturnSuccess;
1675: }
1676: IOReturn NVRMUserClient::clientMemoryForType(UInt32 type, IOOptionBits *options, IOMemoryDescriptor **memory)
1677: {
1678:     nv_alloc_mapping_context_t *c = &fMmap;
```

[固定源 L1742–L1779](https://github.com/nullmoth/nvidia-macos-driver/blob/ac55984c473e746c2a8ebea7ba0913461aa7c393/kexts/NVRM/NVRM.cpp#L1742-L1779)

```cpp
1742:     // The session this opens is an NVKMS kernel-space client, and NVKMS trusts a kernel client's embedded pointers
1743:     // (flip heads, LUT ramps, clip lists) as kernel addresses. Nothing the driver ships calls this: the display path
1744:     // reaches NVKMS through its in-kernel API and the Vulkan driver never uses this selector. So it is root-only;
1745:     // an unprivileged caller would otherwise hand NVKMS pointers it dereferences in the kernel.
1746:     if (kauth_getuid() != 0) return kIOReturnNotPrivileged;
1747:     uint32_t cmd = (uint32_t)args->scalarInput[0];
1748:     uint32_t size = args->structureInputDescriptor ? (uint32_t)args->structureInputDescriptor->getLength() : args->structureInputSize;
1749:     if (size == 0 || size > (1u << 20)) return kIOReturnBadArgument;
1750:     if (!me->fKms) { me->fKms = nvkms_xnu_open(me->fPid); if (!me->fKms) { kprintf("NVRM-xnu: nvkms open failed (loaded? pass 2 done?)\n"); return kIOReturnNotReady; } }
1751:     void *buf = kern_os_malloc(size);
1752:     if (!buf) return kIOReturnNoMemory;
1753:     if (args->structureInputDescriptor) {
1754:         if (args->structureInputDescriptor->prepare() != kIOReturnSuccess) { kern_os_free(buf); return kIOReturnVMError; }
1755:         args->structureInputDescriptor->readBytes(0, buf, size);
1756:         args->structureInputDescriptor->complete();
1757:     } else nvu_memcpy(buf, args->structureInput, size);
1758:     int rc = nvkms_xnu_ioctl(me->fKms, cmd, buf, size);
1759:     if (rc) kprintf("NVRM-xnu: nvkms ioctl cmd %u size %u -> FALSE\n", cmd, size);
1760:     if (args->structureOutputDescriptor) {
1761:         if (args->structureOutputDescriptor->prepare() == kIOReturnSuccess) {
1762:             args->structureOutputDescriptor->writeBytes(0, buf, size);
1763:             args->structureOutputDescriptor->complete();
1764:         }
1765:     } else if (args->structureOutput && args->structureOutputSize >= size) {
1766:         nvu_memcpy(args->structureOutput, buf, size);
1767:         args->structureOutputSize = size;
1768:     }
1769:     kern_os_free(buf);
1770:     return rc == 0 ? kIOReturnSuccess : kIOReturnError;
1771: }
1772: IOReturn NVRMUserClient::sKmsEvents(OSObject *target, void *reference, IOExternalMethodArguments *args)
1773: {
1774:     NVRMUserClient *me = OSDynamicCast(NVRMUserClient, target);
1775:     if (!me) return kIOReturnNotAttached;
1776:     if (kauth_getuid() != 0) return kIOReturnNotPrivileged;   // the NVKMS session sKms opens is root-only
1777:     args->scalarOutput[0] = nvkms_xnu_events_available(me->fKms);
1778:     return kIOReturnSuccess;
1779: }
```
