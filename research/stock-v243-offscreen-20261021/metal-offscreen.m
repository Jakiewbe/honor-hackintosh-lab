// HONOR G1 offscreen acceptance candidate. No device API before explicit opt-in.
// A successful application test does not certify driver teardown or system PM.
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <IOKit/IOKitLib.h>
#import <dispatch/dispatch.h>
#include <errno.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int fail(const char *stage, NSError *error) {
    fprintf(stderr, "FAIL stage=%s error=%s\n", stage,
            error ? error.localizedDescription.UTF8String : "unavailable (not zero)");
    return 1;
}

static bool pciWord(io_registry_entry_t entry, CFStringRef key, uint16_t *out) {
    CFTypeRef value=IORegistryEntryCreateCFProperty(entry,key,kCFAllocatorDefault,0);
    bool ok=value && CFGetTypeID(value)==CFDataGetTypeID() && CFDataGetLength((CFDataRef)value)>=2;
    if(ok){ const UInt8 *b=CFDataGetBytePtr((CFDataRef)value); *out=(uint16_t)(b[0]|b[1]<<8); }
    if(value)CFRelease(value);
    return ok;
}

static bool isRTX2050(uint64_t registryID) {
    io_registry_entry_t entry=IOServiceGetMatchingService(kIOMainPortDefault,IORegistryEntryIDMatching(registryID));
    bool matched=false;
    for(unsigned depth=0;entry && depth<32;depth++) {
        if(IOObjectConformsTo(entry,"IOPCIDevice")){
            uint16_t vendor,device;
            matched=pciWord(entry,CFSTR("vendor-id"),&vendor) &&
                    pciWord(entry,CFSTR("device-id"),&device) && vendor==0x10de && device==0x25a9;
            break;
        }
        io_registry_entry_t parent=IO_OBJECT_NULL;
        kern_return_t kr=IORegistryEntryGetParentEntry(entry,kIOServicePlane,&parent);
        IOObjectRelease(entry);entry=kr==KERN_SUCCESS?parent:IO_OBJECT_NULL;
    }
    if(entry)IOObjectRelease(entry);
    return matched;
}

static bool completed(id<MTLCommandBuffer> command, const char *stage) {
    if(!command){fail(stage,nil);return false;}
    dispatch_semaphore_t done=dispatch_semaphore_create(0);
    [command addCompletedHandler:^(id<MTLCommandBuffer> ignored){ (void)ignored;dispatch_semaphore_signal(done); }];
    [command commit];
    if(dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,10*NSEC_PER_SEC))!=0){
        fprintf(stderr,"FAIL stage=%s completion=TIMEOUT in_flight=UNKNOWN; stop further submissions; kernel-close safety UNVERIFIED\n",stage);
        return false;
    }
    if(command.status!=MTLCommandBufferStatusCompleted || command.error){fail(stage,command.error);return false;}
    return true;
}

static NSString *const source=@"#include <metal_stdlib>\nusing namespace metal;\n"
    "kernel void kat(device const uint *in [[buffer(0)]],device uint *out [[buffer(1)]],uint i [[thread_position_in_grid]]){"
    " if(i<64) out[i]=(in[i]^0xa5a5a5a5u)*1664525u+1013904223u; }\n"
    "vertex float4 vertex_main(uint i [[vertex_id]]){const float2 p[3]={float2(-1,-1),float2(3,-1),float2(-1,3)};return float4(p[i],0,1);}\n"
    "fragment float4 fragment_main(){return float4(0,1,0,1);}\n";

static int exercise(id<MTLDevice> device) {
    NSError *error=nil;
    id<MTLLibrary> library=[device newLibraryWithSource:source options:nil error:&error];
    if(!library)return fail("library",error);
    id<MTLFunction> computeFunction=[library newFunctionWithName:@"kat"];
    if(!computeFunction)return fail("compute-function",nil);
    id<MTLComputePipelineState> compute=[device newComputePipelineStateWithFunction:computeFunction error:&error];
    if(!compute)return fail("compute-pipeline",error);
    NSUInteger width=MIN((NSUInteger)32,compute.maxTotalThreadsPerThreadgroup);
    if(width==0)return fail("compute-threadgroup",nil);
    id<MTLCommandQueue> queue=[device newCommandQueue];
    id<MTLBuffer> input=[device newBufferWithLength:64*sizeof(uint32_t) options:MTLResourceStorageModeShared];
    id<MTLBuffer> output=[device newBufferWithLength:64*sizeof(uint32_t) options:MTLResourceStorageModeShared];
    if(!queue || !input || !output || !input.contents || !output.contents)return fail("compute-allocation",nil);
    uint32_t *in=input.contents,*out=output.contents;
    for(unsigned i=0;i<64;i++){in[i]=i*0x1020304u+0x57319u;out[i]=0xdeadc0deu;}
    id<MTLCommandBuffer> cb=[queue commandBuffer];
    id<MTLComputeCommandEncoder> encoder=[cb computeCommandEncoder];
    if(!cb || !encoder)return fail("compute-encoder",nil);
    [encoder setComputePipelineState:compute];[encoder setBuffer:input offset:0 atIndex:0];[encoder setBuffer:output offset:0 atIndex:1];
    [encoder dispatchThreads:MTLSizeMake(64,1,1) threadsPerThreadgroup:MTLSizeMake(width,1,1)];
    [encoder endEncoding];
    if(!completed(cb,"compute-completion"))return 2;
    for(unsigned i=0;i<64;i++){
        uint32_t expected=(in[i]^0xa5a5a5a5u)*1664525u+1013904223u;
        if(out[i]!=expected){fprintf(stderr,"FAIL compute index=%u expected=%08x actual=%08x\n",i,expected,out[i]);return 3;}
    }
    puts("OBSERVED compute: 64/64 correct after Metal command completion");

    MTLRenderPipelineDescriptor *pd=[MTLRenderPipelineDescriptor new];
    pd.vertexFunction=[library newFunctionWithName:@"vertex_main"];pd.fragmentFunction=[library newFunctionWithName:@"fragment_main"];
    if(!pd.vertexFunction || !pd.fragmentFunction)return fail("render-functions",nil);
    pd.colorAttachments[0].pixelFormat=MTLPixelFormatRGBA8Unorm;
    error=nil;id<MTLRenderPipelineState> render=[device newRenderPipelineStateWithDescriptor:pd error:&error];
    if(!render)return fail("render-pipeline",error);
    MTLTextureDescriptor *td=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:8 height:8 mipmapped:NO];
    td.storageMode=MTLStorageModePrivate;td.usage=MTLTextureUsageRenderTarget;
    id<MTLTexture> texture=[device newTextureWithDescriptor:td];
    id<MTLBuffer> pixels=[device newBufferWithLength:256*8 options:MTLResourceStorageModeShared];
    if(!texture || !pixels || !pixels.contents)return fail("render-allocation",nil);
    memset(pixels.contents,0xa5,256*8);
    MTLRenderPassDescriptor *pass=[MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture=texture;pass.colorAttachments[0].loadAction=MTLLoadActionClear;
    pass.colorAttachments[0].clearColor=MTLClearColorMake(1,0,1,1);pass.colorAttachments[0].storeAction=MTLStoreActionStore;
    cb=[queue commandBuffer];id<MTLRenderCommandEncoder> re=[cb renderCommandEncoderWithDescriptor:pass];
    if(!cb || !re)return fail("render-encoder",nil);
    [re setRenderPipelineState:render];[re drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];[re endEncoding];
    id<MTLBlitCommandEncoder> blit=[cb blitCommandEncoder];
    if(!blit)return fail("readback-encoder",nil);
    [blit copyFromTexture:texture sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0,0,0) sourceSize:MTLSizeMake(8,8,1)
        toBuffer:pixels destinationOffset:0 destinationBytesPerRow:256 destinationBytesPerImage:256*8];
    [blit endEncoding];
    if(!completed(cb,"render-and-readback-completion"))return 4;
    const uint8_t *bytes=pixels.contents;
    for(unsigned y=0;y<8;y++)for(unsigned x=0;x<8;x++){
        const uint8_t *p=bytes+y*256+x*4;
        if(p[0]!=0 || p[1]!=255 || p[2]!=0 || p[3]!=255){fprintf(stderr,"FAIL pixel x=%u y=%u rgba=%u,%u,%u,%u\n",x,y,p[0],p[1],p[2],p[3]);return 5;}
    }
    puts("OBSERVED render/readback: 64/64 exact green pixels; magenta clear and CPU sentinel were different");
    error=nil;id<MTLLibrary> invalid=[device newLibraryWithSource:@"deliberately invalid metal shader !!!" options:nil error:&error];
    if(invalid || !error)return fail("shader-error-not-propagated",error);
    puts("OBSERVED shader compiler refusal: nil result with NSError (not an asynchronous GPU fault test)");
    puts("APP_TEST_PASS; kernel shutdown/PM/driver teardown NOT_TESTED; hardware execution corroboration still required");
    return 0;
}

int main(int argc,const char *argv[]) {
    // Parsing/help paths intentionally do not call Metal or IOKit APIs.
    if(argc==2 && strcmp(argv[1],"--help")==0){
        puts("Requires separate device authorization: --execute-authorized --registry-id HEX_NONZERO\n"
             "No default device enumeration. Compile-only CI never executes this program.\n"
             "No kext installation/loading/unloading or PM test. Runtime remains NO-GO until independently released.");
        return 0;
    }
    if(argc!=4 || strcmp(argv[1],"--execute-authorized") || strcmp(argv[2],"--registry-id")){
        fputs("REFUSED: explicit device authorization and expected registry ID required; use --help\n",stderr);return 64;
    }
    errno=0;char *end=NULL;uint64_t expected=strtoull(argv[3],&end,16);
    if(errno || !end || end==argv[3] || *end || !expected || argv[3][0]=='-'){
        fputs("REFUSED: invalid or unknown registry ID\n",stderr);return 64;
    }
    @autoreleasepool {
        id<MTLDevice> selected=nil;unsigned matches=0;
        for(id<MTLDevice> device in MTLCopyAllDevices())if(device.registryID==expected){selected=device;matches++;}
        if(matches!=1 || !selected || !isRTX2050(expected))return fail("RTX2050-registry-and-PCI-binding",nil);
        printf("SELECTED registryID=0x%" PRIx64 " PCI=10de:25a9\n",expected);
        @try { return exercise(selected); }
        @catch(NSException *exception){
            fprintf(stderr,"FAIL Objective-C exception: %s; no runtime acceptance\n",exception.reason.UTF8String);
            return 6;
        }
    }
}
