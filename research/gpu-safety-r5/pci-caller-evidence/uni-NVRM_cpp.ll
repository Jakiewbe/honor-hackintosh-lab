; ModuleID = '/Users/runner/work/_temp/nullmoth-v2.3.3-gpu-safety-r5-candidate/kexts/NVRM/NVRM.cpp'
source_filename = "/Users/runner/work/_temp/nullmoth-v2.3.3-gpu-safety-r5-candidate/kexts/NVRM/NVRM.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx15.5.0"

%struct.kmod_info = type <{ ptr, i32, i32, [64 x i8], [64 x i8], i32, ptr, i64, i64, i64, ptr, ptr }>
%"class.NVRMDisplay::MetaClass" = type { %class.OSMetaClass }
%class.OSMetaClass = type { %class.OSMetaClassBase, ptr, ptr, ptr, i32, i32 }
%class.OSMetaClassBase = type { ptr }
%"class.IOService::MetaClass" = type { %class.OSMetaClass }
%struct.sysctl_oid_list = type { ptr }
%struct.sysctl_oid = type { ptr, %struct.anon, i32, i32, ptr, i32, ptr, ptr, ptr, ptr, i32, i32 }
%struct.anon = type { ptr }
%struct.nv_pm_owner = type { i64, i32, i32, i64, [20 x i8] }
%"class.NVRM::MetaClass" = type { %class.OSMetaClass }
%struct.IOPMPowerState = type { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }
%"class.NVRMUserClient::MetaClass" = type { %class.OSMetaClass }
%"class.IOUserClient::MetaClass" = type { %class.OSMetaClass }
%"class.IOAccelNVRMBridge::MetaClass" = type { %class.OSMetaClass }
%struct.IOExternalMethodDispatch = type { ptr, i32, i32, i32, i32 }
%struct.PE_Video = type { i64, i64, i64, i64, i64, i64, [64 x i8], i64, i64, i8, i8, [2 x i8], i64 }
%struct.nv_aperture_t = type { i64, i64, i32, ptr, ptr }
%struct.MemoryRange = type { i64, i64 }
%struct.IOVirtualRange = type { i64, i64 }
%struct.IORPC = type { ptr, ptr, i32, i32, ptr }

@kmod_info = local_unnamed_addr global %struct.kmod_info <{ ptr null, i32 1, i32 -1, [64 x i8] c"com.nullmoth.NVRM\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [64 x i8] c"0.1\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", i32 -1, ptr null, i64 0, i64 0, i64 0, ptr @_start, ptr @_stop }>, align 4
@_realmain = local_unnamed_addr global ptr null, align 8
@_antimain = local_unnamed_addr global ptr null, align 8
@_kext_apple_cc = local_unnamed_addr global i32 6000, align 4
@_ZN11NVRMDisplay10gMetaClassE = global %"class.NVRMDisplay::MetaClass" zeroinitializer, align 8
@_ZN11NVRMDisplay9metaClassE = local_unnamed_addr constant ptr @_ZN11NVRMDisplay10gMetaClassE, align 8
@_ZN9IOService10gMetaClassE = external global %"class.IOService::MetaClass", align 8
@_ZN11NVRMDisplay10superClassE = local_unnamed_addr constant ptr @_ZN9IOService10gMetaClassE, align 8
@_ZTV11NVRMDisplay = unnamed_addr constant { [269 x ptr] } { [269 x ptr] [ptr null, ptr null, ptr @_ZN11NVRMDisplayD1Ev, ptr @_ZN11NVRMDisplayD0Ev, ptr @_ZNK8OSObject7releaseEi, ptr @_ZNK8OSObject14getRetainCountEv, ptr @_ZNK8OSObject6retainEv, ptr @_ZNK8OSObject7releaseEv, ptr @_ZNK8OSObject9serializeEP11OSSerialize, ptr @_ZNK11NVRMDisplay12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK8OSObject12taggedRetainEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKvi, ptr @_ZN9IOService8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZN8OSObject4initEv, ptr @_ZN9IOService4freeEv, ptr @_ZN8OSObject18_RESERVEDOSObject0Ev, ptr @_ZN8OSObject18_RESERVEDOSObject1Ev, ptr @_ZN8OSObject18_RESERVEDOSObject2Ev, ptr @_ZN8OSObject18_RESERVEDOSObject3Ev, ptr @_ZN8OSObject18_RESERVEDOSObject4Ev, ptr @_ZN8OSObject18_RESERVEDOSObject5Ev, ptr @_ZN8OSObject18_RESERVEDOSObject6Ev, ptr @_ZN8OSObject18_RESERVEDOSObject7Ev, ptr @_ZN8OSObject18_RESERVEDOSObject8Ev, ptr @_ZN8OSObject18_RESERVEDOSObject9Ev, ptr @_ZN8OSObject19_RESERVEDOSObject10Ev, ptr @_ZN8OSObject19_RESERVEDOSObject11Ev, ptr @_ZN8OSObject19_RESERVEDOSObject12Ev, ptr @_ZN8OSObject19_RESERVEDOSObject13Ev, ptr @_ZN8OSObject19_RESERVEDOSObject14Ev, ptr @_ZN8OSObject19_RESERVEDOSObject15Ev, ptr @_ZNK15IORegistryEntry12copyPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry15copyParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14copyChildEntryEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry17runPropertyActionEPFiP8OSObjectPvS2_S2_S2_ES1_S2_S2_S2_S2_, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry0Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry1Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry2Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry3Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry4Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry5Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry6Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry7Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry8Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry9Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry10Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry11Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry12Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry13Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry14Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry15Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry16Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry17Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry18Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry19Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry20Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry21Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry22Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry23Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry24Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry25Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry26Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry27Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry28Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry29Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry30Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry31Ev, ptr @_ZN9IOService4initEP12OSDictionary, ptr @_ZN15IORegistryEntry16setPropertyTableEP12OSDictionary, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSSymbolP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSStringP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcS1_, ptr @_ZN15IORegistryEntry11setPropertyEPKcb, ptr @_ZN15IORegistryEntry11setPropertyEPKcyj, ptr @_ZN15IORegistryEntry11setPropertyEPKcPvj, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSSymbol, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSString, ptr @_ZN15IORegistryEntry14removePropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry11getPropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry12copyPropertyEPKc, ptr @_ZNK15IORegistryEntry24dictionaryWithPropertiesEv, ptr @_ZNK9IOService19serializePropertiesEP11OSSerialize, ptr @_ZN15IORegistryEntry13setPropertiesEP8OSObject, ptr @_ZNK15IORegistryEntry17getParentIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14applyToParentsEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14getParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getChildIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry15applyToChildrenEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry13getChildEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7isChildEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry8isParentEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry7inPlaneEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8getDepthEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry14attachToParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry16detachFromParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry13attachToChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry15detachFromChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry11detachAboveEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry9detachAllEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8copyNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12compareNamesEP8OSObjectPP8OSString, ptr @_ZNK15IORegistryEntry11compareNameEP8OSStringPS1_, ptr @_ZN15IORegistryEntry7setNameEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry7setNameEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry11getLocationEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12copyLocationEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getPathEPcPiPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getPathComponentEPcPiPK15IORegistryPlane, ptr @_ZN15IORegistryEntry13childFromPathEPKcPK15IORegistryPlanePcPi, ptr @_ZN9IOService4initEP15IORegistryEntryPK15IORegistryPlane, ptr @_ZN9IOService16requestTerminateEPS_j, ptr @_ZN9IOService13willTerminateEPS_j, ptr @_ZN9IOService12didTerminateEPS_jPb, ptr @_ZN9IOService15nextIdleTimeoutEyyj, ptr @_ZN9IOService18systemWillShutdownEj, ptr @_ZN9IOService22copyClientWithCategoryEPK8OSSymbol, ptr @_ZN9IOService15configureReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService12updateReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService19_RESERVEDIOService2Ev, ptr @_ZN9IOService19_RESERVEDIOService3Ev, ptr @_ZN9IOService19_RESERVEDIOService4Ev, ptr @_ZN9IOService19_RESERVEDIOService5Ev, ptr @_ZN9IOService19_RESERVEDIOService6Ev, ptr @_ZN9IOService19_RESERVEDIOService7Ev, ptr @_ZN9IOService19_RESERVEDIOService8Ev, ptr @_ZN9IOService19_RESERVEDIOService9Ev, ptr @_ZN9IOService20_RESERVEDIOService10Ev, ptr @_ZN9IOService20_RESERVEDIOService11Ev, ptr @_ZN9IOService20_RESERVEDIOService12Ev, ptr @_ZN9IOService20_RESERVEDIOService13Ev, ptr @_ZN9IOService20_RESERVEDIOService14Ev, ptr @_ZN9IOService20_RESERVEDIOService15Ev, ptr @_ZN9IOService20_RESERVEDIOService16Ev, ptr @_ZN9IOService20_RESERVEDIOService17Ev, ptr @_ZN9IOService20_RESERVEDIOService18Ev, ptr @_ZN9IOService20_RESERVEDIOService19Ev, ptr @_ZN9IOService20_RESERVEDIOService20Ev, ptr @_ZN9IOService20_RESERVEDIOService21Ev, ptr @_ZN9IOService20_RESERVEDIOService22Ev, ptr @_ZN9IOService20_RESERVEDIOService23Ev, ptr @_ZN9IOService20_RESERVEDIOService24Ev, ptr @_ZN9IOService20_RESERVEDIOService25Ev, ptr @_ZN9IOService20_RESERVEDIOService26Ev, ptr @_ZN9IOService20_RESERVEDIOService27Ev, ptr @_ZN9IOService20_RESERVEDIOService28Ev, ptr @_ZN9IOService20_RESERVEDIOService29Ev, ptr @_ZN9IOService20_RESERVEDIOService30Ev, ptr @_ZN9IOService20_RESERVEDIOService31Ev, ptr @_ZN9IOService20_RESERVEDIOService32Ev, ptr @_ZN9IOService20_RESERVEDIOService33Ev, ptr @_ZN9IOService20_RESERVEDIOService34Ev, ptr @_ZN9IOService20_RESERVEDIOService35Ev, ptr @_ZN9IOService20_RESERVEDIOService36Ev, ptr @_ZN9IOService20_RESERVEDIOService37Ev, ptr @_ZN9IOService20_RESERVEDIOService38Ev, ptr @_ZN9IOService20_RESERVEDIOService39Ev, ptr @_ZN9IOService20_RESERVEDIOService40Ev, ptr @_ZN9IOService20_RESERVEDIOService41Ev, ptr @_ZN9IOService20_RESERVEDIOService42Ev, ptr @_ZN9IOService20_RESERVEDIOService43Ev, ptr @_ZN9IOService20_RESERVEDIOService44Ev, ptr @_ZN9IOService20_RESERVEDIOService45Ev, ptr @_ZN9IOService20_RESERVEDIOService46Ev, ptr @_ZN9IOService20_RESERVEDIOService47Ev, ptr @_ZNK9IOService8getStateEv, ptr @_ZN9IOService15registerServiceEj, ptr @_ZN9IOService5probeEPS_Pi, ptr @_ZN9IOService5startEPS_, ptr @_ZN9IOService4stopEPS_, ptr @_ZN9IOService4openEPS_jPv, ptr @_ZN9IOService5closeEPS_j, ptr @_ZNK9IOService6isOpenEPKS_, ptr @_ZN9IOService10handleOpenEPS_jPv, ptr @_ZN9IOService11handleCloseEPS_j, ptr @_ZNK9IOService12handleIsOpenEPKS_, ptr @_ZN9IOService9terminateEj, ptr @_ZN9IOService8finalizeEj, ptr @_ZN9IOService18lockForArbitrationEb, ptr @_ZN9IOService20unlockForArbitrationEv, ptr @_ZN9IOService15terminateClientEPS_j, ptr @_ZN9IOService12getBusyStateEv, ptr @_ZN9IOService10adjustBusyEi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionaryPi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionary, ptr @_ZN9IOService13matchLocationEPS_, ptr @_ZN9IOService17addNeededResourceEPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPK8OSString, ptr @_ZN9IOService17comparePropertiesEP12OSDictionaryP12OSCollection, ptr @_ZN9IOService6attachEPS_, ptr @_ZN9IOService6detachEPS_, ptr @_ZNK9IOService11getProviderEv, ptr @_ZNK9IOService11getWorkLoopEv, ptr @_ZNK9IOService19getProviderIteratorEv, ptr @_ZNK9IOService23getOpenProviderIteratorEv, ptr @_ZNK9IOService9getClientEv, ptr @_ZNK9IOService17getClientIteratorEv, ptr @_ZNK9IOService21getOpenClientIteratorEv, ptr @_ZN9IOService20callPlatformFunctionEPK8OSSymbolbPvS3_S3_S3_, ptr @_ZN9IOService20callPlatformFunctionEPKcbPvS2_S2_S2_, ptr @_ZN9IOService12getResourcesEv, ptr @_ZN9IOService20getDeviceMemoryCountEv, ptr @_ZN9IOService24getDeviceMemoryWithIndexEj, ptr @_ZN9IOService24mapDeviceMemoryWithIndexEjj, ptr @_ZN9IOService15getDeviceMemoryEv, ptr @_ZN9IOService15setDeviceMemoryEP7OSArray, ptr @_ZN9IOService17registerInterruptEiP8OSObjectPFvS1_PvPS_iES2_, ptr @_ZN9IOService19unregisterInterruptEi, ptr @_ZN9IOService16getInterruptTypeEiPi, ptr @_ZN9IOService15enableInterruptEi, ptr @_ZN9IOService16disableInterruptEi, ptr @_ZN9IOService14causeInterruptEi, ptr @_ZN9IOService12requestProbeEj, ptr @_ZN9IOService7messageEjPS_Pv, ptr @_ZN9IOService13messageClientEjP8OSObjectPvm, ptr @_ZN9IOService14messageClientsEjPvm, ptr @_ZN9IOService16registerInterestEPK8OSSymbolPFiPvS3_jPS_S3_mES3_S3_, ptr @_ZN9IOService16applyToProvidersEPFvPS_PvES1_, ptr @_ZN9IOService14applyToClientsEPFvPS_PvES1_, ptr @_ZN9IOService17applyToInterestedEPK8OSSymbolPFvP8OSObjectPvES5_, ptr @_ZN9IOService23acknowledgeNotificationEPvj, ptr @_ZN9IOService13newUserClientEP4taskPvjP12OSDictionaryPP12IOUserClient, ptr @_ZN9IOService13newUserClientEP4taskPvjPP12IOUserClient, ptr @_ZN9IOService16stringFromReturnEi, ptr @_ZN9IOService15errnoFromReturnEi, ptr @_ZN9IOService6PMinitEv, ptr @_ZN9IOService6PMstopEv, ptr @_ZN9IOService10joinPMtreeEPS_, ptr @_ZN9IOService19registerPowerDriverEPS_P14IOPMPowerStatem, ptr @_ZN9IOService23requestPowerDomainStateEmP17IOPowerConnectionm, ptr @_ZN9IOService14activityTickleEmm, ptr @_ZN9IOService17setAggressivenessEmm, ptr @_ZN9IOService17getAggressivenessEmPm, ptr @_ZN9IOService13addPowerChildEPS_, ptr @_ZN9IOService16removePowerChildEP17IOPowerConnection, ptr @_ZN9IOService18setIdleTimerPeriodEm, ptr @_ZN9IOService13setPowerStateEmPS_, ptr @_ZN9IOService27maxCapabilityForDomainStateEm, ptr @_ZN9IOService31initialPowerStateForDomainStateEm, ptr @_ZN9IOService24powerStateForDomainStateEm, ptr @_ZN9IOService22powerStateWillChangeToEmmPS_, ptr @_ZN9IOService21powerStateDidChangeToEmmPS_, ptr @_ZN9IOService13askChangeDownEm, ptr @_ZN9IOService14tellChangeDownEm, ptr @_ZN9IOService16tellNoChangeDownEm, ptr @_ZN9IOService12tellChangeUpEm, ptr @_ZN9IOService16allowPowerChangeEm, ptr @_ZN9IOService17cancelPowerChangeEm, ptr @_ZN9IOService15powerChangeDoneEm, ptr null] }, align 8
@.str = private unnamed_addr constant [12 x i8] c"NVRMDisplay\00", align 1
@_ZTVN11NVRMDisplay9MetaClassE = unnamed_addr constant { [29 x ptr] } { [29 x ptr] [ptr null, ptr null, ptr @_ZN11NVRMDisplay9MetaClassD1Ev, ptr @_ZN11NVRMDisplay9MetaClassD0Ev, ptr @_ZNK11OSMetaClass7releaseEi, ptr @_ZNK11OSMetaClass14getRetainCountEv, ptr @_ZNK11OSMetaClass6retainEv, ptr @_ZNK11OSMetaClass7releaseEv, ptr @_ZNK11OSMetaClass9serializeEP11OSSerialize, ptr @_ZNK11OSMetaClass12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK11OSMetaClass12taggedRetainEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKvi, ptr @_ZN15OSMetaClassBase8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZNK11NVRMDisplay9MetaClass5allocEv, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass1Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass2Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass3Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass4Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass5Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass6Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass7Ev, ptr null] }, align 8
@sysctl__debug_children = external global %struct.sysctl_oid_list, align 8
@_ZL11gNvIsrCount = internal global i64 0, align 8
@.str.1 = private unnamed_addr constant [15 x i8] c"nvrm_isr_count\00", align 1
@.str.2 = private unnamed_addr constant [2 x i8] c"Q\00", align 1
@.str.3 = private unnamed_addr constant [15 x i8] c"GPU MSIs taken\00", align 1
@sysctl__debug_nvrm_isr_count = global %struct.sysctl_oid { ptr @sysctl__debug_children, %struct.anon zeroinitializer, i32 -1, i32 -2143289340, ptr @_ZL11gNvIsrCount, i32 0, ptr @.str.1, ptr @sysctl_handle_quad, ptr @.str.2, ptr @.str.3, i32 1, i32 0 }, align 8
@_ZL13gNvIsrHandled = internal global i64 0, align 8
@.str.4 = private unnamed_addr constant [17 x i8] c"nvrm_isr_handled\00", align 1
@.str.5 = private unnamed_addr constant [20 x i8] c"GPU MSIs RM claimed\00", align 1
@sysctl__debug_nvrm_isr_handled = global %struct.sysctl_oid { ptr @sysctl__debug_children, %struct.anon zeroinitializer, i32 -1, i32 -2143289340, ptr @_ZL13gNvIsrHandled, i32 0, ptr @.str.4, ptr @sysctl_handle_quad, ptr @.str.2, ptr @.str.5, i32 1, i32 0 }, align 8
@_ZL11gNvEvtPosts = internal global i64 0, align 8
@.str.6 = private unnamed_addr constant [15 x i8] c"nvrm_evt_posts\00", align 1
@.str.7 = private unnamed_addr constant [33 x i8] c"RM events posted to user clients\00", align 1
@sysctl__debug_nvrm_evt_posts = global %struct.sysctl_oid { ptr @sysctl__debug_children, %struct.anon zeroinitializer, i32 -1, i32 -2143289340, ptr @_ZL11gNvEvtPosts, i32 0, ptr @.str.6, ptr @sysctl_handle_quad, ptr @.str.2, ptr @.str.7, i32 1, i32 0 }, align 8
@_ZL11gNvEvtWaits = internal global i64 0, align 8
@.str.8 = private unnamed_addr constant [15 x i8] c"nvrm_evt_waits\00", align 1
@.str.9 = private unnamed_addr constant [17 x i8] c"user event waits\00", align 1
@sysctl__debug_nvrm_evt_waits = global %struct.sysctl_oid { ptr @sysctl__debug_children, %struct.anon zeroinitializer, i32 -1, i32 -2143289340, ptr @_ZL11gNvEvtWaits, i32 0, ptr @.str.8, ptr @sysctl_handle_quad, ptr @.str.2, ptr @.str.9, i32 1, i32 0 }, align 8
@_ZL11gNvPmWaited = internal global i64 0, align 8
@.str.10 = private unnamed_addr constant [15 x i8] c"nvrm_pm_waited\00", align 1
@.str.11 = private unnamed_addr constant [38 x i8] c"RM calls that waited for a GPU resume\00", align 1
@sysctl__debug_nvrm_pm_waited = global %struct.sysctl_oid { ptr @sysctl__debug_children, %struct.anon zeroinitializer, i32 -1, i32 -2143289340, ptr @_ZL11gNvPmWaited, i32 0, ptr @.str.10, ptr @sysctl_handle_quad, ptr @.str.2, ptr @.str.11, i32 1, i32 0 }, align 8
@_ZL19gNvKmsCloseDeferred = internal global i64 0, align 8
@.str.12 = private unnamed_addr constant [24 x i8] c"nvrm_kms_close_deferred\00", align 1
@.str.13 = private unnamed_addr constant [44 x i8] c"bridge closes waiting for the GPU to return\00", align 1
@sysctl__debug_nvrm_kms_close_deferred = global %struct.sysctl_oid { ptr @sysctl__debug_children, %struct.anon zeroinitializer, i32 -1, i32 -2143289340, ptr @_ZL19gNvKmsCloseDeferred, i32 0, ptr @.str.12, ptr @sysctl_handle_quad, ptr @.str.2, ptr @.str.13, i32 1, i32 0 }, align 8
@_ZL9gNvPmGate = internal unnamed_addr global ptr null, align 8
@_ZL10gNvPmOwner = internal unnamed_addr global ptr null, align 8
@_ZL11gNvPmClosed = internal global i8 0, align 1
@_ZL10gNvPmUsers = internal global i32 0, align 4
@_ZL14gNvClientsLock = internal unnamed_addr global ptr null, align 8
@_ZL8gNvPmTab = internal global [256 x %struct.nv_pm_owner] zeroinitializer, align 16
@_ZL10gNvClients = internal unnamed_addr global [32768 x ptr] zeroinitializer, align 16
@_ZN14NVRMUserClient9metaClassE = local_unnamed_addr constant ptr @_ZN14NVRMUserClient10gMetaClassE, align 8
@_ZN4NVRM10gMetaClassE = global %"class.NVRM::MetaClass" zeroinitializer, align 8
@_ZN4NVRM9metaClassE = local_unnamed_addr constant ptr @_ZN4NVRM10gMetaClassE, align 8
@_ZN4NVRM10superClassE = local_unnamed_addr constant ptr @_ZN9IOService10gMetaClassE, align 8
@_ZTV4NVRM = unnamed_addr constant { [269 x ptr] } { [269 x ptr] [ptr null, ptr null, ptr @_ZN4NVRMD1Ev, ptr @_ZN4NVRMD0Ev, ptr @_ZNK8OSObject7releaseEi, ptr @_ZNK8OSObject14getRetainCountEv, ptr @_ZNK8OSObject6retainEv, ptr @_ZNK8OSObject7releaseEv, ptr @_ZNK8OSObject9serializeEP11OSSerialize, ptr @_ZNK4NVRM12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK8OSObject12taggedRetainEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKvi, ptr @_ZN9IOService8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZN8OSObject4initEv, ptr @_ZN9IOService4freeEv, ptr @_ZN8OSObject18_RESERVEDOSObject0Ev, ptr @_ZN8OSObject18_RESERVEDOSObject1Ev, ptr @_ZN8OSObject18_RESERVEDOSObject2Ev, ptr @_ZN8OSObject18_RESERVEDOSObject3Ev, ptr @_ZN8OSObject18_RESERVEDOSObject4Ev, ptr @_ZN8OSObject18_RESERVEDOSObject5Ev, ptr @_ZN8OSObject18_RESERVEDOSObject6Ev, ptr @_ZN8OSObject18_RESERVEDOSObject7Ev, ptr @_ZN8OSObject18_RESERVEDOSObject8Ev, ptr @_ZN8OSObject18_RESERVEDOSObject9Ev, ptr @_ZN8OSObject19_RESERVEDOSObject10Ev, ptr @_ZN8OSObject19_RESERVEDOSObject11Ev, ptr @_ZN8OSObject19_RESERVEDOSObject12Ev, ptr @_ZN8OSObject19_RESERVEDOSObject13Ev, ptr @_ZN8OSObject19_RESERVEDOSObject14Ev, ptr @_ZN8OSObject19_RESERVEDOSObject15Ev, ptr @_ZNK15IORegistryEntry12copyPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry15copyParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14copyChildEntryEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry17runPropertyActionEPFiP8OSObjectPvS2_S2_S2_ES1_S2_S2_S2_S2_, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry0Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry1Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry2Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry3Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry4Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry5Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry6Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry7Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry8Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry9Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry10Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry11Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry12Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry13Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry14Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry15Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry16Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry17Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry18Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry19Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry20Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry21Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry22Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry23Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry24Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry25Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry26Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry27Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry28Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry29Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry30Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry31Ev, ptr @_ZN9IOService4initEP12OSDictionary, ptr @_ZN15IORegistryEntry16setPropertyTableEP12OSDictionary, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSSymbolP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSStringP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcS1_, ptr @_ZN15IORegistryEntry11setPropertyEPKcb, ptr @_ZN15IORegistryEntry11setPropertyEPKcyj, ptr @_ZN15IORegistryEntry11setPropertyEPKcPvj, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSSymbol, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSString, ptr @_ZN15IORegistryEntry14removePropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry11getPropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry12copyPropertyEPKc, ptr @_ZNK15IORegistryEntry24dictionaryWithPropertiesEv, ptr @_ZNK9IOService19serializePropertiesEP11OSSerialize, ptr @_ZN15IORegistryEntry13setPropertiesEP8OSObject, ptr @_ZNK15IORegistryEntry17getParentIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14applyToParentsEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14getParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getChildIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry15applyToChildrenEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry13getChildEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7isChildEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry8isParentEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry7inPlaneEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8getDepthEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry14attachToParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry16detachFromParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry13attachToChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry15detachFromChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry11detachAboveEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry9detachAllEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8copyNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12compareNamesEP8OSObjectPP8OSString, ptr @_ZNK15IORegistryEntry11compareNameEP8OSStringPS1_, ptr @_ZN15IORegistryEntry7setNameEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry7setNameEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry11getLocationEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12copyLocationEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getPathEPcPiPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getPathComponentEPcPiPK15IORegistryPlane, ptr @_ZN15IORegistryEntry13childFromPathEPKcPK15IORegistryPlanePcPi, ptr @_ZN9IOService4initEP15IORegistryEntryPK15IORegistryPlane, ptr @_ZN9IOService16requestTerminateEPS_j, ptr @_ZN9IOService13willTerminateEPS_j, ptr @_ZN9IOService12didTerminateEPS_jPb, ptr @_ZN9IOService15nextIdleTimeoutEyyj, ptr @_ZN9IOService18systemWillShutdownEj, ptr @_ZN9IOService22copyClientWithCategoryEPK8OSSymbol, ptr @_ZN9IOService15configureReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService12updateReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService19_RESERVEDIOService2Ev, ptr @_ZN9IOService19_RESERVEDIOService3Ev, ptr @_ZN9IOService19_RESERVEDIOService4Ev, ptr @_ZN9IOService19_RESERVEDIOService5Ev, ptr @_ZN9IOService19_RESERVEDIOService6Ev, ptr @_ZN9IOService19_RESERVEDIOService7Ev, ptr @_ZN9IOService19_RESERVEDIOService8Ev, ptr @_ZN9IOService19_RESERVEDIOService9Ev, ptr @_ZN9IOService20_RESERVEDIOService10Ev, ptr @_ZN9IOService20_RESERVEDIOService11Ev, ptr @_ZN9IOService20_RESERVEDIOService12Ev, ptr @_ZN9IOService20_RESERVEDIOService13Ev, ptr @_ZN9IOService20_RESERVEDIOService14Ev, ptr @_ZN9IOService20_RESERVEDIOService15Ev, ptr @_ZN9IOService20_RESERVEDIOService16Ev, ptr @_ZN9IOService20_RESERVEDIOService17Ev, ptr @_ZN9IOService20_RESERVEDIOService18Ev, ptr @_ZN9IOService20_RESERVEDIOService19Ev, ptr @_ZN9IOService20_RESERVEDIOService20Ev, ptr @_ZN9IOService20_RESERVEDIOService21Ev, ptr @_ZN9IOService20_RESERVEDIOService22Ev, ptr @_ZN9IOService20_RESERVEDIOService23Ev, ptr @_ZN9IOService20_RESERVEDIOService24Ev, ptr @_ZN9IOService20_RESERVEDIOService25Ev, ptr @_ZN9IOService20_RESERVEDIOService26Ev, ptr @_ZN9IOService20_RESERVEDIOService27Ev, ptr @_ZN9IOService20_RESERVEDIOService28Ev, ptr @_ZN9IOService20_RESERVEDIOService29Ev, ptr @_ZN9IOService20_RESERVEDIOService30Ev, ptr @_ZN9IOService20_RESERVEDIOService31Ev, ptr @_ZN9IOService20_RESERVEDIOService32Ev, ptr @_ZN9IOService20_RESERVEDIOService33Ev, ptr @_ZN9IOService20_RESERVEDIOService34Ev, ptr @_ZN9IOService20_RESERVEDIOService35Ev, ptr @_ZN9IOService20_RESERVEDIOService36Ev, ptr @_ZN9IOService20_RESERVEDIOService37Ev, ptr @_ZN9IOService20_RESERVEDIOService38Ev, ptr @_ZN9IOService20_RESERVEDIOService39Ev, ptr @_ZN9IOService20_RESERVEDIOService40Ev, ptr @_ZN9IOService20_RESERVEDIOService41Ev, ptr @_ZN9IOService20_RESERVEDIOService42Ev, ptr @_ZN9IOService20_RESERVEDIOService43Ev, ptr @_ZN9IOService20_RESERVEDIOService44Ev, ptr @_ZN9IOService20_RESERVEDIOService45Ev, ptr @_ZN9IOService20_RESERVEDIOService46Ev, ptr @_ZN9IOService20_RESERVEDIOService47Ev, ptr @_ZNK9IOService8getStateEv, ptr @_ZN9IOService15registerServiceEj, ptr @_ZN4NVRM5probeEP9IOServicePi, ptr @_ZN4NVRM5startEP9IOService, ptr @_ZN4NVRM4stopEP9IOService, ptr @_ZN9IOService4openEPS_jPv, ptr @_ZN9IOService5closeEPS_j, ptr @_ZNK9IOService6isOpenEPKS_, ptr @_ZN9IOService10handleOpenEPS_jPv, ptr @_ZN9IOService11handleCloseEPS_j, ptr @_ZNK9IOService12handleIsOpenEPKS_, ptr @_ZN9IOService9terminateEj, ptr @_ZN9IOService8finalizeEj, ptr @_ZN9IOService18lockForArbitrationEb, ptr @_ZN9IOService20unlockForArbitrationEv, ptr @_ZN9IOService15terminateClientEPS_j, ptr @_ZN9IOService12getBusyStateEv, ptr @_ZN9IOService10adjustBusyEi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionaryPi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionary, ptr @_ZN9IOService13matchLocationEPS_, ptr @_ZN9IOService17addNeededResourceEPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPK8OSString, ptr @_ZN9IOService17comparePropertiesEP12OSDictionaryP12OSCollection, ptr @_ZN9IOService6attachEPS_, ptr @_ZN9IOService6detachEPS_, ptr @_ZNK9IOService11getProviderEv, ptr @_ZNK9IOService11getWorkLoopEv, ptr @_ZNK9IOService19getProviderIteratorEv, ptr @_ZNK9IOService23getOpenProviderIteratorEv, ptr @_ZNK9IOService9getClientEv, ptr @_ZNK9IOService17getClientIteratorEv, ptr @_ZNK9IOService21getOpenClientIteratorEv, ptr @_ZN4NVRM20callPlatformFunctionEPK8OSSymbolbPvS3_S3_S3_, ptr @_ZN9IOService20callPlatformFunctionEPKcbPvS2_S2_S2_, ptr @_ZN9IOService12getResourcesEv, ptr @_ZN9IOService20getDeviceMemoryCountEv, ptr @_ZN9IOService24getDeviceMemoryWithIndexEj, ptr @_ZN9IOService24mapDeviceMemoryWithIndexEjj, ptr @_ZN9IOService15getDeviceMemoryEv, ptr @_ZN9IOService15setDeviceMemoryEP7OSArray, ptr @_ZN9IOService17registerInterruptEiP8OSObjectPFvS1_PvPS_iES2_, ptr @_ZN9IOService19unregisterInterruptEi, ptr @_ZN9IOService16getInterruptTypeEiPi, ptr @_ZN9IOService15enableInterruptEi, ptr @_ZN9IOService16disableInterruptEi, ptr @_ZN9IOService14causeInterruptEi, ptr @_ZN9IOService12requestProbeEj, ptr @_ZN9IOService7messageEjPS_Pv, ptr @_ZN9IOService13messageClientEjP8OSObjectPvm, ptr @_ZN9IOService14messageClientsEjPvm, ptr @_ZN9IOService16registerInterestEPK8OSSymbolPFiPvS3_jPS_S3_mES3_S3_, ptr @_ZN9IOService16applyToProvidersEPFvPS_PvES1_, ptr @_ZN9IOService14applyToClientsEPFvPS_PvES1_, ptr @_ZN9IOService17applyToInterestedEPK8OSSymbolPFvP8OSObjectPvES5_, ptr @_ZN9IOService23acknowledgeNotificationEPvj, ptr @_ZN9IOService13newUserClientEP4taskPvjP12OSDictionaryPP12IOUserClient, ptr @_ZN9IOService13newUserClientEP4taskPvjPP12IOUserClient, ptr @_ZN9IOService16stringFromReturnEi, ptr @_ZN9IOService15errnoFromReturnEi, ptr @_ZN9IOService6PMinitEv, ptr @_ZN9IOService6PMstopEv, ptr @_ZN9IOService10joinPMtreeEPS_, ptr @_ZN9IOService19registerPowerDriverEPS_P14IOPMPowerStatem, ptr @_ZN9IOService23requestPowerDomainStateEmP17IOPowerConnectionm, ptr @_ZN9IOService14activityTickleEmm, ptr @_ZN9IOService17setAggressivenessEmm, ptr @_ZN9IOService17getAggressivenessEmPm, ptr @_ZN9IOService13addPowerChildEPS_, ptr @_ZN9IOService16removePowerChildEP17IOPowerConnection, ptr @_ZN9IOService18setIdleTimerPeriodEm, ptr @_ZN4NVRM13setPowerStateEmP9IOService, ptr @_ZN9IOService27maxCapabilityForDomainStateEm, ptr @_ZN9IOService31initialPowerStateForDomainStateEm, ptr @_ZN9IOService24powerStateForDomainStateEm, ptr @_ZN9IOService22powerStateWillChangeToEmmPS_, ptr @_ZN9IOService21powerStateDidChangeToEmmPS_, ptr @_ZN9IOService13askChangeDownEm, ptr @_ZN9IOService14tellChangeDownEm, ptr @_ZN9IOService16tellNoChangeDownEm, ptr @_ZN9IOService12tellChangeUpEm, ptr @_ZN9IOService16allowPowerChangeEm, ptr @_ZN9IOService17cancelPowerChangeEm, ptr @_ZN9IOService15powerChangeDoneEm, ptr null] }, align 8
@.str.15 = private unnamed_addr constant [5 x i8] c"NVRM\00", align 1
@_ZTVN4NVRM9MetaClassE = unnamed_addr constant { [29 x ptr] } { [29 x ptr] [ptr null, ptr null, ptr @_ZN4NVRM9MetaClassD1Ev, ptr @_ZN4NVRM9MetaClassD0Ev, ptr @_ZNK11OSMetaClass7releaseEi, ptr @_ZNK11OSMetaClass14getRetainCountEv, ptr @_ZNK11OSMetaClass6retainEv, ptr @_ZNK11OSMetaClass7releaseEv, ptr @_ZNK11OSMetaClass9serializeEP11OSSerialize, ptr @_ZNK11OSMetaClass12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK11OSMetaClass12taggedRetainEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKvi, ptr @_ZN15OSMetaClassBase8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZNK4NVRM9MetaClass5allocEv, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass1Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass2Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass3Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass4Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass5Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass6Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass7Ev, ptr null] }, align 8
@_ZTV9IOService = external unnamed_addr constant { [269 x ptr] }, align 8
@_ZN11IOPCIDevice9metaClassE = external local_unnamed_addr constant ptr, align 8
@.str.16 = private unnamed_addr constant [63 x i8] c"NVRM-xnu: probe %04x:%04x class %02x.%02x subsystem %04x:%04x\0A\00", align 1
@.str.17 = private unnamed_addr constant [73 x i8] c"NVRM-xnu: rm_is_supported_pci_device says NO \E2\80\94 not claiming %04x:%04x\0A\00", align 1
@.str.18 = private unnamed_addr constant [66 x i8] c"NVRM-xnu: rm_is_supported_pci_device OK; RM names %04x:%04x \22%s\22\0A\00", align 1
@.str.19 = private unnamed_addr constant [7 x i8] c"(null)\00", align 1
@.str.20 = private unnamed_addr constant [10 x i8] c"-nvrmnopm\00", align 1
@.str.21 = private unnamed_addr constant [59 x i8] c"NVRM-xnu: PM gate allocation failed; driver start refused\0A\00", align 1
@_ZL12gNVRMService = internal unnamed_addr global ptr null, align 8
@_ZZN4NVRM5startEP9IOServiceE9sysctlsUp = internal unnamed_addr global i1 false, align 1
@.str.22 = private unnamed_addr constant [6 x i8] c"model\00", align 1
@.str.23 = private unnamed_addr constant [62 x i8] c"NVRM-xnu: published model=\22%s\22 from RM's released-chip table\0A\00", align 1
@.str.24 = private unnamed_addr constant [104 x i8] c"NVRM-xnu: RM cannot name device 0x%04x (subsystem %04x:%04x) - publishing no model rather than a guess\0A\00", align 1
@.str.25 = private unnamed_addr constant [43 x i8] c"NVRM-xnu: armed on %02x:%02x.%d %04x:%04x\0A\00", align 1
@.str.26 = private unnamed_addr constant [13 x i8] c"nvrm-claimed\00", align 1
@kOSBooleanTrue = external local_unnamed_addr constant ptr, align 8
@.str.27 = private unnamed_addr constant [30 x i8] c"NVRM-xnu: IOLockAlloc FAILED\0A\00", align 1
@.str.28 = private unnamed_addr constant [11 x i8] c"nvrmsettle\00", align 1
@.str.29 = private unnamed_addr constant [10 x i8] c"-nvrmnogo\00", align 1
@.str.30 = private unnamed_addr constant [12 x i8] c"nvrm-autogo\00", align 1
@.str.31 = private unnamed_addr constant [16 x i8] c"off (-nvrmnogo)\00", align 1
@.str.32 = private unnamed_addr constant [67 x i8] c"NVRM-xnu: auto-go OFF (-nvrmnogo): idle until `nvrmctl go <pass>`\0A\00", align 1
@.str.33 = private unnamed_addr constant [15 x i8] c"nvrm-boot-hold\00", align 1
@.str.34 = private unnamed_addr constant [8 x i8] c"holding\00", align 1
@.str.35 = private unnamed_addr constant [29 x i8] c"no cap timer \E2\80\94 not holding\00", align 1
@.str.36 = private unnamed_addr constant [22 x i8] c"nvrm-autogo-settle-ms\00", align 1
@.str.37 = private unnamed_addr constant [10 x i8] c"scheduled\00", align 1
@.str.38 = private unnamed_addr constant [130 x i8] c"NVRM-xnu: auto-go: go(2) in %u ms on its own thread (BAR1 %s); registry held busy until the display is armed (cap settle + 40 s)\0A\00", align 1
@.str.39 = private unnamed_addr constant [27 x i8] c"placed outside the console\00", align 1
@.str.40 = private unnamed_addr constant [11 x i8] c"not placed\00", align 1
@.str.41 = private unnamed_addr constant [27 x i8] c"kernel_thread_start FAILED\00", align 1
@.str.42 = private unnamed_addr constant [68 x i8] c"NVRM-xnu: auto-go: kernel_thread_start FAILED \E2\80\94 idle until asked\0A\00", align 1
@.str.43 = private unnamed_addr constant [18 x i8] c"no auto-go thread\00", align 1
@_ZZN4NVRM5startEP9IOServiceE16kNvrmPowerStates = internal global [2 x %struct.IOPMPowerState] [%struct.IOPMPowerState { i64 1, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0 }, %struct.IOPMPowerState { i64 1, i64 32770, i64 2, i64 2, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0 }], align 16
@.str.44 = private unnamed_addr constant [8 x i8] c"nvrm-pm\00", align 1
@.str.45 = private unnamed_addr constant [16 x i8] c"off (-nvrmnopm)\00", align 1
@.str.46 = private unnamed_addr constant [76 x i8] c"NVRM-xnu: power management OFF (-nvrmnopm): system sleep will lose the GPU\0A\00", align 1
@.str.47 = private unnamed_addr constant [8 x i8] c"running\00", align 1
@.str.48 = private unnamed_addr constant [99 x i8] c"NVRM-xnu: power management: joined the power tree under %s (sleep = RM standby, wake = RM resume)\0A\00", align 1
@.str.49 = private unnamed_addr constant [18 x i8] c"-nvrmnobootscreen\00", align 1
@.str.50 = private unnamed_addr constant [57 x i8] c"NVRM-xnu: boot screen: snapshot OFF (-nvrmnobootscreen)\0A\00", align 1
@.str.51 = private unnamed_addr constant [101 x i8] c"NVRM-xnu: boot screen: no 32-bit console to copy (depth %lu %lux%lu) \E2\80\94 the takeover will be black\0A\00", align 1
@.str.52 = private unnamed_addr constant [64 x i8] c"NVRM-xnu: boot screen: %llu B is not a console \E2\80\94 not copying\0A\00", align 1
@kernel_task = external local_unnamed_addr global ptr, align 8
@page_size = external local_unnamed_addr global i64, align 8
@.str.53 = private unnamed_addr constant [57 x i8] c"NVRM-xnu: boot screen: map %p buffer %p \E2\80\94 not copying\0A\00", align 1
@.str.54 = private unnamed_addr constant [94 x i8] c"NVRM-xnu: boot screen: copied %ux%u pitch %u (%llu KB) from the console at 0x%llx in %llu ms\0A\00", align 1
@.str.55 = private unnamed_addr constant [15 x i8] c"-nvkmsnosmooth\00", align 1
@.str.56 = private unnamed_addr constant [48 x i8] c"NVRM-xnu: smooth takeover OFF (-nvkmsnosmooth)\0A\00", align 1
@_ZL11gSmoothHead = internal unnamed_addr global i32 -1, align 4
@_ZL11gSmoothPclk = internal unnamed_addr global i32 0, align 4
@_ZL9gSmoothHt = internal unnamed_addr global i32 0, align 4
@_ZL9gSmoothVt = internal unnamed_addr global i32 0, align 4
@.str.57 = private unnamed_addr constant [58 x i8] c"NVRM-xnu: boot raster: BAR0 too small (%llu) \E2\80\94 unknown\0A\00", align 1
@.str.58 = private unnamed_addr constant [52 x i8] c"NVRM-xnu: boot raster: BAR0 map failed \E2\80\94 unknown\0A\00", align 1
@.str.59 = private unnamed_addr constant [75 x i8] c"NVRM-xnu: boot raster: head %u vline reads 0x%08x (PRI error) \E2\80\94 unknown\0A\00", align 1
@.str.60 = private unnamed_addr constant [126 x i8] c"NVRM-xnu: boot raster: head %u vline wraps %u moves %u max %u -> %u.%03u Hz %s | armed raster %ux%u pclk %u Hz -> %u.%03u Hz\0A\00", align 1
@.str.61 = private unnamed_addr constant [9 x i8] c"MEASURED\00", align 1
@.str.62 = private unnamed_addr constant [24 x i8] c"(not running / unknown)\00", align 1
@.str.63 = private unnamed_addr constant [19 x i8] c"%shead%u %u.%03uHz\00", align 1
@.str.64 = private unnamed_addr constant [2 x i8] c" \00", align 1
@.str.65 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@.str.66 = private unnamed_addr constant [17 x i8] c"nvrm-boot-raster\00", align 1
@.str.67 = private unnamed_addr constant [8 x i8] c"unknown\00", align 1
@_ZZN4NVRM9headWatchEPviE4armH = internal unnamed_addr global [256 x i32] zeroinitializer, align 16
@_ZZN4NVRM9headWatchEPviE4armW = internal unnamed_addr global [256 x i32] zeroinitializer, align 16
@.str.68 = private unnamed_addr constant [91 x i8] c"NVRM-xnu: armwatch: baseline taken (firmware) head0 SET_CONTROL 0x%08x RASTER_SIZE 0x%08x\0A\00", align 1
@.str.69 = private unnamed_addr constant [74 x i8] c"NVRM-xnu: headwatch: head %d %s at %llu ms since boot (vline raw 0x%08x)\0A\00", align 1
@.str.70 = private unnamed_addr constant [8 x i8] c"RUNNING\00", align 1
@.str.71 = private unnamed_addr constant [8 x i8] c"STOPPED\00", align 1
@.str.72 = private unnamed_addr constant [60 x i8] c"NVRM-xnu: armwatch: %llu ms HEAD0 +0x%03x 0x%08x -> 0x%08x\0A\00", align 1
@.str.73 = private unnamed_addr constant [61 x i8] c"NVRM-xnu: armwatch: %llu ms WIN    +0x%03x 0x%08x -> 0x%08x\0A\00", align 1
@.str.74 = private unnamed_addr constant [27 x i8] c"NVRM-xnu: headwatch: done\0A\00", align 1
@.str.75 = private unnamed_addr constant [80 x i8] c"NVRM-xnu: boot hold RELEASED (%s) \E2\80\94 WindowServer's IOKitWaitQuiet may return\0A\00", align 1
@.str.76 = private unnamed_addr constant [57 x i8] c"CAP: settle + 40 s \E2\80\94 bring-up not finished, NOT arming\00", align 1
@.str.77 = private unnamed_addr constant [106 x i8] c"NVRM-xnu: boot hold RELEASED by the settle + 40 s cap \E2\80\94 the bring-up will not arm with WindowServer up\0A\00", align 1
@.str.78 = private unnamed_addr constant [276 x i8] c"NVRM-xnu: starting the NVIDIA card: waiting %u s before it takes over the screen, because its memory window (BAR1) is too small to move off the boot screen. This is not a freeze. To start in about a second instead, enable \22Above 4G Decoding\22 and \22Resizable BAR\22 in the BIOS.\0A\00", align 1
@.str.79 = private unnamed_addr constant [62 x i8] c"NVRM-xnu: starting the NVIDIA card: %u s left (not a freeze)\0A\00", align 1
@.str.80 = private unnamed_addr constant [49 x i8] c"NVRM-xnu: auto-go: go(2) -> 0x%x (fPassDone %u)\0A\00", align 1
@.str.81 = private unnamed_addr constant [32 x i8] c"busy (a hand-run go is running)\00", align 1
@.str.82 = private unnamed_addr constant [13 x i8] c"go(2) failed\00", align 1
@.str.83 = private unnamed_addr constant [3 x i8] c"up\00", align 1
@.str.84 = private unnamed_addr constant [10 x i8] c"nvfbheads\00", align 1
@.str.85 = private unnamed_addr constant [30 x i8] c"debug.nvaccel_heads_published\00", align 1
@_ZL12gDisplayNub0 = internal unnamed_addr global ptr null, align 8
@.str.86 = private unnamed_addr constant [19 x i8] c"connected-displays\00", align 1
@_ZN8OSNumber9metaClassE = external local_unnamed_addr constant ptr, align 8
@.str.87 = private unnamed_addr constant [78 x i8] c"NVRM-xnu: auto-go: heads published mask 0x%x (%u of nvfbheads %d) after %d s\0A\00", align 1
@.str.88 = private unnamed_addr constant [104 x i8] c"NVRM-xnu: auto-go: the hold was already released (cap) \E2\80\94 NOT arming with WindowServer up; heads 0x%x\0A\00", align 1
@.str.89 = private unnamed_addr constant [13 x i8] c"nvrm-display\00", align 1
@.str.90 = private unnamed_addr constant [42 x i8] c"not armed: hold released by the cap first\00", align 1
@.str.91 = private unnamed_addr constant [16 x i8] c"debug.nvaccelfb\00", align 1
@.str.92 = private unnamed_addr constant [59 x i8] c"NVRM-xnu: auto-go: accelerator level 1 %s after %d tr%s%s\0A\00", align 1
@.str.93 = private unnamed_addr constant [5 x i8] c"took\00", align 1
@.str.94 = private unnamed_addr constant [11 x i8] c"NEVER took\00", align 1
@.str.95 = private unnamed_addr constant [4 x i8] c"ies\00", align 1
@.str.96 = private unnamed_addr constant [2 x i8] c"y\00", align 1
@.str.97 = private unnamed_addr constant [18 x i8] c", level 4 written\00", align 1
@.str.98 = private unnamed_addr constant [24 x i8] c" \E2\80\94 not arming further\00", align 1
@.str.99 = private unnamed_addr constant [21 x i8] c"debug.nvrmfb_agdc_k5\00", align 1
@.str.100 = private unnamed_addr constant [18 x i8] c"debug.nvrmfb_agdc\00", align 1
@.str.101 = private unnamed_addr constant [18 x i8] c"debug.nvaccel_iop\00", align 1
@.str.102 = private unnamed_addr constant [41 x i8] c"heads 0x%x accel %d agdc %d k5 %d iop %d\00", align 1
@.str.103 = private unnamed_addr constant [38 x i8] c"NVRM-xnu: auto-go: display stack: %s\0A\00", align 1
@.str.104 = private unnamed_addr constant [14 x i8] c"display armed\00", align 1
@.str.105 = private unnamed_addr constant [16 x i8] c"display PARTIAL\00", align 1
@.str.106 = private unnamed_addr constant [12 x i8] c"-nvrmnoflip\00", align 1
@.str.107 = private unnamed_addr constant [40 x i8] c"BAR1 not placed (small firmware window)\00", align 1
@.str.108 = private unnamed_addr constant [14 x i8] c"IOAccelerator\00", align 1
@.str.109 = private unnamed_addr constant [3 x i8] c"NV\00", align 1
@.str.110 = private unnamed_addr constant [37 x i8] c"another GPU's accelerator is running\00", align 1
@.str.111 = private unnamed_addr constant [43 x i8] c"NVRM-xnu: auto-go: accelerator %s present\0A\00", align 1
@.str.112 = private unnamed_addr constant [89 x i8] c"NVRM-xnu: auto-go: zero-copy flip NOT started: %s; the copy path stays (as -nvrmnoflip)\0A\00", align 1
@.str.113 = private unnamed_addr constant [10 x i8] c"nvrm-flip\00", align 1
@.str.114 = private unnamed_addr constant [16 x i8] c"off (copy path)\00", align 1
@.str.115 = private unnamed_addr constant [23 x i8] c"debug.nvaccel_iop_flip\00", align 1
@.str.116 = private unnamed_addr constant [76 x i8] c"NVRM-xnu: auto-go: flip debug.nvaccel_iop_flip=%d (60 s after the release)\0A\00", align 1
@.str.117 = private unnamed_addr constant [3 x i8] c"on\00", align 1
@.str.118 = private unnamed_addr constant [7 x i8] c"FAILED\00", align 1
@.str.119 = private unnamed_addr constant [14 x i8] c"-nvrmsmallbar\00", align 1
@.str.120 = private unnamed_addr constant [84 x i8] c"NVRM-xnu: bar1: no Resizable BAR capability \E2\80\94 BAR1 left as IOPCIFamily placed it\0A\00", align 1
@.str.121 = private unnamed_addr constant [96 x i8] c"NVRM-xnu: bar1: Resizable BAR capability @0x%x says BAR1 = %llu MB (sizes supported mask 0x%x)\0A\00", align 1
@.str.122 = private unnamed_addr constant [102 x i8] c"NVRM-xnu: bar1: -nvrmsmallbar set but the card cannot be sized to 256 MB (mask 0x%x) \E2\80\94 not placing\0A\00", align 1
@.str.123 = private unnamed_addr constant [112 x i8] c"NVRM-xnu: bar1: -nvrmsmallbar set \E2\80\94 BAR1 %llu MB will be sized to 256 MB, as on a card without Resizable BAR\0A\00", align 1
@.str.124 = private unnamed_addr constant [114 x i8] c"NVRM-xnu: bar1: BAR1 is %llu MB, the card offers no larger size and the console is not inside it \E2\80\94 not placing\0A\00", align 1
@.str.125 = private unnamed_addr constant [115 x i8] c"NVRM-xnu: bar1: BAR1 is %llu MB with the console inside it (0x%llx) and no larger size \E2\80\94 moving it at this size\0A\00", align 1
@.str.126 = private unnamed_addr constant [60 x i8] c"NVRM-xnu: bar1: BAR1 is %llu MB; will resize it to %llu MB\0A\00", align 1
@.str.127 = private unnamed_addr constant [75 x i8] c"NVRM-xnu: bar1: BAR1/BAR3 are not both 64-bit (0x%x 0x%x) \E2\80\94 not placing\0A\00", align 1
@_ZN18IOMemoryDescriptor9metaClassE = external local_unnamed_addr constant ptr, align 8
@.str.128 = private unnamed_addr constant [141 x i8] c"NVRM-xnu: bar1: BAR1 already %llu MB at 0x%llx (above 4 GB, in the nub, console 0x%llx outside it) - left in place, as NVIDIA's driver does\0A\00", align 1
@.str.129 = private unnamed_addr constant [19 x i8] c"assigned-addresses\00", align 1
@_ZN6OSData9metaClassE = external local_unnamed_addr constant ptr, align 8
@.str.130 = private unnamed_addr constant [78 x i8] c"NVRM-xnu: bar1: BAR0 0x%llx+0x%llx taken from assigned-addresses (nub stale)\0A\00", align 1
@.str.131 = private unnamed_addr constant [78 x i8] c"NVRM-xnu: bar1: BAR3 0x%llx+0x%llx taken from assigned-addresses (nub stale)\0A\00", align 1
@.str.132 = private unnamed_addr constant [94 x i8] c"NVRM-xnu: bar1: BAR0/BAR3 apertures not found in the nub (bar0 %d bar3 %llu) \E2\80\94 not placing\0A\00", align 1
@.str.133 = private unnamed_addr constant [90 x i8] c"NVRM-xnu: bar1: host bridge 64-bit window 0x%llx-0x%llx (ACPI _CRS), CPU reaches %u bits\0A\00", align 1
@.str.134 = private unnamed_addr constant [111 x i8] c"NVRM-xnu: bar1: no 64-bit window in the host bridge's _CRS (%s) \E2\80\94 using 0x%llx-0x%llx (CPU reaches %u bits)\0A\00", align 1
@.str.135 = private unnamed_addr constant [135 x i8] c"NVRM-xnu: bar1: no 64-bit window in the host bridge's _CRS \E2\80\94 using Intel's 256-512 GB PCI range 0x%llx-0x%llx (CPU reaches %u bits)\0A\00", align 1
@.str.136 = private unnamed_addr constant [74 x i8] c"NVRM-xnu: bar1: window 0x%llx-0x%llx cannot hold %llu MB \E2\80\94 not placing\0A\00", align 1
@.str.137 = private unnamed_addr constant [74 x i8] c"NVRM-xnu: bar1: no %llu MB-aligned slot in 0x%llx-0x%llx \E2\80\94 not placing\0A\00", align 1
@.str.138 = private unnamed_addr constant [60 x i8] c"NVRM-xnu: bar1: parent root port not found \E2\80\94 not placing\0A\00", align 1
@.str.139 = private unnamed_addr constant [107 x i8] c"NVRM-xnu: bar1: parent bridge is not a PCIe Root Port (port type %u) - BAR1 left as IOPCIFamily placed it\0A\00", align 1
@.str.140 = private unnamed_addr constant [85 x i8] c"NVRM-xnu: bar1: root port bus range %u-%u does not cover our bus %u \E2\80\94 not placing\0A\00", align 1
@.str.141 = private unnamed_addr constant [77 x i8] c"NVRM-xnu: bar1: root port range %u-%u has other PCI devices \E2\80\94 not placing\0A\00", align 1
@.str.142 = private unnamed_addr constant [84 x i8] c"NVRM-xnu: bar1: root port prefetchable window is not 64-bit (0x%x) \E2\80\94 not placing\0A\00", align 1
@.str.143 = private unnamed_addr constant [55 x i8] c"NVRM-xnu: bar1: destination is in use \E2\80\94 not placing\0A\00", align 1
@.str.144 = private unnamed_addr constant [123 x i8] c"NVRM-xnu: bar1: placing BAR1 %llu MB @0x%llx, BAR3 %llu MB @0x%llx, root port window 0x%llx-0x%llx (was 0x%08x %08x/%08x)\0A\00", align 1
@.str.145 = private unnamed_addr constant [73 x i8] c"NVRM-xnu: bar1: resize to %llu MB did not take (ctl 0x%x) \E2\80\94 restoring\0A\00", align 1
@.str.146 = private unnamed_addr constant [41 x i8] c"NVRM-xnu: bar1: resized BAR1 to %llu MB\0A\00", align 1
@.str.147 = private unnamed_addr constant [111 x i8] c"NVRM-xnu: bar1: read-back MISMATCH (bar 0x%08x %08x, rp 0x%08x %08x %08x) \E2\80\94 restoring what IOPCIFamily left\0A\00", align 1
@.str.148 = private unnamed_addr constant [123 x i8] c"NVRM-xnu: bar1: placed in hardware but the aperture list could not be built (no memory) - restoring what IOPCIFamily left\0A\00", align 1
@.str.149 = private unnamed_addr constant [55 x i8] c"NVRM-xnu: bar1: dropping stale aperture 0x%llx+0x%llx\0A\00", align 1
@.str.150 = private unnamed_addr constant [17 x i8] c"nvrm-bar1-placed\00", align 1
@.str.151 = private unnamed_addr constant [56 x i8] c"NVRM-xnu: bar1: PLACED \E2\80\94 BAR1 %llu MB live at 0x%llx\0A\00", align 1
@.str.152 = private unnamed_addr constant [114 x i8] c"NVRM-xnu: gpu profile: the RM did not answer (status 0x%x) - no profile published, users fall back to device ids\0A\00", align 1
@.str.153 = private unnamed_addr constant [14 x i8] c"Turing GTX 16\00", align 1
@.str.154 = private unnamed_addr constant [7 x i8] c"Turing\00", align 1
@.str.155 = private unnamed_addr constant [3 x i8] c"TU\00", align 1
@.str.156 = private unnamed_addr constant [7 x i8] c"Ampere\00", align 1
@.str.157 = private unnamed_addr constant [3 x i8] c"GA\00", align 1
@.str.158 = private unnamed_addr constant [7 x i8] c"Hopper\00", align 1
@.str.159 = private unnamed_addr constant [3 x i8] c"GH\00", align 1
@.str.160 = private unnamed_addr constant [4 x i8] c"Ada\00", align 1
@.str.161 = private unnamed_addr constant [3 x i8] c"AD\00", align 1
@.str.162 = private unnamed_addr constant [10 x i8] c"Blackwell\00", align 1
@.str.163 = private unnamed_addr constant [3 x i8] c"GB\00", align 1
@.str.164 = private unnamed_addr constant [6 x i8] c"TU116\00", align 1
@.str.165 = private unnamed_addr constant [6 x i8] c"TU117\00", align 1
@.str.166 = private unnamed_addr constant [9 x i8] c"%s%x%02x\00", align 1
@.str.167 = private unnamed_addr constant [15 x i8] c"VRAM,totalsize\00", align 1
@.str.168 = private unnamed_addr constant [5 x i8] c"arch\00", align 1
@.str.169 = private unnamed_addr constant [5 x i8] c"impl\00", align 1
@.str.170 = private unnamed_addr constant [5 x i8] c"chip\00", align 1
@.str.171 = private unnamed_addr constant [11 x i8] c"generation\00", align 1
@.str.172 = private unnamed_addr constant [9 x i8] c"class-3d\00", align 1
@.str.173 = private unnamed_addr constant [14 x i8] c"class-compute\00", align 1
@.str.174 = private unnamed_addr constant [11 x i8] c"class-copy\00", align 1
@.str.175 = private unnamed_addr constant [12 x i8] c"class-nvenc\00", align 1
@.str.176 = private unnamed_addr constant [12 x i8] c"class-nvdec\00", align 1
@.str.177 = private unnamed_addr constant [8 x i8] c"bar1-mb\00", align 1
@.str.178 = private unnamed_addr constant [8 x i8] c"vram-mb\00", align 1
@.str.179 = private unnamed_addr constant [8 x i8] c"scanout\00", align 1
@.str.180 = private unnamed_addr constant [12 x i8] c"static-bar1\00", align 1
@.str.181 = private unnamed_addr constant [10 x i8] c"by-handle\00", align 1
@.str.182 = private unnamed_addr constant [13 x i8] c"video-layout\00", align 1
@.str.183 = private unnamed_addr constant [10 x i8] c"blackwell\00", align 1
@.str.184 = private unnamed_addr constant [8 x i8] c"classic\00", align 1
@.str.185 = private unnamed_addr constant [15 x i8] c"native-shaders\00", align 1
@.str.186 = private unnamed_addr constant [7 x i8] c"sm_120\00", align 1
@.str.187 = private unnamed_addr constant [5 x i8] c"none\00", align 1
@.str.188 = private unnamed_addr constant [17 x i8] c"nvrm-gpu-profile\00", align 1
@.str.189 = private unnamed_addr constant [115 x i8] c"NVRM-xnu: gpu profile: %s %s, 3d 0x%x copy 0x%x nvenc 0x%x nvdec 0x%x, BAR1 %llu MB of %llu MB VRAM -> scanout %s\0A\00", align 1
@.str.190 = private unnamed_addr constant [67 x i8] c"NVRM-xnu: aperture idx %u phys 0x%llx size 0x%llx: %s \E2\80\94 skipped\0A\00", align 1
@.str.191 = private unnamed_addr constant [24 x i8] c"no BAR register matches\00", align 1
@.str.192 = private unnamed_addr constant [12 x i8] c"zero length\00", align 1
@.str.193 = private unnamed_addr constant [28 x i8] c"bar%u@0x%02x:0x%llx+0x%llx \00", align 1
@.str.194 = private unnamed_addr constant [189 x i8] c"NVRM-xnu: BAR1 (the VRAM window) has no address from macOS: the GPU cannot start. Enable \22Above 4G Decoding\22 in the BIOS, or turn Resizable BAR off if it is on and the board cannot map it\0A\00", align 1
@.str.195 = private unnamed_addr constant [10 x i8] c"nvrm-bars\00", align 1
@.str.196 = private unnamed_addr constant [19 x i8] c"NVRM-xnu: BARS %s\0A\00", align 1
@.str.197 = private unnamed_addr constant [73 x i8] c"NVRM-xnu: go(%u) refused: caller is not an administrator (fPassDone %d)\0A\00", align 1
@_ZZN4NVRM2goEjE7gGoBusy = internal unnamed_addr global i1 false, align 1
@.str.198 = private unnamed_addr constant [49 x i8] c"NVRM-xnu: go(%u) refused: another go is running\0A\00", align 1
@.str.199 = private unnamed_addr constant [40 x i8] c"NVRM-xnu: go(%u) begins (fPassDone %d)\0A\00", align 1
@.str.201 = private unnamed_addr constant [43 x i8] c"NVRM-xnu: go(pass %u) \E2\80\94 done so far: %u\0A\00", align 1
@.str.202 = private unnamed_addr constant [85 x i8] c"NVRM-xnu: anchor: os_mem_set runtime 0x%llx (slide = runtime - its nm link address)\0A\00", align 1
@_ZL11gRmInitDone = internal unnamed_addr global i1 false, align 1
@.str.203 = private unnamed_addr constant [24 x i8] c"NVRM-xnu: rm_init_rm()\0A\00", align 1
@.str.204 = private unnamed_addr constant [29 x i8] c"NVRM-xnu: rm_init_rm FAILED\0A\00", align 1
@.str.205 = private unnamed_addr constant [25 x i8] c"NVRM-xnu: rm_init_rm OK\0A\00", align 1
@.str.206 = private unnamed_addr constant [43 x i8] c"NVRM-xnu: rm_init_event_locks(ctl) FAILED\0A\00", align 1
@.str.207 = private unnamed_addr constant [43 x i8] c"NVRM-xnu: rm_init_event_locks(gpu) FAILED\0A\00", align 1
@.str.208 = private unnamed_addr constant [66 x i8] c"NVRM-xnu: event locks created for the control device and the GPU\0A\00", align 1
@.str.209 = private unnamed_addr constant [6 x i8] c"RmMsg\00", align 1
@.str.210 = private unnamed_addr constant [2 x i8] c":\00", align 1
@.str.211 = private unnamed_addr constant [17 x i8] c"ResmanDebugLevel\00", align 1
@.str.212 = private unnamed_addr constant [63 x i8] c"NVRM-xnu: registry: RmMsg=\22:\22 ResmanDebugLevel=0 (verbose RM)\0A\00", align 1
@.str.213 = private unnamed_addr constant [31 x i8] c"PreserveVideoMemoryAllocations\00", align 1
@.str.214 = private unnamed_addr constant [87 x i8] c"NVRM-xnu: registry: PreserveVideoMemoryAllocations=1 (all VRAM survives system sleep)\0A\00", align 1
@.str.215 = private unnamed_addr constant [102 x i8] c"NVRM-xnu: rm_is_supported_device -> 0x%x: RM will not drive device 0x%04x - stopping, card untouched\0A\00", align 1
@.str.216 = private unnamed_addr constant [69 x i8] c"NVRM-xnu: rm_is_supported_device OK - this chip has a HAL and a GSP\0A\00", align 1
@.str.217 = private unnamed_addr constant [35 x i8] c"NVRM-xnu: rm_init_private_state()\0A\00", align 1
@.str.218 = private unnamed_addr constant [40 x i8] c"NVRM-xnu: rm_init_private_state FAILED\0A\00", align 1
@.str.219 = private unnamed_addr constant [36 x i8] c"NVRM-xnu: rm_init_private_state OK\0A\00", align 1
@.str.220 = private unnamed_addr constant [87 x i8] c"NVRM-xnu: PASS 1 REACHED: RM initialised, private state built, GSP firmware requested\0A\00", align 1
@.str.221 = private unnamed_addr constant [56 x i8] c"NVRM-xnu: bus master + memory enabled (command 0x%04x)\0A\00", align 1
@.str.222 = private unnamed_addr constant [45 x i8] c"NVRM-xnu:   interrupt source %d type 0x%x%s\0A\00", align 1
@.str.223 = private unnamed_addr constant [7 x i8] c" (MSI)\00", align 1
@.str.224 = private unnamed_addr constant [96 x i8] c"NVRM-xnu: no MSI source on the device \E2\80\94 refusing (the RM needs message-signalled interrupts)\0A\00", align 1
@.str.225 = private unnamed_addr constant [41 x i8] c"NVRM-xnu: interrupt source setup FAILED\0A\00", align 1
@.str.226 = private unnamed_addr constant [82 x i8] c"NVRM-xnu: MSI %d armed; calling rm_init_adapter() \E2\80\94 GSP boot from inside macOS\0A\00", align 1
@.str.227 = private unnamed_addr constant [33 x i8] c"NVRM-xnu: rm_init_adapter -> %s\0A\00", align 1
@.str.228 = private unnamed_addr constant [3 x i8] c"OK\00", align 1
@.str.229 = private unnamed_addr constant [91 x i8] c"NVRM-xnu: PASS 2 REACHED: the adapter is up \E2\80\94 GSP-RM is running on the card under macOS\0A\00", align 1
@.str.230 = private unnamed_addr constant [13 x i8] c"VRAM,totalMB\00", align 1
@.str.231 = private unnamed_addr constant [100 x i8] c"NVRM-xnu: published VRAM,totalsize=%llu bytes (RAM_SIZE %u KB, TOTAL_RAM_SIZE %u KB) from the card\0A\00", align 1
@.str.232 = private unnamed_addr constant [99 x i8] c"NVRM-xnu: FB_GET_INFO_V2 did not answer (status 0x%x, RAM_SIZE %u KB) - publishing no VRAM figure\0A\00", align 1
@.str.233 = private unnamed_addr constant [54 x i8] c"NVRM-xnu: MSI #%lu -> work loop (handled so far %lu)\0A\00", align 1
@nv_xnu_isr_thread = external global ptr, align 8
@.str.234 = private unnamed_addr constant [18 x i8] c"nvrm-pm-violation\00", align 1
@.str.235 = private unnamed_addr constant [73 x i8] c"NVRM-xnu: power: setPowerState %lu (gpu %s, adapter %s) - nothing to do\0A\00", align 1
@.str.236 = private unnamed_addr constant [10 x i8] c"suspended\00", align 1
@.str.237 = private unnamed_addr constant [5 x i8] c"lost\00", align 1
@.str.238 = private unnamed_addr constant [5 x i8] c"down\00", align 1
@.str.239 = private unnamed_addr constant [66 x i8] c"NVRM-xnu: sleep #%u: suspending the GPU (NVKMS, then RM standby)\0A\00", align 1
@.str.240 = private unnamed_addr constant [105 x i8] c"NVRM-xnu: sleep #%u: the display layer refused to start (already suspended, LOST, or a request pending)\0A\00", align 1
@.str.241 = private unnamed_addr constant [109 x i8] c"NVRM-xnu: sleep #%u: VIOLATION after %llu ms - a teardown pin did not drain; NVKMS and RM were left running\0A\00", align 1
@.str.242 = private unnamed_addr constant [81 x i8] c"NVRM-xnu: sleep #%u: %d RM call(s) still running after 10 s - suspending anyway\0A\00", align 1
@.str.243 = private unnamed_addr constant [103 x i8] c"NVRM-xnu: sleep #%u: user channels stopped -> 0x%x; rm_power_management(STANDBY) -> 0x%x in %llu ms%s\0A\00", align 1
@.str.244 = private unnamed_addr constant [43 x i8] c" - resume will still be tried, as on Linux\00", align 1
@.str.245 = private unnamed_addr constant [38 x i8] c"NVRM-xnu: wake #%u: resuming the GPU\0A\00", align 1
@.str.246 = private unnamed_addr constant [21 x i8] c"lost (resume failed)\00", align 1
@.str.247 = private unnamed_addr constant [104 x i8] c"NVRM-xnu: wake #%u: rm_power_management(RESUME) -> 0x%x, user channels restarted -> 0x%x, %llu ms - %s\0A\00", align 1
@.str.248 = private unnamed_addr constant [38 x i8] c"GPU running, telling the framebuffers\00", align 1
@.str.249 = private unnamed_addr constant [57 x i8] c"GPU LOST: NVKMS refuses all display work until a restart\00", align 1
@.str.250 = private unnamed_addr constant [64 x i8] c"NVRM-xnu: wake #%u: reclaimed bridge closes, %d still deferred\0A\00", align 1
@.str.251 = private unnamed_addr constant [117 x i8] c"NVRM-xnu: sleep: saved config - cmd 0x%04x BAR1 0x%08x%08x, %u ReBAR control(s), root port %s pref 0x%08x %08x/%08x\0A\00", align 1
@.str.252 = private unnamed_addr constant [7 x i8] c"(none)\00", align 1
@.str.253 = private unnamed_addr constant [69 x i8] c"NVRM-xnu: wake: no saved config - leaving what IOPCIFamily restored\0A\00", align 1
@.str.254 = private unnamed_addr constant [80 x i8] c"NVRM-xnu: wake: config space answers vendor 0x%04x - the GPU is not on the bus\0A\00", align 1
@.str.255 = private unnamed_addr constant [57 x i8] c"NVRM-xnu: wake: root port @0x%02x is 0x%08x, was 0x%08x\0A\00", align 1
@.str.256 = private unnamed_addr constant [59 x i8] c"NVRM-xnu: wake: ReBAR control @0x%x is 0x%08x, was 0x%08x\0A\00", align 1
@.str.257 = private unnamed_addr constant [60 x i8] c"NVRM-xnu: wake: BAR register @0x%02x is 0x%08x, was 0x%08x\0A\00", align 1
@.str.258 = private unnamed_addr constant [58 x i8] c"NVRM-xnu: wake: config %s (%u fix-up(s)), command 0x%04x\0A\00", align 1
@.str.259 = private unnamed_addr constant [28 x i8] c"matches the pre-sleep state\00", align 1
@.str.260 = private unnamed_addr constant [28 x i8] c"does NOT read back as saved\00", align 1
@.str.261 = private unnamed_addr constant [42 x i8] c"NVRM-xnu: wake: PMC_BOOT_0 = 0x%08x - %s\0A\00", align 1
@.str.262 = private unnamed_addr constant [16 x i8] c"the GPU answers\00", align 1
@.str.263 = private unnamed_addr constant [24 x i8] c"the GPU does not answer\00", align 1
@.str.264 = private unnamed_addr constant [13 x i8] c"NVRMGpuPower\00", align 1
@gIOServicePlane = external local_unnamed_addr global ptr, align 8
@_ZN9IOService9metaClassE = external local_unnamed_addr constant ptr, align 8
@.str.265 = private unnamed_addr constant [55 x i8] c"NVRM-xnu: power: told %u framebuffer(s) the GPU is %s\0A\00", align 1
@.str.266 = private unnamed_addr constant [17 x i8] c"going to standby\00", align 1
@.str.267 = private unnamed_addr constant [5 x i8] c"back\00", align 1
@_ZN14NVRMUserClient10gMetaClassE = global %"class.NVRMUserClient::MetaClass" zeroinitializer, align 8
@_ZN12IOUserClient10gMetaClassE = external global %"class.IOUserClient::MetaClass", align 8
@_ZN14NVRMUserClient10superClassE = local_unnamed_addr constant ptr @_ZN12IOUserClient10gMetaClassE, align 8
@_ZTV14NVRMUserClient = unnamed_addr constant { [303 x ptr] } { [303 x ptr] [ptr null, ptr null, ptr @_ZN14NVRMUserClientD1Ev, ptr @_ZN14NVRMUserClientD0Ev, ptr @_ZNK8OSObject7releaseEi, ptr @_ZNK8OSObject14getRetainCountEv, ptr @_ZNK8OSObject6retainEv, ptr @_ZNK8OSObject7releaseEv, ptr @_ZNK8OSObject9serializeEP11OSSerialize, ptr @_ZNK14NVRMUserClient12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK8OSObject12taggedRetainEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKvi, ptr @_ZN12IOUserClient8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZN12IOUserClient4initEv, ptr @_ZN14NVRMUserClient4freeEv, ptr @_ZN8OSObject18_RESERVEDOSObject0Ev, ptr @_ZN8OSObject18_RESERVEDOSObject1Ev, ptr @_ZN8OSObject18_RESERVEDOSObject2Ev, ptr @_ZN8OSObject18_RESERVEDOSObject3Ev, ptr @_ZN8OSObject18_RESERVEDOSObject4Ev, ptr @_ZN8OSObject18_RESERVEDOSObject5Ev, ptr @_ZN8OSObject18_RESERVEDOSObject6Ev, ptr @_ZN8OSObject18_RESERVEDOSObject7Ev, ptr @_ZN8OSObject18_RESERVEDOSObject8Ev, ptr @_ZN8OSObject18_RESERVEDOSObject9Ev, ptr @_ZN8OSObject19_RESERVEDOSObject10Ev, ptr @_ZN8OSObject19_RESERVEDOSObject11Ev, ptr @_ZN8OSObject19_RESERVEDOSObject12Ev, ptr @_ZN8OSObject19_RESERVEDOSObject13Ev, ptr @_ZN8OSObject19_RESERVEDOSObject14Ev, ptr @_ZN8OSObject19_RESERVEDOSObject15Ev, ptr @_ZNK15IORegistryEntry12copyPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry15copyParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14copyChildEntryEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry17runPropertyActionEPFiP8OSObjectPvS2_S2_S2_ES1_S2_S2_S2_S2_, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry0Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry1Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry2Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry3Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry4Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry5Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry6Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry7Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry8Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry9Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry10Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry11Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry12Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry13Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry14Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry15Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry16Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry17Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry18Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry19Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry20Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry21Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry22Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry23Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry24Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry25Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry26Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry27Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry28Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry29Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry30Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry31Ev, ptr @_ZN12IOUserClient4initEP12OSDictionary, ptr @_ZN15IORegistryEntry16setPropertyTableEP12OSDictionary, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSSymbolP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSStringP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcS1_, ptr @_ZN15IORegistryEntry11setPropertyEPKcb, ptr @_ZN15IORegistryEntry11setPropertyEPKcyj, ptr @_ZN15IORegistryEntry11setPropertyEPKcPvj, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSSymbol, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSString, ptr @_ZN15IORegistryEntry14removePropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry11getPropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry12copyPropertyEPKc, ptr @_ZNK15IORegistryEntry24dictionaryWithPropertiesEv, ptr @_ZNK9IOService19serializePropertiesEP11OSSerialize, ptr @_ZN15IORegistryEntry13setPropertiesEP8OSObject, ptr @_ZNK15IORegistryEntry17getParentIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14applyToParentsEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14getParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getChildIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry15applyToChildrenEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry13getChildEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7isChildEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry8isParentEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry7inPlaneEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8getDepthEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry14attachToParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry16detachFromParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry13attachToChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry15detachFromChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry11detachAboveEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry9detachAllEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8copyNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12compareNamesEP8OSObjectPP8OSString, ptr @_ZNK15IORegistryEntry11compareNameEP8OSStringPS1_, ptr @_ZN15IORegistryEntry7setNameEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry7setNameEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry11getLocationEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12copyLocationEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getPathEPcPiPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getPathComponentEPcPiPK15IORegistryPlane, ptr @_ZN15IORegistryEntry13childFromPathEPKcPK15IORegistryPlanePcPi, ptr @_ZN9IOService4initEP15IORegistryEntryPK15IORegistryPlane, ptr @_ZN9IOService16requestTerminateEPS_j, ptr @_ZN9IOService13willTerminateEPS_j, ptr @_ZN9IOService12didTerminateEPS_jPb, ptr @_ZN9IOService15nextIdleTimeoutEyyj, ptr @_ZN9IOService18systemWillShutdownEj, ptr @_ZN9IOService22copyClientWithCategoryEPK8OSSymbol, ptr @_ZN9IOService15configureReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService12updateReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService19_RESERVEDIOService2Ev, ptr @_ZN9IOService19_RESERVEDIOService3Ev, ptr @_ZN9IOService19_RESERVEDIOService4Ev, ptr @_ZN9IOService19_RESERVEDIOService5Ev, ptr @_ZN9IOService19_RESERVEDIOService6Ev, ptr @_ZN9IOService19_RESERVEDIOService7Ev, ptr @_ZN9IOService19_RESERVEDIOService8Ev, ptr @_ZN9IOService19_RESERVEDIOService9Ev, ptr @_ZN9IOService20_RESERVEDIOService10Ev, ptr @_ZN9IOService20_RESERVEDIOService11Ev, ptr @_ZN9IOService20_RESERVEDIOService12Ev, ptr @_ZN9IOService20_RESERVEDIOService13Ev, ptr @_ZN9IOService20_RESERVEDIOService14Ev, ptr @_ZN9IOService20_RESERVEDIOService15Ev, ptr @_ZN9IOService20_RESERVEDIOService16Ev, ptr @_ZN9IOService20_RESERVEDIOService17Ev, ptr @_ZN9IOService20_RESERVEDIOService18Ev, ptr @_ZN9IOService20_RESERVEDIOService19Ev, ptr @_ZN9IOService20_RESERVEDIOService20Ev, ptr @_ZN9IOService20_RESERVEDIOService21Ev, ptr @_ZN9IOService20_RESERVEDIOService22Ev, ptr @_ZN9IOService20_RESERVEDIOService23Ev, ptr @_ZN9IOService20_RESERVEDIOService24Ev, ptr @_ZN9IOService20_RESERVEDIOService25Ev, ptr @_ZN9IOService20_RESERVEDIOService26Ev, ptr @_ZN9IOService20_RESERVEDIOService27Ev, ptr @_ZN9IOService20_RESERVEDIOService28Ev, ptr @_ZN9IOService20_RESERVEDIOService29Ev, ptr @_ZN9IOService20_RESERVEDIOService30Ev, ptr @_ZN9IOService20_RESERVEDIOService31Ev, ptr @_ZN9IOService20_RESERVEDIOService32Ev, ptr @_ZN9IOService20_RESERVEDIOService33Ev, ptr @_ZN9IOService20_RESERVEDIOService34Ev, ptr @_ZN9IOService20_RESERVEDIOService35Ev, ptr @_ZN9IOService20_RESERVEDIOService36Ev, ptr @_ZN9IOService20_RESERVEDIOService37Ev, ptr @_ZN9IOService20_RESERVEDIOService38Ev, ptr @_ZN9IOService20_RESERVEDIOService39Ev, ptr @_ZN9IOService20_RESERVEDIOService40Ev, ptr @_ZN9IOService20_RESERVEDIOService41Ev, ptr @_ZN9IOService20_RESERVEDIOService42Ev, ptr @_ZN9IOService20_RESERVEDIOService43Ev, ptr @_ZN9IOService20_RESERVEDIOService44Ev, ptr @_ZN9IOService20_RESERVEDIOService45Ev, ptr @_ZN9IOService20_RESERVEDIOService46Ev, ptr @_ZN9IOService20_RESERVEDIOService47Ev, ptr @_ZNK9IOService8getStateEv, ptr @_ZN9IOService15registerServiceEj, ptr @_ZN9IOService5probeEPS_Pi, ptr @_ZN14NVRMUserClient5startEP9IOService, ptr @_ZN9IOService4stopEPS_, ptr @_ZN9IOService4openEPS_jPv, ptr @_ZN9IOService5closeEPS_j, ptr @_ZNK9IOService6isOpenEPKS_, ptr @_ZN9IOService10handleOpenEPS_jPv, ptr @_ZN9IOService11handleCloseEPS_j, ptr @_ZNK9IOService12handleIsOpenEPKS_, ptr @_ZN9IOService9terminateEj, ptr @_ZN9IOService8finalizeEj, ptr @_ZN9IOService18lockForArbitrationEb, ptr @_ZN9IOService20unlockForArbitrationEv, ptr @_ZN9IOService15terminateClientEPS_j, ptr @_ZN9IOService12getBusyStateEv, ptr @_ZN9IOService10adjustBusyEi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionaryPi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionary, ptr @_ZN9IOService13matchLocationEPS_, ptr @_ZN9IOService17addNeededResourceEPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPK8OSString, ptr @_ZN9IOService17comparePropertiesEP12OSDictionaryP12OSCollection, ptr @_ZN9IOService6attachEPS_, ptr @_ZN9IOService6detachEPS_, ptr @_ZNK9IOService11getProviderEv, ptr @_ZNK9IOService11getWorkLoopEv, ptr @_ZNK9IOService19getProviderIteratorEv, ptr @_ZNK9IOService23getOpenProviderIteratorEv, ptr @_ZNK9IOService9getClientEv, ptr @_ZNK9IOService17getClientIteratorEv, ptr @_ZNK9IOService21getOpenClientIteratorEv, ptr @_ZN9IOService20callPlatformFunctionEPK8OSSymbolbPvS3_S3_S3_, ptr @_ZN9IOService20callPlatformFunctionEPKcbPvS2_S2_S2_, ptr @_ZN9IOService12getResourcesEv, ptr @_ZN9IOService20getDeviceMemoryCountEv, ptr @_ZN9IOService24getDeviceMemoryWithIndexEj, ptr @_ZN9IOService24mapDeviceMemoryWithIndexEjj, ptr @_ZN9IOService15getDeviceMemoryEv, ptr @_ZN9IOService15setDeviceMemoryEP7OSArray, ptr @_ZN9IOService17registerInterruptEiP8OSObjectPFvS1_PvPS_iES2_, ptr @_ZN9IOService19unregisterInterruptEi, ptr @_ZN9IOService16getInterruptTypeEiPi, ptr @_ZN9IOService15enableInterruptEi, ptr @_ZN9IOService16disableInterruptEi, ptr @_ZN9IOService14causeInterruptEi, ptr @_ZN9IOService12requestProbeEj, ptr @_ZN9IOService7messageEjPS_Pv, ptr @_ZN9IOService13messageClientEjP8OSObjectPvm, ptr @_ZN9IOService14messageClientsEjPvm, ptr @_ZN9IOService16registerInterestEPK8OSSymbolPFiPvS3_jPS_S3_mES3_S3_, ptr @_ZN9IOService16applyToProvidersEPFvPS_PvES1_, ptr @_ZN9IOService14applyToClientsEPFvPS_PvES1_, ptr @_ZN9IOService17applyToInterestedEPK8OSSymbolPFvP8OSObjectPvES5_, ptr @_ZN9IOService23acknowledgeNotificationEPvj, ptr @_ZN9IOService13newUserClientEP4taskPvjP12OSDictionaryPP12IOUserClient, ptr @_ZN9IOService13newUserClientEP4taskPvjPP12IOUserClient, ptr @_ZN9IOService16stringFromReturnEi, ptr @_ZN9IOService15errnoFromReturnEi, ptr @_ZN9IOService6PMinitEv, ptr @_ZN9IOService6PMstopEv, ptr @_ZN9IOService10joinPMtreeEPS_, ptr @_ZN9IOService19registerPowerDriverEPS_P14IOPMPowerStatem, ptr @_ZN9IOService23requestPowerDomainStateEmP17IOPowerConnectionm, ptr @_ZN9IOService14activityTickleEmm, ptr @_ZN9IOService17setAggressivenessEmm, ptr @_ZN9IOService17getAggressivenessEmPm, ptr @_ZN9IOService13addPowerChildEPS_, ptr @_ZN9IOService16removePowerChildEP17IOPowerConnection, ptr @_ZN9IOService18setIdleTimerPeriodEm, ptr @_ZN9IOService13setPowerStateEmPS_, ptr @_ZN9IOService27maxCapabilityForDomainStateEm, ptr @_ZN9IOService31initialPowerStateForDomainStateEm, ptr @_ZN9IOService24powerStateForDomainStateEm, ptr @_ZN9IOService22powerStateWillChangeToEmmPS_, ptr @_ZN9IOService21powerStateDidChangeToEmmPS_, ptr @_ZN9IOService13askChangeDownEm, ptr @_ZN9IOService14tellChangeDownEm, ptr @_ZN9IOService16tellNoChangeDownEm, ptr @_ZN9IOService12tellChangeUpEm, ptr @_ZN9IOService16allowPowerChangeEm, ptr @_ZN9IOService17cancelPowerChangeEm, ptr @_ZN9IOService15powerChangeDoneEm, ptr @_ZN14NVRMUserClient14externalMethodEjP25IOExternalMethodArgumentsP24IOExternalMethodDispatchP8OSObjectPv, ptr @_ZN12IOUserClient24registerNotificationPortEP8ipc_portjy, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient0Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient1Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient2Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient3Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient4Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient5Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient6Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient7Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient8Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient9Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient10Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient11Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient12Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient13Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient14Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient15Ev, ptr @_ZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionary, ptr @_ZN12IOUserClient12initWithTaskEP4taskPvj, ptr @_ZN14NVRMUserClient11clientCloseEv, ptr @_ZN12IOUserClient10clientDiedEv, ptr @_ZN12IOUserClient10getServiceEv, ptr @_ZN12IOUserClient24registerNotificationPortEP8ipc_portjj, ptr @_ZN12IOUserClient24getNotificationSemaphoreEjPP9semaphore, ptr @_ZN12IOUserClient13connectClientEPS_, ptr @_ZN14NVRMUserClient19clientMemoryForTypeEjPjPP18IOMemoryDescriptor, ptr @_ZN12IOUserClient20exportObjectToClientEP4taskP8OSObjectPS3_, ptr @_ZN12IOUserClient25getExternalMethodForIndexEj, ptr @_ZN12IOUserClient30getExternalAsyncMethodForIndexEj, ptr @_ZN12IOUserClient26getTargetAndMethodForIndexEPP9IOServicej, ptr @_ZN12IOUserClient31getAsyncTargetAndMethodForIndexEPP9IOServicej, ptr @_ZN12IOUserClient23getExternalTrapForIndexEj, ptr @_ZN12IOUserClient24getTargetAndTrapForIndexEPP9IOServicej, ptr null] }, align 8
@.str.269 = private unnamed_addr constant [15 x i8] c"NVRMUserClient\00", align 1
@_ZTVN14NVRMUserClient9MetaClassE = unnamed_addr constant { [29 x ptr] } { [29 x ptr] [ptr null, ptr null, ptr @_ZN14NVRMUserClient9MetaClassD1Ev, ptr @_ZN14NVRMUserClient9MetaClassD0Ev, ptr @_ZNK11OSMetaClass7releaseEi, ptr @_ZNK11OSMetaClass14getRetainCountEv, ptr @_ZNK11OSMetaClass6retainEv, ptr @_ZNK11OSMetaClass7releaseEv, ptr @_ZNK11OSMetaClass9serializeEP11OSSerialize, ptr @_ZNK11OSMetaClass12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK11OSMetaClass12taggedRetainEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKvi, ptr @_ZN15OSMetaClassBase8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZNK14NVRMUserClient9MetaClass5allocEv, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass1Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass2Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass3Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass4Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass5Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass6Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass7Ev, ptr null] }, align 8
@_ZN17IOAccelNVRMBridge10gMetaClassE = global %"class.IOAccelNVRMBridge::MetaClass" zeroinitializer, align 8
@_ZN17IOAccelNVRMBridge9metaClassE = local_unnamed_addr constant ptr @_ZN17IOAccelNVRMBridge10gMetaClassE, align 8
@_ZN17IOAccelNVRMBridge10superClassE = local_unnamed_addr constant ptr @_ZN14NVRMUserClient10gMetaClassE, align 8
@_ZTV17IOAccelNVRMBridge = unnamed_addr constant { [303 x ptr] } { [303 x ptr] [ptr null, ptr null, ptr @_ZN17IOAccelNVRMBridgeD1Ev, ptr @_ZN17IOAccelNVRMBridgeD0Ev, ptr @_ZNK8OSObject7releaseEi, ptr @_ZNK8OSObject14getRetainCountEv, ptr @_ZNK8OSObject6retainEv, ptr @_ZNK8OSObject7releaseEv, ptr @_ZNK8OSObject9serializeEP11OSSerialize, ptr @_ZNK17IOAccelNVRMBridge12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK8OSObject12taggedRetainEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKv, ptr @_ZNK8OSObject13taggedReleaseEPKvi, ptr @_ZN12IOUserClient8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZN12IOUserClient4initEv, ptr @_ZN14NVRMUserClient4freeEv, ptr @_ZN8OSObject18_RESERVEDOSObject0Ev, ptr @_ZN8OSObject18_RESERVEDOSObject1Ev, ptr @_ZN8OSObject18_RESERVEDOSObject2Ev, ptr @_ZN8OSObject18_RESERVEDOSObject3Ev, ptr @_ZN8OSObject18_RESERVEDOSObject4Ev, ptr @_ZN8OSObject18_RESERVEDOSObject5Ev, ptr @_ZN8OSObject18_RESERVEDOSObject6Ev, ptr @_ZN8OSObject18_RESERVEDOSObject7Ev, ptr @_ZN8OSObject18_RESERVEDOSObject8Ev, ptr @_ZN8OSObject18_RESERVEDOSObject9Ev, ptr @_ZN8OSObject19_RESERVEDOSObject10Ev, ptr @_ZN8OSObject19_RESERVEDOSObject11Ev, ptr @_ZN8OSObject19_RESERVEDOSObject12Ev, ptr @_ZN8OSObject19_RESERVEDOSObject13Ev, ptr @_ZN8OSObject19_RESERVEDOSObject14Ev, ptr @_ZN8OSObject19_RESERVEDOSObject15Ev, ptr @_ZNK15IORegistryEntry12copyPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry15copyParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14copyChildEntryEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry17runPropertyActionEPFiP8OSObjectPvS2_S2_S2_ES1_S2_S2_S2_S2_, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry0Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry1Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry2Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry3Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry4Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry5Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry6Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry7Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry8Ev, ptr @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry9Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry10Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry11Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry12Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry13Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry14Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry15Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry16Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry17Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry18Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry19Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry20Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry21Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry22Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry23Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry24Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry25Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry26Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry27Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry28Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry29Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry30Ev, ptr @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry31Ev, ptr @_ZN12IOUserClient4initEP12OSDictionary, ptr @_ZN15IORegistryEntry16setPropertyTableEP12OSDictionary, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSSymbolP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPK8OSStringP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcP8OSObject, ptr @_ZN15IORegistryEntry11setPropertyEPKcS1_, ptr @_ZN15IORegistryEntry11setPropertyEPKcb, ptr @_ZN15IORegistryEntry11setPropertyEPKcyj, ptr @_ZN15IORegistryEntry11setPropertyEPKcPvj, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSSymbol, ptr @_ZN15IORegistryEntry14removePropertyEPK8OSString, ptr @_ZN15IORegistryEntry14removePropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry11getPropertyEPKc, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbolPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSStringPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry11getPropertyEPKcPK15IORegistryPlanej, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbol, ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSString, ptr @_ZNK15IORegistryEntry12copyPropertyEPKc, ptr @_ZNK15IORegistryEntry24dictionaryWithPropertiesEv, ptr @_ZNK9IOService19serializePropertiesEP11OSSerialize, ptr @_ZN15IORegistryEntry13setPropertiesEP8OSObject, ptr @_ZNK15IORegistryEntry17getParentIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14applyToParentsEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry14getParentEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getChildIteratorEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry15applyToChildrenEPFvPS_PvES1_PK15IORegistryPlane, ptr @_ZNK15IORegistryEntry13getChildEntryEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7isChildEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry8isParentEPS_PK15IORegistryPlaneb, ptr @_ZNK15IORegistryEntry7inPlaneEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8getDepthEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry14attachToParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry16detachFromParentEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry13attachToChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry15detachFromChildEPS_PK15IORegistryPlane, ptr @_ZN15IORegistryEntry11detachAboveEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry9detachAllEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry8copyNameEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12compareNamesEP8OSObjectPP8OSString, ptr @_ZNK15IORegistryEntry11compareNameEP8OSStringPS1_, ptr @_ZN15IORegistryEntry7setNameEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry7setNameEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry11getLocationEPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry12copyLocationEPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPK8OSSymbolPK15IORegistryPlane, ptr @_ZN15IORegistryEntry11setLocationEPKcPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry7getPathEPcPiPK15IORegistryPlane, ptr @_ZNK15IORegistryEntry16getPathComponentEPcPiPK15IORegistryPlane, ptr @_ZN15IORegistryEntry13childFromPathEPKcPK15IORegistryPlanePcPi, ptr @_ZN9IOService4initEP15IORegistryEntryPK15IORegistryPlane, ptr @_ZN9IOService16requestTerminateEPS_j, ptr @_ZN9IOService13willTerminateEPS_j, ptr @_ZN9IOService12didTerminateEPS_jPb, ptr @_ZN9IOService15nextIdleTimeoutEyyj, ptr @_ZN9IOService18systemWillShutdownEj, ptr @_ZN9IOService22copyClientWithCategoryEPK8OSSymbol, ptr @_ZN9IOService15configureReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService12updateReportEP19IOReportChannelListjPvS2_, ptr @_ZN9IOService19_RESERVEDIOService2Ev, ptr @_ZN9IOService19_RESERVEDIOService3Ev, ptr @_ZN9IOService19_RESERVEDIOService4Ev, ptr @_ZN9IOService19_RESERVEDIOService5Ev, ptr @_ZN9IOService19_RESERVEDIOService6Ev, ptr @_ZN9IOService19_RESERVEDIOService7Ev, ptr @_ZN9IOService19_RESERVEDIOService8Ev, ptr @_ZN9IOService19_RESERVEDIOService9Ev, ptr @_ZN9IOService20_RESERVEDIOService10Ev, ptr @_ZN9IOService20_RESERVEDIOService11Ev, ptr @_ZN9IOService20_RESERVEDIOService12Ev, ptr @_ZN9IOService20_RESERVEDIOService13Ev, ptr @_ZN9IOService20_RESERVEDIOService14Ev, ptr @_ZN9IOService20_RESERVEDIOService15Ev, ptr @_ZN9IOService20_RESERVEDIOService16Ev, ptr @_ZN9IOService20_RESERVEDIOService17Ev, ptr @_ZN9IOService20_RESERVEDIOService18Ev, ptr @_ZN9IOService20_RESERVEDIOService19Ev, ptr @_ZN9IOService20_RESERVEDIOService20Ev, ptr @_ZN9IOService20_RESERVEDIOService21Ev, ptr @_ZN9IOService20_RESERVEDIOService22Ev, ptr @_ZN9IOService20_RESERVEDIOService23Ev, ptr @_ZN9IOService20_RESERVEDIOService24Ev, ptr @_ZN9IOService20_RESERVEDIOService25Ev, ptr @_ZN9IOService20_RESERVEDIOService26Ev, ptr @_ZN9IOService20_RESERVEDIOService27Ev, ptr @_ZN9IOService20_RESERVEDIOService28Ev, ptr @_ZN9IOService20_RESERVEDIOService29Ev, ptr @_ZN9IOService20_RESERVEDIOService30Ev, ptr @_ZN9IOService20_RESERVEDIOService31Ev, ptr @_ZN9IOService20_RESERVEDIOService32Ev, ptr @_ZN9IOService20_RESERVEDIOService33Ev, ptr @_ZN9IOService20_RESERVEDIOService34Ev, ptr @_ZN9IOService20_RESERVEDIOService35Ev, ptr @_ZN9IOService20_RESERVEDIOService36Ev, ptr @_ZN9IOService20_RESERVEDIOService37Ev, ptr @_ZN9IOService20_RESERVEDIOService38Ev, ptr @_ZN9IOService20_RESERVEDIOService39Ev, ptr @_ZN9IOService20_RESERVEDIOService40Ev, ptr @_ZN9IOService20_RESERVEDIOService41Ev, ptr @_ZN9IOService20_RESERVEDIOService42Ev, ptr @_ZN9IOService20_RESERVEDIOService43Ev, ptr @_ZN9IOService20_RESERVEDIOService44Ev, ptr @_ZN9IOService20_RESERVEDIOService45Ev, ptr @_ZN9IOService20_RESERVEDIOService46Ev, ptr @_ZN9IOService20_RESERVEDIOService47Ev, ptr @_ZNK9IOService8getStateEv, ptr @_ZN9IOService15registerServiceEj, ptr @_ZN9IOService5probeEPS_Pi, ptr @_ZN17IOAccelNVRMBridge5startEP9IOService, ptr @_ZN9IOService4stopEPS_, ptr @_ZN9IOService4openEPS_jPv, ptr @_ZN9IOService5closeEPS_j, ptr @_ZNK9IOService6isOpenEPKS_, ptr @_ZN9IOService10handleOpenEPS_jPv, ptr @_ZN9IOService11handleCloseEPS_j, ptr @_ZNK9IOService12handleIsOpenEPKS_, ptr @_ZN9IOService9terminateEj, ptr @_ZN9IOService8finalizeEj, ptr @_ZN9IOService18lockForArbitrationEb, ptr @_ZN9IOService20unlockForArbitrationEv, ptr @_ZN9IOService15terminateClientEPS_j, ptr @_ZN9IOService12getBusyStateEv, ptr @_ZN9IOService10adjustBusyEi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionaryPi, ptr @_ZN9IOService18matchPropertyTableEP12OSDictionary, ptr @_ZN9IOService13matchLocationEPS_, ptr @_ZN9IOService17addNeededResourceEPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPKc, ptr @_ZN9IOService15comparePropertyEP12OSDictionaryPK8OSString, ptr @_ZN9IOService17comparePropertiesEP12OSDictionaryP12OSCollection, ptr @_ZN9IOService6attachEPS_, ptr @_ZN9IOService6detachEPS_, ptr @_ZNK9IOService11getProviderEv, ptr @_ZNK9IOService11getWorkLoopEv, ptr @_ZNK9IOService19getProviderIteratorEv, ptr @_ZNK9IOService23getOpenProviderIteratorEv, ptr @_ZNK9IOService9getClientEv, ptr @_ZNK9IOService17getClientIteratorEv, ptr @_ZNK9IOService21getOpenClientIteratorEv, ptr @_ZN9IOService20callPlatformFunctionEPK8OSSymbolbPvS3_S3_S3_, ptr @_ZN9IOService20callPlatformFunctionEPKcbPvS2_S2_S2_, ptr @_ZN9IOService12getResourcesEv, ptr @_ZN9IOService20getDeviceMemoryCountEv, ptr @_ZN9IOService24getDeviceMemoryWithIndexEj, ptr @_ZN9IOService24mapDeviceMemoryWithIndexEjj, ptr @_ZN9IOService15getDeviceMemoryEv, ptr @_ZN9IOService15setDeviceMemoryEP7OSArray, ptr @_ZN9IOService17registerInterruptEiP8OSObjectPFvS1_PvPS_iES2_, ptr @_ZN9IOService19unregisterInterruptEi, ptr @_ZN9IOService16getInterruptTypeEiPi, ptr @_ZN9IOService15enableInterruptEi, ptr @_ZN9IOService16disableInterruptEi, ptr @_ZN9IOService14causeInterruptEi, ptr @_ZN9IOService12requestProbeEj, ptr @_ZN9IOService7messageEjPS_Pv, ptr @_ZN9IOService13messageClientEjP8OSObjectPvm, ptr @_ZN9IOService14messageClientsEjPvm, ptr @_ZN9IOService16registerInterestEPK8OSSymbolPFiPvS3_jPS_S3_mES3_S3_, ptr @_ZN9IOService16applyToProvidersEPFvPS_PvES1_, ptr @_ZN9IOService14applyToClientsEPFvPS_PvES1_, ptr @_ZN9IOService17applyToInterestedEPK8OSSymbolPFvP8OSObjectPvES5_, ptr @_ZN9IOService23acknowledgeNotificationEPvj, ptr @_ZN9IOService13newUserClientEP4taskPvjP12OSDictionaryPP12IOUserClient, ptr @_ZN9IOService13newUserClientEP4taskPvjPP12IOUserClient, ptr @_ZN9IOService16stringFromReturnEi, ptr @_ZN9IOService15errnoFromReturnEi, ptr @_ZN9IOService6PMinitEv, ptr @_ZN9IOService6PMstopEv, ptr @_ZN9IOService10joinPMtreeEPS_, ptr @_ZN9IOService19registerPowerDriverEPS_P14IOPMPowerStatem, ptr @_ZN9IOService23requestPowerDomainStateEmP17IOPowerConnectionm, ptr @_ZN9IOService14activityTickleEmm, ptr @_ZN9IOService17setAggressivenessEmm, ptr @_ZN9IOService17getAggressivenessEmPm, ptr @_ZN9IOService13addPowerChildEPS_, ptr @_ZN9IOService16removePowerChildEP17IOPowerConnection, ptr @_ZN9IOService18setIdleTimerPeriodEm, ptr @_ZN9IOService13setPowerStateEmPS_, ptr @_ZN9IOService27maxCapabilityForDomainStateEm, ptr @_ZN9IOService31initialPowerStateForDomainStateEm, ptr @_ZN9IOService24powerStateForDomainStateEm, ptr @_ZN9IOService22powerStateWillChangeToEmmPS_, ptr @_ZN9IOService21powerStateDidChangeToEmmPS_, ptr @_ZN9IOService13askChangeDownEm, ptr @_ZN9IOService14tellChangeDownEm, ptr @_ZN9IOService16tellNoChangeDownEm, ptr @_ZN9IOService12tellChangeUpEm, ptr @_ZN9IOService16allowPowerChangeEm, ptr @_ZN9IOService17cancelPowerChangeEm, ptr @_ZN9IOService15powerChangeDoneEm, ptr @_ZN14NVRMUserClient14externalMethodEjP25IOExternalMethodArgumentsP24IOExternalMethodDispatchP8OSObjectPv, ptr @_ZN12IOUserClient24registerNotificationPortEP8ipc_portjy, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient0Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient1Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient2Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient3Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient4Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient5Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient6Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient7Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient8Ev, ptr @_ZN12IOUserClient22_RESERVEDIOUserClient9Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient10Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient11Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient12Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient13Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient14Ev, ptr @_ZN12IOUserClient23_RESERVEDIOUserClient15Ev, ptr @_ZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionary, ptr @_ZN12IOUserClient12initWithTaskEP4taskPvj, ptr @_ZN14NVRMUserClient11clientCloseEv, ptr @_ZN12IOUserClient10clientDiedEv, ptr @_ZN12IOUserClient10getServiceEv, ptr @_ZN12IOUserClient24registerNotificationPortEP8ipc_portjj, ptr @_ZN12IOUserClient24getNotificationSemaphoreEjPP9semaphore, ptr @_ZN12IOUserClient13connectClientEPS_, ptr @_ZN14NVRMUserClient19clientMemoryForTypeEjPjPP18IOMemoryDescriptor, ptr @_ZN12IOUserClient20exportObjectToClientEP4taskP8OSObjectPS3_, ptr @_ZN12IOUserClient25getExternalMethodForIndexEj, ptr @_ZN12IOUserClient30getExternalAsyncMethodForIndexEj, ptr @_ZN12IOUserClient26getTargetAndMethodForIndexEPP9IOServicej, ptr @_ZN12IOUserClient31getAsyncTargetAndMethodForIndexEPP9IOServicej, ptr @_ZN12IOUserClient23getExternalTrapForIndexEj, ptr @_ZN12IOUserClient24getTargetAndTrapForIndexEPP9IOServicej, ptr null] }, align 8
@.str.271 = private unnamed_addr constant [18 x i8] c"IOAccelNVRMBridge\00", align 1
@_ZTVN17IOAccelNVRMBridge9MetaClassE = unnamed_addr constant { [29 x ptr] } { [29 x ptr] [ptr null, ptr null, ptr @_ZN17IOAccelNVRMBridge9MetaClassD1Ev, ptr @_ZN17IOAccelNVRMBridge9MetaClassD0Ev, ptr @_ZNK11OSMetaClass7releaseEi, ptr @_ZNK11OSMetaClass14getRetainCountEv, ptr @_ZNK11OSMetaClass6retainEv, ptr @_ZNK11OSMetaClass7releaseEv, ptr @_ZNK11OSMetaClass9serializeEP11OSSerialize, ptr @_ZNK11OSMetaClass12getMetaClassEv, ptr @_ZNK15OSMetaClassBase9isEqualToEPKS_, ptr @_ZNK11OSMetaClass12taggedRetainEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKv, ptr @_ZNK11OSMetaClass13taggedReleaseEPKvi, ptr @_ZN15OSMetaClassBase8DispatchE5IORPC, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev, ptr @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev, ptr @_ZNK17IOAccelNVRMBridge9MetaClass5allocEv, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass1Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass2Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass3Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass4Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass5Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass6Ev, ptr @_ZN11OSMetaClass21_RESERVEDOSMetaClass7Ev, ptr null] }, align 8
@.str.272 = private unnamed_addr constant [15 x i8] c"NVRMBootRaster\00", align 1
@.str.273 = private unnamed_addr constant [15 x i8] c"NVRMBootScreen\00", align 1
@.str.274 = private unnamed_addr constant [14 x i8] c"NVRMBacklight\00", align 1
@.str.275 = private unnamed_addr constant [13 x i8] c"NVRMGpuReady\00", align 1
@.str.276 = private unnamed_addr constant [19 x i8] c"NVRMBootScreenDone\00", align 1
@.str.277 = private unnamed_addr constant [59 x i8] c"NVRM-xnu: boot screen: buffer released after the takeover\0A\00", align 1
@.str.278 = private unnamed_addr constant [17 x i8] c"nvNewAccelClient\00", align 1
@.str.279 = private unnamed_addr constant [47 x i8] c"NVRM-xnu: bridge initWithTask(type %u) FAILED\0A\00", align 1
@.str.280 = private unnamed_addr constant [66 x i8] c"NVRM-xnu: bridge client created for the accelerator (rm type %u)\0A\00", align 1
@.str.281 = private unnamed_addr constant [21 x i8] c"NVRMKmsRetryClose-v1\00", align 1
@.str.282 = private unnamed_addr constant [13 x i8] c"nvGpuVaAlloc\00", align 1
@.str.283 = private unnamed_addr constant [11 x i8] c"nvGpuVaMap\00", align 1
@.str.284 = private unnamed_addr constant [12 x i8] c"nvGpuVaFree\00", align 1
@.str.285 = private unnamed_addr constant [14 x i8] c"nvSurfShareRm\00", align 1
@.str.286 = private unnamed_addr constant [14 x i8] c"nvSurfPageoff\00", align 1
@_ZTV12IOUserClient = external unnamed_addr constant { [303 x ptr] }, align 8
@_ZZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionaryE11quotaLogged = internal unnamed_addr global i32 0, align 4
@.str.287 = private unnamed_addr constant [84 x i8] c"NVRM-xnu: client refused for pid %d: %s (%d held by this process, %d of %d in use)\0A\00", align 1
@.str.288 = private unnamed_addr constant [18 x i8] c"per-process limit\00", align 1
@.str.289 = private unnamed_addr constant [35 x i8] c"slots reserved for system accounts\00", align 1
@_ZZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionaryE15tableFullLogged = internal unnamed_addr global i32 0, align 4
@.str.290 = private unnamed_addr constant [107 x i8] c"NVRM-xnu: CLIENT TABLE FULL (%d of %d in use) -- every further allocation will fail until a client closes\0A\00", align 1
@.str.291 = private unnamed_addr constant [36 x i8] c"NVRM-xnu: client fd %d opened (%s)\0A\00", align 1
@.str.292 = private unnamed_addr constant [4 x i8] c"ctl\00", align 1
@.str.293 = private unnamed_addr constant [7 x i8] c"device\00", align 1
@.str.294 = private unnamed_addr constant [74 x i8] c"NVRM-xnu: bridge close deferred for fd %d; session and provider retained\0A\00", align 1
@.str.295 = private unnamed_addr constant [31 x i8] c"NVRM-xnu: client fd %d closed\0A\00", align 1
@.str.296 = private unnamed_addr constant [48 x i8] c"NVRM-xnu: map on fd %d with no mapping context\0A\00", align 1
@.str.297 = private unnamed_addr constant [57 x i8] c"NVRM-xnu: map fd %d: sysmem +0x%llx len 0x%llx cache %u\0A\00", align 1
@.str.298 = private unnamed_addr constant [74 x i8] c"NVRM-xnu: map fd %d: device %llu range(s) first 0x%llx+0x%llx caching %u\0A\00", align 1
@_ZZN14NVRMUserClient14externalMethodEjP25IOExternalMethodArgumentsP24IOExternalMethodDispatchP8OSObjectPvE3tbl = internal unnamed_addr constant [7 x %struct.IOExternalMethodDispatch] [%struct.IOExternalMethodDispatch { ptr @_ZN14NVRMUserClient3sGoEP8OSObjectPvP25IOExternalMethodArguments, i32 1, i32 0, i32 0, i32 0 }, %struct.IOExternalMethodDispatch { ptr @_ZN14NVRMUserClient4sEscEP8OSObjectPvP25IOExternalMethodArguments, i32 1, i32 -1, i32 0, i32 -1 }, %struct.IOExternalMethodDispatch { ptr @_ZN14NVRMUserClient6sGetFdEP8OSObjectPvP25IOExternalMethodArguments, i32 0, i32 0, i32 1, i32 0 }, %struct.IOExternalMethodDispatch { ptr @_ZN14NVRMUserClient7sBindFdEP8OSObjectPvP25IOExternalMethodArguments, i32 1, i32 0, i32 0, i32 0 }, %struct.IOExternalMethodDispatch { ptr @_ZN14NVRMUserClient4sKmsEP8OSObjectPvP25IOExternalMethodArguments, i32 1, i32 -1, i32 0, i32 -1 }, %struct.IOExternalMethodDispatch { ptr @_ZN14NVRMUserClient10sKmsEventsEP8OSObjectPvP25IOExternalMethodArguments, i32 0, i32 0, i32 1, i32 0 }, %struct.IOExternalMethodDispatch { ptr @_ZN14NVRMUserClient10sWaitEventEP8OSObjectPvP25IOExternalMethodArguments, i32 2, i32 0, i32 1, i32 0 }], align 16
@.str.299 = private unnamed_addr constant [52 x i8] c"NVRM-xnu: nvkms open failed (loaded? pass 2 done?)\0A\00", align 1
@.str.300 = private unnamed_addr constant [47 x i8] c"NVRM-xnu: nvkms ioctl cmd %u size %u -> FALSE\0A\00", align 1
@_ZL13gNvEvtMatched = internal global i64 0, align 8
@.str.301 = private unnamed_addr constant [71 x i8] c"NVRM-xnu: post #%lld caller chain (nv_post_event at %p, isr-thread %d)\00", align 1
@.str.302 = private unnamed_addr constant [97 x i8] c"NVRM-xnu: nv_post_event #%lld hEvent 0x%x index %u -> %s | matched %lld, waits %lld, slept %lld\0A\00", align 1
@.str.303 = private unnamed_addr constant [17 x i8] c"connection woken\00", align 1
@.str.304 = private unnamed_addr constant [14 x i8] c"no connection\00", align 1
@_ZL11gNvEvtSlept = internal global i64 0, align 8
@_ZL14gNvEvtSleepers = internal global i32 0, align 4
@.str.305 = private unnamed_addr constant [78 x i8] c"NVRM-xnu: client %d re-bound to fd %d with a stale mapping context - cleared\0A\00", align 1
@.str.306 = private unnamed_addr constant [43 x i8] c"NVRM-xnu: client %d bound to pid %d fd %d\0A\00", align 1
@_ZZN14NVRMUserClient3escEjPvjE4once = internal unnamed_addr global i1 false, align 1
@.str.307 = private unnamed_addr constant [63 x i8] c"NVRM-xnu: esc 0x%x refused: adapter not up (run nvrmctl go 2)\0A\00", align 1
@_ZZN14NVRMUserClient3escEjPvjE5accel = internal unnamed_addr global ptr null, align 8
@.str.308 = private unnamed_addr constant [8 x i8] c"NVAccel\00", align 1
@.str.309 = private unnamed_addr constant [11 x i8] c"nvSurfVram\00", align 1
@.str.310 = private unnamed_addr constant [46 x i8] c"NVRM-xnu: esc 0x%x size %u -> RM status 0x%x\0A\00", align 1
@.str.311 = private unnamed_addr constant [7 x i8] c"-nvoff\00", align 1
@.str.312 = private unnamed_addr constant [9 x i8] c"/options\00", align 1
@gIODTPlane = external local_unnamed_addr global ptr, align 8
@.str.313 = private unnamed_addr constant [16 x i8] c"nullmoth-remove\00", align 1
@.str.314 = private unnamed_addr constant [19 x i8] c"nullmoth-nv-starts\00", align 1
@_ZZL22nvrm_guard_count_startvE7counted = internal unnamed_addr global i1 false, align 1
@.str.315 = private unnamed_addr constant [92 x i8] c"NVRM: boot guard: start %u without a display so far (the driver turns itself off after %u)\0A\00", align 1
@_ZN20IOACPIPlatformDevice9metaClassE = external local_unnamed_addr constant ptr, align 8
@.str.316 = private unnamed_addr constant [5 x i8] c"_CRS\00", align 1
@.str.317 = private unnamed_addr constant [17 x i8] c"not an Intel CPU\00", align 1
@.str.318 = private unnamed_addr constant [31 x i8] c"CPU reaches fewer than 39 bits\00", align 1
@.str.319 = private unnamed_addr constant [30 x i8] c"firmware left BAR1 below 4 GB\00", align 1
@.str.320 = private unnamed_addr constant [11 x i8] c"hw.memsize\00", align 1
@.str.321 = private unnamed_addr constant [22 x i8] c"hw.memsize unreadable\00", align 1
@.str.322 = private unnamed_addr constant [24 x i8] c"RAM reaches into 256 GB\00", align 1
@.str.323 = private unnamed_addr constant [77 x i8] c"NVRM-xnu: bar1: root port bus range %u-%u also contains PCI device %u:%u:%u\0A\00", align 1
@.str.324 = private unnamed_addr constant [72 x i8] c"NVRM-xnu: bar1: 0x%llx-0x%llx is taken by a PCI device's 0x%llx-0x%llx\0A\00", align 1
@.str.325 = private unnamed_addr constant [70 x i8] c"NVRM-xnu: bar1: 0x%llx-0x%llx overlaps a bridge window 0x%llx-0x%llx\0A\00", align 1
@.str.326 = private unnamed_addr constant [7 x i8] c"BOOT_0\00", align 1
@.str.327 = private unnamed_addr constant [21 x i8] c"PGSP_FALCON_MAILBOX0\00", align 1
@.str.328 = private unnamed_addr constant [21 x i8] c"PGSP_FALCON_MAILBOX1\00", align 1
@.str.329 = private unnamed_addr constant [35 x i8] c"PGSP_FALCON_HWCFG2(bit13=lockdown)\00", align 1
@.str.330 = private unnamed_addr constant [15 x i8] c"PGSP_FALCON_OS\00", align 1
@.str.331 = private unnamed_addr constant [20 x i8] c"PGSP_FALCON_IRQSTAT\00", align 1
@.str.332 = private unnamed_addr constant [19 x i8] c"PGSP_FALCON_ENGINE\00", align 1
@.str.333 = private unnamed_addr constant [42 x i8] c"GSP_RISCV_CPUCTL(bit7=active,bit4=halted)\00", align 1
@.str.334 = private unnamed_addr constant [19 x i8] c"GSP_RISCV_BCR_CTRL\00", align 1
@.str.335 = private unnamed_addr constant [16 x i8] c"PGSP_MAILBOX(0)\00", align 1
@.str.336 = private unnamed_addr constant [16 x i8] c"PGSP_MAILBOX(1)\00", align 1
@.str.337 = private unnamed_addr constant [19 x i8] c"PGSP_QUEUE_HEAD(0)\00", align 1
@.str.338 = private unnamed_addr constant [25 x i8] c"PFB_PRI_MMU_WPR2_ADDR_LO\00", align 1
@.str.339 = private unnamed_addr constant [25 x i8] c"PFB_PRI_MMU_WPR2_ADDR_HI\00", align 1
@.str.340 = private unnamed_addr constant [31 x i8] c"GFW_BOOT_PROGRESS(scratch05_0)\00", align 1
@.str.341 = private unnamed_addr constant [28 x i8] c"NVRM-xnu: regdump: no BAR0\0A\00", align 1
@.str.342 = private unnamed_addr constant [47 x i8] c"NVRM-xnu: regdump: withPhysicalAddress failed\0A\00", align 1
@.str.343 = private unnamed_addr constant [31 x i8] c"NVRM-xnu: regdump: map failed\0A\00", align 1
@.str.344 = private unnamed_addr constant [42 x i8] c"NVRM-xnu: regdump %-42s @0x%06x = 0x%08x\0A\00", align 1
@_ZZL20nvrm_display_publishP9IOServicejE10gPublished = internal unnamed_addr global i1 false, align 1
@.str.345 = private unnamed_addr constant [47 x i8] c"NVRM-xnu: no NVKMS kapi table, no display nub\0A\00", align 1
@.str.346 = private unnamed_addr constant [11 x i8] c"nvkms-kapi\00", align 1
@.str.347 = private unnamed_addr constant [7 x i8] c"gpu-id\00", align 1
@.str.348 = private unnamed_addr constant [12 x i8] c"phys-for-va\00", align 1
@.str.349 = private unnamed_addr constant [9 x i8] c"fb-index\00", align 1
@.str.350 = private unnamed_addr constant [93 x i8] c"NVRM-xnu: nub 0 published first; its framebuffer started (waitQuiet 0x%x) before nubs 1..%d\0A\00", align 1
@.str.351 = private unnamed_addr constant [49 x i8] c"NVRM-xnu: no NVRMDisplay nub could be published\0A\00", align 1
@.str.352 = private unnamed_addr constant [96 x i8] c"NVRM-xnu: %u NVRMDisplay nub(s) published (kapi %p, nvfbheads=%d) \E2\80\94 NVRMFB.kext matches them\0A\00", align 1
@.str.353 = private unnamed_addr constant [40 x i8] c"NVRM-xnu: bridge started with no owner\0A\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @_GLOBAL__sub_I_NVRM.cpp, ptr null }]
@llvm.global_dtors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @_GLOBAL__D_a, ptr null }]

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef i32 @_start(ptr nocapture readnone %0, ptr nocapture readnone %1) #0 {
  ret i32 0
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef i32 @_stop(ptr nocapture readnone %0, ptr nocapture readnone %1) #0 {
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplay9MetaClassC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str, ptr noundef nonnull @_ZN9IOService10gMetaClassE, i32 noundef 136) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN11NVRMDisplay9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN11NVRMDisplay9MetaClassD1Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplayC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV11NVRMDisplay, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplayC1EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV11NVRMDisplay, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: alwaysinline mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplayD2Ev(ptr noundef %0) unnamed_addr #4 align 2 {
  tail call void @_ZN9IOServiceD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone nounwind
declare void @_ZN9IOServiceD2Ev(ptr noundef) unnamed_addr #5

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplayD1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplayD0Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceD2Ev(ptr noundef %0) #15
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef 136) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplaydlEPvm(ptr noundef %0, i64 noundef %1) local_unnamed_addr #1 align 2 {
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef %1) #15
  ret void
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef nonnull ptr @_ZNK11NVRMDisplay12getMetaClassEv(ptr nocapture readnone %0) unnamed_addr #0 align 2 {
  ret ptr @_ZN11NVRMDisplay10gMetaClassE
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplay9MetaClassC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str, ptr noundef nonnull @_ZN9IOService10gMetaClassE, i32 noundef 136) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN11NVRMDisplay9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef ptr @_ZNK11NVRMDisplay9MetaClass5allocEv(ptr nocapture readnone %0) unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef 136) #15
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %2, ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV11NVRMDisplay, i64 16), ptr %2, align 8, !tbaa !4
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @_ZN11NVRMDisplaynwEm(i64 noundef %0) local_unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef %0) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplayC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV11NVRMDisplay, i64 16), ptr %0, align 8, !tbaa !4
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN11NVRMDisplayC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV11NVRMDisplay, i64 16), ptr %0, align 8, !tbaa !4
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN8OSObjectnwEm(i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone nounwind
declare void @_ZN8OSObjectdlEPvm(ptr noundef, i64 noundef) local_unnamed_addr #5

; Function Attrs: noimplicitfloat noredzone
declare i32 @sysctl_handle_quad(ptr noundef, ptr noundef, i32 noundef, ptr noundef) #3

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none)
define i64 @nv_xnu_kms_close_deferred() local_unnamed_addr #6 {
  %1 = load i64, ptr @_ZL19gNvKmsCloseDeferred, align 8, !tbaa !7
  ret i64 %1
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 2) i32 @nv_xnu_pm_enter() local_unnamed_addr #1 {
  %1 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  %2 = icmp eq ptr %1, null
  br i1 %2, label %25, label %3

3:                                                ; preds = %0
  tail call void @IOLockLock(ptr noundef nonnull %1) #15
  %4 = tail call ptr @current_thread() #16
  %5 = load ptr, ptr @_ZL10gNvPmOwner, align 8, !tbaa !10
  %6 = icmp eq ptr %4, %5
  br i1 %6, label %22, label %7

7:                                                ; preds = %3
  %8 = load i8, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12, !range !14, !noundef !15
  %9 = trunc nuw i8 %8 to i1
  br i1 %9, label %10, label %19

10:                                               ; preds = %7
  %11 = tail call i64 @OSAddAtomic64(i64 noundef 1, ptr noundef nonnull @_ZL11gNvPmWaited) #15
  %12 = load i8, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12, !range !14, !noundef !15
  %13 = trunc nuw i8 %12 to i1
  br i1 %13, label %14, label %19

14:                                               ; preds = %10, %14
  %15 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  %16 = tail call i32 @"\01_IOLockSleep_darwin14"(ptr noundef %15, ptr noundef nonnull @_ZL11gNvPmClosed, i32 noundef 0) #15
  %17 = load i8, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12, !range !14, !noundef !15
  %18 = trunc nuw i8 %17 to i1
  br i1 %18, label %14, label %19, !llvm.loop !16

19:                                               ; preds = %14, %10, %7
  %20 = load i32, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  br label %22

22:                                               ; preds = %3, %19
  %23 = phi i32 [ 1, %19 ], [ 0, %3 ]
  %24 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %24) #15
  br label %25

25:                                               ; preds = %22, %0
  %26 = phi i32 [ 0, %0 ], [ %23, %22 ]
  ret i32 %26
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOLockLock(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noimplicitfloat noredzone nosync nounwind willreturn memory(none)
declare ptr @current_thread() local_unnamed_addr #7

; Function Attrs: noimplicitfloat noredzone
declare void @IOLockUnlock(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @"\01_IOLockSleep_darwin14"(ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @nv_xnu_pm_exit(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp ne i32 %0, 0
  %3 = load ptr, ptr @_ZL9gNvPmGate, align 8
  %4 = icmp ne ptr %3, null
  %5 = select i1 %2, i1 %4, i1 false
  br i1 %5, label %6, label %17

6:                                                ; preds = %1
  tail call void @IOLockLock(ptr noundef nonnull %3) #15
  %7 = load i32, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %8 = add nsw i32 %7, -1
  store i32 %8, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %6
  %11 = load i8, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12, !range !14, !noundef !15
  %12 = trunc nuw i8 %11 to i1
  br i1 %12, label %13, label %15

13:                                               ; preds = %10
  %14 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @"\01_IOLockWakeup_darwin14"(ptr noundef %14, ptr noundef nonnull @_ZL10gNvPmUsers, i1 noundef zeroext false) #15
  br label %15

15:                                               ; preds = %13, %10, %6
  %16 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %16) #15
  br label %17

17:                                               ; preds = %1, %15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @"\01_IOLockWakeup_darwin14"(ptr noundef, ptr noundef, i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @nv_xnu_pmap_owner(i64 noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef writeonly %3) local_unnamed_addr #1 {
  %5 = icmp ne ptr %1, null
  %6 = icmp ne i64 %2, 0
  %7 = and i1 %5, %6
  br i1 %7, label %8, label %9

8:                                                ; preds = %4
  store i8 0, ptr %1, align 1, !tbaa !20
  br label %9

9:                                                ; preds = %8, %4
  %10 = icmp eq ptr %3, null
  br i1 %10, label %12, label %11

11:                                               ; preds = %9
  store i64 0, ptr %3, align 8, !tbaa !7
  br label %12

12:                                               ; preds = %11, %9
  %13 = icmp ne i64 %0, 0
  %14 = load ptr, ptr @_ZL14gNvClientsLock, align 8
  %15 = icmp ne ptr %14, null
  %16 = select i1 %13, i1 %15, i1 false
  br i1 %16, label %17, label %55

17:                                               ; preds = %12
  tail call void @IOLockLock(ptr noundef nonnull %14) #15
  br label %36

18:                                               ; preds = %36
  %19 = or disjoint i64 %37, 1
  %20 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %19
  %21 = load i64, ptr %20, align 16, !tbaa !21
  %22 = icmp eq i64 %21, %0
  br i1 %22, label %41, label %23

23:                                               ; preds = %18
  %24 = or disjoint i64 %37, 2
  %25 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %24
  %26 = load i64, ptr %25, align 16, !tbaa !21
  %27 = icmp eq i64 %26, %0
  br i1 %27, label %41, label %28

28:                                               ; preds = %23
  %29 = or disjoint i64 %37, 3
  %30 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %29
  %31 = load i64, ptr %30, align 16, !tbaa !21
  %32 = icmp eq i64 %31, %0
  br i1 %32, label %41, label %33

33:                                               ; preds = %28
  %34 = add nuw nsw i64 %37, 4
  %35 = icmp eq i64 %34, 256
  br i1 %35, label %52, label %36, !llvm.loop !23

36:                                               ; preds = %33, %17
  %37 = phi i64 [ 0, %17 ], [ %34, %33 ]
  %38 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %37
  %39 = load i64, ptr %38, align 16, !tbaa !21
  %40 = icmp eq i64 %39, %0
  br i1 %40, label %41, label %18

41:                                               ; preds = %28, %23, %18, %36
  %42 = phi ptr [ %38, %36 ], [ %20, %18 ], [ %25, %23 ], [ %30, %28 ]
  %43 = getelementptr inbounds i8, ptr %42, i64 8
  %44 = load i32, ptr %43, align 8, !tbaa !24
  br i1 %7, label %45, label %48

45:                                               ; preds = %41
  %46 = getelementptr inbounds i8, ptr %42, i64 24
  %47 = tail call i64 @"\01_strlcpy"(ptr noundef nonnull %1, ptr noundef nonnull %46, i64 noundef %2) #15
  br label %48

48:                                               ; preds = %45, %41
  br i1 %10, label %52, label %49

49:                                               ; preds = %48
  %50 = getelementptr inbounds i8, ptr %42, i64 16
  %51 = load i64, ptr %50, align 16, !tbaa !25
  store i64 %51, ptr %3, align 8, !tbaa !7
  br label %52

52:                                               ; preds = %33, %48, %49
  %53 = phi i32 [ %44, %49 ], [ %44, %48 ], [ -1, %33 ]
  %54 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %54) #15
  br label %55

55:                                               ; preds = %12, %52
  %56 = phi i32 [ %53, %52 ], [ -1, %12 ]
  ret i32 %56
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #8

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #8

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @nv_xnu_lookup_fd(i32 noundef %0, ptr noundef writeonly %1, ptr noundef writeonly %2) local_unnamed_addr #1 {
  %4 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  %5 = icmp eq ptr %4, null
  br i1 %5, label %69, label %6

6:                                                ; preds = %3
  %7 = tail call i32 @proc_selfpid() #15
  %8 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockLock(ptr noundef %8) #15
  br label %12

9:                                                ; preds = %26
  br i1 %30, label %34, label %10

10:                                               ; preds = %9
  %11 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %11) #15
  br label %58

12:                                               ; preds = %6, %26
  %13 = phi i64 [ 0, %6 ], [ %28, %26 ]
  %14 = getelementptr inbounds [32768 x ptr], ptr @_ZL10gNvClients, i64 0, i64 %13
  %15 = load ptr, ptr %14, align 8, !tbaa !10
  %16 = icmp eq ptr %15, null
  br i1 %16, label %26, label %17

17:                                               ; preds = %12
  %18 = getelementptr inbounds i8, ptr %15, i64 440
  %19 = load i32, ptr %18, align 8, !tbaa !26
  %20 = icmp eq i32 %19, %7
  br i1 %20, label %21, label %26

21:                                               ; preds = %17
  %22 = getelementptr inbounds i8, ptr %15, i64 448
  %23 = load i32, ptr %22, align 8, !tbaa !37
  %24 = icmp eq i32 %23, %0
  %25 = select i1 %24, ptr %15, ptr null
  br label %26

26:                                               ; preds = %21, %17, %12
  %27 = phi ptr [ null, %17 ], [ null, %12 ], [ %25, %21 ]
  %28 = add nuw nsw i64 %13, 1
  %29 = icmp ult i64 %13, 32767
  %30 = icmp eq ptr %27, null
  %31 = select i1 %29, i1 %30, i1 false
  br i1 %31, label %12, label %9, !llvm.loop !38

32:                                               ; preds = %52
  %33 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %33) #15
  br i1 %56, label %69, label %58

34:                                               ; preds = %9, %52
  %35 = phi i64 [ %54, %52 ], [ 0, %9 ]
  %36 = getelementptr inbounds [32768 x ptr], ptr @_ZL10gNvClients, i64 0, i64 %35
  %37 = load ptr, ptr %36, align 8, !tbaa !10
  %38 = icmp eq ptr %37, null
  br i1 %38, label %52, label %39

39:                                               ; preds = %34
  %40 = getelementptr inbounds i8, ptr %37, i64 440
  %41 = load i32, ptr %40, align 8, !tbaa !26
  %42 = icmp eq i32 %41, %7
  br i1 %42, label %43, label %52

43:                                               ; preds = %39
  %44 = getelementptr inbounds i8, ptr %37, i64 444
  %45 = load i8, ptr %44, align 4, !tbaa !39, !range !14, !noundef !15
  %46 = trunc nuw i8 %45 to i1
  br i1 %46, label %52, label %47

47:                                               ; preds = %43
  %48 = getelementptr inbounds i8, ptr %37, i64 436
  %49 = load i32, ptr %48, align 4, !tbaa !40
  %50 = icmp eq i32 %49, %0
  %51 = select i1 %50, ptr %37, ptr null
  br label %52

52:                                               ; preds = %47, %43, %39, %34
  %53 = phi ptr [ null, %43 ], [ null, %39 ], [ null, %34 ], [ %51, %47 ]
  %54 = add nuw nsw i64 %35, 1
  %55 = icmp ult i64 %35, 32767
  %56 = icmp eq ptr %53, null
  %57 = select i1 %55, i1 %56, i1 false
  br i1 %57, label %34, label %32, !llvm.loop !41

58:                                               ; preds = %10, %32
  %59 = phi ptr [ %27, %10 ], [ %53, %32 ]
  %60 = icmp eq ptr %1, null
  br i1 %60, label %62, label %61

61:                                               ; preds = %58
  store ptr %59, ptr %1, align 8, !tbaa !10
  br label %62

62:                                               ; preds = %61, %58
  %63 = icmp eq ptr %2, null
  br i1 %63, label %67, label %64

64:                                               ; preds = %62
  %65 = getelementptr inbounds i8, ptr %59, i64 432
  %66 = load i8, ptr %65, align 8, !tbaa !42, !range !14, !noundef !15
  store i8 %66, ptr %2, align 1, !tbaa !20
  br label %67

67:                                               ; preds = %64, %62
  %68 = getelementptr inbounds i8, ptr %59, i64 232
  br label %69

69:                                               ; preds = %67, %32, %3
  %70 = phi ptr [ null, %3 ], [ %68, %67 ], [ null, %32 ]
  ret ptr %70
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @proc_selfpid() local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @nv_xnu_mmap_context(ptr noundef %0) local_unnamed_addr #1 {
  %2 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %3 = icmp eq ptr %2, null
  %4 = getelementptr inbounds i8, ptr %2, i64 352
  %5 = select i1 %3, ptr null, ptr %4
  ret ptr %5
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM9MetaClassC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str.15, ptr noundef nonnull @_ZN9IOService10gMetaClassE, i32 noundef 1288) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN4NVRM9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN4NVRM9MetaClassD1Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV4NVRM, i64 16), ptr %0, align 8, !tbaa !4
  %3 = getelementptr inbounds i8, ptr %0, i64 136
  store i32 -1, ptr %3, align 8, !tbaa !43
  %4 = getelementptr inbounds i8, ptr %0, i64 140
  store i32 0, ptr %4, align 4, !tbaa !54
  %5 = getelementptr inbounds i8, ptr %0, i64 144
  store i32 0, ptr %5, align 8, !tbaa !55
  %6 = getelementptr inbounds i8, ptr %0, i64 148
  store i32 0, ptr %6, align 4, !tbaa !56
  %7 = getelementptr inbounds i8, ptr %0, i64 152
  store ptr null, ptr %7, align 8, !tbaa !57
  %8 = getelementptr inbounds i8, ptr %0, i64 160
  store i32 0, ptr %8, align 8, !tbaa !58
  %9 = getelementptr inbounds i8, ptr %0, i64 164
  store i32 0, ptr %9, align 4, !tbaa !59
  %10 = getelementptr inbounds i8, ptr %0, i64 168
  store i32 0, ptr %10, align 8, !tbaa !60
  %11 = getelementptr inbounds i8, ptr %0, i64 172
  store i32 10000, ptr %11, align 4, !tbaa !61
  %12 = getelementptr inbounds i8, ptr %0, i64 176
  store i8 0, ptr %12, align 8, !tbaa !62
  %13 = getelementptr inbounds i8, ptr %0, i64 180
  store volatile i32 0, ptr %13, align 4, !tbaa !63
  %14 = getelementptr inbounds i8, ptr %0, i64 184
  store volatile i32 0, ptr %14, align 8, !tbaa !64
  %15 = getelementptr inbounds i8, ptr %0, i64 188
  store i8 0, ptr %15, align 4, !tbaa !65
  %16 = getelementptr inbounds i8, ptr %0, i64 192
  store i32 0, ptr %16, align 8, !tbaa !66
  %17 = getelementptr inbounds i8, ptr %0, i64 200
  store i8 0, ptr %17, align 8, !tbaa !67
  %18 = getelementptr inbounds i8, ptr %0, i64 204
  %19 = getelementptr inbounds i8, ptr %0, i64 288
  %20 = getelementptr inbounds i8, ptr %0, i64 328
  %21 = getelementptr inbounds i8, ptr %0, i64 364
  %22 = getelementptr inbounds i8, ptr %0, i64 408
  %23 = getelementptr inbounds i8, ptr %0, i64 1016
  %24 = getelementptr inbounds i8, ptr %0, i64 1028
  store i32 0, ptr %24, align 4, !tbaa !68
  %25 = getelementptr inbounds i8, ptr %0, i64 1032
  store i8 0, ptr %25, align 8, !tbaa !69
  %26 = getelementptr inbounds i8, ptr %0, i64 1036
  store i32 0, ptr %26, align 4, !tbaa !70
  %27 = getelementptr inbounds i8, ptr %0, i64 1040
  store i32 0, ptr %27, align 8, !tbaa !71
  %28 = getelementptr inbounds i8, ptr %0, i64 1048
  %29 = getelementptr inbounds i8, ptr %0, i64 1108
  %30 = getelementptr inbounds i8, ptr %0, i64 1148
  store i32 0, ptr %30, align 4, !tbaa !72
  %31 = getelementptr inbounds i8, ptr %0, i64 1152
  store i8 0, ptr %31, align 8, !tbaa !73
  %32 = getelementptr inbounds i8, ptr %0, i64 1153
  store i8 0, ptr %32, align 1, !tbaa !74
  %33 = getelementptr inbounds i8, ptr %0, i64 1156
  %34 = getelementptr inbounds i8, ptr %0, i64 1264
  store i8 0, ptr %34, align 8, !tbaa !75
  %35 = getelementptr inbounds i8, ptr %0, i64 1265
  store i8 0, ptr %35, align 1, !tbaa !76
  %36 = getelementptr inbounds i8, ptr %0, i64 1268
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(78) %18, i8 0, i64 78, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(34) %19, i8 0, i64 34, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(35) %20, i8 0, i64 35, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(40) %21, i8 0, i64 40, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(603) %22, i8 0, i64 603, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(11) %23, i8 0, i64 11, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(58) %28, i8 0, i64 58, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(38) %29, i8 0, i64 38, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(103) %33, i8 0, i64 103, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(20) %36, i8 0, i64 20, i1 false)
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #9

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMC1EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV4NVRM, i64 16), ptr %0, align 8, !tbaa !4
  %3 = getelementptr inbounds i8, ptr %0, i64 136
  store i32 -1, ptr %3, align 8, !tbaa !43
  %4 = getelementptr inbounds i8, ptr %0, i64 140
  store i32 0, ptr %4, align 4, !tbaa !54
  %5 = getelementptr inbounds i8, ptr %0, i64 144
  store i32 0, ptr %5, align 8, !tbaa !55
  %6 = getelementptr inbounds i8, ptr %0, i64 148
  store i32 0, ptr %6, align 4, !tbaa !56
  %7 = getelementptr inbounds i8, ptr %0, i64 152
  store ptr null, ptr %7, align 8, !tbaa !57
  %8 = getelementptr inbounds i8, ptr %0, i64 160
  store i32 0, ptr %8, align 8, !tbaa !58
  %9 = getelementptr inbounds i8, ptr %0, i64 164
  store i32 0, ptr %9, align 4, !tbaa !59
  %10 = getelementptr inbounds i8, ptr %0, i64 168
  store i32 0, ptr %10, align 8, !tbaa !60
  %11 = getelementptr inbounds i8, ptr %0, i64 172
  store i32 10000, ptr %11, align 4, !tbaa !61
  %12 = getelementptr inbounds i8, ptr %0, i64 176
  store i8 0, ptr %12, align 8, !tbaa !62
  %13 = getelementptr inbounds i8, ptr %0, i64 180
  store volatile i32 0, ptr %13, align 4, !tbaa !63
  %14 = getelementptr inbounds i8, ptr %0, i64 184
  store volatile i32 0, ptr %14, align 8, !tbaa !64
  %15 = getelementptr inbounds i8, ptr %0, i64 188
  store i8 0, ptr %15, align 4, !tbaa !65
  %16 = getelementptr inbounds i8, ptr %0, i64 192
  store i32 0, ptr %16, align 8, !tbaa !66
  %17 = getelementptr inbounds i8, ptr %0, i64 200
  store i8 0, ptr %17, align 8, !tbaa !67
  %18 = getelementptr inbounds i8, ptr %0, i64 204
  %19 = getelementptr inbounds i8, ptr %0, i64 288
  %20 = getelementptr inbounds i8, ptr %0, i64 328
  %21 = getelementptr inbounds i8, ptr %0, i64 364
  %22 = getelementptr inbounds i8, ptr %0, i64 408
  %23 = getelementptr inbounds i8, ptr %0, i64 1016
  %24 = getelementptr inbounds i8, ptr %0, i64 1028
  store i32 0, ptr %24, align 4, !tbaa !68
  %25 = getelementptr inbounds i8, ptr %0, i64 1032
  store i8 0, ptr %25, align 8, !tbaa !69
  %26 = getelementptr inbounds i8, ptr %0, i64 1036
  store i32 0, ptr %26, align 4, !tbaa !70
  %27 = getelementptr inbounds i8, ptr %0, i64 1040
  store i32 0, ptr %27, align 8, !tbaa !71
  %28 = getelementptr inbounds i8, ptr %0, i64 1048
  %29 = getelementptr inbounds i8, ptr %0, i64 1108
  %30 = getelementptr inbounds i8, ptr %0, i64 1148
  store i32 0, ptr %30, align 4, !tbaa !72
  %31 = getelementptr inbounds i8, ptr %0, i64 1152
  store i8 0, ptr %31, align 8, !tbaa !73
  %32 = getelementptr inbounds i8, ptr %0, i64 1153
  store i8 0, ptr %32, align 1, !tbaa !74
  %33 = getelementptr inbounds i8, ptr %0, i64 1156
  %34 = getelementptr inbounds i8, ptr %0, i64 1264
  store i8 0, ptr %34, align 8, !tbaa !75
  %35 = getelementptr inbounds i8, ptr %0, i64 1265
  store i8 0, ptr %35, align 1, !tbaa !76
  %36 = getelementptr inbounds i8, ptr %0, i64 1268
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(78) %18, i8 0, i64 78, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(34) %19, i8 0, i64 34, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(35) %20, i8 0, i64 35, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(40) %21, i8 0, i64 40, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(603) %22, i8 0, i64 603, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(11) %23, i8 0, i64 11, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(58) %28, i8 0, i64 58, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(38) %29, i8 0, i64 38, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(103) %33, i8 0, i64 103, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(20) %36, i8 0, i64 20, i1 false)
  ret void
}

; Function Attrs: alwaysinline mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMD2Ev(ptr noundef %0) unnamed_addr #4 align 2 {
  tail call void @_ZN9IOServiceD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMD1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMD0Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceD2Ev(ptr noundef %0) #15
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef 1288) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMdlEPvm(ptr noundef %0, i64 noundef %1) local_unnamed_addr #1 align 2 {
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef %1) #15
  ret void
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef nonnull ptr @_ZNK4NVRM12getMetaClassEv(ptr nocapture readnone %0) unnamed_addr #0 align 2 {
  ret ptr @_ZN4NVRM10gMetaClassE
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM9MetaClassC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str.15, ptr noundef nonnull @_ZN9IOService10gMetaClassE, i32 noundef 1288) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN4NVRM9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef ptr @_ZNK4NVRM9MetaClass5allocEv(ptr nocapture readnone %0) unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef 1288) #15
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %2, ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV4NVRM, i64 16), ptr %2, align 8, !tbaa !4
  %3 = getelementptr inbounds i8, ptr %2, i64 136
  store i32 -1, ptr %3, align 8, !tbaa !43
  %4 = getelementptr inbounds i8, ptr %2, i64 140
  store i32 0, ptr %4, align 4, !tbaa !54
  %5 = getelementptr inbounds i8, ptr %2, i64 144
  store i32 0, ptr %5, align 8, !tbaa !55
  %6 = getelementptr inbounds i8, ptr %2, i64 148
  store i32 0, ptr %6, align 4, !tbaa !56
  %7 = getelementptr inbounds i8, ptr %2, i64 152
  store ptr null, ptr %7, align 8, !tbaa !57
  %8 = getelementptr inbounds i8, ptr %2, i64 160
  store i32 0, ptr %8, align 8, !tbaa !58
  %9 = getelementptr inbounds i8, ptr %2, i64 164
  store i32 0, ptr %9, align 4, !tbaa !59
  %10 = getelementptr inbounds i8, ptr %2, i64 168
  store i32 0, ptr %10, align 8, !tbaa !60
  %11 = getelementptr inbounds i8, ptr %2, i64 172
  store i32 10000, ptr %11, align 4, !tbaa !61
  %12 = getelementptr inbounds i8, ptr %2, i64 176
  store i8 0, ptr %12, align 8, !tbaa !62
  %13 = getelementptr inbounds i8, ptr %2, i64 180
  store volatile i32 0, ptr %13, align 4, !tbaa !63
  %14 = getelementptr inbounds i8, ptr %2, i64 184
  store volatile i32 0, ptr %14, align 8, !tbaa !64
  %15 = getelementptr inbounds i8, ptr %2, i64 188
  store i8 0, ptr %15, align 4, !tbaa !65
  %16 = getelementptr inbounds i8, ptr %2, i64 192
  store i32 0, ptr %16, align 8, !tbaa !66
  %17 = getelementptr inbounds i8, ptr %2, i64 200
  store i8 0, ptr %17, align 8, !tbaa !67
  %18 = getelementptr inbounds i8, ptr %2, i64 204
  %19 = getelementptr inbounds i8, ptr %2, i64 288
  %20 = getelementptr inbounds i8, ptr %2, i64 328
  %21 = getelementptr inbounds i8, ptr %2, i64 364
  %22 = getelementptr inbounds i8, ptr %2, i64 408
  %23 = getelementptr inbounds i8, ptr %2, i64 1016
  %24 = getelementptr inbounds i8, ptr %2, i64 1028
  store i32 0, ptr %24, align 4, !tbaa !68
  %25 = getelementptr inbounds i8, ptr %2, i64 1032
  store i8 0, ptr %25, align 8, !tbaa !69
  %26 = getelementptr inbounds i8, ptr %2, i64 1036
  store i32 0, ptr %26, align 4, !tbaa !70
  %27 = getelementptr inbounds i8, ptr %2, i64 1040
  store i32 0, ptr %27, align 8, !tbaa !71
  %28 = getelementptr inbounds i8, ptr %2, i64 1048
  %29 = getelementptr inbounds i8, ptr %2, i64 1108
  %30 = getelementptr inbounds i8, ptr %2, i64 1148
  store i32 0, ptr %30, align 4, !tbaa !72
  %31 = getelementptr inbounds i8, ptr %2, i64 1152
  store i8 0, ptr %31, align 8, !tbaa !73
  %32 = getelementptr inbounds i8, ptr %2, i64 1153
  store i8 0, ptr %32, align 1, !tbaa !74
  %33 = getelementptr inbounds i8, ptr %2, i64 1156
  %34 = getelementptr inbounds i8, ptr %2, i64 1264
  store i8 0, ptr %34, align 8, !tbaa !75
  %35 = getelementptr inbounds i8, ptr %2, i64 1265
  store i8 0, ptr %35, align 1, !tbaa !76
  %36 = getelementptr inbounds i8, ptr %2, i64 1268
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(78) %18, i8 0, i64 78, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(34) %19, i8 0, i64 34, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(35) %20, i8 0, i64 35, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(40) %21, i8 0, i64 40, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(603) %22, i8 0, i64 603, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(11) %23, i8 0, i64 11, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(58) %28, i8 0, i64 58, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(38) %29, i8 0, i64 38, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(103) %33, i8 0, i64 103, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(20) %36, i8 0, i64 20, i1 false)
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @_ZN4NVRMnwEm(i64 noundef %0) local_unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef %0) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV4NVRM, i64 16), ptr %0, align 8, !tbaa !4
  %2 = getelementptr inbounds i8, ptr %0, i64 136
  store i32 -1, ptr %2, align 8, !tbaa !43
  %3 = getelementptr inbounds i8, ptr %0, i64 140
  store i32 0, ptr %3, align 4, !tbaa !54
  %4 = getelementptr inbounds i8, ptr %0, i64 144
  store i32 0, ptr %4, align 8, !tbaa !55
  %5 = getelementptr inbounds i8, ptr %0, i64 148
  store i32 0, ptr %5, align 4, !tbaa !56
  %6 = getelementptr inbounds i8, ptr %0, i64 152
  store ptr null, ptr %6, align 8, !tbaa !57
  %7 = getelementptr inbounds i8, ptr %0, i64 160
  store i32 0, ptr %7, align 8, !tbaa !58
  %8 = getelementptr inbounds i8, ptr %0, i64 164
  store i32 0, ptr %8, align 4, !tbaa !59
  %9 = getelementptr inbounds i8, ptr %0, i64 168
  store i32 0, ptr %9, align 8, !tbaa !60
  %10 = getelementptr inbounds i8, ptr %0, i64 172
  store i32 10000, ptr %10, align 4, !tbaa !61
  %11 = getelementptr inbounds i8, ptr %0, i64 176
  store i8 0, ptr %11, align 8, !tbaa !62
  %12 = getelementptr inbounds i8, ptr %0, i64 180
  store volatile i32 0, ptr %12, align 4, !tbaa !63
  %13 = getelementptr inbounds i8, ptr %0, i64 184
  store volatile i32 0, ptr %13, align 8, !tbaa !64
  %14 = getelementptr inbounds i8, ptr %0, i64 188
  store i8 0, ptr %14, align 4, !tbaa !65
  %15 = getelementptr inbounds i8, ptr %0, i64 192
  store i32 0, ptr %15, align 8, !tbaa !66
  %16 = getelementptr inbounds i8, ptr %0, i64 200
  store i8 0, ptr %16, align 8, !tbaa !67
  %17 = getelementptr inbounds i8, ptr %0, i64 204
  %18 = getelementptr inbounds i8, ptr %0, i64 288
  %19 = getelementptr inbounds i8, ptr %0, i64 328
  %20 = getelementptr inbounds i8, ptr %0, i64 364
  %21 = getelementptr inbounds i8, ptr %0, i64 408
  %22 = getelementptr inbounds i8, ptr %0, i64 1016
  %23 = getelementptr inbounds i8, ptr %0, i64 1028
  store i32 0, ptr %23, align 4, !tbaa !68
  %24 = getelementptr inbounds i8, ptr %0, i64 1032
  store i8 0, ptr %24, align 8, !tbaa !69
  %25 = getelementptr inbounds i8, ptr %0, i64 1036
  store i32 0, ptr %25, align 4, !tbaa !70
  %26 = getelementptr inbounds i8, ptr %0, i64 1040
  store i32 0, ptr %26, align 8, !tbaa !71
  %27 = getelementptr inbounds i8, ptr %0, i64 1048
  %28 = getelementptr inbounds i8, ptr %0, i64 1108
  %29 = getelementptr inbounds i8, ptr %0, i64 1148
  store i32 0, ptr %29, align 4, !tbaa !72
  %30 = getelementptr inbounds i8, ptr %0, i64 1152
  store i8 0, ptr %30, align 8, !tbaa !73
  %31 = getelementptr inbounds i8, ptr %0, i64 1153
  store i8 0, ptr %31, align 1, !tbaa !74
  %32 = getelementptr inbounds i8, ptr %0, i64 1156
  %33 = getelementptr inbounds i8, ptr %0, i64 1264
  store i8 0, ptr %33, align 8, !tbaa !75
  %34 = getelementptr inbounds i8, ptr %0, i64 1265
  store i8 0, ptr %34, align 1, !tbaa !76
  %35 = getelementptr inbounds i8, ptr %0, i64 1268
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(78) %17, i8 0, i64 78, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(34) %18, i8 0, i64 34, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(35) %19, i8 0, i64 35, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(40) %20, i8 0, i64 40, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(603) %21, i8 0, i64 603, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(11) %22, i8 0, i64 11, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(58) %27, i8 0, i64 58, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(38) %28, i8 0, i64 38, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(103) %32, i8 0, i64 103, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(20) %35, i8 0, i64 20, i1 false)
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRMC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN9IOServiceC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2136) (i8, ptr @_ZTV4NVRM, i64 16), ptr %0, align 8, !tbaa !4
  %2 = getelementptr inbounds i8, ptr %0, i64 136
  store i32 -1, ptr %2, align 8, !tbaa !43
  %3 = getelementptr inbounds i8, ptr %0, i64 140
  store i32 0, ptr %3, align 4, !tbaa !54
  %4 = getelementptr inbounds i8, ptr %0, i64 144
  store i32 0, ptr %4, align 8, !tbaa !55
  %5 = getelementptr inbounds i8, ptr %0, i64 148
  store i32 0, ptr %5, align 4, !tbaa !56
  %6 = getelementptr inbounds i8, ptr %0, i64 152
  store ptr null, ptr %6, align 8, !tbaa !57
  %7 = getelementptr inbounds i8, ptr %0, i64 160
  store i32 0, ptr %7, align 8, !tbaa !58
  %8 = getelementptr inbounds i8, ptr %0, i64 164
  store i32 0, ptr %8, align 4, !tbaa !59
  %9 = getelementptr inbounds i8, ptr %0, i64 168
  store i32 0, ptr %9, align 8, !tbaa !60
  %10 = getelementptr inbounds i8, ptr %0, i64 172
  store i32 10000, ptr %10, align 4, !tbaa !61
  %11 = getelementptr inbounds i8, ptr %0, i64 176
  store i8 0, ptr %11, align 8, !tbaa !62
  %12 = getelementptr inbounds i8, ptr %0, i64 180
  store volatile i32 0, ptr %12, align 4, !tbaa !63
  %13 = getelementptr inbounds i8, ptr %0, i64 184
  store volatile i32 0, ptr %13, align 8, !tbaa !64
  %14 = getelementptr inbounds i8, ptr %0, i64 188
  store i8 0, ptr %14, align 4, !tbaa !65
  %15 = getelementptr inbounds i8, ptr %0, i64 192
  store i32 0, ptr %15, align 8, !tbaa !66
  %16 = getelementptr inbounds i8, ptr %0, i64 200
  store i8 0, ptr %16, align 8, !tbaa !67
  %17 = getelementptr inbounds i8, ptr %0, i64 204
  %18 = getelementptr inbounds i8, ptr %0, i64 288
  %19 = getelementptr inbounds i8, ptr %0, i64 328
  %20 = getelementptr inbounds i8, ptr %0, i64 364
  %21 = getelementptr inbounds i8, ptr %0, i64 408
  %22 = getelementptr inbounds i8, ptr %0, i64 1016
  %23 = getelementptr inbounds i8, ptr %0, i64 1028
  store i32 0, ptr %23, align 4, !tbaa !68
  %24 = getelementptr inbounds i8, ptr %0, i64 1032
  store i8 0, ptr %24, align 8, !tbaa !69
  %25 = getelementptr inbounds i8, ptr %0, i64 1036
  store i32 0, ptr %25, align 4, !tbaa !70
  %26 = getelementptr inbounds i8, ptr %0, i64 1040
  store i32 0, ptr %26, align 8, !tbaa !71
  %27 = getelementptr inbounds i8, ptr %0, i64 1048
  %28 = getelementptr inbounds i8, ptr %0, i64 1108
  %29 = getelementptr inbounds i8, ptr %0, i64 1148
  store i32 0, ptr %29, align 4, !tbaa !72
  %30 = getelementptr inbounds i8, ptr %0, i64 1152
  store i8 0, ptr %30, align 8, !tbaa !73
  %31 = getelementptr inbounds i8, ptr %0, i64 1153
  store i8 0, ptr %31, align 1, !tbaa !74
  %32 = getelementptr inbounds i8, ptr %0, i64 1156
  %33 = getelementptr inbounds i8, ptr %0, i64 1264
  store i8 0, ptr %33, align 8, !tbaa !75
  %34 = getelementptr inbounds i8, ptr %0, i64 1265
  store i8 0, ptr %34, align 1, !tbaa !76
  %35 = getelementptr inbounds i8, ptr %0, i64 1268
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(78) %17, i8 0, i64 78, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(34) %18, i8 0, i64 34, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(35) %19, i8 0, i64 35, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(40) %20, i8 0, i64 40, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(603) %21, i8 0, i64 603, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(11) %22, i8 0, i64 11, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(58) %27, i8 0, i64 58, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(38) %28, i8 0, i64 38, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(103) %32, i8 0, i64 103, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(20) %35, i8 0, i64 20, i1 false)
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @_ZN4NVRM5probeEP9IOServicePi(ptr noundef %0, ptr noundef %1, ptr noundef %2) unnamed_addr #1 align 2 {
  %4 = tail call fastcc zeroext i1 @_ZL15nvrm_driver_offv() #17
  br i1 %4, label %31, label %5

5:                                                ; preds = %3
  %6 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV9IOService, i64 1480), align 8
  %7 = tail call ptr %6(ptr noundef %0, ptr noundef %1, ptr noundef %2) #15
  %8 = load ptr, ptr @_ZN11IOPCIDevice9metaClassE, align 8, !tbaa !10
  %9 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %1, ptr noundef %8) #15
  %10 = icmp eq ptr %9, null
  br i1 %10, label %31, label %11

11:                                               ; preds = %5
  %12 = tail call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef nonnull %9, i64 noundef 11) #15
  %13 = tail call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef nonnull %9, i64 noundef 10) #15
  %14 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef nonnull %9, i64 noundef 0) #15
  %15 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef nonnull %9, i64 noundef 2) #15
  %16 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef nonnull %9, i64 noundef 44) #15
  %17 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef nonnull %9, i64 noundef 46) #15
  %18 = zext i16 %14 to i32
  %19 = zext i16 %15 to i32
  %20 = zext i8 %12 to i32
  %21 = zext i8 %13 to i32
  %22 = zext i16 %16 to i32
  %23 = zext i16 %17 to i32
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.16, i32 noundef %18, i32 noundef %19, i32 noundef %20, i32 noundef %21, i32 noundef %22, i32 noundef %23) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.16, i32 noundef %18, i32 noundef %19, i32 noundef %20, i32 noundef %21, i32 noundef %22, i32 noundef %23) #15
  %24 = tail call zeroext i8 @rm_is_supported_pci_device(i8 noundef zeroext %12, i8 noundef zeroext %13, i16 noundef zeroext %14, i16 noundef zeroext %15, i16 noundef zeroext %16, i16 noundef zeroext %17, i8 noundef zeroext 1) #15
  %25 = icmp eq i8 %24, 0
  br i1 %25, label %26, label %27

26:                                               ; preds = %11
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.17, i32 noundef %18, i32 noundef %19) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.17, i32 noundef %18, i32 noundef %19) #15
  br label %31

27:                                               ; preds = %11
  %28 = tail call ptr @rm_get_device_name(i16 noundef zeroext %15, i16 noundef zeroext %16, i16 noundef zeroext %17) #15
  %29 = icmp eq ptr %28, null
  %30 = select i1 %29, ptr @.str.19, ptr %28
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.18, i32 noundef %18, i32 noundef %19, ptr noundef nonnull %30) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.18, i32 noundef %18, i32 noundef %19, ptr noundef nonnull %30) #15
  br label %31

31:                                               ; preds = %5, %27, %26, %3
  %32 = phi ptr [ null, %3 ], [ null, %5 ], [ %7, %27 ], [ null, %26 ]
  ret ptr %32
}

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal fastcc zeroext i1 @_ZL15nvrm_driver_offv() unnamed_addr #2 {
  %1 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %1) #18
  store i64 0, ptr %1, align 8, !annotation !77
  %2 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.311, ptr noundef nonnull %1, i32 noundef 8) #15
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %4, label %49

4:                                                ; preds = %0
  %5 = load ptr, ptr @gIODTPlane, align 8, !tbaa !10
  %6 = call ptr @_ZN15IORegistryEntry8fromPathEPKcPK15IORegistryPlanePcPiPS_(ptr noundef nonnull @.str.312, ptr noundef %5, ptr noundef null, ptr noundef null, ptr noundef null) #15
  %7 = icmp eq ptr %6, null
  br i1 %7, label %49, label %8

8:                                                ; preds = %4
  %9 = load ptr, ptr %6, align 8, !tbaa !4
  %10 = getelementptr inbounds i8, ptr %9, i64 744
  %11 = load ptr, ptr %10, align 8
  %12 = call ptr %11(ptr noundef nonnull %6, ptr noundef nonnull @.str.313) #15
  %13 = load ptr, ptr %6, align 8, !tbaa !4
  %14 = getelementptr inbounds i8, ptr %13, i64 744
  %15 = load ptr, ptr %14, align 8
  %16 = call ptr %15(ptr noundef nonnull %6, ptr noundef nonnull @.str.314) #15
  %17 = load ptr, ptr @_ZN6OSData9metaClassE, align 8, !tbaa !10
  %18 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %16, ptr noundef %17) #15
  %19 = icmp eq ptr %18, null
  br i1 %19, label %33, label %20

20:                                               ; preds = %8
  %21 = load ptr, ptr %18, align 8, !tbaa !4
  %22 = getelementptr inbounds i8, ptr %21, i64 320
  %23 = load ptr, ptr %22, align 8
  %24 = call i32 %23(ptr noundef nonnull %18) #15
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %33, label %26

26:                                               ; preds = %20
  %27 = load ptr, ptr %18, align 8, !tbaa !4
  %28 = getelementptr inbounds i8, ptr %27, i64 376
  %29 = load ptr, ptr %28, align 8
  %30 = call ptr %29(ptr noundef nonnull %18) #15
  %31 = load i8, ptr %30, align 1, !tbaa !20
  %32 = icmp ugt i8 %31, 1
  br label %33

33:                                               ; preds = %26, %20, %8
  %34 = phi i1 [ %32, %26 ], [ false, %20 ], [ false, %8 ]
  %35 = icmp eq ptr %16, null
  br i1 %35, label %40, label %36

36:                                               ; preds = %33
  %37 = load ptr, ptr %16, align 8, !tbaa !4
  %38 = getelementptr inbounds i8, ptr %37, i64 40
  %39 = load ptr, ptr %38, align 8
  call void %39(ptr noundef nonnull %16) #15
  br label %40

40:                                               ; preds = %33, %36
  %41 = load ptr, ptr %6, align 8, !tbaa !4
  %42 = getelementptr inbounds i8, ptr %41, i64 40
  %43 = load ptr, ptr %42, align 8
  call void %43(ptr noundef nonnull %6) #15
  %44 = icmp eq ptr %12, null
  br i1 %44, label %49, label %45

45:                                               ; preds = %40
  %46 = load ptr, ptr %12, align 8, !tbaa !4
  %47 = getelementptr inbounds i8, ptr %46, i64 40
  %48 = load ptr, ptr %47, align 8
  call void %48(ptr noundef nonnull %12) #15
  br label %49

49:                                               ; preds = %40, %4, %45, %0
  %50 = phi i1 [ true, %0 ], [ false, %4 ], [ true, %45 ], [ %34, %40 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %1) #18
  ret i1 %50
}

; Function Attrs: noimplicitfloat noredzone
declare void @kprintf(ptr noundef, ...) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @IOLog(ptr noundef, ...) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @rm_is_supported_pci_device(i8 noundef zeroext, i8 noundef zeroext, i16 noundef zeroext, i16 noundef zeroext, i16 noundef zeroext, i16 noundef zeroext, i8 noundef zeroext) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @rm_get_device_name(i16 noundef zeroext, i16 noundef zeroext, i16 noundef zeroext) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i1 @_ZN4NVRM5startEP9IOService(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  %3 = alloca i8, align 1
  %4 = alloca [8 x i8], align 8
  %5 = alloca [8 x i8], align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i64, align 8
  %9 = alloca i64, align 8
  %10 = tail call fastcc zeroext i1 @_ZL15nvrm_driver_offv() #17
  br i1 %10, label %320, label %11

11:                                               ; preds = %2
  %12 = load i1, ptr @_ZZL22nvrm_guard_count_startvE7counted, align 1
  br i1 %12, label %62, label %13

13:                                               ; preds = %11
  store i1 true, ptr @_ZZL22nvrm_guard_count_startvE7counted, align 1
  %14 = load ptr, ptr @gIODTPlane, align 8, !tbaa !10
  %15 = tail call ptr @_ZN15IORegistryEntry8fromPathEPKcPK15IORegistryPlanePcPiPS_(ptr noundef nonnull @.str.312, ptr noundef %14, ptr noundef null, ptr noundef null, ptr noundef null) #15
  %16 = icmp eq ptr %15, null
  br i1 %16, label %62, label %17

17:                                               ; preds = %13
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %3) #18
  %18 = load ptr, ptr %15, align 8, !tbaa !4
  %19 = getelementptr inbounds i8, ptr %18, i64 744
  %20 = load ptr, ptr %19, align 8
  %21 = tail call ptr %20(ptr noundef nonnull %15, ptr noundef nonnull @.str.314) #15
  %22 = load ptr, ptr @_ZN6OSData9metaClassE, align 8, !tbaa !10
  %23 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %21, ptr noundef %22) #15
  %24 = icmp eq ptr %23, null
  br i1 %24, label %38, label %25

25:                                               ; preds = %17
  %26 = load ptr, ptr %23, align 8, !tbaa !4
  %27 = getelementptr inbounds i8, ptr %26, i64 320
  %28 = load ptr, ptr %27, align 8
  %29 = tail call i32 %28(ptr noundef nonnull %23) #15
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %38, label %31

31:                                               ; preds = %25
  %32 = load ptr, ptr %23, align 8, !tbaa !4
  %33 = getelementptr inbounds i8, ptr %32, i64 376
  %34 = load ptr, ptr %33, align 8
  %35 = tail call ptr %34(ptr noundef nonnull %23) #15
  %36 = load i8, ptr %35, align 1, !tbaa !20
  %37 = add i8 %36, 1
  br label %38

38:                                               ; preds = %31, %25, %17
  %39 = phi i8 [ %37, %31 ], [ 1, %25 ], [ 1, %17 ]
  %40 = icmp eq ptr %21, null
  br i1 %40, label %45, label %41

41:                                               ; preds = %38
  %42 = load ptr, ptr %21, align 8, !tbaa !4
  %43 = getelementptr inbounds i8, ptr %42, i64 40
  %44 = load ptr, ptr %43, align 8
  tail call void %44(ptr noundef nonnull %21) #15
  br label %45

45:                                               ; preds = %41, %38
  store i8 %39, ptr %3, align 1, !tbaa !20
  %46 = call ptr @_ZN6OSData9withBytesEPKvj(ptr noundef nonnull %3, i32 noundef 1) #15
  %47 = icmp eq ptr %46, null
  br i1 %47, label %56, label %48

48:                                               ; preds = %45
  %49 = load ptr, ptr %15, align 8, !tbaa !4
  %50 = getelementptr inbounds i8, ptr %49, i64 616
  %51 = load ptr, ptr %50, align 8
  %52 = call zeroext i1 %51(ptr noundef nonnull %15, ptr noundef nonnull @.str.314, ptr noundef nonnull %46) #15
  %53 = load ptr, ptr %46, align 8, !tbaa !4
  %54 = getelementptr inbounds i8, ptr %53, i64 40
  %55 = load ptr, ptr %54, align 8
  call void %55(ptr noundef nonnull %46) #15
  br label %56

56:                                               ; preds = %48, %45
  %57 = load ptr, ptr %15, align 8, !tbaa !4
  %58 = getelementptr inbounds i8, ptr %57, i64 40
  %59 = load ptr, ptr %58, align 8
  call void %59(ptr noundef nonnull %15) #15
  %60 = load i8, ptr %3, align 1, !tbaa !20
  %61 = zext i8 %60 to i32
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.315, i32 noundef %61, i32 noundef 2) #15
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %3) #18
  br label %62

62:                                               ; preds = %11, %13, %56
  %63 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV9IOService, i64 1488), align 8
  %64 = call zeroext i1 %63(ptr noundef %0, ptr noundef %1) #15
  br i1 %64, label %65, label %320

65:                                               ; preds = %62
  %66 = load ptr, ptr @_ZN11IOPCIDevice9metaClassE, align 8, !tbaa !10
  %67 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %1, ptr noundef %66) #15
  %68 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr %67, ptr %68, align 8, !tbaa !78
  %69 = icmp eq ptr %67, null
  br i1 %69, label %320, label %70

70:                                               ; preds = %65
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #18
  store i64 0, ptr %4, align 8
  %71 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.20, ptr noundef nonnull %4, i32 noundef 8) #15
  %72 = icmp ne i32 %71, 0
  %73 = load ptr, ptr @_ZL9gNvPmGate, align 8
  %74 = icmp ne ptr %73, null
  %75 = select i1 %72, i1 true, i1 %74
  br i1 %75, label %78, label %76

76:                                               ; preds = %70
  %77 = call ptr @IOLockAlloc() #15
  store ptr %77, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  br label %78

78:                                               ; preds = %76, %70
  %79 = phi ptr [ %77, %76 ], [ %73, %70 ]
  %80 = icmp ne ptr %79, null
  %81 = select i1 %72, i1 true, i1 %80
  br i1 %81, label %83, label %82

82:                                               ; preds = %78
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.21) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.21) #15
  br label %318

83:                                               ; preds = %78
  store ptr %0, ptr @_ZL12gNVRMService, align 8, !tbaa !10
  call void @nv_xnu_log_init() #15
  %84 = load i1, ptr @_ZZN4NVRM5startEP9IOServiceE9sysctlsUp, align 1
  br i1 %84, label %86, label %85

85:                                               ; preds = %83
  store i1 true, ptr @_ZZN4NVRM5startEP9IOServiceE9sysctlsUp, align 1
  call void @sysctl_register_oid(ptr noundef nonnull @sysctl__debug_nvrm_isr_count) #15
  call void @sysctl_register_oid(ptr noundef nonnull @sysctl__debug_nvrm_isr_handled) #15
  call void @sysctl_register_oid(ptr noundef nonnull @sysctl__debug_nvrm_evt_posts) #15
  call void @sysctl_register_oid(ptr noundef nonnull @sysctl__debug_nvrm_evt_waits) #15
  call void @sysctl_register_oid(ptr noundef nonnull @sysctl__debug_nvrm_pm_waited) #15
  call void @sysctl_register_oid(ptr noundef nonnull @sysctl__debug_nvrm_kms_close_deferred) #15
  br label %86

86:                                               ; preds = %85, %83
  %87 = load ptr, ptr %68, align 8, !tbaa !78
  %88 = load ptr, ptr %87, align 8, !tbaa !4
  %89 = getelementptr inbounds i8, ptr %88, i64 2280
  %90 = load ptr, ptr %89, align 8
  %91 = call zeroext i8 %90(ptr noundef nonnull %87) #15
  %92 = load ptr, ptr %68, align 8, !tbaa !78
  %93 = load ptr, ptr %92, align 8, !tbaa !4
  %94 = getelementptr inbounds i8, ptr %93, i64 2288
  %95 = load ptr, ptr %94, align 8
  %96 = call zeroext i8 %95(ptr noundef nonnull %92) #15
  %97 = load ptr, ptr %68, align 8, !tbaa !78
  %98 = load ptr, ptr %97, align 8, !tbaa !4
  %99 = getelementptr inbounds i8, ptr %98, i64 2296
  %100 = load ptr, ptr %99, align 8
  %101 = call zeroext i8 %100(ptr noundef nonnull %97) #15
  %102 = load ptr, ptr %68, align 8, !tbaa !78
  call void @nv_xnu_register_pci(ptr noundef %102, i32 noundef 0, i8 noundef zeroext %91, i8 noundef zeroext %96, i8 noundef zeroext %101) #15
  call void @nv_xnu_register_all_pci() #15
  %103 = getelementptr inbounds i8, ptr %0, i64 356
  store i32 0, ptr %103, align 4, !tbaa !79
  %104 = getelementptr inbounds i8, ptr %0, i64 360
  store i8 %91, ptr %104, align 4, !tbaa !80
  %105 = getelementptr inbounds i8, ptr %0, i64 361
  store i8 %96, ptr %105, align 1, !tbaa !81
  %106 = getelementptr inbounds i8, ptr %0, i64 362
  store i8 %101, ptr %106, align 2, !tbaa !82
  %107 = load ptr, ptr %68, align 8, !tbaa !78
  %108 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %107, i64 noundef 0) #15
  %109 = getelementptr inbounds i8, ptr %0, i64 364
  store i16 %108, ptr %109, align 4, !tbaa !83
  %110 = load ptr, ptr %68, align 8, !tbaa !78
  %111 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %110, i64 noundef 2) #15
  %112 = getelementptr inbounds i8, ptr %0, i64 366
  store i16 %111, ptr %112, align 2, !tbaa !84
  %113 = load ptr, ptr %68, align 8, !tbaa !78
  %114 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %113, i64 noundef 44) #15
  %115 = getelementptr inbounds i8, ptr %0, i64 370
  store i16 %114, ptr %115, align 2, !tbaa !85
  %116 = load ptr, ptr %68, align 8, !tbaa !78
  %117 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %116, i64 noundef 46) #15
  %118 = getelementptr inbounds i8, ptr %0, i64 368
  store i16 %117, ptr %118, align 8, !tbaa !86
  %119 = call ptr @os_pci_init_handle(i32 noundef 0, i8 noundef zeroext %91, i8 noundef zeroext %96, i8 noundef zeroext %101, ptr noundef null, ptr noundef null) #15
  %120 = getelementptr inbounds i8, ptr %0, i64 408
  store ptr %119, ptr %120, align 8, !tbaa !87
  %121 = getelementptr inbounds i8, ptr %0, i64 480
  %122 = getelementptr inbounds i8, ptr %0, i64 600
  store ptr %121, ptr %122, align 8, !tbaa !88
  %123 = getelementptr inbounds i8, ptr %0, i64 520
  %124 = getelementptr inbounds i8, ptr %0, i64 656
  store ptr %123, ptr %124, align 8, !tbaa !89
  call void @_ZN4NVRM18snapshotBootScreenEv(ptr noundef nonnull %0) #17
  %125 = call zeroext i1 @_ZN4NVRM14placeLargeBar1Ev(ptr noundef nonnull %0) #17
  %126 = zext i1 %125 to i8
  %127 = getelementptr inbounds i8, ptr %0, i64 176
  store i8 %126, ptr %127, align 8, !tbaa !62
  call void @_ZN4NVRM8readBARsEv(ptr noundef nonnull %0) #17
  %128 = load i16, ptr %112, align 2, !tbaa !84
  %129 = load i16, ptr %115, align 2, !tbaa !85
  %130 = load i16, ptr %118, align 8, !tbaa !86
  %131 = call ptr @rm_get_device_name(i16 noundef zeroext %128, i16 noundef zeroext %129, i16 noundef zeroext %130) #15
  %132 = icmp eq ptr %131, null
  br i1 %132, label %177, label %133

133:                                              ; preds = %86
  %134 = load i8, ptr %131, align 1, !tbaa !20
  switch i8 %134, label %163 [
    i8 0, label %177
    i8 85, label %135
  ]

135:                                              ; preds = %133
  %136 = getelementptr inbounds i8, ptr %131, i64 1
  %137 = load i8, ptr %136, align 1, !tbaa !20
  %138 = icmp eq i8 %137, 110
  br i1 %138, label %139, label %163

139:                                              ; preds = %135
  %140 = getelementptr inbounds i8, ptr %131, i64 2
  %141 = load i8, ptr %140, align 1, !tbaa !20
  %142 = icmp eq i8 %141, 107
  br i1 %142, label %143, label %163

143:                                              ; preds = %139
  %144 = getelementptr inbounds i8, ptr %131, i64 3
  %145 = load i8, ptr %144, align 1, !tbaa !20
  %146 = icmp eq i8 %145, 110
  br i1 %146, label %147, label %163

147:                                              ; preds = %143
  %148 = getelementptr inbounds i8, ptr %131, i64 4
  %149 = load i8, ptr %148, align 1, !tbaa !20
  %150 = icmp eq i8 %149, 111
  br i1 %150, label %151, label %163

151:                                              ; preds = %147
  %152 = getelementptr inbounds i8, ptr %131, i64 5
  %153 = load i8, ptr %152, align 1, !tbaa !20
  %154 = icmp eq i8 %153, 119
  br i1 %154, label %155, label %163

155:                                              ; preds = %151
  %156 = getelementptr inbounds i8, ptr %131, i64 6
  %157 = load i8, ptr %156, align 1, !tbaa !20
  %158 = icmp eq i8 %157, 110
  br i1 %158, label %159, label %163

159:                                              ; preds = %155
  %160 = getelementptr inbounds i8, ptr %131, i64 7
  %161 = load i8, ptr %160, align 1, !tbaa !20
  %162 = icmp eq i8 %161, 0
  br i1 %162, label %177, label %163

163:                                              ; preds = %155, %151, %147, %143, %139, %135, %133, %159
  br label %164

164:                                              ; preds = %163, %164
  %165 = phi i32 [ %170, %164 ], [ 0, %163 ]
  %166 = zext i32 %165 to i64
  %167 = getelementptr inbounds i8, ptr %131, i64 %166
  %168 = load i8, ptr %167, align 1, !tbaa !20
  %169 = icmp eq i8 %168, 0
  %170 = add i32 %165, 1
  br i1 %169, label %171, label %164, !llvm.loop !90

171:                                              ; preds = %164
  %172 = load ptr, ptr %68, align 8, !tbaa !78
  %173 = load ptr, ptr %172, align 8, !tbaa !4
  %174 = getelementptr inbounds i8, ptr %173, i64 648
  %175 = load ptr, ptr %174, align 8
  %176 = call zeroext i1 %175(ptr noundef nonnull %172, ptr noundef nonnull @.str.22, ptr noundef nonnull %131, i32 noundef %170) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.23, ptr noundef nonnull %131) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.23, ptr noundef nonnull %131) #15
  br label %190

177:                                              ; preds = %133, %159, %86
  %178 = load i16, ptr %112, align 2, !tbaa !84
  %179 = zext i16 %178 to i32
  %180 = load i16, ptr %115, align 2, !tbaa !85
  %181 = zext i16 %180 to i32
  %182 = load i16, ptr %118, align 8, !tbaa !86
  %183 = zext i16 %182 to i32
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.24, i32 noundef %179, i32 noundef %181, i32 noundef %183) #15
  %184 = load i16, ptr %112, align 2, !tbaa !84
  %185 = zext i16 %184 to i32
  %186 = load i16, ptr %115, align 2, !tbaa !85
  %187 = zext i16 %186 to i32
  %188 = load i16, ptr %118, align 8, !tbaa !86
  %189 = zext i16 %188 to i32
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.24, i32 noundef %185, i32 noundef %187, i32 noundef %189) #15
  br label %190

190:                                              ; preds = %177, %171
  %191 = zext i8 %91 to i32
  %192 = zext i8 %96 to i32
  %193 = zext i8 %101 to i32
  %194 = load i16, ptr %109, align 4, !tbaa !83
  %195 = zext i16 %194 to i32
  %196 = load i16, ptr %112, align 2, !tbaa !84
  %197 = zext i16 %196 to i32
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.25, i32 noundef %191, i32 noundef %192, i32 noundef %193, i32 noundef %195, i32 noundef %197) #15
  %198 = load i16, ptr %109, align 4, !tbaa !83
  %199 = zext i16 %198 to i32
  %200 = load i16, ptr %112, align 2, !tbaa !84
  %201 = zext i16 %200 to i32
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.25, i32 noundef %191, i32 noundef %192, i32 noundef %193, i32 noundef %199, i32 noundef %201) #15
  %202 = load ptr, ptr %68, align 8, !tbaa !78
  %203 = load ptr, ptr @kOSBooleanTrue, align 8, !tbaa !10
  %204 = load ptr, ptr %203, align 8, !tbaa !10
  %205 = load ptr, ptr %202, align 8, !tbaa !4
  %206 = getelementptr inbounds i8, ptr %205, i64 616
  %207 = load ptr, ptr %206, align 8
  %208 = call zeroext i1 %207(ptr noundef nonnull %202, ptr noundef nonnull @.str.26, ptr noundef %204) #15
  %209 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  %210 = icmp eq ptr %209, null
  br i1 %210, label %211, label %215

211:                                              ; preds = %190
  %212 = call ptr @IOLockAlloc() #15
  store ptr %212, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  %213 = icmp eq ptr %212, null
  br i1 %213, label %214, label %215

214:                                              ; preds = %211
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.27) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.27) #15
  br label %318

215:                                              ; preds = %190, %211
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 0, ptr %5, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #18
  store ptr null, ptr %6, align 8, !tbaa !10
  %216 = select i1 %125, i32 500, i32 100000
  %217 = getelementptr inbounds i8, ptr %0, i64 172
  store i32 %216, ptr %217, align 4, !tbaa !61
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #18
  store i32 0, ptr %7, align 4, !tbaa !18
  %218 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.28, ptr noundef nonnull %7, i32 noundef 4) #15
  %219 = icmp eq i32 %218, 0
  br i1 %219, label %222, label %220

220:                                              ; preds = %215
  %221 = load i32, ptr %7, align 4, !tbaa !18
  store i32 %221, ptr %217, align 4, !tbaa !61
  br label %222

222:                                              ; preds = %220, %215
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #18
  %223 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.29, ptr noundef nonnull %5, i32 noundef 8) #15
  %224 = icmp eq i32 %223, 0
  br i1 %224, label %230, label %225

225:                                              ; preds = %222
  %226 = load ptr, ptr %0, align 8, !tbaa !4
  %227 = getelementptr inbounds i8, ptr %226, i64 624
  %228 = load ptr, ptr %227, align 8
  %229 = call zeroext i1 %228(ptr noundef nonnull %0, ptr noundef nonnull @.str.30, ptr noundef nonnull @.str.31) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.32) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.32) #15
  br label %281

230:                                              ; preds = %222
  %231 = getelementptr inbounds i8, ptr %0, i64 180
  store volatile i32 1, ptr %231, align 4, !tbaa !63
  %232 = load ptr, ptr %0, align 8, !tbaa !4
  %233 = getelementptr inbounds i8, ptr %232, i64 1584
  %234 = load ptr, ptr %233, align 8
  call void %234(ptr noundef nonnull %0, i32 noundef 1) #15
  %235 = load ptr, ptr %0, align 8, !tbaa !4
  %236 = getelementptr inbounds i8, ptr %235, i64 624
  %237 = load ptr, ptr %236, align 8
  %238 = call zeroext i1 %237(ptr noundef nonnull %0, ptr noundef nonnull @.str.33, ptr noundef nonnull @.str.34) #15
  %239 = call ptr @thread_call_allocate(ptr noundef nonnull @_ZN4NVRM11bootHoldCapEPvS0_, ptr noundef nonnull %0) #15
  %240 = icmp eq ptr %239, null
  br i1 %240, label %251, label %241

241:                                              ; preds = %230
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #18
  store i64 0, ptr %8, align 8, !annotation !77
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9) #18
  store i64 0, ptr %9, align 8, !annotation !77
  call void @clock_interval_to_deadline(i32 noundef 40000, i32 noundef 1000000, ptr noundef nonnull %8) #15
  %242 = load i32, ptr %217, align 4, !tbaa !61
  call void @clock_interval_to_absolutetime_interval(i32 noundef %242, i32 noundef 1000000, ptr noundef nonnull %9) #15
  %243 = load i64, ptr %9, align 8, !tbaa !7
  %244 = load i64, ptr %8, align 8, !tbaa !7
  %245 = add i64 %244, %243
  store i64 %245, ptr %8, align 8, !tbaa !7
  %246 = load ptr, ptr %0, align 8, !tbaa !4
  %247 = getelementptr inbounds i8, ptr %246, i64 32
  %248 = load ptr, ptr %247, align 8
  call void %248(ptr noundef nonnull %0) #15
  %249 = load i64, ptr %8, align 8, !tbaa !7
  %250 = call i32 @thread_call_enter_delayed(ptr noundef nonnull %239, i64 noundef %249) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9) #18
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #18
  br label %252

251:                                              ; preds = %230
  call void @_ZN4NVRM15releaseBootHoldEPKc(ptr noundef nonnull %0, ptr noundef nonnull @.str.35) #17
  br label %252

252:                                              ; preds = %251, %241
  %253 = load ptr, ptr %0, align 8, !tbaa !4
  %254 = getelementptr inbounds i8, ptr %253, i64 32
  %255 = load ptr, ptr %254, align 8
  call void %255(ptr noundef nonnull %0) #15
  %256 = call i32 @kernel_thread_start(ptr noundef nonnull @_ZN4NVRM6autoGoEPvi, ptr noundef nonnull %0, ptr noundef nonnull %6) #15
  %257 = icmp eq i32 %256, 0
  br i1 %257, label %258, label %273

258:                                              ; preds = %252
  %259 = load ptr, ptr %6, align 8, !tbaa !10
  call void @thread_deallocate(ptr noundef %259) #15
  %260 = load i32, ptr %217, align 4, !tbaa !61
  %261 = zext i32 %260 to i64
  %262 = load ptr, ptr %0, align 8, !tbaa !4
  %263 = getelementptr inbounds i8, ptr %262, i64 640
  %264 = load ptr, ptr %263, align 8
  %265 = call zeroext i1 %264(ptr noundef nonnull %0, ptr noundef nonnull @.str.36, i64 noundef %261, i32 noundef 32) #15
  %266 = load ptr, ptr %0, align 8, !tbaa !4
  %267 = getelementptr inbounds i8, ptr %266, i64 624
  %268 = load ptr, ptr %267, align 8
  %269 = call zeroext i1 %268(ptr noundef nonnull %0, ptr noundef nonnull @.str.30, ptr noundef nonnull @.str.37) #15
  %270 = load i32, ptr %217, align 4, !tbaa !61
  %271 = select i1 %125, ptr @.str.39, ptr @.str.40
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.38, i32 noundef %270, ptr noundef nonnull %271) #15
  %272 = load i32, ptr %217, align 4, !tbaa !61
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.38, i32 noundef %272, ptr noundef nonnull %271) #15
  br label %281

273:                                              ; preds = %252
  %274 = load ptr, ptr %0, align 8, !tbaa !4
  %275 = getelementptr inbounds i8, ptr %274, i64 40
  %276 = load ptr, ptr %275, align 8
  call void %276(ptr noundef nonnull %0) #15
  %277 = load ptr, ptr %0, align 8, !tbaa !4
  %278 = getelementptr inbounds i8, ptr %277, i64 624
  %279 = load ptr, ptr %278, align 8
  %280 = call zeroext i1 %279(ptr noundef nonnull %0, ptr noundef nonnull @.str.30, ptr noundef nonnull @.str.41) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.42) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.42) #15
  call void @_ZN4NVRM15releaseBootHoldEPKc(ptr noundef nonnull %0, ptr noundef nonnull @.str.43) #17
  br label %281

281:                                              ; preds = %258, %273, %225
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #18
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  %282 = load ptr, ptr %0, align 8, !tbaa !4
  br i1 %72, label %283, label %287

283:                                              ; preds = %281
  %284 = getelementptr inbounds i8, ptr %282, i64 624
  %285 = load ptr, ptr %284, align 8
  %286 = call zeroext i1 %285(ptr noundef nonnull %0, ptr noundef nonnull @.str.44, ptr noundef nonnull @.str.45) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.46) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.46) #15
  br label %314

287:                                              ; preds = %281
  %288 = getelementptr inbounds i8, ptr %282, i64 1936
  %289 = load ptr, ptr %288, align 8
  call void %289(ptr noundef nonnull %0) #15
  %290 = load ptr, ptr %68, align 8, !tbaa !78
  %291 = load ptr, ptr %290, align 8, !tbaa !4
  %292 = getelementptr inbounds i8, ptr %291, i64 1952
  %293 = load ptr, ptr %292, align 8
  call void %293(ptr noundef nonnull %290, ptr noundef nonnull %0) #15
  %294 = load ptr, ptr %0, align 8, !tbaa !4
  %295 = getelementptr inbounds i8, ptr %294, i64 1960
  %296 = load ptr, ptr %295, align 8
  %297 = call i32 %296(ptr noundef nonnull %0, ptr noundef nonnull %0, ptr noundef nonnull @_ZZN4NVRM5startEP9IOServiceE16kNvrmPowerStates, i64 noundef 2) #15
  %298 = call i32 @_ZN9IOService18changePowerStateToEm(ptr noundef nonnull %0, i64 noundef 1) #15
  %299 = getelementptr inbounds i8, ptr %0, i64 188
  store i8 1, ptr %299, align 4, !tbaa !65
  %300 = load ptr, ptr %0, align 8, !tbaa !4
  %301 = getelementptr inbounds i8, ptr %300, i64 624
  %302 = load ptr, ptr %301, align 8
  %303 = call zeroext i1 %302(ptr noundef nonnull %0, ptr noundef nonnull @.str.44, ptr noundef nonnull @.str.47) #15
  %304 = load ptr, ptr %68, align 8, !tbaa !78
  %305 = load ptr, ptr %304, align 8, !tbaa !4
  %306 = getelementptr inbounds i8, ptr %305, i64 904
  %307 = load ptr, ptr %306, align 8
  %308 = call ptr %307(ptr noundef nonnull %304, ptr noundef null) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.48, ptr noundef %308) #15
  %309 = load ptr, ptr %68, align 8, !tbaa !78
  %310 = load ptr, ptr %309, align 8, !tbaa !4
  %311 = getelementptr inbounds i8, ptr %310, i64 904
  %312 = load ptr, ptr %311, align 8
  %313 = call ptr %312(ptr noundef nonnull %309, ptr noundef null) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.48, ptr noundef %313) #15
  br label %314

314:                                              ; preds = %287, %283
  %315 = load ptr, ptr %0, align 8, !tbaa !4
  %316 = getelementptr inbounds i8, ptr %315, i64 1456
  %317 = load ptr, ptr %316, align 8
  call void %317(ptr noundef nonnull %0, i32 noundef 0) #15
  br label %318

318:                                              ; preds = %214, %314, %82
  %319 = phi i1 [ false, %82 ], [ true, %314 ], [ false, %214 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  br label %320

320:                                              ; preds = %65, %62, %2, %318
  %321 = phi i1 [ %319, %318 ], [ false, %2 ], [ false, %62 ], [ false, %65 ]
  ret i1 %321
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @PE_parse_boot_argn(ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @IOLockAlloc() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @nv_xnu_log_init() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @sysctl_register_oid(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @nv_xnu_register_pci(ptr noundef, i32 noundef, i8 noundef zeroext, i8 noundef zeroext, i8 noundef zeroext) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @nv_xnu_register_all_pci() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @os_pci_init_handle(i32 noundef, i8 noundef zeroext, i8 noundef zeroext, i8 noundef zeroext, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM18snapshotBootScreenEv(ptr nocapture noundef %0) local_unnamed_addr #1 align 2 {
  %2 = alloca [8 x i8], align 8
  %3 = alloca %struct.PE_Video, align 8
  %4 = alloca i64, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #18
  store i64 0, ptr %2, align 8
  %5 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.49, ptr noundef nonnull %2, i32 noundef 8) #15
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %8, label %7

7:                                                ; preds = %1
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.50) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.50) #15
  br label %164

8:                                                ; preds = %1
  call void @llvm.lifetime.start.p0(i64 144, ptr nonnull %3) #18
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(144) %3, i8 0, i64 144, i1 false)
  %9 = call ptr @_ZN9IOService11getPlatformEv() #15
  %10 = icmp eq ptr %9, null
  br i1 %10, label %38, label %11

11:                                               ; preds = %8
  %12 = call ptr @_ZN9IOService11getPlatformEv() #15
  %13 = load ptr, ptr %12, align 8, !tbaa !4
  %14 = getelementptr inbounds i8, ptr %13, i64 2280
  %15 = load ptr, ptr %14, align 8
  %16 = call i32 %15(ptr noundef nonnull %12, ptr noundef nonnull %3) #15
  %17 = icmp eq i32 %16, 0
  %18 = load i64, ptr %3, align 8
  %19 = icmp ne i64 %18, 0
  %20 = select i1 %17, i1 %19, i1 false
  %21 = getelementptr inbounds i8, ptr %3, i64 32
  %22 = load i64, ptr %21, align 8
  %23 = icmp eq i64 %22, 32
  %24 = select i1 %20, i1 %23, i1 false
  %25 = getelementptr inbounds i8, ptr %3, i64 16
  %26 = load i64, ptr %25, align 8
  %27 = icmp ne i64 %26, 0
  %28 = select i1 %24, i1 %27, i1 false
  %29 = getelementptr inbounds i8, ptr %3, i64 24
  %30 = load i64, ptr %29, align 8
  %31 = icmp ne i64 %30, 0
  %32 = select i1 %28, i1 %31, i1 false
  br i1 %32, label %33, label %38

33:                                               ; preds = %11
  %34 = getelementptr inbounds i8, ptr %3, i64 8
  %35 = load i64, ptr %34, align 8, !tbaa !91
  %36 = shl i64 %26, 2
  %37 = icmp ult i64 %35, %36
  br i1 %37, label %38, label %48

38:                                               ; preds = %8, %11, %33
  %39 = phi i64 [ 0, %8 ], [ %30, %11 ], [ %30, %33 ]
  %40 = phi i64 [ 0, %8 ], [ %26, %11 ], [ %26, %33 ]
  %41 = phi i64 [ 0, %8 ], [ %22, %11 ], [ 32, %33 ]
  %42 = getelementptr inbounds i8, ptr %3, i64 32
  %43 = getelementptr inbounds i8, ptr %3, i64 16
  %44 = getelementptr inbounds i8, ptr %3, i64 24
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.51, i64 noundef %41, i64 noundef %40, i64 noundef %39) #15
  %45 = load i64, ptr %42, align 8, !tbaa !94
  %46 = load i64, ptr %43, align 8, !tbaa !95
  %47 = load i64, ptr %44, align 8, !tbaa !96
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.51, i64 noundef %45, i64 noundef %46, i64 noundef %47) #15
  br label %163

48:                                               ; preds = %33
  %49 = and i64 %18, -4
  %50 = mul i64 %35, %30
  %51 = icmp ugt i64 %50, 67108864
  br i1 %51, label %52, label %53

52:                                               ; preds = %48
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.52, i64 noundef %50) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.52, i64 noundef %50) #15
  br label %163

53:                                               ; preds = %48
  %54 = call ptr @_ZN18IOMemoryDescriptor16withAddressRangeEyyjP4task(i64 noundef %49, i64 noundef %50, i32 noundef 2049, ptr noundef null) #15
  %55 = icmp eq ptr %54, null
  br i1 %55, label %61, label %56

56:                                               ; preds = %53
  %57 = load ptr, ptr %54, align 8, !tbaa !4
  %58 = getelementptr inbounds i8, ptr %57, i64 512
  %59 = load ptr, ptr %58, align 8
  %60 = call ptr %59(ptr noundef nonnull %54, i32 noundef 256) #15
  br label %61

61:                                               ; preds = %53, %56
  %62 = phi ptr [ %60, %56 ], [ null, %53 ]
  %63 = load ptr, ptr @kernel_task, align 8, !tbaa !10
  %64 = load i64, ptr @page_size, align 8, !tbaa !97
  %65 = call ptr @_ZN24IOBufferMemoryDescriptor17inTaskWithOptionsEP4taskjmm(ptr noundef %63, i32 noundef 3, i64 noundef %50, i64 noundef %64) #15
  %66 = icmp ne ptr %62, null
  %67 = icmp ne ptr %65, null
  %68 = select i1 %66, i1 %67, i1 false
  br i1 %68, label %84, label %69

69:                                               ; preds = %61
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.53, ptr noundef %62, ptr noundef %65) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.53, ptr noundef %62, ptr noundef %65) #15
  br i1 %66, label %70, label %74

70:                                               ; preds = %69
  %71 = load ptr, ptr %62, align 8, !tbaa !4
  %72 = getelementptr inbounds i8, ptr %71, i64 40
  %73 = load ptr, ptr %72, align 8
  call void %73(ptr noundef nonnull %62) #15
  br label %74

74:                                               ; preds = %70, %69
  br i1 %55, label %79, label %75

75:                                               ; preds = %74
  %76 = load ptr, ptr %54, align 8, !tbaa !4
  %77 = getelementptr inbounds i8, ptr %76, i64 40
  %78 = load ptr, ptr %77, align 8
  call void %78(ptr noundef nonnull %54) #15
  br label %79

79:                                               ; preds = %75, %74
  br i1 %67, label %80, label %163

80:                                               ; preds = %79
  %81 = load ptr, ptr %65, align 8, !tbaa !4
  %82 = getelementptr inbounds i8, ptr %81, i64 40
  %83 = load ptr, ptr %82, align 8
  call void %83(ptr noundef nonnull %65) #15
  br label %163

84:                                               ; preds = %61
  %85 = call i64 @mach_absolute_time() #15
  %86 = load ptr, ptr %62, align 8, !tbaa !4
  %87 = getelementptr inbounds i8, ptr %86, i64 280
  %88 = load ptr, ptr %87, align 8
  %89 = call i64 %88(ptr noundef nonnull %62) #15
  %90 = inttoptr i64 %89 to ptr
  %91 = load ptr, ptr %65, align 8, !tbaa !4
  %92 = getelementptr inbounds i8, ptr %91, i64 736
  %93 = load ptr, ptr %92, align 8
  %94 = call ptr %93(ptr noundef nonnull %65) #15
  %95 = icmp ult i64 %50, 8
  br i1 %95, label %115, label %96

96:                                               ; preds = %84
  %97 = lshr i64 %50, 3
  %98 = add nsw i64 %97, -1
  %99 = and i64 %97, 3
  %100 = icmp ult i64 %98, 3
  br i1 %100, label %103, label %101

101:                                              ; preds = %96
  %102 = and i64 %97, 16777212
  br label %142

103:                                              ; preds = %142, %96
  %104 = phi i64 [ 0, %96 ], [ %160, %142 ]
  %105 = icmp eq i64 %99, 0
  br i1 %105, label %115, label %106

106:                                              ; preds = %103, %106
  %107 = phi i64 [ %112, %106 ], [ %104, %103 ]
  %108 = phi i64 [ %113, %106 ], [ 0, %103 ]
  %109 = getelementptr inbounds i64, ptr %90, i64 %107
  %110 = load volatile i64, ptr %109, align 8, !tbaa !7
  %111 = getelementptr inbounds i64, ptr %94, i64 %107
  store i64 %110, ptr %111, align 8, !tbaa !7
  %112 = add nuw nsw i64 %107, 1
  %113 = add i64 %108, 1
  %114 = icmp eq i64 %113, %99
  br i1 %114, label %115, label %106, !llvm.loop !98

115:                                              ; preds = %103, %106, %84
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #18
  store i64 0, ptr %4, align 8, !tbaa !7
  %116 = call i64 @mach_absolute_time() #15
  %117 = sub i64 %116, %85
  call void @absolutetime_to_nanoseconds(i64 noundef %117, ptr noundef nonnull %4) #15
  %118 = load ptr, ptr %62, align 8, !tbaa !4
  %119 = getelementptr inbounds i8, ptr %118, i64 40
  %120 = load ptr, ptr %119, align 8
  call void %120(ptr noundef nonnull %62) #15
  %121 = load ptr, ptr %54, align 8, !tbaa !4
  %122 = getelementptr inbounds i8, ptr %121, i64 40
  %123 = load ptr, ptr %122, align 8
  call void %123(ptr noundef nonnull %54) #15
  %124 = getelementptr inbounds i8, ptr %0, i64 152
  store ptr %65, ptr %124, align 8, !tbaa !57
  %125 = load i64, ptr %25, align 8, !tbaa !95
  %126 = trunc i64 %125 to i32
  %127 = getelementptr inbounds i8, ptr %0, i64 160
  store i32 %126, ptr %127, align 8, !tbaa !58
  %128 = load i64, ptr %29, align 8, !tbaa !96
  %129 = trunc i64 %128 to i32
  %130 = getelementptr inbounds i8, ptr %0, i64 164
  store i32 %129, ptr %130, align 4, !tbaa !59
  %131 = load i64, ptr %34, align 8, !tbaa !91
  %132 = trunc i64 %131 to i32
  %133 = getelementptr inbounds i8, ptr %0, i64 168
  store i32 %132, ptr %133, align 8, !tbaa !60
  %134 = lshr i64 %50, 10
  %135 = load i64, ptr %4, align 8, !tbaa !7
  %136 = udiv i64 %135, 1000000
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.54, i32 noundef %126, i32 noundef %129, i32 noundef %132, i64 noundef %134, i64 noundef %49, i64 noundef %136) #15
  %137 = load i32, ptr %127, align 8, !tbaa !58
  %138 = load i32, ptr %130, align 4, !tbaa !59
  %139 = load i32, ptr %133, align 8, !tbaa !60
  %140 = load i64, ptr %4, align 8, !tbaa !7
  %141 = udiv i64 %140, 1000000
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.54, i32 noundef %137, i32 noundef %138, i32 noundef %139, i64 noundef %134, i64 noundef %49, i64 noundef %141) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  br label %163

142:                                              ; preds = %142, %101
  %143 = phi i64 [ 0, %101 ], [ %160, %142 ]
  %144 = phi i64 [ 0, %101 ], [ %161, %142 ]
  %145 = getelementptr inbounds i64, ptr %90, i64 %143
  %146 = load volatile i64, ptr %145, align 8, !tbaa !7
  %147 = getelementptr inbounds i64, ptr %94, i64 %143
  store i64 %146, ptr %147, align 8, !tbaa !7
  %148 = or disjoint i64 %143, 1
  %149 = getelementptr inbounds i64, ptr %90, i64 %148
  %150 = load volatile i64, ptr %149, align 8, !tbaa !7
  %151 = getelementptr inbounds i64, ptr %94, i64 %148
  store i64 %150, ptr %151, align 8, !tbaa !7
  %152 = or disjoint i64 %143, 2
  %153 = getelementptr inbounds i64, ptr %90, i64 %152
  %154 = load volatile i64, ptr %153, align 8, !tbaa !7
  %155 = getelementptr inbounds i64, ptr %94, i64 %152
  store i64 %154, ptr %155, align 8, !tbaa !7
  %156 = or disjoint i64 %143, 3
  %157 = getelementptr inbounds i64, ptr %90, i64 %156
  %158 = load volatile i64, ptr %157, align 8, !tbaa !7
  %159 = getelementptr inbounds i64, ptr %94, i64 %156
  store i64 %158, ptr %159, align 8, !tbaa !7
  %160 = add nuw nsw i64 %143, 4
  %161 = add i64 %144, 4
  %162 = icmp eq i64 %161, %102
  br i1 %162, label %103, label %142, !llvm.loop !100

163:                                              ; preds = %52, %79, %80, %115, %38
  call void @llvm.lifetime.end.p0(i64 144, ptr nonnull %3) #18
  br label %164

164:                                              ; preds = %163, %7
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #18
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i1 @_ZN4NVRM14placeLargeBar1Ev(ptr nocapture noundef readonly %0) local_unnamed_addr #1 align 2 {
  %2 = alloca i64, align 8
  %3 = alloca i64, align 8
  %4 = alloca ptr, align 8
  %5 = alloca [8 x i8], align 8
  %6 = alloca %struct.PE_Video, align 8
  %7 = alloca %struct.PE_Video, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 0, ptr %5, align 8
  %8 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.119, ptr noundef nonnull %5, i32 noundef 8) #15
  %9 = icmp eq i32 %8, 0
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  %10 = getelementptr inbounds i8, ptr %0, i64 328
  br label %11

11:                                               ; preds = %1, %22
  %12 = phi i32 [ 256, %1 ], [ %23, %22 ]
  %13 = phi i32 [ 0, %1 ], [ %24, %22 ]
  %14 = load ptr, ptr %10, align 8, !tbaa !78
  %15 = zext nneg i32 %12 to i64
  %16 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %14, i64 noundef %15) #15
  %17 = add i32 %16, 1
  %18 = icmp ult i32 %17, 2
  br i1 %18, label %28, label %19

19:                                               ; preds = %11
  %20 = and i32 %16, 65535
  %21 = icmp eq i32 %20, 21
  br i1 %21, label %29, label %22

22:                                               ; preds = %19
  %23 = lshr i32 %16, 20
  %24 = add nuw nsw i32 %13, 1
  %25 = icmp ugt i32 %16, 268435455
  %26 = icmp ult i32 %13, 63
  %27 = select i1 %25, i1 %26, i1 false
  br i1 %27, label %11, label %28, !llvm.loop !101

28:                                               ; preds = %11, %22
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.120) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.120) #15
  br label %954

29:                                               ; preds = %19
  %30 = load ptr, ptr %10, align 8, !tbaa !78
  %31 = add nuw nsw i32 %12, 8
  %32 = zext nneg i32 %31 to i64
  %33 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %30, i64 noundef %32) #15
  %34 = lshr i32 %33, 5
  %35 = and i32 %34, 7
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %42, label %37

37:                                               ; preds = %29
  %38 = call i32 @llvm.umin.i32(i32 %35, i32 6)
  %39 = add nuw nsw i32 %12, 4
  %40 = zext nneg i32 %39 to i64
  %41 = zext nneg i32 %38 to i64
  br label %48

42:                                               ; preds = %71, %29
  %43 = phi i32 [ 0, %29 ], [ %72, %71 ]
  %44 = phi i32 [ 0, %29 ], [ %73, %71 ]
  %45 = phi i32 [ 0, %29 ], [ %74, %71 ]
  %46 = phi i64 [ 0, %29 ], [ %75, %71 ]
  %47 = lshr i64 %46, 20
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.121, i32 noundef %12, i64 noundef %47, i32 noundef %43) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.121, i32 noundef %12, i64 noundef %47, i32 noundef %43) #15
  br i1 %9, label %85, label %78

48:                                               ; preds = %37, %71
  %49 = phi i64 [ 0, %37 ], [ %76, %71 ]
  %50 = phi i64 [ 0, %37 ], [ %75, %71 ]
  %51 = phi i32 [ 0, %37 ], [ %74, %71 ]
  %52 = phi i32 [ 0, %37 ], [ %73, %71 ]
  %53 = phi i32 [ 0, %37 ], [ %72, %71 ]
  %54 = load ptr, ptr %10, align 8, !tbaa !78
  %55 = shl nuw nsw i64 %49, 3
  %56 = add nuw nsw i64 %55, %32
  %57 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %54, i64 noundef %56) #15
  %58 = and i32 %57, 7
  %59 = icmp eq i32 %58, 1
  br i1 %59, label %60, label %71

60:                                               ; preds = %48
  %61 = lshr i32 %57, 8
  %62 = and i32 %61, 63
  %63 = add nuw nsw i32 %62, 20
  %64 = zext nneg i32 %63 to i64
  %65 = shl nuw i64 1, %64
  %66 = load ptr, ptr %10, align 8, !tbaa !78
  %67 = add nuw nsw i64 %55, %40
  %68 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %66, i64 noundef %67) #15
  %69 = lshr i32 %68, 4
  %70 = trunc nuw nsw i64 %56 to i32
  br label %71

71:                                               ; preds = %60, %48
  %72 = phi i32 [ %69, %60 ], [ %53, %48 ]
  %73 = phi i32 [ %57, %60 ], [ %52, %48 ]
  %74 = phi i32 [ %70, %60 ], [ %51, %48 ]
  %75 = phi i64 [ %65, %60 ], [ %50, %48 ]
  %76 = add nuw nsw i64 %49, 1
  %77 = icmp eq i64 %76, %41
  br i1 %77, label %42, label %48, !llvm.loop !102

78:                                               ; preds = %42
  %79 = icmp eq i32 %45, 0
  %80 = and i32 %43, 256
  %81 = icmp eq i32 %80, 0
  %82 = or i1 %79, %81
  br i1 %82, label %83, label %84

83:                                               ; preds = %78
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.122, i32 noundef %43) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.122, i32 noundef %43) #15
  br label %954

84:                                               ; preds = %78
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.123, i64 noundef %47) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.123, i64 noundef %47) #15
  br label %153

85:                                               ; preds = %42
  %86 = icmp ult i64 %46, 4294967296
  br i1 %86, label %87, label %153

87:                                               ; preds = %85
  %88 = icmp eq i32 %45, 0
  br i1 %88, label %95, label %89

89:                                               ; preds = %87
  %90 = and i32 %43, 8192
  %91 = icmp eq i32 %90, 0
  br i1 %91, label %92, label %96

92:                                               ; preds = %89
  %93 = and i32 %43, 4096
  %94 = icmp eq i32 %93, 0
  br i1 %94, label %95, label %96

95:                                               ; preds = %87, %92
  br label %100

96:                                               ; preds = %89, %92
  %97 = phi i64 [ 33, %89 ], [ 32, %92 ]
  %98 = shl nuw nsw i64 1, %97
  br label %150

99:                                               ; preds = %111
  br i1 %114, label %117, label %150

100:                                              ; preds = %95, %111
  %101 = phi i64 [ %113, %111 ], [ 11, %95 ]
  br i1 %88, label %111, label %102

102:                                              ; preds = %100
  %103 = trunc nuw nsw i64 %101 to i32
  %104 = shl nuw i32 1, %103
  %105 = and i32 %104, %43
  %106 = icmp eq i32 %105, 0
  br i1 %106, label %111, label %107

107:                                              ; preds = %102
  %108 = shl nuw i64 1048576, %101
  %109 = icmp ugt i64 %108, %46
  %110 = select i1 %109, i64 %108, i64 0
  br label %111

111:                                              ; preds = %107, %100, %102
  %112 = phi i64 [ 0, %102 ], [ 0, %100 ], [ %110, %107 ]
  %113 = add nsw i64 %101, -1
  %114 = icmp eq i64 %112, 0
  %115 = icmp ne i64 %101, 0
  %116 = select i1 %114, i1 %115, i1 false
  br i1 %116, label %100, label %99, !llvm.loop !103

117:                                              ; preds = %99
  %118 = load ptr, ptr %10, align 8, !tbaa !78
  %119 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %118, i64 noundef 24) #15
  %120 = zext i32 %119 to i64
  %121 = shl nuw i64 %120, 32
  %122 = load ptr, ptr %10, align 8, !tbaa !78
  %123 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %122, i64 noundef 20) #15
  %124 = and i32 %123, -16
  %125 = zext i32 %124 to i64
  %126 = or disjoint i64 %121, %125
  call void @llvm.lifetime.start.p0(i64 144, ptr nonnull %6) #18
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(144) %6, i8 0, i64 144, i1 false)
  %127 = call ptr @_ZN9IOService11getPlatformEv() #15
  %128 = icmp eq ptr %127, null
  br i1 %128, label %139, label %129

129:                                              ; preds = %117
  %130 = call ptr @_ZN9IOService11getPlatformEv() #15
  %131 = load ptr, ptr %130, align 8, !tbaa !4
  %132 = getelementptr inbounds i8, ptr %131, i64 2280
  %133 = load ptr, ptr %132, align 8
  %134 = call i32 %133(ptr noundef nonnull %130, ptr noundef nonnull %6) #15
  %135 = icmp eq i32 %134, 0
  br i1 %135, label %136, label %139

136:                                              ; preds = %129
  %137 = load i64, ptr %6, align 8, !tbaa !104
  %138 = and i64 %137, -4
  br label %139

139:                                              ; preds = %117, %129, %136
  %140 = phi i64 [ %138, %136 ], [ 0, %129 ], [ 0, %117 ]
  %141 = icmp ne i64 %140, 0
  %142 = add i64 %126, -1
  %143 = icmp ult i64 %142, %140
  %144 = add i64 %126, %46
  %145 = icmp ult i64 %140, %144
  %146 = and i1 %143, %145
  %147 = select i1 %141, i1 %146, i1 false
  br i1 %147, label %149, label %148

148:                                              ; preds = %139
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.124, i64 noundef %47) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.124, i64 noundef %47) #15
  call void @llvm.lifetime.end.p0(i64 144, ptr nonnull %6) #18
  br label %954

149:                                              ; preds = %139
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.125, i64 noundef %47, i64 noundef %140) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.125, i64 noundef %47, i64 noundef %140) #15
  call void @llvm.lifetime.end.p0(i64 144, ptr nonnull %6) #18
  br label %153

150:                                              ; preds = %96, %99
  %151 = phi i64 [ %112, %99 ], [ %98, %96 ]
  %152 = lshr i64 %151, 20
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.126, i64 noundef %47, i64 noundef %152) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.126, i64 noundef %47, i64 noundef %152) #15
  br label %153

153:                                              ; preds = %149, %85, %150, %84
  %154 = phi i64 [ 268435456, %84 ], [ %151, %150 ], [ 0, %85 ], [ 0, %149 ]
  %155 = phi i64 [ 268435456, %84 ], [ %151, %150 ], [ %46, %85 ], [ %46, %149 ]
  %156 = load ptr, ptr %10, align 8, !tbaa !78
  %157 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %156, i64 noundef 20) #15
  %158 = load ptr, ptr %10, align 8, !tbaa !78
  %159 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %158, i64 noundef 28) #15
  %160 = load ptr, ptr %10, align 8, !tbaa !78
  %161 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %160, i64 noundef 32) #15
  %162 = load ptr, ptr %10, align 8, !tbaa !78
  %163 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %162, i64 noundef 24) #15
  %164 = and i32 %157, 6
  %165 = icmp eq i32 %164, 4
  %166 = and i32 %159, 6
  %167 = icmp eq i32 %166, 4
  %168 = select i1 %165, i1 %167, i1 false
  br i1 %168, label %170, label %169

169:                                              ; preds = %153
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.127, i32 noundef %157, i32 noundef %159) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.127, i32 noundef %157, i32 noundef %159) #15
  br label %954

170:                                              ; preds = %153
  %171 = zext i32 %161 to i64
  %172 = shl nuw i64 %171, 32
  %173 = and i32 %159, -16
  %174 = zext i32 %173 to i64
  %175 = or disjoint i64 %172, %174
  %176 = load ptr, ptr %10, align 8, !tbaa !78
  %177 = load ptr, ptr %176, align 8, !tbaa !4
  %178 = getelementptr inbounds i8, ptr %177, i64 1768
  %179 = load ptr, ptr %178, align 8
  %180 = call ptr %179(ptr noundef nonnull %176) #15
  %181 = load ptr, ptr %10, align 8, !tbaa !78
  %182 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %181, i64 noundef 16) #15
  %183 = icmp eq ptr %180, null
  br i1 %183, label %197, label %184

184:                                              ; preds = %170
  %185 = load ptr, ptr @_ZN18IOMemoryDescriptor9metaClassE, align 8
  %186 = and i32 %182, -16
  %187 = zext i32 %186 to i64
  %188 = load ptr, ptr %180, align 8, !tbaa !4
  %189 = getelementptr inbounds i8, ptr %188, i64 304
  %190 = load ptr, ptr %189, align 8
  %191 = call i32 %190(ptr noundef nonnull %180) #15
  %192 = icmp eq i32 %191, 0
  br i1 %192, label %193, label %205

193:                                              ; preds = %228, %184
  %194 = phi ptr [ null, %184 ], [ %230, %228 ]
  %195 = phi i64 [ 0, %184 ], [ %229, %228 ]
  %196 = icmp eq i64 %154, 0
  br i1 %196, label %237, label %305

197:                                              ; preds = %170
  %198 = icmp eq i64 %154, 0
  br i1 %198, label %199, label %312

199:                                              ; preds = %197
  %200 = zext i32 %163 to i64
  %201 = shl nuw i64 %200, 32
  %202 = and i32 %157, -16
  %203 = zext i32 %202 to i64
  %204 = or disjoint i64 %201, %203
  br label %273

205:                                              ; preds = %184, %228
  %206 = phi i32 [ %231, %228 ], [ 0, %184 ]
  %207 = phi i64 [ %229, %228 ], [ 0, %184 ]
  %208 = phi ptr [ %230, %228 ], [ null, %184 ]
  %209 = load ptr, ptr %180, align 8, !tbaa !4
  %210 = getelementptr inbounds i8, ptr %209, i64 488
  %211 = load ptr, ptr %210, align 8
  %212 = call ptr %211(ptr noundef nonnull %180, i32 noundef %206) #15
  %213 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %212, ptr noundef %185) #15
  %214 = icmp eq ptr %213, null
  br i1 %214, label %228, label %215

215:                                              ; preds = %205
  %216 = call i64 @_ZN18IOMemoryDescriptor18getPhysicalAddressEv(ptr noundef nonnull %213) #15
  %217 = icmp eq i64 %216, %175
  br i1 %217, label %218, label %223

218:                                              ; preds = %215
  %219 = load ptr, ptr %213, align 8, !tbaa !4
  %220 = getelementptr inbounds i8, ptr %219, i64 456
  %221 = load ptr, ptr %220, align 8
  %222 = call i64 %221(ptr noundef nonnull %213) #15
  br label %223

223:                                              ; preds = %218, %215
  %224 = phi i64 [ %222, %218 ], [ %207, %215 ]
  %225 = call i64 @_ZN18IOMemoryDescriptor18getPhysicalAddressEv(ptr noundef nonnull %213) #15
  %226 = icmp eq i64 %225, %187
  %227 = select i1 %226, ptr %213, ptr %208
  br label %228

228:                                              ; preds = %205, %223
  %229 = phi i64 [ %224, %223 ], [ %207, %205 ]
  %230 = phi ptr [ %227, %223 ], [ %208, %205 ]
  %231 = add nuw i32 %206, 1
  %232 = load ptr, ptr %180, align 8, !tbaa !4
  %233 = getelementptr inbounds i8, ptr %232, i64 304
  %234 = load ptr, ptr %233, align 8
  %235 = call i32 %234(ptr noundef nonnull %180) #15
  %236 = icmp ult i32 %231, %235
  br i1 %236, label %205, label %193

237:                                              ; preds = %193
  %238 = zext i32 %163 to i64
  %239 = shl nuw i64 %238, 32
  %240 = and i32 %157, -16
  %241 = zext i32 %240 to i64
  %242 = or disjoint i64 %239, %241
  %243 = load ptr, ptr @_ZN18IOMemoryDescriptor9metaClassE, align 8
  %244 = load ptr, ptr %180, align 8, !tbaa !4
  %245 = getelementptr inbounds i8, ptr %244, i64 304
  %246 = load ptr, ptr %245, align 8
  %247 = call i32 %246(ptr noundef nonnull %180) #15
  %248 = icmp eq i32 %247, 0
  br i1 %248, label %273, label %249

249:                                              ; preds = %237, %266
  %250 = phi i32 [ %267, %266 ], [ 0, %237 ]
  %251 = load ptr, ptr %180, align 8, !tbaa !4
  %252 = getelementptr inbounds i8, ptr %251, i64 488
  %253 = load ptr, ptr %252, align 8
  %254 = call ptr %253(ptr noundef nonnull %180, i32 noundef %250) #15
  %255 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %254, ptr noundef %243) #15
  %256 = icmp eq ptr %255, null
  br i1 %256, label %266, label %257

257:                                              ; preds = %249
  %258 = call i64 @_ZN18IOMemoryDescriptor18getPhysicalAddressEv(ptr noundef nonnull %255) #15
  %259 = icmp eq i64 %258, %242
  br i1 %259, label %260, label %266

260:                                              ; preds = %257
  %261 = load ptr, ptr %255, align 8, !tbaa !4
  %262 = getelementptr inbounds i8, ptr %261, i64 456
  %263 = load ptr, ptr %262, align 8
  %264 = call i64 %263(ptr noundef nonnull %255) #15
  %265 = icmp ult i64 %264, %155
  br i1 %265, label %266, label %273

266:                                              ; preds = %249, %257, %260
  %267 = add nuw i32 %250, 1
  %268 = load ptr, ptr %180, align 8, !tbaa !4
  %269 = getelementptr inbounds i8, ptr %268, i64 304
  %270 = load ptr, ptr %269, align 8
  %271 = call i32 %270(ptr noundef nonnull %180) #15
  %272 = icmp ult i32 %267, %271
  br i1 %272, label %249, label %273

273:                                              ; preds = %260, %266, %237, %199
  %274 = phi i64 [ %204, %199 ], [ %242, %237 ], [ %242, %266 ], [ %242, %260 ]
  %275 = phi i64 [ 0, %199 ], [ %195, %237 ], [ %195, %266 ], [ %195, %260 ]
  %276 = phi ptr [ null, %199 ], [ %194, %237 ], [ %194, %266 ], [ %194, %260 ]
  %277 = phi i1 [ true, %199 ], [ true, %237 ], [ false, %260 ], [ true, %266 ]
  call void @llvm.lifetime.start.p0(i64 144, ptr nonnull %7) #18
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(144) %7, i8 0, i64 144, i1 false)
  %278 = call ptr @_ZN9IOService11getPlatformEv() #15
  %279 = icmp eq ptr %278, null
  br i1 %279, label %296, label %280

280:                                              ; preds = %273
  %281 = call ptr @_ZN9IOService11getPlatformEv() #15
  %282 = load ptr, ptr %281, align 8, !tbaa !4
  %283 = getelementptr inbounds i8, ptr %282, i64 2280
  %284 = load ptr, ptr %283, align 8
  %285 = call i32 %284(ptr noundef nonnull %281, ptr noundef nonnull %7) #15
  %286 = icmp eq i32 %285, 0
  br i1 %286, label %287, label %296

287:                                              ; preds = %280
  %288 = load i64, ptr %7, align 8, !tbaa !104
  %289 = and i64 %288, -4
  %290 = icmp eq i64 %289, 0
  %291 = icmp ult i64 %289, %274
  %292 = select i1 %290, i1 true, i1 %291
  br i1 %292, label %296, label %293

293:                                              ; preds = %287
  %294 = add i64 %274, %155
  %295 = icmp ult i64 %289, %294
  br label %296

296:                                              ; preds = %273, %280, %293, %287
  %297 = phi i64 [ %289, %287 ], [ %289, %293 ], [ 0, %280 ], [ 0, %273 ]
  %298 = phi i1 [ false, %287 ], [ %295, %293 ], [ false, %280 ], [ false, %273 ]
  %299 = icmp eq i32 %163, 0
  %300 = or i1 %299, %277
  %301 = select i1 %300, i1 true, i1 %298
  br i1 %301, label %302, label %303

302:                                              ; preds = %296
  call void @llvm.lifetime.end.p0(i64 144, ptr nonnull %7) #18
  br label %305

303:                                              ; preds = %296
  %304 = lshr i64 %155, 20
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.128, i64 noundef %304, i64 noundef %274, i64 noundef %297) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.128, i64 noundef %304, i64 noundef %274, i64 noundef %297) #15
  call void @llvm.lifetime.end.p0(i64 144, ptr nonnull %7) #18
  br label %954

305:                                              ; preds = %302, %193
  %306 = phi i1 [ true, %302 ], [ false, %193 ]
  %307 = phi ptr [ %276, %302 ], [ %194, %193 ]
  %308 = phi i64 [ %275, %302 ], [ %195, %193 ]
  %309 = icmp ne ptr %307, null
  %310 = icmp ne i64 %308, 0
  %311 = select i1 %309, i1 %310, i1 false
  br i1 %311, label %402, label %312

312:                                              ; preds = %197, %305
  %313 = phi i1 [ %309, %305 ], [ false, %197 ]
  %314 = phi i64 [ %308, %305 ], [ 0, %197 ]
  %315 = phi ptr [ %307, %305 ], [ null, %197 ]
  %316 = phi i1 [ %306, %305 ], [ false, %197 ]
  %317 = load ptr, ptr %10, align 8, !tbaa !78
  %318 = load ptr, ptr %317, align 8, !tbaa !4
  %319 = getelementptr inbounds i8, ptr %318, i64 696
  %320 = load ptr, ptr %319, align 8
  %321 = call ptr %320(ptr noundef nonnull %317, ptr noundef nonnull @.str.129) #15
  %322 = load ptr, ptr @_ZN6OSData9metaClassE, align 8, !tbaa !10
  %323 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %321, ptr noundef %322) #15
  %324 = icmp eq ptr %323, null
  br i1 %324, label %402, label %325

325:                                              ; preds = %312
  %326 = load ptr, ptr %323, align 8, !tbaa !4
  %327 = getelementptr inbounds i8, ptr %326, i64 376
  %328 = load ptr, ptr %327, align 8
  %329 = call ptr %328(ptr noundef nonnull %323) #15
  %330 = icmp eq ptr %329, null
  br i1 %330, label %402, label %331

331:                                              ; preds = %325
  %332 = getelementptr inbounds i8, ptr %329, i64 4
  %333 = getelementptr inbounds i8, ptr %329, i64 8
  %334 = getelementptr inbounds i8, ptr %329, i64 12
  %335 = getelementptr inbounds i8, ptr %329, i64 16
  %336 = load ptr, ptr %323, align 8, !tbaa !4
  %337 = getelementptr inbounds i8, ptr %336, i64 320
  %338 = load ptr, ptr %337, align 8
  %339 = call i32 %338(ptr noundef nonnull %323) #15
  %340 = icmp ult i32 %339, 20
  br i1 %340, label %381, label %341

341:                                              ; preds = %331, %341
  %342 = phi i64 [ %373, %341 ], [ 5, %331 ]
  %343 = phi i64 [ %371, %341 ], [ 0, %331 ]
  %344 = phi i64 [ %372, %341 ], [ 0, %331 ]
  %345 = phi i64 [ %368, %341 ], [ 0, %331 ]
  %346 = phi i64 [ %369, %341 ], [ 0, %331 ]
  %347 = phi i64 [ %342, %341 ], [ 0, %331 ]
  %348 = getelementptr inbounds i32, ptr %332, i64 %347
  %349 = load i32, ptr %348, align 4, !tbaa !18
  %350 = zext i32 %349 to i64
  %351 = shl nuw i64 %350, 32
  %352 = getelementptr inbounds i32, ptr %333, i64 %347
  %353 = load i32, ptr %352, align 4, !tbaa !18
  %354 = zext i32 %353 to i64
  %355 = or disjoint i64 %351, %354
  %356 = getelementptr inbounds i32, ptr %334, i64 %347
  %357 = load i32, ptr %356, align 4, !tbaa !18
  %358 = zext i32 %357 to i64
  %359 = shl nuw i64 %358, 32
  %360 = getelementptr inbounds i32, ptr %335, i64 %347
  %361 = load i32, ptr %360, align 4, !tbaa !18
  %362 = zext i32 %361 to i64
  %363 = or disjoint i64 %359, %362
  %364 = getelementptr inbounds i32, ptr %329, i64 %347
  %365 = load i32, ptr %364, align 4, !tbaa !18
  %366 = and i32 %365, 255
  %367 = icmp eq i32 %366, 16
  %368 = select i1 %367, i64 %363, i64 %345
  %369 = select i1 %367, i64 %355, i64 %346
  %370 = icmp eq i32 %366, 28
  %371 = select i1 %370, i64 %363, i64 %343
  %372 = select i1 %370, i64 %355, i64 %344
  %373 = add nuw nsw i64 %342, 5
  %374 = load ptr, ptr %323, align 8, !tbaa !4
  %375 = getelementptr inbounds i8, ptr %374, i64 320
  %376 = load ptr, ptr %375, align 8
  %377 = call i32 %376(ptr noundef nonnull %323) #15
  %378 = lshr i32 %377, 2
  %379 = zext nneg i32 %378 to i64
  %380 = icmp ugt i64 %373, %379
  br i1 %380, label %381, label %341

381:                                              ; preds = %341, %331
  %382 = phi i64 [ 0, %331 ], [ %369, %341 ]
  %383 = phi i64 [ 0, %331 ], [ %368, %341 ]
  %384 = phi i64 [ 0, %331 ], [ %372, %341 ]
  %385 = phi i64 [ 0, %331 ], [ %371, %341 ]
  %386 = icmp eq ptr %315, null
  %387 = icmp ne i64 %383, 0
  %388 = select i1 %386, i1 %387, i1 false
  %389 = and i32 %182, -16
  %390 = zext i32 %389 to i64
  %391 = icmp eq i64 %382, %390
  %392 = select i1 %388, i1 %391, i1 false
  br i1 %392, label %393, label %394

393:                                              ; preds = %381
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.130, i64 noundef %390, i64 noundef %383) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.130, i64 noundef %390, i64 noundef %383) #15
  br label %394

394:                                              ; preds = %393, %381
  %395 = phi i64 [ %383, %393 ], [ 0, %381 ]
  %396 = icmp eq i64 %314, 0
  %397 = icmp ne i64 %385, 0
  %398 = select i1 %396, i1 %397, i1 false
  br i1 %398, label %399, label %402

399:                                              ; preds = %394
  %400 = icmp eq i64 %384, %175
  br i1 %400, label %401, label %412

401:                                              ; preds = %399
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.131, i64 noundef %175, i64 noundef %385) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.131, i64 noundef %175, i64 noundef %385) #15
  br label %402

402:                                              ; preds = %325, %312, %394, %401, %305
  %403 = phi i1 [ %309, %305 ], [ %313, %401 ], [ %313, %394 ], [ %313, %312 ], [ %313, %325 ]
  %404 = phi ptr [ %307, %305 ], [ %315, %401 ], [ %315, %394 ], [ %315, %312 ], [ %315, %325 ]
  %405 = phi i1 [ %306, %305 ], [ %316, %401 ], [ %316, %394 ], [ %316, %312 ], [ %316, %325 ]
  %406 = phi i64 [ 0, %305 ], [ %395, %401 ], [ %395, %394 ], [ 0, %312 ], [ 0, %325 ]
  %407 = phi i64 [ %308, %305 ], [ %385, %401 ], [ %314, %394 ], [ %314, %312 ], [ %314, %325 ]
  %408 = icmp ne i64 %406, 0
  %409 = select i1 %403, i1 true, i1 %408
  %410 = icmp ne i64 %407, 0
  %411 = select i1 %409, i1 %410, i1 false
  br i1 %411, label %416, label %412

412:                                              ; preds = %399, %402
  %413 = phi i1 [ %403, %402 ], [ %313, %399 ]
  %414 = phi i64 [ %407, %402 ], [ 0, %399 ]
  %415 = zext i1 %413 to i32
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.132, i32 noundef %415, i64 noundef %414) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.132, i32 noundef %415, i64 noundef %414) #15
  br label %954

416:                                              ; preds = %402
  %417 = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={ax},={bx},={cx},={dx},{ax},{cx},~{dirflag},~{fpsr},~{flags}"(i32 -2147483648, i32 0) #18, !srcloc !105
  %418 = extractvalue { i32, i32, i32, i32 } %417, 0
  %419 = icmp ult i32 %418, -2147483640
  br i1 %419, label %430, label %420

420:                                              ; preds = %416
  %421 = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={ax},={bx},={cx},={dx},{ax},{cx},~{dirflag},~{fpsr},~{flags}"(i32 -2147483640, i32 0) #18, !srcloc !106
  %422 = freeze { i32, i32, i32, i32 } %421
  %423 = extractvalue { i32, i32, i32, i32 } %422, 0
  %424 = and i32 %423, 255
  %425 = icmp ugt i32 %424, 62
  %426 = zext nneg i32 %424 to i64
  %427 = shl nsw i64 -1, %426
  %428 = xor i64 %427, -1
  %429 = select i1 %425, i64 -1, i64 %428
  br label %430

430:                                              ; preds = %420, %416
  %431 = phi i32 [ 36, %416 ], [ %424, %420 ]
  %432 = phi i64 [ 68719476735, %416 ], [ %429, %420 ]
  %433 = load ptr, ptr %10, align 8, !tbaa !78
  %434 = icmp eq ptr %433, null
  br i1 %434, label %566, label %435

435:                                              ; preds = %430
  %436 = load ptr, ptr @_ZN20IOACPIPlatformDevice9metaClassE, align 8
  br label %438

437:                                              ; preds = %438
  br i1 %450, label %566, label %452

438:                                              ; preds = %438, %435
  %439 = phi ptr [ %433, %435 ], [ %444, %438 ]
  %440 = phi i32 [ 0, %435 ], [ %446, %438 ]
  %441 = load ptr, ptr %439, align 8, !tbaa !4
  %442 = getelementptr inbounds i8, ptr %441, i64 1664
  %443 = load ptr, ptr %442, align 8
  %444 = call ptr %443(ptr noundef nonnull %439) #15
  %445 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %444, ptr noundef %436) #15
  %446 = add nuw nsw i32 %440, 1
  %447 = icmp ne ptr %444, null
  %448 = icmp ult i32 %440, 15
  %449 = select i1 %447, i1 %448, i1 false
  %450 = icmp eq ptr %445, null
  %451 = select i1 %449, i1 %450, i1 false
  br i1 %451, label %438, label %437, !llvm.loop !107

452:                                              ; preds = %437
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #18
  store ptr null, ptr %4, align 8, !tbaa !10
  %453 = load ptr, ptr %445, align 8, !tbaa !4
  %454 = getelementptr inbounds i8, ptr %453, i64 2240
  %455 = load ptr, ptr %454, align 8
  %456 = call i32 %455(ptr noundef nonnull %445, ptr noundef nonnull @.str.316, ptr noundef nonnull %4, ptr noundef null, i32 noundef 0, i32 noundef 0) #15
  %457 = icmp eq i32 %456, 0
  %458 = load ptr, ptr %4, align 8
  %459 = icmp ne ptr %458, null
  %460 = select i1 %457, i1 %459, i1 false
  br i1 %460, label %462, label %461

461:                                              ; preds = %452
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  br label %566

462:                                              ; preds = %452
  %463 = load ptr, ptr @_ZN6OSData9metaClassE, align 8, !tbaa !10
  %464 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef nonnull %458, ptr noundef %463) #15
  %465 = icmp eq ptr %464, null
  br i1 %465, label %557, label %466

466:                                              ; preds = %462
  %467 = load ptr, ptr %464, align 8, !tbaa !4
  %468 = getelementptr inbounds i8, ptr %467, i64 376
  %469 = load ptr, ptr %468, align 8
  %470 = call ptr %469(ptr noundef nonnull %464) #15
  %471 = load ptr, ptr %464, align 8, !tbaa !4
  %472 = getelementptr inbounds i8, ptr %471, i64 320
  %473 = load ptr, ptr %472, align 8
  %474 = call i32 %473(ptr noundef nonnull %464) #15
  %475 = icmp ne ptr %470, null
  %476 = icmp ne i32 %474, 0
  %477 = select i1 %475, i1 %476, i1 false
  br i1 %477, label %478, label %557

478:                                              ; preds = %466, %545
  %479 = phi i64 [ %546, %545 ], [ 0, %466 ]
  %480 = phi i64 [ %547, %545 ], [ 0, %466 ]
  %481 = phi i32 [ %550, %545 ], [ 0, %466 ]
  %482 = phi i8 [ %548, %545 ], [ 0, %466 ]
  %483 = zext i32 %481 to i64
  %484 = getelementptr inbounds i8, ptr %470, i64 %483
  %485 = load i8, ptr %484, align 1, !tbaa !20
  %486 = zext i8 %485 to i32
  %487 = icmp sgt i8 %485, -1
  br i1 %487, label %539, label %488

488:                                              ; preds = %478
  %489 = add i32 %481, 3
  %490 = icmp ugt i32 %489, %474
  br i1 %490, label %552, label %491

491:                                              ; preds = %488
  %492 = add nuw i32 %481, 1
  %493 = zext i32 %492 to i64
  %494 = getelementptr inbounds i8, ptr %470, i64 %493
  %495 = load i8, ptr %494, align 1, !tbaa !20
  %496 = zext i8 %495 to i32
  %497 = add i32 %481, 2
  %498 = zext i32 %497 to i64
  %499 = getelementptr inbounds i8, ptr %470, i64 %498
  %500 = load i8, ptr %499, align 1, !tbaa !20
  %501 = zext i8 %500 to i32
  %502 = shl nuw nsw i32 %501, 8
  %503 = or disjoint i32 %502, %496
  %504 = add i32 %503, %489
  %505 = icmp ugt i32 %504, %474
  br i1 %505, label %552, label %506

506:                                              ; preds = %491
  %507 = icmp eq i8 %485, -118
  %508 = icmp ugt i32 %503, 42
  %509 = and i1 %507, %508
  br i1 %509, label %510, label %534

510:                                              ; preds = %506
  %511 = zext i32 %489 to i64
  %512 = getelementptr inbounds i8, ptr %470, i64 %511
  %513 = load i8, ptr %512, align 1, !tbaa !20
  %514 = icmp eq i8 %513, 0
  br i1 %514, label %515, label %534

515:                                              ; preds = %510
  %516 = getelementptr inbounds i8, ptr %484, i64 14
  %517 = load i64, ptr %516, align 1
  %518 = getelementptr inbounds i8, ptr %484, i64 22
  %519 = load i64, ptr %518, align 1
  %520 = getelementptr inbounds i8, ptr %484, i64 30
  %521 = load i64, ptr %520, align 1
  %522 = icmp eq i64 %521, 0
  %523 = icmp ugt i64 %517, 4294967295
  %524 = select i1 %522, i1 %523, i1 false
  %525 = icmp ugt i64 %519, %517
  %526 = select i1 %524, i1 %525, i1 false
  br i1 %526, label %527, label %534

527:                                              ; preds = %515
  %528 = trunc nuw i8 %482 to i1
  br i1 %528, label %529, label %533

529:                                              ; preds = %527
  %530 = sub i64 %519, %517
  %531 = sub i64 %480, %479
  %532 = icmp ugt i64 %530, %531
  br i1 %532, label %533, label %534

533:                                              ; preds = %529, %527
  br label %534

534:                                              ; preds = %533, %529, %515, %510, %506
  %535 = phi i64 [ %517, %533 ], [ %479, %529 ], [ %479, %515 ], [ %479, %510 ], [ %479, %506 ]
  %536 = phi i64 [ %519, %533 ], [ %480, %529 ], [ %480, %515 ], [ %480, %510 ], [ %480, %506 ]
  %537 = phi i8 [ 1, %533 ], [ %482, %529 ], [ %482, %515 ], [ %482, %510 ], [ %482, %506 ]
  %538 = add nuw nsw i32 %503, 3
  br label %545

539:                                              ; preds = %478
  %540 = and i32 %486, 120
  %541 = icmp eq i32 %540, 120
  br i1 %541, label %552, label %542

542:                                              ; preds = %539
  %543 = and i32 %486, 7
  %544 = add nuw nsw i32 %543, 1
  br label %545

545:                                              ; preds = %542, %534
  %546 = phi i64 [ %479, %542 ], [ %535, %534 ]
  %547 = phi i64 [ %480, %542 ], [ %536, %534 ]
  %548 = phi i8 [ %482, %542 ], [ %537, %534 ]
  %549 = phi i32 [ %544, %542 ], [ %538, %534 ]
  %550 = add i32 %549, %481
  %551 = icmp ult i32 %550, %474
  br i1 %551, label %478, label %552

552:                                              ; preds = %545, %539, %491, %488
  %553 = phi i64 [ %479, %539 ], [ %546, %545 ], [ %479, %488 ], [ %479, %491 ]
  %554 = phi i64 [ %480, %539 ], [ %547, %545 ], [ %480, %488 ], [ %480, %491 ]
  %555 = phi i8 [ %482, %539 ], [ %548, %545 ], [ %482, %488 ], [ %482, %491 ]
  %556 = trunc nuw i8 %555 to i1
  br label %557

557:                                              ; preds = %462, %466, %552
  %558 = phi i64 [ 0, %462 ], [ %553, %552 ], [ 0, %466 ]
  %559 = phi i64 [ 0, %462 ], [ %554, %552 ], [ 0, %466 ]
  %560 = phi i1 [ false, %462 ], [ %556, %552 ], [ false, %466 ]
  %561 = load ptr, ptr %4, align 8, !tbaa !10
  %562 = load ptr, ptr %561, align 8, !tbaa !4
  %563 = getelementptr inbounds i8, ptr %562, i64 40
  %564 = load ptr, ptr %563, align 8
  call void %564(ptr noundef nonnull %561) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  br i1 %560, label %565, label %566

565:                                              ; preds = %557
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.133, i64 noundef %558, i64 noundef %559, i32 noundef %431) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.133, i64 noundef %558, i64 noundef %559, i32 noundef %431) #15
  br label %592

566:                                              ; preds = %430, %437, %461, %557
  %567 = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={ax},={bx},={cx},={dx},{ax},{cx},~{dirflag},~{fpsr},~{flags}"(i32 0, i32 0) #18, !srcloc !108
  %568 = extractvalue { i32, i32, i32, i32 } %567, 1
  %569 = extractvalue { i32, i32, i32, i32 } %567, 2
  %570 = extractvalue { i32, i32, i32, i32 } %567, 3
  %571 = icmp eq i32 %568, 1970169159
  %572 = icmp eq i32 %570, 1231384169
  %573 = select i1 %571, i1 %572, i1 false
  %574 = icmp eq i32 %569, 1818588270
  %575 = select i1 %573, i1 %574, i1 false
  br i1 %575, label %576, label %589

576:                                              ; preds = %566
  %577 = icmp ult i32 %431, 39
  br i1 %577, label %589, label %578

578:                                              ; preds = %576
  %579 = icmp eq i32 %163, 0
  br i1 %579, label %589, label %580

580:                                              ; preds = %578
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #18
  store i64 0, ptr %2, align 8, !tbaa !7
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #18
  store i64 8, ptr %3, align 8, !tbaa !97
  %581 = call i32 @sysctlbyname(ptr noundef nonnull @.str.320, ptr noundef nonnull %2, ptr noundef nonnull %3, ptr noundef null, i64 noundef 0) #15
  %582 = icmp eq i32 %581, 0
  %583 = load i64, ptr %2, align 8
  %584 = icmp ne i64 %583, 0
  %585 = select i1 %582, i1 %584, i1 false
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #18
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #18
  br i1 %585, label %586, label %589

586:                                              ; preds = %580
  %587 = add i64 %583, 4294967296
  %588 = icmp ult i64 %587, 274877906944
  br i1 %588, label %591, label %589

589:                                              ; preds = %578, %576, %566, %580, %586
  %590 = phi ptr [ @.str.322, %586 ], [ @.str.319, %578 ], [ @.str.318, %576 ], [ @.str.317, %566 ], [ @.str.321, %580 ]
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.134, ptr noundef nonnull %590, i64 noundef 1099511627776, i64 noundef 4396972769279, i32 noundef %431) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.134, ptr noundef nonnull %590, i64 noundef 1099511627776, i64 noundef 4396972769279, i32 noundef %431) #15
  br label %592

591:                                              ; preds = %586
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.135, i64 noundef 274877906944, i64 noundef 549755813887, i32 noundef %431) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.135, i64 noundef 274877906944, i64 noundef 549755813887, i32 noundef %431) #15
  br label %592

592:                                              ; preds = %589, %591, %565
  %593 = phi i64 [ %558, %565 ], [ 274877906944, %591 ], [ 1099511627776, %589 ]
  %594 = phi i64 [ %559, %565 ], [ 549755813887, %591 ], [ 4396972769279, %589 ]
  %595 = call i64 @llvm.umin.i64(i64 %594, i64 %432)
  %596 = add i64 %407, %155
  %597 = icmp ugt i64 %595, %593
  br i1 %597, label %598, label %602

598:                                              ; preds = %592
  %599 = sub i64 %595, %593
  %600 = add i64 %599, 1
  %601 = icmp ult i64 %600, %596
  br i1 %601, label %602, label %604

602:                                              ; preds = %592, %598
  %603 = lshr i64 %596, 20
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.136, i64 noundef %593, i64 noundef %595, i64 noundef %603) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.136, i64 noundef %593, i64 noundef %595, i64 noundef %603) #15
  br label %954

604:                                              ; preds = %598
  %605 = sub i64 %595, %596
  %606 = freeze i64 %605
  %607 = add i64 %606, 1
  %608 = urem i64 %607, %155
  %609 = sub nuw i64 %607, %608
  %610 = add i64 %609, %155
  %611 = add i64 %407, -1
  %612 = add i64 %611, %610
  %613 = icmp ult i64 %609, %593
  %614 = icmp ugt i64 %612, %595
  %615 = select i1 %613, i1 true, i1 %614
  br i1 %615, label %616, label %618

616:                                              ; preds = %604
  %617 = lshr i64 %155, 20
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.137, i64 noundef %617, i64 noundef %593, i64 noundef %595) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.137, i64 noundef %617, i64 noundef %593, i64 noundef %595) #15
  br label %954

618:                                              ; preds = %604
  %619 = load ptr, ptr %10, align 8, !tbaa !78
  %620 = load ptr, ptr %619, align 8, !tbaa !4
  %621 = getelementptr inbounds i8, ptr %620, i64 1664
  %622 = load ptr, ptr %621, align 8
  %623 = call ptr %622(ptr noundef nonnull %619) #15
  %624 = icmp eq ptr %623, null
  br i1 %624, label %637, label %625

625:                                              ; preds = %618
  %626 = load ptr, ptr %623, align 8, !tbaa !4
  %627 = getelementptr inbounds i8, ptr %626, i64 1664
  %628 = load ptr, ptr %627, align 8
  %629 = call ptr %628(ptr noundef nonnull %623) #15
  %630 = load ptr, ptr @_ZN11IOPCIDevice9metaClassE, align 8, !tbaa !10
  %631 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %629, ptr noundef %630) #15
  %632 = icmp eq ptr %631, null
  br i1 %632, label %637, label %633

633:                                              ; preds = %625
  %634 = call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef nonnull %631, i64 noundef 14) #15
  %635 = and i8 %634, 127
  %636 = icmp eq i8 %635, 1
  br i1 %636, label %638, label %637

637:                                              ; preds = %618, %625, %633
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.138) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.138) #15
  br label %954

638:                                              ; preds = %633
  %639 = call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef nonnull %631, i64 noundef 52) #15
  %640 = and i8 %639, -4
  %641 = icmp eq i8 %640, 0
  br i1 %641, label %664, label %642

642:                                              ; preds = %638, %648
  %643 = phi i8 [ %652, %648 ], [ %640, %638 ]
  %644 = phi i8 [ %651, %648 ], [ 0, %638 ]
  %645 = zext i8 %643 to i64
  %646 = call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef %631, i64 noundef %645) #15
  %647 = icmp eq i8 %646, 16
  br i1 %647, label %656, label %648

648:                                              ; preds = %642
  %649 = or disjoint i64 %645, 1
  %650 = call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef %631, i64 noundef %649) #15
  %651 = add nuw nsw i8 %644, 1
  %652 = and i8 %650, -4
  %653 = icmp ne i8 %652, 0
  %654 = icmp ult i8 %644, 47
  %655 = select i1 %653, i1 %654, i1 false
  br i1 %655, label %642, label %664, !llvm.loop !109

656:                                              ; preds = %642
  %657 = or disjoint i8 %643, 2
  %658 = zext i8 %657 to i64
  %659 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %631, i64 noundef %658) #15
  %660 = lshr i16 %659, 4
  %661 = and i16 %660, 15
  %662 = zext nneg i16 %661 to i32
  %663 = icmp eq i16 %661, 4
  br i1 %663, label %666, label %664

664:                                              ; preds = %648, %638, %656
  %665 = phi i32 [ %662, %656 ], [ 255, %638 ], [ 255, %648 ]
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.139, i32 noundef %665) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.139, i32 noundef %665) #15
  br label %954

666:                                              ; preds = %656
  %667 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 24) #15
  %668 = lshr i32 %667, 8
  %669 = lshr i32 %667, 16
  %670 = trunc i32 %669 to i8
  %671 = load ptr, ptr %10, align 8, !tbaa !78
  %672 = load ptr, ptr %671, align 8, !tbaa !4
  %673 = getelementptr inbounds i8, ptr %672, i64 2280
  %674 = load ptr, ptr %673, align 8
  %675 = call zeroext i8 %674(ptr noundef nonnull %671) #15
  %676 = and i32 %668, 255
  %677 = zext i8 %675 to i32
  %678 = icmp ne i32 %676, %677
  %679 = and i32 %669, 255
  %680 = icmp ult i32 %679, %676
  %681 = select i1 %678, i1 true, i1 %680
  br i1 %681, label %682, label %683

682:                                              ; preds = %666
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.140, i32 noundef %676, i32 noundef %679, i32 noundef %677) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.140, i32 noundef %676, i32 noundef %679, i32 noundef %677) #15
  br label %954

683:                                              ; preds = %666
  %684 = icmp ugt i32 %679, %676
  br i1 %684, label %685, label %690

685:                                              ; preds = %683
  %686 = add i8 %675, 1
  %687 = load ptr, ptr %10, align 8, !tbaa !78
  %688 = call fastcc zeroext i1 @_ZL27nvrmBusRangeHasOtherDeviceshhP11IOPCIDevice(i8 noundef zeroext %686, i8 noundef zeroext %670, ptr noundef %687) #17
  br i1 %688, label %689, label %690

689:                                              ; preds = %685
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.141, i32 noundef %676, i32 noundef %679) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.141, i32 noundef %676, i32 noundef %679) #15
  br label %954

690:                                              ; preds = %685, %683
  %691 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 36) #15
  %692 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 40) #15
  %693 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 44) #15
  %694 = and i32 %691, 15
  %695 = icmp eq i32 %694, 1
  br i1 %695, label %696, label %701

696:                                              ; preds = %690
  %697 = load ptr, ptr %10, align 8, !tbaa !78
  %698 = call fastcc zeroext i1 @_ZL13nvrmRangeBusyyyP11IOPCIDeviceS0_(i64 noundef %609, i64 noundef %612, ptr noundef %697, ptr noundef %631) #17
  br i1 %698, label %699, label %715

699:                                              ; preds = %696
  %700 = add i64 %593, %155
  br label %702

701:                                              ; preds = %690
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.142, i32 noundef %691) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.142, i32 noundef %691) #15
  br label %954

702:                                              ; preds = %699, %709
  %703 = phi i32 [ 1, %699 ], [ %712, %709 ]
  %704 = phi i64 [ %609, %699 ], [ %710, %709 ]
  %705 = icmp ugt i32 %703, 15
  %706 = icmp ult i64 %704, %700
  %707 = or i1 %705, %706
  br i1 %707, label %708, label %709

708:                                              ; preds = %702
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.143) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.143) #15
  br label %954

709:                                              ; preds = %702
  %710 = sub i64 %704, %155
  %711 = add i64 %611, %704
  %712 = add nuw nsw i32 %703, 1
  %713 = load ptr, ptr %10, align 8, !tbaa !78
  %714 = call fastcc zeroext i1 @_ZL13nvrmRangeBusyyyP11IOPCIDeviceS0_(i64 noundef %710, i64 noundef %711, ptr noundef %713, ptr noundef %631) #17
  br i1 %714, label %702, label %715, !llvm.loop !110

715:                                              ; preds = %709, %696
  %716 = phi i64 [ %609, %696 ], [ %710, %709 ]
  %717 = phi i64 [ %610, %696 ], [ %704, %709 ]
  %718 = phi i64 [ %612, %696 ], [ %711, %709 ]
  %719 = lshr i64 %155, 20
  %720 = lshr i64 %407, 20
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.144, i64 noundef %719, i64 noundef %716, i64 noundef %720, i64 noundef %717, i64 noundef %716, i64 noundef %718, i32 noundef %691, i32 noundef %692, i32 noundef %693) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.144, i64 noundef %719, i64 noundef %716, i64 noundef %720, i64 noundef %717, i64 noundef %716, i64 noundef %718, i32 noundef %691, i32 noundef %692, i32 noundef %693) #15
  %721 = load ptr, ptr %10, align 8, !tbaa !78
  %722 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %721, i64 noundef 4) #15
  %723 = load ptr, ptr %10, align 8, !tbaa !78
  %724 = and i16 %722, -3
  call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %723, i64 noundef 4, i16 noundef zeroext %724) #15
  br i1 %405, label %746, label %725

725:                                              ; preds = %715
  %726 = load ptr, ptr %10, align 8, !tbaa !78
  %727 = zext i32 %45 to i64
  %728 = and i32 %44, -16129
  %729 = call range(i64 0, 65) i64 @llvm.cttz.i64(i64 %154, i1 true)
  %730 = trunc nuw nsw i64 %729 to i32
  %731 = add nsw i32 %730, -20
  %732 = shl nsw i32 %731, 8
  %733 = or i32 %732, %728
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %726, i64 noundef %727, i32 noundef %733) #15
  %734 = load ptr, ptr %10, align 8, !tbaa !78
  %735 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %734, i64 noundef %727) #15
  %736 = lshr i32 %735, 8
  %737 = and i32 %736, 63
  %738 = icmp eq i32 %737, %731
  %739 = lshr i64 %154, 20
  br i1 %738, label %740, label %741

740:                                              ; preds = %725
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.146, i64 noundef %739) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.146, i64 noundef %739) #15
  br label %746

741:                                              ; preds = %725
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.145, i64 noundef %739, i32 noundef %735) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.145, i64 noundef %739, i32 noundef %735) #15
  %742 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %742, i64 noundef %727, i32 noundef %44) #15
  %743 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %743, i64 noundef 20, i32 noundef %157) #15
  %744 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %744, i64 noundef 24, i32 noundef %163) #15
  %745 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %745, i64 noundef 4, i16 noundef zeroext %722) #15
  br label %954

746:                                              ; preds = %740, %715
  %747 = load ptr, ptr %10, align 8, !tbaa !78
  %748 = trunc i64 %716 to i32
  %749 = and i32 %157, 13
  %750 = or i32 %749, %748
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %747, i64 noundef 20, i32 noundef %750) #15
  %751 = load ptr, ptr %10, align 8, !tbaa !78
  %752 = lshr i64 %716, 32
  %753 = trunc nuw i64 %752 to i32
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %751, i64 noundef 24, i32 noundef %753) #15
  %754 = load ptr, ptr %10, align 8, !tbaa !78
  %755 = trunc i64 %717 to i32
  %756 = and i32 %159, 13
  %757 = or i32 %756, %755
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %754, i64 noundef 28, i32 noundef %757) #15
  %758 = load ptr, ptr %10, align 8, !tbaa !78
  %759 = lshr i64 %717, 32
  %760 = trunc nuw i64 %759 to i32
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %758, i64 noundef 32, i32 noundef %760) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 36, i32 noundef 65520) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 40, i32 noundef %753) #15
  %761 = lshr i64 %718, 32
  %762 = trunc nuw i64 %761 to i32
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 44, i32 noundef %762) #15
  %763 = lshr i32 %748, 16
  %764 = and i32 %763, 65520
  %765 = trunc i64 %718 to i32
  %766 = and i32 %765, -1048576
  %767 = or disjoint i32 %766, %764
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 36, i32 noundef %767) #15
  %768 = load ptr, ptr %10, align 8, !tbaa !78
  %769 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %768, i64 noundef 20) #15
  %770 = and i32 %769, -16
  %771 = icmp eq i32 %770, %748
  br i1 %771, label %772, label %795

772:                                              ; preds = %746
  %773 = load ptr, ptr %10, align 8, !tbaa !78
  %774 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %773, i64 noundef 24) #15
  %775 = icmp eq i32 %774, %753
  br i1 %775, label %776, label %795

776:                                              ; preds = %772
  %777 = load ptr, ptr %10, align 8, !tbaa !78
  %778 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %777, i64 noundef 28) #15
  %779 = and i32 %778, -16
  %780 = icmp eq i32 %779, %755
  br i1 %780, label %781, label %795

781:                                              ; preds = %776
  %782 = load ptr, ptr %10, align 8, !tbaa !78
  %783 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %782, i64 noundef 32) #15
  %784 = icmp eq i32 %783, %760
  br i1 %784, label %785, label %795

785:                                              ; preds = %781
  %786 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 36) #15
  %787 = and i32 %786, -983056
  %788 = icmp eq i32 %787, %767
  br i1 %788, label %789, label %795

789:                                              ; preds = %785
  %790 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 40) #15
  %791 = icmp eq i32 %790, %753
  br i1 %791, label %792, label %795

792:                                              ; preds = %789
  %793 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 44) #15
  %794 = icmp eq i32 %793, %762
  br i1 %794, label %819, label %795

795:                                              ; preds = %789, %785, %781, %776, %772, %746, %792
  %796 = load ptr, ptr %10, align 8, !tbaa !78
  %797 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %796, i64 noundef 20) #15
  %798 = load ptr, ptr %10, align 8, !tbaa !78
  %799 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %798, i64 noundef 24) #15
  %800 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 36) #15
  %801 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 40) #15
  %802 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 44) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.147, i32 noundef %797, i32 noundef %799, i32 noundef %800, i32 noundef %801, i32 noundef %802) #15
  %803 = load ptr, ptr %10, align 8, !tbaa !78
  %804 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %803, i64 noundef 20) #15
  %805 = load ptr, ptr %10, align 8, !tbaa !78
  %806 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %805, i64 noundef 24) #15
  %807 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 36) #15
  %808 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 40) #15
  %809 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %631, i64 noundef 44) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.147, i32 noundef %804, i32 noundef %806, i32 noundef %807, i32 noundef %808, i32 noundef %809) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 36, i32 noundef 65520) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 40, i32 noundef %692) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 44, i32 noundef %693) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 36, i32 noundef %691) #15
  br i1 %405, label %813, label %810

810:                                              ; preds = %795
  %811 = load ptr, ptr %10, align 8, !tbaa !78
  %812 = zext i32 %45 to i64
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %811, i64 noundef %812, i32 noundef %44) #15
  br label %813

813:                                              ; preds = %810, %795
  %814 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %814, i64 noundef 20, i32 noundef %157) #15
  %815 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %815, i64 noundef 24, i32 noundef %163) #15
  %816 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %816, i64 noundef 28, i32 noundef %159) #15
  %817 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %817, i64 noundef 32, i32 noundef %161) #15
  %818 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %818, i64 noundef 4, i16 noundef zeroext %722) #15
  br label %954

819:                                              ; preds = %792
  %820 = load ptr, ptr %10, align 8, !tbaa !78
  %821 = or i16 %722, 2
  call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %820, i64 noundef 4, i16 noundef zeroext %821) #15
  br i1 %183, label %827, label %822

822:                                              ; preds = %819
  %823 = load ptr, ptr %180, align 8, !tbaa !4
  %824 = getelementptr inbounds i8, ptr %823, i64 304
  %825 = load ptr, ptr %824, align 8
  %826 = call i32 %825(ptr noundef nonnull %180) #15
  br label %827

827:                                              ; preds = %819, %822
  %828 = phi i32 [ %826, %822 ], [ 0, %819 ]
  %829 = add i32 %828, 3
  %830 = call ptr @_ZN7OSArray12withCapacityEj(i32 noundef %829) #15
  %831 = call ptr @_ZN14IODeviceMemory9withRangeEyy(i64 noundef %716, i64 noundef %155) #15
  %832 = call ptr @_ZN14IODeviceMemory9withRangeEyy(i64 noundef %717, i64 noundef %407) #15
  br i1 %403, label %837, label %833

833:                                              ; preds = %827
  %834 = and i32 %182, -16
  %835 = zext i32 %834 to i64
  %836 = call ptr @_ZN14IODeviceMemory9withRangeEyy(i64 noundef %835, i64 noundef %406) #15
  br label %837

837:                                              ; preds = %827, %833
  %838 = phi ptr [ %836, %833 ], [ %404, %827 ]
  %839 = phi ptr [ %836, %833 ], [ null, %827 ]
  %840 = icmp ne ptr %830, null
  %841 = icmp ne ptr %831, null
  %842 = select i1 %840, i1 %841, i1 false
  %843 = icmp ne ptr %832, null
  %844 = select i1 %842, i1 %843, i1 false
  br i1 %844, label %845, label %848

845:                                              ; preds = %837
  %846 = icmp ne ptr %839, null
  %847 = select i1 %403, i1 true, i1 %846
  br i1 %847, label %880, label %848

848:                                              ; preds = %837, %845
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.148) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.148) #15
  br i1 %840, label %849, label %853

849:                                              ; preds = %848
  %850 = load ptr, ptr %830, align 8, !tbaa !4
  %851 = getelementptr inbounds i8, ptr %850, i64 40
  %852 = load ptr, ptr %851, align 8
  call void %852(ptr noundef nonnull %830) #15
  br label %853

853:                                              ; preds = %849, %848
  br i1 %841, label %854, label %858

854:                                              ; preds = %853
  %855 = load ptr, ptr %831, align 8, !tbaa !4
  %856 = getelementptr inbounds i8, ptr %855, i64 40
  %857 = load ptr, ptr %856, align 8
  call void %857(ptr noundef nonnull %831) #15
  br label %858

858:                                              ; preds = %854, %853
  br i1 %843, label %859, label %863

859:                                              ; preds = %858
  %860 = load ptr, ptr %832, align 8, !tbaa !4
  %861 = getelementptr inbounds i8, ptr %860, i64 40
  %862 = load ptr, ptr %861, align 8
  call void %862(ptr noundef nonnull %832) #15
  br label %863

863:                                              ; preds = %859, %858
  %864 = icmp eq ptr %839, null
  br i1 %864, label %869, label %865

865:                                              ; preds = %863
  %866 = load ptr, ptr %839, align 8, !tbaa !4
  %867 = getelementptr inbounds i8, ptr %866, i64 40
  %868 = load ptr, ptr %867, align 8
  call void %868(ptr noundef nonnull %839) #15
  br label %869

869:                                              ; preds = %865, %863
  %870 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %870, i64 noundef 4, i16 noundef zeroext %724) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 36, i32 noundef 65520) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 40, i32 noundef %692) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 44, i32 noundef %693) #15
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %631, i64 noundef 36, i32 noundef %691) #15
  br i1 %405, label %874, label %871

871:                                              ; preds = %869
  %872 = load ptr, ptr %10, align 8, !tbaa !78
  %873 = zext i32 %45 to i64
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %872, i64 noundef %873, i32 noundef %44) #15
  br label %874

874:                                              ; preds = %871, %869
  %875 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %875, i64 noundef 20, i32 noundef %157) #15
  %876 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %876, i64 noundef 24, i32 noundef %163) #15
  %877 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %877, i64 noundef 28, i32 noundef %159) #15
  %878 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %878, i64 noundef 32, i32 noundef %161) #15
  %879 = load ptr, ptr %10, align 8, !tbaa !78
  call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %879, i64 noundef 4, i16 noundef zeroext %722) #15
  br label %954

880:                                              ; preds = %845
  %881 = load ptr, ptr %830, align 8, !tbaa !4
  %882 = getelementptr inbounds i8, ptr %881, i64 440
  %883 = load ptr, ptr %882, align 8
  %884 = call zeroext i1 %883(ptr noundef nonnull %830, ptr noundef %838) #15
  %885 = load ptr, ptr %830, align 8, !tbaa !4
  %886 = getelementptr inbounds i8, ptr %885, i64 440
  %887 = load ptr, ptr %886, align 8
  %888 = call zeroext i1 %887(ptr noundef nonnull %830, ptr noundef nonnull %831) #15
  %889 = load ptr, ptr %830, align 8, !tbaa !4
  %890 = getelementptr inbounds i8, ptr %889, i64 440
  %891 = load ptr, ptr %890, align 8
  %892 = call zeroext i1 %891(ptr noundef nonnull %830, ptr noundef nonnull %832) #15
  br i1 %846, label %893, label %897

893:                                              ; preds = %880
  %894 = load ptr, ptr %839, align 8, !tbaa !4
  %895 = getelementptr inbounds i8, ptr %894, i64 40
  %896 = load ptr, ptr %895, align 8
  call void %896(ptr noundef nonnull %839) #15
  br label %897

897:                                              ; preds = %893, %880
  %898 = icmp eq i32 %828, 0
  br i1 %898, label %903, label %899

899:                                              ; preds = %897
  %900 = load ptr, ptr @_ZN18IOMemoryDescriptor9metaClassE, align 8
  %901 = and i32 %163, -16
  %902 = zext i32 %901 to i64
  br label %922

903:                                              ; preds = %951, %897
  %904 = load ptr, ptr %10, align 8, !tbaa !78
  %905 = load ptr, ptr %904, align 8, !tbaa !4
  %906 = getelementptr inbounds i8, ptr %905, i64 1776
  %907 = load ptr, ptr %906, align 8
  call void %907(ptr noundef nonnull %904, ptr noundef nonnull %830) #15
  %908 = load ptr, ptr %831, align 8, !tbaa !4
  %909 = getelementptr inbounds i8, ptr %908, i64 40
  %910 = load ptr, ptr %909, align 8
  call void %910(ptr noundef nonnull %831) #15
  %911 = load ptr, ptr %832, align 8, !tbaa !4
  %912 = getelementptr inbounds i8, ptr %911, i64 40
  %913 = load ptr, ptr %912, align 8
  call void %913(ptr noundef nonnull %832) #15
  %914 = load ptr, ptr %830, align 8, !tbaa !4
  %915 = getelementptr inbounds i8, ptr %914, i64 40
  %916 = load ptr, ptr %915, align 8
  call void %916(ptr noundef nonnull %830) #15
  %917 = load ptr, ptr %10, align 8, !tbaa !78
  %918 = load ptr, ptr %917, align 8, !tbaa !4
  %919 = getelementptr inbounds i8, ptr %918, i64 640
  %920 = load ptr, ptr %919, align 8
  %921 = call zeroext i1 %920(ptr noundef nonnull %917, ptr noundef nonnull @.str.150, i64 noundef %716, i32 noundef 64) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.151, i64 noundef %719, i64 noundef %716) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.151, i64 noundef %719, i64 noundef %716) #15
  br label %954

922:                                              ; preds = %899, %951
  %923 = phi i32 [ 0, %899 ], [ %952, %951 ]
  %924 = load ptr, ptr %180, align 8, !tbaa !4
  %925 = getelementptr inbounds i8, ptr %924, i64 488
  %926 = load ptr, ptr %925, align 8
  %927 = call ptr %926(ptr noundef nonnull %180, i32 noundef %923) #15
  %928 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %927, ptr noundef %900) #15
  %929 = icmp eq ptr %928, null
  %930 = icmp eq ptr %928, %404
  %931 = or i1 %929, %930
  br i1 %931, label %951, label %932

932:                                              ; preds = %922
  %933 = call i64 @_ZN18IOMemoryDescriptor18getPhysicalAddressEv(ptr noundef nonnull %928) #15
  %934 = icmp eq i64 %933, %175
  %935 = icmp eq i64 %933, %902
  %936 = select i1 %934, i1 true, i1 %935
  br i1 %936, label %937, label %946

937:                                              ; preds = %932
  %938 = load ptr, ptr %928, align 8, !tbaa !4
  %939 = getelementptr inbounds i8, ptr %938, i64 456
  %940 = load ptr, ptr %939, align 8
  %941 = call i64 %940(ptr noundef nonnull %928) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.149, i64 noundef %933, i64 noundef %941) #15
  %942 = load ptr, ptr %928, align 8, !tbaa !4
  %943 = getelementptr inbounds i8, ptr %942, i64 456
  %944 = load ptr, ptr %943, align 8
  %945 = call i64 %944(ptr noundef nonnull %928) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.149, i64 noundef %933, i64 noundef %945) #15
  br label %951

946:                                              ; preds = %932
  %947 = load ptr, ptr %830, align 8, !tbaa !4
  %948 = getelementptr inbounds i8, ptr %947, i64 440
  %949 = load ptr, ptr %948, align 8
  %950 = call zeroext i1 %949(ptr noundef nonnull %830, ptr noundef nonnull %928) #15
  br label %951

951:                                              ; preds = %937, %946, %922
  %952 = add nuw i32 %923, 1
  %953 = icmp eq i32 %952, %828
  br i1 %953, label %903, label %922, !llvm.loop !111

954:                                              ; preds = %602, %637, %701, %813, %903, %874, %689, %682, %616, %664, %708, %741, %303, %83, %148, %412, %169, %28
  %955 = phi i1 [ false, %28 ], [ false, %83 ], [ false, %148 ], [ false, %169 ], [ true, %303 ], [ false, %412 ], [ false, %602 ], [ false, %616 ], [ false, %637 ], [ false, %664 ], [ false, %682 ], [ false, %689 ], [ false, %701 ], [ false, %741 ], [ false, %813 ], [ true, %903 ], [ false, %874 ], [ false, %708 ]
  ret i1 %955
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM8readBARsEv(ptr noundef %0) local_unnamed_addr #1 align 2 {
  %2 = alloca [256 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 256, ptr nonnull %2) #18
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(256) %2, i8 0, i64 256, i1 false), !annotation !77
  %3 = getelementptr inbounds i8, ptr %0, i64 328
  %4 = load ptr, ptr %3, align 8, !tbaa !78
  %5 = load ptr, ptr %4, align 8, !tbaa !4
  %6 = getelementptr inbounds i8, ptr %5, i64 1744
  %7 = load ptr, ptr %6, align 8
  %8 = tail call i32 %7(ptr noundef nonnull %4) #15
  %9 = getelementptr inbounds i8, ptr %0, i64 480
  %10 = getelementptr inbounds i8, ptr %0, i64 496
  store i32 0, ptr %10, align 8, !tbaa !112
  store i64 0, ptr %9, align 8, !tbaa !113
  %11 = getelementptr inbounds i8, ptr %0, i64 488
  store i64 0, ptr %11, align 8, !tbaa !114
  %12 = getelementptr inbounds i8, ptr %0, i64 520
  %13 = getelementptr inbounds i8, ptr %0, i64 536
  store i32 0, ptr %13, align 8, !tbaa !112
  store i64 0, ptr %12, align 8, !tbaa !113
  %14 = getelementptr inbounds i8, ptr %0, i64 528
  store i64 0, ptr %14, align 8, !tbaa !114
  %15 = getelementptr inbounds i8, ptr %0, i64 560
  %16 = getelementptr inbounds i8, ptr %0, i64 576
  store i32 0, ptr %16, align 8, !tbaa !112
  store i64 0, ptr %15, align 8, !tbaa !113
  %17 = getelementptr inbounds i8, ptr %0, i64 568
  store i64 0, ptr %17, align 8, !tbaa !114
  %18 = icmp eq i32 %8, 0
  br i1 %18, label %103, label %22

19:                                               ; preds = %96
  %20 = load i64, ptr %14, align 8, !tbaa !114
  %21 = icmp eq i64 %20, 0
  br i1 %21, label %103, label %104

22:                                               ; preds = %1, %96
  %23 = phi i32 [ %98, %96 ], [ 0, %1 ]
  %24 = phi i32 [ %97, %96 ], [ 0, %1 ]
  %25 = phi i32 [ %99, %96 ], [ 0, %1 ]
  %26 = load ptr, ptr %3, align 8, !tbaa !78
  %27 = load ptr, ptr %26, align 8, !tbaa !4
  %28 = getelementptr inbounds i8, ptr %27, i64 1752
  %29 = load ptr, ptr %28, align 8
  %30 = call ptr %29(ptr noundef nonnull %26, i32 noundef %25) #15
  %31 = icmp eq ptr %30, null
  br i1 %31, label %96, label %32

32:                                               ; preds = %22
  %33 = call i64 @_ZN18IOMemoryDescriptor18getPhysicalAddressEv(ptr noundef nonnull %30) #15
  %34 = load ptr, ptr %30, align 8, !tbaa !4
  %35 = getelementptr inbounds i8, ptr %34, i64 456
  %36 = load ptr, ptr %35, align 8
  %37 = call i64 %36(ptr noundef nonnull %30) #15
  %38 = and i64 %33, -16
  br label %39

39:                                               ; preds = %32, %68
  %40 = phi i32 [ 0, %32 ], [ %70, %68 ]
  %41 = load ptr, ptr %3, align 8, !tbaa !78
  %42 = shl nuw nsw i32 %40, 2
  %43 = add nuw nsw i32 %42, 16
  %44 = zext nneg i32 %43 to i64
  %45 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %41, i64 noundef %44) #15
  %46 = and i32 %45, 1
  %47 = icmp eq i32 %46, 0
  br i1 %47, label %48, label %68

48:                                               ; preds = %39
  %49 = and i32 %45, 6
  %50 = icmp eq i32 %49, 4
  %51 = and i32 %45, -16
  %52 = zext i32 %51 to i64
  %53 = icmp ne i32 %40, 5
  %54 = and i1 %53, %50
  br i1 %54, label %55, label %63

55:                                               ; preds = %48
  %56 = load ptr, ptr %3, align 8, !tbaa !78
  %57 = add nuw nsw i32 %42, 20
  %58 = zext nneg i32 %57 to i64
  %59 = call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %56, i64 noundef %58) #15
  %60 = zext i32 %59 to i64
  %61 = shl nuw i64 %60, 32
  %62 = or disjoint i64 %61, %52
  br label %63

63:                                               ; preds = %55, %48
  %64 = phi i64 [ %62, %55 ], [ %52, %48 ]
  %65 = icmp eq i64 %64, %38
  %66 = zext i1 %50 to i32
  %67 = add nuw nsw i32 %40, %66
  br i1 %65, label %72, label %68

68:                                               ; preds = %63, %39
  %69 = phi i32 [ %40, %39 ], [ %67, %63 ]
  %70 = add nuw nsw i32 %69, 1
  %71 = icmp ult i32 %69, 5
  br i1 %71, label %39, label %75, !llvm.loop !115

72:                                               ; preds = %63
  %73 = and i32 %43, 252
  %74 = icmp eq i64 %37, 0
  br i1 %74, label %75, label %77

75:                                               ; preds = %68, %72
  %76 = phi ptr [ @.str.192, %72 ], [ @.str.191, %68 ]
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.190, i32 noundef %25, i64 noundef %33, i64 noundef %37, ptr noundef nonnull %76) #15
  br label %96

77:                                               ; preds = %72
  %78 = trunc nuw nsw i32 %43 to i8
  switch i8 %78, label %96 [
    i8 16, label %81
    i8 20, label %79
    i8 28, label %80
  ]

79:                                               ; preds = %77
  br label %81

80:                                               ; preds = %77
  br label %81

81:                                               ; preds = %77, %80, %79
  %82 = phi i32 [ 1, %79 ], [ 0, %77 ], [ 2, %80 ]
  %83 = zext nneg i32 %82 to i64
  %84 = getelementptr inbounds [3 x %struct.nv_aperture_t], ptr %9, i64 0, i64 %83
  %85 = getelementptr inbounds i8, ptr %84, i64 8
  %86 = load i64, ptr %85, align 8, !tbaa !114
  %87 = icmp eq i64 %86, 0
  br i1 %87, label %88, label %96

88:                                               ; preds = %81
  %89 = add nuw nsw i32 %24, 1
  %90 = getelementptr inbounds i8, ptr %84, i64 16
  store i32 %73, ptr %90, align 8, !tbaa !112
  store i64 %33, ptr %84, align 8, !tbaa !113
  store i64 %37, ptr %85, align 8, !tbaa !114
  %91 = zext i32 %23 to i64
  %92 = getelementptr inbounds i8, ptr %2, i64 %91
  %93 = sub nsw i64 256, %91
  %94 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %92, i64 noundef %93, ptr noundef nonnull @.str.193, i32 noundef %82, i32 noundef %73, i64 noundef %33, i64 noundef %37) #15
  %95 = add i32 %94, %23
  br label %96

96:                                               ; preds = %77, %75, %88, %81, %22
  %97 = phi i32 [ %24, %22 ], [ %24, %75 ], [ %89, %88 ], [ %24, %81 ], [ %24, %77 ]
  %98 = phi i32 [ %23, %22 ], [ %23, %75 ], [ %95, %88 ], [ %23, %81 ], [ %23, %77 ]
  %99 = add nuw i32 %25, 1
  %100 = icmp ult i32 %99, %8
  %101 = icmp ult i32 %97, 3
  %102 = select i1 %100, i1 %101, i1 false
  br i1 %102, label %22, label %19, !llvm.loop !116

103:                                              ; preds = %1, %19
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.194) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.194) #15
  br label %104

104:                                              ; preds = %103, %19
  %105 = load ptr, ptr %0, align 8, !tbaa !4
  %106 = getelementptr inbounds i8, ptr %105, i64 624
  %107 = load ptr, ptr %106, align 8
  %108 = call zeroext i1 %107(ptr noundef nonnull %0, ptr noundef nonnull @.str.195, ptr noundef nonnull %2) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.196, ptr noundef nonnull %2) #15
  call void @llvm.lifetime.end.p0(i64 256, ptr nonnull %2) #18
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @thread_call_allocate(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM11bootHoldCapEPvS0_(ptr noundef %0, ptr nocapture readnone %1) #1 align 2 {
  %3 = getelementptr inbounds i8, ptr %0, i64 180
  %4 = tail call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef 0, ptr noundef nonnull %3) #15
  br i1 %4, label %5, label %13

5:                                                ; preds = %2
  %6 = load ptr, ptr %0, align 8, !tbaa !4
  %7 = getelementptr inbounds i8, ptr %6, i64 1584
  %8 = load ptr, ptr %7, align 8
  tail call void %8(ptr noundef nonnull %0, i32 noundef -1) #15
  %9 = load ptr, ptr %0, align 8, !tbaa !4
  %10 = getelementptr inbounds i8, ptr %9, i64 624
  %11 = load ptr, ptr %10, align 8
  %12 = tail call zeroext i1 %11(ptr noundef nonnull %0, ptr noundef nonnull @.str.33, ptr noundef nonnull @.str.76) #15
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.77) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.77) #15
  br label %13

13:                                               ; preds = %5, %2
  %14 = load ptr, ptr %0, align 8, !tbaa !4
  %15 = getelementptr inbounds i8, ptr %14, i64 40
  %16 = load ptr, ptr %15, align 8
  tail call void %16(ptr noundef nonnull %0) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @clock_interval_to_deadline(i32 noundef, i32 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @clock_interval_to_absolutetime_interval(i32 noundef, i32 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @thread_call_enter_delayed(ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM15releaseBootHoldEPKc(ptr noundef %0, ptr noundef %1) local_unnamed_addr #1 align 2 {
  %3 = getelementptr inbounds i8, ptr %0, i64 180
  %4 = tail call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef 0, ptr noundef nonnull %3) #15
  br i1 %4, label %7, label %5

5:                                                ; preds = %2
  %6 = tail call zeroext i1 @OSCompareAndSwap(i32 noundef 2, i32 noundef 0, ptr noundef nonnull %3) #15
  br i1 %6, label %7, label %15

7:                                                ; preds = %5, %2
  %8 = load ptr, ptr %0, align 8, !tbaa !4
  %9 = getelementptr inbounds i8, ptr %8, i64 1584
  %10 = load ptr, ptr %9, align 8
  tail call void %10(ptr noundef nonnull %0, i32 noundef -1) #15
  %11 = load ptr, ptr %0, align 8, !tbaa !4
  %12 = getelementptr inbounds i8, ptr %11, i64 624
  %13 = load ptr, ptr %12, align 8
  %14 = tail call zeroext i1 %13(ptr noundef nonnull %0, ptr noundef nonnull @.str.33, ptr noundef %1) #15
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.75, ptr noundef %1) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.75, ptr noundef %1) #15
  br label %15

15:                                               ; preds = %5, %7
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @kernel_thread_start(ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM6autoGoEPvi(ptr noundef %0, i32 %1) #1 align 2 {
  %3 = alloca i64, align 8
  %4 = alloca i32, align 4
  %5 = alloca i64, align 8
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  %8 = alloca i64, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i64, align 8
  %13 = alloca i32, align 4
  %14 = alloca i64, align 8
  %15 = alloca [8 x i8], align 8
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  %21 = alloca i32, align 4
  %22 = alloca i32, align 4
  %23 = alloca [160 x i8], align 16
  %24 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %15) #18
  store i64 0, ptr %15, align 8
  %25 = getelementptr inbounds i8, ptr %0, i64 172
  %26 = load i32, ptr %25, align 4, !tbaa !61
  %27 = icmp ugt i32 %26, 5000
  br i1 %27, label %28, label %44

28:                                               ; preds = %2
  %29 = udiv i32 %26, 1000
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.78, i32 noundef %29) #15
  %30 = load i32, ptr %25, align 4, !tbaa !61
  %31 = udiv i32 %30, 1000
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.78, i32 noundef %31) #15
  %32 = load i32, ptr %25, align 4, !tbaa !61
  %33 = icmp eq i32 %32, 0
  br i1 %33, label %45, label %34

34:                                               ; preds = %28
  %35 = tail call i32 @llvm.umin.i32(i32 %32, i32 15000)
  tail call void @IOSleep(i32 noundef %35) #15
  %36 = sub i32 %32, %35
  %37 = icmp eq i32 %36, 0
  br i1 %37, label %45, label %38

38:                                               ; preds = %34, %38
  %39 = phi i32 [ %42, %38 ], [ %36, %34 ]
  %40 = udiv i32 %39, 1000
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.79, i32 noundef %40) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.79, i32 noundef %40) #15
  %41 = tail call i32 @llvm.umin.i32(i32 %39, i32 15000)
  tail call void @IOSleep(i32 noundef %41) #15
  %42 = sub i32 %39, %41
  %43 = icmp eq i32 %42, 0
  br i1 %43, label %45, label %38

44:                                               ; preds = %2
  tail call void @IOSleep(i32 noundef %26) #15
  br label %45

45:                                               ; preds = %38, %34, %28, %44
  tail call void @_ZN4NVRM17measureBootRasterEv(ptr noundef %0) #17
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %16) #18
  store ptr null, ptr %16, align 8, !tbaa !10
  %46 = load ptr, ptr %0, align 8, !tbaa !4
  %47 = getelementptr inbounds i8, ptr %46, i64 32
  %48 = load ptr, ptr %47, align 8
  tail call void %48(ptr noundef nonnull %0) #15
  %49 = call i32 @kernel_thread_start(ptr noundef nonnull @_ZN4NVRM9headWatchEPvi, ptr noundef nonnull %0, ptr noundef nonnull %16) #15
  %50 = icmp eq i32 %49, 0
  br i1 %50, label %51, label %53

51:                                               ; preds = %45
  %52 = load ptr, ptr %16, align 8, !tbaa !10
  call void @thread_deallocate(ptr noundef %52) #15
  br label %57

53:                                               ; preds = %45
  %54 = load ptr, ptr %0, align 8, !tbaa !4
  %55 = getelementptr inbounds i8, ptr %54, i64 40
  %56 = load ptr, ptr %55, align 8
  call void %56(ptr noundef nonnull %0) #15
  br label %57

57:                                               ; preds = %53, %51
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %16) #18
  %58 = call i32 @_ZN4NVRM2goEj(ptr noundef nonnull %0, i32 noundef 2) #17
  %59 = getelementptr inbounds i8, ptr %0, i64 1268
  %60 = load i32, ptr %59, align 4, !tbaa !117
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.80, i32 noundef %58, i32 noundef %60) #15
  %61 = icmp eq i32 %58, 0
  br i1 %61, label %81, label %62

62:                                               ; preds = %57
  %63 = icmp eq i32 %58, -536870187
  %64 = select i1 %63, ptr @.str.81, ptr @.str.82
  %65 = load ptr, ptr %0, align 8, !tbaa !4
  %66 = getelementptr inbounds i8, ptr %65, i64 624
  %67 = load ptr, ptr %66, align 8
  %68 = call zeroext i1 %67(ptr noundef nonnull %0, ptr noundef nonnull @.str.30, ptr noundef nonnull %64) #15
  %69 = getelementptr inbounds i8, ptr %0, i64 180
  %70 = call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef 0, ptr noundef nonnull %69) #15
  br i1 %70, label %73, label %71

71:                                               ; preds = %62
  %72 = call zeroext i1 @OSCompareAndSwap(i32 noundef 2, i32 noundef 0, ptr noundef nonnull %69) #15
  br i1 %72, label %73, label %360

73:                                               ; preds = %71, %62
  %74 = load ptr, ptr %0, align 8, !tbaa !4
  %75 = getelementptr inbounds i8, ptr %74, i64 1584
  %76 = load ptr, ptr %75, align 8
  call void %76(ptr noundef nonnull %0, i32 noundef -1) #15
  %77 = load ptr, ptr %0, align 8, !tbaa !4
  %78 = getelementptr inbounds i8, ptr %77, i64 624
  %79 = load ptr, ptr %78, align 8
  %80 = call zeroext i1 %79(ptr noundef nonnull %0, ptr noundef nonnull @.str.33, ptr noundef nonnull @.str.82) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.75, ptr noundef nonnull @.str.82) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.75, ptr noundef nonnull @.str.82) #15
  br label %360

81:                                               ; preds = %57
  %82 = load ptr, ptr %0, align 8, !tbaa !4
  %83 = getelementptr inbounds i8, ptr %82, i64 624
  %84 = load ptr, ptr %83, align 8
  %85 = call zeroext i1 %84(ptr noundef nonnull %0, ptr noundef nonnull @.str.30, ptr noundef nonnull @.str.83) #15
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %17) #18
  store i32 1, ptr %17, align 4, !tbaa !18
  %86 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.84, ptr noundef nonnull %17, i32 noundef 4) #15
  %87 = icmp eq i32 %86, 0
  %88 = load i32, ptr %17, align 4
  %89 = icmp slt i32 %88, 1
  %90 = select i1 %87, i1 true, i1 %89
  br i1 %90, label %91, label %92

91:                                               ; preds = %81
  store i32 1, ptr %17, align 4, !tbaa !18
  br label %92

92:                                               ; preds = %81, %91
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %18) #18
  %93 = load ptr, ptr @_ZN8OSNumber9metaClassE, align 8
  br label %94

94:                                               ; preds = %92, %156
  %95 = phi i32 [ -1, %92 ], [ %112, %156 ]
  %96 = phi i32 [ 0, %92 ], [ %121, %156 ]
  %97 = phi i32 [ 0, %92 ], [ %157, %156 ]
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %14) #18
  store i64 4, ptr %14, align 8, !tbaa !97
  store i32 -99, ptr %18, align 4, !tbaa !18
  %98 = call i32 @sysctlbyname(ptr noundef nonnull @.str.85, ptr noundef nonnull %18, ptr noundef nonnull %14, ptr noundef null, i64 noundef 0) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %14) #18
  %99 = icmp eq i32 %98, 0
  br i1 %99, label %101, label %100

100:                                              ; preds = %94
  store i32 0, ptr %18, align 4, !tbaa !18
  br label %111

101:                                              ; preds = %94
  %102 = load i32, ptr %18, align 4, !tbaa !18
  %103 = icmp eq i32 %102, 0
  br i1 %103, label %111, label %104

104:                                              ; preds = %101, %104
  %105 = phi i32 [ %107, %104 ], [ 0, %101 ]
  %106 = phi i32 [ %109, %104 ], [ %102, %101 ]
  %107 = add i32 %105, 1
  %108 = add i32 %106, -1
  %109 = and i32 %108, %106
  %110 = icmp eq i32 %109, 0
  br i1 %110, label %111, label %104, !llvm.loop !118

111:                                              ; preds = %104, %100, %101
  %112 = phi i32 [ 0, %101 ], [ 0, %100 ], [ %102, %104 ]
  %113 = phi i32 [ 0, %101 ], [ 0, %100 ], [ %107, %104 ]
  %114 = load i32, ptr %17, align 4, !tbaa !18
  %115 = icmp slt i32 %113, %114
  br i1 %115, label %116, label %159

116:                                              ; preds = %111
  %117 = icmp ne i32 %112, 0
  %118 = icmp eq i32 %112, %95
  %119 = and i1 %117, %118
  %120 = add nsw i32 %96, 1
  %121 = select i1 %119, i32 %120, i32 0
  %122 = icmp sgt i32 %121, 2
  br i1 %122, label %159, label %123

123:                                              ; preds = %116
  %124 = load ptr, ptr @_ZL12gDisplayNub0, align 8, !tbaa !10
  %125 = icmp eq ptr %124, null
  br i1 %125, label %156, label %126

126:                                              ; preds = %123
  %127 = load ptr, ptr %124, align 8, !tbaa !4
  %128 = getelementptr inbounds i8, ptr %127, i64 696
  %129 = load ptr, ptr %128, align 8
  %130 = call ptr %129(ptr noundef nonnull %124, ptr noundef nonnull @.str.86) #15
  %131 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %130, ptr noundef %93) #15
  %132 = icmp eq ptr %131, null
  br i1 %132, label %156, label %133

133:                                              ; preds = %126
  %134 = load ptr, ptr %131, align 8, !tbaa !4
  %135 = getelementptr inbounds i8, ptr %134, i64 328
  %136 = load ptr, ptr %135, align 8
  %137 = call i32 %136(ptr noundef nonnull %131) #15
  %138 = icmp eq i32 %137, 0
  br i1 %138, label %156, label %139

139:                                              ; preds = %133
  %140 = load i32, ptr %18, align 4, !tbaa !18
  %141 = icmp eq i32 %140, 0
  br i1 %141, label %149, label %142

142:                                              ; preds = %139, %142
  %143 = phi i32 [ %145, %142 ], [ 0, %139 ]
  %144 = phi i32 [ %147, %142 ], [ %140, %139 ]
  %145 = add i32 %143, 1
  %146 = add i32 %144, -1
  %147 = and i32 %146, %144
  %148 = icmp eq i32 %147, 0
  br i1 %148, label %149, label %142, !llvm.loop !118

149:                                              ; preds = %142, %139
  %150 = phi i32 [ 0, %139 ], [ %145, %142 ]
  %151 = load ptr, ptr %131, align 8, !tbaa !4
  %152 = getelementptr inbounds i8, ptr %151, i64 328
  %153 = load ptr, ptr %152, align 8
  %154 = call i32 %153(ptr noundef nonnull %131) #15
  %155 = icmp slt i32 %150, %154
  br i1 %155, label %156, label %159

156:                                              ; preds = %149, %133, %126, %123
  call void @IOSleep(i32 noundef 1000) #15
  %157 = add nuw nsw i32 %97, 1
  %158 = icmp eq i32 %157, 20
  br i1 %158, label %159, label %94, !llvm.loop !119

159:                                              ; preds = %149, %156, %111, %116
  %160 = phi i32 [ %97, %149 ], [ 20, %156 ], [ %97, %111 ], [ %97, %116 ]
  %161 = load i32, ptr %18, align 4, !tbaa !18
  %162 = icmp eq i32 %161, 0
  br i1 %162, label %170, label %163

163:                                              ; preds = %159, %163
  %164 = phi i32 [ %166, %163 ], [ 0, %159 ]
  %165 = phi i32 [ %168, %163 ], [ %161, %159 ]
  %166 = add i32 %164, 1
  %167 = add i32 %165, -1
  %168 = and i32 %167, %165
  %169 = icmp eq i32 %168, 0
  br i1 %169, label %170, label %163, !llvm.loop !118

170:                                              ; preds = %163, %159
  %171 = phi i32 [ 0, %159 ], [ %166, %163 ]
  %172 = load i32, ptr %17, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.87, i32 noundef %161, i32 noundef %171, i32 noundef %172, i32 noundef %160) #15
  %173 = load i32, ptr %18, align 4, !tbaa !18
  %174 = icmp eq i32 %173, 0
  br i1 %174, label %182, label %175

175:                                              ; preds = %170, %175
  %176 = phi i32 [ %178, %175 ], [ 0, %170 ]
  %177 = phi i32 [ %180, %175 ], [ %173, %170 ]
  %178 = add i32 %176, 1
  %179 = add i32 %177, -1
  %180 = and i32 %179, %177
  %181 = icmp eq i32 %180, 0
  br i1 %181, label %182, label %175, !llvm.loop !118

182:                                              ; preds = %175, %170
  %183 = phi i32 [ 0, %170 ], [ %178, %175 ]
  %184 = load i32, ptr %17, align 4, !tbaa !18
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.87, i32 noundef %173, i32 noundef %183, i32 noundef %184, i32 noundef %160) #15
  %185 = getelementptr inbounds i8, ptr %0, i64 180
  %186 = call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef 2, ptr noundef nonnull %185) #15
  br i1 %186, label %199, label %187

187:                                              ; preds = %182
  %188 = load i32, ptr %18, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.88, i32 noundef %188) #15
  %189 = load i32, ptr %18, align 4, !tbaa !18
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.88, i32 noundef %189) #15
  %190 = load ptr, ptr %0, align 8, !tbaa !4
  %191 = getelementptr inbounds i8, ptr %190, i64 624
  %192 = load ptr, ptr %191, align 8
  %193 = call zeroext i1 %192(ptr noundef nonnull %0, ptr noundef nonnull @.str.89, ptr noundef nonnull @.str.90) #15
  %194 = load ptr, ptr %0, align 8, !tbaa !4
  %195 = getelementptr inbounds i8, ptr %194, i64 40
  %196 = load ptr, ptr %195, align 8
  call void %196(ptr noundef nonnull %0) #15
  %197 = tail call ptr @current_thread() #16
  %198 = call i32 @thread_terminate(ptr noundef %197) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %18) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %17) #18
  br label %366

199:                                              ; preds = %182
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %19) #18
  store i32 0, ptr %19, align 4, !tbaa !18
  br label %200

200:                                              ; preds = %199, %206
  %201 = phi i32 [ 0, %199 ], [ %207, %206 ]
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %13)
  store i32 1, ptr %13, align 4, !tbaa !18
  %202 = call i32 @sysctlbyname(ptr noundef nonnull @.str.91, ptr noundef null, ptr noundef null, ptr noundef nonnull %13, i64 noundef 4) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %13)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %12) #18
  store i64 4, ptr %12, align 8, !tbaa !97
  store i32 -99, ptr %19, align 4, !tbaa !18
  %203 = call i32 @sysctlbyname(ptr noundef nonnull @.str.91, ptr noundef nonnull %19, ptr noundef nonnull %12, ptr noundef null, i64 noundef 0) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %12) #18
  %204 = load i32, ptr %19, align 4, !tbaa !18
  %205 = icmp eq i32 %204, 1
  br i1 %205, label %212, label %206

206:                                              ; preds = %200
  call void @IOSleep(i32 noundef 1000) #15
  %207 = add i32 %201, 1
  %208 = icmp eq i32 %207, 10
  br i1 %208, label %209, label %200, !llvm.loop !120

209:                                              ; preds = %206
  %210 = load i32, ptr %19, align 4, !tbaa !18
  %211 = icmp eq i32 %210, 1
  br i1 %211, label %212, label %223

212:                                              ; preds = %200, %209
  %213 = phi i32 [ 10, %209 ], [ %201, %200 ]
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %11)
  store i32 4, ptr %11, align 4, !tbaa !18
  %214 = call i32 @sysctlbyname(ptr noundef nonnull @.str.91, ptr noundef null, ptr noundef null, ptr noundef nonnull %11, i64 noundef 4) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %11)
  %215 = load i32, ptr %19, align 4, !tbaa !18
  %216 = freeze i32 %215
  %217 = icmp eq i32 %216, 1
  %218 = select i1 %217, ptr @.str.93, ptr @.str.94
  %219 = add nuw nsw i32 %213, 1
  %220 = icmp eq i32 %213, 0
  %221 = select i1 %220, ptr @.str.96, ptr @.str.95
  %222 = select i1 %217, ptr @.str.97, ptr @.str.98
  br label %223

223:                                              ; preds = %212, %209
  %224 = phi ptr [ @.str.95, %209 ], [ %221, %212 ]
  %225 = phi ptr [ @.str.94, %209 ], [ %218, %212 ]
  %226 = phi i32 [ 11, %209 ], [ %219, %212 ]
  %227 = phi ptr [ @.str.98, %209 ], [ %222, %212 ]
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.92, ptr noundef nonnull %225, i32 noundef %226, ptr noundef nonnull %224, ptr noundef nonnull %227) #15
  %228 = load i32, ptr %19, align 4, !tbaa !18
  %229 = icmp eq i32 %228, 1
  %230 = select i1 %229, ptr @.str.93, ptr @.str.94
  %231 = select i1 %229, ptr @.str.97, ptr @.str.98
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.92, ptr noundef nonnull %230, i32 noundef %226, ptr noundef nonnull %224, ptr noundef nonnull %231) #15
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %20) #18
  store i32 -99, ptr %20, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %21) #18
  store i32 -99, ptr %21, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %22) #18
  store i32 -99, ptr %22, align 4, !tbaa !18
  %232 = load i32, ptr %19, align 4, !tbaa !18
  %233 = icmp eq i32 %232, 1
  br i1 %233, label %234, label %257

234:                                              ; preds = %223
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %10)
  store i32 1, ptr %10, align 4, !tbaa !18
  %235 = call i32 @sysctlbyname(ptr noundef nonnull @.str.99, ptr noundef null, ptr noundef null, ptr noundef nonnull %10, i64 noundef 4) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %10)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %9)
  store i32 1, ptr %9, align 4, !tbaa !18
  %236 = call i32 @sysctlbyname(ptr noundef nonnull @.str.100, ptr noundef null, ptr noundef null, ptr noundef nonnull %9, i64 noundef 4) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %9)
  br label %237

237:                                              ; preds = %234, %244
  %238 = phi i32 [ 0, %234 ], [ %245, %244 ]
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #18
  store i64 4, ptr %8, align 8, !tbaa !97
  store i32 -99, ptr %21, align 4, !tbaa !18
  %239 = call i32 @sysctlbyname(ptr noundef nonnull @.str.100, ptr noundef nonnull %21, ptr noundef nonnull %8, ptr noundef null, i64 noundef 0) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #18
  %240 = load i32, ptr %21, align 4
  %241 = icmp eq i32 %240, 1
  %242 = icmp slt i32 %240, 0
  %243 = or i1 %241, %242
  br i1 %243, label %247, label %244

244:                                              ; preds = %237
  call void @IOSleep(i32 noundef 200) #15
  %245 = add nuw nsw i32 %238, 1
  %246 = icmp eq i32 %245, 25
  br i1 %246, label %247, label %237, !llvm.loop !121

247:                                              ; preds = %237, %244
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7)
  store i32 1, ptr %7, align 4, !tbaa !18
  %248 = call i32 @sysctlbyname(ptr noundef nonnull @.str.101, ptr noundef null, ptr noundef null, ptr noundef nonnull %7, i64 noundef 4) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #18
  store i64 4, ptr %6, align 8, !tbaa !97
  store i32 -99, ptr %20, align 4, !tbaa !18
  %249 = call i32 @sysctlbyname(ptr noundef nonnull @.str.99, ptr noundef nonnull %20, ptr noundef nonnull %6, ptr noundef null, i64 noundef 0) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #18
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 4, ptr %5, align 8, !tbaa !97
  store i32 -99, ptr %22, align 4, !tbaa !18
  %250 = call i32 @sysctlbyname(ptr noundef nonnull @.str.101, ptr noundef nonnull %22, ptr noundef nonnull %5, ptr noundef null, i64 noundef 0) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  %251 = load i32, ptr %19, align 4, !tbaa !18
  %252 = load i32, ptr %21, align 4, !tbaa !18
  %253 = load i32, ptr %20, align 4, !tbaa !18
  %254 = load i32, ptr %22, align 4, !tbaa !18
  %255 = icmp eq i32 %251, 1
  %256 = select i1 %255, i32 4, i32 0
  br label %257

257:                                              ; preds = %247, %223
  %258 = phi i32 [ %254, %247 ], [ -99, %223 ]
  %259 = phi i32 [ %253, %247 ], [ -99, %223 ]
  %260 = phi i32 [ %252, %247 ], [ -99, %223 ]
  %261 = phi i32 [ %256, %247 ], [ 0, %223 ]
  call void @llvm.lifetime.start.p0(i64 160, ptr nonnull %23) #18
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(160) %23, i8 0, i64 160, i1 false), !annotation !77
  %262 = load i32, ptr %18, align 4, !tbaa !18
  %263 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %23, i64 noundef 160, ptr noundef nonnull @.str.102, i32 noundef %262, i32 noundef %261, i32 noundef %260, i32 noundef %259, i32 noundef %258) #15
  %264 = load ptr, ptr %0, align 8, !tbaa !4
  %265 = getelementptr inbounds i8, ptr %264, i64 624
  %266 = load ptr, ptr %265, align 8
  %267 = call zeroext i1 %266(ptr noundef nonnull %0, ptr noundef nonnull @.str.89, ptr noundef nonnull %23) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.103, ptr noundef nonnull %23) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.103, ptr noundef nonnull %23) #15
  %268 = load i32, ptr %19, align 4, !tbaa !18
  %269 = icmp eq i32 %268, 1
  %270 = load i32, ptr %21, align 4
  %271 = icmp eq i32 %270, 1
  %272 = select i1 %269, i1 %271, i1 false
  %273 = load i32, ptr %22, align 4
  %274 = icmp eq i32 %273, 1
  %275 = select i1 %272, i1 %274, i1 false
  %276 = select i1 %275, ptr @.str.104, ptr @.str.105
  %277 = call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef 0, ptr noundef nonnull %185) #15
  br i1 %277, label %280, label %278

278:                                              ; preds = %257
  %279 = call zeroext i1 @OSCompareAndSwap(i32 noundef 2, i32 noundef 0, ptr noundef nonnull %185) #15
  br i1 %279, label %280, label %288

280:                                              ; preds = %278, %257
  %281 = load ptr, ptr %0, align 8, !tbaa !4
  %282 = getelementptr inbounds i8, ptr %281, i64 1584
  %283 = load ptr, ptr %282, align 8
  call void %283(ptr noundef nonnull %0, i32 noundef -1) #15
  %284 = load ptr, ptr %0, align 8, !tbaa !4
  %285 = getelementptr inbounds i8, ptr %284, i64 624
  %286 = load ptr, ptr %285, align 8
  %287 = call zeroext i1 %286(ptr noundef nonnull %0, ptr noundef nonnull @.str.33, ptr noundef nonnull %276) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.75, ptr noundef nonnull %276) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.75, ptr noundef nonnull %276) #15
  br label %288

288:                                              ; preds = %278, %280
  %289 = load i32, ptr %19, align 4, !tbaa !18
  %290 = icmp eq i32 %289, 1
  %291 = load i32, ptr %22, align 4
  %292 = icmp eq i32 %291, 1
  %293 = select i1 %290, i1 %292, i1 false
  br i1 %293, label %294, label %348

294:                                              ; preds = %288
  %295 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.106, ptr noundef nonnull %15, i32 noundef 8) #15
  %296 = icmp eq i32 %295, 0
  br i1 %296, label %297, label %348

297:                                              ; preds = %294
  call void @IOSleep(i32 noundef 60000) #15
  %298 = getelementptr inbounds i8, ptr %0, i64 176
  %299 = load i8, ptr %298, align 8, !tbaa !62, !range !14, !noundef !15
  %300 = trunc nuw i8 %299 to i1
  br i1 %300, label %301, label %349

301:                                              ; preds = %297
  %302 = call ptr @_ZN9IOService15serviceMatchingEPKcP12OSDictionary(ptr noundef nonnull @.str.108, ptr noundef null) #15
  %303 = call ptr @_ZN9IOService19getMatchingServicesEP12OSDictionary(ptr noundef %302) #15
  %304 = icmp eq ptr %303, null
  br i1 %304, label %336, label %305

305:                                              ; preds = %301
  %306 = load ptr, ptr %303, align 8, !tbaa !4
  %307 = getelementptr inbounds i8, ptr %306, i64 296
  %308 = load ptr, ptr %307, align 8
  %309 = call ptr %308(ptr noundef nonnull %303) #15
  %310 = icmp eq ptr %309, null
  br i1 %310, label %328, label %311

311:                                              ; preds = %305, %322
  %312 = phi ptr [ %326, %322 ], [ %309, %305 ]
  %313 = load ptr, ptr %312, align 8, !tbaa !4
  %314 = getelementptr inbounds i8, ptr %313, i64 56
  %315 = load ptr, ptr %314, align 8
  %316 = call ptr %315(ptr noundef nonnull %312) #15
  %317 = call ptr @_ZNK11OSMetaClass12getClassNameEv(ptr noundef %316) #15
  %318 = icmp eq ptr %317, null
  br i1 %318, label %322, label %319

319:                                              ; preds = %311
  %320 = call i32 @strncmp(ptr noundef nonnull %317, ptr noundef nonnull @.str.109, i64 noundef 2) #15
  %321 = icmp eq i32 %320, 0
  br i1 %321, label %322, label %332

322:                                              ; preds = %319, %311
  %323 = load ptr, ptr %303, align 8, !tbaa !4
  %324 = getelementptr inbounds i8, ptr %323, i64 296
  %325 = load ptr, ptr %324, align 8
  %326 = call ptr %325(ptr noundef nonnull %303) #15
  %327 = icmp eq ptr %326, null
  br i1 %327, label %328, label %311

328:                                              ; preds = %322, %305
  %329 = load ptr, ptr %303, align 8, !tbaa !4
  %330 = getelementptr inbounds i8, ptr %329, i64 40
  %331 = load ptr, ptr %330, align 8
  call void %331(ptr noundef nonnull %303) #15
  br label %336

332:                                              ; preds = %319
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.111, ptr noundef nonnull %317) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.111, ptr noundef nonnull %317) #15
  %333 = load ptr, ptr %303, align 8, !tbaa !4
  %334 = getelementptr inbounds i8, ptr %333, i64 40
  %335 = load ptr, ptr %334, align 8
  call void %335(ptr noundef nonnull %303) #15
  br label %349

336:                                              ; preds = %328, %301
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %24) #18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4)
  store i32 1, ptr %4, align 4, !tbaa !18
  %337 = call i32 @sysctlbyname(ptr noundef nonnull @.str.115, ptr noundef null, ptr noundef null, ptr noundef nonnull %4, i64 noundef 4) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #18
  store i64 4, ptr %3, align 8, !tbaa !97
  store i32 -99, ptr %24, align 4, !tbaa !18
  %338 = call i32 @sysctlbyname(ptr noundef nonnull @.str.115, ptr noundef nonnull %24, ptr noundef nonnull %3, ptr noundef null, i64 noundef 0) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #18
  %339 = load i32, ptr %24, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.116, i32 noundef %339) #15
  %340 = load i32, ptr %24, align 4, !tbaa !18
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.116, i32 noundef %340) #15
  %341 = load i32, ptr %24, align 4, !tbaa !18
  %342 = icmp eq i32 %341, 1
  %343 = select i1 %342, ptr @.str.117, ptr @.str.118
  %344 = load ptr, ptr %0, align 8, !tbaa !4
  %345 = getelementptr inbounds i8, ptr %344, i64 624
  %346 = load ptr, ptr %345, align 8
  %347 = call zeroext i1 %346(ptr noundef nonnull %0, ptr noundef nonnull @.str.113, ptr noundef nonnull %343) #15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %24) #18
  br label %348

348:                                              ; preds = %336, %294, %288
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %23) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %22) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %21) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %20) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %19) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %18) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %17) #18
  br label %360

349:                                              ; preds = %332, %297
  %350 = phi ptr [ @.str.110, %332 ], [ @.str.107, %297 ]
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.112, ptr noundef nonnull %350) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.112, ptr noundef nonnull %350) #15
  %351 = load ptr, ptr %0, align 8, !tbaa !4
  %352 = getelementptr inbounds i8, ptr %351, i64 624
  %353 = load ptr, ptr %352, align 8
  %354 = call zeroext i1 %353(ptr noundef nonnull %0, ptr noundef nonnull @.str.113, ptr noundef nonnull @.str.114) #15
  %355 = load ptr, ptr %0, align 8, !tbaa !4
  %356 = getelementptr inbounds i8, ptr %355, i64 40
  %357 = load ptr, ptr %356, align 8
  call void %357(ptr noundef nonnull %0) #15
  %358 = tail call ptr @current_thread() #16
  %359 = call i32 @thread_terminate(ptr noundef %358) #15
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %23) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %22) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %21) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %20) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %19) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %18) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %17) #18
  br label %366

360:                                              ; preds = %73, %71, %348
  %361 = load ptr, ptr %0, align 8, !tbaa !4
  %362 = getelementptr inbounds i8, ptr %361, i64 40
  %363 = load ptr, ptr %362, align 8
  call void %363(ptr noundef nonnull %0) #15
  %364 = tail call ptr @current_thread() #16
  %365 = call i32 @thread_terminate(ptr noundef %364) #15
  br label %366

366:                                              ; preds = %349, %187, %360
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %15) #18
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @thread_deallocate(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService18changePowerStateToEm(ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService11getPlatformEv() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN18IOMemoryDescriptor16withAddressRangeEyyjP4task(i64 noundef, i64 noundef, i32 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN24IOBufferMemoryDescriptor17inTaskWithOptionsEP4taskjmm(ptr noundef, i32 noundef, i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i64 @mach_absolute_time() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @absolutetime_to_nanoseconds(i64 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 2) i32 @nvrm_xnu_smooth_takeover(ptr noundef writeonly %0, ptr noundef writeonly %1, ptr noundef writeonly %2, ptr noundef writeonly %3) local_unnamed_addr #1 {
  %5 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 0, ptr %5, align 8
  %6 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.55, ptr noundef nonnull %5, i32 noundef 8) #15
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %9, label %8

8:                                                ; preds = %4
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.56) #15
  br label %24

9:                                                ; preds = %4
  %10 = load i32, ptr @_ZL11gSmoothHead, align 4, !tbaa !18
  %11 = icmp sgt i32 %10, -1
  %12 = icmp ne ptr %0, null
  %13 = and i1 %12, %11
  %14 = icmp ne ptr %1, null
  %15 = and i1 %14, %13
  %16 = icmp ne ptr %2, null
  %17 = and i1 %16, %15
  %18 = icmp ne ptr %3, null
  %19 = and i1 %18, %17
  br i1 %19, label %20, label %24

20:                                               ; preds = %9
  store i32 %10, ptr %0, align 4, !tbaa !18
  %21 = load i32, ptr @_ZL11gSmoothPclk, align 4, !tbaa !18
  store i32 %21, ptr %1, align 4, !tbaa !18
  %22 = load i32, ptr @_ZL9gSmoothHt, align 4, !tbaa !18
  store i32 %22, ptr %2, align 4, !tbaa !18
  %23 = load i32, ptr @_ZL9gSmoothVt, align 4, !tbaa !18
  store i32 %23, ptr %3, align 4, !tbaa !18
  br label %24

24:                                               ; preds = %9, %20, %8
  %25 = phi i32 [ 0, %8 ], [ 1, %20 ], [ 0, %9 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  ret i32 %25
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM17measureBootRasterEv(ptr noundef %0) local_unnamed_addr #1 align 2 {
  %2 = alloca [256 x i8], align 16
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = getelementptr inbounds i8, ptr %0, i64 488
  %6 = load i64, ptr %5, align 8, !tbaa !114
  %7 = icmp ult i64 %6, 7340032
  br i1 %7, label %8, label %10

8:                                                ; preds = %1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.57, i64 noundef %6) #15
  %9 = load i64, ptr %5, align 8, !tbaa !114
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.57, i64 noundef %9) #15
  br label %174

10:                                               ; preds = %1
  %11 = getelementptr inbounds i8, ptr %0, i64 480
  %12 = load i64, ptr %11, align 8, !tbaa !113
  %13 = tail call ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef %12, i64 noundef 7340032, i32 noundef 1) #15
  %14 = icmp eq ptr %13, null
  br i1 %14, label %173, label %15

15:                                               ; preds = %10
  %16 = load ptr, ptr %13, align 8, !tbaa !4
  %17 = getelementptr inbounds i8, ptr %16, i64 512
  %18 = load ptr, ptr %17, align 8
  %19 = tail call ptr %18(ptr noundef nonnull %13, i32 noundef 256) #15
  %20 = icmp eq ptr %19, null
  br i1 %20, label %21, label %25

21:                                               ; preds = %15
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.58) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.58) #15
  %22 = load ptr, ptr %13, align 8, !tbaa !4
  %23 = getelementptr inbounds i8, ptr %22, i64 40
  %24 = load ptr, ptr %23, align 8
  tail call void %24(ptr noundef nonnull %13) #15
  br label %174

25:                                               ; preds = %15
  %26 = load ptr, ptr %19, align 8, !tbaa !4
  %27 = getelementptr inbounds i8, ptr %26, i64 280
  %28 = load ptr, ptr %27, align 8
  %29 = tail call i64 %28(ptr noundef nonnull %19) #15
  %30 = inttoptr i64 %29 to ptr
  call void @llvm.lifetime.start.p0(i64 256, ptr nonnull %2) #18
  %31 = getelementptr inbounds i8, ptr %30, i64 6856804
  %32 = getelementptr inbounds i8, ptr %30, i64 6856716
  %33 = getelementptr inbounds i8, ptr %30, i64 6382384
  %34 = getelementptr inbounds i8, ptr %0, i64 136
  %35 = getelementptr inbounds i8, ptr %0, i64 140
  %36 = getelementptr inbounds i8, ptr %0, i64 144
  %37 = getelementptr inbounds i8, ptr %0, i64 148
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(256) %2, i8 0, i64 256, i1 false)
  br label %51

38:                                               ; preds = %169
  %39 = icmp eq i32 %170, 0
  %40 = select i1 %39, ptr @.str.67, ptr %2
  %41 = load ptr, ptr %0, align 8, !tbaa !4
  %42 = getelementptr inbounds i8, ptr %41, i64 624
  %43 = load ptr, ptr %42, align 8
  %44 = call zeroext i1 %43(ptr noundef nonnull %0, ptr noundef nonnull @.str.66, ptr noundef nonnull %40) #15
  %45 = load ptr, ptr %19, align 8, !tbaa !4
  %46 = getelementptr inbounds i8, ptr %45, i64 40
  %47 = load ptr, ptr %46, align 8
  call void %47(ptr noundef nonnull %19) #15
  %48 = load ptr, ptr %13, align 8, !tbaa !4
  %49 = getelementptr inbounds i8, ptr %48, i64 40
  %50 = load ptr, ptr %49, align 8
  call void %50(ptr noundef nonnull %13) #15
  call void @llvm.lifetime.end.p0(i64 256, ptr nonnull %2) #18
  br label %174

51:                                               ; preds = %25, %169
  %52 = phi i64 [ 0, %25 ], [ %171, %169 ]
  %53 = phi i32 [ 0, %25 ], [ %170, %169 ]
  %54 = shl nuw nsw i64 %52, 10
  %55 = getelementptr inbounds i8, ptr %31, i64 %54
  %56 = load volatile i32, ptr %55, align 4, !tbaa !18
  %57 = getelementptr inbounds i8, ptr %32, i64 %54
  %58 = load volatile i32, ptr %57, align 4, !tbaa !18
  %59 = shl nuw nsw i64 %52, 11
  %60 = getelementptr inbounds i8, ptr %33, i64 %59
  %61 = load volatile i32, ptr %60, align 4, !tbaa !18
  %62 = load volatile i32, ptr %60, align 4, !tbaa !18
  %63 = call i64 @mach_absolute_time() #15
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #18
  store i64 0, ptr %3, align 8, !tbaa !7
  %64 = and i32 %62, -65536
  %65 = icmp eq i32 %64, -1159790592
  br i1 %65, label %68, label %66

66:                                               ; preds = %51
  %67 = and i32 %61, 65535
  br label %70

68:                                               ; preds = %51
  %69 = trunc nuw nsw i64 %52 to i32
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.59, i32 noundef %69, i32 noundef %62) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.59, i32 noundef %69, i32 noundef %62) #15
  br label %169

70:                                               ; preds = %66, %92
  %71 = phi i32 [ %81, %92 ], [ 0, %66 ]
  %72 = phi i64 [ %93, %92 ], [ 0, %66 ]
  %73 = phi i64 [ %94, %92 ], [ 0, %66 ]
  %74 = phi i32 [ %95, %92 ], [ 0, %66 ]
  %75 = phi i32 [ %96, %92 ], [ %67, %66 ]
  %76 = phi i32 [ %78, %92 ], [ %67, %66 ]
  %77 = load volatile i32, ptr %60, align 4, !tbaa !18
  %78 = and i32 %77, 65535
  %79 = icmp ne i32 %78, %76
  %80 = zext i1 %79 to i32
  %81 = add i32 %71, %80
  %82 = add nuw nsw i32 %78, 64
  %83 = icmp ult i32 %82, %76
  br i1 %83, label %84, label %92

84:                                               ; preds = %70
  %85 = add i32 %74, 1
  %86 = icmp eq i64 %72, 0
  br i1 %86, label %87, label %89

87:                                               ; preds = %84
  %88 = call i64 @mach_absolute_time() #15
  br label %89

89:                                               ; preds = %87, %84
  %90 = phi i64 [ %72, %84 ], [ %88, %87 ]
  %91 = call i64 @mach_absolute_time() #15
  br label %92

92:                                               ; preds = %89, %70
  %93 = phi i64 [ %90, %89 ], [ %72, %70 ]
  %94 = phi i64 [ %91, %89 ], [ %73, %70 ]
  %95 = phi i32 [ %85, %89 ], [ %74, %70 ]
  %96 = call i32 @llvm.umax.i32(i32 %78, i32 %75)
  %97 = call i64 @mach_absolute_time() #15
  %98 = sub i64 %97, %63
  call void @absolutetime_to_nanoseconds(i64 noundef %98, ptr noundef nonnull %3) #15
  %99 = load i64, ptr %3, align 8, !tbaa !7
  %100 = icmp ult i64 %99, 250000000
  br i1 %100, label %70, label %101, !llvm.loop !122

101:                                              ; preds = %92
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #18
  store i64 0, ptr %4, align 8, !tbaa !7
  %102 = icmp ugt i32 %95, 1
  br i1 %102, label %103, label %113

103:                                              ; preds = %101
  %104 = sub i64 %94, %93
  call void @absolutetime_to_nanoseconds(i64 noundef %104, ptr noundef nonnull %4) #15
  %105 = load i64, ptr %4, align 8
  %106 = icmp eq i64 %105, 0
  br i1 %106, label %113, label %107

107:                                              ; preds = %103
  %108 = add i32 %95, -1
  %109 = zext i32 %108 to i64
  %110 = mul i64 %109, 1000000000000
  %111 = udiv i64 %110, %105
  %112 = trunc i64 %111 to i32
  br label %113

113:                                              ; preds = %101, %103, %107
  %114 = phi i32 [ %112, %107 ], [ 0, %103 ], [ 0, %101 ]
  %115 = lshr i32 %56, 16
  %116 = and i32 %56, 65535
  %117 = icmp ugt i32 %56, 65535
  %118 = icmp ne i32 %116, 0
  %119 = and i1 %117, %118
  %120 = icmp ne i32 %58, 0
  %121 = add i32 %58, -1
  %122 = icmp ult i32 %121, 1999999999
  %123 = select i1 %119, i1 %122, i1 false
  br i1 %123, label %124, label %131

124:                                              ; preds = %113
  %125 = zext nneg i32 %58 to i64
  %126 = mul nuw nsw i64 %125, 1000
  %127 = mul nuw i32 %115, %116
  %128 = zext i32 %127 to i64
  %129 = udiv i64 %126, %128
  %130 = trunc i64 %129 to i32
  br label %131

131:                                              ; preds = %113, %124
  %132 = phi i32 [ %130, %124 ], [ 0, %113 ]
  %133 = icmp ugt i32 %81, 100
  %134 = add i32 %114, -20000
  %135 = icmp ult i32 %134, 230001
  %136 = select i1 %133, i1 %135, i1 false
  %137 = udiv i32 %114, 1000
  %138 = urem i32 %114, 1000
  %139 = select i1 %136, ptr @.str.61, ptr @.str.62
  %140 = udiv i32 %132, 1000
  %141 = urem i32 %132, 1000
  %142 = trunc nuw nsw i64 %52 to i32
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.60, i32 noundef %142, i32 noundef %95, i32 noundef %81, i32 noundef %96, i32 noundef %137, i32 noundef %138, ptr noundef nonnull %139, i32 noundef %116, i32 noundef %115, i32 noundef %58, i32 noundef %140, i32 noundef %141) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.60, i32 noundef %142, i32 noundef %95, i32 noundef %81, i32 noundef %96, i32 noundef %137, i32 noundef %138, ptr noundef nonnull %139, i32 noundef %116, i32 noundef %115, i32 noundef %58, i32 noundef %140, i32 noundef %141) #15
  br i1 %136, label %143, label %167

143:                                              ; preds = %131
  %144 = load i32, ptr %34, align 8, !tbaa !43
  %145 = icmp slt i32 %144, 0
  %146 = and i1 %118, %145
  %147 = and i1 %117, %146
  %148 = select i1 %147, i1 %120, i1 false
  br i1 %148, label %149, label %150

149:                                              ; preds = %143
  store i32 %142, ptr %34, align 8, !tbaa !43
  store i32 %58, ptr %35, align 4, !tbaa !54
  store i32 %116, ptr %36, align 8, !tbaa !55
  store i32 %115, ptr %37, align 4, !tbaa !56
  br label %150

150:                                              ; preds = %149, %143
  %151 = load i32, ptr @_ZL11gSmoothHead, align 4
  %152 = icmp slt i32 %151, 0
  %153 = and i1 %118, %152
  %154 = and i1 %117, %153
  %155 = select i1 %154, i1 %120, i1 false
  br i1 %155, label %156, label %157

156:                                              ; preds = %150
  store i32 %142, ptr @_ZL11gSmoothHead, align 4, !tbaa !18
  store i32 %58, ptr @_ZL11gSmoothPclk, align 4, !tbaa !18
  store i32 %116, ptr @_ZL9gSmoothHt, align 4, !tbaa !18
  store i32 %115, ptr @_ZL9gSmoothVt, align 4, !tbaa !18
  br label %157

157:                                              ; preds = %156, %150
  %158 = icmp slt i32 %53, 216
  br i1 %158, label %159, label %167

159:                                              ; preds = %157
  %160 = sext i32 %53 to i64
  %161 = getelementptr inbounds i8, ptr %2, i64 %160
  %162 = sub nsw i64 256, %160
  %163 = icmp eq i32 %53, 0
  %164 = select i1 %163, ptr @.str.65, ptr @.str.64
  %165 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %161, i64 noundef %162, ptr noundef nonnull @.str.63, ptr noundef nonnull %164, i32 noundef %142, i32 noundef %137, i32 noundef %138) #15
  %166 = add nsw i32 %165, %53
  br label %167

167:                                              ; preds = %131, %159, %157
  %168 = phi i32 [ %166, %159 ], [ %53, %157 ], [ %53, %131 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  br label %169

169:                                              ; preds = %167, %68
  %170 = phi i32 [ %53, %68 ], [ %168, %167 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #18
  %171 = add nuw nsw i64 %52, 1
  %172 = icmp eq i64 %171, 4
  br i1 %172, label %38, label %51, !llvm.loop !123

173:                                              ; preds = %10
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.58) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.58) #15
  br label %174

174:                                              ; preds = %173, %38, %21, %8
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef, i64 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @snprintf(ptr noundef, i64 noundef, ptr noundef, ...) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM9headWatchEPvi(ptr noundef %0, i32 %1) #1 align 2 {
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  %8 = getelementptr inbounds i8, ptr %0, i64 488
  %9 = load i64, ptr %8, align 8, !tbaa !114
  %10 = icmp ugt i64 %9, 7340031
  br i1 %10, label %11, label %163

11:                                               ; preds = %2
  %12 = getelementptr inbounds i8, ptr %0, i64 480
  %13 = load i64, ptr %12, align 8, !tbaa !113
  %14 = tail call ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef %13, i64 noundef 7340032, i32 noundef 1) #15
  %15 = icmp eq ptr %14, null
  br i1 %15, label %163, label %16

16:                                               ; preds = %11
  %17 = load ptr, ptr %14, align 8, !tbaa !4
  %18 = getelementptr inbounds i8, ptr %17, i64 512
  %19 = load ptr, ptr %18, align 8
  %20 = tail call ptr %19(ptr noundef nonnull %14, i32 noundef 256) #15
  %21 = icmp eq ptr %20, null
  br i1 %21, label %159, label %22

22:                                               ; preds = %16
  %23 = load ptr, ptr %20, align 8, !tbaa !4
  %24 = getelementptr inbounds i8, ptr %23, i64 280
  %25 = load ptr, ptr %24, align 8
  %26 = tail call i64 %25(ptr noundef nonnull %20) #15
  %27 = inttoptr i64 %26 to ptr
  %28 = getelementptr inbounds i8, ptr %27, i64 6856704
  %29 = getelementptr inbounds i8, ptr %27, i64 6852608
  br label %37

30:                                               ; preds = %37
  %31 = load i32, ptr @_ZZN4NVRM9headWatchEPviE4armH, align 16, !tbaa !18
  %32 = load i32, ptr getelementptr inbounds (i8, ptr @_ZZN4NVRM9headWatchEPviE4armH, i64 100), align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.68, i32 noundef %31, i32 noundef %32) #15
  %33 = tail call i64 @mach_absolute_time() #15
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #18
  store i64 0, ptr %3, align 8, !tbaa !7
  %34 = getelementptr inbounds i8, ptr %27, i64 6382384
  %35 = getelementptr inbounds i8, ptr %0, i64 180
  %36 = getelementptr inbounds i8, ptr %27, i64 6384432
  br label %56

37:                                               ; preds = %37, %22
  %38 = phi i64 [ 0, %22 ], [ %54, %37 ]
  %39 = shl nuw nsw i64 %38, 2
  %40 = getelementptr inbounds i8, ptr %28, i64 %39
  %41 = load volatile i32, ptr %40, align 4, !tbaa !18
  %42 = getelementptr inbounds [256 x i32], ptr @_ZZN4NVRM9headWatchEPviE4armH, i64 0, i64 %38
  store i32 %41, ptr %42, align 8, !tbaa !18
  %43 = getelementptr inbounds i8, ptr %29, i64 %39
  %44 = load volatile i32, ptr %43, align 4, !tbaa !18
  %45 = getelementptr inbounds [256 x i32], ptr @_ZZN4NVRM9headWatchEPviE4armW, i64 0, i64 %38
  store i32 %44, ptr %45, align 8, !tbaa !18
  %46 = or disjoint i64 %38, 1
  %47 = shl nuw nsw i64 %46, 2
  %48 = getelementptr inbounds i8, ptr %28, i64 %47
  %49 = load volatile i32, ptr %48, align 4, !tbaa !18
  %50 = getelementptr inbounds [256 x i32], ptr @_ZZN4NVRM9headWatchEPviE4armH, i64 0, i64 %46
  store i32 %49, ptr %50, align 4, !tbaa !18
  %51 = getelementptr inbounds i8, ptr %29, i64 %47
  %52 = load volatile i32, ptr %51, align 4, !tbaa !18
  %53 = getelementptr inbounds [256 x i32], ptr @_ZZN4NVRM9headWatchEPviE4armW, i64 0, i64 %46
  store i32 %52, ptr %53, align 4, !tbaa !18
  %54 = add nuw nsw i64 %38, 2
  %55 = icmp eq i64 %54, 256
  br i1 %55, label %30, label %37, !llvm.loop !124

56:                                               ; preds = %154, %30
  %57 = phi i32 [ -1, %30 ], [ %81, %154 ]
  %58 = phi i32 [ -1, %30 ], [ %67, %154 ]
  %59 = phi i64 [ 0, %30 ], [ %69, %154 ]
  %60 = phi i64 [ 0, %30 ], [ %83, %154 ]
  %61 = phi i32 [ -1, %30 ], [ %94, %154 ]
  %62 = phi i32 [ -1, %30 ], [ %80, %154 ]
  %63 = phi i64 [ 0, %30 ], [ %148, %154 ]
  %64 = phi i32 [ 0, %30 ], [ %97, %154 ]
  %65 = call i64 @mach_absolute_time() #15
  %66 = sub i64 %65, %33
  call void @absolutetime_to_nanoseconds(i64 noundef %66, ptr noundef nonnull %3) #15
  %67 = load volatile i32, ptr %34, align 4, !tbaa !18
  %68 = icmp eq i32 %67, %58
  %69 = select i1 %68, i64 %59, i64 %65
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #18
  store i64 0, ptr %4, align 8, !tbaa !7
  %70 = sub i64 %65, %69
  call void @absolutetime_to_nanoseconds(i64 noundef %70, ptr noundef nonnull %4) #15
  %71 = load i64, ptr %4, align 8, !tbaa !7
  %72 = icmp ult i64 %71, 20000000
  %73 = zext i1 %72 to i32
  %74 = icmp eq i32 %62, %73
  br i1 %74, label %79, label %75

75:                                               ; preds = %56
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 0, ptr %5, align 8, !tbaa !7
  call void @absolutetime_to_nanoseconds(i64 noundef %65, ptr noundef nonnull %5) #15
  %76 = select i1 %72, ptr @.str.70, ptr @.str.71
  %77 = load i64, ptr %5, align 8, !tbaa !7
  %78 = udiv i64 %77, 1000000
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.69, i32 noundef 0, ptr noundef nonnull %76, i64 noundef %78, i32 noundef %67) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  br label %79

79:                                               ; preds = %75, %56
  %80 = phi i32 [ %62, %56 ], [ %73, %75 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  %81 = load volatile i32, ptr %36, align 4, !tbaa !18
  %82 = icmp eq i32 %81, %57
  %83 = select i1 %82, i64 %60, i64 %65
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #18
  store i64 0, ptr %4, align 8, !tbaa !7
  %84 = sub i64 %65, %83
  call void @absolutetime_to_nanoseconds(i64 noundef %84, ptr noundef nonnull %4) #15
  %85 = load i64, ptr %4, align 8, !tbaa !7
  %86 = icmp ult i64 %85, 20000000
  %87 = zext i1 %86 to i32
  %88 = icmp eq i32 %61, %87
  br i1 %88, label %93, label %89

89:                                               ; preds = %79
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 0, ptr %5, align 8, !tbaa !7
  call void @absolutetime_to_nanoseconds(i64 noundef %65, ptr noundef nonnull %5) #15
  %90 = select i1 %86, ptr @.str.70, ptr @.str.71
  %91 = load i64, ptr %5, align 8, !tbaa !7
  %92 = udiv i64 %91, 1000000
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.69, i32 noundef 1, ptr noundef nonnull %90, i64 noundef %92, i32 noundef %81) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  br label %93

93:                                               ; preds = %89, %79
  %94 = phi i32 [ %61, %79 ], [ %87, %89 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  %95 = icmp ult i32 %64, 400
  br i1 %95, label %100, label %96

96:                                               ; preds = %130, %93
  %97 = phi i32 [ %64, %93 ], [ %131, %130 ]
  %98 = icmp eq i64 %63, 0
  br i1 %98, label %136, label %99

99:                                               ; preds = %96
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #18
  store i64 0, ptr %7, align 8, !tbaa !7
  br label %141

100:                                              ; preds = %93, %130
  %101 = phi i64 [ %132, %130 ], [ 0, %93 ]
  %102 = phi i32 [ %131, %130 ], [ %64, %93 ]
  %103 = shl nuw nsw i64 %101, 2
  %104 = getelementptr inbounds i8, ptr %28, i64 %103
  %105 = load volatile i32, ptr %104, align 4, !tbaa !18
  %106 = getelementptr inbounds i8, ptr %29, i64 %103
  %107 = load volatile i32, ptr %106, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #18
  store i64 0, ptr %6, align 8, !tbaa !7
  %108 = getelementptr inbounds [256 x i32], ptr @_ZZN4NVRM9headWatchEPviE4armH, i64 0, i64 %101
  %109 = load i32, ptr %108, align 4, !tbaa !18
  %110 = icmp eq i32 %105, %109
  br i1 %110, label %118, label %111

111:                                              ; preds = %100
  call void @absolutetime_to_nanoseconds(i64 noundef %65, ptr noundef nonnull %6) #15
  %112 = load i64, ptr %6, align 8, !tbaa !7
  %113 = udiv i64 %112, 1000000
  %114 = load i32, ptr %108, align 4, !tbaa !18
  %115 = trunc i64 %103 to i32
  %116 = or i32 %115, 8192
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.72, i64 noundef %113, i32 noundef %116, i32 noundef %114, i32 noundef %105) #15
  store i32 %105, ptr %108, align 4, !tbaa !18
  %117 = add nuw nsw i32 %102, 1
  br label %118

118:                                              ; preds = %111, %100
  %119 = phi i32 [ %117, %111 ], [ %102, %100 ]
  %120 = getelementptr inbounds [256 x i32], ptr @_ZZN4NVRM9headWatchEPviE4armW, i64 0, i64 %101
  %121 = load i32, ptr %120, align 4, !tbaa !18
  %122 = icmp eq i32 %107, %121
  br i1 %122, label %130, label %123

123:                                              ; preds = %118
  call void @absolutetime_to_nanoseconds(i64 noundef %65, ptr noundef nonnull %6) #15
  %124 = load i64, ptr %6, align 8, !tbaa !7
  %125 = udiv i64 %124, 1000000
  %126 = load i32, ptr %120, align 4, !tbaa !18
  %127 = trunc i64 %103 to i32
  %128 = or i32 %127, 4096
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.73, i64 noundef %125, i32 noundef %128, i32 noundef %126, i32 noundef %107) #15
  store i32 %107, ptr %120, align 4, !tbaa !18
  %129 = add nuw nsw i32 %119, 1
  br label %130

130:                                              ; preds = %123, %118
  %131 = phi i32 [ %129, %123 ], [ %119, %118 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #18
  %132 = add nuw nsw i64 %101, 1
  %133 = icmp ult i64 %101, 255
  %134 = icmp ult i32 %131, 400
  %135 = select i1 %133, i1 %134, i1 false
  br i1 %135, label %100, label %96, !llvm.loop !125

136:                                              ; preds = %96
  %137 = load volatile i32, ptr %35, align 4, !tbaa !63
  %138 = icmp ne i32 %137, 0
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #18
  store i64 0, ptr %7, align 8, !tbaa !7
  %139 = icmp eq i64 %65, 0
  %140 = or i1 %138, %139
  br i1 %140, label %145, label %141

141:                                              ; preds = %136, %99
  %142 = phi i64 [ %63, %99 ], [ %65, %136 ]
  %143 = sub i64 %65, %142
  call void @absolutetime_to_nanoseconds(i64 noundef %143, ptr noundef nonnull %7) #15
  %144 = load i64, ptr %7, align 8
  br label %145

145:                                              ; preds = %136, %141
  %146 = phi i64 [ %144, %141 ], [ 0, %136 ]
  %147 = phi i1 [ true, %141 ], [ false, %136 ]
  %148 = phi i64 [ %142, %141 ], [ 0, %136 ]
  %149 = icmp ugt i64 %146, 15000000000
  %150 = select i1 %147, i1 %149, i1 false
  %151 = load i64, ptr %3, align 8
  %152 = icmp ugt i64 %151, 90000000000
  %153 = select i1 %150, i1 true, i1 %152
  br i1 %153, label %155, label %154

154:                                              ; preds = %145
  call void @IOSleep(i32 noundef 5) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #18
  br label %56

155:                                              ; preds = %145
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #18
  %156 = load ptr, ptr %20, align 8, !tbaa !4
  %157 = getelementptr inbounds i8, ptr %156, i64 40
  %158 = load ptr, ptr %157, align 8
  call void %158(ptr noundef nonnull %20) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #18
  br label %159

159:                                              ; preds = %155, %16
  %160 = load ptr, ptr %14, align 8, !tbaa !4
  %161 = getelementptr inbounds i8, ptr %160, i64 40
  %162 = load ptr, ptr %161, align 8
  call void %162(ptr noundef nonnull %14) #15
  br label %163

163:                                              ; preds = %11, %2, %159
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.74) #15
  %164 = load ptr, ptr %0, align 8, !tbaa !4
  %165 = getelementptr inbounds i8, ptr %164, i64 40
  %166 = load ptr, ptr %165, align 8
  call void %166(ptr noundef nonnull %0) #15
  %167 = tail call ptr @current_thread() #16
  %168 = call i32 @thread_terminate(ptr noundef %167) #15
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #10

; Function Attrs: noimplicitfloat noredzone
declare void @IOSleep(i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @thread_terminate(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @OSCompareAndSwap(i32 noundef, i32 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870212, 1) i32 @_ZN4NVRM2goEj(ptr noundef %0, i32 noundef %1) local_unnamed_addr #1 align 2 {
  %3 = alloca [8 x i8], align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = getelementptr inbounds i8, ptr %0, i64 1268
  %9 = load i32, ptr %8, align 4, !tbaa !117
  %10 = icmp ult i32 %9, %1
  br i1 %10, label %11, label %16

11:                                               ; preds = %2
  %12 = tail call i32 @kauth_getuid() #15
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %16, label %14

14:                                               ; preds = %11
  %15 = load i32, ptr %8, align 4, !tbaa !117
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.197, i32 noundef %1, i32 noundef %15) #15
  br label %190

16:                                               ; preds = %11, %2
  %17 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockLock(ptr noundef %17) #15
  %18 = load i1, ptr @_ZZN4NVRM2goEjE7gGoBusy, align 1
  br i1 %18, label %19, label %21

19:                                               ; preds = %16
  %20 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %20) #15
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.198, i32 noundef %1) #15
  br label %190

21:                                               ; preds = %16
  store i1 true, ptr @_ZZN4NVRM2goEjE7gGoBusy, align 1
  %22 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %22) #15
  %23 = load i32, ptr %8, align 4, !tbaa !117
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.199, i32 noundef %1, i32 noundef %23) #15
  %24 = getelementptr inbounds i8, ptr %0, i64 336
  %25 = load i32, ptr %8, align 4, !tbaa !117
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.201, i32 noundef %1, i32 noundef %25) #15
  %26 = load i32, ptr %8, align 4, !tbaa !117
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.201, i32 noundef %1, i32 noundef %26) #15
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.202, i64 noundef ptrtoint (ptr @os_mem_set to i64)) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.202, i64 noundef ptrtoint (ptr @os_mem_set to i64)) #15
  %27 = icmp eq i32 %1, 0
  br i1 %27, label %186, label %28

28:                                               ; preds = %21
  %29 = load i32, ptr %8, align 4, !tbaa !117
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %31, label %68

31:                                               ; preds = %28
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #18
  store i64 0, ptr %3, align 8
  %32 = load i1, ptr @_ZL11gRmInitDone, align 1
  br i1 %32, label %53, label %33

33:                                               ; preds = %31
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.203) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.203) #15
  %34 = tail call zeroext i8 @rm_init_rm(ptr noundef null) #15
  %35 = icmp eq i8 %34, 0
  br i1 %35, label %36, label %37

36:                                               ; preds = %33
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.204) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.204) #15
  br label %66

37:                                               ; preds = %33
  store i1 true, ptr @_ZL11gRmInitDone, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.205) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.205) #15
  %38 = tail call ptr @nv_get_ctl_state() #15
  %39 = tail call zeroext i8 @rm_init_event_locks(ptr noundef null, ptr noundef %38) #15
  %40 = icmp eq i8 %39, 0
  br i1 %40, label %41, label %42

41:                                               ; preds = %37
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.206) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.206) #15
  br label %66

42:                                               ; preds = %37
  %43 = tail call zeroext i8 @rm_init_event_locks(ptr noundef null, ptr noundef nonnull %24) #15
  %44 = icmp eq i8 %43, 0
  br i1 %44, label %45, label %46

45:                                               ; preds = %42
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.207) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.207) #15
  br label %66

46:                                               ; preds = %42
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.208) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.208) #15
  %47 = tail call i32 @rm_write_registry_string(ptr noundef null, ptr noundef null, ptr noundef nonnull @.str.209, ptr noundef nonnull @.str.210, i32 noundef 1) #15
  %48 = tail call i32 @rm_write_registry_dword(ptr noundef null, ptr noundef null, ptr noundef nonnull @.str.211, i32 noundef 0) #15
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.212) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.212) #15
  %49 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.20, ptr noundef nonnull %3, i32 noundef 8) #15
  %50 = icmp eq i32 %49, 0
  br i1 %50, label %51, label %53

51:                                               ; preds = %46
  %52 = call i32 @rm_write_registry_dword(ptr noundef null, ptr noundef null, ptr noundef nonnull @.str.213, i32 noundef 1) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.214) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.214) #15
  br label %53

53:                                               ; preds = %46, %51, %31
  %54 = call i32 @rm_is_supported_device(ptr noundef null, ptr noundef nonnull %24) #15
  %55 = icmp eq i32 %54, 0
  br i1 %55, label %62, label %56

56:                                               ; preds = %53
  %57 = getelementptr inbounds i8, ptr %0, i64 366
  %58 = load i16, ptr %57, align 2, !tbaa !84
  %59 = zext i16 %58 to i32
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.215, i32 noundef %54, i32 noundef %59) #15
  %60 = load i16, ptr %57, align 2, !tbaa !84
  %61 = zext i16 %60 to i32
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.215, i32 noundef %54, i32 noundef %61) #15
  br label %66

62:                                               ; preds = %53
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.216) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.216) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.217) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.217) #15
  %63 = call zeroext i8 @rm_init_private_state(ptr noundef null, ptr noundef nonnull %24) #15
  %64 = icmp eq i8 %63, 0
  br i1 %64, label %65, label %72

65:                                               ; preds = %62
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.218) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.218) #15
  br label %66

66:                                               ; preds = %65, %56, %45, %41, %36
  %67 = phi i32 [ -536870212, %36 ], [ -536870212, %41 ], [ -536870212, %45 ], [ -536870201, %56 ], [ -536870212, %65 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #18
  br label %186

68:                                               ; preds = %28
  %69 = icmp ne i32 %1, 1
  %70 = icmp eq i32 %29, 1
  %71 = and i1 %69, %70
  br i1 %71, label %75, label %186

72:                                               ; preds = %62
  %73 = getelementptr inbounds i8, ptr %0, i64 1264
  store i8 1, ptr %73, align 8, !tbaa !75
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.219) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.219) #15
  call void @rm_set_rm_firmware_requested(ptr noundef null, ptr noundef nonnull %24) #15
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.220) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.220) #15
  store i32 1, ptr %8, align 4, !tbaa !117
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #18
  %74 = icmp eq i32 %1, 1
  br i1 %74, label %186, label %75

75:                                               ; preds = %68, %72
  %76 = getelementptr inbounds i8, ptr %0, i64 344
  store ptr %0, ptr %76, align 8, !tbaa !126
  %77 = getelementptr inbounds i8, ptr %0, i64 328
  %78 = load ptr, ptr %77, align 8, !tbaa !78
  %79 = load ptr, ptr %78, align 8, !tbaa !4
  %80 = getelementptr inbounds i8, ptr %79, i64 2248
  %81 = load ptr, ptr %80, align 8
  %82 = call zeroext i1 %81(ptr noundef nonnull %78, i1 noundef zeroext true) #15
  %83 = load ptr, ptr %77, align 8, !tbaa !78
  %84 = load ptr, ptr %83, align 8, !tbaa !4
  %85 = getelementptr inbounds i8, ptr %84, i64 2264
  %86 = load ptr, ptr %85, align 8
  %87 = call zeroext i1 %86(ptr noundef nonnull %83, i1 noundef zeroext true) #15
  %88 = load ptr, ptr %77, align 8, !tbaa !78
  %89 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %88, i64 noundef 4) #15
  %90 = zext i16 %89 to i32
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.221, i32 noundef %90) #15
  %91 = load ptr, ptr %77, align 8, !tbaa !78
  %92 = call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %91, i64 noundef 4) #15
  %93 = zext i16 %92 to i32
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.221, i32 noundef %93) #15
  br label %94

94:                                               ; preds = %75, %103
  %95 = phi i32 [ 0, %75 ], [ %118, %103 ]
  %96 = phi i32 [ -1, %75 ], [ %117, %103 ]
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #18
  store i32 0, ptr %4, align 4, !tbaa !18
  %97 = load ptr, ptr %77, align 8, !tbaa !78
  %98 = load ptr, ptr %97, align 8, !tbaa !4
  %99 = getelementptr inbounds i8, ptr %98, i64 1800
  %100 = load ptr, ptr %99, align 8
  %101 = call i32 %100(ptr noundef nonnull %97, i32 noundef %95, ptr noundef nonnull %4) #15
  %102 = icmp eq i32 %101, 0
  br i1 %102, label %103, label %120

103:                                              ; preds = %94
  %104 = load i32, ptr %4, align 4, !tbaa !18
  %105 = and i32 %104, 65536
  %106 = icmp eq i32 %105, 0
  %107 = select i1 %106, ptr @.str.65, ptr @.str.223
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.222, i32 noundef %95, i32 noundef %104, ptr noundef nonnull %107) #15
  %108 = load i32, ptr %4, align 4, !tbaa !18
  %109 = and i32 %108, 65536
  %110 = icmp eq i32 %109, 0
  %111 = select i1 %110, ptr @.str.65, ptr @.str.223
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.222, i32 noundef %95, i32 noundef %108, ptr noundef nonnull %111) #15
  %112 = icmp slt i32 %96, 0
  %113 = load i32, ptr %4, align 4
  %114 = and i32 %113, 65536
  %115 = icmp eq i32 %114, 0
  %116 = select i1 %115, i32 %96, i32 %95
  %117 = select i1 %112, i32 %116, i32 %96
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #18
  %118 = add nuw nsw i32 %95, 1
  %119 = icmp eq i32 %118, 8
  br i1 %119, label %121, label %94, !llvm.loop !127

120:                                              ; preds = %94
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #18
  br label %121

121:                                              ; preds = %103, %120
  %122 = phi i32 [ %96, %120 ], [ %117, %103 ]
  %123 = icmp slt i32 %122, 0
  br i1 %123, label %124, label %125

124:                                              ; preds = %121
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.224) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.224) #15
  br label %186

125:                                              ; preds = %121
  %126 = call ptr @_ZN10IOWorkLoop8workLoopEv() #15
  %127 = getelementptr inbounds i8, ptr %0, i64 1272
  store ptr %126, ptr %127, align 8, !tbaa !128
  %128 = load ptr, ptr %77, align 8, !tbaa !78
  %129 = call ptr @_ZN28IOFilterInterruptEventSource26filterInterruptEventSourceEP8OSObjectPFvS1_P22IOInterruptEventSourceiEPFbS1_PS_EP9IOServicei(ptr noundef nonnull %0, ptr noundef nonnull @_ZN4NVRM17interruptOccurredEP22IOInterruptEventSourcei, ptr noundef nonnull @_ZN4NVRM15interruptFilterEP28IOFilterInterruptEventSource, ptr noundef %128, i32 noundef %122) #15
  %130 = getelementptr inbounds i8, ptr %0, i64 1280
  store ptr %129, ptr %130, align 8, !tbaa !129
  %131 = load ptr, ptr %127, align 8, !tbaa !128
  %132 = icmp eq ptr %131, null
  %133 = icmp eq ptr %129, null
  %134 = select i1 %132, i1 true, i1 %133
  br i1 %134, label %141, label %135

135:                                              ; preds = %125
  %136 = load ptr, ptr %131, align 8, !tbaa !4
  %137 = getelementptr inbounds i8, ptr %136, i64 320
  %138 = load ptr, ptr %137, align 8
  %139 = call i32 %138(ptr noundef nonnull %131, ptr noundef nonnull %129) #15
  %140 = icmp eq i32 %139, 0
  br i1 %140, label %142, label %141

141:                                              ; preds = %125, %135
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.225) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.225) #15
  br label %186

142:                                              ; preds = %135
  %143 = load ptr, ptr %130, align 8, !tbaa !129
  %144 = load ptr, ptr %143, align 8, !tbaa !4
  %145 = getelementptr inbounds i8, ptr %144, i64 336
  %146 = load ptr, ptr %145, align 8
  call void %146(ptr noundef nonnull %143) #15
  %147 = getelementptr inbounds i8, ptr %0, i64 716
  store i32 %122, ptr %147, align 4, !tbaa !130
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.226, i32 noundef %122) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.226, i32 noundef %122) #15
  %148 = call zeroext i8 @rm_init_adapter(ptr noundef null, ptr noundef nonnull %24) #15
  %149 = icmp eq i8 %148, 0
  %150 = select i1 %149, ptr @.str.118, ptr @.str.228
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.227, ptr noundef nonnull %150) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.227, ptr noundef nonnull %150) #15
  call void @nv_xnu_dump_live_allocs() #15
  call fastcc void @_ZL20nv_xnu_dump_gsp_regsP10nv_state_t(ptr noundef nonnull %24) #17
  br i1 %149, label %186, label %151

151:                                              ; preds = %142
  %152 = getelementptr inbounds i8, ptr %0, i64 1265
  store i8 1, ptr %152, align 1, !tbaa !76
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.229) #15
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.229) #15
  store i32 2, ptr %8, align 4, !tbaa !117
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #18
  store i32 0, ptr %5, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #18
  store i32 0, ptr %6, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #18
  store i32 0, ptr %7, align 4, !tbaa !18
  %153 = getelementptr inbounds i8, ptr %0, i64 372
  %154 = load i32, ptr %153, align 4, !tbaa !131
  %155 = call zeroext i1 @nvrm_query_vram_kb(i32 noundef %154, ptr noundef nonnull %5, ptr noundef nonnull %6, ptr noundef nonnull %7) #15
  %156 = load i32, ptr %5, align 4
  %157 = icmp ne i32 %156, 0
  %158 = select i1 %155, i1 %157, i1 false
  br i1 %158, label %159, label %177

159:                                              ; preds = %151
  %160 = zext i32 %156 to i64
  %161 = shl nuw nsw i64 %160, 10
  %162 = load ptr, ptr %77, align 8, !tbaa !78
  %163 = load ptr, ptr %162, align 8, !tbaa !4
  %164 = getelementptr inbounds i8, ptr %163, i64 640
  %165 = load ptr, ptr %164, align 8
  %166 = call zeroext i1 %165(ptr noundef nonnull %162, ptr noundef nonnull @.str.167, i64 noundef %161, i32 noundef 64) #15
  %167 = load ptr, ptr %77, align 8, !tbaa !78
  %168 = lshr i64 %160, 10
  %169 = load ptr, ptr %167, align 8, !tbaa !4
  %170 = getelementptr inbounds i8, ptr %169, i64 640
  %171 = load ptr, ptr %170, align 8
  %172 = call zeroext i1 %171(ptr noundef nonnull %167, ptr noundef nonnull @.str.230, i64 noundef %168, i32 noundef 32) #15
  %173 = load i32, ptr %5, align 4, !tbaa !18
  %174 = load i32, ptr %6, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.231, i64 noundef %161, i32 noundef %173, i32 noundef %174) #15
  %175 = load i32, ptr %5, align 4, !tbaa !18
  %176 = load i32, ptr %6, align 4, !tbaa !18
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.231, i64 noundef %161, i32 noundef %175, i32 noundef %176) #15
  br label %181

177:                                              ; preds = %151
  %178 = load i32, ptr %7, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.232, i32 noundef %178, i32 noundef %156) #15
  %179 = load i32, ptr %7, align 4, !tbaa !18
  %180 = load i32, ptr %5, align 4, !tbaa !18
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.232, i32 noundef %179, i32 noundef %180) #15
  br label %181

181:                                              ; preds = %177, %159
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #18
  call void @_ZN4NVRM17publishGpuProfileEv(ptr noundef nonnull %0) #17
  %182 = call zeroext i8 @nvkms_xnu_load() #15
  %183 = icmp eq i8 %182, 0
  br i1 %183, label %186, label %184

184:                                              ; preds = %181
  %185 = load i32, ptr %153, align 4, !tbaa !132
  call fastcc void @_ZL20nvrm_display_publishP9IOServicej(ptr noundef nonnull %0, i32 noundef %185) #17
  br label %186

186:                                              ; preds = %72, %142, %141, %124, %21, %68, %184, %181, %66
  %187 = phi i32 [ %67, %66 ], [ 0, %181 ], [ 0, %184 ], [ 0, %68 ], [ 0, %21 ], [ -536870212, %142 ], [ -536870212, %141 ], [ -536870201, %124 ], [ 0, %72 ]
  %188 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  call void @IOLockLock(ptr noundef %188) #15
  store i1 false, ptr @_ZZN4NVRM2goEjE7gGoBusy, align 1
  %189 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  call void @IOLockUnlock(ptr noundef %189) #15
  br label %190

190:                                              ; preds = %19, %186, %14
  %191 = phi i32 [ -536870174, %14 ], [ -536870187, %19 ], [ %187, %186 ]
  ret i32 %191
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService19getMatchingServicesEP12OSDictionary(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService15serviceMatchingEPKcP12OSDictionary(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK11OSMetaClass12getClassNameEv(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i64 @_ZN18IOMemoryDescriptor18getPhysicalAddressEv(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define internal fastcc noundef zeroext i1 @_ZL27nvrmBusRangeHasOtherDeviceshhP11IOPCIDevice(i8 noundef zeroext %0, i8 noundef zeroext %1, ptr noundef readnone %2) unnamed_addr #1 {
  %4 = load ptr, ptr @gIOServicePlane, align 8, !tbaa !10
  %5 = tail call ptr @_ZN18IORegistryIterator11iterateOverEPK15IORegistryPlanej(ptr noundef %4, i32 noundef 1) #15
  %6 = icmp eq ptr %5, null
  br i1 %6, label %64, label %7

7:                                                ; preds = %3
  %8 = load ptr, ptr %5, align 8, !tbaa !4
  %9 = getelementptr inbounds i8, ptr %8, i64 296
  %10 = load ptr, ptr %9, align 8
  %11 = tail call ptr %10(ptr noundef nonnull %5) #15
  %12 = icmp eq ptr %11, null
  br i1 %12, label %59, label %13

13:                                               ; preds = %7
  %14 = load ptr, ptr @_ZN11IOPCIDevice9metaClassE, align 8, !tbaa !10
  br label %15

15:                                               ; preds = %13, %53
  %16 = phi ptr [ %11, %13 ], [ %57, %53 ]
  %17 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef nonnull %16, ptr noundef %14) #15
  %18 = icmp eq ptr %17, null
  %19 = icmp eq ptr %17, %2
  %20 = or i1 %18, %19
  br i1 %20, label %53, label %21, !llvm.loop !133

21:                                               ; preds = %15
  %22 = load ptr, ptr %17, align 8, !tbaa !4
  %23 = getelementptr inbounds i8, ptr %22, i64 2280
  %24 = load ptr, ptr %23, align 8
  %25 = tail call zeroext i8 %24(ptr noundef nonnull %17) #15
  %26 = icmp ult i8 %25, %0
  %27 = icmp ugt i8 %25, %1
  %28 = or i1 %26, %27
  br i1 %28, label %53, label %29

29:                                               ; preds = %21
  %30 = zext i8 %0 to i32
  %31 = zext i8 %25 to i32
  %32 = zext i8 %1 to i32
  %33 = load ptr, ptr %17, align 8, !tbaa !4
  %34 = getelementptr inbounds i8, ptr %33, i64 2288
  %35 = load ptr, ptr %34, align 8
  %36 = tail call zeroext i8 %35(ptr noundef nonnull %17) #15
  %37 = zext i8 %36 to i32
  %38 = load ptr, ptr %17, align 8, !tbaa !4
  %39 = getelementptr inbounds i8, ptr %38, i64 2296
  %40 = load ptr, ptr %39, align 8
  %41 = tail call zeroext i8 %40(ptr noundef nonnull %17) #15
  %42 = zext i8 %41 to i32
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.323, i32 noundef %30, i32 noundef %32, i32 noundef %31, i32 noundef %37, i32 noundef %42) #15
  %43 = load ptr, ptr %17, align 8, !tbaa !4
  %44 = getelementptr inbounds i8, ptr %43, i64 2288
  %45 = load ptr, ptr %44, align 8
  %46 = tail call zeroext i8 %45(ptr noundef nonnull %17) #15
  %47 = zext i8 %46 to i32
  %48 = load ptr, ptr %17, align 8, !tbaa !4
  %49 = getelementptr inbounds i8, ptr %48, i64 2296
  %50 = load ptr, ptr %49, align 8
  %51 = tail call zeroext i8 %50(ptr noundef nonnull %17) #15
  %52 = zext i8 %51 to i32
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.323, i32 noundef %30, i32 noundef %32, i32 noundef %31, i32 noundef %47, i32 noundef %52) #15
  br label %59

53:                                               ; preds = %15, %21
  %54 = load ptr, ptr %5, align 8, !tbaa !4
  %55 = getelementptr inbounds i8, ptr %54, i64 296
  %56 = load ptr, ptr %55, align 8
  %57 = tail call ptr %56(ptr noundef nonnull %5) #15
  %58 = icmp eq ptr %57, null
  br i1 %58, label %59, label %15

59:                                               ; preds = %53, %7, %29
  %60 = phi i1 [ true, %29 ], [ false, %7 ], [ false, %53 ]
  %61 = load ptr, ptr %5, align 8, !tbaa !4
  %62 = getelementptr inbounds i8, ptr %61, i64 40
  %63 = load ptr, ptr %62, align 8
  tail call void %63(ptr noundef nonnull %5) #15
  br label %64

64:                                               ; preds = %3, %59
  %65 = phi i1 [ %60, %59 ], [ true, %3 ]
  ret i1 %65
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define internal fastcc zeroext i1 @_ZL13nvrmRangeBusyyyP11IOPCIDeviceS0_(i64 noundef %0, i64 noundef %1, ptr noundef readnone %2, ptr noundef readnone %3) unnamed_addr #1 {
  %5 = load ptr, ptr @gIOServicePlane, align 8, !tbaa !10
  %6 = tail call ptr @_ZN18IORegistryIterator11iterateOverEPK15IORegistryPlanej(ptr noundef %5, i32 noundef 1) #15
  %7 = icmp eq ptr %6, null
  br i1 %7, label %115, label %8

8:                                                ; preds = %4
  %9 = load ptr, ptr @_ZN11IOPCIDevice9metaClassE, align 8
  %10 = load ptr, ptr @_ZN18IOMemoryDescriptor9metaClassE, align 8
  br label %11

11:                                               ; preds = %108, %8
  %12 = phi i8 [ %78, %108 ], [ 0, %8 ]
  br label %13

13:                                               ; preds = %19, %11
  %14 = load ptr, ptr %6, align 8, !tbaa !4
  %15 = getelementptr inbounds i8, ptr %14, i64 296
  %16 = load ptr, ptr %15, align 8
  %17 = tail call ptr %16(ptr noundef nonnull %6) #15
  %18 = icmp eq ptr %17, null
  br i1 %18, label %109, label %19

19:                                               ; preds = %13
  %20 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef nonnull %17, ptr noundef %9) #15
  %21 = icmp eq ptr %20, null
  %22 = icmp eq ptr %20, %2
  %23 = or i1 %21, %22
  %24 = icmp eq ptr %20, %3
  %25 = or i1 %24, %23
  br i1 %25, label %13, label %26, !llvm.loop !134

26:                                               ; preds = %19
  %27 = load ptr, ptr %20, align 8, !tbaa !4
  %28 = getelementptr inbounds i8, ptr %27, i64 1768
  %29 = load ptr, ptr %28, align 8
  %30 = tail call ptr %29(ptr noundef nonnull %20) #15
  %31 = icmp eq ptr %30, null
  br i1 %31, label %77, label %32

32:                                               ; preds = %26
  %33 = load ptr, ptr %30, align 8, !tbaa !4
  %34 = getelementptr inbounds i8, ptr %33, i64 304
  %35 = load ptr, ptr %34, align 8
  %36 = tail call i32 %35(ptr noundef nonnull %30) #15
  %37 = icmp eq i32 %36, 0
  %38 = trunc nuw i8 %12 to i1
  %39 = select i1 %37, i1 true, i1 %38
  br i1 %39, label %77, label %40

40:                                               ; preds = %32, %67
  %41 = phi i8 [ %68, %67 ], [ %12, %32 ]
  %42 = phi i32 [ %69, %67 ], [ 0, %32 ]
  %43 = load ptr, ptr %30, align 8, !tbaa !4
  %44 = getelementptr inbounds i8, ptr %43, i64 488
  %45 = load ptr, ptr %44, align 8
  %46 = tail call ptr %45(ptr noundef nonnull %30, i32 noundef %42) #15
  %47 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %46, ptr noundef %10) #15
  %48 = icmp eq ptr %47, null
  br i1 %48, label %67, label %49

49:                                               ; preds = %40
  %50 = tail call i64 @_ZN18IOMemoryDescriptor18getPhysicalAddressEv(ptr noundef nonnull %47) #15
  %51 = load ptr, ptr %47, align 8, !tbaa !4
  %52 = getelementptr inbounds i8, ptr %51, i64 456
  %53 = load ptr, ptr %52, align 8
  %54 = tail call i64 %53(ptr noundef nonnull %47) #15
  %55 = add i64 %50, -1
  %56 = add i64 %55, %54
  %57 = load ptr, ptr %47, align 8, !tbaa !4
  %58 = getelementptr inbounds i8, ptr %57, i64 456
  %59 = load ptr, ptr %58, align 8
  %60 = tail call i64 %59(ptr noundef nonnull %47) #15
  %61 = icmp eq i64 %60, 0
  %62 = icmp ugt i64 %50, %1
  %63 = select i1 %61, i1 true, i1 %62
  %64 = icmp ult i64 %56, %0
  %65 = select i1 %63, i1 true, i1 %64
  br i1 %65, label %67, label %66

66:                                               ; preds = %49
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.324, i64 noundef %0, i64 noundef %1, i64 noundef %50, i64 noundef %56) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.324, i64 noundef %0, i64 noundef %1, i64 noundef %50, i64 noundef %56) #15
  br label %67

67:                                               ; preds = %49, %66, %40
  %68 = phi i8 [ %41, %40 ], [ 1, %66 ], [ %41, %49 ]
  %69 = add nuw i32 %42, 1
  %70 = load ptr, ptr %30, align 8, !tbaa !4
  %71 = getelementptr inbounds i8, ptr %70, i64 304
  %72 = load ptr, ptr %71, align 8
  %73 = tail call i32 %72(ptr noundef nonnull %30) #15
  %74 = icmp uge i32 %69, %73
  %75 = trunc nuw i8 %68 to i1
  %76 = select i1 %74, i1 true, i1 %75
  br i1 %76, label %77, label %40, !llvm.loop !135

77:                                               ; preds = %67, %32, %26
  %78 = phi i8 [ %12, %26 ], [ %12, %32 ], [ %68, %67 ]
  %79 = trunc nuw i8 %78 to i1
  br i1 %79, label %109, label %80

80:                                               ; preds = %77
  %81 = tail call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef nonnull %20, i64 noundef 14) #15
  %82 = and i8 %81, 127
  %83 = icmp eq i8 %82, 1
  br i1 %83, label %84, label %108

84:                                               ; preds = %80
  %85 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef nonnull %20, i64 noundef 36) #15
  %86 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef nonnull %20, i64 noundef 40) #15
  %87 = zext i32 %86 to i64
  %88 = shl nuw i64 %87, 32
  %89 = shl i32 %85, 16
  %90 = and i32 %89, -1048576
  %91 = zext i32 %90 to i64
  %92 = or disjoint i64 %88, %91
  %93 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef nonnull %20, i64 noundef 44) #15
  %94 = zext i32 %93 to i64
  %95 = shl nuw i64 %94, 32
  %96 = or i32 %85, 1048575
  %97 = zext i32 %96 to i64
  %98 = or disjoint i64 %95, %97
  %99 = and i32 %85, 15
  %100 = icmp ne i32 %99, 1
  %101 = icmp ule i64 %98, %92
  %102 = icmp ugt i64 %92, %1
  %103 = or i1 %102, %101
  %104 = icmp ult i64 %98, %0
  %105 = or i1 %104, %103
  %106 = select i1 %100, i1 true, i1 %105
  br i1 %106, label %108, label %107

107:                                              ; preds = %84
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.325, i64 noundef %0, i64 noundef %1, i64 noundef %92, i64 noundef %98) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.325, i64 noundef %0, i64 noundef %1, i64 noundef %92, i64 noundef %98) #15
  br label %109

108:                                              ; preds = %84, %80
  br i1 %79, label %109, label %11

109:                                              ; preds = %108, %77, %13, %107
  %110 = phi i8 [ 1, %107 ], [ %12, %13 ], [ %78, %77 ], [ %78, %108 ]
  %111 = load ptr, ptr %6, align 8, !tbaa !4
  %112 = getelementptr inbounds i8, ptr %111, i64 40
  %113 = load ptr, ptr %112, align 8
  tail call void %113(ptr noundef nonnull %6) #15
  %114 = trunc nuw i8 %110 to i1
  br label %115

115:                                              ; preds = %4, %109
  %116 = phi i1 [ %114, %109 ], [ true, %4 ]
  ret i1 %116
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef, i64 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.cttz.i64(i64, i1 immarg) #11

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN7OSArray12withCapacityEj(i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN14IODeviceMemory9withRangeEyy(i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM17publishGpuProfileEv(ptr nocapture noundef readonly %0) local_unnamed_addr #1 align 2 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca [16 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #18
  store i32 0, ptr %2, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #18
  store i32 0, ptr %3, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #18
  store i32 0, ptr %4, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #18
  store i32 0, ptr %5, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #18
  store i32 0, ptr %6, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #18
  store i32 0, ptr %7, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #18
  store i32 0, ptr %8, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %9) #18
  store i32 0, ptr %9, align 4, !tbaa !18
  %11 = getelementptr inbounds i8, ptr %0, i64 372
  %12 = load i32, ptr %11, align 4, !tbaa !132
  %13 = call zeroext i1 @nvrm_query_gpu_profile(i32 noundef %12, ptr noundef nonnull %2, ptr noundef nonnull %3, ptr noundef nonnull %4, ptr noundef nonnull %5, ptr noundef nonnull %6, ptr noundef nonnull %7, ptr noundef nonnull %8, ptr noundef nonnull %9) #15
  br i1 %13, label %17, label %14

14:                                               ; preds = %1
  %15 = load i32, ptr %9, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.152, i32 noundef %15) #15
  %16 = load i32, ptr %9, align 4, !tbaa !18
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.152, i32 noundef %16) #15
  br label %267

17:                                               ; preds = %1
  %18 = load i32, ptr %2, align 4, !tbaa !18
  %19 = add i32 %18, -352
  %20 = call i32 @llvm.fshl.i32(i32 %19, i32 %19, i32 28)
  switch i32 %20, label %30 [
    i32 0, label %21
    i32 1, label %26
    i32 2, label %27
    i32 3, label %28
    i32 4, label %29
    i32 5, label %29
  ]

21:                                               ; preds = %17
  %22 = load i32, ptr %3, align 4
  %23 = add i32 %22, -7
  %24 = icmp ult i32 %23, 2
  %25 = select i1 %24, ptr @.str.153, ptr @.str.154
  br label %30

26:                                               ; preds = %17
  br label %30

27:                                               ; preds = %17
  br label %30

28:                                               ; preds = %17
  br label %30

29:                                               ; preds = %17, %17
  br label %30

30:                                               ; preds = %17, %29, %28, %27, %26, %21
  %31 = phi ptr [ @.str.65, %17 ], [ @.str.163, %29 ], [ @.str.161, %28 ], [ @.str.159, %27 ], [ @.str.157, %26 ], [ @.str.155, %21 ]
  %32 = phi ptr [ @.str.67, %17 ], [ @.str.162, %29 ], [ @.str.160, %28 ], [ @.str.158, %27 ], [ @.str.156, %26 ], [ %25, %21 ]
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %10) #18
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %10, i8 0, i64 16, i1 false), !annotation !77
  %33 = icmp eq i32 %18, 352
  %34 = load i32, ptr %3, align 4
  %35 = icmp eq i32 %34, 8
  %36 = select i1 %33, i1 %35, i1 false
  br i1 %36, label %37, label %39

37:                                               ; preds = %30
  %38 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %10, i64 noundef 16, ptr noundef nonnull @.str.164) #15
  br label %48

39:                                               ; preds = %30
  %40 = icmp eq i32 %34, 7
  %41 = select i1 %33, i1 %40, i1 false
  br i1 %41, label %42, label %44

42:                                               ; preds = %39
  %43 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %10, i64 noundef 16, ptr noundef nonnull @.str.165) #15
  br label %48

44:                                               ; preds = %39
  %45 = icmp eq i32 %18, 432
  %46 = select i1 %45, i32 2, i32 1
  %47 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %10, i64 noundef 16, ptr noundef nonnull @.str.166, ptr noundef nonnull %31, i32 noundef %46, i32 noundef %34) #15
  br label %48

48:                                               ; preds = %42, %44, %37
  %49 = getelementptr inbounds i8, ptr %0, i64 528
  %50 = load i64, ptr %49, align 8, !tbaa !114
  %51 = freeze i64 %50
  %52 = getelementptr inbounds i8, ptr %0, i64 328
  %53 = load ptr, ptr %52, align 8, !tbaa !78
  %54 = load ptr, ptr %53, align 8, !tbaa !4
  %55 = getelementptr inbounds i8, ptr %54, i64 696
  %56 = load ptr, ptr %55, align 8
  %57 = call ptr %56(ptr noundef nonnull %53, ptr noundef nonnull @.str.167) #15
  %58 = load ptr, ptr @_ZN8OSNumber9metaClassE, align 8, !tbaa !10
  %59 = call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %57, ptr noundef %58) #15
  %60 = icmp eq ptr %59, null
  br i1 %60, label %66, label %61

61:                                               ; preds = %48
  %62 = load ptr, ptr %59, align 8, !tbaa !4
  %63 = getelementptr inbounds i8, ptr %62, i64 336
  %64 = load ptr, ptr %63, align 8
  %65 = call i64 %64(ptr noundef nonnull %59) #15
  br label %66

66:                                               ; preds = %61, %48
  %67 = phi i64 [ %65, %61 ], [ 0, %48 ]
  %68 = call ptr @_ZN12OSDictionary12withCapacityEj(i32 noundef 16) #15
  %69 = icmp eq ptr %68, null
  br i1 %69, label %266, label %70

70:                                               ; preds = %66
  %71 = add i64 %67, -1
  %72 = icmp ult i64 %71, %51
  %73 = load i32, ptr %2, align 4, !tbaa !18
  %74 = zext i32 %73 to i64
  %75 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %74, i32 noundef 32) #15
  %76 = icmp eq ptr %75, null
  br i1 %76, label %85, label %77

77:                                               ; preds = %70
  %78 = load ptr, ptr %68, align 8, !tbaa !4
  %79 = getelementptr inbounds i8, ptr %78, i64 464
  %80 = load ptr, ptr %79, align 8
  %81 = call zeroext i1 %80(ptr noundef nonnull %68, ptr noundef nonnull @.str.168, ptr noundef nonnull %75) #15
  %82 = load ptr, ptr %75, align 8, !tbaa !4
  %83 = getelementptr inbounds i8, ptr %82, i64 40
  %84 = load ptr, ptr %83, align 8
  call void %84(ptr noundef nonnull %75) #15
  br label %85

85:                                               ; preds = %70, %77
  %86 = load i32, ptr %3, align 4, !tbaa !18
  %87 = zext i32 %86 to i64
  %88 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %87, i32 noundef 32) #15
  %89 = icmp eq ptr %88, null
  br i1 %89, label %98, label %90

90:                                               ; preds = %85
  %91 = load ptr, ptr %68, align 8, !tbaa !4
  %92 = getelementptr inbounds i8, ptr %91, i64 464
  %93 = load ptr, ptr %92, align 8
  %94 = call zeroext i1 %93(ptr noundef nonnull %68, ptr noundef nonnull @.str.169, ptr noundef nonnull %88) #15
  %95 = load ptr, ptr %88, align 8, !tbaa !4
  %96 = getelementptr inbounds i8, ptr %95, i64 40
  %97 = load ptr, ptr %96, align 8
  call void %97(ptr noundef nonnull %88) #15
  br label %98

98:                                               ; preds = %85, %90
  %99 = call ptr @_ZN8OSString11withCStringEPKc(ptr noundef nonnull %10) #15
  %100 = icmp eq ptr %99, null
  br i1 %100, label %109, label %101

101:                                              ; preds = %98
  %102 = load ptr, ptr %68, align 8, !tbaa !4
  %103 = getelementptr inbounds i8, ptr %102, i64 464
  %104 = load ptr, ptr %103, align 8
  %105 = call zeroext i1 %104(ptr noundef nonnull %68, ptr noundef nonnull @.str.170, ptr noundef nonnull %99) #15
  %106 = load ptr, ptr %99, align 8, !tbaa !4
  %107 = getelementptr inbounds i8, ptr %106, i64 40
  %108 = load ptr, ptr %107, align 8
  call void %108(ptr noundef nonnull %99) #15
  br label %109

109:                                              ; preds = %98, %101
  %110 = call ptr @_ZN8OSString11withCStringEPKc(ptr noundef nonnull %32) #15
  %111 = icmp eq ptr %110, null
  br i1 %111, label %120, label %112

112:                                              ; preds = %109
  %113 = load ptr, ptr %68, align 8, !tbaa !4
  %114 = getelementptr inbounds i8, ptr %113, i64 464
  %115 = load ptr, ptr %114, align 8
  %116 = call zeroext i1 %115(ptr noundef nonnull %68, ptr noundef nonnull @.str.171, ptr noundef nonnull %110) #15
  %117 = load ptr, ptr %110, align 8, !tbaa !4
  %118 = getelementptr inbounds i8, ptr %117, i64 40
  %119 = load ptr, ptr %118, align 8
  call void %119(ptr noundef nonnull %110) #15
  br label %120

120:                                              ; preds = %109, %112
  %121 = load i32, ptr %4, align 4, !tbaa !18
  %122 = zext i32 %121 to i64
  %123 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %122, i32 noundef 32) #15
  %124 = icmp eq ptr %123, null
  br i1 %124, label %133, label %125

125:                                              ; preds = %120
  %126 = load ptr, ptr %68, align 8, !tbaa !4
  %127 = getelementptr inbounds i8, ptr %126, i64 464
  %128 = load ptr, ptr %127, align 8
  %129 = call zeroext i1 %128(ptr noundef nonnull %68, ptr noundef nonnull @.str.172, ptr noundef nonnull %123) #15
  %130 = load ptr, ptr %123, align 8, !tbaa !4
  %131 = getelementptr inbounds i8, ptr %130, i64 40
  %132 = load ptr, ptr %131, align 8
  call void %132(ptr noundef nonnull %123) #15
  br label %133

133:                                              ; preds = %120, %125
  %134 = load i32, ptr %5, align 4, !tbaa !18
  %135 = zext i32 %134 to i64
  %136 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %135, i32 noundef 32) #15
  %137 = icmp eq ptr %136, null
  br i1 %137, label %146, label %138

138:                                              ; preds = %133
  %139 = load ptr, ptr %68, align 8, !tbaa !4
  %140 = getelementptr inbounds i8, ptr %139, i64 464
  %141 = load ptr, ptr %140, align 8
  %142 = call zeroext i1 %141(ptr noundef nonnull %68, ptr noundef nonnull @.str.173, ptr noundef nonnull %136) #15
  %143 = load ptr, ptr %136, align 8, !tbaa !4
  %144 = getelementptr inbounds i8, ptr %143, i64 40
  %145 = load ptr, ptr %144, align 8
  call void %145(ptr noundef nonnull %136) #15
  br label %146

146:                                              ; preds = %133, %138
  %147 = load i32, ptr %6, align 4, !tbaa !18
  %148 = zext i32 %147 to i64
  %149 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %148, i32 noundef 32) #15
  %150 = icmp eq ptr %149, null
  br i1 %150, label %159, label %151

151:                                              ; preds = %146
  %152 = load ptr, ptr %68, align 8, !tbaa !4
  %153 = getelementptr inbounds i8, ptr %152, i64 464
  %154 = load ptr, ptr %153, align 8
  %155 = call zeroext i1 %154(ptr noundef nonnull %68, ptr noundef nonnull @.str.174, ptr noundef nonnull %149) #15
  %156 = load ptr, ptr %149, align 8, !tbaa !4
  %157 = getelementptr inbounds i8, ptr %156, i64 40
  %158 = load ptr, ptr %157, align 8
  call void %158(ptr noundef nonnull %149) #15
  br label %159

159:                                              ; preds = %146, %151
  %160 = load i32, ptr %7, align 4, !tbaa !18
  %161 = zext i32 %160 to i64
  %162 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %161, i32 noundef 32) #15
  %163 = icmp eq ptr %162, null
  br i1 %163, label %172, label %164

164:                                              ; preds = %159
  %165 = load ptr, ptr %68, align 8, !tbaa !4
  %166 = getelementptr inbounds i8, ptr %165, i64 464
  %167 = load ptr, ptr %166, align 8
  %168 = call zeroext i1 %167(ptr noundef nonnull %68, ptr noundef nonnull @.str.175, ptr noundef nonnull %162) #15
  %169 = load ptr, ptr %162, align 8, !tbaa !4
  %170 = getelementptr inbounds i8, ptr %169, i64 40
  %171 = load ptr, ptr %170, align 8
  call void %171(ptr noundef nonnull %162) #15
  br label %172

172:                                              ; preds = %159, %164
  %173 = load i32, ptr %8, align 4, !tbaa !18
  %174 = zext i32 %173 to i64
  %175 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %174, i32 noundef 32) #15
  %176 = icmp eq ptr %175, null
  br i1 %176, label %185, label %177

177:                                              ; preds = %172
  %178 = load ptr, ptr %68, align 8, !tbaa !4
  %179 = getelementptr inbounds i8, ptr %178, i64 464
  %180 = load ptr, ptr %179, align 8
  %181 = call zeroext i1 %180(ptr noundef nonnull %68, ptr noundef nonnull @.str.176, ptr noundef nonnull %175) #15
  %182 = load ptr, ptr %175, align 8, !tbaa !4
  %183 = getelementptr inbounds i8, ptr %182, i64 40
  %184 = load ptr, ptr %183, align 8
  call void %184(ptr noundef nonnull %175) #15
  br label %185

185:                                              ; preds = %172, %177
  %186 = lshr i64 %51, 20
  %187 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %186, i32 noundef 32) #15
  %188 = icmp eq ptr %187, null
  br i1 %188, label %197, label %189

189:                                              ; preds = %185
  %190 = load ptr, ptr %68, align 8, !tbaa !4
  %191 = getelementptr inbounds i8, ptr %190, i64 464
  %192 = load ptr, ptr %191, align 8
  %193 = call zeroext i1 %192(ptr noundef nonnull %68, ptr noundef nonnull @.str.177, ptr noundef nonnull %187) #15
  %194 = load ptr, ptr %187, align 8, !tbaa !4
  %195 = getelementptr inbounds i8, ptr %194, i64 40
  %196 = load ptr, ptr %195, align 8
  call void %196(ptr noundef nonnull %187) #15
  br label %197

197:                                              ; preds = %185, %189
  %198 = lshr i64 %67, 20
  %199 = call ptr @_ZN8OSNumber10withNumberEyj(i64 noundef %198, i32 noundef 32) #15
  %200 = icmp eq ptr %199, null
  br i1 %200, label %209, label %201

201:                                              ; preds = %197
  %202 = load ptr, ptr %68, align 8, !tbaa !4
  %203 = getelementptr inbounds i8, ptr %202, i64 464
  %204 = load ptr, ptr %203, align 8
  %205 = call zeroext i1 %204(ptr noundef nonnull %68, ptr noundef nonnull @.str.178, ptr noundef nonnull %199) #15
  %206 = load ptr, ptr %199, align 8, !tbaa !4
  %207 = getelementptr inbounds i8, ptr %206, i64 40
  %208 = load ptr, ptr %207, align 8
  call void %208(ptr noundef nonnull %199) #15
  br label %209

209:                                              ; preds = %197, %201
  %210 = select i1 %72, ptr @.str.180, ptr @.str.181
  %211 = call ptr @_ZN8OSString11withCStringEPKc(ptr noundef nonnull %210) #15
  %212 = icmp eq ptr %211, null
  br i1 %212, label %221, label %213

213:                                              ; preds = %209
  %214 = load ptr, ptr %68, align 8, !tbaa !4
  %215 = getelementptr inbounds i8, ptr %214, i64 464
  %216 = load ptr, ptr %215, align 8
  %217 = call zeroext i1 %216(ptr noundef nonnull %68, ptr noundef nonnull @.str.179, ptr noundef nonnull %211) #15
  %218 = load ptr, ptr %211, align 8, !tbaa !4
  %219 = getelementptr inbounds i8, ptr %218, i64 40
  %220 = load ptr, ptr %219, align 8
  call void %220(ptr noundef nonnull %211) #15
  br label %221

221:                                              ; preds = %209, %213
  %222 = load i32, ptr %2, align 4, !tbaa !18
  %223 = icmp ugt i32 %222, 415
  %224 = select i1 %223, ptr @.str.183, ptr @.str.184
  %225 = call ptr @_ZN8OSString11withCStringEPKc(ptr noundef nonnull %224) #15
  %226 = icmp eq ptr %225, null
  br i1 %226, label %235, label %227

227:                                              ; preds = %221
  %228 = load ptr, ptr %68, align 8, !tbaa !4
  %229 = getelementptr inbounds i8, ptr %228, i64 464
  %230 = load ptr, ptr %229, align 8
  %231 = call zeroext i1 %230(ptr noundef nonnull %68, ptr noundef nonnull @.str.182, ptr noundef nonnull %225) #15
  %232 = load ptr, ptr %225, align 8, !tbaa !4
  %233 = getelementptr inbounds i8, ptr %232, i64 40
  %234 = load ptr, ptr %233, align 8
  call void %234(ptr noundef nonnull %225) #15
  br label %235

235:                                              ; preds = %221, %227
  %236 = load i32, ptr %2, align 4, !tbaa !18
  %237 = icmp eq i32 %236, 432
  %238 = select i1 %237, ptr @.str.186, ptr @.str.187
  %239 = call ptr @_ZN8OSString11withCStringEPKc(ptr noundef nonnull %238) #15
  %240 = icmp eq ptr %239, null
  br i1 %240, label %249, label %241

241:                                              ; preds = %235
  %242 = load ptr, ptr %68, align 8, !tbaa !4
  %243 = getelementptr inbounds i8, ptr %242, i64 464
  %244 = load ptr, ptr %243, align 8
  %245 = call zeroext i1 %244(ptr noundef nonnull %68, ptr noundef nonnull @.str.185, ptr noundef nonnull %239) #15
  %246 = load ptr, ptr %239, align 8, !tbaa !4
  %247 = getelementptr inbounds i8, ptr %246, i64 40
  %248 = load ptr, ptr %247, align 8
  call void %248(ptr noundef nonnull %239) #15
  br label %249

249:                                              ; preds = %235, %241
  %250 = load ptr, ptr %52, align 8, !tbaa !78
  %251 = load ptr, ptr %250, align 8, !tbaa !4
  %252 = getelementptr inbounds i8, ptr %251, i64 616
  %253 = load ptr, ptr %252, align 8
  %254 = call zeroext i1 %253(ptr noundef nonnull %250, ptr noundef nonnull @.str.188, ptr noundef nonnull %68) #15
  %255 = load ptr, ptr %68, align 8, !tbaa !4
  %256 = getelementptr inbounds i8, ptr %255, i64 40
  %257 = load ptr, ptr %256, align 8
  call void %257(ptr noundef nonnull %68) #15
  %258 = load i32, ptr %4, align 4, !tbaa !18
  %259 = load i32, ptr %6, align 4, !tbaa !18
  %260 = load i32, ptr %7, align 4, !tbaa !18
  %261 = load i32, ptr %8, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.189, ptr noundef nonnull %32, ptr noundef nonnull %10, i32 noundef %258, i32 noundef %259, i32 noundef %260, i32 noundef %261, i64 noundef %186, i64 noundef %198, ptr noundef nonnull %210) #15
  %262 = load i32, ptr %4, align 4, !tbaa !18
  %263 = load i32, ptr %6, align 4, !tbaa !18
  %264 = load i32, ptr %7, align 4, !tbaa !18
  %265 = load i32, ptr %8, align 4, !tbaa !18
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.189, ptr noundef nonnull %32, ptr noundef nonnull %10, i32 noundef %262, i32 noundef %263, i32 noundef %264, i32 noundef %265, i64 noundef %186, i64 noundef %198, ptr noundef nonnull %210) #15
  br label %266

266:                                              ; preds = %66, %249
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %10) #18
  br label %267

267:                                              ; preds = %266, %14
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %9) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #18
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @nvrm_query_gpu_profile(i32 noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12OSDictionary12withCapacityEj(i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @kauth_getuid() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @os_mem_set(ptr noundef, i8 noundef zeroext, i32 noundef) #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @rm_init_rm(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @rm_init_event_locks(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @nv_get_ctl_state() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_write_registry_string(ptr noundef, ptr noundef, ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_write_registry_dword(ptr noundef, ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_is_supported_device(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @rm_init_private_state(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @rm_set_rm_firmware_requested(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN10IOWorkLoop8workLoopEv() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN28IOFilterInterruptEventSource26filterInterruptEventSourceEP8OSObjectPFvS1_P22IOInterruptEventSourceiEPFbS1_PS_EP9IOServicei(ptr noundef, ptr noundef, ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM17interruptOccurredEP22IOInterruptEventSourcei(ptr noundef %0, ptr nocapture readnone %1, i32 %2) #1 align 2 {
  %4 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #18
  store i32 0, ptr %4, align 4, !tbaa !18
  %5 = tail call ptr @current_thread() #16
  store volatile ptr %5, ptr @nv_xnu_isr_thread, align 8, !tbaa !10
  %6 = getelementptr inbounds i8, ptr %0, i64 336
  %7 = call zeroext i8 @rm_isr(ptr noundef null, ptr noundef nonnull %6, ptr noundef nonnull %4) #15
  store volatile ptr null, ptr @nv_xnu_isr_thread, align 8, !tbaa !10
  %8 = icmp eq i8 %7, 0
  br i1 %8, label %15, label %9

9:                                                ; preds = %3
  %10 = load volatile i64, ptr @_ZL13gNvIsrHandled, align 8, !tbaa !97
  %11 = add i64 %10, 1
  store volatile i64 %11, ptr @_ZL13gNvIsrHandled, align 8, !tbaa !97
  %12 = load i32, ptr %4, align 4
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %15, label %14

14:                                               ; preds = %9
  call void @rm_isr_bh(ptr noundef null, ptr noundef nonnull %6) #15
  br label %15

15:                                               ; preds = %3, %14, %9
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #18
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i1 @_ZN4NVRM15interruptFilterEP28IOFilterInterruptEventSource(ptr nocapture readnone %0, ptr nocapture readnone %1) #1 align 2 {
  %3 = load volatile i64, ptr @_ZL11gNvIsrCount, align 8, !tbaa !97
  %4 = add i64 %3, 1
  store volatile i64 %4, ptr @_ZL11gNvIsrCount, align 8, !tbaa !97
  %5 = icmp ult i64 %4, 4
  %6 = urem i64 %4, 1000
  %7 = icmp eq i64 %6, 0
  %8 = or i1 %5, %7
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = load volatile i64, ptr @_ZL13gNvIsrHandled, align 8, !tbaa !97
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.233, i64 noundef %4, i64 noundef %10) #15
  br label %11

11:                                               ; preds = %2, %9
  ret i1 true
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @rm_init_adapter(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @nv_xnu_dump_live_allocs() local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define internal fastcc void @_ZL20nv_xnu_dump_gsp_regsP10nv_state_t(ptr nocapture noundef readonly %0) unnamed_addr #1 {
  %2 = getelementptr inbounds i8, ptr %0, i64 152
  %3 = load i64, ptr %2, align 8, !tbaa !114
  %4 = icmp ult i64 %3, 2097152
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.341) #15
  br label %63

6:                                                ; preds = %1
  %7 = getelementptr inbounds i8, ptr %0, i64 144
  %8 = load i64, ptr %7, align 8, !tbaa !113
  %9 = tail call ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef %8, i64 noundef 2097152, i32 noundef 3) #15
  %10 = icmp eq ptr %9, null
  br i1 %10, label %11, label %12

11:                                               ; preds = %6
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.342) #15
  br label %63

12:                                               ; preds = %6
  %13 = load ptr, ptr %9, align 8, !tbaa !4
  %14 = getelementptr inbounds i8, ptr %13, i64 512
  %15 = load ptr, ptr %14, align 8
  %16 = tail call ptr %15(ptr noundef nonnull %9, i32 noundef 256) #15
  %17 = icmp eq ptr %16, null
  br i1 %17, label %18, label %22

18:                                               ; preds = %12
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.343) #15
  %19 = load ptr, ptr %9, align 8, !tbaa !4
  %20 = getelementptr inbounds i8, ptr %19, i64 40
  %21 = load ptr, ptr %20, align 8
  tail call void %21(ptr noundef nonnull %9) #15
  br label %63

22:                                               ; preds = %12
  %23 = load ptr, ptr %16, align 8, !tbaa !4
  %24 = getelementptr inbounds i8, ptr %23, i64 280
  %25 = load ptr, ptr %24, align 8
  %26 = tail call i64 %25(ptr noundef nonnull %16) #15
  %27 = inttoptr i64 %26 to ptr
  %28 = load volatile i32, ptr %27, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.326, i32 noundef 0, i32 noundef %28) #15
  %29 = getelementptr inbounds i8, ptr %27, i64 1114176
  %30 = load volatile i32, ptr %29, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.327, i32 noundef 1114176, i32 noundef %30) #15
  %31 = getelementptr inbounds i8, ptr %27, i64 1114180
  %32 = load volatile i32, ptr %31, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.328, i32 noundef 1114180, i32 noundef %32) #15
  %33 = getelementptr inbounds i8, ptr %27, i64 1114356
  %34 = load volatile i32, ptr %33, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.329, i32 noundef 1114356, i32 noundef %34) #15
  %35 = getelementptr inbounds i8, ptr %27, i64 1114240
  %36 = load volatile i32, ptr %35, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.330, i32 noundef 1114240, i32 noundef %36) #15
  %37 = getelementptr inbounds i8, ptr %27, i64 1114120
  %38 = load volatile i32, ptr %37, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.331, i32 noundef 1114120, i32 noundef %38) #15
  %39 = getelementptr inbounds i8, ptr %27, i64 1115072
  %40 = load volatile i32, ptr %39, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.332, i32 noundef 1115072, i32 noundef %40) #15
  %41 = getelementptr inbounds i8, ptr %27, i64 1119112
  %42 = load volatile i32, ptr %41, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.333, i32 noundef 1119112, i32 noundef %42) #15
  %43 = getelementptr inbounds i8, ptr %27, i64 1119848
  %44 = load volatile i32, ptr %43, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.334, i32 noundef 1119848, i32 noundef %44) #15
  %45 = getelementptr inbounds i8, ptr %27, i64 1116164
  %46 = load volatile i32, ptr %45, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.335, i32 noundef 1116164, i32 noundef %46) #15
  %47 = getelementptr inbounds i8, ptr %27, i64 1116168
  %48 = load volatile i32, ptr %47, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.336, i32 noundef 1116168, i32 noundef %48) #15
  %49 = getelementptr inbounds i8, ptr %27, i64 1117184
  %50 = load volatile i32, ptr %49, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.337, i32 noundef 1117184, i32 noundef %50) #15
  %51 = getelementptr inbounds i8, ptr %27, i64 2074660
  %52 = load volatile i32, ptr %51, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.338, i32 noundef 2074660, i32 noundef %52) #15
  %53 = getelementptr inbounds i8, ptr %27, i64 2074664
  %54 = load volatile i32, ptr %53, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.339, i32 noundef 2074664, i32 noundef %54) #15
  %55 = getelementptr inbounds i8, ptr %27, i64 1147444
  %56 = load volatile i32, ptr %55, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.344, ptr noundef nonnull @.str.340, i32 noundef 1147444, i32 noundef %56) #15
  %57 = load ptr, ptr %16, align 8, !tbaa !4
  %58 = getelementptr inbounds i8, ptr %57, i64 40
  %59 = load ptr, ptr %58, align 8
  tail call void %59(ptr noundef nonnull %16) #15
  %60 = load ptr, ptr %9, align 8, !tbaa !4
  %61 = getelementptr inbounds i8, ptr %60, i64 40
  %62 = load ptr, ptr %61, align 8
  tail call void %62(ptr noundef nonnull %9) #15
  br label %63

63:                                               ; preds = %11, %22, %18, %5
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @nvrm_query_vram_kb(i32 noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @nvkms_xnu_load() local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define internal fastcc void @_ZL20nvrm_display_publishP9IOServicej(ptr noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = alloca i32, align 4
  %4 = load i1, ptr @_ZZL20nvrm_display_publishP9IOServicejE10gPublished, align 1
  br i1 %4, label %133, label %5

5:                                                ; preds = %2
  %6 = tail call ptr @nvkms_xnu_kapi_table() #15
  %7 = icmp eq ptr %6, null
  br i1 %7, label %8, label %9

8:                                                ; preds = %5
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.345) #15
  br label %133

9:                                                ; preds = %5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #18
  store i32 1, ptr %3, align 4, !tbaa !18
  %10 = call i32 @PE_parse_boot_argn(ptr noundef nonnull @.str.84, ptr noundef nonnull %3, i32 noundef 4) #15
  %11 = icmp eq i32 %10, 0
  %12 = load i32, ptr %3, align 4
  %13 = icmp slt i32 %12, 1
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %16

15:                                               ; preds = %9
  store i32 1, ptr %3, align 4, !tbaa !18
  br label %19

16:                                               ; preds = %9
  %17 = icmp ugt i32 %12, 4
  br i1 %17, label %18, label %19

18:                                               ; preds = %16
  store i32 4, ptr %3, align 4, !tbaa !18
  br label %19

19:                                               ; preds = %16, %18, %15
  %20 = ptrtoint ptr %6 to i64
  %21 = zext i32 %1 to i64
  %22 = load ptr, ptr @_ZN11NVRMDisplay10gMetaClassE, align 8, !tbaa !4
  %23 = getelementptr inbounds i8, ptr %22, i64 136
  %24 = load ptr, ptr %23, align 8
  %25 = call ptr %24(ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  %26 = icmp eq ptr %25, null
  br i1 %26, label %128, label %27

27:                                               ; preds = %19
  %28 = load ptr, ptr %25, align 8, !tbaa !4
  %29 = getelementptr inbounds i8, ptr %28, i64 584
  %30 = load ptr, ptr %29, align 8
  %31 = call zeroext i1 %30(ptr noundef nonnull %25, ptr noundef null) #15
  br i1 %31, label %32, label %79

32:                                               ; preds = %27
  %33 = load ptr, ptr %25, align 8, !tbaa !4
  %34 = getelementptr inbounds i8, ptr %33, i64 640
  %35 = load ptr, ptr %34, align 8
  %36 = call zeroext i1 %35(ptr noundef nonnull %25, ptr noundef nonnull @.str.346, i64 noundef %20, i32 noundef 64) #15
  %37 = load ptr, ptr %25, align 8, !tbaa !4
  %38 = getelementptr inbounds i8, ptr %37, i64 640
  %39 = load ptr, ptr %38, align 8
  %40 = call zeroext i1 %39(ptr noundef nonnull %25, ptr noundef nonnull @.str.347, i64 noundef %21, i32 noundef 32) #15
  %41 = load ptr, ptr %25, align 8, !tbaa !4
  %42 = getelementptr inbounds i8, ptr %41, i64 640
  %43 = load ptr, ptr %42, align 8
  %44 = call zeroext i1 %43(ptr noundef nonnull %25, ptr noundef nonnull @.str.348, i64 noundef ptrtoint (ptr @nv_xnu_phys_for_kernel_va to i64), i32 noundef 64) #15
  %45 = load ptr, ptr %25, align 8, !tbaa !4
  %46 = getelementptr inbounds i8, ptr %45, i64 640
  %47 = load ptr, ptr %46, align 8
  %48 = call zeroext i1 %47(ptr noundef nonnull %25, ptr noundef nonnull @.str.349, i64 noundef 0, i32 noundef 32) #15
  %49 = load ptr, ptr %25, align 8, !tbaa !4
  %50 = getelementptr inbounds i8, ptr %49, i64 1648
  %51 = load ptr, ptr %50, align 8
  %52 = call zeroext i1 %51(ptr noundef nonnull %25, ptr noundef %0) #15
  br i1 %52, label %53, label %108

53:                                               ; preds = %32
  %54 = load ptr, ptr %25, align 8, !tbaa !4
  %55 = getelementptr inbounds i8, ptr %54, i64 1456
  %56 = load ptr, ptr %55, align 8
  call void %56(ptr noundef nonnull %25, i32 noundef 0) #15
  store ptr %25, ptr @_ZL12gDisplayNub0, align 8, !tbaa !10
  %57 = load i32, ptr %3, align 4
  %58 = icmp sgt i32 %57, 1
  br i1 %58, label %59, label %129

59:                                               ; preds = %53
  %60 = call i32 @_ZN9IOService9waitQuietEy(ptr noundef nonnull %25, i64 noundef 10000000000) #15
  %61 = load i32, ptr %3, align 4, !tbaa !18
  %62 = add nsw i32 %61, -1
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.350, i32 noundef %60, i32 noundef %62) #15
  %63 = load i32, ptr %3, align 4, !tbaa !18
  %64 = icmp sgt i32 %63, 1
  br i1 %64, label %65, label %129

65:                                               ; preds = %59, %114
  %66 = phi i64 [ %119, %114 ], [ 1, %59 ]
  %67 = load ptr, ptr @_ZN11NVRMDisplay10gMetaClassE, align 8, !tbaa !4
  %68 = getelementptr inbounds i8, ptr %67, i64 136
  %69 = load ptr, ptr %68, align 8
  %70 = call ptr %69(ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  %71 = icmp eq ptr %70, null
  br i1 %71, label %122, label %72

72:                                               ; preds = %65
  %73 = load ptr, ptr %70, align 8, !tbaa !4
  %74 = getelementptr inbounds i8, ptr %73, i64 584
  %75 = load ptr, ptr %74, align 8
  %76 = call zeroext i1 %75(ptr noundef nonnull %70, ptr noundef null) #15
  br i1 %76, label %85, label %77

77:                                               ; preds = %72
  %78 = trunc i64 %66 to i32
  br label %79

79:                                               ; preds = %77, %27
  %80 = phi i32 [ 0, %27 ], [ %78, %77 ]
  %81 = phi ptr [ %25, %27 ], [ %70, %77 ]
  %82 = load ptr, ptr %81, align 8, !tbaa !4
  %83 = getelementptr inbounds i8, ptr %82, i64 40
  %84 = load ptr, ptr %83, align 8
  call void %84(ptr noundef nonnull %81) #15
  br label %125

85:                                               ; preds = %72
  %86 = load ptr, ptr %70, align 8, !tbaa !4
  %87 = getelementptr inbounds i8, ptr %86, i64 640
  %88 = load ptr, ptr %87, align 8
  %89 = call zeroext i1 %88(ptr noundef nonnull %70, ptr noundef nonnull @.str.346, i64 noundef %20, i32 noundef 64) #15
  %90 = load ptr, ptr %70, align 8, !tbaa !4
  %91 = getelementptr inbounds i8, ptr %90, i64 640
  %92 = load ptr, ptr %91, align 8
  %93 = call zeroext i1 %92(ptr noundef nonnull %70, ptr noundef nonnull @.str.347, i64 noundef %21, i32 noundef 32) #15
  %94 = load ptr, ptr %70, align 8, !tbaa !4
  %95 = getelementptr inbounds i8, ptr %94, i64 640
  %96 = load ptr, ptr %95, align 8
  %97 = call zeroext i1 %96(ptr noundef nonnull %70, ptr noundef nonnull @.str.348, i64 noundef ptrtoint (ptr @nv_xnu_phys_for_kernel_va to i64), i32 noundef 64) #15
  %98 = load ptr, ptr %70, align 8, !tbaa !4
  %99 = getelementptr inbounds i8, ptr %98, i64 640
  %100 = load ptr, ptr %99, align 8
  %101 = call zeroext i1 %100(ptr noundef nonnull %70, ptr noundef nonnull @.str.349, i64 noundef %66, i32 noundef 32) #15
  %102 = load ptr, ptr %70, align 8, !tbaa !4
  %103 = getelementptr inbounds i8, ptr %102, i64 1648
  %104 = load ptr, ptr %103, align 8
  %105 = call zeroext i1 %104(ptr noundef nonnull %70, ptr noundef %0) #15
  br i1 %105, label %114, label %106

106:                                              ; preds = %85
  %107 = trunc i64 %66 to i32
  br label %108

108:                                              ; preds = %106, %32
  %109 = phi i32 [ 0, %32 ], [ %107, %106 ]
  %110 = phi ptr [ %25, %32 ], [ %70, %106 ]
  %111 = load ptr, ptr %110, align 8, !tbaa !4
  %112 = getelementptr inbounds i8, ptr %111, i64 40
  %113 = load ptr, ptr %112, align 8
  call void %113(ptr noundef nonnull %110) #15
  br label %125

114:                                              ; preds = %85
  %115 = load ptr, ptr %70, align 8, !tbaa !4
  %116 = getelementptr inbounds i8, ptr %115, i64 1456
  %117 = load ptr, ptr %116, align 8
  call void %117(ptr noundef nonnull %70, i32 noundef 0) #15
  %118 = load i32, ptr %3, align 4
  %119 = add nuw nsw i64 %66, 1
  %120 = sext i32 %118 to i64
  %121 = icmp slt i64 %119, %120
  br i1 %121, label %65, label %122, !llvm.loop !136

122:                                              ; preds = %114, %65
  %123 = phi i64 [ %66, %65 ], [ %119, %114 ]
  %124 = trunc i64 %123 to i32
  br label %125

125:                                              ; preds = %122, %79, %108
  %126 = phi i32 [ %80, %79 ], [ %109, %108 ], [ %124, %122 ]
  %127 = icmp eq i32 %126, 0
  br i1 %127, label %128, label %129

128:                                              ; preds = %19, %125
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.351) #15
  br label %132

129:                                              ; preds = %53, %59, %125
  %130 = phi i32 [ %126, %125 ], [ 1, %59 ], [ 1, %53 ]
  store i1 true, ptr @_ZZL20nvrm_display_publishP9IOServicejE10gPublished, align 1
  %131 = load i32, ptr %3, align 4, !tbaa !18
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.352, i32 noundef %130, ptr noundef nonnull %6, i32 noundef %131) #15
  br label %132

132:                                              ; preds = %129, %128
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #18
  br label %133

133:                                              ; preds = %8, %132, %2
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @rm_isr(ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @rm_isr_bh(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM4stopEP9IOService(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  %3 = getelementptr inbounds i8, ptr %0, i64 188
  %4 = load i8, ptr %3, align 4, !tbaa !65, !range !14, !noundef !15
  %5 = trunc nuw i8 %4 to i1
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = load ptr, ptr %0, align 8, !tbaa !4
  %8 = getelementptr inbounds i8, ptr %7, i64 1944
  %9 = load ptr, ptr %8, align 8
  tail call void %9(ptr noundef nonnull %0) #15
  store i8 0, ptr %3, align 4, !tbaa !65
  br label %10

10:                                               ; preds = %6, %2
  %11 = getelementptr inbounds i8, ptr %0, i64 1265
  %12 = load i8, ptr %11, align 1, !tbaa !76, !range !14, !noundef !15
  %13 = trunc nuw i8 %12 to i1
  br i1 %13, label %14, label %16

14:                                               ; preds = %10
  %15 = getelementptr inbounds i8, ptr %0, i64 336
  tail call void @rm_shutdown_adapter(ptr noundef null, ptr noundef nonnull %15) #15
  store i8 0, ptr %11, align 1, !tbaa !76
  br label %16

16:                                               ; preds = %14, %10
  %17 = getelementptr inbounds i8, ptr %0, i64 1280
  %18 = load ptr, ptr %17, align 8, !tbaa !129
  %19 = icmp eq ptr %18, null
  br i1 %19, label %38, label %20

20:                                               ; preds = %16
  %21 = load ptr, ptr %18, align 8, !tbaa !4
  %22 = getelementptr inbounds i8, ptr %21, i64 344
  %23 = load ptr, ptr %22, align 8
  tail call void %23(ptr noundef nonnull %18) #15
  %24 = getelementptr inbounds i8, ptr %0, i64 1272
  %25 = load ptr, ptr %24, align 8, !tbaa !128
  %26 = icmp eq ptr %25, null
  br i1 %26, label %33, label %27

27:                                               ; preds = %20
  %28 = load ptr, ptr %17, align 8, !tbaa !129
  %29 = load ptr, ptr %25, align 8, !tbaa !4
  %30 = getelementptr inbounds i8, ptr %29, i64 328
  %31 = load ptr, ptr %30, align 8
  %32 = tail call i32 %31(ptr noundef nonnull %25, ptr noundef %28) #15
  br label %33

33:                                               ; preds = %27, %20
  %34 = load ptr, ptr %17, align 8, !tbaa !129
  %35 = load ptr, ptr %34, align 8, !tbaa !4
  %36 = getelementptr inbounds i8, ptr %35, i64 40
  %37 = load ptr, ptr %36, align 8
  tail call void %37(ptr noundef nonnull %34) #15
  store ptr null, ptr %17, align 8, !tbaa !129
  br label %38

38:                                               ; preds = %33, %16
  %39 = getelementptr inbounds i8, ptr %0, i64 1272
  %40 = load ptr, ptr %39, align 8, !tbaa !128
  %41 = icmp eq ptr %40, null
  br i1 %41, label %46, label %42

42:                                               ; preds = %38
  %43 = load ptr, ptr %40, align 8, !tbaa !4
  %44 = getelementptr inbounds i8, ptr %43, i64 40
  %45 = load ptr, ptr %44, align 8
  tail call void %45(ptr noundef nonnull %40) #15
  store ptr null, ptr %39, align 8, !tbaa !128
  br label %46

46:                                               ; preds = %42, %38
  %47 = getelementptr inbounds i8, ptr %0, i64 1264
  %48 = load i8, ptr %47, align 8, !tbaa !75, !range !14, !noundef !15
  %49 = trunc nuw i8 %48 to i1
  br i1 %49, label %50, label %52

50:                                               ; preds = %46
  %51 = getelementptr inbounds i8, ptr %0, i64 336
  tail call void @rm_free_private_state(ptr noundef null, ptr noundef nonnull %51) #15
  store i8 0, ptr %47, align 8, !tbaa !75
  br label %52

52:                                               ; preds = %50, %46
  %53 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV9IOService, i64 1496), align 8
  tail call void %53(ptr noundef nonnull %0, ptr noundef %1) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @rm_shutdown_adapter(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @rm_free_private_state(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @_ZN4NVRM13setPowerStateEmP9IOService(ptr noundef %0, i64 noundef %1, ptr nocapture readnone %2) unnamed_addr #1 align 2 {
  %4 = getelementptr inbounds i8, ptr %0, i64 184
  %5 = tail call i32 @OSAddAtomic(i32 noundef 0, ptr noundef nonnull %4) #15
  %6 = icmp eq i64 %1, 0
  %7 = icmp eq i32 %5, 0
  %8 = select i1 %6, i1 %7, i1 false
  br i1 %8, label %9, label %22

9:                                                ; preds = %3
  %10 = getelementptr inbounds i8, ptr %0, i64 1265
  %11 = load i8, ptr %10, align 1, !tbaa !76, !range !14, !noundef !15
  %12 = trunc nuw i8 %11 to i1
  br i1 %12, label %13, label %33

13:                                               ; preds = %9
  %14 = tail call zeroext i1 @_ZN4NVRM10gpuSuspendEv(ptr noundef nonnull %0) #17
  br i1 %14, label %41, label %15

15:                                               ; preds = %13
  %16 = load ptr, ptr @kOSBooleanTrue, align 8, !tbaa !10
  %17 = load ptr, ptr %16, align 8, !tbaa !10
  %18 = load ptr, ptr %0, align 8, !tbaa !4
  %19 = getelementptr inbounds i8, ptr %18, i64 616
  %20 = load ptr, ptr %19, align 8
  %21 = tail call zeroext i1 %20(ptr noundef nonnull %0, ptr noundef nonnull @.str.234, ptr noundef %17) #15
  br label %41

22:                                               ; preds = %3
  %23 = icmp ne i64 %1, 0
  %24 = icmp eq i32 %5, 1
  %25 = select i1 %23, i1 %24, i1 false
  br i1 %25, label %32, label %26

26:                                               ; preds = %22
  %27 = getelementptr inbounds i8, ptr %0, i64 1265
  %28 = load i8, ptr %27, align 1, !tbaa !76, !range !14
  %29 = trunc nuw i8 %28 to i1
  %30 = select i1 %24, ptr @.str.236, ptr @.str.237
  %31 = select i1 %29, ptr @.str.83, ptr @.str.238
  br label %33

32:                                               ; preds = %22
  tail call void @_ZN4NVRM9gpuResumeEv(ptr noundef %0) #17
  br label %41

33:                                               ; preds = %26, %9
  %34 = phi ptr [ %31, %26 ], [ @.str.238, %9 ]
  %35 = phi ptr [ %30, %26 ], [ @.str.237, %9 ]
  %36 = select i1 %7, ptr @.str.47, ptr %35
  %37 = getelementptr inbounds i8, ptr %0, i64 1265
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.235, i64 noundef %1, ptr noundef nonnull %36, ptr noundef nonnull %34) #15
  %38 = load i8, ptr %37, align 1, !tbaa !76, !range !14, !noundef !15
  %39 = trunc nuw i8 %38 to i1
  %40 = select i1 %39, ptr @.str.83, ptr @.str.238
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.235, i64 noundef %1, ptr noundef nonnull %36, ptr noundef nonnull %40) #15
  br label %41

41:                                               ; preds = %32, %33, %13, %15
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @OSAddAtomic(i32 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i1 @_ZN4NVRM10gpuSuspendEv(ptr noundef %0) local_unnamed_addr #1 align 2 {
  %2 = alloca i64, align 8
  %3 = alloca i32, align 4
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = tail call i64 @mach_absolute_time() #15
  %7 = getelementptr inbounds i8, ptr %0, i64 192
  %8 = load i32, ptr %7, align 8, !tbaa !66
  %9 = add i32 %8, 1
  store i32 %9, ptr %7, align 8, !tbaa !66
  %10 = getelementptr inbounds i8, ptr %0, i64 184
  %11 = tail call zeroext i1 @OSCompareAndSwap(i32 noundef 0, i32 noundef 1, ptr noundef nonnull %10) #15
  %12 = load ptr, ptr %0, align 8, !tbaa !4
  %13 = getelementptr inbounds i8, ptr %12, i64 624
  %14 = load ptr, ptr %13, align 8
  %15 = tail call zeroext i1 %14(ptr noundef nonnull %0, ptr noundef nonnull @.str.44, ptr noundef nonnull @.str.236) #15
  %16 = load i32, ptr %7, align 8, !tbaa !66
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.239, i32 noundef %16) #15
  %17 = load i32, ptr %7, align 8, !tbaa !66
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.239, i32 noundef %17) #15
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #18
  store i32 0, ptr %3, align 4, !tbaa !18
  %18 = call zeroext i8 @nvkms_xnu_suspend_begin(ptr noundef nonnull %3) #15
  %19 = icmp eq i8 %18, 0
  br i1 %19, label %20, label %28

20:                                               ; preds = %1
  %21 = call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef 0, ptr noundef nonnull %10) #15
  %22 = load ptr, ptr %0, align 8, !tbaa !4
  %23 = getelementptr inbounds i8, ptr %22, i64 624
  %24 = load ptr, ptr %23, align 8
  %25 = call zeroext i1 %24(ptr noundef nonnull %0, ptr noundef nonnull @.str.44, ptr noundef nonnull @.str.47) #15
  %26 = load i32, ptr %7, align 8, !tbaa !66
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.240, i32 noundef %26) #15
  %27 = load i32, ptr %7, align 8, !tbaa !66
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.240, i32 noundef %27) #15
  br label %101

28:                                               ; preds = %1
  call void @_ZN4NVRM18notifyFramebuffersEm(ptr noundef nonnull %0, i64 noundef 0) #17
  %29 = getelementptr inbounds i8, ptr %0, i64 336
  %30 = getelementptr inbounds i8, ptr %0, i64 372
  %31 = load i32, ptr %30, align 4, !tbaa !132
  %32 = load i32, ptr %3, align 4, !tbaa !18
  %33 = call zeroext i8 @nvkms_xnu_suspend_commit(i32 noundef %31, i32 noundef %32, i32 noundef 60000) #15
  %34 = icmp eq i8 %33, 0
  br i1 %34, label %35, label %56

35:                                               ; preds = %28
  %36 = load i32, ptr %3, align 4, !tbaa !18
  call void @nvkms_xnu_suspend_abort(i32 noundef %36) #15
  %37 = call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef 0, ptr noundef nonnull %10) #15
  %38 = load ptr, ptr %0, align 8, !tbaa !4
  %39 = getelementptr inbounds i8, ptr %38, i64 624
  %40 = load ptr, ptr %39, align 8
  %41 = call zeroext i1 %40(ptr noundef nonnull %0, ptr noundef nonnull @.str.44, ptr noundef nonnull @.str.47) #15
  %42 = load ptr, ptr @kOSBooleanTrue, align 8, !tbaa !10
  %43 = load ptr, ptr %42, align 8, !tbaa !10
  %44 = load ptr, ptr %0, align 8, !tbaa !4
  %45 = getelementptr inbounds i8, ptr %44, i64 616
  %46 = load ptr, ptr %45, align 8
  %47 = call zeroext i1 %46(ptr noundef nonnull %0, ptr noundef nonnull @.str.234, ptr noundef %43) #15
  call void @_ZN4NVRM18notifyFramebuffersEm(ptr noundef nonnull %0, i64 noundef 1) #17
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #18
  store i64 0, ptr %4, align 8, !tbaa !7
  %48 = call i64 @mach_absolute_time() #15
  %49 = sub i64 %48, %6
  call void @absolutetime_to_nanoseconds(i64 noundef %49, ptr noundef nonnull %4) #15
  %50 = load i32, ptr %7, align 8, !tbaa !66
  %51 = load i64, ptr %4, align 8, !tbaa !7
  %52 = udiv i64 %51, 1000000
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.241, i32 noundef %50, i64 noundef %52) #15
  %53 = load i32, ptr %7, align 8, !tbaa !66
  %54 = load i64, ptr %4, align 8, !tbaa !7
  %55 = udiv i64 %54, 1000000
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.241, i32 noundef %53, i64 noundef %55) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #18
  br label %101

56:                                               ; preds = %28
  %57 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  %58 = icmp eq ptr %57, null
  br i1 %58, label %76, label %59

59:                                               ; preds = %56
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #18
  store i64 0, ptr %2, align 8, !annotation !77
  call void @clock_interval_to_deadline(i32 noundef 10000, i32 noundef 1000000, ptr noundef nonnull %2) #15
  %60 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  call void @IOLockLock(ptr noundef %60) #15
  store i8 1, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12
  %61 = tail call ptr @current_thread() #16
  store ptr %61, ptr @_ZL10gNvPmOwner, align 8, !tbaa !10
  %62 = load i32, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %63 = icmp sgt i32 %62, 0
  br i1 %63, label %64, label %72

64:                                               ; preds = %59, %64
  %65 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  %66 = load i64, ptr %2, align 8, !tbaa !7
  %67 = call i32 @"\01_IOLockSleepDeadline_darwin14"(ptr noundef %65, ptr noundef nonnull @_ZL10gNvPmUsers, i64 noundef %66, i32 noundef 0) #15
  %68 = icmp ne i32 %67, 1
  %69 = load i32, ptr @_ZL10gNvPmUsers, align 4
  %70 = icmp sgt i32 %69, 0
  %71 = select i1 %68, i1 %70, i1 false
  br i1 %71, label %64, label %72, !llvm.loop !138

72:                                               ; preds = %64, %59
  %73 = phi i32 [ %62, %59 ], [ %69, %64 ]
  %74 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  call void @IOLockUnlock(ptr noundef %74) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #18
  %75 = icmp eq i32 %73, 0
  br i1 %75, label %80, label %76

76:                                               ; preds = %56, %72
  %77 = phi i32 [ %73, %72 ], [ -1, %56 ]
  %78 = load i32, ptr %7, align 8, !tbaa !66
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.242, i32 noundef %78, i32 noundef %77) #15
  %79 = load i32, ptr %7, align 8, !tbaa !66
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.242, i32 noundef %79, i32 noundef %77) #15
  br label %80

80:                                               ; preds = %76, %72
  %81 = call i32 @rm_stop_user_channels(ptr noundef null, ptr noundef nonnull %29) #15
  call void @_ZN4NVRM15pciSaveForSleepEv(ptr noundef nonnull %0) #17
  %82 = call i32 @rm_power_management(ptr noundef null, ptr noundef nonnull %29, i32 noundef 1) #15
  %83 = getelementptr inbounds i8, ptr %0, i64 1280
  %84 = load ptr, ptr %83, align 8, !tbaa !129
  %85 = icmp eq ptr %84, null
  br i1 %85, label %90, label %86

86:                                               ; preds = %80
  %87 = load ptr, ptr %84, align 8, !tbaa !4
  %88 = getelementptr inbounds i8, ptr %87, i64 344
  %89 = load ptr, ptr %88, align 8
  call void %89(ptr noundef nonnull %84) #15
  br label %90

90:                                               ; preds = %86, %80
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 0, ptr %5, align 8, !tbaa !7
  %91 = call i64 @mach_absolute_time() #15
  %92 = sub i64 %91, %6
  call void @absolutetime_to_nanoseconds(i64 noundef %92, ptr noundef nonnull %5) #15
  %93 = load i32, ptr %7, align 8, !tbaa !66
  %94 = load i64, ptr %5, align 8, !tbaa !7
  %95 = udiv i64 %94, 1000000
  %96 = icmp eq i32 %82, 0
  %97 = select i1 %96, ptr @.str.65, ptr @.str.244
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.243, i32 noundef %93, i32 noundef %81, i32 noundef %82, i64 noundef %95, ptr noundef nonnull %97) #15
  %98 = load i32, ptr %7, align 8, !tbaa !66
  %99 = load i64, ptr %5, align 8, !tbaa !7
  %100 = udiv i64 %99, 1000000
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.243, i32 noundef %98, i32 noundef %81, i32 noundef %82, i64 noundef %100, ptr noundef nonnull %97) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  br label %101

101:                                              ; preds = %90, %35, %20
  %102 = phi i1 [ true, %90 ], [ false, %35 ], [ false, %20 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #18
  ret i1 %102
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM9gpuResumeEv(ptr noundef %0) local_unnamed_addr #1 align 2 {
  %2 = alloca i64, align 8
  %3 = tail call i64 @mach_absolute_time() #15
  %4 = getelementptr inbounds i8, ptr %0, i64 192
  %5 = load i32, ptr %4, align 8, !tbaa !66
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.245, i32 noundef %5) #15
  %6 = load i32, ptr %4, align 8, !tbaa !66
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.245, i32 noundef %6) #15
  %7 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  %8 = icmp eq ptr %7, null
  br i1 %8, label %12, label %9

9:                                                ; preds = %1
  tail call void @IOLockLock(ptr noundef nonnull %7) #15
  %10 = tail call ptr @current_thread() #16
  store ptr %10, ptr @_ZL10gNvPmOwner, align 8, !tbaa !10
  %11 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %11) #15
  br label %12

12:                                               ; preds = %1, %9
  %13 = tail call zeroext i1 @_ZN4NVRM19pciRestoreAfterWakeEv(ptr noundef nonnull %0) #17
  br i1 %13, label %14, label %16

14:                                               ; preds = %12
  %15 = tail call zeroext i1 @_ZN4NVRM10gpuAnswersEv(ptr noundef nonnull %0) #17
  br label %16

16:                                               ; preds = %14, %12
  %17 = phi i1 [ false, %12 ], [ %15, %14 ]
  %18 = getelementptr inbounds i8, ptr %0, i64 1280
  %19 = load ptr, ptr %18, align 8, !tbaa !129
  %20 = icmp eq ptr %19, null
  br i1 %20, label %25, label %21

21:                                               ; preds = %16
  %22 = load ptr, ptr %19, align 8, !tbaa !4
  %23 = getelementptr inbounds i8, ptr %22, i64 336
  %24 = load ptr, ptr %23, align 8
  tail call void %24(ptr noundef nonnull %19) #15
  br label %25

25:                                               ; preds = %21, %16
  br i1 %17, label %26, label %32

26:                                               ; preds = %25
  %27 = getelementptr inbounds i8, ptr %0, i64 336
  %28 = tail call i32 @rm_power_management(ptr noundef null, ptr noundef nonnull %27, i32 noundef 2) #15
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %30, label %32

30:                                               ; preds = %26
  %31 = tail call i32 @rm_restart_user_channels(ptr noundef null, ptr noundef nonnull %27) #15
  br label %32

32:                                               ; preds = %25, %26, %30
  %33 = phi i8 [ 1, %30 ], [ 0, %26 ], [ 0, %25 ]
  %34 = phi i32 [ 0, %30 ], [ %28, %26 ], [ 15, %25 ]
  %35 = phi i64 [ 1, %30 ], [ 2, %26 ], [ 2, %25 ]
  %36 = phi ptr [ @.str.248, %30 ], [ @.str.249, %26 ], [ @.str.249, %25 ]
  %37 = phi ptr [ @.str.47, %30 ], [ @.str.246, %26 ], [ @.str.246, %25 ]
  %38 = phi i32 [ 0, %30 ], [ 2, %26 ], [ 2, %25 ]
  %39 = phi i32 [ %31, %30 ], [ 15, %26 ], [ 15, %25 ]
  %40 = getelementptr inbounds i8, ptr %0, i64 184
  %41 = tail call zeroext i1 @OSCompareAndSwap(i32 noundef 1, i32 noundef %38, ptr noundef nonnull %40) #15
  %42 = getelementptr inbounds i8, ptr %0, i64 372
  %43 = load i32, ptr %42, align 4, !tbaa !132
  tail call void @nvkms_xnu_resume(i32 noundef %43, i8 noundef zeroext %33) #15
  %44 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  %45 = icmp eq ptr %44, null
  br i1 %45, label %49, label %46

46:                                               ; preds = %32
  tail call void @IOLockLock(ptr noundef nonnull %44) #15
  store i8 0, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12
  store ptr null, ptr @_ZL10gNvPmOwner, align 8, !tbaa !10
  %47 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @"\01_IOLockWakeup_darwin14"(ptr noundef %47, ptr noundef nonnull @_ZL11gNvPmClosed, i1 noundef zeroext false) #15
  %48 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %48) #15
  br label %49

49:                                               ; preds = %32, %46
  %50 = load ptr, ptr %0, align 8, !tbaa !4
  %51 = getelementptr inbounds i8, ptr %50, i64 624
  %52 = load ptr, ptr %51, align 8
  %53 = tail call zeroext i1 %52(ptr noundef nonnull %0, ptr noundef nonnull @.str.44, ptr noundef nonnull %37) #15
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #18
  store i64 0, ptr %2, align 8, !tbaa !7
  %54 = tail call i64 @mach_absolute_time() #15
  %55 = sub i64 %54, %3
  call void @absolutetime_to_nanoseconds(i64 noundef %55, ptr noundef nonnull %2) #15
  %56 = load i32, ptr %4, align 8, !tbaa !66
  %57 = load i64, ptr %2, align 8, !tbaa !7
  %58 = udiv i64 %57, 1000000
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.247, i32 noundef %56, i32 noundef %34, i32 noundef %39, i64 noundef %58, ptr noundef nonnull %36) #15
  %59 = load i32, ptr %4, align 8, !tbaa !66
  %60 = load i64, ptr %2, align 8, !tbaa !7
  %61 = udiv i64 %60, 1000000
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.247, i32 noundef %59, i32 noundef %34, i32 noundef %39, i64 noundef %61, ptr noundef nonnull %36) #15
  call void @_ZN4NVRM18notifyFramebuffersEm(ptr noundef nonnull %0, i64 noundef %35) #17
  %62 = load i64, ptr @_ZL19gNvKmsCloseDeferred, align 8, !tbaa !7
  %63 = icmp sgt i64 %62, 0
  br i1 %63, label %64, label %74

64:                                               ; preds = %49
  %65 = load ptr, ptr %0, align 8, !tbaa !4
  %66 = getelementptr inbounds i8, ptr %65, i64 32
  %67 = load ptr, ptr %66, align 8
  call void %67(ptr noundef nonnull %0) #15
  %68 = call i32 @nv_xnu_retry_kms_bridge_closes() #17
  %69 = load i32, ptr %4, align 8, !tbaa !66
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.250, i32 noundef %69, i32 noundef %68) #15
  %70 = load i32, ptr %4, align 8, !tbaa !66
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.250, i32 noundef %70, i32 noundef %68) #15
  %71 = load ptr, ptr %0, align 8, !tbaa !4
  %72 = getelementptr inbounds i8, ptr %71, i64 40
  %73 = load ptr, ptr %72, align 8
  call void %73(ptr noundef nonnull %0) #15
  br label %74

74:                                               ; preds = %64, %49
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #18
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @nvkms_xnu_suspend_begin(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM18notifyFramebuffersEm(ptr noundef %0, i64 noundef %1) local_unnamed_addr #1 align 2 {
  %3 = tail call ptr @_ZN8OSSymbol11withCStringEPKc(ptr noundef nonnull @.str.264) #15
  %4 = load ptr, ptr @gIOServicePlane, align 8, !tbaa !10
  %5 = load ptr, ptr %0, align 8, !tbaa !4
  %6 = getelementptr inbounds i8, ptr %5, i64 800
  %7 = load ptr, ptr %6, align 8
  %8 = tail call ptr %7(ptr noundef nonnull %0, ptr noundef %4) #15
  %9 = icmp ne ptr %3, null
  %10 = icmp ne ptr %8, null
  %11 = select i1 %9, i1 %10, i1 false
  br i1 %11, label %12, label %66

12:                                               ; preds = %2
  %13 = load ptr, ptr @_ZN9IOService9metaClassE, align 8
  %14 = inttoptr i64 %1 to ptr
  %15 = load ptr, ptr %8, align 8, !tbaa !4
  %16 = getelementptr inbounds i8, ptr %15, i64 296
  %17 = load ptr, ptr %16, align 8
  %18 = tail call ptr %17(ptr noundef nonnull %8) #15
  %19 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %18, ptr noundef %13) #15
  %20 = icmp eq ptr %19, null
  br i1 %20, label %67, label %21

21:                                               ; preds = %12, %58
  %22 = phi ptr [ %64, %58 ], [ %19, %12 ]
  %23 = phi i32 [ %59, %58 ], [ 0, %12 ]
  %24 = load ptr, ptr @gIOServicePlane, align 8, !tbaa !10
  %25 = load ptr, ptr %22, align 8, !tbaa !4
  %26 = getelementptr inbounds i8, ptr %25, i64 800
  %27 = load ptr, ptr %26, align 8
  %28 = tail call ptr %27(ptr noundef nonnull %22, ptr noundef %24) #15
  %29 = icmp eq ptr %28, null
  br i1 %29, label %58, label %30

30:                                               ; preds = %21
  %31 = load ptr, ptr %28, align 8, !tbaa !4
  %32 = getelementptr inbounds i8, ptr %31, i64 296
  %33 = load ptr, ptr %32, align 8
  %34 = tail call ptr %33(ptr noundef nonnull %28) #15
  %35 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %34, ptr noundef %13) #15
  %36 = icmp eq ptr %35, null
  br i1 %36, label %53, label %37

37:                                               ; preds = %30, %37
  %38 = phi ptr [ %51, %37 ], [ %35, %30 ]
  %39 = phi i32 [ %46, %37 ], [ %23, %30 ]
  %40 = load ptr, ptr %38, align 8, !tbaa !4
  %41 = getelementptr inbounds i8, ptr %40, i64 1720
  %42 = load ptr, ptr %41, align 8
  %43 = tail call i32 %42(ptr noundef nonnull %38, ptr noundef nonnull %3, i1 noundef zeroext false, ptr noundef %14, ptr noundef null, ptr noundef null, ptr noundef null) #15
  %44 = icmp eq i32 %43, 0
  %45 = zext i1 %44 to i32
  %46 = add i32 %39, %45
  %47 = load ptr, ptr %28, align 8, !tbaa !4
  %48 = getelementptr inbounds i8, ptr %47, i64 296
  %49 = load ptr, ptr %48, align 8
  %50 = tail call ptr %49(ptr noundef nonnull %28) #15
  %51 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %50, ptr noundef %13) #15
  %52 = icmp eq ptr %51, null
  br i1 %52, label %53, label %37

53:                                               ; preds = %37, %30
  %54 = phi i32 [ %23, %30 ], [ %46, %37 ]
  %55 = load ptr, ptr %28, align 8, !tbaa !4
  %56 = getelementptr inbounds i8, ptr %55, i64 40
  %57 = load ptr, ptr %56, align 8
  tail call void %57(ptr noundef nonnull %28) #15
  br label %58

58:                                               ; preds = %21, %53
  %59 = phi i32 [ %54, %53 ], [ %23, %21 ]
  %60 = load ptr, ptr %8, align 8, !tbaa !4
  %61 = getelementptr inbounds i8, ptr %60, i64 296
  %62 = load ptr, ptr %61, align 8
  %63 = tail call ptr %62(ptr noundef nonnull %8) #15
  %64 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %63, ptr noundef %13) #15
  %65 = icmp eq ptr %64, null
  br i1 %65, label %67, label %21

66:                                               ; preds = %2
  br i1 %10, label %67, label %72

67:                                               ; preds = %58, %12, %66
  %68 = phi i32 [ 0, %66 ], [ 0, %12 ], [ %59, %58 ]
  %69 = load ptr, ptr %8, align 8, !tbaa !4
  %70 = getelementptr inbounds i8, ptr %69, i64 40
  %71 = load ptr, ptr %70, align 8
  tail call void %71(ptr noundef nonnull %8) #15
  br label %72

72:                                               ; preds = %67, %66
  %73 = phi i32 [ %68, %67 ], [ 0, %66 ]
  br i1 %9, label %74, label %78

74:                                               ; preds = %72
  %75 = load ptr, ptr %3, align 8, !tbaa !4
  %76 = getelementptr inbounds i8, ptr %75, i64 40
  %77 = load ptr, ptr %76, align 8
  tail call void %77(ptr noundef nonnull %3) #15
  br label %78

78:                                               ; preds = %74, %72
  %79 = icmp eq i64 %1, 0
  %80 = icmp eq i64 %1, 1
  %81 = select i1 %80, ptr @.str.267, ptr @.str.237
  %82 = select i1 %79, ptr @.str.266, ptr %81
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.265, i32 noundef %73, ptr noundef nonnull %82) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.265, i32 noundef %73, ptr noundef nonnull %82) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @nvkms_xnu_suspend_commit(i32 noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @nvkms_xnu_suspend_abort(i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_stop_user_channels(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN4NVRM15pciSaveForSleepEv(ptr nocapture noundef %0) local_unnamed_addr #1 align 2 {
  %2 = getelementptr inbounds i8, ptr %0, i64 200
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(128) %2, i8 0, i64 128, i1 false)
  %3 = getelementptr inbounds i8, ptr %0, i64 328
  %4 = load ptr, ptr %3, align 8, !tbaa !78
  %5 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %4, i64 noundef 4) #15
  %6 = getelementptr inbounds i8, ptr %0, i64 280
  store i16 %5, ptr %6, align 8, !tbaa !139
  %7 = getelementptr inbounds i8, ptr %0, i64 256
  %8 = load ptr, ptr %3, align 8, !tbaa !78
  %9 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %8, i64 noundef 16) #15
  store i32 %9, ptr %7, align 4, !tbaa !18
  %10 = load ptr, ptr %3, align 8, !tbaa !78
  %11 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %10, i64 noundef 20) #15
  %12 = getelementptr inbounds i8, ptr %0, i64 260
  store i32 %11, ptr %12, align 4, !tbaa !18
  %13 = load ptr, ptr %3, align 8, !tbaa !78
  %14 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %13, i64 noundef 24) #15
  %15 = getelementptr inbounds i8, ptr %0, i64 264
  store i32 %14, ptr %15, align 4, !tbaa !18
  %16 = load ptr, ptr %3, align 8, !tbaa !78
  %17 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %16, i64 noundef 28) #15
  %18 = getelementptr inbounds i8, ptr %0, i64 268
  store i32 %17, ptr %18, align 4, !tbaa !18
  %19 = load ptr, ptr %3, align 8, !tbaa !78
  %20 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %19, i64 noundef 32) #15
  %21 = getelementptr inbounds i8, ptr %0, i64 272
  store i32 %20, ptr %21, align 4, !tbaa !18
  %22 = load ptr, ptr %3, align 8, !tbaa !78
  %23 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %22, i64 noundef 36) #15
  %24 = getelementptr inbounds i8, ptr %0, i64 276
  store i32 %23, ptr %24, align 4, !tbaa !18
  br label %25

25:                                               ; preds = %1, %62
  %26 = phi i32 [ %63, %62 ], [ 256, %1 ]
  %27 = phi i32 [ %64, %62 ], [ 0, %1 ]
  %28 = load ptr, ptr %3, align 8, !tbaa !78
  %29 = zext nneg i32 %26 to i64
  %30 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %28, i64 noundef %29) #15
  %31 = add i32 %30, 1
  %32 = icmp ult i32 %31, 2
  br i1 %32, label %68, label %33

33:                                               ; preds = %25
  %34 = and i32 %30, 65535
  %35 = icmp eq i32 %34, 21
  br i1 %35, label %36, label %62

36:                                               ; preds = %33
  %37 = load ptr, ptr %3, align 8, !tbaa !78
  %38 = add nuw nsw i32 %26, 8
  %39 = zext nneg i32 %38 to i64
  %40 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %37, i64 noundef %39) #15
  %41 = lshr i32 %40, 5
  %42 = and i32 %41, 7
  %43 = tail call i32 @llvm.umin.i32(i32 %42, i32 6)
  %44 = icmp eq i32 %42, 0
  br i1 %44, label %49, label %45

45:                                               ; preds = %36
  %46 = getelementptr inbounds i8, ptr %0, i64 204
  %47 = getelementptr inbounds i8, ptr %0, i64 228
  %48 = zext nneg i32 %43 to i64
  br label %51

49:                                               ; preds = %51, %36
  %50 = getelementptr inbounds i8, ptr %0, i64 252
  store i32 %43, ptr %50, align 4, !tbaa !140
  br label %68

51:                                               ; preds = %45, %51
  %52 = phi i64 [ 0, %45 ], [ %60, %51 ]
  %53 = shl nuw nsw i64 %52, 3
  %54 = add nuw nsw i64 %53, %39
  %55 = getelementptr inbounds [6 x i32], ptr %46, i64 0, i64 %52
  %56 = trunc nuw nsw i64 %54 to i32
  store i32 %56, ptr %55, align 4, !tbaa !18
  %57 = load ptr, ptr %3, align 8, !tbaa !78
  %58 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %57, i64 noundef %54) #15
  %59 = getelementptr inbounds [6 x i32], ptr %47, i64 0, i64 %52
  store i32 %58, ptr %59, align 4, !tbaa !18
  %60 = add nuw nsw i64 %52, 1
  %61 = icmp eq i64 %60, %48
  br i1 %61, label %49, label %51, !llvm.loop !141

62:                                               ; preds = %33
  %63 = lshr i32 %30, 20
  %64 = add nuw nsw i32 %27, 1
  %65 = icmp ugt i32 %30, 268435455
  %66 = icmp ult i32 %27, 63
  %67 = select i1 %65, i1 %66, i1 false
  br i1 %67, label %25, label %68, !llvm.loop !142

68:                                               ; preds = %25, %62, %49
  %69 = load ptr, ptr %3, align 8, !tbaa !78
  %70 = load ptr, ptr %69, align 8, !tbaa !4
  %71 = getelementptr inbounds i8, ptr %70, i64 1664
  %72 = load ptr, ptr %71, align 8
  %73 = tail call ptr %72(ptr noundef nonnull %69) #15
  %74 = icmp eq ptr %73, null
  br i1 %74, label %75, label %77

75:                                               ; preds = %68
  %76 = getelementptr inbounds i8, ptr %0, i64 288
  store ptr null, ptr %76, align 8, !tbaa !143
  br label %108

77:                                               ; preds = %68
  %78 = load ptr, ptr %73, align 8, !tbaa !4
  %79 = getelementptr inbounds i8, ptr %78, i64 1664
  %80 = load ptr, ptr %79, align 8
  %81 = tail call ptr %80(ptr noundef nonnull %73) #15
  %82 = load ptr, ptr @_ZN11IOPCIDevice9metaClassE, align 8, !tbaa !10
  %83 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %81, ptr noundef %82) #15
  %84 = getelementptr inbounds i8, ptr %0, i64 288
  store ptr %83, ptr %84, align 8, !tbaa !143
  %85 = icmp eq ptr %83, null
  br i1 %85, label %108, label %86

86:                                               ; preds = %77
  %87 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef nonnull %83, i64 noundef 4) #15
  %88 = getelementptr inbounds i8, ptr %0, i64 320
  store i16 %87, ptr %88, align 8, !tbaa !144
  %89 = getelementptr inbounds i8, ptr %0, i64 296
  %90 = load ptr, ptr %84, align 8, !tbaa !143
  %91 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %90, i64 noundef 24) #15
  store i32 %91, ptr %89, align 4, !tbaa !18
  %92 = load ptr, ptr %84, align 8, !tbaa !143
  %93 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %92, i64 noundef 28) #15
  %94 = getelementptr inbounds i8, ptr %0, i64 300
  store i32 %93, ptr %94, align 4, !tbaa !18
  %95 = load ptr, ptr %84, align 8, !tbaa !143
  %96 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %95, i64 noundef 32) #15
  %97 = getelementptr inbounds i8, ptr %0, i64 304
  store i32 %96, ptr %97, align 4, !tbaa !18
  %98 = load ptr, ptr %84, align 8, !tbaa !143
  %99 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %98, i64 noundef 36) #15
  %100 = getelementptr inbounds i8, ptr %0, i64 308
  store i32 %99, ptr %100, align 4, !tbaa !18
  %101 = load ptr, ptr %84, align 8, !tbaa !143
  %102 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %101, i64 noundef 40) #15
  %103 = getelementptr inbounds i8, ptr %0, i64 312
  store i32 %102, ptr %103, align 4, !tbaa !18
  %104 = load ptr, ptr %84, align 8, !tbaa !143
  %105 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %104, i64 noundef 44) #15
  %106 = getelementptr inbounds i8, ptr %0, i64 316
  store i32 %105, ptr %106, align 4, !tbaa !18
  %107 = load ptr, ptr %84, align 8, !tbaa !143
  br label %108

108:                                              ; preds = %86, %75, %77
  %109 = phi ptr [ null, %75 ], [ null, %77 ], [ %107, %86 ]
  %110 = phi ptr [ %76, %75 ], [ %84, %77 ], [ %84, %86 ]
  store i8 1, ptr %2, align 8, !tbaa !67
  %111 = load i16, ptr %6, align 8, !tbaa !139
  %112 = zext i16 %111 to i32
  %113 = load i32, ptr %15, align 8, !tbaa !18
  %114 = load i32, ptr %12, align 4, !tbaa !18
  %115 = and i32 %114, -16
  %116 = getelementptr inbounds i8, ptr %0, i64 252
  %117 = load i32, ptr %116, align 4, !tbaa !140
  %118 = icmp eq ptr %109, null
  br i1 %118, label %124, label %119

119:                                              ; preds = %108
  %120 = load ptr, ptr %109, align 8, !tbaa !4
  %121 = getelementptr inbounds i8, ptr %120, i64 904
  %122 = load ptr, ptr %121, align 8
  %123 = tail call ptr %122(ptr noundef nonnull %109, ptr noundef null) #15
  br label %124

124:                                              ; preds = %108, %119
  %125 = phi ptr [ %123, %119 ], [ @.str.252, %108 ]
  %126 = getelementptr inbounds i8, ptr %0, i64 308
  %127 = load i32, ptr %126, align 4, !tbaa !18
  %128 = getelementptr inbounds i8, ptr %0, i64 312
  %129 = load i32, ptr %128, align 8, !tbaa !18
  %130 = getelementptr inbounds i8, ptr %0, i64 316
  %131 = load i32, ptr %130, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.251, i32 noundef %112, i32 noundef %113, i32 noundef %115, i32 noundef %117, ptr noundef %125, i32 noundef %127, i32 noundef %129, i32 noundef %131) #15
  %132 = load i16, ptr %6, align 8, !tbaa !139
  %133 = load i32, ptr %15, align 8, !tbaa !18
  %134 = load i32, ptr %12, align 4, !tbaa !18
  %135 = load i32, ptr %116, align 4, !tbaa !140
  %136 = load ptr, ptr %110, align 8, !tbaa !143
  %137 = icmp eq ptr %136, null
  br i1 %137, label %143, label %138

138:                                              ; preds = %124
  %139 = load ptr, ptr %136, align 8, !tbaa !4
  %140 = getelementptr inbounds i8, ptr %139, i64 904
  %141 = load ptr, ptr %140, align 8
  %142 = tail call ptr %141(ptr noundef nonnull %136, ptr noundef null) #15
  br label %143

143:                                              ; preds = %124, %138
  %144 = phi ptr [ %142, %138 ], [ @.str.252, %124 ]
  %145 = and i32 %134, -16
  %146 = zext i16 %132 to i32
  %147 = load i32, ptr %126, align 4, !tbaa !18
  %148 = load i32, ptr %128, align 8, !tbaa !18
  %149 = load i32, ptr %130, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.251, i32 noundef %146, i32 noundef %133, i32 noundef %145, i32 noundef %135, ptr noundef %144, i32 noundef %147, i32 noundef %148, i32 noundef %149) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_power_management(ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define zeroext i1 @_ZN4NVRM19pciRestoreAfterWakeEv(ptr nocapture noundef readonly %0) local_unnamed_addr #1 align 2 {
  %2 = getelementptr inbounds i8, ptr %0, i64 200
  %3 = load i8, ptr %2, align 8, !tbaa !67, !range !14, !noundef !15
  %4 = trunc nuw i8 %3 to i1
  br i1 %4, label %6, label %5

5:                                                ; preds = %1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.253) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.253) #15
  br label %301

6:                                                ; preds = %1
  %7 = getelementptr inbounds i8, ptr %0, i64 328
  %8 = load ptr, ptr %7, align 8, !tbaa !78
  %9 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %8, i64 noundef 0) #15
  %10 = icmp eq i16 %9, 4318
  br i1 %10, label %18, label %11

11:                                               ; preds = %6
  %12 = load ptr, ptr %7, align 8, !tbaa !78
  %13 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %12, i64 noundef 0) #15
  %14 = zext i16 %13 to i32
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.254, i32 noundef %14) #15
  %15 = load ptr, ptr %7, align 8, !tbaa !78
  %16 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %15, i64 noundef 0) #15
  %17 = zext i16 %16 to i32
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.254, i32 noundef %17) #15
  br label %301

18:                                               ; preds = %6
  %19 = getelementptr inbounds i8, ptr %0, i64 288
  %20 = load ptr, ptr %19, align 8, !tbaa !143
  %21 = icmp eq ptr %20, null
  br i1 %21, label %104, label %22

22:                                               ; preds = %18
  %23 = getelementptr inbounds i8, ptr %0, i64 296
  %24 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef nonnull %20, i64 noundef 24) #15
  %25 = load i32, ptr %23, align 4, !tbaa !18
  %26 = icmp ne i32 %25, %24
  br i1 %26, label %27, label %29

27:                                               ; preds = %22
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.255, i32 noundef 24, i32 noundef %24, i32 noundef %25) #15
  %28 = load i32, ptr %23, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.255, i32 noundef 24, i32 noundef %24, i32 noundef %28) #15
  br label %29

29:                                               ; preds = %27, %22
  %30 = load ptr, ptr %19, align 8, !tbaa !143
  %31 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %30, i64 noundef 28) #15
  %32 = getelementptr inbounds i8, ptr %0, i64 300
  %33 = load i32, ptr %32, align 4, !tbaa !18
  %34 = xor i32 %33, %31
  %35 = and i32 %34, 65535
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %39, label %37

37:                                               ; preds = %29
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.255, i32 noundef 28, i32 noundef %31, i32 noundef %33) #15
  %38 = load i32, ptr %32, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.255, i32 noundef 28, i32 noundef %31, i32 noundef %38) #15
  br label %39

39:                                               ; preds = %37, %29
  %40 = phi i1 [ true, %37 ], [ %26, %29 ]
  %41 = load ptr, ptr %19, align 8, !tbaa !143
  %42 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %41, i64 noundef 32) #15
  %43 = getelementptr inbounds i8, ptr %0, i64 304
  %44 = load i32, ptr %43, align 4, !tbaa !18
  %45 = icmp eq i32 %44, %42
  br i1 %45, label %48, label %46

46:                                               ; preds = %39
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.255, i32 noundef 32, i32 noundef %42, i32 noundef %44) #15
  %47 = load i32, ptr %43, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.255, i32 noundef 32, i32 noundef %42, i32 noundef %47) #15
  br label %48

48:                                               ; preds = %46, %39
  %49 = phi i1 [ true, %46 ], [ %40, %39 ]
  %50 = load ptr, ptr %19, align 8, !tbaa !143
  %51 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %50, i64 noundef 36) #15
  %52 = getelementptr inbounds i8, ptr %0, i64 308
  %53 = load i32, ptr %52, align 4, !tbaa !18
  %54 = icmp eq i32 %53, %51
  br i1 %54, label %57, label %55

55:                                               ; preds = %48
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.255, i32 noundef 36, i32 noundef %51, i32 noundef %53) #15
  %56 = load i32, ptr %52, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.255, i32 noundef 36, i32 noundef %51, i32 noundef %56) #15
  br label %57

57:                                               ; preds = %55, %48
  %58 = phi i1 [ true, %55 ], [ %49, %48 ]
  %59 = load ptr, ptr %19, align 8, !tbaa !143
  %60 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %59, i64 noundef 40) #15
  %61 = getelementptr inbounds i8, ptr %0, i64 312
  %62 = load i32, ptr %61, align 4, !tbaa !18
  %63 = icmp eq i32 %62, %60
  br i1 %63, label %66, label %64

64:                                               ; preds = %57
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.255, i32 noundef 40, i32 noundef %60, i32 noundef %62) #15
  %65 = load i32, ptr %61, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.255, i32 noundef 40, i32 noundef %60, i32 noundef %65) #15
  br label %66

66:                                               ; preds = %64, %57
  %67 = phi i1 [ true, %64 ], [ %58, %57 ]
  %68 = load ptr, ptr %19, align 8, !tbaa !143
  %69 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %68, i64 noundef 44) #15
  %70 = getelementptr inbounds i8, ptr %0, i64 316
  %71 = load i32, ptr %70, align 4, !tbaa !18
  %72 = icmp eq i32 %71, %69
  br i1 %72, label %75, label %73

73:                                               ; preds = %66
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.255, i32 noundef 44, i32 noundef %69, i32 noundef %71) #15
  %74 = load i32, ptr %70, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.255, i32 noundef 44, i32 noundef %69, i32 noundef %74) #15
  br label %76

75:                                               ; preds = %66
  br i1 %67, label %76, label %91

76:                                               ; preds = %73, %75
  %77 = load ptr, ptr %19, align 8, !tbaa !143
  %78 = load i32, ptr %23, align 8, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %77, i64 noundef 24, i32 noundef %78) #15
  %79 = load ptr, ptr %19, align 8, !tbaa !143
  %80 = load i32, ptr %32, align 4, !tbaa !18
  %81 = trunc i32 %80 to i16
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %79, i64 noundef 28, i16 noundef zeroext %81) #15
  %82 = load ptr, ptr %19, align 8, !tbaa !143
  %83 = load i32, ptr %43, align 8, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %82, i64 noundef 32, i32 noundef %83) #15
  %84 = load ptr, ptr %19, align 8, !tbaa !143
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %84, i64 noundef 36, i32 noundef 65520) #15
  %85 = load ptr, ptr %19, align 8, !tbaa !143
  %86 = load i32, ptr %61, align 8, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %85, i64 noundef 40, i32 noundef %86) #15
  %87 = load ptr, ptr %19, align 8, !tbaa !143
  %88 = load i32, ptr %70, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %87, i64 noundef 44, i32 noundef %88) #15
  %89 = load ptr, ptr %19, align 8, !tbaa !143
  %90 = load i32, ptr %52, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %89, i64 noundef 36, i32 noundef %90) #15
  br label %91

91:                                               ; preds = %76, %75
  %92 = phi i32 [ 1, %76 ], [ 0, %75 ]
  %93 = load ptr, ptr %19, align 8, !tbaa !143
  %94 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %93, i64 noundef 4) #15
  %95 = and i16 %94, 6
  %96 = getelementptr inbounds i8, ptr %0, i64 320
  %97 = load i16, ptr %96, align 8, !tbaa !144
  %98 = and i16 %97, 6
  %99 = icmp eq i16 %95, %98
  br i1 %99, label %104, label %100

100:                                              ; preds = %91
  %101 = load ptr, ptr %19, align 8, !tbaa !143
  %102 = or i16 %98, %94
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %101, i64 noundef 4, i16 noundef zeroext %102) #15
  %103 = add nuw nsw i32 %92, 1
  br label %104

104:                                              ; preds = %91, %100, %18
  %105 = phi i32 [ 0, %18 ], [ %103, %100 ], [ %92, %91 ]
  %106 = getelementptr inbounds i8, ptr %0, i64 252
  %107 = load i32, ptr %106, align 4, !tbaa !140
  %108 = icmp eq i32 %107, 0
  br i1 %108, label %112, label %109

109:                                              ; preds = %104
  %110 = getelementptr inbounds i8, ptr %0, i64 204
  %111 = getelementptr inbounds i8, ptr %0, i64 228
  br label %119

112:                                              ; preds = %136, %104
  %113 = phi i1 [ false, %104 ], [ %137, %136 ]
  %114 = getelementptr inbounds i8, ptr %0, i64 256
  %115 = load ptr, ptr %7, align 8, !tbaa !78
  %116 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %115, i64 noundef 16) #15
  %117 = load i32, ptr %114, align 4, !tbaa !18
  %118 = icmp eq i32 %116, %117
  br i1 %118, label %144, label %142

119:                                              ; preds = %109, %136
  %120 = phi i64 [ 0, %109 ], [ %138, %136 ]
  %121 = phi i1 [ false, %109 ], [ %137, %136 ]
  %122 = load ptr, ptr %7, align 8, !tbaa !78
  %123 = getelementptr inbounds [6 x i32], ptr %110, i64 0, i64 %120
  %124 = load i32, ptr %123, align 4, !tbaa !18
  %125 = zext i32 %124 to i64
  %126 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %122, i64 noundef %125) #15
  %127 = getelementptr inbounds [6 x i32], ptr %111, i64 0, i64 %120
  %128 = load i32, ptr %127, align 4, !tbaa !18
  %129 = xor i32 %128, %126
  %130 = and i32 %129, 16128
  %131 = icmp eq i32 %130, 0
  br i1 %131, label %136, label %132

132:                                              ; preds = %119
  %133 = load i32, ptr %123, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.256, i32 noundef %133, i32 noundef %126, i32 noundef %128) #15
  %134 = load i32, ptr %123, align 4, !tbaa !18
  %135 = load i32, ptr %127, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.256, i32 noundef %134, i32 noundef %126, i32 noundef %135) #15
  br label %136

136:                                              ; preds = %132, %119
  %137 = phi i1 [ true, %132 ], [ %121, %119 ]
  %138 = add nuw nsw i64 %120, 1
  %139 = load i32, ptr %106, align 4, !tbaa !140
  %140 = zext i32 %139 to i64
  %141 = icmp ult i64 %138, %140
  br i1 %141, label %119, label %112, !llvm.loop !145

142:                                              ; preds = %112
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.257, i32 noundef 16, i32 noundef %116, i32 noundef %117) #15
  %143 = load i32, ptr %114, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.257, i32 noundef 16, i32 noundef %116, i32 noundef %143) #15
  br label %144

144:                                              ; preds = %142, %112
  %145 = phi i1 [ true, %142 ], [ %113, %112 ]
  %146 = load ptr, ptr %7, align 8, !tbaa !78
  %147 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %146, i64 noundef 20) #15
  %148 = getelementptr inbounds i8, ptr %0, i64 260
  %149 = load i32, ptr %148, align 4, !tbaa !18
  %150 = icmp eq i32 %147, %149
  br i1 %150, label %153, label %151

151:                                              ; preds = %144
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.257, i32 noundef 20, i32 noundef %147, i32 noundef %149) #15
  %152 = load i32, ptr %148, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.257, i32 noundef 20, i32 noundef %147, i32 noundef %152) #15
  br label %153

153:                                              ; preds = %151, %144
  %154 = phi i1 [ true, %151 ], [ %145, %144 ]
  %155 = load ptr, ptr %7, align 8, !tbaa !78
  %156 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %155, i64 noundef 24) #15
  %157 = getelementptr inbounds i8, ptr %0, i64 264
  %158 = load i32, ptr %157, align 4, !tbaa !18
  %159 = icmp eq i32 %156, %158
  br i1 %159, label %162, label %160

160:                                              ; preds = %153
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.257, i32 noundef 24, i32 noundef %156, i32 noundef %158) #15
  %161 = load i32, ptr %157, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.257, i32 noundef 24, i32 noundef %156, i32 noundef %161) #15
  br label %162

162:                                              ; preds = %160, %153
  %163 = phi i1 [ true, %160 ], [ %154, %153 ]
  %164 = load ptr, ptr %7, align 8, !tbaa !78
  %165 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %164, i64 noundef 28) #15
  %166 = getelementptr inbounds i8, ptr %0, i64 268
  %167 = load i32, ptr %166, align 4, !tbaa !18
  %168 = icmp eq i32 %165, %167
  br i1 %168, label %171, label %169

169:                                              ; preds = %162
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.257, i32 noundef 28, i32 noundef %165, i32 noundef %167) #15
  %170 = load i32, ptr %166, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.257, i32 noundef 28, i32 noundef %165, i32 noundef %170) #15
  br label %171

171:                                              ; preds = %169, %162
  %172 = phi i1 [ true, %169 ], [ %163, %162 ]
  %173 = load ptr, ptr %7, align 8, !tbaa !78
  %174 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %173, i64 noundef 32) #15
  %175 = getelementptr inbounds i8, ptr %0, i64 272
  %176 = load i32, ptr %175, align 4, !tbaa !18
  %177 = icmp eq i32 %174, %176
  br i1 %177, label %180, label %178

178:                                              ; preds = %171
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.257, i32 noundef 32, i32 noundef %174, i32 noundef %176) #15
  %179 = load i32, ptr %175, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.257, i32 noundef 32, i32 noundef %174, i32 noundef %179) #15
  br label %180

180:                                              ; preds = %178, %171
  %181 = phi i1 [ true, %178 ], [ %172, %171 ]
  %182 = load ptr, ptr %7, align 8, !tbaa !78
  %183 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %182, i64 noundef 36) #15
  %184 = getelementptr inbounds i8, ptr %0, i64 276
  %185 = load i32, ptr %184, align 4, !tbaa !18
  %186 = icmp eq i32 %183, %185
  br i1 %186, label %189, label %187

187:                                              ; preds = %180
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.257, i32 noundef 36, i32 noundef %183, i32 noundef %185) #15
  %188 = load i32, ptr %184, align 4, !tbaa !18
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.257, i32 noundef 36, i32 noundef %183, i32 noundef %188) #15
  br label %190

189:                                              ; preds = %180
  br i1 %181, label %190, label %226

190:                                              ; preds = %187, %189
  %191 = load ptr, ptr %7, align 8, !tbaa !78
  %192 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %191, i64 noundef 4) #15
  %193 = load ptr, ptr %7, align 8, !tbaa !78
  %194 = and i16 %192, -3
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %193, i64 noundef 4, i16 noundef zeroext %194) #15
  %195 = load i32, ptr %106, align 4, !tbaa !140
  %196 = icmp eq i32 %195, 0
  br i1 %196, label %200, label %197

197:                                              ; preds = %190
  %198 = getelementptr inbounds i8, ptr %0, i64 204
  %199 = getelementptr inbounds i8, ptr %0, i64 228
  br label %214

200:                                              ; preds = %214, %190
  %201 = load ptr, ptr %7, align 8, !tbaa !78
  %202 = load i32, ptr %114, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %201, i64 noundef 16, i32 noundef %202) #15
  %203 = load ptr, ptr %7, align 8, !tbaa !78
  %204 = load i32, ptr %148, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %203, i64 noundef 20, i32 noundef %204) #15
  %205 = load ptr, ptr %7, align 8, !tbaa !78
  %206 = load i32, ptr %157, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %205, i64 noundef 24, i32 noundef %206) #15
  %207 = load ptr, ptr %7, align 8, !tbaa !78
  %208 = load i32, ptr %166, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %207, i64 noundef 28, i32 noundef %208) #15
  %209 = load ptr, ptr %7, align 8, !tbaa !78
  %210 = load i32, ptr %175, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %209, i64 noundef 32, i32 noundef %210) #15
  %211 = load ptr, ptr %7, align 8, !tbaa !78
  %212 = load i32, ptr %184, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %211, i64 noundef 36, i32 noundef %212) #15
  %213 = add nuw nsw i32 %105, 1
  br label %226

214:                                              ; preds = %197, %214
  %215 = phi i64 [ 0, %197 ], [ %222, %214 ]
  %216 = load ptr, ptr %7, align 8, !tbaa !78
  %217 = getelementptr inbounds [6 x i32], ptr %198, i64 0, i64 %215
  %218 = load i32, ptr %217, align 4, !tbaa !18
  %219 = zext i32 %218 to i64
  %220 = getelementptr inbounds [6 x i32], ptr %199, i64 0, i64 %215
  %221 = load i32, ptr %220, align 4, !tbaa !18
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %216, i64 noundef %219, i32 noundef %221) #15
  %222 = add nuw nsw i64 %215, 1
  %223 = load i32, ptr %106, align 4, !tbaa !140
  %224 = zext i32 %223 to i64
  %225 = icmp ult i64 %222, %224
  br i1 %225, label %214, label %200, !llvm.loop !146

226:                                              ; preds = %200, %189
  %227 = phi i32 [ %213, %200 ], [ %105, %189 ]
  %228 = load ptr, ptr %7, align 8, !tbaa !78
  %229 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %228, i64 noundef 4) #15
  %230 = and i16 %229, 6
  %231 = getelementptr inbounds i8, ptr %0, i64 280
  %232 = load i16, ptr %231, align 8, !tbaa !139
  %233 = and i16 %232, 6
  %234 = icmp eq i16 %230, %233
  br i1 %234, label %238, label %235

235:                                              ; preds = %226
  %236 = load ptr, ptr %7, align 8, !tbaa !78
  %237 = or i16 %233, %229
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %236, i64 noundef 4, i16 noundef zeroext %237) #15
  br label %238

238:                                              ; preds = %235, %226
  %239 = load i32, ptr %106, align 4, !tbaa !140
  %240 = icmp eq i32 %239, 0
  br i1 %240, label %244, label %241

241:                                              ; preds = %238
  %242 = getelementptr inbounds i8, ptr %0, i64 204
  %243 = getelementptr inbounds i8, ptr %0, i64 228
  br label %283

244:                                              ; preds = %283, %238
  %245 = phi i1 [ true, %238 ], [ %296, %283 ]
  %246 = load ptr, ptr %7, align 8, !tbaa !78
  %247 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %246, i64 noundef 16) #15
  %248 = load i32, ptr %114, align 4, !tbaa !18
  %249 = icmp eq i32 %247, %248
  %250 = load ptr, ptr %7, align 8, !tbaa !78
  %251 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %250, i64 noundef 20) #15
  %252 = load i32, ptr %148, align 4, !tbaa !18
  %253 = icmp eq i32 %251, %252
  %254 = load ptr, ptr %7, align 8, !tbaa !78
  %255 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %254, i64 noundef 24) #15
  %256 = load i32, ptr %157, align 4, !tbaa !18
  %257 = icmp eq i32 %255, %256
  %258 = load ptr, ptr %7, align 8, !tbaa !78
  %259 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %258, i64 noundef 28) #15
  %260 = load i32, ptr %166, align 4, !tbaa !18
  %261 = icmp eq i32 %259, %260
  %262 = load ptr, ptr %7, align 8, !tbaa !78
  %263 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %262, i64 noundef 32) #15
  %264 = load i32, ptr %175, align 4, !tbaa !18
  %265 = icmp eq i32 %263, %264
  %266 = load ptr, ptr %7, align 8, !tbaa !78
  %267 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %266, i64 noundef 36) #15
  %268 = load i32, ptr %184, align 4, !tbaa !18
  %269 = icmp eq i32 %267, %268
  %270 = select i1 %269, i1 %265, i1 false
  %271 = select i1 %270, i1 %261, i1 false
  %272 = select i1 %271, i1 %257, i1 false
  %273 = select i1 %272, i1 %253, i1 false
  %274 = select i1 %273, i1 %249, i1 false
  %275 = select i1 %274, i1 %245, i1 false
  %276 = select i1 %275, ptr @.str.259, ptr @.str.260
  %277 = load ptr, ptr %7, align 8, !tbaa !78
  %278 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %277, i64 noundef 4) #15
  %279 = zext i16 %278 to i32
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.258, ptr noundef nonnull %276, i32 noundef %227, i32 noundef %279) #15
  %280 = load ptr, ptr %7, align 8, !tbaa !78
  %281 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %280, i64 noundef 4) #15
  %282 = zext i16 %281 to i32
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.258, ptr noundef nonnull %276, i32 noundef %227, i32 noundef %282) #15
  br label %301

283:                                              ; preds = %241, %283
  %284 = phi i64 [ 0, %241 ], [ %297, %283 ]
  %285 = phi i1 [ true, %241 ], [ %296, %283 ]
  %286 = load ptr, ptr %7, align 8, !tbaa !78
  %287 = getelementptr inbounds [6 x i32], ptr %242, i64 0, i64 %284
  %288 = load i32, ptr %287, align 4, !tbaa !18
  %289 = zext i32 %288 to i64
  %290 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %286, i64 noundef %289) #15
  %291 = getelementptr inbounds [6 x i32], ptr %243, i64 0, i64 %284
  %292 = load i32, ptr %291, align 4, !tbaa !18
  %293 = xor i32 %292, %290
  %294 = and i32 %293, 16128
  %295 = icmp eq i32 %294, 0
  %296 = select i1 %295, i1 %285, i1 false
  %297 = add nuw nsw i64 %284, 1
  %298 = load i32, ptr %106, align 4, !tbaa !140
  %299 = zext i32 %298 to i64
  %300 = icmp ult i64 %297, %299
  br i1 %300, label %283, label %244, !llvm.loop !147

301:                                              ; preds = %244, %11, %5
  %302 = phi i1 [ false, %11 ], [ %275, %244 ], [ true, %5 ]
  ret i1 %302
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i1 @_ZN4NVRM10gpuAnswersEv(ptr nocapture noundef readonly %0) local_unnamed_addr #1 align 2 {
  %2 = getelementptr inbounds i8, ptr %0, i64 488
  %3 = load i64, ptr %2, align 8, !tbaa !114
  %4 = icmp ult i64 %3, 4096
  br i1 %4, label %36, label %5

5:                                                ; preds = %1
  %6 = getelementptr inbounds i8, ptr %0, i64 480
  %7 = load i64, ptr %6, align 8, !tbaa !113
  %8 = tail call ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef %7, i64 noundef 4096, i32 noundef 3) #15
  %9 = icmp eq ptr %8, null
  br i1 %9, label %31, label %10

10:                                               ; preds = %5
  %11 = load ptr, ptr %8, align 8, !tbaa !4
  %12 = getelementptr inbounds i8, ptr %11, i64 512
  %13 = load ptr, ptr %12, align 8
  %14 = tail call ptr %13(ptr noundef nonnull %8, i32 noundef 256) #15
  %15 = icmp eq ptr %14, null
  br i1 %15, label %26, label %16

16:                                               ; preds = %10
  %17 = load ptr, ptr %14, align 8, !tbaa !4
  %18 = getelementptr inbounds i8, ptr %17, i64 280
  %19 = load ptr, ptr %18, align 8
  %20 = tail call i64 %19(ptr noundef nonnull %14) #15
  %21 = inttoptr i64 %20 to ptr
  %22 = load volatile i32, ptr %21, align 4, !tbaa !18
  %23 = load ptr, ptr %14, align 8, !tbaa !4
  %24 = getelementptr inbounds i8, ptr %23, i64 40
  %25 = load ptr, ptr %24, align 8
  tail call void %25(ptr noundef nonnull %14) #15
  br label %26

26:                                               ; preds = %10, %16
  %27 = phi i32 [ %22, %16 ], [ -1, %10 ]
  %28 = load ptr, ptr %8, align 8, !tbaa !4
  %29 = getelementptr inbounds i8, ptr %28, i64 40
  %30 = load ptr, ptr %29, align 8
  tail call void %30(ptr noundef nonnull %8) #15
  br label %31

31:                                               ; preds = %5, %26
  %32 = phi i32 [ %27, %26 ], [ -1, %5 ]
  %33 = add i32 %32, -1
  %34 = icmp ult i32 %33, -2
  %35 = select i1 %34, ptr @.str.262, ptr @.str.263
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.261, i32 noundef %32, ptr noundef nonnull %35) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.261, i32 noundef %32, ptr noundef nonnull %35) #15
  br label %36

36:                                               ; preds = %1, %31
  %37 = phi i1 [ %34, %31 ], [ true, %1 ]
  ret i1 %37
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_restart_user_channels(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @nvkms_xnu_resume(i32 noundef, i8 noundef zeroext) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @nv_xnu_retry_kms_bridge_closes() local_unnamed_addr #1 {
  %1 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  %2 = icmp eq ptr %1, null
  br i1 %2, label %42, label %3

3:                                                ; preds = %0, %38
  %4 = phi i64 [ %40, %38 ], [ 0, %0 ]
  %5 = phi i32 [ %39, %38 ], [ 0, %0 ]
  %6 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockLock(ptr noundef %6) #15
  %7 = getelementptr inbounds [32768 x ptr], ptr @_ZL10gNvClients, i64 0, i64 %4
  %8 = load ptr, ptr %7, align 8, !tbaa !10
  %9 = icmp eq ptr %8, null
  br i1 %9, label %36, label %10

10:                                               ; preds = %3
  %11 = load ptr, ptr %8, align 8, !tbaa !4
  %12 = getelementptr inbounds i8, ptr %11, i64 32
  %13 = load ptr, ptr %12, align 8
  tail call void %13(ptr noundef nonnull %8) #15
  %14 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %14) #15
  %15 = getelementptr inbounds i8, ptr %8, i64 464
  %16 = load ptr, ptr %15, align 8, !tbaa !148
  %17 = icmp eq ptr %16, null
  br i1 %17, label %30, label %18

18:                                               ; preds = %10
  tail call void @IOLockLock(ptr noundef nonnull %16) #15
  %19 = getelementptr inbounds i8, ptr %8, i64 473
  %20 = load i8, ptr %19, align 1, !tbaa !149, !range !14, !noundef !15
  %21 = trunc nuw i8 %20 to i1
  tail call void @IOLockUnlock(ptr noundef nonnull %16) #15
  br i1 %21, label %22, label %30

22:                                               ; preds = %18
  %23 = load ptr, ptr %8, align 8, !tbaa !4
  %24 = getelementptr inbounds i8, ptr %23, i64 2288
  %25 = load ptr, ptr %24, align 8
  %26 = tail call i32 %25(ptr noundef nonnull %8) #15
  %27 = freeze i32 %26
  %28 = icmp eq i32 %27, 0
  %29 = add nsw i32 %5, 1
  br i1 %28, label %30, label %31

30:                                               ; preds = %10, %18, %22
  br label %31

31:                                               ; preds = %22, %30
  %32 = phi i32 [ %5, %30 ], [ %29, %22 ]
  %33 = load ptr, ptr %8, align 8, !tbaa !4
  %34 = getelementptr inbounds i8, ptr %33, i64 40
  %35 = load ptr, ptr %34, align 8
  tail call void %35(ptr noundef nonnull %8) #15
  br label %38

36:                                               ; preds = %3
  %37 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %37) #15
  br label %38

38:                                               ; preds = %36, %31
  %39 = phi i32 [ %32, %31 ], [ %5, %36 ]
  %40 = add nuw nsw i64 %4, 1
  %41 = icmp eq i64 %40, 32768
  br i1 %41, label %42, label %3, !llvm.loop !150

42:                                               ; preds = %38, %0
  %43 = phi i32 [ 0, %0 ], [ %39, %38 ]
  ret i32 %43
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN8OSSymbol11withCStringEPKc(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClient9MetaClassC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str.269, ptr noundef nonnull @_ZN12IOUserClient10gMetaClassE, i32 noundef 488) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN14NVRMUserClient9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN14NVRMUserClient9MetaClassD1Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV14NVRMUserClient, i64 16), ptr %0, align 8, !tbaa !4
  %3 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %3, align 8, !tbaa !151
  %4 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %4, align 8, !tbaa !152
  %5 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %5, align 8, !tbaa !153
  %6 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %6, align 4, !tbaa !154
  %7 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %7, align 8, !tbaa !155
  %8 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %8, i8 0, i64 64, i1 false)
  %9 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %9, align 8, !tbaa !156
  %10 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %10, align 8, !tbaa !157
  %11 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %11, align 8, !tbaa !158
  %12 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %12, align 4, !tbaa !159
  %13 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %13, align 8, !tbaa !160
  %14 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %14, align 8, !tbaa !161
  %15 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %15, align 8, !tbaa !162
  %16 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %16, align 8, !tbaa !163
  %17 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %17, align 8, !tbaa !164
  %18 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %18, align 8, !tbaa !165
  %19 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %19, align 8, !tbaa !166
  %20 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %20, align 8, !tbaa !167
  %21 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %21, align 8, !tbaa !168
  %22 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %22, align 8, !tbaa !169
  %23 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %23, align 4, !tbaa !170
  %24 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %24, align 8, !tbaa !171
  %25 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %25, align 8, !tbaa !42
  %26 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %26, align 4, !tbaa !40
  %27 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %27, align 8, !tbaa !26
  %28 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %28, align 4, !tbaa !39
  %29 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %29, align 8, !tbaa !37
  %30 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %30, align 4, !tbaa !172
  %31 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %31, align 8, !tbaa !173
  %32 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %32, align 8, !tbaa !148
  %33 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %33, align 8, !tbaa !174
  %34 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %34, align 1, !tbaa !149
  %35 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %35, align 4, !tbaa !175
  %36 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %36, align 8, !tbaa !176
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientC1EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV14NVRMUserClient, i64 16), ptr %0, align 8, !tbaa !4
  %3 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %3, align 8, !tbaa !151
  %4 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %4, align 8, !tbaa !152
  %5 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %5, align 8, !tbaa !153
  %6 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %6, align 4, !tbaa !154
  %7 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %7, align 8, !tbaa !155
  %8 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %8, i8 0, i64 64, i1 false)
  %9 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %9, align 8, !tbaa !156
  %10 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %10, align 8, !tbaa !157
  %11 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %11, align 8, !tbaa !158
  %12 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %12, align 4, !tbaa !159
  %13 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %13, align 8, !tbaa !160
  %14 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %14, align 8, !tbaa !161
  %15 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %15, align 8, !tbaa !162
  %16 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %16, align 8, !tbaa !163
  %17 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %17, align 8, !tbaa !164
  %18 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %18, align 8, !tbaa !165
  %19 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %19, align 8, !tbaa !166
  %20 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %20, align 8, !tbaa !167
  %21 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %21, align 8, !tbaa !168
  %22 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %22, align 8, !tbaa !169
  %23 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %23, align 4, !tbaa !170
  %24 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %24, align 8, !tbaa !171
  %25 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %25, align 8, !tbaa !42
  %26 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %26, align 4, !tbaa !40
  %27 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %27, align 8, !tbaa !26
  %28 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %28, align 4, !tbaa !39
  %29 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %29, align 8, !tbaa !37
  %30 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %30, align 4, !tbaa !172
  %31 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %31, align 8, !tbaa !173
  %32 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %32, align 8, !tbaa !148
  %33 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %33, align 8, !tbaa !174
  %34 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %34, align 1, !tbaa !149
  %35 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %35, align 4, !tbaa !175
  %36 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %36, align 8, !tbaa !176
  ret void
}

; Function Attrs: alwaysinline mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientD2Ev(ptr noundef %0) unnamed_addr #4 align 2 {
  tail call void @_ZN12IOUserClientD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone nounwind
declare void @_ZN12IOUserClientD2Ev(ptr noundef) unnamed_addr #5

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientD1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientD0Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientD2Ev(ptr noundef %0) #15
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef 488) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientdlEPvm(ptr noundef %0, i64 noundef %1) local_unnamed_addr #1 align 2 {
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef %1) #15
  ret void
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef nonnull ptr @_ZNK14NVRMUserClient12getMetaClassEv(ptr nocapture readnone %0) unnamed_addr #0 align 2 {
  ret ptr @_ZN14NVRMUserClient10gMetaClassE
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClient9MetaClassC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str.269, ptr noundef nonnull @_ZN12IOUserClient10gMetaClassE, i32 noundef 488) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN14NVRMUserClient9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef ptr @_ZNK14NVRMUserClient9MetaClass5allocEv(ptr nocapture readnone %0) unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef 488) #15
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %2, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV14NVRMUserClient, i64 16), ptr %2, align 8, !tbaa !4
  %3 = getelementptr inbounds i8, ptr %2, i64 224
  store ptr null, ptr %3, align 8, !tbaa !151
  %4 = getelementptr inbounds i8, ptr %2, i64 232
  store ptr null, ptr %4, align 8, !tbaa !152
  %5 = getelementptr inbounds i8, ptr %2, i64 240
  store i16 0, ptr %5, align 8, !tbaa !153
  %6 = getelementptr inbounds i8, ptr %2, i64 244
  store i32 0, ptr %6, align 4, !tbaa !154
  %7 = getelementptr inbounds i8, ptr %2, i64 248
  store i32 0, ptr %7, align 8, !tbaa !155
  %8 = getelementptr inbounds i8, ptr %2, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %8, i8 0, i64 64, i1 false)
  %9 = getelementptr inbounds i8, ptr %2, i64 320
  store volatile ptr null, ptr %9, align 8, !tbaa !156
  %10 = getelementptr inbounds i8, ptr %2, i64 328
  store ptr null, ptr %10, align 8, !tbaa !157
  %11 = getelementptr inbounds i8, ptr %2, i64 336
  store volatile i32 0, ptr %11, align 8, !tbaa !158
  %12 = getelementptr inbounds i8, ptr %2, i64 340
  store volatile i32 0, ptr %12, align 4, !tbaa !159
  %13 = getelementptr inbounds i8, ptr %2, i64 344
  store i8 0, ptr %13, align 8, !tbaa !160
  %14 = getelementptr inbounds i8, ptr %2, i64 352
  store ptr null, ptr %14, align 8, !tbaa !161
  %15 = getelementptr inbounds i8, ptr %2, i64 360
  store i64 0, ptr %15, align 8, !tbaa !162
  %16 = getelementptr inbounds i8, ptr %2, i64 368
  store ptr null, ptr %16, align 8, !tbaa !163
  %17 = getelementptr inbounds i8, ptr %2, i64 376
  store i64 0, ptr %17, align 8, !tbaa !164
  %18 = getelementptr inbounds i8, ptr %2, i64 384
  store ptr null, ptr %18, align 8, !tbaa !165
  %19 = getelementptr inbounds i8, ptr %2, i64 392
  store i64 0, ptr %19, align 8, !tbaa !166
  %20 = getelementptr inbounds i8, ptr %2, i64 400
  store i64 0, ptr %20, align 8, !tbaa !167
  %21 = getelementptr inbounds i8, ptr %2, i64 408
  store i64 0, ptr %21, align 8, !tbaa !168
  %22 = getelementptr inbounds i8, ptr %2, i64 416
  store i32 0, ptr %22, align 8, !tbaa !169
  %23 = getelementptr inbounds i8, ptr %2, i64 420
  store i8 0, ptr %23, align 4, !tbaa !170
  %24 = getelementptr inbounds i8, ptr %2, i64 424
  store i32 0, ptr %24, align 8, !tbaa !171
  %25 = getelementptr inbounds i8, ptr %2, i64 432
  store i8 1, ptr %25, align 8, !tbaa !42
  %26 = getelementptr inbounds i8, ptr %2, i64 436
  store i32 -1, ptr %26, align 4, !tbaa !40
  %27 = getelementptr inbounds i8, ptr %2, i64 440
  store i32 0, ptr %27, align 8, !tbaa !26
  %28 = getelementptr inbounds i8, ptr %2, i64 444
  store i8 0, ptr %28, align 4, !tbaa !39
  %29 = getelementptr inbounds i8, ptr %2, i64 448
  store i32 -1, ptr %29, align 8, !tbaa !37
  %30 = getelementptr inbounds i8, ptr %2, i64 452
  store i8 0, ptr %30, align 4, !tbaa !172
  %31 = getelementptr inbounds i8, ptr %2, i64 456
  store ptr null, ptr %31, align 8, !tbaa !173
  %32 = getelementptr inbounds i8, ptr %2, i64 464
  store ptr null, ptr %32, align 8, !tbaa !148
  %33 = getelementptr inbounds i8, ptr %2, i64 472
  store i8 0, ptr %33, align 8, !tbaa !174
  %34 = getelementptr inbounds i8, ptr %2, i64 473
  store i8 0, ptr %34, align 1, !tbaa !149
  %35 = getelementptr inbounds i8, ptr %2, i64 476
  store volatile i32 0, ptr %35, align 4, !tbaa !175
  %36 = getelementptr inbounds i8, ptr %2, i64 480
  store i32 1314276694, ptr %36, align 8, !tbaa !176
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @_ZN14NVRMUserClientnwEm(i64 noundef %0) local_unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef %0) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV14NVRMUserClient, i64 16), ptr %0, align 8, !tbaa !4
  %2 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %2, align 8, !tbaa !151
  %3 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %3, align 8, !tbaa !152
  %4 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %4, align 8, !tbaa !153
  %5 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %5, align 4, !tbaa !154
  %6 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %6, align 8, !tbaa !155
  %7 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %7, i8 0, i64 64, i1 false)
  %8 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %8, align 8, !tbaa !156
  %9 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %9, align 8, !tbaa !157
  %10 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %10, align 8, !tbaa !158
  %11 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %11, align 4, !tbaa !159
  %12 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %12, align 8, !tbaa !160
  %13 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %13, align 8, !tbaa !161
  %14 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %14, align 8, !tbaa !162
  %15 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %15, align 8, !tbaa !163
  %16 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %16, align 8, !tbaa !164
  %17 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %17, align 8, !tbaa !165
  %18 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %18, align 8, !tbaa !166
  %19 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %19, align 8, !tbaa !167
  %20 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %20, align 8, !tbaa !168
  %21 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %21, align 8, !tbaa !169
  %22 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %22, align 4, !tbaa !170
  %23 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %23, align 8, !tbaa !171
  %24 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %24, align 8, !tbaa !42
  %25 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %25, align 4, !tbaa !40
  %26 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %26, align 8, !tbaa !26
  %27 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %27, align 4, !tbaa !39
  %28 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %28, align 8, !tbaa !37
  %29 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %29, align 4, !tbaa !172
  %30 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %30, align 8, !tbaa !173
  %31 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %31, align 8, !tbaa !148
  %32 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %32, align 8, !tbaa !174
  %33 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %33, align 1, !tbaa !149
  %34 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %34, align 4, !tbaa !175
  %35 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %35, align 8, !tbaa !176
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClientC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV14NVRMUserClient, i64 16), ptr %0, align 8, !tbaa !4
  %2 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %2, align 8, !tbaa !151
  %3 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %3, align 8, !tbaa !152
  %4 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %4, align 8, !tbaa !153
  %5 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %5, align 4, !tbaa !154
  %6 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %6, align 8, !tbaa !155
  %7 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %7, i8 0, i64 64, i1 false)
  %8 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %8, align 8, !tbaa !156
  %9 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %9, align 8, !tbaa !157
  %10 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %10, align 8, !tbaa !158
  %11 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %11, align 4, !tbaa !159
  %12 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %12, align 8, !tbaa !160
  %13 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %13, align 8, !tbaa !161
  %14 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %14, align 8, !tbaa !162
  %15 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %15, align 8, !tbaa !163
  %16 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %16, align 8, !tbaa !164
  %17 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %17, align 8, !tbaa !165
  %18 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %18, align 8, !tbaa !166
  %19 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %19, align 8, !tbaa !167
  %20 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %20, align 8, !tbaa !168
  %21 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %21, align 8, !tbaa !169
  %22 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %22, align 4, !tbaa !170
  %23 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %23, align 8, !tbaa !171
  %24 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %24, align 8, !tbaa !42
  %25 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %25, align 4, !tbaa !40
  %26 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %26, align 8, !tbaa !26
  %27 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %27, align 4, !tbaa !39
  %28 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %28, align 8, !tbaa !37
  %29 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %29, align 4, !tbaa !172
  %30 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %30, align 8, !tbaa !173
  %31 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %31, align 8, !tbaa !148
  %32 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %32, align 8, !tbaa !174
  %33 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %33, align 1, !tbaa !149
  %34 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %34, align 4, !tbaa !175
  %35 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %35, align 8, !tbaa !176
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridge9MetaClassC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str.271, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE, i32 noundef 488) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN17IOAccelNVRMBridge9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN17IOAccelNVRMBridge9MetaClassD1Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgeC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  %3 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %3, align 8, !tbaa !151
  %4 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %4, align 8, !tbaa !152
  %5 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %5, align 8, !tbaa !153
  %6 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %6, align 4, !tbaa !154
  %7 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %7, align 8, !tbaa !155
  %8 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %8, i8 0, i64 64, i1 false)
  %9 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %9, align 8, !tbaa !156
  %10 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %10, align 8, !tbaa !157
  %11 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %11, align 8, !tbaa !158
  %12 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %12, align 4, !tbaa !159
  %13 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %13, align 8, !tbaa !160
  %14 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %14, align 8, !tbaa !161
  %15 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %15, align 8, !tbaa !162
  %16 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %16, align 8, !tbaa !163
  %17 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %17, align 8, !tbaa !164
  %18 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %18, align 8, !tbaa !165
  %19 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %19, align 8, !tbaa !166
  %20 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %20, align 8, !tbaa !167
  %21 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %21, align 8, !tbaa !168
  %22 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %22, align 8, !tbaa !169
  %23 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %23, align 4, !tbaa !170
  %24 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %24, align 8, !tbaa !171
  %25 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %25, align 8, !tbaa !42
  %26 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %26, align 4, !tbaa !40
  %27 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %27, align 8, !tbaa !26
  %28 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %28, align 4, !tbaa !39
  %29 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %29, align 8, !tbaa !37
  %30 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %30, align 4, !tbaa !172
  %31 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %31, align 8, !tbaa !173
  %32 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %32, align 8, !tbaa !148
  %33 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %33, align 8, !tbaa !174
  %34 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %34, align 1, !tbaa !149
  %35 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %35, align 4, !tbaa !175
  %36 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %36, align 8, !tbaa !176
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV17IOAccelNVRMBridge, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgeC1EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef %1) #15
  %3 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %3, align 8, !tbaa !151
  %4 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %4, align 8, !tbaa !152
  %5 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %5, align 8, !tbaa !153
  %6 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %6, align 4, !tbaa !154
  %7 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %7, align 8, !tbaa !155
  %8 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %8, i8 0, i64 64, i1 false)
  %9 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %9, align 8, !tbaa !156
  %10 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %10, align 8, !tbaa !157
  %11 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %11, align 8, !tbaa !158
  %12 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %12, align 4, !tbaa !159
  %13 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %13, align 8, !tbaa !160
  %14 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %14, align 8, !tbaa !161
  %15 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %15, align 8, !tbaa !162
  %16 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %16, align 8, !tbaa !163
  %17 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %17, align 8, !tbaa !164
  %18 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %18, align 8, !tbaa !165
  %19 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %19, align 8, !tbaa !166
  %20 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %20, align 8, !tbaa !167
  %21 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %21, align 8, !tbaa !168
  %22 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %22, align 8, !tbaa !169
  %23 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %23, align 4, !tbaa !170
  %24 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %24, align 8, !tbaa !171
  %25 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %25, align 8, !tbaa !42
  %26 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %26, align 4, !tbaa !40
  %27 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %27, align 8, !tbaa !26
  %28 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %28, align 4, !tbaa !39
  %29 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %29, align 8, !tbaa !37
  %30 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %30, align 4, !tbaa !172
  %31 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %31, align 8, !tbaa !173
  %32 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %32, align 8, !tbaa !148
  %33 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %33, align 8, !tbaa !174
  %34 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %34, align 1, !tbaa !149
  %35 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %35, align 4, !tbaa !175
  %36 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %36, align 8, !tbaa !176
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV17IOAccelNVRMBridge, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: alwaysinline mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgeD2Ev(ptr noundef %0) unnamed_addr #4 align 2 {
  tail call void @_ZN12IOUserClientD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgeD1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgeD0Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientD2Ev(ptr noundef %0) #15
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef 488) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgedlEPvm(ptr noundef %0, i64 noundef %1) local_unnamed_addr #1 align 2 {
  tail call void @_ZN8OSObjectdlEPvm(ptr noundef %0, i64 noundef %1) #15
  ret void
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef nonnull ptr @_ZNK17IOAccelNVRMBridge12getMetaClassEv(ptr nocapture readnone %0) unnamed_addr #0 align 2 {
  ret ptr @_ZN17IOAccelNVRMBridge10gMetaClassE
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridge9MetaClassC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef %0, ptr noundef nonnull @.str.271, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE, i32 noundef 488) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN17IOAccelNVRMBridge9MetaClassE, i64 16), ptr %0, align 8, !tbaa !4
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef ptr @_ZNK17IOAccelNVRMBridge9MetaClass5allocEv(ptr nocapture readnone %0) unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef 488) #15
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %2, ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  %3 = getelementptr inbounds i8, ptr %2, i64 224
  store ptr null, ptr %3, align 8, !tbaa !151
  %4 = getelementptr inbounds i8, ptr %2, i64 232
  store ptr null, ptr %4, align 8, !tbaa !152
  %5 = getelementptr inbounds i8, ptr %2, i64 240
  store i16 0, ptr %5, align 8, !tbaa !153
  %6 = getelementptr inbounds i8, ptr %2, i64 244
  store i32 0, ptr %6, align 4, !tbaa !154
  %7 = getelementptr inbounds i8, ptr %2, i64 248
  store i32 0, ptr %7, align 8, !tbaa !155
  %8 = getelementptr inbounds i8, ptr %2, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %8, i8 0, i64 64, i1 false)
  %9 = getelementptr inbounds i8, ptr %2, i64 320
  store volatile ptr null, ptr %9, align 8, !tbaa !156
  %10 = getelementptr inbounds i8, ptr %2, i64 328
  store ptr null, ptr %10, align 8, !tbaa !157
  %11 = getelementptr inbounds i8, ptr %2, i64 336
  store volatile i32 0, ptr %11, align 8, !tbaa !158
  %12 = getelementptr inbounds i8, ptr %2, i64 340
  store volatile i32 0, ptr %12, align 4, !tbaa !159
  %13 = getelementptr inbounds i8, ptr %2, i64 344
  store i8 0, ptr %13, align 8, !tbaa !160
  %14 = getelementptr inbounds i8, ptr %2, i64 352
  store ptr null, ptr %14, align 8, !tbaa !161
  %15 = getelementptr inbounds i8, ptr %2, i64 360
  store i64 0, ptr %15, align 8, !tbaa !162
  %16 = getelementptr inbounds i8, ptr %2, i64 368
  store ptr null, ptr %16, align 8, !tbaa !163
  %17 = getelementptr inbounds i8, ptr %2, i64 376
  store i64 0, ptr %17, align 8, !tbaa !164
  %18 = getelementptr inbounds i8, ptr %2, i64 384
  store ptr null, ptr %18, align 8, !tbaa !165
  %19 = getelementptr inbounds i8, ptr %2, i64 392
  store i64 0, ptr %19, align 8, !tbaa !166
  %20 = getelementptr inbounds i8, ptr %2, i64 400
  store i64 0, ptr %20, align 8, !tbaa !167
  %21 = getelementptr inbounds i8, ptr %2, i64 408
  store i64 0, ptr %21, align 8, !tbaa !168
  %22 = getelementptr inbounds i8, ptr %2, i64 416
  store i32 0, ptr %22, align 8, !tbaa !169
  %23 = getelementptr inbounds i8, ptr %2, i64 420
  store i8 0, ptr %23, align 4, !tbaa !170
  %24 = getelementptr inbounds i8, ptr %2, i64 424
  store i32 0, ptr %24, align 8, !tbaa !171
  %25 = getelementptr inbounds i8, ptr %2, i64 432
  store i8 1, ptr %25, align 8, !tbaa !42
  %26 = getelementptr inbounds i8, ptr %2, i64 436
  store i32 -1, ptr %26, align 4, !tbaa !40
  %27 = getelementptr inbounds i8, ptr %2, i64 440
  store i32 0, ptr %27, align 8, !tbaa !26
  %28 = getelementptr inbounds i8, ptr %2, i64 444
  store i8 0, ptr %28, align 4, !tbaa !39
  %29 = getelementptr inbounds i8, ptr %2, i64 448
  store i32 -1, ptr %29, align 8, !tbaa !37
  %30 = getelementptr inbounds i8, ptr %2, i64 452
  store i8 0, ptr %30, align 4, !tbaa !172
  %31 = getelementptr inbounds i8, ptr %2, i64 456
  store ptr null, ptr %31, align 8, !tbaa !173
  %32 = getelementptr inbounds i8, ptr %2, i64 464
  store ptr null, ptr %32, align 8, !tbaa !148
  %33 = getelementptr inbounds i8, ptr %2, i64 472
  store i8 0, ptr %33, align 8, !tbaa !174
  %34 = getelementptr inbounds i8, ptr %2, i64 473
  store i8 0, ptr %34, align 1, !tbaa !149
  %35 = getelementptr inbounds i8, ptr %2, i64 476
  store volatile i32 0, ptr %35, align 4, !tbaa !175
  %36 = getelementptr inbounds i8, ptr %2, i64 480
  store i32 1314276694, ptr %36, align 8, !tbaa !176
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV17IOAccelNVRMBridge, i64 16), ptr %2, align 8, !tbaa !4
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @_ZN17IOAccelNVRMBridgenwEm(i64 noundef %0) local_unnamed_addr #1 align 2 {
  %2 = tail call ptr @_ZN8OSObjectnwEm(i64 noundef %0) #15
  ret ptr %2
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgeC1Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  %2 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %2, align 8, !tbaa !151
  %3 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %3, align 8, !tbaa !152
  %4 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %4, align 8, !tbaa !153
  %5 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %5, align 4, !tbaa !154
  %6 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %6, align 8, !tbaa !155
  %7 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %7, i8 0, i64 64, i1 false)
  %8 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %8, align 8, !tbaa !156
  %9 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %9, align 8, !tbaa !157
  %10 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %10, align 8, !tbaa !158
  %11 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %11, align 4, !tbaa !159
  %12 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %12, align 8, !tbaa !160
  %13 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %13, align 8, !tbaa !161
  %14 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %14, align 8, !tbaa !162
  %15 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %15, align 8, !tbaa !163
  %16 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %16, align 8, !tbaa !164
  %17 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %17, align 8, !tbaa !165
  %18 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %18, align 8, !tbaa !166
  %19 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %19, align 8, !tbaa !167
  %20 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %20, align 8, !tbaa !168
  %21 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %21, align 8, !tbaa !169
  %22 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %22, align 4, !tbaa !170
  %23 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %23, align 8, !tbaa !171
  %24 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %24, align 8, !tbaa !42
  %25 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %25, align 4, !tbaa !40
  %26 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %26, align 8, !tbaa !26
  %27 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %27, align 4, !tbaa !39
  %28 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %28, align 8, !tbaa !37
  %29 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %29, align 4, !tbaa !172
  %30 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %30, align 8, !tbaa !173
  %31 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %31, align 8, !tbaa !148
  %32 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %32, align 8, !tbaa !174
  %33 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %33, align 1, !tbaa !149
  %34 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %34, align 4, !tbaa !175
  %35 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %35, align 8, !tbaa !176
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV17IOAccelNVRMBridge, i64 16), ptr %0, align 8, !tbaa !4
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN17IOAccelNVRMBridgeC2Ev(ptr noundef %0) unnamed_addr #1 align 2 {
  tail call void @_ZN12IOUserClientC2EPK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  %2 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr null, ptr %2, align 8, !tbaa !151
  %3 = getelementptr inbounds i8, ptr %0, i64 232
  store ptr null, ptr %3, align 8, !tbaa !152
  %4 = getelementptr inbounds i8, ptr %0, i64 240
  store i16 0, ptr %4, align 8, !tbaa !153
  %5 = getelementptr inbounds i8, ptr %0, i64 244
  store i32 0, ptr %5, align 4, !tbaa !154
  %6 = getelementptr inbounds i8, ptr %0, i64 248
  store i32 0, ptr %6, align 8, !tbaa !155
  %7 = getelementptr inbounds i8, ptr %0, i64 252
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(64) %7, i8 0, i64 64, i1 false)
  %8 = getelementptr inbounds i8, ptr %0, i64 320
  store volatile ptr null, ptr %8, align 8, !tbaa !156
  %9 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr null, ptr %9, align 8, !tbaa !157
  %10 = getelementptr inbounds i8, ptr %0, i64 336
  store volatile i32 0, ptr %10, align 8, !tbaa !158
  %11 = getelementptr inbounds i8, ptr %0, i64 340
  store volatile i32 0, ptr %11, align 4, !tbaa !159
  %12 = getelementptr inbounds i8, ptr %0, i64 344
  store i8 0, ptr %12, align 8, !tbaa !160
  %13 = getelementptr inbounds i8, ptr %0, i64 352
  store ptr null, ptr %13, align 8, !tbaa !161
  %14 = getelementptr inbounds i8, ptr %0, i64 360
  store i64 0, ptr %14, align 8, !tbaa !162
  %15 = getelementptr inbounds i8, ptr %0, i64 368
  store ptr null, ptr %15, align 8, !tbaa !163
  %16 = getelementptr inbounds i8, ptr %0, i64 376
  store i64 0, ptr %16, align 8, !tbaa !164
  %17 = getelementptr inbounds i8, ptr %0, i64 384
  store ptr null, ptr %17, align 8, !tbaa !165
  %18 = getelementptr inbounds i8, ptr %0, i64 392
  store i64 0, ptr %18, align 8, !tbaa !166
  %19 = getelementptr inbounds i8, ptr %0, i64 400
  store i64 0, ptr %19, align 8, !tbaa !167
  %20 = getelementptr inbounds i8, ptr %0, i64 408
  store i64 0, ptr %20, align 8, !tbaa !168
  %21 = getelementptr inbounds i8, ptr %0, i64 416
  store i32 0, ptr %21, align 8, !tbaa !169
  %22 = getelementptr inbounds i8, ptr %0, i64 420
  store i8 0, ptr %22, align 4, !tbaa !170
  %23 = getelementptr inbounds i8, ptr %0, i64 424
  store i32 0, ptr %23, align 8, !tbaa !171
  %24 = getelementptr inbounds i8, ptr %0, i64 432
  store i8 1, ptr %24, align 8, !tbaa !42
  %25 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 -1, ptr %25, align 4, !tbaa !40
  %26 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 0, ptr %26, align 8, !tbaa !26
  %27 = getelementptr inbounds i8, ptr %0, i64 444
  store i8 0, ptr %27, align 4, !tbaa !39
  %28 = getelementptr inbounds i8, ptr %0, i64 448
  store i32 -1, ptr %28, align 8, !tbaa !37
  %29 = getelementptr inbounds i8, ptr %0, i64 452
  store i8 0, ptr %29, align 4, !tbaa !172
  %30 = getelementptr inbounds i8, ptr %0, i64 456
  store ptr null, ptr %30, align 8, !tbaa !173
  %31 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr null, ptr %31, align 8, !tbaa !148
  %32 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 0, ptr %32, align 8, !tbaa !174
  %33 = getelementptr inbounds i8, ptr %0, i64 473
  store i8 0, ptr %33, align 1, !tbaa !149
  %34 = getelementptr inbounds i8, ptr %0, i64 476
  store volatile i32 0, ptr %34, align 4, !tbaa !175
  %35 = getelementptr inbounds i8, ptr %0, i64 480
  store i32 1314276694, ptr %35, align 8, !tbaa !176
  store ptr getelementptr inbounds inrange(-16, 2408) (i8, ptr @_ZTV17IOAccelNVRMBridge, i64 16), ptr %0, align 8, !tbaa !4
  tail call void @_ZNK11OSMetaClass19instanceConstructedEv(ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @_ZN4NVRM20callPlatformFunctionEPK8OSSymbolbPvS3_S3_S3_(ptr noundef %0, ptr noundef %1, i1 noundef zeroext %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6) unnamed_addr #1 align 2 {
  %8 = icmp eq ptr %1, null
  br i1 %8, label %231, label %9

9:                                                ; preds = %7
  %10 = load ptr, ptr %1, align 8, !tbaa !4
  %11 = getelementptr inbounds i8, ptr %10, i64 344
  %12 = load ptr, ptr %11, align 8
  %13 = tail call zeroext i1 %12(ptr noundef nonnull %1, ptr noundef nonnull @.str.272) #15
  br i1 %13, label %14, label %30

14:                                               ; preds = %9
  %15 = icmp eq ptr %3, null
  br i1 %15, label %234, label %16

16:                                               ; preds = %14
  %17 = getelementptr inbounds i8, ptr %0, i64 136
  %18 = load i32, ptr %17, align 8, !tbaa !43
  %19 = icmp slt i32 %18, 0
  br i1 %19, label %234, label %20

20:                                               ; preds = %16
  store i32 %18, ptr %3, align 4, !tbaa !18
  %21 = getelementptr inbounds i8, ptr %0, i64 140
  %22 = load i32, ptr %21, align 4, !tbaa !54
  %23 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 %22, ptr %23, align 4, !tbaa !18
  %24 = getelementptr inbounds i8, ptr %0, i64 144
  %25 = load i32, ptr %24, align 8, !tbaa !55
  %26 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 %25, ptr %26, align 4, !tbaa !18
  %27 = getelementptr inbounds i8, ptr %0, i64 148
  %28 = load i32, ptr %27, align 4, !tbaa !56
  %29 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 %28, ptr %29, align 4, !tbaa !18
  br label %234

30:                                               ; preds = %9
  %31 = load ptr, ptr %1, align 8, !tbaa !4
  %32 = getelementptr inbounds i8, ptr %31, i64 344
  %33 = load ptr, ptr %32, align 8
  %34 = tail call zeroext i1 %33(ptr noundef nonnull %1, ptr noundef nonnull @.str.273) #15
  br i1 %34, label %35, label %56

35:                                               ; preds = %30
  %36 = icmp ne ptr %3, null
  %37 = icmp ne ptr %4, null
  %38 = and i1 %36, %37
  br i1 %38, label %39, label %234

39:                                               ; preds = %35
  %40 = getelementptr inbounds i8, ptr %0, i64 152
  %41 = load ptr, ptr %40, align 8, !tbaa !57
  %42 = icmp eq ptr %41, null
  br i1 %42, label %234, label %43

43:                                               ; preds = %39
  %44 = load ptr, ptr %41, align 8, !tbaa !4
  %45 = getelementptr inbounds i8, ptr %44, i64 736
  %46 = load ptr, ptr %45, align 8
  %47 = tail call ptr %46(ptr noundef nonnull %41) #15
  store ptr %47, ptr %3, align 8, !tbaa !10
  %48 = getelementptr inbounds i8, ptr %0, i64 160
  %49 = load i32, ptr %48, align 8, !tbaa !58
  store i32 %49, ptr %4, align 4, !tbaa !18
  %50 = getelementptr inbounds i8, ptr %0, i64 164
  %51 = load i32, ptr %50, align 4, !tbaa !59
  %52 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 %51, ptr %52, align 4, !tbaa !18
  %53 = getelementptr inbounds i8, ptr %0, i64 168
  %54 = load i32, ptr %53, align 8, !tbaa !60
  %55 = getelementptr inbounds i8, ptr %4, i64 8
  store i32 %54, ptr %55, align 4, !tbaa !18
  br label %234

56:                                               ; preds = %30
  %57 = load ptr, ptr %1, align 8, !tbaa !4
  %58 = getelementptr inbounds i8, ptr %57, i64 344
  %59 = load ptr, ptr %58, align 8
  %60 = tail call zeroext i1 %59(ptr noundef nonnull %1, ptr noundef nonnull @.str.274) #15
  br i1 %60, label %61, label %69

61:                                               ; preds = %56
  %62 = icmp eq ptr %3, null
  br i1 %62, label %234, label %63

63:                                               ; preds = %61
  %64 = icmp ne ptr %4, null
  %65 = zext i1 %64 to i8
  %66 = tail call zeroext i8 @nvkms_xnu_backlight(i8 noundef zeroext %65, ptr noundef nonnull %3) #15
  %67 = icmp eq i8 %66, 0
  %68 = select i1 %67, i32 -536870160, i32 0
  br label %234

69:                                               ; preds = %56
  %70 = load ptr, ptr %1, align 8, !tbaa !4
  %71 = getelementptr inbounds i8, ptr %70, i64 344
  %72 = load ptr, ptr %71, align 8
  %73 = tail call zeroext i1 %72(ptr noundef nonnull %1, ptr noundef nonnull @.str.275) #15
  br i1 %73, label %74, label %79

74:                                               ; preds = %69
  %75 = getelementptr inbounds i8, ptr %0, i64 184
  %76 = tail call i32 @OSAddAtomic(i32 noundef 0, ptr noundef nonnull %75) #15
  %77 = icmp eq i32 %76, 0
  %78 = select i1 %77, i32 0, i32 -536870184
  br label %234

79:                                               ; preds = %69
  %80 = load ptr, ptr %1, align 8, !tbaa !4
  %81 = getelementptr inbounds i8, ptr %80, i64 344
  %82 = load ptr, ptr %81, align 8
  %83 = tail call zeroext i1 %82(ptr noundef nonnull %1, ptr noundef nonnull @.str.264) #15
  br i1 %83, label %234, label %84

84:                                               ; preds = %79
  %85 = load ptr, ptr %1, align 8, !tbaa !4
  %86 = getelementptr inbounds i8, ptr %85, i64 344
  %87 = load ptr, ptr %86, align 8
  %88 = tail call zeroext i1 %87(ptr noundef nonnull %1, ptr noundef nonnull @.str.276) #15
  br i1 %88, label %89, label %97

89:                                               ; preds = %84
  %90 = getelementptr inbounds i8, ptr %0, i64 152
  %91 = load ptr, ptr %90, align 8, !tbaa !57
  %92 = icmp eq ptr %91, null
  br i1 %92, label %234, label %93

93:                                               ; preds = %89
  %94 = load ptr, ptr %91, align 8, !tbaa !4
  %95 = getelementptr inbounds i8, ptr %94, i64 40
  %96 = load ptr, ptr %95, align 8
  tail call void %96(ptr noundef nonnull %91) #15
  store ptr null, ptr %90, align 8, !tbaa !57
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.277) #15
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.277) #15
  br label %234

97:                                               ; preds = %84
  %98 = load ptr, ptr %1, align 8, !tbaa !4
  %99 = getelementptr inbounds i8, ptr %98, i64 344
  %100 = load ptr, ptr %99, align 8
  %101 = tail call zeroext i1 %100(ptr noundef nonnull %1, ptr noundef nonnull @.str.278) #15
  br i1 %101, label %102, label %126

102:                                              ; preds = %97
  %103 = icmp eq ptr %5, null
  br i1 %103, label %234, label %104

104:                                              ; preds = %102
  store ptr null, ptr %5, align 8, !tbaa !10
  %105 = load ptr, ptr @_ZN17IOAccelNVRMBridge10gMetaClassE, align 8, !tbaa !4
  %106 = getelementptr inbounds i8, ptr %105, i64 136
  %107 = load ptr, ptr %106, align 8
  %108 = tail call ptr %107(ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  %109 = icmp eq ptr %108, null
  br i1 %109, label %234, label %110

110:                                              ; preds = %104
  %111 = getelementptr inbounds i8, ptr %108, i64 224
  store ptr %0, ptr %111, align 8, !tbaa !151
  %112 = ptrtoint ptr %4 to i64
  %113 = trunc i64 %112 to i32
  %114 = load ptr, ptr %108, align 8, !tbaa !4
  %115 = getelementptr inbounds i8, ptr %114, i64 2272
  %116 = load ptr, ptr %115, align 8
  %117 = tail call zeroext i1 %116(ptr noundef nonnull %108, ptr noundef %3, ptr noundef null, i32 noundef %113, ptr noundef null) #15
  br i1 %117, label %122, label %118

118:                                              ; preds = %110
  %119 = load ptr, ptr %108, align 8, !tbaa !4
  %120 = getelementptr inbounds i8, ptr %119, i64 40
  %121 = load ptr, ptr %120, align 8
  tail call void %121(ptr noundef nonnull %108) #15
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.279, i32 noundef %113) #15
  br label %234

122:                                              ; preds = %110
  %123 = tail call zeroext i1 @nv_xnu_chat() #15
  br i1 %123, label %124, label %125

124:                                              ; preds = %122
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.280, i32 noundef %113) #15
  br label %125

125:                                              ; preds = %124, %122
  store ptr %108, ptr %5, align 8, !tbaa !10
  br label %234

126:                                              ; preds = %97
  %127 = load ptr, ptr %1, align 8, !tbaa !4
  %128 = getelementptr inbounds i8, ptr %127, i64 344
  %129 = load ptr, ptr %128, align 8
  %130 = tail call zeroext i1 %129(ptr noundef nonnull %1, ptr noundef nonnull @.str.281) #15
  br i1 %130, label %131, label %136

131:                                              ; preds = %126
  br i1 %2, label %132, label %234

132:                                              ; preds = %131
  %133 = tail call i32 @nv_xnu_retry_kms_bridge_closes() #17
  %134 = icmp eq i32 %133, 0
  %135 = select i1 %134, i32 0, i32 -536870184
  br label %234

136:                                              ; preds = %126
  %137 = icmp eq ptr %3, null
  br i1 %137, label %231, label %138

138:                                              ; preds = %136
  %139 = load ptr, ptr %1, align 8, !tbaa !4
  %140 = getelementptr inbounds i8, ptr %139, i64 344
  %141 = load ptr, ptr %140, align 8
  %142 = tail call zeroext i1 %141(ptr noundef nonnull %1, ptr noundef nonnull @.str.282) #15
  br i1 %142, label %163, label %143

143:                                              ; preds = %138
  %144 = load ptr, ptr %1, align 8, !tbaa !4
  %145 = getelementptr inbounds i8, ptr %144, i64 344
  %146 = load ptr, ptr %145, align 8
  %147 = tail call zeroext i1 %146(ptr noundef nonnull %1, ptr noundef nonnull @.str.283) #15
  br i1 %147, label %163, label %148

148:                                              ; preds = %143
  %149 = load ptr, ptr %1, align 8, !tbaa !4
  %150 = getelementptr inbounds i8, ptr %149, i64 344
  %151 = load ptr, ptr %150, align 8
  %152 = tail call zeroext i1 %151(ptr noundef nonnull %1, ptr noundef nonnull @.str.284) #15
  br i1 %152, label %163, label %153

153:                                              ; preds = %148
  %154 = load ptr, ptr %1, align 8, !tbaa !4
  %155 = getelementptr inbounds i8, ptr %154, i64 344
  %156 = load ptr, ptr %155, align 8
  %157 = tail call zeroext i1 %156(ptr noundef nonnull %1, ptr noundef nonnull @.str.285) #15
  br i1 %157, label %163, label %158

158:                                              ; preds = %153
  %159 = load ptr, ptr %1, align 8, !tbaa !4
  %160 = getelementptr inbounds i8, ptr %159, i64 344
  %161 = load ptr, ptr %160, align 8
  %162 = tail call zeroext i1 %161(ptr noundef nonnull %1, ptr noundef nonnull @.str.286) #15
  br i1 %162, label %163, label %166

163:                                              ; preds = %138, %143, %148, %153, %158
  %164 = tail call i32 @nv_xnu_pm_enter() #17
  %165 = icmp ne i32 %164, 0
  br label %166

166:                                              ; preds = %158, %163
  %167 = phi i1 [ %165, %163 ], [ false, %158 ]
  %168 = load ptr, ptr %1, align 8, !tbaa !4
  %169 = getelementptr inbounds i8, ptr %168, i64 344
  %170 = load ptr, ptr %169, align 8
  %171 = tail call zeroext i1 %170(ptr noundef nonnull %1, ptr noundef nonnull @.str.282) #15
  br i1 %171, label %172, label %176

172:                                              ; preds = %166
  %173 = tail call i32 @nvrm_gpuva_alloc(ptr noundef nonnull %3) #15
  %174 = icmp eq i32 %173, 0
  %175 = select i1 %174, i32 0, i32 -536870198
  br label %213

176:                                              ; preds = %166
  %177 = load ptr, ptr %1, align 8, !tbaa !4
  %178 = getelementptr inbounds i8, ptr %177, i64 344
  %179 = load ptr, ptr %178, align 8
  %180 = tail call zeroext i1 %179(ptr noundef nonnull %1, ptr noundef nonnull @.str.283) #15
  br i1 %180, label %181, label %185

181:                                              ; preds = %176
  %182 = tail call i32 @nvrm_gpuva_map(ptr noundef nonnull %3) #15
  %183 = icmp eq i32 %182, 0
  %184 = select i1 %183, i32 0, i32 -536870198
  br label %213

185:                                              ; preds = %176
  %186 = load ptr, ptr %1, align 8, !tbaa !4
  %187 = getelementptr inbounds i8, ptr %186, i64 344
  %188 = load ptr, ptr %187, align 8
  %189 = tail call zeroext i1 %188(ptr noundef nonnull %1, ptr noundef nonnull @.str.284) #15
  br i1 %189, label %190, label %194

190:                                              ; preds = %185
  %191 = tail call i32 @nvrm_gpuva_free(ptr noundef nonnull %3) #15
  %192 = icmp eq i32 %191, 0
  %193 = select i1 %192, i32 0, i32 -536870198
  br label %213

194:                                              ; preds = %185
  %195 = load ptr, ptr %1, align 8, !tbaa !4
  %196 = getelementptr inbounds i8, ptr %195, i64 344
  %197 = load ptr, ptr %196, align 8
  %198 = tail call zeroext i1 %197(ptr noundef nonnull %1, ptr noundef nonnull @.str.285) #15
  br i1 %198, label %199, label %203

199:                                              ; preds = %194
  %200 = tail call i32 @nvrm_surfshare_rm(ptr noundef nonnull %3) #15
  %201 = icmp eq i32 %200, 0
  %202 = select i1 %201, i32 0, i32 -536870198
  br label %213

203:                                              ; preds = %194
  %204 = load ptr, ptr %1, align 8, !tbaa !4
  %205 = getelementptr inbounds i8, ptr %204, i64 344
  %206 = load ptr, ptr %205, align 8
  %207 = tail call zeroext i1 %206(ptr noundef nonnull %1, ptr noundef nonnull @.str.286) #15
  br i1 %207, label %208, label %213

208:                                              ; preds = %203
  %209 = getelementptr inbounds i8, ptr %0, i64 336
  %210 = tail call i32 @nvrm_surfshare_pageoff(ptr noundef nonnull %3, ptr noundef nonnull %209) #15
  %211 = icmp eq i32 %210, 0
  %212 = select i1 %211, i32 0, i32 -536870198
  br label %213

213:                                              ; preds = %203, %208, %199, %190, %181, %172
  %214 = phi i1 [ false, %172 ], [ false, %181 ], [ false, %190 ], [ false, %199 ], [ false, %208 ], [ true, %203 ]
  %215 = phi i32 [ %175, %172 ], [ %184, %181 ], [ %193, %190 ], [ %202, %199 ], [ %212, %208 ], [ undef, %203 ]
  %216 = load ptr, ptr @_ZL9gNvPmGate, align 8
  %217 = icmp ne ptr %216, null
  %218 = select i1 %167, i1 %217, i1 false
  br i1 %218, label %219, label %230

219:                                              ; preds = %213
  tail call void @IOLockLock(ptr noundef nonnull %216) #15
  %220 = load i32, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %221 = add nsw i32 %220, -1
  store i32 %221, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %222 = icmp eq i32 %221, 0
  br i1 %222, label %223, label %228

223:                                              ; preds = %219
  %224 = load i8, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12, !range !14, !noundef !15
  %225 = trunc nuw i8 %224 to i1
  br i1 %225, label %226, label %228

226:                                              ; preds = %223
  %227 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @"\01_IOLockWakeup_darwin14"(ptr noundef %227, ptr noundef nonnull @_ZL10gNvPmUsers, i1 noundef zeroext false) #15
  br label %228

228:                                              ; preds = %226, %223, %219
  %229 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %229) #15
  br label %230

230:                                              ; preds = %213, %228
  br i1 %214, label %231, label %234

231:                                              ; preds = %7, %230, %136
  %232 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV9IOService, i64 1736), align 8
  %233 = tail call i32 %232(ptr noundef %0, ptr noundef %1, i1 noundef zeroext %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6) #15
  br label %234

234:                                              ; preds = %230, %131, %102, %104, %125, %118, %89, %93, %79, %63, %61, %43, %35, %39, %20, %14, %16, %231, %132, %74
  %235 = phi i32 [ %78, %74 ], [ %135, %132 ], [ %215, %230 ], [ %233, %231 ], [ 0, %20 ], [ -536870206, %14 ], [ -536870160, %16 ], [ 0, %43 ], [ -536870206, %35 ], [ -536870160, %39 ], [ %68, %63 ], [ -536870206, %61 ], [ -536870201, %79 ], [ 0, %93 ], [ 0, %89 ], [ -536870206, %102 ], [ 0, %125 ], [ -536870210, %118 ], [ -536870211, %104 ], [ -536870201, %131 ]
  ret i32 %235
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @nvkms_xnu_backlight(i8 noundef zeroext, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @nv_xnu_chat() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @nvrm_gpuva_alloc(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @nvrm_gpuva_map(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @nvrm_gpuva_free(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @nvrm_surfshare_rm(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @nvrm_surfshare_pageoff(ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define zeroext i1 @_ZN14NVRMUserClient5startEP9IOService(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  %3 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %1, ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  %4 = getelementptr inbounds i8, ptr %0, i64 224
  store ptr %3, ptr %4, align 8, !tbaa !151
  %5 = icmp eq ptr %3, null
  br i1 %5, label %9, label %6

6:                                                ; preds = %2
  %7 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV12IOUserClient, i64 1488), align 8
  %8 = tail call zeroext i1 %7(ptr noundef nonnull %0, ptr noundef %1) #15
  br label %9

9:                                                ; preds = %2, %6
  %10 = phi i1 [ %8, %6 ], [ false, %2 ]
  ret i1 %10
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i1 @_ZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionary(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3, ptr noundef %4) unnamed_addr #1 align 2 {
  %6 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV12IOUserClient, i64 2288), align 8
  %7 = tail call zeroext i1 %6(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3, ptr noundef %4) #15
  %8 = icmp ult i32 %3, 2
  %9 = and i1 %8, %7
  br i1 %9, label %10, label %158

10:                                               ; preds = %5
  %11 = tail call ptr @IOLockAlloc() #15
  %12 = getelementptr inbounds i8, ptr %0, i64 464
  store ptr %11, ptr %12, align 8, !tbaa !148
  %13 = icmp eq ptr %11, null
  br i1 %13, label %158, label %14

14:                                               ; preds = %10
  %15 = getelementptr inbounds i8, ptr %0, i64 432
  %16 = trunc nuw i32 %3 to i8
  %17 = xor i8 %16, 1
  store i8 %17, ptr %15, align 8, !tbaa !42
  %18 = getelementptr inbounds i8, ptr %0, i64 232
  %19 = tail call { ptr, i64 } asm sideeffect "rep stosb", "={di},={cx},{ax},0,1,~{memory},~{dirflag},~{fpsr},~{flags}"(i32 0, ptr nonnull %18, i64 120) #18, !srcloc !177
  %20 = getelementptr inbounds i8, ptr %0, i64 328
  store ptr %0, ptr %20, align 8, !tbaa !178
  %21 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  %22 = icmp eq ptr %21, null
  br i1 %22, label %23, label %26

23:                                               ; preds = %14
  %24 = tail call ptr @IOLockAlloc() #15
  store ptr %24, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  %25 = icmp eq ptr %24, null
  br i1 %25, label %158, label %26

26:                                               ; preds = %14, %23
  %27 = tail call i32 @proc_selfpid() #15
  %28 = tail call i32 @kauth_getuid() #15
  %29 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockLock(ptr noundef %29) #15
  br label %38

30:                                               ; preds = %57
  %31 = icmp ugt i32 %28, 499
  %32 = icmp sgt i32 %59, 4095
  %33 = icmp sgt i32 %60, 28671
  %34 = select i1 %31, i1 %33, i1 false
  %35 = icmp slt i32 %58, 0
  %36 = select i1 %35, i1 true, i1 %32
  %37 = select i1 %36, i1 true, i1 %34
  br i1 %37, label %67, label %63

38:                                               ; preds = %26, %57
  %39 = phi i64 [ 0, %26 ], [ %61, %57 ]
  %40 = phi i32 [ 0, %26 ], [ %60, %57 ]
  %41 = phi i32 [ 0, %26 ], [ %59, %57 ]
  %42 = phi i32 [ -1, %26 ], [ %58, %57 ]
  %43 = getelementptr inbounds [32768 x ptr], ptr @_ZL10gNvClients, i64 0, i64 %39
  %44 = load ptr, ptr %43, align 8, !tbaa !10
  %45 = icmp eq ptr %44, null
  br i1 %45, label %46, label %50

46:                                               ; preds = %38
  %47 = icmp slt i32 %42, 0
  %48 = trunc nuw nsw i64 %39 to i32
  %49 = select i1 %47, i32 %48, i32 %42
  br label %57

50:                                               ; preds = %38
  %51 = add nsw i32 %40, 1
  %52 = getelementptr inbounds i8, ptr %44, i64 440
  %53 = load i32, ptr %52, align 8, !tbaa !26
  %54 = icmp eq i32 %53, %27
  %55 = zext i1 %54 to i32
  %56 = add nsw i32 %41, %55
  br label %57

57:                                               ; preds = %50, %46
  %58 = phi i32 [ %42, %50 ], [ %49, %46 ]
  %59 = phi i32 [ %56, %50 ], [ %41, %46 ]
  %60 = phi i32 [ %51, %50 ], [ %40, %46 ]
  %61 = add nuw nsw i64 %39, 1
  %62 = icmp eq i64 %61, 32768
  br i1 %62, label %30, label %38, !llvm.loop !179

63:                                               ; preds = %30
  %64 = zext nneg i32 %58 to i64
  %65 = getelementptr inbounds [32768 x ptr], ptr @_ZL10gNvClients, i64 0, i64 %64
  store ptr %0, ptr %65, align 8, !tbaa !10
  %66 = getelementptr inbounds i8, ptr %0, i64 436
  store i32 %58, ptr %66, align 4, !tbaa !40
  br label %67

67:                                               ; preds = %30, %63
  %68 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %68) #15
  %69 = select i1 %32, i1 true, i1 %34
  br i1 %69, label %70, label %76

70:                                               ; preds = %67
  %71 = load i32, ptr @_ZZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionaryE11quotaLogged, align 4, !tbaa !18
  %72 = icmp ult i32 %71, 8
  br i1 %72, label %73, label %158

73:                                               ; preds = %70
  %74 = add nuw nsw i32 %71, 1
  store i32 %74, ptr @_ZZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionaryE11quotaLogged, align 4, !tbaa !18
  %75 = select i1 %32, ptr @.str.288, ptr @.str.289
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.287, i32 noundef %27, ptr noundef nonnull %75, i32 noundef %59, i32 noundef %60, i32 noundef 32768) #15
  br label %158

76:                                               ; preds = %67
  %77 = getelementptr inbounds i8, ptr %0, i64 436
  %78 = load i32, ptr %77, align 4, !tbaa !40
  %79 = icmp slt i32 %78, 0
  br i1 %79, label %80, label %85

80:                                               ; preds = %76
  %81 = load i32, ptr @_ZZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionaryE15tableFullLogged, align 4, !tbaa !18
  %82 = icmp ult i32 %81, 8
  br i1 %82, label %83, label %158

83:                                               ; preds = %80
  %84 = add nuw nsw i32 %81, 1
  store i32 %84, ptr @_ZZN14NVRMUserClient12initWithTaskEP4taskPvjP12OSDictionaryE15tableFullLogged, align 4, !tbaa !18
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.290, i32 noundef 32768, i32 noundef 32768) #15
  br label %158

85:                                               ; preds = %76
  %86 = tail call i32 @proc_selfpid() #15
  %87 = getelementptr inbounds i8, ptr %0, i64 440
  store i32 %86, ptr %87, align 8, !tbaa !26
  %88 = tail call ptr @get_task_pmap(ptr noundef %1) #15
  %89 = ptrtoint ptr %88 to i64
  %90 = getelementptr inbounds i8, ptr %0, i64 216
  store i64 %89, ptr %90, align 8, !tbaa !180
  %91 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockLock(ptr noundef %91) #15
  %92 = load i64, ptr %90, align 8, !tbaa !180
  %93 = load i32, ptr %87, align 8, !tbaa !26
  %94 = icmp eq i64 %92, 0
  br i1 %94, label %150, label %95

95:                                               ; preds = %85, %122
  %96 = phi i64 [ %124, %122 ], [ 0, %85 ]
  %97 = phi i32 [ %123, %122 ], [ -1, %85 ]
  %98 = phi i32 [ %107, %122 ], [ -1, %85 ]
  %99 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %96
  %100 = load i64, ptr %99, align 16, !tbaa !21
  %101 = icmp eq i64 %100, %92
  br i1 %101, label %126, label %102

102:                                              ; preds = %95
  %103 = icmp eq i64 %100, 0
  %104 = icmp slt i32 %98, 0
  %105 = select i1 %103, i1 %104, i1 false
  %106 = trunc nuw nsw i64 %96 to i32
  %107 = select i1 %105, i32 %106, i32 %98
  br i1 %103, label %122, label %108

108:                                              ; preds = %102
  %109 = getelementptr inbounds i8, ptr %99, i64 12
  %110 = load i32, ptr %109, align 4, !tbaa !181
  %111 = icmp eq i32 %110, 0
  br i1 %111, label %112, label %122

112:                                              ; preds = %108
  %113 = icmp slt i32 %97, 0
  br i1 %113, label %121, label %114

114:                                              ; preds = %112
  %115 = getelementptr inbounds i8, ptr %99, i64 16
  %116 = load i64, ptr %115, align 16, !tbaa !25
  %117 = zext nneg i32 %97 to i64
  %118 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %117, i32 3
  %119 = load i64, ptr %118, align 16, !tbaa !25
  %120 = icmp ult i64 %116, %119
  br i1 %120, label %121, label %122

121:                                              ; preds = %114, %112
  br label %122

122:                                              ; preds = %121, %114, %108, %102
  %123 = phi i32 [ %97, %108 ], [ %106, %121 ], [ %97, %114 ], [ %97, %102 ]
  %124 = add nuw nsw i64 %96, 1
  %125 = icmp eq i64 %124, 256
  br i1 %125, label %137, label %95, !llvm.loop !182

126:                                              ; preds = %95
  %127 = and i64 %96, 4294967295
  %128 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %127
  %129 = getelementptr inbounds i8, ptr %128, i64 8
  %130 = load i32, ptr %129, align 8, !tbaa !24
  %131 = icmp eq i32 %130, %93
  br i1 %131, label %132, label %143

132:                                              ; preds = %126
  %133 = getelementptr inbounds i8, ptr %128, i64 12
  %134 = load i32, ptr %133, align 4, !tbaa !181
  %135 = add nsw i32 %134, 1
  store i32 %135, ptr %133, align 4, !tbaa !181
  %136 = getelementptr inbounds i8, ptr %128, i64 16
  store i64 0, ptr %136, align 16, !tbaa !25
  br label %150

137:                                              ; preds = %122
  %138 = icmp slt i32 %107, 0
  %139 = select i1 %138, i32 %123, i32 %107
  %140 = icmp slt i32 %139, 0
  br i1 %140, label %150, label %141

141:                                              ; preds = %137
  %142 = zext nneg i32 %139 to i64
  br label %143

143:                                              ; preds = %141, %126
  %144 = phi i64 [ %142, %141 ], [ %127, %126 ]
  %145 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %144
  store i64 %92, ptr %145, align 16, !tbaa !21
  %146 = getelementptr inbounds i8, ptr %145, i64 8
  store i32 %93, ptr %146, align 8, !tbaa !24
  %147 = getelementptr inbounds i8, ptr %145, i64 12
  store i32 1, ptr %147, align 4, !tbaa !181
  %148 = getelementptr inbounds i8, ptr %145, i64 16
  store i64 0, ptr %148, align 16, !tbaa !25
  %149 = getelementptr inbounds i8, ptr %145, i64 24
  store i8 0, ptr %149, align 8, !tbaa !20
  tail call void @proc_name(i32 noundef %93, ptr noundef nonnull %149, i32 noundef 20) #15
  br label %150

150:                                              ; preds = %85, %132, %137, %143
  %151 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %151) #15
  %152 = tail call zeroext i1 @nv_xnu_chat() #15
  br i1 %152, label %153, label %158

153:                                              ; preds = %150
  %154 = load i32, ptr %77, align 4, !tbaa !40
  %155 = load i8, ptr %15, align 8, !tbaa !42, !range !14, !noundef !15
  %156 = trunc nuw i8 %155 to i1
  %157 = select i1 %156, ptr @.str.292, ptr @.str.293
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.291, i32 noundef %154, ptr noundef nonnull %157) #15
  br label %158

158:                                              ; preds = %73, %70, %83, %80, %153, %150, %23, %10, %5
  %159 = phi i1 [ false, %5 ], [ false, %10 ], [ false, %23 ], [ false, %73 ], [ false, %70 ], [ false, %83 ], [ false, %80 ], [ true, %153 ], [ true, %150 ]
  ret i1 %159
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @get_task_pmap(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @_ZN14NVRMUserClient7nvStateEv(ptr nocapture noundef readonly %0) local_unnamed_addr #1 align 2 {
  %2 = getelementptr inbounds i8, ptr %0, i64 432
  %3 = load i8, ptr %2, align 8, !tbaa !42, !range !14, !noundef !15
  %4 = trunc nuw i8 %3 to i1
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call ptr @nv_get_ctl_state() #15
  br label %11

7:                                                ; preds = %1
  %8 = getelementptr inbounds i8, ptr %0, i64 224
  %9 = load ptr, ptr %8, align 8, !tbaa !151
  %10 = getelementptr inbounds i8, ptr %9, i64 336
  br label %11

11:                                               ; preds = %7, %5
  %12 = phi ptr [ %6, %5 ], [ %10, %7 ]
  ret ptr %12
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @_ZN14NVRMUserClient4freeEv(ptr noundef %0) unnamed_addr #1 align 2 {
  %2 = getelementptr inbounds i8, ptr %0, i64 464
  %3 = load ptr, ptr %2, align 8, !tbaa !148
  %4 = icmp eq ptr %3, null
  br i1 %4, label %6, label %5

5:                                                ; preds = %1
  tail call void @IOLockFree(ptr noundef nonnull %3) #15
  store ptr null, ptr %2, align 8, !tbaa !148
  br label %6

6:                                                ; preds = %5, %1
  %7 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV12IOUserClient, i64 160), align 8
  tail call void %7(ptr noundef nonnull %0) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOLockFree(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870184, 1) i32 @_ZN14NVRMUserClient11clientCloseEv(ptr noundef %0) unnamed_addr #1 align 2 {
  %2 = alloca i64, align 8
  %3 = getelementptr inbounds i8, ptr %0, i64 464
  %4 = load ptr, ptr %3, align 8, !tbaa !148
  %5 = icmp eq ptr %4, null
  br i1 %5, label %6, label %11

6:                                                ; preds = %1
  %7 = load ptr, ptr %0, align 8, !tbaa !4
  %8 = getelementptr inbounds i8, ptr %7, i64 1536
  %9 = load ptr, ptr %8, align 8
  %10 = tail call zeroext i1 %9(ptr noundef nonnull %0, i32 noundef 0) #15
  br label %160

11:                                               ; preds = %1
  tail call void @IOLockLock(ptr noundef nonnull %4) #15
  %12 = getelementptr inbounds i8, ptr %0, i64 472
  store i8 1, ptr %12, align 8, !tbaa !174
  %13 = getelementptr inbounds i8, ptr %0, i64 452
  %14 = load i8, ptr %13, align 4, !tbaa !172, !range !14, !noundef !15
  %15 = trunc nuw i8 %14 to i1
  br i1 %15, label %133, label %16

16:                                               ; preds = %11
  %17 = getelementptr inbounds i8, ptr %0, i64 456
  %18 = load ptr, ptr %17, align 8, !tbaa !173
  %19 = icmp eq ptr %18, null
  br i1 %19, label %40, label %20

20:                                               ; preds = %16
  %21 = tail call zeroext i8 @nvkms_xnu_try_close_bridge(ptr noundef nonnull %18) #15
  %22 = icmp eq i8 %21, 0
  br i1 %22, label %23, label %40

23:                                               ; preds = %20
  %24 = getelementptr inbounds i8, ptr %0, i64 473
  %25 = load i8, ptr %24, align 1, !tbaa !149, !range !14, !noundef !15
  %26 = trunc nuw i8 %25 to i1
  br i1 %26, label %141, label %27

27:                                               ; preds = %23
  %28 = load ptr, ptr %0, align 8, !tbaa !4
  %29 = getelementptr inbounds i8, ptr %28, i64 32
  %30 = load ptr, ptr %29, align 8
  tail call void %30(ptr noundef nonnull %0) #15
  %31 = getelementptr inbounds i8, ptr %0, i64 224
  %32 = load ptr, ptr %31, align 8, !tbaa !151
  %33 = icmp eq ptr %32, null
  br i1 %33, label %38, label %34

34:                                               ; preds = %27
  %35 = load ptr, ptr %32, align 8, !tbaa !4
  %36 = getelementptr inbounds i8, ptr %35, i64 32
  %37 = load ptr, ptr %36, align 8
  tail call void %37(ptr noundef nonnull %32) #15
  br label %38

38:                                               ; preds = %34, %27
  store i8 1, ptr %24, align 1, !tbaa !149
  %39 = tail call i64 @OSAddAtomic64(i64 noundef 1, ptr noundef nonnull @_ZL19gNvKmsCloseDeferred) #15
  br label %141

40:                                               ; preds = %20, %16
  store ptr null, ptr %17, align 8, !tbaa !173
  store i8 1, ptr %13, align 4, !tbaa !172
  %41 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  %42 = icmp eq ptr %41, null
  br i1 %42, label %91, label %43

43:                                               ; preds = %40
  %44 = getelementptr inbounds i8, ptr %0, i64 436
  %45 = load i32, ptr %44, align 4, !tbaa !40
  %46 = icmp sgt i32 %45, -1
  br i1 %46, label %47, label %91

47:                                               ; preds = %43
  tail call void @IOLockLock(ptr noundef nonnull %41) #15
  %48 = load i32, ptr %44, align 4, !tbaa !40
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds [32768 x ptr], ptr @_ZL10gNvClients, i64 0, i64 %49
  store ptr null, ptr %50, align 8, !tbaa !10
  %51 = getelementptr inbounds i8, ptr %0, i64 216
  %52 = load i64, ptr %51, align 8, !tbaa !180
  br label %71

53:                                               ; preds = %71
  %54 = or disjoint i64 %72, 1
  %55 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %54
  %56 = load i64, ptr %55, align 16, !tbaa !21
  %57 = icmp eq i64 %56, %52
  br i1 %57, label %76, label %58

58:                                               ; preds = %53
  %59 = or disjoint i64 %72, 2
  %60 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %59
  %61 = load i64, ptr %60, align 16, !tbaa !21
  %62 = icmp eq i64 %61, %52
  br i1 %62, label %76, label %63

63:                                               ; preds = %58
  %64 = or disjoint i64 %72, 3
  %65 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %64
  %66 = load i64, ptr %65, align 16, !tbaa !21
  %67 = icmp eq i64 %66, %52
  br i1 %67, label %76, label %68

68:                                               ; preds = %63
  %69 = add nuw nsw i64 %72, 4
  %70 = icmp eq i64 %69, 256
  br i1 %70, label %89, label %71, !llvm.loop !183

71:                                               ; preds = %68, %47
  %72 = phi i64 [ 0, %47 ], [ %69, %68 ]
  %73 = getelementptr inbounds [256 x %struct.nv_pm_owner], ptr @_ZL8gNvPmTab, i64 0, i64 %72
  %74 = load i64, ptr %73, align 16, !tbaa !21
  %75 = icmp eq i64 %74, %52
  br i1 %75, label %76, label %53

76:                                               ; preds = %63, %58, %53, %71
  %77 = phi ptr [ %73, %71 ], [ %55, %53 ], [ %60, %58 ], [ %65, %63 ]
  %78 = getelementptr inbounds i8, ptr %77, i64 12
  %79 = load i32, ptr %78, align 4, !tbaa !181
  %80 = icmp sgt i32 %79, 0
  br i1 %80, label %81, label %89

81:                                               ; preds = %76
  %82 = add nsw i32 %79, -1
  store i32 %82, ptr %78, align 4, !tbaa !181
  %83 = icmp eq i32 %82, 0
  br i1 %83, label %84, label %89

84:                                               ; preds = %81
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #18
  store i64 0, ptr %2, align 8, !tbaa !7
  %85 = tail call i64 @mach_absolute_time() #15
  call void @absolutetime_to_nanoseconds(i64 noundef %85, ptr noundef nonnull %2) #15
  %86 = load i64, ptr %2, align 8, !tbaa !7
  %87 = udiv i64 %86, 1000000
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #18
  %88 = getelementptr inbounds i8, ptr %77, i64 16
  store i64 %87, ptr %88, align 16, !tbaa !25
  br label %89

89:                                               ; preds = %68, %76, %81, %84
  %90 = load ptr, ptr @_ZL14gNvClientsLock, align 8, !tbaa !10
  call void @IOLockUnlock(ptr noundef %90) #15
  br label %91

91:                                               ; preds = %89, %43, %40
  %92 = getelementptr inbounds i8, ptr %0, i64 224
  %93 = load ptr, ptr %92, align 8, !tbaa !151
  %94 = icmp eq ptr %93, null
  br i1 %94, label %123, label %95

95:                                               ; preds = %91
  %96 = call i32 @nv_xnu_pm_enter() #17
  %97 = getelementptr inbounds i8, ptr %0, i64 432
  %98 = load i8, ptr %97, align 8, !tbaa !42, !range !14, !noundef !15
  %99 = trunc nuw i8 %98 to i1
  br i1 %99, label %100, label %102

100:                                              ; preds = %95
  %101 = call ptr @nv_get_ctl_state() #15
  br label %105

102:                                              ; preds = %95
  %103 = load ptr, ptr %92, align 8, !tbaa !151
  %104 = getelementptr inbounds i8, ptr %103, i64 336
  br label %105

105:                                              ; preds = %100, %102
  %106 = phi ptr [ %101, %100 ], [ %104, %102 ]
  %107 = getelementptr inbounds i8, ptr %0, i64 232
  call void @rm_cleanup_file_private(ptr noundef null, ptr noundef %106, ptr noundef nonnull %107) #15
  %108 = icmp ne i32 %96, 0
  %109 = load ptr, ptr @_ZL9gNvPmGate, align 8
  %110 = icmp ne ptr %109, null
  %111 = select i1 %108, i1 %110, i1 false
  br i1 %111, label %112, label %123

112:                                              ; preds = %105
  call void @IOLockLock(ptr noundef nonnull %109) #15
  %113 = load i32, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %114 = add nsw i32 %113, -1
  store i32 %114, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %115 = icmp eq i32 %114, 0
  br i1 %115, label %116, label %121

116:                                              ; preds = %112
  %117 = load i8, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12, !range !14, !noundef !15
  %118 = trunc nuw i8 %117 to i1
  br i1 %118, label %119, label %121

119:                                              ; preds = %116
  %120 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  call void @"\01_IOLockWakeup_darwin14"(ptr noundef %120, ptr noundef nonnull @_ZL10gNvPmUsers, i1 noundef zeroext false) #15
  br label %121

121:                                              ; preds = %119, %116, %112
  %122 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  call void @IOLockUnlock(ptr noundef %122) #15
  br label %123

123:                                              ; preds = %121, %105, %91
  %124 = getelementptr inbounds i8, ptr %0, i64 384
  %125 = load ptr, ptr %124, align 8, !tbaa !184
  %126 = icmp eq ptr %125, null
  br i1 %126, label %128, label %127

127:                                              ; preds = %123
  call void @kern_os_free(ptr noundef nonnull %125) #15
  store ptr null, ptr %124, align 8, !tbaa !184
  br label %128

128:                                              ; preds = %127, %123
  %129 = call zeroext i1 @nv_xnu_chat() #15
  br i1 %129, label %130, label %133

130:                                              ; preds = %128
  %131 = getelementptr inbounds i8, ptr %0, i64 436
  %132 = load i32, ptr %131, align 4, !tbaa !40
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.295, i32 noundef %132) #15
  br label %133

133:                                              ; preds = %128, %130, %11
  %134 = getelementptr inbounds i8, ptr %0, i64 473
  %135 = load i8, ptr %134, align 1, !tbaa !149, !range !14, !noundef !15
  %136 = trunc nuw i8 %135 to i1
  br i1 %136, label %137, label %144

137:                                              ; preds = %133
  store i8 0, ptr %134, align 1, !tbaa !149
  %138 = getelementptr inbounds i8, ptr %0, i64 224
  %139 = load ptr, ptr %138, align 8, !tbaa !151
  %140 = call i64 @OSAddAtomic64(i64 noundef -1, ptr noundef nonnull @_ZL19gNvKmsCloseDeferred) #15
  br label %144

141:                                              ; preds = %23, %38
  %142 = getelementptr inbounds i8, ptr %0, i64 436
  %143 = load i32, ptr %142, align 4, !tbaa !40
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.294, i32 noundef %143) #15
  tail call void @IOLockUnlock(ptr noundef nonnull %4) #15
  br label %160

144:                                              ; preds = %137, %133
  %145 = phi ptr [ null, %133 ], [ %139, %137 ]
  call void @IOLockUnlock(ptr noundef nonnull %4) #15
  %146 = load ptr, ptr %0, align 8, !tbaa !4
  %147 = getelementptr inbounds i8, ptr %146, i64 1536
  %148 = load ptr, ptr %147, align 8
  %149 = call zeroext i1 %148(ptr noundef nonnull %0, i32 noundef 0) #15
  %150 = icmp eq ptr %145, null
  br i1 %150, label %155, label %151

151:                                              ; preds = %144
  %152 = load ptr, ptr %145, align 8, !tbaa !4
  %153 = getelementptr inbounds i8, ptr %152, i64 40
  %154 = load ptr, ptr %153, align 8
  call void %154(ptr noundef nonnull %145) #15
  br label %155

155:                                              ; preds = %151, %144
  br i1 %136, label %156, label %160

156:                                              ; preds = %155
  %157 = load ptr, ptr %0, align 8, !tbaa !4
  %158 = getelementptr inbounds i8, ptr %157, i64 40
  %159 = load ptr, ptr %158, align 8
  call void %159(ptr noundef nonnull %0) #15
  br label %160

160:                                              ; preds = %141, %155, %156, %6
  %161 = phi i32 [ -536870184, %141 ], [ 0, %6 ], [ 0, %156 ], [ 0, %155 ]
  ret i32 %161
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @nvkms_xnu_try_close_bridge(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @rm_cleanup_file_private(ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @kern_os_free(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @_ZN14NVRMUserClient13retryKmsCloseEv(ptr noundef %0) local_unnamed_addr #1 align 2 {
  %2 = getelementptr inbounds i8, ptr %0, i64 464
  %3 = load ptr, ptr %2, align 8, !tbaa !148
  %4 = icmp eq ptr %3, null
  br i1 %4, label %14, label %5

5:                                                ; preds = %1
  tail call void @IOLockLock(ptr noundef nonnull %3) #15
  %6 = getelementptr inbounds i8, ptr %0, i64 473
  %7 = load i8, ptr %6, align 1, !tbaa !149, !range !14, !noundef !15
  %8 = trunc nuw i8 %7 to i1
  tail call void @IOLockUnlock(ptr noundef nonnull %3) #15
  br i1 %8, label %9, label %14

9:                                                ; preds = %5
  %10 = load ptr, ptr %0, align 8, !tbaa !4
  %11 = getelementptr inbounds i8, ptr %10, i64 2288
  %12 = load ptr, ptr %11, align 8
  %13 = tail call i32 %12(ptr noundef nonnull %0) #15
  br label %14

14:                                               ; preds = %5, %1, %9
  %15 = phi i32 [ 0, %5 ], [ %13, %9 ], [ 0, %1 ]
  ret i32 %15
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @_ZN14NVRMUserClient19clientMemoryForTypeEjPjPP18IOMemoryDescriptor(ptr nocapture noundef readonly %0, i32 %1, ptr nocapture noundef %2, ptr nocapture noundef writeonly %3) unnamed_addr #1 align 2 {
  %5 = alloca i64, align 8
  %6 = alloca i32, align 4
  %7 = getelementptr inbounds i8, ptr %0, i64 464
  %8 = load ptr, ptr %7, align 8, !tbaa !148
  %9 = icmp eq ptr %8, null
  br i1 %9, label %180, label %10

10:                                               ; preds = %4
  tail call void @IOLockLock(ptr noundef nonnull %8) #15
  %11 = getelementptr inbounds i8, ptr %0, i64 472
  %12 = load i8, ptr %11, align 8, !tbaa !174, !range !14, !noundef !15
  %13 = trunc nuw i8 %12 to i1
  br i1 %13, label %178, label %14

14:                                               ; preds = %10
  %15 = getelementptr inbounds i8, ptr %0, i64 452
  %16 = load i8, ptr %15, align 4, !tbaa !172, !range !14, !noundef !15
  %17 = trunc nuw i8 %16 to i1
  br i1 %17, label %178, label %18

18:                                               ; preds = %14
  %19 = getelementptr inbounds i8, ptr %0, i64 352
  %20 = getelementptr inbounds i8, ptr %0, i64 420
  %21 = load i8, ptr %20, align 4, !tbaa !170
  %22 = icmp eq i8 %21, 0
  br i1 %22, label %23, label %26

23:                                               ; preds = %18
  %24 = getelementptr inbounds i8, ptr %0, i64 436
  %25 = load i32, ptr %24, align 4, !tbaa !40
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.296, i32 noundef %25) #15
  br label %178

26:                                               ; preds = %18
  %27 = getelementptr inbounds i8, ptr %0, i64 424
  %28 = load i32, ptr %27, align 8, !tbaa !171
  %29 = getelementptr inbounds i8, ptr %0, i64 432
  %30 = load i8, ptr %29, align 8, !tbaa !42, !range !14, !noundef !15
  %31 = trunc nuw i8 %30 to i1
  br i1 %31, label %32, label %66

32:                                               ; preds = %26
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #18
  store i64 0, ptr %5, align 8, !tbaa !7
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #18
  store i32 0, ptr %6, align 4, !tbaa !18
  %33 = load ptr, ptr %19, align 8, !tbaa !161
  %34 = call ptr @nv_xnu_alloc_md(ptr noundef %33, ptr noundef nonnull %5, ptr noundef nonnull %6) #15
  %35 = getelementptr inbounds i8, ptr %0, i64 360
  %36 = load i64, ptr %35, align 8, !tbaa !162
  %37 = shl i64 %36, 12
  %38 = icmp eq ptr %34, null
  br i1 %38, label %65, label %39

39:                                               ; preds = %32
  %40 = load i64, ptr %5, align 8, !tbaa !7
  %41 = icmp ult i64 %37, %40
  br i1 %41, label %46, label %42

42:                                               ; preds = %39
  %43 = load ptr, ptr %34, align 8, !tbaa !4
  %44 = getelementptr inbounds i8, ptr %43, i64 40
  %45 = load ptr, ptr %44, align 8
  call void %45(ptr noundef nonnull %34) #15
  br label %65

46:                                               ; preds = %39
  %47 = getelementptr inbounds i8, ptr %0, i64 408
  %48 = load i64, ptr %47, align 8, !tbaa !168
  %49 = icmp eq i64 %48, 0
  %50 = sub i64 %40, %37
  %51 = select i1 %49, i64 %50, i64 %48
  %52 = add i64 %51, %37
  %53 = icmp ugt i64 %52, %40
  %54 = select i1 %53, i64 %50, i64 %51
  %55 = call ptr @_ZN21IOSubMemoryDescriptor12withSubRangeEP18IOMemoryDescriptoryyj(ptr noundef nonnull %34, i64 noundef %37, i64 noundef %54, i32 noundef 3) #15
  %56 = load ptr, ptr %34, align 8, !tbaa !4
  %57 = getelementptr inbounds i8, ptr %56, i64 40
  %58 = load ptr, ptr %57, align 8
  call void %58(ptr noundef nonnull %34) #15
  %59 = load i32, ptr %6, align 4, !tbaa !18
  %60 = call zeroext i1 @nv_xnu_chat() #15
  br i1 %60, label %61, label %64

61:                                               ; preds = %46
  %62 = getelementptr inbounds i8, ptr %0, i64 436
  %63 = load i32, ptr %62, align 4, !tbaa !40
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.297, i32 noundef %63, i64 noundef %37, i64 noundef %54, i32 noundef %59) #15
  br label %64

64:                                               ; preds = %61, %46
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #18
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  br label %159

65:                                               ; preds = %32, %42
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #18
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #18
  br label %178

66:                                               ; preds = %26
  %67 = getelementptr inbounds i8, ptr %0, i64 384
  %68 = getelementptr inbounds i8, ptr %0, i64 392
  %69 = load i64, ptr %68, align 8, !tbaa !185
  switch i64 %69, label %87 [
    i64 1, label %70
    i64 0, label %108
  ]

70:                                               ; preds = %66
  %71 = load ptr, ptr %67, align 8, !tbaa !186
  %72 = load i64, ptr %71, align 8, !tbaa !187
  %73 = getelementptr inbounds i8, ptr %71, i64 8
  %74 = load i64, ptr %73, align 8, !tbaa !189
  %75 = tail call zeroext i1 @nv_pm_is_gpu(i64 noundef %72, i64 noundef %74) #15
  %76 = load ptr, ptr %67, align 8, !tbaa !186
  %77 = load i64, ptr %76, align 8, !tbaa !187
  %78 = getelementptr inbounds i8, ptr %76, i64 8
  %79 = load i64, ptr %78, align 8, !tbaa !189
  br i1 %75, label %85, label %80

80:                                               ; preds = %70
  %81 = getelementptr inbounds i8, ptr %0, i64 440
  %82 = load i32, ptr %81, align 8, !tbaa !26
  %83 = tail call ptr @nv_pm_ram_submd(i64 noundef %77, i64 noundef %79, i32 noundef %82) #15
  %84 = icmp eq ptr %83, null
  br i1 %84, label %178, label %151

85:                                               ; preds = %70
  %86 = tail call ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef %77, i64 noundef %79, i32 noundef 3) #15
  br label %151

87:                                               ; preds = %66, %101
  %88 = phi i64 [ %102, %101 ], [ 0, %66 ]
  %89 = load ptr, ptr %67, align 8, !tbaa !186
  %90 = getelementptr inbounds %struct.MemoryRange, ptr %89, i64 %88
  %91 = load i64, ptr %90, align 8, !tbaa !187
  %92 = getelementptr inbounds i8, ptr %90, i64 8
  %93 = load i64, ptr %92, align 8, !tbaa !189
  %94 = tail call zeroext i1 @nv_pm_is_gpu(i64 noundef %91, i64 noundef %93) #15
  br i1 %94, label %101, label %95

95:                                               ; preds = %87
  %96 = load ptr, ptr %67, align 8, !tbaa !186
  %97 = getelementptr inbounds %struct.MemoryRange, ptr %96, i64 %88
  %98 = load i64, ptr %97, align 8, !tbaa !187
  %99 = getelementptr inbounds i8, ptr %97, i64 8
  %100 = load i64, ptr %99, align 8, !tbaa !189
  tail call void @nv_pm_dev_refused(i64 noundef %98, i64 noundef %100) #15
  br label %178

101:                                              ; preds = %87
  %102 = add nuw i64 %88, 1
  %103 = icmp eq i64 %102, %69
  br i1 %103, label %104, label %87, !llvm.loop !190

104:                                              ; preds = %101
  %105 = shl i64 %69, 4
  %106 = tail call ptr @kern_os_malloc(i64 noundef %105) #15
  %107 = icmp eq ptr %106, null
  br i1 %107, label %178, label %112

108:                                              ; preds = %66
  %109 = shl nuw nsw i64 %69, 4
  %110 = tail call ptr @kern_os_malloc(i64 noundef %109) #15
  %111 = icmp eq ptr %110, null
  br i1 %111, label %178, label %147

112:                                              ; preds = %104
  %113 = load ptr, ptr %67, align 8, !tbaa !186
  %114 = and i64 %69, 1
  %115 = icmp eq i64 %69, 1
  br i1 %115, label %137, label %116

116:                                              ; preds = %112
  %117 = and i64 %69, -2
  br label %118

118:                                              ; preds = %118, %116
  %119 = phi i64 [ 0, %116 ], [ %134, %118 ]
  %120 = phi i64 [ 0, %116 ], [ %135, %118 ]
  %121 = getelementptr inbounds %struct.MemoryRange, ptr %113, i64 %119
  %122 = load i64, ptr %121, align 8, !tbaa !187
  %123 = getelementptr inbounds %struct.IOVirtualRange, ptr %106, i64 %119
  store i64 %122, ptr %123, align 8, !tbaa !191
  %124 = getelementptr inbounds %struct.MemoryRange, ptr %113, i64 %119, i32 1
  %125 = load i64, ptr %124, align 8, !tbaa !189
  %126 = getelementptr inbounds i8, ptr %123, i64 8
  store i64 %125, ptr %126, align 8, !tbaa !193
  %127 = or disjoint i64 %119, 1
  %128 = getelementptr inbounds %struct.MemoryRange, ptr %113, i64 %127
  %129 = load i64, ptr %128, align 8, !tbaa !187
  %130 = getelementptr inbounds %struct.IOVirtualRange, ptr %106, i64 %127
  store i64 %129, ptr %130, align 8, !tbaa !191
  %131 = getelementptr inbounds %struct.MemoryRange, ptr %113, i64 %127, i32 1
  %132 = load i64, ptr %131, align 8, !tbaa !189
  %133 = getelementptr inbounds i8, ptr %130, i64 8
  store i64 %132, ptr %133, align 8, !tbaa !193
  %134 = add nuw i64 %119, 2
  %135 = add i64 %120, 2
  %136 = icmp eq i64 %135, %117
  br i1 %136, label %137, label %118, !llvm.loop !194

137:                                              ; preds = %118, %112
  %138 = phi i64 [ 0, %112 ], [ %134, %118 ]
  %139 = icmp eq i64 %114, 0
  br i1 %139, label %147, label %140

140:                                              ; preds = %137
  %141 = getelementptr inbounds %struct.MemoryRange, ptr %113, i64 %138
  %142 = load i64, ptr %141, align 8, !tbaa !187
  %143 = getelementptr inbounds %struct.IOVirtualRange, ptr %106, i64 %138
  store i64 %142, ptr %143, align 8, !tbaa !191
  %144 = getelementptr inbounds %struct.MemoryRange, ptr %113, i64 %138, i32 1
  %145 = load i64, ptr %144, align 8, !tbaa !189
  %146 = getelementptr inbounds i8, ptr %143, i64 8
  store i64 %145, ptr %146, align 8, !tbaa !193
  br label %147

147:                                              ; preds = %140, %137, %108
  %148 = phi ptr [ %110, %108 ], [ %106, %137 ], [ %106, %140 ]
  %149 = trunc i64 %69 to i32
  %150 = tail call ptr @_ZN18IOMemoryDescriptor11withOptionsEPvjjP4taskjP8IOMapper(ptr noundef nonnull %148, i32 noundef %149, i32 noundef 0, ptr noundef null, i32 noundef 35, ptr noundef null) #15
  tail call void @kern_os_free(ptr noundef nonnull %148) #15
  br label %151

151:                                              ; preds = %80, %85, %147
  %152 = phi ptr [ %86, %85 ], [ %150, %147 ], [ %83, %80 ]
  %153 = getelementptr inbounds i8, ptr %0, i64 436
  %154 = load i32, ptr %153, align 4, !tbaa !40
  %155 = load ptr, ptr %67, align 8, !tbaa !186
  %156 = load i64, ptr %155, align 8, !tbaa !187
  %157 = getelementptr inbounds i8, ptr %155, i64 8
  %158 = load i64, ptr %157, align 8, !tbaa !189
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.298, i32 noundef %154, i64 noundef %69, i64 noundef %156, i64 noundef %158, i32 noundef %28) #15
  br label %159

159:                                              ; preds = %151, %64
  %160 = phi i32 [ %28, %151 ], [ %59, %64 ]
  %161 = phi ptr [ %152, %151 ], [ %55, %64 ]
  %162 = icmp eq ptr %161, null
  br i1 %162, label %178, label %163

163:                                              ; preds = %159
  switch i32 %160, label %169 [
    i32 1, label %165
    i32 2, label %164
  ]

164:                                              ; preds = %163
  br label %165

165:                                              ; preds = %163, %164
  %166 = phi i32 [ 1024, %164 ], [ 256, %163 ]
  %167 = load i32, ptr %2, align 4, !tbaa !18
  %168 = or i32 %167, %166
  store i32 %168, ptr %2, align 4, !tbaa !18
  br label %169

169:                                              ; preds = %165, %163
  %170 = getelementptr inbounds i8, ptr %0, i64 416
  %171 = load i32, ptr %170, align 8, !tbaa !169
  %172 = and i32 %171, 2
  %173 = icmp eq i32 %172, 0
  br i1 %173, label %174, label %177

174:                                              ; preds = %169
  %175 = load i32, ptr %2, align 4, !tbaa !18
  %176 = or i32 %175, 4096
  store i32 %176, ptr %2, align 4, !tbaa !18
  br label %177

177:                                              ; preds = %174, %169
  store ptr %161, ptr %3, align 8, !tbaa !10
  br label %178

178:                                              ; preds = %108, %104, %80, %95, %65, %23, %159, %177, %10, %14
  %179 = phi i32 [ -536870184, %14 ], [ -536870184, %10 ], [ -536870206, %23 ], [ 0, %177 ], [ -536870206, %65 ], [ -536870211, %159 ], [ -536870174, %80 ], [ -536870174, %95 ], [ -536870211, %104 ], [ -536870211, %108 ]
  call void @IOLockUnlock(ptr noundef nonnull %8) #15
  br label %180

180:                                              ; preds = %4, %178
  %181 = phi i32 [ %179, %178 ], [ -536870183, %4 ]
  ret i32 %181
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @nv_xnu_alloc_md(ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN21IOSubMemoryDescriptor12withSubRangeEP18IOMemoryDescriptoryyj(ptr noundef, i64 noundef, i64 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @nv_pm_is_gpu(i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @nv_pm_ram_submd(i64 noundef, i64 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @nv_pm_dev_refused(i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @kern_os_malloc(i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN18IOMemoryDescriptor11withOptionsEPvjjP4taskjP8IOMapper(ptr noundef, i32 noundef, i32 noundef, ptr noundef, i32 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @_ZN14NVRMUserClient14externalMethodEjP25IOExternalMethodArgumentsP24IOExternalMethodDispatchP8OSObjectPv(ptr noundef %0, i32 noundef %1, ptr noundef %2, ptr nocapture readnone %3, ptr nocapture readnone %4, ptr noundef %5) unnamed_addr #1 align 2 {
  %7 = alloca %struct.IOExternalMethodDispatch, align 8
  %8 = zext i32 %1 to i64
  %9 = icmp ugt i32 %1, 6
  br i1 %9, label %28, label %10

10:                                               ; preds = %6
  %11 = getelementptr inbounds i8, ptr %0, i64 464
  %12 = load ptr, ptr %11, align 8, !tbaa !148
  %13 = icmp eq ptr %12, null
  br i1 %13, label %28, label %14

14:                                               ; preds = %10
  tail call void @IOLockLock(ptr noundef nonnull %12) #15
  %15 = getelementptr inbounds i8, ptr %0, i64 472
  %16 = load i8, ptr %15, align 8, !tbaa !174, !range !14, !noundef !15
  %17 = trunc nuw i8 %16 to i1
  br i1 %17, label %26, label %18

18:                                               ; preds = %14
  %19 = getelementptr inbounds i8, ptr %0, i64 452
  %20 = load i8, ptr %19, align 4, !tbaa !172, !range !14, !noundef !15
  %21 = trunc nuw i8 %20 to i1
  br i1 %21, label %26, label %22

22:                                               ; preds = %18
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %7) #18
  %23 = getelementptr inbounds [7 x %struct.IOExternalMethodDispatch], ptr @_ZZN14NVRMUserClient14externalMethodEjP25IOExternalMethodArgumentsP24IOExternalMethodDispatchP8OSObjectPvE3tbl, i64 0, i64 %8
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %7, ptr noundef nonnull align 8 dereferenceable(24) %23, i64 24, i1 false), !tbaa.struct !195
  %24 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV12IOUserClient, i64 2144), align 8
  %25 = call i32 %24(ptr noundef nonnull %0, i32 noundef %1, ptr noundef %2, ptr noundef nonnull %7, ptr noundef nonnull %0, ptr noundef %5) #15
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %7) #18
  br label %26

26:                                               ; preds = %14, %18, %22
  %27 = phi i32 [ %25, %22 ], [ -536870184, %18 ], [ -536870184, %14 ]
  call void @IOLockUnlock(ptr noundef nonnull %12) #15
  br label %28

28:                                               ; preds = %10, %6, %26
  %29 = phi i32 [ %27, %26 ], [ -536870206, %6 ], [ -536870183, %10 ]
  ret i32 %29
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870212, 1) i32 @_ZN14NVRMUserClient3sGoEP8OSObjectPvP25IOExternalMethodArguments(ptr noundef %0, ptr nocapture readnone %1, ptr nocapture noundef readonly %2) #1 align 2 {
  %4 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %5 = icmp eq ptr %4, null
  br i1 %5, label %21, label %6

6:                                                ; preds = %3
  %7 = getelementptr inbounds i8, ptr %4, i64 224
  %8 = load ptr, ptr %7, align 8, !tbaa !151
  %9 = icmp eq ptr %8, null
  br i1 %9, label %21, label %10

10:                                               ; preds = %6
  %11 = tail call ptr @kauth_cred_get() #16
  %12 = tail call i32 @kauth_cred_issuser(ptr noundef %11) #15
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %21, label %14

14:                                               ; preds = %10
  %15 = load ptr, ptr %7, align 8, !tbaa !151
  %16 = getelementptr inbounds i8, ptr %2, i64 32
  %17 = load ptr, ptr %16, align 8, !tbaa !196
  %18 = load i64, ptr %17, align 8, !tbaa !7
  %19 = trunc i64 %18 to i32
  %20 = tail call i32 @_ZN4NVRM2goEj(ptr noundef %15, i32 noundef %19) #17
  br label %21

21:                                               ; preds = %10, %3, %6, %14
  %22 = phi i32 [ %20, %14 ], [ -536870183, %6 ], [ -536870183, %3 ], [ -536870207, %10 ]
  ret i32 %22
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @_ZN14NVRMUserClient4sEscEP8OSObjectPvP25IOExternalMethodArguments(ptr noundef %0, ptr nocapture readnone %1, ptr nocapture noundef %2) #1 align 2 {
  %4 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %5 = icmp eq ptr %4, null
  br i1 %5, label %93, label %6

6:                                                ; preds = %3
  %7 = getelementptr inbounds i8, ptr %4, i64 224
  %8 = load ptr, ptr %7, align 8, !tbaa !151
  %9 = icmp eq ptr %8, null
  br i1 %9, label %93, label %10

10:                                               ; preds = %6
  %11 = getelementptr inbounds i8, ptr %2, i64 32
  %12 = load ptr, ptr %11, align 8, !tbaa !196
  %13 = load i64, ptr %12, align 8, !tbaa !7
  %14 = trunc i64 %13 to i32
  %15 = getelementptr inbounds i8, ptr %2, i64 64
  %16 = load ptr, ptr %15, align 8, !tbaa !198
  %17 = icmp eq ptr %16, null
  br i1 %17, label %24, label %18

18:                                               ; preds = %10
  %19 = load ptr, ptr %16, align 8, !tbaa !4
  %20 = getelementptr inbounds i8, ptr %19, i64 456
  %21 = load ptr, ptr %20, align 8
  %22 = tail call i64 %21(ptr noundef nonnull %16) #15
  %23 = trunc i64 %22 to i32
  br label %27

24:                                               ; preds = %10
  %25 = getelementptr inbounds i8, ptr %2, i64 56
  %26 = load i32, ptr %25, align 8, !tbaa !199
  br label %27

27:                                               ; preds = %24, %18
  %28 = phi i32 [ %23, %18 ], [ %26, %24 ]
  %29 = add i32 %28, -1048577
  %30 = icmp ult i32 %29, -1048576
  br i1 %30, label %93, label %31

31:                                               ; preds = %27
  %32 = zext nneg i32 %28 to i64
  %33 = tail call ptr @kern_os_malloc(i64 noundef %32) #15
  %34 = icmp eq ptr %33, null
  br i1 %34, label %93, label %35

35:                                               ; preds = %31
  %36 = load ptr, ptr %15, align 8, !tbaa !198
  %37 = icmp eq ptr %36, null
  br i1 %37, label %55, label %38

38:                                               ; preds = %35
  %39 = load ptr, ptr %36, align 8, !tbaa !4
  %40 = getelementptr inbounds i8, ptr %39, i64 496
  %41 = load ptr, ptr %40, align 8
  %42 = tail call i32 %41(ptr noundef nonnull %36, i32 noundef 0) #15
  %43 = icmp eq i32 %42, 0
  br i1 %43, label %44, label %91

44:                                               ; preds = %38
  %45 = load ptr, ptr %15, align 8, !tbaa !198
  %46 = load ptr, ptr %45, align 8, !tbaa !4
  %47 = getelementptr inbounds i8, ptr %46, i64 480
  %48 = load ptr, ptr %47, align 8
  %49 = tail call i64 %48(ptr noundef nonnull %45, i64 noundef 0, ptr noundef nonnull %33, i64 noundef %32) #15
  %50 = load ptr, ptr %15, align 8, !tbaa !198
  %51 = load ptr, ptr %50, align 8, !tbaa !4
  %52 = getelementptr inbounds i8, ptr %51, i64 504
  %53 = load ptr, ptr %52, align 8
  %54 = tail call i32 %53(ptr noundef nonnull %50, i32 noundef 0) #15
  br label %59

55:                                               ; preds = %35
  %56 = getelementptr inbounds i8, ptr %2, i64 48
  %57 = load ptr, ptr %56, align 8, !tbaa !200
  %58 = tail call { ptr, ptr, i64 } asm sideeffect "rep movsb", "={di},={si},={cx},0,1,2,~{memory},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %33, ptr %57, i64 %32) #18, !srcloc !201
  br label %59

59:                                               ; preds = %55, %44
  %60 = tail call i32 @_ZN14NVRMUserClient3escEjPvj(ptr noundef nonnull %4, i32 noundef %14, ptr noundef nonnull %33, i32 noundef %28) #17
  %61 = getelementptr inbounds i8, ptr %2, i64 104
  %62 = load ptr, ptr %61, align 8, !tbaa !202
  %63 = icmp eq ptr %62, null
  br i1 %63, label %81, label %64

64:                                               ; preds = %59
  %65 = load ptr, ptr %62, align 8, !tbaa !4
  %66 = getelementptr inbounds i8, ptr %65, i64 496
  %67 = load ptr, ptr %66, align 8
  %68 = tail call i32 %67(ptr noundef nonnull %62, i32 noundef 0) #15
  %69 = icmp eq i32 %68, 0
  br i1 %69, label %70, label %91

70:                                               ; preds = %64
  %71 = load ptr, ptr %61, align 8, !tbaa !202
  %72 = load ptr, ptr %71, align 8, !tbaa !4
  %73 = getelementptr inbounds i8, ptr %72, i64 488
  %74 = load ptr, ptr %73, align 8
  %75 = tail call i64 %74(ptr noundef nonnull %71, i64 noundef 0, ptr noundef nonnull %33, i64 noundef %32) #15
  %76 = load ptr, ptr %61, align 8, !tbaa !202
  %77 = load ptr, ptr %76, align 8, !tbaa !4
  %78 = getelementptr inbounds i8, ptr %77, i64 504
  %79 = load ptr, ptr %78, align 8
  %80 = tail call i32 %79(ptr noundef nonnull %76, i32 noundef 0) #15
  br label %91

81:                                               ; preds = %59
  %82 = getelementptr inbounds i8, ptr %2, i64 88
  %83 = load ptr, ptr %82, align 8, !tbaa !203
  %84 = icmp eq ptr %83, null
  br i1 %84, label %91, label %85

85:                                               ; preds = %81
  %86 = getelementptr inbounds i8, ptr %2, i64 96
  %87 = load i32, ptr %86, align 8, !tbaa !204
  %88 = icmp ult i32 %87, %28
  br i1 %88, label %91, label %89

89:                                               ; preds = %85
  %90 = tail call { ptr, ptr, i64 } asm sideeffect "rep movsb", "={di},={si},={cx},0,1,2,~{memory},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %83, ptr nonnull %33, i64 %32) #18, !srcloc !201
  store i32 %28, ptr %86, align 8, !tbaa !204
  br label %91

91:                                               ; preds = %70, %64, %89, %85, %81, %38
  %92 = phi i32 [ -536870200, %38 ], [ %60, %81 ], [ %60, %85 ], [ %60, %89 ], [ %60, %64 ], [ %60, %70 ]
  tail call void @kern_os_free(ptr noundef nonnull %33) #15
  br label %93

93:                                               ; preds = %91, %27, %31, %3, %6
  %94 = phi i32 [ -536870183, %6 ], [ -536870183, %3 ], [ -536870206, %27 ], [ -536870211, %31 ], [ %92, %91 ]
  ret i32 %94
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870183, 1) i32 @_ZN14NVRMUserClient6sGetFdEP8OSObjectPvP25IOExternalMethodArguments(ptr noundef %0, ptr nocapture readnone %1, ptr nocapture noundef readonly %2) #1 align 2 {
  %4 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %5 = icmp eq ptr %4, null
  br i1 %5, label %12, label %6

6:                                                ; preds = %3
  %7 = getelementptr inbounds i8, ptr %4, i64 436
  %8 = load i32, ptr %7, align 4, !tbaa !40
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds i8, ptr %2, i64 72
  %11 = load ptr, ptr %10, align 8, !tbaa !205
  store i64 %9, ptr %11, align 8, !tbaa !7
  br label %12

12:                                               ; preds = %3, %6
  %13 = phi i32 [ 0, %6 ], [ -536870183, %3 ]
  ret i32 %13
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870206, 1) i32 @_ZN14NVRMUserClient7sBindFdEP8OSObjectPvP25IOExternalMethodArguments(ptr noundef %0, ptr nocapture readnone %1, ptr nocapture noundef readonly %2) #1 align 2 {
  %4 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %5 = icmp eq ptr %4, null
  br i1 %5, label %38, label %6

6:                                                ; preds = %3
  %7 = getelementptr inbounds i8, ptr %2, i64 32
  %8 = load ptr, ptr %7, align 8, !tbaa !196
  %9 = load i64, ptr %8, align 8, !tbaa !7
  %10 = add i64 %9, -2147483648
  %11 = icmp ult i64 %10, -4294967296
  br i1 %11, label %38, label %12

12:                                               ; preds = %6
  %13 = trunc nsw i64 %9 to i32
  %14 = getelementptr inbounds i8, ptr %4, i64 448
  store i32 %13, ptr %14, align 8, !tbaa !37
  %15 = getelementptr inbounds i8, ptr %4, i64 444
  store i8 1, ptr %15, align 4, !tbaa !39
  %16 = icmp sgt i64 %9, -1
  br i1 %16, label %17, label %30

17:                                               ; preds = %12
  %18 = getelementptr inbounds i8, ptr %4, i64 420
  %19 = load i8, ptr %18, align 4, !tbaa !206
  %20 = icmp eq i8 %19, 0
  br i1 %20, label %30, label %21

21:                                               ; preds = %17
  %22 = getelementptr inbounds i8, ptr %4, i64 352
  %23 = getelementptr inbounds i8, ptr %4, i64 436
  %24 = load i32, ptr %23, align 4, !tbaa !40
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.305, i32 noundef %24, i32 noundef %13) #15
  %25 = getelementptr inbounds i8, ptr %4, i64 384
  %26 = load ptr, ptr %25, align 8, !tbaa !186
  %27 = icmp eq ptr %26, null
  br i1 %27, label %29, label %28

28:                                               ; preds = %21
  tail call void @kern_os_free(ptr noundef nonnull %26) #15
  br label %29

29:                                               ; preds = %21, %28
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(80) %22, i8 0, i64 80, i1 false)
  br label %30

30:                                               ; preds = %29, %17, %12
  %31 = tail call zeroext i1 @nv_xnu_chat() #15
  br i1 %31, label %32, label %38

32:                                               ; preds = %30
  %33 = getelementptr inbounds i8, ptr %4, i64 436
  %34 = load i32, ptr %33, align 4, !tbaa !40
  %35 = getelementptr inbounds i8, ptr %4, i64 440
  %36 = load i32, ptr %35, align 8, !tbaa !26
  %37 = load i32, ptr %14, align 8, !tbaa !37
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.306, i32 noundef %34, i32 noundef %36, i32 noundef %37) #15
  br label %38

38:                                               ; preds = %6, %32, %30, %3
  %39 = phi i32 [ -536870183, %3 ], [ -536870206, %6 ], [ 0, %32 ], [ 0, %30 ]
  ret i32 %39
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870212, 1) i32 @_ZN14NVRMUserClient4sKmsEP8OSObjectPvP25IOExternalMethodArguments(ptr noundef %0, ptr nocapture readnone %1, ptr nocapture noundef %2) #1 align 2 {
  %4 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %5 = icmp eq ptr %4, null
  br i1 %5, label %111, label %6

6:                                                ; preds = %3
  %7 = getelementptr inbounds i8, ptr %4, i64 224
  %8 = load ptr, ptr %7, align 8, !tbaa !151
  %9 = icmp eq ptr %8, null
  br i1 %9, label %111, label %10

10:                                               ; preds = %6
  %11 = tail call i32 @kauth_getuid() #15
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %111

13:                                               ; preds = %10
  %14 = getelementptr inbounds i8, ptr %2, i64 32
  %15 = load ptr, ptr %14, align 8, !tbaa !196
  %16 = load i64, ptr %15, align 8, !tbaa !7
  %17 = trunc i64 %16 to i32
  %18 = getelementptr inbounds i8, ptr %2, i64 64
  %19 = load ptr, ptr %18, align 8, !tbaa !198
  %20 = icmp eq ptr %19, null
  br i1 %20, label %27, label %21

21:                                               ; preds = %13
  %22 = load ptr, ptr %19, align 8, !tbaa !4
  %23 = getelementptr inbounds i8, ptr %22, i64 456
  %24 = load ptr, ptr %23, align 8
  %25 = tail call i64 %24(ptr noundef nonnull %19) #15
  %26 = trunc i64 %25 to i32
  br label %30

27:                                               ; preds = %13
  %28 = getelementptr inbounds i8, ptr %2, i64 56
  %29 = load i32, ptr %28, align 8, !tbaa !199
  br label %30

30:                                               ; preds = %27, %21
  %31 = phi i32 [ %26, %21 ], [ %29, %27 ]
  %32 = add i32 %31, -1048577
  %33 = icmp ult i32 %32, -1048576
  br i1 %33, label %111, label %34

34:                                               ; preds = %30
  %35 = getelementptr inbounds i8, ptr %4, i64 456
  %36 = load ptr, ptr %35, align 8, !tbaa !173
  %37 = icmp eq ptr %36, null
  br i1 %37, label %38, label %44

38:                                               ; preds = %34
  %39 = getelementptr inbounds i8, ptr %4, i64 440
  %40 = load i32, ptr %39, align 8, !tbaa !26
  %41 = tail call ptr @nvkms_xnu_open(i32 noundef %40) #15
  store ptr %41, ptr %35, align 8, !tbaa !173
  %42 = icmp eq ptr %41, null
  br i1 %42, label %43, label %44

43:                                               ; preds = %38
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.299) #15
  br label %111

44:                                               ; preds = %38, %34
  %45 = zext nneg i32 %31 to i64
  %46 = tail call ptr @kern_os_malloc(i64 noundef %45) #15
  %47 = icmp eq ptr %46, null
  br i1 %47, label %111, label %48

48:                                               ; preds = %44
  %49 = load ptr, ptr %18, align 8, !tbaa !198
  %50 = icmp eq ptr %49, null
  br i1 %50, label %69, label %51

51:                                               ; preds = %48
  %52 = load ptr, ptr %49, align 8, !tbaa !4
  %53 = getelementptr inbounds i8, ptr %52, i64 496
  %54 = load ptr, ptr %53, align 8
  %55 = tail call i32 %54(ptr noundef nonnull %49, i32 noundef 0) #15
  %56 = icmp eq i32 %55, 0
  br i1 %56, label %58, label %57

57:                                               ; preds = %51
  tail call void @kern_os_free(ptr noundef nonnull %46) #15
  br label %111

58:                                               ; preds = %51
  %59 = load ptr, ptr %18, align 8, !tbaa !198
  %60 = load ptr, ptr %59, align 8, !tbaa !4
  %61 = getelementptr inbounds i8, ptr %60, i64 480
  %62 = load ptr, ptr %61, align 8
  %63 = tail call i64 %62(ptr noundef nonnull %59, i64 noundef 0, ptr noundef nonnull %46, i64 noundef %45) #15
  %64 = load ptr, ptr %18, align 8, !tbaa !198
  %65 = load ptr, ptr %64, align 8, !tbaa !4
  %66 = getelementptr inbounds i8, ptr %65, i64 504
  %67 = load ptr, ptr %66, align 8
  %68 = tail call i32 %67(ptr noundef nonnull %64, i32 noundef 0) #15
  br label %73

69:                                               ; preds = %48
  %70 = getelementptr inbounds i8, ptr %2, i64 48
  %71 = load ptr, ptr %70, align 8, !tbaa !200
  %72 = tail call { ptr, ptr, i64 } asm sideeffect "rep movsb", "={di},={si},={cx},0,1,2,~{memory},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %46, ptr %71, i64 %45) #18, !srcloc !201
  br label %73

73:                                               ; preds = %69, %58
  %74 = load ptr, ptr %35, align 8, !tbaa !173
  %75 = tail call i32 @nvkms_xnu_ioctl(ptr noundef %74, i32 noundef %17, ptr noundef nonnull %46, i64 noundef %45) #15
  %76 = icmp eq i32 %75, 0
  br i1 %76, label %78, label %77

77:                                               ; preds = %73
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.300, i32 noundef %17, i32 noundef %31) #15
  br label %78

78:                                               ; preds = %77, %73
  %79 = getelementptr inbounds i8, ptr %2, i64 104
  %80 = load ptr, ptr %79, align 8, !tbaa !202
  %81 = icmp eq ptr %80, null
  br i1 %81, label %99, label %82

82:                                               ; preds = %78
  %83 = load ptr, ptr %80, align 8, !tbaa !4
  %84 = getelementptr inbounds i8, ptr %83, i64 496
  %85 = load ptr, ptr %84, align 8
  %86 = tail call i32 %85(ptr noundef nonnull %80, i32 noundef 0) #15
  %87 = icmp eq i32 %86, 0
  br i1 %87, label %88, label %109

88:                                               ; preds = %82
  %89 = load ptr, ptr %79, align 8, !tbaa !202
  %90 = load ptr, ptr %89, align 8, !tbaa !4
  %91 = getelementptr inbounds i8, ptr %90, i64 488
  %92 = load ptr, ptr %91, align 8
  %93 = tail call i64 %92(ptr noundef nonnull %89, i64 noundef 0, ptr noundef nonnull %46, i64 noundef %45) #15
  %94 = load ptr, ptr %79, align 8, !tbaa !202
  %95 = load ptr, ptr %94, align 8, !tbaa !4
  %96 = getelementptr inbounds i8, ptr %95, i64 504
  %97 = load ptr, ptr %96, align 8
  %98 = tail call i32 %97(ptr noundef nonnull %94, i32 noundef 0) #15
  br label %109

99:                                               ; preds = %78
  %100 = getelementptr inbounds i8, ptr %2, i64 88
  %101 = load ptr, ptr %100, align 8, !tbaa !203
  %102 = icmp eq ptr %101, null
  br i1 %102, label %109, label %103

103:                                              ; preds = %99
  %104 = getelementptr inbounds i8, ptr %2, i64 96
  %105 = load i32, ptr %104, align 8, !tbaa !204
  %106 = icmp ult i32 %105, %31
  br i1 %106, label %109, label %107

107:                                              ; preds = %103
  %108 = tail call { ptr, ptr, i64 } asm sideeffect "rep movsb", "={di},={si},={cx},0,1,2,~{memory},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %101, ptr nonnull %46, i64 %45) #18, !srcloc !201
  store i32 %31, ptr %104, align 8, !tbaa !204
  br label %109

109:                                              ; preds = %99, %103, %107, %82, %88
  tail call void @kern_os_free(ptr noundef nonnull %46) #15
  %110 = select i1 %76, i32 0, i32 -536870212
  br label %111

111:                                              ; preds = %43, %30, %44, %109, %57, %10, %3, %6
  %112 = phi i32 [ -536870183, %6 ], [ -536870183, %3 ], [ -536870207, %10 ], [ -536870184, %43 ], [ -536870206, %30 ], [ -536870200, %57 ], [ %110, %109 ], [ -536870211, %44 ]
  ret i32 %112
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870207, 1) i32 @_ZN14NVRMUserClient10sKmsEventsEP8OSObjectPvP25IOExternalMethodArguments(ptr noundef %0, ptr nocapture readnone %1, ptr nocapture noundef readonly %2) #1 align 2 {
  %4 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %5 = icmp eq ptr %4, null
  br i1 %5, label %16, label %6

6:                                                ; preds = %3
  %7 = tail call i32 @kauth_getuid() #15
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %16

9:                                                ; preds = %6
  %10 = getelementptr inbounds i8, ptr %4, i64 456
  %11 = load ptr, ptr %10, align 8, !tbaa !173
  %12 = tail call i32 @nvkms_xnu_events_available(ptr noundef %11) #15
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds i8, ptr %2, i64 72
  %15 = load ptr, ptr %14, align 8, !tbaa !205
  store i64 %13, ptr %15, align 8, !tbaa !7
  br label %16

16:                                               ; preds = %6, %3, %9
  %17 = phi i32 [ 0, %9 ], [ -536870183, %3 ], [ -536870207, %6 ]
  ret i32 %17
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870183, 1) i32 @_ZN14NVRMUserClient10sWaitEventEP8OSObjectPvP25IOExternalMethodArguments(ptr noundef %0, ptr nocapture readnone %1, ptr nocapture noundef readonly %2) #1 align 2 {
  %4 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef %0, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  %5 = icmp eq ptr %4, null
  br i1 %5, label %41, label %6

6:                                                ; preds = %3
  %7 = getelementptr inbounds i8, ptr %2, i64 32
  %8 = load ptr, ptr %7, align 8, !tbaa !196
  %9 = load i64, ptr %8, align 8, !tbaa !7
  %10 = trunc i64 %9 to i32
  %11 = getelementptr inbounds i8, ptr %8, i64 8
  %12 = load i64, ptr %11, align 8, !tbaa !7
  %13 = tail call i64 @llvm.umin.i64(i64 %12, i64 100000)
  %14 = tail call i64 @OSAddAtomic64(i64 noundef 1, ptr noundef nonnull @_ZL11gNvEvtWaits) #15
  %15 = icmp eq i64 %12, 0
  br i1 %15, label %35, label %16

16:                                               ; preds = %6
  %17 = getelementptr inbounds i8, ptr %4, i64 476
  %18 = load volatile i32, ptr %17, align 4, !tbaa !175
  %19 = icmp eq i32 %18, %10
  br i1 %19, label %20, label %35

20:                                               ; preds = %16
  %21 = tail call i32 @OSIncrementAtomic(ptr noundef nonnull @_ZL14gNvEvtSleepers) #15
  %22 = icmp sgt i32 %21, 255
  br i1 %22, label %33, label %23

23:                                               ; preds = %20
  %24 = trunc nuw nsw i64 %13 to i32
  %25 = tail call i32 @assert_wait_timeout(ptr noundef nonnull %17, i32 noundef 2, i32 noundef %24, i32 noundef 1000) #15
  %26 = load volatile i32, ptr %17, align 4, !tbaa !175
  %27 = icmp eq i32 %26, %10
  br i1 %27, label %30, label %28

28:                                               ; preds = %23
  %29 = tail call i32 @thread_wakeup_prim(ptr noundef nonnull %17, i32 noundef 0, i32 noundef 0) #15
  br label %30

30:                                               ; preds = %28, %23
  %31 = tail call i64 @OSAddAtomic64(i64 noundef 1, ptr noundef nonnull @_ZL11gNvEvtSlept) #15
  %32 = tail call i32 @thread_block(ptr noundef null) #15
  br label %33

33:                                               ; preds = %20, %30
  %34 = tail call i32 @OSDecrementAtomic(ptr noundef nonnull @_ZL14gNvEvtSleepers) #15
  br label %35

35:                                               ; preds = %33, %16, %6
  %36 = getelementptr inbounds i8, ptr %4, i64 476
  %37 = load volatile i32, ptr %36, align 4, !tbaa !175
  %38 = zext i32 %37 to i64
  %39 = getelementptr inbounds i8, ptr %2, i64 72
  %40 = load ptr, ptr %39, align 8, !tbaa !205
  store i64 %38, ptr %40, align 8, !tbaa !7
  br label %41

41:                                               ; preds = %3, %35
  %42 = phi i32 [ 0, %35 ], [ -536870183, %3 ]
  ret i32 %42
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none)
define ptr @nv_xnu_gpu_state() local_unnamed_addr #6 {
  %1 = load ptr, ptr @_ZL12gNVRMService, align 8
  %2 = icmp eq ptr %1, null
  %3 = getelementptr inbounds i8, ptr %1, i64 336
  %4 = select i1 %2, ptr null, ptr %3
  ret ptr %4
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none)
define ptr @nv_xnu_gpu_os_device() local_unnamed_addr #6 {
  %1 = load ptr, ptr @_ZL12gNVRMService, align 8, !tbaa !10
  ret ptr %1
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @nvkms_xnu_open(i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @nvkms_xnu_ioctl(ptr noundef, i32 noundef, ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @nvkms_xnu_events_available(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(argmem: read)
define ptr @_ZN14NVRMUserClient8fromNvfpEP17nv_file_private_t(ptr noundef readonly %0) local_unnamed_addr #12 align 2 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %9, label %3

3:                                                ; preds = %1
  %4 = getelementptr inbounds i8, ptr %0, i64 -232
  %5 = getelementptr inbounds i8, ptr %0, i64 248
  %6 = load i32, ptr %5, align 8, !tbaa !176
  %7 = icmp eq i32 %6, 1314276694
  %8 = select i1 %7, ptr %4, ptr null
  br label %9

9:                                                ; preds = %1, %3
  %10 = phi ptr [ %8, %3 ], [ null, %1 ]
  ret ptr %10
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @nv_post_event(ptr noundef readonly %0, i32 noundef %1, i32 noundef %2, i32 %3, i16 zeroext %4, i8 zeroext %5) #1 {
  %7 = tail call i64 @OSAddAtomic64(i64 noundef 1, ptr noundef nonnull @_ZL11gNvEvtPosts) #15
  %8 = icmp eq ptr %0, null
  br i1 %8, label %22, label %9

9:                                                ; preds = %6
  %10 = getelementptr inbounds i8, ptr %0, i64 24
  %11 = load ptr, ptr %10, align 8, !tbaa !207
  %12 = icmp eq ptr %11, null
  br i1 %12, label %22, label %13

13:                                               ; preds = %9
  %14 = getelementptr inbounds i8, ptr %11, i64 248
  %15 = load i32, ptr %14, align 8, !tbaa !176
  %16 = icmp eq i32 %15, 1314276694
  br i1 %16, label %17, label %22

17:                                               ; preds = %13
  %18 = tail call i64 @OSAddAtomic64(i64 noundef 1, ptr noundef nonnull @_ZL13gNvEvtMatched) #15
  %19 = getelementptr inbounds i8, ptr %11, i64 244
  %20 = tail call i32 @OSIncrementAtomic(ptr noundef nonnull %19) #15
  %21 = tail call i32 @thread_wakeup_prim(ptr noundef nonnull %19, i32 noundef 0, i32 noundef 0) #15
  br label %22

22:                                               ; preds = %9, %13, %6, %17
  %23 = phi ptr [ @.str.303, %17 ], [ @.str.304, %6 ], [ @.str.304, %13 ], [ @.str.304, %9 ]
  switch i64 %7, label %30 [
    i64 999999, label %24
    i64 99999, label %24
    i64 999, label %24
  ]

24:                                               ; preds = %22, %22, %22
  %25 = add nuw nsw i64 %7, 1
  %26 = tail call ptr @current_thread() #16
  %27 = load volatile ptr, ptr @nv_xnu_isr_thread, align 8, !tbaa !10
  %28 = icmp eq ptr %26, %27
  %29 = zext i1 %28 to i32
  tail call void (ptr, ...) @OSReportWithBacktrace(ptr noundef nonnull @.str.301, i64 noundef %25, ptr noundef nonnull @nv_post_event, i32 noundef %29) #15
  br label %33

30:                                               ; preds = %22
  %31 = icmp slt i64 %7, 4
  %32 = add nsw i64 %7, 1
  br i1 %31, label %37, label %33

33:                                               ; preds = %30, %24
  %34 = phi i64 [ %25, %24 ], [ %32, %30 ]
  %35 = and i64 %34, 16383
  %36 = icmp eq i64 %35, 0
  br i1 %36, label %37, label %42

37:                                               ; preds = %30, %33
  %38 = phi i64 [ %34, %33 ], [ %32, %30 ]
  %39 = load volatile i64, ptr @_ZL13gNvEvtMatched, align 8, !tbaa !7
  %40 = load volatile i64, ptr @_ZL11gNvEvtWaits, align 8, !tbaa !7
  %41 = load volatile i64, ptr @_ZL11gNvEvtSlept, align 8, !tbaa !7
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.302, i64 noundef %38, i32 noundef %1, i32 noundef %2, ptr noundef nonnull %23, i64 noundef %39, i64 noundef %40, i64 noundef %41) #15
  br label %42

42:                                               ; preds = %37, %33
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @OSIncrementAtomic(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @thread_wakeup_prim(ptr noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @OSReportWithBacktrace(ptr noundef, ...) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @OSDecrementAtomic(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @assert_wait_timeout(ptr noundef, i32 noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @thread_block(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 -536870212, 1) i32 @_ZN14NVRMUserClient3escEjPvj(ptr noundef %0, i32 noundef %1, ptr noundef %2, i32 noundef %3) local_unnamed_addr #1 align 2 {
  %5 = getelementptr inbounds i8, ptr %0, i64 224
  %6 = load ptr, ptr %5, align 8, !tbaa !151
  %7 = icmp eq ptr %6, null
  br i1 %7, label %12, label %8

8:                                                ; preds = %4
  %9 = getelementptr inbounds i8, ptr %6, i64 1268
  %10 = load i32, ptr %9, align 4, !tbaa !117
  %11 = icmp ult i32 %10, 2
  br i1 %11, label %12, label %15

12:                                               ; preds = %8, %4
  %13 = load i1, ptr @_ZZN14NVRMUserClient3escEjPvjE4once, align 1
  br i1 %13, label %118, label %14

14:                                               ; preds = %12
  store i1 true, ptr @_ZZN14NVRMUserClient3escEjPvjE4once, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.307, i32 noundef %1) #15
  br label %118

15:                                               ; preds = %8
  %16 = getelementptr inbounds i8, ptr %0, i64 432
  %17 = load i8, ptr %16, align 8, !tbaa !42, !range !14, !noundef !15
  %18 = trunc nuw i8 %17 to i1
  br i1 %18, label %19, label %21

19:                                               ; preds = %15
  %20 = tail call ptr @nv_get_ctl_state() #15
  br label %23

21:                                               ; preds = %15
  %22 = getelementptr inbounds i8, ptr %6, i64 336
  br label %23

23:                                               ; preds = %19, %21
  %24 = phi ptr [ %20, %19 ], [ %22, %21 ]
  %25 = tail call i32 @nv_xnu_pm_enter() #17
  switch i32 %1, label %96 [
    i32 200, label %26
    i32 210, label %57
    i32 227, label %64
    i32 226, label %64
  ]

26:                                               ; preds = %23
  %27 = load i8, ptr %16, align 8, !tbaa !42, !range !14, !noundef !15
  %28 = trunc nuw i8 %27 to i1
  br i1 %28, label %29, label %101

29:                                               ; preds = %26
  %30 = zext i32 %3 to i64
  %31 = tail call { ptr, i64 } asm sideeffect "rep stosb", "={di},={cx},{ax},0,1,~{memory},~{dirflag},~{fpsr},~{flags}"(i32 0, ptr %2, i64 %30) #18, !srcloc !177
  %32 = icmp ult i32 %3, 72
  br i1 %32, label %101, label %33

33:                                               ; preds = %29
  %34 = load ptr, ptr %5, align 8, !tbaa !151
  store i8 1, ptr %2, align 8, !tbaa !209
  %35 = getelementptr inbounds i8, ptr %34, i64 356
  %36 = getelementptr inbounds i8, ptr %2, i64 4
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %36, ptr noundef nonnull align 4 dereferenceable(12) %35, i64 12, i1 false), !tbaa.struct !211
  %37 = getelementptr inbounds i8, ptr %34, i64 372
  %38 = load i32, ptr %37, align 4, !tbaa !131
  %39 = getelementptr inbounds i8, ptr %2, i64 16
  store i32 %38, ptr %39, align 8, !tbaa !213
  %40 = getelementptr inbounds i8, ptr %34, i64 716
  %41 = load i32, ptr %40, align 4, !tbaa !130
  %42 = trunc i32 %41 to i16
  %43 = getelementptr inbounds i8, ptr %2, i64 20
  store i16 %42, ptr %43, align 4, !tbaa !214
  %44 = getelementptr inbounds i8, ptr %34, i64 480
  %45 = load i64, ptr %44, align 8, !tbaa !113
  %46 = getelementptr inbounds i8, ptr %2, i64 24
  store i64 %45, ptr %46, align 8, !tbaa !215
  %47 = getelementptr inbounds i8, ptr %34, i64 488
  %48 = load i64, ptr %47, align 8, !tbaa !114
  %49 = getelementptr inbounds i8, ptr %2, i64 32
  store i64 %48, ptr %49, align 8, !tbaa !216
  %50 = getelementptr inbounds i8, ptr %34, i64 520
  %51 = load i64, ptr %50, align 8, !tbaa !113
  %52 = getelementptr inbounds i8, ptr %2, i64 40
  store i64 %51, ptr %52, align 8, !tbaa !217
  %53 = getelementptr inbounds i8, ptr %34, i64 528
  %54 = load i64, ptr %53, align 8, !tbaa !114
  %55 = getelementptr inbounds i8, ptr %2, i64 48
  store i64 %54, ptr %55, align 8, !tbaa !218
  %56 = getelementptr inbounds i8, ptr %2, i64 56
  store i32 0, ptr %56, align 8, !tbaa !219
  br label %101

57:                                               ; preds = %23
  %58 = load i8, ptr %16, align 8, !tbaa !42, !range !14, !noundef !15
  %59 = trunc nuw i8 %58 to i1
  br i1 %59, label %60, label %101

60:                                               ; preds = %57
  %61 = tail call i32 @rm_perform_version_check(ptr noundef null, ptr noundef %2, i32 noundef %3) #15
  %62 = icmp eq i32 %61, 0
  %63 = select i1 %62, i32 0, i32 -536870206
  br label %101

64:                                               ; preds = %23, %23
  %65 = icmp eq i32 %3, 40
  br i1 %65, label %66, label %101

66:                                               ; preds = %64
  %67 = getelementptr inbounds i8, ptr %2, i64 24
  store i32 -2147483646, ptr %67, align 8, !tbaa !220
  %68 = load ptr, ptr @_ZZN14NVRMUserClient3escEjPvjE5accel, align 8, !tbaa !10
  %69 = icmp eq ptr %68, null
  br i1 %69, label %70, label %81

70:                                               ; preds = %66
  %71 = tail call ptr @_ZN9IOService15serviceMatchingEPKcP12OSDictionary(ptr noundef nonnull @.str.308, ptr noundef null) #15
  %72 = icmp eq ptr %71, null
  br i1 %72, label %78, label %73

73:                                               ; preds = %70
  %74 = tail call ptr @_ZN9IOService22waitForMatchingServiceEP12OSDictionaryy(ptr noundef nonnull %71, i64 noundef 100000000) #15
  store ptr %74, ptr @_ZZN14NVRMUserClient3escEjPvjE5accel, align 8, !tbaa !10
  %75 = load ptr, ptr %71, align 8, !tbaa !4
  %76 = getelementptr inbounds i8, ptr %75, i64 40
  %77 = load ptr, ptr %76, align 8
  tail call void %77(ptr noundef nonnull %71) #15
  br label %78

78:                                               ; preds = %70, %73
  %79 = load ptr, ptr @_ZZN14NVRMUserClient3escEjPvjE5accel, align 8, !tbaa !10
  %80 = icmp eq ptr %79, null
  br i1 %80, label %101, label %81

81:                                               ; preds = %66, %78
  %82 = tail call ptr @_ZN8OSSymbol17withCStringNoCopyEPKc(ptr noundef nonnull @.str.309) #15
  %83 = icmp eq ptr %82, null
  br i1 %83, label %101, label %84

84:                                               ; preds = %81
  %85 = load ptr, ptr @_ZZN14NVRMUserClient3escEjPvjE5accel, align 8, !tbaa !10
  %86 = tail call ptr @current_task() #16
  %87 = zext nneg i32 %1 to i64
  %88 = inttoptr i64 %87 to ptr
  %89 = load ptr, ptr %85, align 8, !tbaa !4
  %90 = getelementptr inbounds i8, ptr %89, i64 1720
  %91 = load ptr, ptr %90, align 8
  %92 = tail call i32 %91(ptr noundef nonnull %85, ptr noundef nonnull %82, i1 noundef zeroext false, ptr noundef nonnull %2, ptr noundef %86, ptr noundef %88, ptr noundef null) #15
  %93 = load ptr, ptr %82, align 8, !tbaa !4
  %94 = getelementptr inbounds i8, ptr %93, i64 40
  %95 = load ptr, ptr %94, align 8
  tail call void %95(ptr noundef nonnull %82) #15
  br label %101

96:                                               ; preds = %23
  %97 = getelementptr inbounds i8, ptr %0, i64 232
  %98 = tail call i32 @rm_ioctl(ptr noundef null, ptr noundef %24, ptr noundef nonnull %97, i32 noundef %1, ptr noundef %2, i32 noundef %3) #15
  %99 = icmp eq i32 %98, 0
  br i1 %99, label %101, label %100

100:                                              ; preds = %96
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.310, i32 noundef %1, i32 noundef %3, i32 noundef %98) #15
  br label %101

101:                                              ; preds = %96, %100, %78, %84, %81, %64, %57, %29, %26, %60, %33
  %102 = phi i32 [ %63, %60 ], [ 0, %33 ], [ -536870206, %26 ], [ -536870206, %29 ], [ -536870206, %57 ], [ -536870206, %64 ], [ 0, %81 ], [ 0, %84 ], [ 0, %78 ], [ -536870212, %100 ], [ 0, %96 ]
  %103 = icmp ne i32 %25, 0
  %104 = load ptr, ptr @_ZL9gNvPmGate, align 8
  %105 = icmp ne ptr %104, null
  %106 = select i1 %103, i1 %105, i1 false
  br i1 %106, label %107, label %118

107:                                              ; preds = %101
  tail call void @IOLockLock(ptr noundef nonnull %104) #15
  %108 = load i32, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %109 = add nsw i32 %108, -1
  store i32 %109, ptr @_ZL10gNvPmUsers, align 4, !tbaa !18
  %110 = icmp eq i32 %109, 0
  br i1 %110, label %111, label %116

111:                                              ; preds = %107
  %112 = load i8, ptr @_ZL11gNvPmClosed, align 1, !tbaa !12, !range !14, !noundef !15
  %113 = trunc nuw i8 %112 to i1
  br i1 %113, label %114, label %116

114:                                              ; preds = %111
  %115 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @"\01_IOLockWakeup_darwin14"(ptr noundef %115, ptr noundef nonnull @_ZL10gNvPmUsers, i1 noundef zeroext false) #15
  br label %116

116:                                              ; preds = %114, %111, %107
  %117 = load ptr, ptr @_ZL9gNvPmGate, align 8, !tbaa !10
  tail call void @IOLockUnlock(ptr noundef %117) #15
  br label %118

118:                                              ; preds = %116, %101, %12, %14
  %119 = phi i32 [ -536870184, %14 ], [ -536870184, %12 ], [ %102, %101 ], [ %102, %116 ]
  ret i32 %119
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_perform_version_check(ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService22waitForMatchingServiceEP12OSDictionaryy(ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN8OSSymbol17withCStringNoCopyEPKc(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noimplicitfloat noredzone nosync nounwind willreturn memory(none)
declare ptr @current_task() local_unnamed_addr #7

; Function Attrs: noimplicitfloat noredzone
declare i32 @rm_ioctl(ptr noundef, ptr noundef, ptr noundef, i32 noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @kauth_cred_issuser(ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noimplicitfloat noredzone nosync nounwind willreturn memory(none)
declare ptr @kauth_cred_get() local_unnamed_addr #7

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN11NVRMDisplay9MetaClassD0Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK11OSMetaClass7releaseEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZNK11OSMetaClass14getRetainCountEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK11OSMetaClass6retainEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK11OSMetaClass7releaseEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK11OSMetaClass9serializeEP11OSSerialize(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK11OSMetaClass12getMetaClassEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15OSMetaClassBase9isEqualToEPKS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK11OSMetaClass12taggedRetainEPKv(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK11OSMetaClass13taggedReleaseEPKv(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK11OSMetaClass13taggedReleaseEPKvi(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN15OSMetaClassBase8DispatchE5IORPC(ptr noundef, ptr noundef byval(%struct.IORPC) align 8) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase4Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase5Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase6Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15OSMetaClassBase25_RESERVEDOSMetaClassBase7Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass1Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass2Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass3Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass4Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass5Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass6Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11OSMetaClass21_RESERVEDOSMetaClass7Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK8OSObject7releaseEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZNK8OSObject14getRetainCountEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK8OSObject6retainEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK8OSObject7releaseEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK8OSObject9serializeEP11OSSerialize(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK8OSObject12taggedRetainEPKv(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK8OSObject13taggedReleaseEPKv(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK8OSObject13taggedReleaseEPKvi(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService8DispatchE5IORPC(ptr noundef, ptr noundef byval(%struct.IORPC) align 8) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN8OSObject4initEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService4freeEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject0Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject1Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject2Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject3Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject4Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject5Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject6Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject7Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject8Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject18_RESERVEDOSObject9Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject19_RESERVEDOSObject10Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject19_RESERVEDOSObject11Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject19_RESERVEDOSObject12Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject19_RESERVEDOSObject13Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject19_RESERVEDOSObject14Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN8OSObject19_RESERVEDOSObject15Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry12copyPropertyEPKcPK15IORegistryPlanej(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSStringPK15IORegistryPlanej(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbolPK15IORegistryPlanej(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry15copyParentEntryEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry14copyChildEntryEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN15IORegistryEntry17runPropertyActionEPFiP8OSObjectPvS2_S2_S2_ES1_S2_S2_S2_S2_(ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry0Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry1Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry2Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry3Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry4Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry5Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry6Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry7Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry8Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry25_RESERVEDIORegistryEntry9Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry10Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry11Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry12Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry13Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry14Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry15Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry16Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry17Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry18Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry19Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry20Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry21Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry22Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry23Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry24Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry25Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry26Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry27Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry28Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry29Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry30Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry26_RESERVEDIORegistryEntry31Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService4initEP12OSDictionary(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry16setPropertyTableEP12OSDictionary(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry11setPropertyEPK8OSSymbolP8OSObject(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry11setPropertyEPK8OSStringP8OSObject(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry11setPropertyEPKcP8OSObject(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry11setPropertyEPKcS1_(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry11setPropertyEPKcb(ptr noundef, ptr noundef, i1 noundef zeroext) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry11setPropertyEPKcyj(ptr noundef, ptr noundef, i64 noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry11setPropertyEPKcPvj(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry14removePropertyEPK8OSSymbol(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry14removePropertyEPK8OSString(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry14removePropertyEPKc(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbol(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSString(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry11getPropertyEPKc(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSSymbolPK15IORegistryPlanej(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry11getPropertyEPK8OSStringPK15IORegistryPlanej(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry11getPropertyEPKcPK15IORegistryPlanej(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSSymbol(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry12copyPropertyEPK8OSString(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry12copyPropertyEPKc(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry24dictionaryWithPropertiesEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK9IOService19serializePropertiesEP11OSSerialize(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN15IORegistryEntry13setPropertiesEP8OSObject(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry17getParentIteratorEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK15IORegistryEntry14applyToParentsEPFvPS_PvES1_PK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry14getParentEntryEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry16getChildIteratorEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZNK15IORegistryEntry15applyToChildrenEPFvPS_PvES1_PK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry13getChildEntryEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15IORegistryEntry7isChildEPS_PK15IORegistryPlaneb(ptr noundef, ptr noundef, ptr noundef, i1 noundef zeroext) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15IORegistryEntry8isParentEPS_PK15IORegistryPlaneb(ptr noundef, ptr noundef, ptr noundef, i1 noundef zeroext) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15IORegistryEntry7inPlaneEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZNK15IORegistryEntry8getDepthEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry14attachToParentEPS_PK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry16detachFromParentEPS_PK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN15IORegistryEntry13attachToChildEPS_PK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry15detachFromChildEPS_PK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry11detachAboveEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry9detachAllEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry7getNameEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry8copyNameEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15IORegistryEntry12compareNamesEP8OSObjectPP8OSString(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15IORegistryEntry11compareNameEP8OSStringPS1_(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry7setNameEPK8OSSymbolPK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry7setNameEPKcPK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry11getLocationEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK15IORegistryEntry12copyLocationEPK15IORegistryPlane(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry11setLocationEPK8OSSymbolPK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN15IORegistryEntry11setLocationEPKcPK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15IORegistryEntry7getPathEPcPiPK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK15IORegistryEntry16getPathComponentEPcPiPK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN15IORegistryEntry13childFromPathEPKcPK15IORegistryPlanePcPi(ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService4initEP15IORegistryEntryPK15IORegistryPlane(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService16requestTerminateEPS_j(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService13willTerminateEPS_j(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService12didTerminateEPS_jPb(ptr noundef, ptr noundef, i32 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService15nextIdleTimeoutEyyj(ptr noundef, i64 noundef, i64 noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService18systemWillShutdownEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService22copyClientWithCategoryEPK8OSSymbol(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService15configureReportEP19IOReportChannelListjPvS2_(ptr noundef, ptr noundef, i32 noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService12updateReportEP19IOReportChannelListjPvS2_(ptr noundef, ptr noundef, i32 noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService2Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService3Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService4Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService5Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService6Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService7Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService8Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService19_RESERVEDIOService9Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService10Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService11Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService12Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService13Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService14Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService15Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService16Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService17Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService18Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService19Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService20Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService21Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService22Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService23Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService24Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService25Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService26Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService27Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService28Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService29Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService30Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService31Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService32Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService33Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService34Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService35Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService36Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService37Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService38Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService39Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService40Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService41Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService42Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService43Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService44Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService45Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService46Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20_RESERVEDIOService47Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZNK9IOService8getStateEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService15registerServiceEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService5probeEPS_Pi(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService5startEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService4stopEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService4openEPS_jPv(ptr noundef, ptr noundef, i32 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService5closeEPS_j(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK9IOService6isOpenEPKS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService10handleOpenEPS_jPv(ptr noundef, ptr noundef, i32 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService11handleCloseEPS_j(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZNK9IOService12handleIsOpenEPKS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService9terminateEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService8finalizeEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService18lockForArbitrationEb(ptr noundef, i1 noundef zeroext) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService20unlockForArbitrationEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService15terminateClientEPS_j(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService12getBusyStateEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService10adjustBusyEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService18matchPropertyTableEP12OSDictionaryPi(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService18matchPropertyTableEP12OSDictionary(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService13matchLocationEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService17addNeededResourceEPKc(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService15comparePropertyEP12OSDictionaryPKc(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService15comparePropertyEP12OSDictionaryPK8OSString(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService17comparePropertiesEP12OSDictionaryP12OSCollection(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService6attachEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService6detachEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK9IOService11getProviderEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK9IOService11getWorkLoopEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK9IOService19getProviderIteratorEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK9IOService23getOpenProviderIteratorEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK9IOService9getClientEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK9IOService17getClientIteratorEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZNK9IOService21getOpenClientIteratorEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService20callPlatformFunctionEPK8OSSymbolbPvS3_S3_S3_(ptr noundef, ptr noundef, i1 noundef zeroext, ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService20callPlatformFunctionEPKcbPvS2_S2_S2_(ptr noundef, ptr noundef, i1 noundef zeroext, ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService12getResourcesEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService20getDeviceMemoryCountEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService24getDeviceMemoryWithIndexEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService24mapDeviceMemoryWithIndexEjj(ptr noundef, i32 noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService15getDeviceMemoryEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService15setDeviceMemoryEP7OSArray(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService17registerInterruptEiP8OSObjectPFvS1_PvPS_iES2_(ptr noundef, i32 noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService19unregisterInterruptEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService16getInterruptTypeEiPi(ptr noundef, i32 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService15enableInterruptEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService16disableInterruptEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService14causeInterruptEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService12requestProbeEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService7messageEjPS_Pv(ptr noundef, i32 noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService13messageClientEjP8OSObjectPvm(ptr noundef, i32 noundef, ptr noundef, ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService14messageClientsEjPvm(ptr noundef, i32 noundef, ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService16registerInterestEPK8OSSymbolPFiPvS3_jPS_S3_mES3_S3_(ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService16applyToProvidersEPFvPS_PvES1_(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService14applyToClientsEPFvPS_PvES1_(ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService17applyToInterestedEPK8OSSymbolPFvP8OSObjectPvES5_(ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService23acknowledgeNotificationEPvj(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService13newUserClientEP4taskPvjP12OSDictionaryPP12IOUserClient(ptr noundef, ptr noundef, ptr noundef, i32 noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService13newUserClientEP4taskPvjPP12IOUserClient(ptr noundef, ptr noundef, ptr noundef, i32 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService16stringFromReturnEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService15errnoFromReturnEi(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService6PMinitEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService6PMstopEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService10joinPMtreeEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService19registerPowerDriverEPS_P14IOPMPowerStatem(ptr noundef, ptr noundef, ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService23requestPowerDomainStateEmP17IOPowerConnectionm(ptr noundef, i64 noundef, ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService14activityTickleEmm(ptr noundef, i64 noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService17setAggressivenessEmm(ptr noundef, i64 noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService17getAggressivenessEmPm(ptr noundef, i64 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService13addPowerChildEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService16removePowerChildEP17IOPowerConnection(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService18setIdleTimerPeriodEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService13setPowerStateEmPS_(ptr noundef, i64 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i64 @_ZN9IOService27maxCapabilityForDomainStateEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i64 @_ZN9IOService31initialPowerStateForDomainStateEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i64 @_ZN9IOService24powerStateForDomainStateEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService22powerStateWillChangeToEmmPS_(ptr noundef, i64 noundef, i64 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService21powerStateDidChangeToEmmPS_(ptr noundef, i64 noundef, i64 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService13askChangeDownEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN9IOService14tellChangeDownEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService16tellNoChangeDownEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService12tellChangeUpEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService16allowPowerChangeEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService17cancelPowerChangeEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN9IOService15powerChangeDoneEm(ptr noundef, i64 noundef) unnamed_addr #3

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN4NVRM9MetaClassD0Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN14NVRMUserClient9MetaClassD0Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN12IOUserClient8DispatchE5IORPC(ptr noundef, ptr noundef byval(%struct.IORPC) align 8) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN12IOUserClient4initEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN12IOUserClient4initEP12OSDictionary(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN12IOUserClient24registerNotificationPortEP8ipc_portjy(ptr noundef, ptr noundef, i32 noundef, i64 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient0Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient1Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient2Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient3Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient4Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient5Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient6Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient7Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient8Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient22_RESERVEDIOUserClient9Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient23_RESERVEDIOUserClient10Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient23_RESERVEDIOUserClient11Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient23_RESERVEDIOUserClient12Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient23_RESERVEDIOUserClient13Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient23_RESERVEDIOUserClient14Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN12IOUserClient23_RESERVEDIOUserClient15Ev(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @_ZN12IOUserClient12initWithTaskEP4taskPvj(ptr noundef, ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN12IOUserClient10clientDiedEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12IOUserClient10getServiceEv(ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN12IOUserClient24registerNotificationPortEP8ipc_portjj(ptr noundef, ptr noundef, i32 noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN12IOUserClient24getNotificationSemaphoreEjPP9semaphore(ptr noundef, i32 noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN12IOUserClient13connectClientEPS_(ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN12IOUserClient20exportObjectToClientEP4taskP8OSObjectPS3_(ptr noundef, ptr noundef, ptr noundef, ptr noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12IOUserClient25getExternalMethodForIndexEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12IOUserClient30getExternalAsyncMethodForIndexEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12IOUserClient26getTargetAndMethodForIndexEPP9IOServicej(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12IOUserClient31getAsyncTargetAndMethodForIndexEPP9IOServicej(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12IOUserClient23getExternalTrapForIndexEj(ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN12IOUserClient24getTargetAndTrapForIndexEPP9IOServicej(ptr noundef, ptr noundef, i32 noundef) unnamed_addr #3

; Function Attrs: inlinehint mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZN17IOAccelNVRMBridge9MetaClassD0Ev(ptr noundef %0) unnamed_addr #2 align 2 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef %0) #15
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define internal zeroext i1 @_ZN17IOAccelNVRMBridge5startEP9IOService(ptr noundef %0, ptr noundef %1) unnamed_addr #1 align 2 {
  %3 = getelementptr inbounds i8, ptr %0, i64 224
  %4 = load ptr, ptr %3, align 8, !tbaa !151
  %5 = icmp eq ptr %4, null
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.353) #15
  br label %10

7:                                                ; preds = %2
  %8 = load ptr, ptr getelementptr inbounds (i8, ptr @_ZTV12IOUserClient, i64 1488), align 8
  %9 = tail call zeroext i1 %8(ptr noundef nonnull %0, ptr noundef %1) #15
  br label %10

10:                                               ; preds = %7, %6
  %11 = phi i1 [ %9, %7 ], [ false, %6 ]
  ret i1 %11
}

; Function Attrs: noimplicitfloat noredzone nounwind
declare void @_ZN11OSMetaClassD2Ev(ptr noundef) unnamed_addr #5

; Function Attrs: noimplicitfloat noredzone
declare i64 @OSAddAtomic64(i64 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i64 @"\01_strlcpy"(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN15IORegistryEntry8fromPathEPKcPK15IORegistryPlanePcPiPS_(ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN6OSData9withBytesEPKvj(ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @sysctlbyname(ptr noundef, ptr noundef, ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone nounwind
declare i32 @strncmp(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #5

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN18IORegistryIterator11iterateOverEPK15IORegistryPlanej(ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef, i64 noundef, i16 noundef zeroext) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN8OSNumber10withNumberEyj(i64 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN8OSString11withCStringEPKc(ptr noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare ptr @nvkms_xnu_kapi_table() local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i64 @nv_xnu_phys_for_kernel_va(ptr noundef) #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN9IOService9waitQuietEy(ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare i32 @"\01_IOLockSleepDeadline_darwin14"(ptr noundef, ptr noundef, i64 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone
declare void @proc_name(i32 noundef, ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: noimplicitfloat noredzone nounwind ssp
define internal void @_GLOBAL__sub_I_NVRM.cpp() #13 {
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE, ptr noundef nonnull @.str, ptr noundef nonnull @_ZN9IOService10gMetaClassE, i32 noundef 136) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN11NVRMDisplay9MetaClassE, i64 16), ptr @_ZN11NVRMDisplay10gMetaClassE, align 8, !tbaa !4
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef nonnull @_ZN4NVRM10gMetaClassE, ptr noundef nonnull @.str.15, ptr noundef nonnull @_ZN9IOService10gMetaClassE, i32 noundef 1288) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN4NVRM9MetaClassE, i64 16), ptr @_ZN4NVRM10gMetaClassE, align 8, !tbaa !4
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE, ptr noundef nonnull @.str.269, ptr noundef nonnull @_ZN12IOUserClient10gMetaClassE, i32 noundef 488) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN14NVRMUserClient9MetaClassE, i64 16), ptr @_ZN14NVRMUserClient10gMetaClassE, align 8, !tbaa !4
  tail call void @_ZN11OSMetaClassC2EPKcPKS_j(ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE, ptr noundef nonnull @.str.271, ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE, i32 noundef 488) #15
  store ptr getelementptr inbounds inrange(-16, 216) (i8, ptr @_ZTVN17IOAccelNVRMBridge9MetaClassE, i64 16), ptr @_ZN17IOAccelNVRMBridge10gMetaClassE, align 8, !tbaa !4
  ret void
}

; Function Attrs: noimplicitfloat noredzone nounwind ssp
define internal void @_GLOBAL__D_a() #13 {
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef nonnull @_ZN17IOAccelNVRMBridge10gMetaClassE) #15
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef nonnull @_ZN14NVRMUserClient10gMetaClassE) #15
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef nonnull @_ZN4NVRM10gMetaClassE) #15
  tail call void @_ZN11OSMetaClassD2Ev(ptr noundef nonnull @_ZN11NVRMDisplay10gMetaClassE) #15
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #14

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #14

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #14

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #14

attributes #0 = { mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress noimplicitfloat noredzone nounwind ssp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { inlinehint mustprogress noimplicitfloat noredzone nounwind ssp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noimplicitfloat noredzone "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { alwaysinline mustprogress noimplicitfloat noredzone nounwind ssp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { noimplicitfloat noredzone nounwind "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nofree noimplicitfloat noredzone nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #9 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #10 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #11 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #12 = { mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(argmem: read) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #13 = { noimplicitfloat noredzone nounwind ssp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #14 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #15 = { nobuiltin noimplicitfloat noredzone nounwind "no-builtins" }
attributes #16 = { nobuiltin noimplicitfloat noredzone nounwind willreturn memory(none) "no-builtins" }
attributes #17 = { nobuiltin noimplicitfloat noredzone "no-builtins" }
attributes #18 = { nounwind }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 5]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"Apple clang version 17.0.0 (clang-1700.0.13.5)"}
!4 = !{!5, !5, i64 0}
!5 = !{!"vtable pointer", !6, i64 0}
!6 = !{!"Simple C++ TBAA"}
!7 = !{!8, !8, i64 0}
!8 = !{!"long long", !9, i64 0}
!9 = !{!"omnipotent char", !6, i64 0}
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !9, i64 0}
!12 = !{!13, !13, i64 0}
!13 = !{!"bool", !9, i64 0}
!14 = !{i8 0, i8 2}
!15 = !{}
!16 = distinct !{!16, !17}
!17 = !{!"llvm.loop.mustprogress"}
!18 = !{!19, !19, i64 0}
!19 = !{!"int", !9, i64 0}
!20 = !{!9, !9, i64 0}
!21 = !{!22, !8, i64 0}
!22 = !{!"_ZTS11nv_pm_owner", !8, i64 0, !19, i64 8, !19, i64 12, !8, i64 16, !9, i64 24}
!23 = distinct !{!23, !17}
!24 = !{!22, !19, i64 8}
!25 = !{!22, !8, i64 16}
!26 = !{!27, !19, i64 440}
!27 = !{!"_ZTS14NVRMUserClient", !28, i64 0, !8, i64 216, !11, i64 224, !33, i64 232, !35, i64 352, !13, i64 432, !19, i64 436, !19, i64 440, !13, i64 444, !19, i64 448, !13, i64 452, !11, i64 456, !11, i64 464, !13, i64 472, !13, i64 473, !19, i64 476, !19, i64 480}
!28 = !{!"_ZTS12IOUserClient", !29, i64 0, !11, i64 136, !9, i64 144}
!29 = !{!"_ZTS9IOService", !30, i64 0, !11, i64 40, !11, i64 48, !19, i64 56, !11, i64 64, !9, i64 72, !8, i64 80, !8, i64 88, !11, i64 96, !13, i64 104, !11, i64 112, !19, i64 120, !11, i64 128}
!30 = !{!"_ZTS15IORegistryEntry", !31, i64 0, !11, i64 16, !11, i64 24, !11, i64 32}
!31 = !{!"_ZTS8OSObject", !32, i64 0, !19, i64 8}
!32 = !{!"_ZTS15OSMetaClassBase"}
!33 = !{!"_ZTS17nv_file_private_t", !11, i64 0, !34, i64 8, !19, i64 12, !19, i64 16, !9, i64 20, !11, i64 88, !11, i64 96, !19, i64 104, !19, i64 108, !9, i64 112}
!34 = !{!"short", !9, i64 0}
!35 = !{!"_ZTS26nv_alloc_mapping_context_s", !11, i64 0, !8, i64 8, !11, i64 16, !8, i64 24, !36, i64 32, !8, i64 48, !8, i64 56, !19, i64 64, !9, i64 68, !19, i64 72}
!36 = !{!"_ZTS10MemoryArea", !11, i64 0, !8, i64 8}
!37 = !{!27, !19, i64 448}
!38 = distinct !{!38, !17}
!39 = !{!27, !13, i64 444}
!40 = !{!27, !19, i64 436}
!41 = distinct !{!41, !17}
!42 = !{!27, !13, i64 432}
!43 = !{!44, !19, i64 136}
!44 = !{!"_ZTS4NVRM", !29, i64 0, !19, i64 136, !19, i64 140, !19, i64 144, !19, i64 148, !11, i64 152, !19, i64 160, !19, i64 164, !19, i64 168, !19, i64 172, !13, i64 176, !19, i64 180, !19, i64 184, !13, i64 188, !19, i64 192, !45, i64 200, !11, i64 328, !46, i64 336, !13, i64 1264, !13, i64 1265, !19, i64 1268, !11, i64 1272, !11, i64 1280}
!45 = !{!"_ZTSN4NVRM7PciSaveE", !13, i64 0, !9, i64 4, !9, i64 28, !19, i64 52, !9, i64 56, !34, i64 80, !11, i64 88, !9, i64 96, !34, i64 120}
!46 = !{!"_ZTS10nv_state_t", !11, i64 0, !11, i64 8, !19, i64 16, !47, i64 20, !34, i64 32, !34, i64 34, !19, i64 36, !19, i64 40, !48, i64 44, !11, i64 72, !9, i64 80, !9, i64 144, !11, i64 264, !9, i64 272, !11, i64 304, !11, i64 312, !11, i64 320, !49, i64 328, !11, i64 368, !19, i64 376, !19, i64 380, !9, i64 384, !9, i64 400, !9, i64 440, !19, i64 640, !19, i64 644, !19, i64 648, !19, i64 652, !11, i64 656, !19, i64 664, !19, i64 668, !9, i64 672, !9, i64 673, !9, i64 674, !8, i64 680, !9, i64 688, !9, i64 689, !9, i64 690, !19, i64 692, !9, i64 696, !19, i64 700, !19, i64 704, !11, i64 712, !11, i64 720, !11, i64 728, !11, i64 736, !11, i64 744, !11, i64 752, !9, i64 760, !9, i64 761, !9, i64 762, !9, i64 763, !9, i64 764, !9, i64 765, !9, i64 766, !9, i64 767, !9, i64 768, !9, i64 769, !19, i64 772, !11, i64 776, !50, i64 784, !9, i64 804, !9, i64 805, !9, i64 806, !9, i64 807, !9, i64 808, !9, i64 809, !19, i64 812, !51, i64 816, !52, i64 828, !9, i64 840, !9, i64 841, !53, i64 842, !9, i64 921, !9, i64 922}
!47 = !{!"_ZTS13nv_pci_info_t", !19, i64 0, !9, i64 4, !9, i64 5, !9, i64 6, !34, i64 8, !34, i64 10}
!48 = !{!"_ZTSN10nv_state_tUt_E", !9, i64 0, !9, i64 1, !9, i64 17, !19, i64 20}
!49 = !{!"_ZTS13nv_aperture_t", !8, i64 0, !8, i64 8, !19, i64 16, !11, i64 24, !11, i64 32}
!50 = !{!"_ZTSN10nv_state_tUt0_E", !19, i64 0, !19, i64 4, !19, i64 8, !19, i64 12, !19, i64 16}
!51 = !{!"_ZTSN10nv_state_tUt1_E", !9, i64 0, !9, i64 1, !19, i64 4, !19, i64 8}
!52 = !{!"_ZTSN10nv_state_tUt2_E", !19, i64 0, !19, i64 4, !19, i64 8}
!53 = !{!"_ZTS20nv_cached_gpu_info_t", !9, i64 0, !9, i64 15}
!54 = !{!44, !19, i64 140}
!55 = !{!44, !19, i64 144}
!56 = !{!44, !19, i64 148}
!57 = !{!44, !11, i64 152}
!58 = !{!44, !19, i64 160}
!59 = !{!44, !19, i64 164}
!60 = !{!44, !19, i64 168}
!61 = !{!44, !19, i64 172}
!62 = !{!44, !13, i64 176}
!63 = !{!44, !19, i64 180}
!64 = !{!44, !19, i64 184}
!65 = !{!44, !13, i64 188}
!66 = !{!44, !19, i64 192}
!67 = !{!45, !13, i64 0}
!68 = !{!46, !19, i64 692}
!69 = !{!46, !9, i64 696}
!70 = !{!46, !19, i64 700}
!71 = !{!46, !19, i64 704}
!72 = !{!46, !19, i64 812}
!73 = !{!51, !9, i64 0}
!74 = !{!51, !9, i64 1}
!75 = !{!44, !13, i64 1264}
!76 = !{!44, !13, i64 1265}
!77 = !{!"auto-init"}
!78 = !{!44, !11, i64 328}
!79 = !{!46, !19, i64 20}
!80 = !{!46, !9, i64 24}
!81 = !{!46, !9, i64 25}
!82 = !{!46, !9, i64 26}
!83 = !{!46, !34, i64 28}
!84 = !{!46, !34, i64 30}
!85 = !{!46, !34, i64 34}
!86 = !{!46, !34, i64 32}
!87 = !{!46, !11, i64 72}
!88 = !{!46, !11, i64 264}
!89 = !{!46, !11, i64 320}
!90 = distinct !{!90, !17}
!91 = !{!92, !93, i64 8}
!92 = !{!"_ZTS8PE_Video", !93, i64 0, !93, i64 8, !93, i64 16, !93, i64 24, !93, i64 32, !93, i64 40, !9, i64 48, !93, i64 112, !93, i64 120, !9, i64 128, !9, i64 129, !9, i64 130, !93, i64 136}
!93 = !{!"long", !9, i64 0}
!94 = !{!92, !93, i64 32}
!95 = !{!92, !93, i64 16}
!96 = !{!92, !93, i64 24}
!97 = !{!93, !93, i64 0}
!98 = distinct !{!98, !99}
!99 = !{!"llvm.loop.unroll.disable"}
!100 = distinct !{!100, !17}
!101 = distinct !{!101, !17}
!102 = distinct !{!102, !17}
!103 = distinct !{!103, !17}
!104 = !{!92, !93, i64 0}
!105 = !{i64 44868}
!106 = !{i64 45000}
!107 = distinct !{!107, !17}
!108 = !{i64 47781}
!109 = distinct !{!109, !17}
!110 = distinct !{!110, !17}
!111 = distinct !{!111, !17}
!112 = !{!49, !19, i64 16}
!113 = !{!49, !8, i64 0}
!114 = !{!49, !8, i64 8}
!115 = distinct !{!115, !17}
!116 = distinct !{!116, !17}
!117 = !{!44, !19, i64 1268}
!118 = distinct !{!118, !17}
!119 = distinct !{!119, !17}
!120 = distinct !{!120, !17}
!121 = distinct !{!121, !17}
!122 = distinct !{!122, !17}
!123 = distinct !{!123, !17}
!124 = distinct !{!124, !17}
!125 = distinct !{!125, !17}
!126 = !{!46, !11, i64 8}
!127 = distinct !{!127, !17}
!128 = !{!44, !11, i64 1272}
!129 = !{!44, !11, i64 1280}
!130 = !{!46, !19, i64 380}
!131 = !{!46, !19, i64 36}
!132 = !{!44, !19, i64 372}
!133 = distinct !{!133, !17}
!134 = distinct !{!134, !17}
!135 = distinct !{!135, !17}
!136 = distinct !{!136, !17, !137}
!137 = !{!"llvm.loop.peeled.count", i32 1}
!138 = distinct !{!138, !17}
!139 = !{!45, !34, i64 80}
!140 = !{!45, !19, i64 52}
!141 = distinct !{!141, !17}
!142 = distinct !{!142, !17}
!143 = !{!45, !11, i64 88}
!144 = !{!45, !34, i64 120}
!145 = distinct !{!145, !17}
!146 = distinct !{!146, !17}
!147 = distinct !{!147, !17}
!148 = !{!27, !11, i64 464}
!149 = !{!27, !13, i64 473}
!150 = distinct !{!150, !17}
!151 = !{!27, !11, i64 224}
!152 = !{!33, !11, i64 0}
!153 = !{!33, !34, i64 8}
!154 = !{!33, !19, i64 12}
!155 = !{!33, !19, i64 16}
!156 = !{!33, !11, i64 88}
!157 = !{!33, !11, i64 96}
!158 = !{!33, !19, i64 104}
!159 = !{!33, !19, i64 108}
!160 = !{!33, !9, i64 112}
!161 = !{!35, !11, i64 0}
!162 = !{!35, !8, i64 8}
!163 = !{!35, !11, i64 16}
!164 = !{!35, !8, i64 24}
!165 = !{!36, !11, i64 0}
!166 = !{!36, !8, i64 8}
!167 = !{!35, !8, i64 48}
!168 = !{!35, !8, i64 56}
!169 = !{!35, !19, i64 64}
!170 = !{!35, !9, i64 68}
!171 = !{!35, !19, i64 72}
!172 = !{!27, !13, i64 452}
!173 = !{!27, !11, i64 456}
!174 = !{!27, !13, i64 472}
!175 = !{!27, !19, i64 476}
!176 = !{!27, !19, i64 480}
!177 = !{i64 10932}
!178 = !{!27, !11, i64 328}
!179 = distinct !{!179, !17}
!180 = !{!27, !8, i64 216}
!181 = !{!22, !19, i64 12}
!182 = distinct !{!182, !17}
!183 = distinct !{!183, !17}
!184 = !{!27, !11, i64 384}
!185 = !{!35, !8, i64 40}
!186 = !{!35, !11, i64 32}
!187 = !{!188, !8, i64 0}
!188 = !{!"_ZTS11MemoryRange", !8, i64 0, !8, i64 8}
!189 = !{!188, !8, i64 8}
!190 = distinct !{!190, !17}
!191 = !{!192, !8, i64 0}
!192 = !{!"_ZTS14IOVirtualRange", !8, i64 0, !8, i64 8}
!193 = !{!192, !8, i64 8}
!194 = distinct !{!194, !17}
!195 = !{i64 0, i64 8, !10, i64 8, i64 4, !18, i64 12, i64 4, !18, i64 16, i64 4, !18, i64 20, i64 4, !18}
!196 = !{!197, !11, i64 32}
!197 = !{!"_ZTS25IOExternalMethodArguments", !19, i64 0, !19, i64 4, !11, i64 8, !11, i64 16, !19, i64 24, !11, i64 32, !19, i64 40, !11, i64 48, !19, i64 56, !11, i64 64, !11, i64 72, !19, i64 80, !11, i64 88, !19, i64 96, !11, i64 104, !19, i64 112, !19, i64 116, !11, i64 120, !9, i64 128}
!198 = !{!197, !11, i64 64}
!199 = !{!197, !19, i64 56}
!200 = !{!197, !11, i64 48}
!201 = !{i64 11074}
!202 = !{!197, !11, i64 104}
!203 = !{!197, !11, i64 88}
!204 = !{!197, !19, i64 96}
!205 = !{!197, !11, i64 72}
!206 = !{!27, !9, i64 420}
!207 = !{!208, !11, i64 24}
!208 = !{!"_ZTS10nv_event_s", !19, i64 0, !19, i64 4, !19, i64 8, !19, i64 12, !34, i64 16, !11, i64 24, !19, i64 32, !19, i64 36, !19, i64 40, !11, i64 48}
!209 = !{!210, !9, i64 0}
!210 = !{!"_ZTS18nv_ioctl_card_info", !9, i64 0, !47, i64 4, !19, i64 16, !34, i64 20, !8, i64 24, !8, i64 32, !8, i64 40, !8, i64 48, !19, i64 56, !9, i64 60}
!211 = !{i64 0, i64 4, !18, i64 4, i64 1, !20, i64 5, i64 1, !20, i64 6, i64 1, !20, i64 8, i64 2, !212, i64 10, i64 2, !212}
!212 = !{!34, !34, i64 0}
!213 = !{!210, !19, i64 16}
!214 = !{!210, !34, i64 20}
!215 = !{!210, !8, i64 24}
!216 = !{!210, !8, i64 32}
!217 = !{!210, !8, i64 40}
!218 = !{!210, !8, i64 48}
!219 = !{!210, !19, i64 56}
!220 = !{!221, !19, i64 24}
!221 = !{!"_ZTS16NVRMSurfShareEsc", !19, i64 0, !19, i64 4, !19, i64 8, !19, i64 12, !19, i64 16, !19, i64 20, !19, i64 24, !19, i64 28, !8, i64 32}
