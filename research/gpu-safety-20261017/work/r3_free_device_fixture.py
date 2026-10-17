#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1]
NV=Path('/mnt/d/Hactk/g1-dev-20261015/upstream/open-gpu-kernel-modules')
OUT=R/'evidence/r3'
def extract(s,marker):
 a=s.index(marker);o=s.index('{',a);i=o+1;depth=1
 while depth:
  depth+=(s[i]=='{')-(s[i]=='}');i+=1
 return s[a:i]
shim=r"""
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
"""
main=r"""
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
"""
records={}
for label,src in [('original',NV/'src/nvidia-modeset/kapi/src/nvkms-kapi.c'),('candidate',R/'candidate/ogkm-e4a5faa-kapi-null-free-r3/src/nvidia-modeset/kapi/src/nvkms-kapi.c')]:
 text=src.read_text();license=text[:text.index('*/')+2]
 bodies='\n'.join(extract(text,m) for m in ['static void KmsFreeDevice(','static void FreeDevice('])
 p=OUT/(label+'-free-device-fixture.c');p.write_text(license+'\n/* Test only: exact source bodies, teardown dependencies injected. No GPU execution. */\n'+shim+'\n'+bodies+'\n'+main)
 records[label]={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'fixture_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'exact_function_bodies':['KmsFreeDevice','FreeDevice'],'dependency_injection':True}
(OUT/'free-device-fixtures.json').write_text(json.dumps(records,indent=1))
