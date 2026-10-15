/*
 * G1 minimal offscreen validator.
 *
 * Loads one Vulkan ICD directly (no loader, so no other driver on the machine is enumerated), requires the expected
 * PCI vendor:device, runs compute into device memory plus two scissored draws into an R32_UINT image, copies both
 * back and compares every word against the CPU reference with per-run random nonces. Scope: offscreen GPU execution
 * and readback only - not display, not Metal, not WindowServer.
 *
 * Exit codes: 0 GPU offscreen pass, 2 mismatch, 3 Vulkan error or device lost, 4 fence timeout (GPU objects are left
 * for process teardown), 5 no acceptable device, 6 watchdog, 1 usage/internal, 10 CPU self-test pass (never GPU).
 */
#define _POSIX_C_SOURCE 200809L
#if defined(__APPLE__)
#define _DARWIN_C_SOURCE
#endif
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define VK_NO_PROTOTYPES
#include <vulkan/vulkan.h>

#include "g1_ref.h"
#include "g1_shaders.h"

enum { EXIT_PASS = 0, EXIT_USAGE = 1, EXIT_MISMATCH = 2, EXIT_VK = 3, EXIT_TIMEOUT = 4, EXIT_NO_DEVICE = 5,
       EXIT_WATCHDOG = 6, EXIT_CPU_SELFTEST = 10 };

#define SENTINEL_READBACK 0x5E5E5E5Eu
#define SENTINEL_DEVICE   0xF111F111u
#define CLEAR_VALUE       0xC1EAC1EAu
#define ROUNDS            2

typedef VkResult (VKAPI_PTR *PFN_negotiate)(uint32_t *);

#define INSTANCE_FNS(X) \
    X(vkDestroyInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties) \
    X(vkGetPhysicalDeviceProperties2) X(vkGetPhysicalDeviceQueueFamilyProperties) \
    X(vkGetPhysicalDeviceMemoryProperties) X(vkGetPhysicalDeviceFormatProperties) X(vkCreateDevice) \
    X(vkGetDeviceProcAddr)

#define DEVICE_FNS(X) \
    X(vkDestroyDevice) X(vkGetDeviceQueue) X(vkDeviceWaitIdle) X(vkQueueSubmit) \
    X(vkCreateBuffer) X(vkDestroyBuffer) X(vkGetBufferMemoryRequirements) X(vkBindBufferMemory) \
    X(vkCreateImage) X(vkDestroyImage) X(vkGetImageMemoryRequirements) X(vkBindImageMemory) \
    X(vkCreateImageView) X(vkDestroyImageView) \
    X(vkAllocateMemory) X(vkFreeMemory) X(vkMapMemory) X(vkUnmapMemory) \
    X(vkFlushMappedMemoryRanges) X(vkInvalidateMappedMemoryRanges) \
    X(vkCreateShaderModule) X(vkDestroyShaderModule) \
    X(vkCreateDescriptorSetLayout) X(vkDestroyDescriptorSetLayout) X(vkCreateDescriptorPool) \
    X(vkDestroyDescriptorPool) X(vkAllocateDescriptorSets) X(vkUpdateDescriptorSets) \
    X(vkCreatePipelineLayout) X(vkDestroyPipelineLayout) X(vkCreateComputePipelines) \
    X(vkCreateGraphicsPipelines) X(vkDestroyPipeline) \
    X(vkCreateRenderPass) X(vkDestroyRenderPass) X(vkCreateFramebuffer) X(vkDestroyFramebuffer) \
    X(vkCreateCommandPool) X(vkDestroyCommandPool) X(vkAllocateCommandBuffers) X(vkResetCommandBuffer) \
    X(vkBeginCommandBuffer) X(vkEndCommandBuffer) \
    X(vkCmdFillBuffer) X(vkCmdPipelineBarrier) X(vkCmdBindPipeline) X(vkCmdBindDescriptorSets) \
    X(vkCmdPushConstants) X(vkCmdDispatch) X(vkCmdCopyBuffer) X(vkCmdBeginRenderPass) X(vkCmdEndRenderPass) \
    X(vkCmdSetViewport) X(vkCmdSetScissor) X(vkCmdDraw) X(vkCmdCopyImageToBuffer) \
    X(vkCreateFence) X(vkDestroyFence) X(vkResetFences) X(vkWaitForFences)

#define DECLARE(fn) static PFN_##fn p_##fn;
INSTANCE_FNS(DECLARE)
DEVICE_FNS(DECLARE)

typedef struct {
    VkBuffer buf;
    VkDeviceMemory mem;
    VkMemoryPropertyFlags flags;
    void *map;
} buffer_t;

static struct {
    const char *icd, *log_path, *inject;
    uint32_t vendor, device, width, height, timeout_ms, watchdog_s;
    int cpu_selftest, have_seed;
    uint64_t seed;
} opt = { .log_path = "g1-offscreen.log", .inject = "none", .vendor = 0x10de, .device = 0x25a9,
          .width = 256, .height = 256, .timeout_ms = 5000, .watchdog_s = 60 };

static struct {
    void *lib;
    VkInstance inst;
    VkPhysicalDevice phys;
    VkDevice dev;
    VkQueue queue;
    VkPhysicalDeviceMemoryProperties memprops;
    buffer_t dev_buf, rb_comp, rb_img;
    VkImage img;
    VkDeviceMemory img_mem;
    VkImageView view;
    VkRenderPass rp;
    VkFramebuffer fb;
    VkShaderModule sm_comp, sm_vert, sm_frag;
    VkDescriptorSetLayout dsl;
    VkDescriptorPool dpool;
    VkDescriptorSet dset;
    VkPipelineLayout pl_comp, pl_gfx;
    VkPipeline pipe_comp, pipe_gfx;
    VkCommandPool cpool;
    VkCommandBuffer cmd;
    VkFence fence;
    int unsafe;     /* a submission did not finish in time: GPU may still use the objects */
} g;

static int log_fd = -1;
static struct timespec t0;

static double now_ms(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (t.tv_sec - t0.tv_sec) * 1e3 + (t.tv_nsec - t0.tv_nsec) / 1e6;
}

/* Every line goes to stdout and, durably, to the log so a hang or panic still shows the last stage reached. */
static void say(const char *fmt, ...)
{
    char line[1024];
    va_list ap;
    int n = snprintf(line, sizeof line, "[%9.3f] ", now_ms());
    va_start(ap, fmt);
    n += vsnprintf(line + n, sizeof line - n, fmt, ap);
    va_end(ap);
    if (n >= (int)sizeof line - 1)
        n = sizeof line - 2;
    line[n++] = '\n';
    fwrite(line, 1, n, stdout);
    fflush(stdout);
    if (log_fd >= 0) {
        ssize_t w = write(log_fd, line, n);
        (void)w;
        fsync(log_fd);
    }
}

static void on_watchdog(int sig)
{
    static const char msg[] = "VERDICT WATCHDOG: process did not finish within the watchdog budget\n";
    (void)sig;
    ssize_t w = write(STDOUT_FILENO, msg, sizeof msg - 1);
    if (log_fd >= 0) {
        w = write(log_fd, msg, sizeof msg - 1);
        fsync(log_fd);
    }
    (void)w;
    _exit(EXIT_WATCHDOG);
}

static const char *vk_name(VkResult r)
{
    switch (r) {
#define R(x) case x: return #x;
    R(VK_SUCCESS) R(VK_NOT_READY) R(VK_TIMEOUT) R(VK_INCOMPLETE) R(VK_ERROR_OUT_OF_HOST_MEMORY)
    R(VK_ERROR_OUT_OF_DEVICE_MEMORY) R(VK_ERROR_INITIALIZATION_FAILED) R(VK_ERROR_DEVICE_LOST)
    R(VK_ERROR_MEMORY_MAP_FAILED) R(VK_ERROR_LAYER_NOT_PRESENT) R(VK_ERROR_EXTENSION_NOT_PRESENT)
    R(VK_ERROR_FEATURE_NOT_PRESENT) R(VK_ERROR_INCOMPATIBLE_DRIVER) R(VK_ERROR_TOO_MANY_OBJECTS)
    R(VK_ERROR_FORMAT_NOT_SUPPORTED) R(VK_ERROR_UNKNOWN)
#undef R
    default: return "VK_RESULT_OTHER";
    }
}

static int vk_fail_code(VkResult r) { return r == VK_TIMEOUT ? EXIT_TIMEOUT : EXIT_VK; }

#define CK(call, stage) do { \
        VkResult r_ = (call); \
        if (r_ != VK_SUCCESS) { \
            say("stage=%s result=%s(%d)", stage, vk_name(r_), (int)r_); \
            rc = vk_fail_code(r_); \
            verdict = r_ == VK_ERROR_DEVICE_LOST ? "DEVICE_LOST" : r_ == VK_TIMEOUT ? "TIMEOUT" : "VULKAN_ERROR"; \
            goto done; \
        } \
    } while (0)

static int find_memory(uint32_t bits, VkMemoryPropertyFlags want)
{
    for (uint32_t i = 0; i < g.memprops.memoryTypeCount; i++)
        if ((bits & (1u << i)) && (g.memprops.memoryTypes[i].propertyFlags & want) == want)
            return (int)i;
    return -1;
}

static VkResult bind_memory(VkMemoryRequirements req, const VkMemoryPropertyFlags *prefs, int nprefs,
                            VkDeviceMemory *mem, VkMemoryPropertyFlags *got)
{
    int type = -1;
    for (int k = 0; k < nprefs && type < 0; k++)
        type = find_memory(req.memoryTypeBits, prefs[k]);
    if (type < 0)
        return VK_ERROR_OUT_OF_DEVICE_MEMORY;
    *got = g.memprops.memoryTypes[type].propertyFlags;
    VkMemoryAllocateInfo ai = { VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, req.size, (uint32_t)type };
    return p_vkAllocateMemory(g.dev, &ai, NULL, mem);
}

static VkResult make_buffer(buffer_t *b, VkDeviceSize size, VkBufferUsageFlags usage, int host)
{
    static const VkMemoryPropertyFlags dev_prefs[] = { VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, 0 };
    static const VkMemoryPropertyFlags host_prefs[] = {
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT };
    VkBufferCreateInfo ci = { VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, NULL, 0, size, usage,
                              VK_SHARING_MODE_EXCLUSIVE, 0, NULL };
    VkResult r = p_vkCreateBuffer(g.dev, &ci, NULL, &b->buf);
    if (r != VK_SUCCESS)
        return r;
    VkMemoryRequirements req;
    p_vkGetBufferMemoryRequirements(g.dev, b->buf, &req);
    r = bind_memory(req, host ? host_prefs : dev_prefs, 2, &b->mem, &b->flags);
    if (r != VK_SUCCESS)
        return r;
    r = p_vkBindBufferMemory(g.dev, b->buf, b->mem, 0);
    if (r == VK_SUCCESS && host)
        r = p_vkMapMemory(g.dev, b->mem, 0, VK_WHOLE_SIZE, 0, &b->map);
    return r;
}

static VkResult host_sync(buffer_t *b, int before_gpu)
{
    if (b->flags & VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
        return VK_SUCCESS;
    VkMappedMemoryRange range = { VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE, NULL, b->mem, 0, VK_WHOLE_SIZE };
    return before_gpu ? p_vkFlushMappedMemoryRanges(g.dev, 1, &range)
                      : p_vkInvalidateMappedMemoryRanges(g.dev, 1, &range);
}

static void destroy_buffer(buffer_t *b)
{
    if (b->map)
        p_vkUnmapMemory(g.dev, b->mem);
    if (b->buf)
        p_vkDestroyBuffer(g.dev, b->buf, NULL);
    if (b->mem)
        p_vkFreeMemory(g.dev, b->mem, NULL);
}

static void cleanup(void)
{
    if (g.unsafe) {
        say("cleanup: skipped - a submission may still be running; objects are left to process teardown");
        return;
    }
    if (g.dev) {
        VkResult r = p_vkDeviceWaitIdle(g.dev);
        say("stage=device_wait_idle result=%s", vk_name(r));
        if (g.fence) p_vkDestroyFence(g.dev, g.fence, NULL);
        if (g.cpool) p_vkDestroyCommandPool(g.dev, g.cpool, NULL);
        if (g.pipe_gfx) p_vkDestroyPipeline(g.dev, g.pipe_gfx, NULL);
        if (g.pipe_comp) p_vkDestroyPipeline(g.dev, g.pipe_comp, NULL);
        if (g.pl_gfx) p_vkDestroyPipelineLayout(g.dev, g.pl_gfx, NULL);
        if (g.pl_comp) p_vkDestroyPipelineLayout(g.dev, g.pl_comp, NULL);
        if (g.dpool) p_vkDestroyDescriptorPool(g.dev, g.dpool, NULL);
        if (g.dsl) p_vkDestroyDescriptorSetLayout(g.dev, g.dsl, NULL);
        if (g.sm_frag) p_vkDestroyShaderModule(g.dev, g.sm_frag, NULL);
        if (g.sm_vert) p_vkDestroyShaderModule(g.dev, g.sm_vert, NULL);
        if (g.sm_comp) p_vkDestroyShaderModule(g.dev, g.sm_comp, NULL);
        if (g.fb) p_vkDestroyFramebuffer(g.dev, g.fb, NULL);
        if (g.rp) p_vkDestroyRenderPass(g.dev, g.rp, NULL);
        if (g.view) p_vkDestroyImageView(g.dev, g.view, NULL);
        if (g.img) p_vkDestroyImage(g.dev, g.img, NULL);
        if (g.img_mem) p_vkFreeMemory(g.dev, g.img_mem, NULL);
        destroy_buffer(&g.rb_img);
        destroy_buffer(&g.rb_comp);
        destroy_buffer(&g.dev_buf);
        p_vkDestroyDevice(g.dev, NULL);
        say("stage=destroy_device done");
    }
    if (g.inst) {
        p_vkDestroyInstance(g.inst, NULL);
        say("stage=destroy_instance done");
    }
    if (g.lib)
        dlclose(g.lib);
}

static uint64_t splitmix(uint64_t *s)
{
    uint64_t z = (*s += 0x9E3779B97F4A7C15ull);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
    return z ^ (z >> 31);
}

static int parse_args(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i], *v = i + 1 < argc ? argv[i + 1] : NULL;
        if (!strcmp(a, "--cpu-selftest")) { opt.cpu_selftest = 1; continue; }
        if (!v) return -1;
        i++;
        if (!strcmp(a, "--icd")) opt.icd = v;
        else if (!strcmp(a, "--log")) opt.log_path = v;
        else if (!strcmp(a, "--inject")) opt.inject = v;
        else if (!strcmp(a, "--expect")) { if (sscanf(v, "%x:%x", &opt.vendor, &opt.device) != 2) return -1; }
        else if (!strcmp(a, "--size")) { if (sscanf(v, "%ux%u", &opt.width, &opt.height) != 2) return -1; }
        else if (!strcmp(a, "--timeout-ms")) opt.timeout_ms = (uint32_t)strtoul(v, NULL, 10);
        else if (!strcmp(a, "--watchdog-s")) opt.watchdog_s = (uint32_t)strtoul(v, NULL, 10);
        else if (!strcmp(a, "--seed")) { opt.seed = strtoull(v, NULL, 0); opt.have_seed = 1; }
        else return -1;
    }
    static const char *injects[] = { "none", "corrupt", "skip-compute", "skip-draw", "hang-fence" };
    int known = 0;
    for (size_t k = 0; k < sizeof injects / sizeof *injects; k++)
        known |= !strcmp(opt.inject, injects[k]);
    if (!opt.icd || !known || opt.width < 8 || opt.height < 8 || opt.width > 4096 || opt.height > 4096 ||
        opt.timeout_ms == 0)
        return -1;
    return 0;
}

static void barrier(VkPipelineStageFlags src, VkPipelineStageFlags dst, VkAccessFlags sa, VkAccessFlags da)
{
    VkMemoryBarrier mb = { VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, sa, da };
    p_vkCmdPipelineBarrier(g.cmd, src, dst, 0, 1, &mb, 0, NULL, 0, NULL);
}

int main(int argc, char **argv)
{
    int rc = EXIT_USAGE;
    const char *verdict = "USAGE";
    clock_gettime(CLOCK_MONOTONIC, &t0);
    if (parse_args(argc, argv)) {
        fprintf(stderr, "usage: %s --icd PATH [--expect 10de:25a9] [--cpu-selftest] [--size 256x256] [--seed N]\n"
                        "          [--timeout-ms 5000] [--watchdog-s 60] [--log g1-offscreen.log]\n"
                        "          [--inject none|corrupt|skip-compute|skip-draw|hang-fence]\n", argv[0]);
        return EXIT_USAGE;
    }
    log_fd = open(opt.log_path, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (log_fd < 0)
        fprintf(stderr, "warning: cannot open log %s: %s\n", opt.log_path, strerror(errno));
    signal(SIGALRM, on_watchdog);
    alarm(opt.watchdog_s);

    if (!opt.have_seed) {
        int fd = open("/dev/urandom", O_RDONLY);
        if (fd < 0 || read(fd, &opt.seed, sizeof opt.seed) != (ssize_t)sizeof opt.seed) {
            say("stage=seed error=%s", strerror(errno));
            return EXIT_USAGE;
        }
        close(fd);
    }
    const uint32_t W = opt.width, H = opt.height, N = W * H;
    const g1_rect rect = { W / 4, H / 3, W / 2, H / 4 };
    say("g1-offscreen scope=offscreen-compute+raster+readback (not display/Metal/WindowServer)");
    say("config icd=%s expect=%04x:%04x cpu_selftest=%d size=%ux%u seed=0x%016" PRIx64 " timeout_ms=%u "
        "watchdog_s=%u inject=%s", opt.icd, opt.vendor, opt.device, opt.cpu_selftest, W, H, opt.seed,
        opt.timeout_ms, opt.watchdog_s, opt.inject);

    /* NVK's own GPU wait budget (read by the NVRM backend); the Metal plugin sets the same variable. */
    if (!getenv("NVRM_FLUSH_TIMEOUT_MS")) {
        char budget[16];
        snprintf(budget, sizeof budget, "%u", opt.timeout_ms);
        setenv("NVRM_FLUSH_TIMEOUT_MS", budget, 1);
    }
    say("env NVRM_FLUSH_TIMEOUT_MS=%s", getenv("NVRM_FLUSH_TIMEOUT_MS"));

    struct stat st;
    if (stat(opt.icd, &st) == 0)
        say("icd size=%lld mtime=%lld", (long long)st.st_size, (long long)st.st_mtime);
    g.lib = dlopen(opt.icd, RTLD_NOW | RTLD_LOCAL);
    if (!g.lib) {
        say("stage=dlopen error=%s", dlerror());
        rc = EXIT_NO_DEVICE;
        verdict = "NO_DRIVER";
        goto done;
    }
    PFN_negotiate negotiate = (PFN_negotiate)dlsym(g.lib, "vk_icdNegotiateLoaderICDInterfaceVersion");
    if (negotiate) {
        uint32_t version = 5;
        VkResult r = negotiate(&version);
        say("stage=negotiate result=%s icd_interface=%u", vk_name(r), version);
    }
    PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(g.lib, "vk_icdGetInstanceProcAddr");
    if (!gipa)
        gipa = (PFN_vkGetInstanceProcAddr)dlsym(g.lib, "vkGetInstanceProcAddr");
    PFN_vkCreateInstance create_instance = gipa ? (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance") : NULL;
    if (!create_instance) {
        say("stage=entry error=no vkGetInstanceProcAddr/vkCreateInstance in ICD");
        rc = EXIT_NO_DEVICE;
        verdict = "NO_DRIVER";
        goto done;
    }

    VkApplicationInfo app = { VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "g1-offscreen", 1, "g1", 1,
                              VK_API_VERSION_1_2 };
    VkInstanceCreateInfo ici = { VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app, 0, NULL, 0, NULL };
    CK(create_instance(&ici, NULL, &g.inst), "create_instance");
#define LOAD_I(fn) \
    if (!(p_##fn = (PFN_##fn)gipa(g.inst, #fn))) { say("stage=entry missing=%s", #fn); rc = EXIT_VK; \
                                                   verdict = "VULKAN_ERROR"; goto done; }
    INSTANCE_FNS(LOAD_I)

    uint32_t count = 0;
    CK(p_vkEnumeratePhysicalDevices(g.inst, &count, NULL), "enumerate_devices");
    VkPhysicalDevice devs[16];
    if (count > 16)
        count = 16;
    if (count)
        CK(p_vkEnumeratePhysicalDevices(g.inst, &count, devs), "enumerate_devices");
    VkPhysicalDeviceProperties props = {0};
    for (uint32_t i = 0; i < count; i++) {
        VkPhysicalDeviceDriverProperties drv = { .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES };
        VkPhysicalDeviceProperties2 p2 = { .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2, .pNext = &drv };
        p_vkGetPhysicalDeviceProperties2(devs[i], &p2);
        const VkPhysicalDeviceProperties *p = &p2.properties;
        int is_cpu = p->deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU;
        int ok = opt.cpu_selftest ? is_cpu : !is_cpu && p->vendorID == opt.vendor && p->deviceID == opt.device;
        say("device[%u] %04x:%04x type=%d name=\"%s\" driver_id=%d driver=\"%s\" info=\"%s\" api=%u.%u.%u "
            "conformance=%u.%u.%u.%u %s", i, p->vendorID, p->deviceID, p->deviceType, p->deviceName,
            drv.driverID, drv.driverName, drv.driverInfo, VK_API_VERSION_MAJOR(p->apiVersion),
            VK_API_VERSION_MINOR(p->apiVersion), VK_API_VERSION_PATCH(p->apiVersion),
            drv.conformanceVersion.major, drv.conformanceVersion.minor, drv.conformanceVersion.subminor,
            drv.conformanceVersion.patch, ok ? "ACCEPTED" : "refused");
        if (ok && !g.phys) {
            g.phys = devs[i];
            props = *p;
        }
    }
    if (!g.phys) {
        say("stage=select error=no %s", opt.cpu_selftest ? "CPU device for self-test" : "matching non-CPU device");
        rc = EXIT_NO_DEVICE;
        verdict = "NO_DEVICE";
        goto done;
    }
    const int is_cpu_device = props.deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU;

    uint32_t nq = 0, qfam = UINT32_MAX;
    VkQueueFamilyProperties qf[16];
    p_vkGetPhysicalDeviceQueueFamilyProperties(g.phys, &nq, NULL);
    if (nq > 16)
        nq = 16;
    p_vkGetPhysicalDeviceQueueFamilyProperties(g.phys, &nq, qf);
    for (uint32_t i = 0; i < nq && qfam == UINT32_MAX; i++)
        if ((qf[i].queueFlags & (VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT)) ==
            (VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT))
            qfam = i;
    if (qfam == UINT32_MAX) {
        say("stage=queue_family error=no graphics+compute queue");
        rc = EXIT_NO_DEVICE;
        verdict = "NO_DEVICE";
        goto done;
    }
    VkFormatProperties fp;
    p_vkGetPhysicalDeviceFormatProperties(g.phys, VK_FORMAT_R32_UINT, &fp);
    if (!(fp.optimalTilingFeatures & VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT)) {
        say("stage=format error=R32_UINT is not a color attachment");
        rc = EXIT_VK;
        verdict = "VULKAN_ERROR";
        goto done;
    }
    p_vkGetPhysicalDeviceMemoryProperties(g.phys, &g.memprops);

    float prio = 1.0f;
    VkDeviceQueueCreateInfo qci = { VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, qfam, 1, &prio };
    VkDeviceCreateInfo dci = { VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, NULL, 0, 1, &qci, 0, NULL, 0, NULL, NULL };
    CK(p_vkCreateDevice(g.phys, &dci, NULL, &g.dev), "create_device");
    PFN_vkGetDeviceProcAddr gdpa = p_vkGetDeviceProcAddr;
#define LOAD_D(fn) \
    if (!(p_##fn = (PFN_##fn)gdpa(g.dev, #fn))) { say("stage=entry missing=%s", #fn); rc = EXIT_VK; \
                                                  verdict = "VULKAN_ERROR"; goto done; }
    DEVICE_FNS(LOAD_D)
    p_vkGetDeviceQueue(g.dev, qfam, 0, &g.queue);
    say("stage=create_device ok queue_family=%u", qfam);

    /* buffers: compute target in device memory, two host-visible readback buffers */
    CK(make_buffer(&g.dev_buf, (VkDeviceSize)N * 4, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT |
                   VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT, 0), "alloc_device_buffer");
    CK(make_buffer(&g.rb_comp, (VkDeviceSize)N * 4, VK_BUFFER_USAGE_TRANSFER_DST_BIT, 1), "alloc_readback");
    CK(make_buffer(&g.rb_img, (VkDeviceSize)N * 4, VK_BUFFER_USAGE_TRANSFER_DST_BIT, 1), "alloc_readback");
    say("memory device_buffer_flags=0x%x readback_flags=0x%x", g.dev_buf.flags, g.rb_img.flags);

    VkImageCreateInfo imci = { VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO, NULL, 0, VK_IMAGE_TYPE_2D, VK_FORMAT_R32_UINT,
                               { W, H, 1 }, 1, 1, VK_SAMPLE_COUNT_1_BIT, VK_IMAGE_TILING_OPTIMAL,
                               VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
                               VK_SHARING_MODE_EXCLUSIVE, 0, NULL, VK_IMAGE_LAYOUT_UNDEFINED };
    CK(p_vkCreateImage(g.dev, &imci, NULL, &g.img), "create_image");
    {
        VkMemoryRequirements req;
        VkMemoryPropertyFlags got, prefs[] = { VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, 0 };
        p_vkGetImageMemoryRequirements(g.dev, g.img, &req);
        CK(bind_memory(req, prefs, 2, &g.img_mem, &got), "alloc_image");
        CK(p_vkBindImageMemory(g.dev, g.img, g.img_mem, 0), "bind_image");
        say("memory image_flags=0x%x", got);
    }
    VkImageViewCreateInfo vci = { VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO, NULL, 0, g.img, VK_IMAGE_VIEW_TYPE_2D,
                                  VK_FORMAT_R32_UINT, { 0 }, { VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1 } };
    CK(p_vkCreateImageView(g.dev, &vci, NULL, &g.view), "create_image_view");

    VkAttachmentDescription att = { 0, VK_FORMAT_R32_UINT, VK_SAMPLE_COUNT_1_BIT, VK_ATTACHMENT_LOAD_OP_CLEAR,
                                    VK_ATTACHMENT_STORE_OP_STORE, VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                    VK_ATTACHMENT_STORE_OP_DONT_CARE, VK_IMAGE_LAYOUT_UNDEFINED,
                                    VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL };
    VkAttachmentReference aref = { 0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL };
    VkSubpassDescription sp = { 0, VK_PIPELINE_BIND_POINT_GRAPHICS, 0, NULL, 1, &aref, NULL, NULL, 0, NULL };
    VkSubpassDependency dep = { 0, VK_SUBPASS_EXTERNAL, VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                                VK_PIPELINE_STAGE_TRANSFER_BIT, VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
                                VK_ACCESS_TRANSFER_READ_BIT, 0 };
    VkRenderPassCreateInfo rpci = { VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO, NULL, 0, 1, &att, 1, &sp, 1, &dep };
    CK(p_vkCreateRenderPass(g.dev, &rpci, NULL, &g.rp), "create_render_pass");
    VkFramebufferCreateInfo fbci = { VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO, NULL, 0, g.rp, 1, &g.view, W, H, 1 };
    CK(p_vkCreateFramebuffer(g.dev, &fbci, NULL, &g.fb), "create_framebuffer");

    VkShaderModuleCreateInfo smci = { VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, sizeof g1_comp_spv,
                                      g1_comp_spv };
    CK(p_vkCreateShaderModule(g.dev, &smci, NULL, &g.sm_comp), "shader_compute");
    smci.codeSize = sizeof g1_vert_spv;
    smci.pCode = g1_vert_spv;
    CK(p_vkCreateShaderModule(g.dev, &smci, NULL, &g.sm_vert), "shader_vertex");
    smci.codeSize = sizeof g1_frag_spv;
    smci.pCode = g1_frag_spv;
    CK(p_vkCreateShaderModule(g.dev, &smci, NULL, &g.sm_frag), "shader_fragment");

    VkDescriptorSetLayoutBinding dslb = { 0, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL };
    VkDescriptorSetLayoutCreateInfo dslci = { VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, 1, &dslb };
    CK(p_vkCreateDescriptorSetLayout(g.dev, &dslci, NULL, &g.dsl), "descriptor_set_layout");
    VkDescriptorPoolSize dps = { VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1 };
    VkDescriptorPoolCreateInfo dpci = { VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1, 1, &dps };
    CK(p_vkCreateDescriptorPool(g.dev, &dpci, NULL, &g.dpool), "descriptor_pool");
    VkDescriptorSetAllocateInfo dsai = { VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, g.dpool, 1, &g.dsl };
    CK(p_vkAllocateDescriptorSets(g.dev, &dsai, &g.dset), "descriptor_set");
    VkDescriptorBufferInfo dbi = { g.dev_buf.buf, 0, VK_WHOLE_SIZE };
    VkWriteDescriptorSet wds = { VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, g.dset, 0, 0, 1,
                                 VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &dbi, NULL };
    p_vkUpdateDescriptorSets(g.dev, 1, &wds, 0, NULL);

    VkPushConstantRange pcr_c = { VK_SHADER_STAGE_COMPUTE_BIT, 0, 8 }, pcr_f = { VK_SHADER_STAGE_FRAGMENT_BIT, 0, 8 };
    VkPipelineLayoutCreateInfo plci = { VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &g.dsl, 1, &pcr_c };
    CK(p_vkCreatePipelineLayout(g.dev, &plci, NULL, &g.pl_comp), "pipeline_layout_compute");
    plci.setLayoutCount = 0;
    plci.pSetLayouts = NULL;
    plci.pPushConstantRanges = &pcr_f;
    CK(p_vkCreatePipelineLayout(g.dev, &plci, NULL, &g.pl_gfx), "pipeline_layout_graphics");

    VkComputePipelineCreateInfo cpci = { VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO, NULL, 0,
        { VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO, NULL, 0, VK_SHADER_STAGE_COMPUTE_BIT, g.sm_comp,
          "main", NULL }, g.pl_comp, VK_NULL_HANDLE, -1 };
    CK(p_vkCreateComputePipelines(g.dev, VK_NULL_HANDLE, 1, &cpci, NULL, &g.pipe_comp), "pipeline_compute");

    VkPipelineShaderStageCreateInfo stages[2] = {
        { VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO, NULL, 0, VK_SHADER_STAGE_VERTEX_BIT, g.sm_vert, "main",
          NULL },
        { VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO, NULL, 0, VK_SHADER_STAGE_FRAGMENT_BIT, g.sm_frag,
          "main", NULL } };
    VkPipelineVertexInputStateCreateInfo vis = { .sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO };
    VkPipelineInputAssemblyStateCreateInfo ias = { VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO, NULL,
                                                   0, VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, VK_FALSE };
    VkPipelineViewportStateCreateInfo vps = { VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO, NULL, 0, 1, NULL,
                                              1, NULL };
    VkPipelineRasterizationStateCreateInfo rs = { VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO, NULL, 0,
                                                  VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL, VK_CULL_MODE_NONE,
                                                  VK_FRONT_FACE_COUNTER_CLOCKWISE, VK_FALSE, 0, 0, 0, 1.0f };
    VkPipelineMultisampleStateCreateInfo ms = { .sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
                                                .rasterizationSamples = VK_SAMPLE_COUNT_1_BIT };
    VkPipelineColorBlendAttachmentState cba = { VK_FALSE, 0, 0, 0, 0, 0, 0, VK_COLOR_COMPONENT_R_BIT };
    VkPipelineColorBlendStateCreateInfo cbs = { VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO, NULL, 0,
                                                VK_FALSE, VK_LOGIC_OP_COPY, 1, &cba, { 0 } };
    VkDynamicState dyn[] = { VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };
    VkPipelineDynamicStateCreateInfo dys = { VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO, NULL, 0, 2, dyn };
    VkGraphicsPipelineCreateInfo gpci = { VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO, NULL, 0, 2, stages, &vis,
                                          &ias, NULL, &vps, &rs, &ms, NULL, &cbs, &dys, g.pl_gfx, g.rp, 0,
                                          VK_NULL_HANDLE, -1 };
    CK(p_vkCreateGraphicsPipelines(g.dev, VK_NULL_HANDLE, 1, &gpci, NULL, &g.pipe_gfx), "pipeline_graphics");

    VkCommandPoolCreateInfo cpoolci = { VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL,
                                        VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, qfam };
    CK(p_vkCreateCommandPool(g.dev, &cpoolci, NULL, &g.cpool), "command_pool");
    VkCommandBufferAllocateInfo cbai = { VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, g.cpool,
                                         VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1 };
    CK(p_vkAllocateCommandBuffers(g.dev, &cbai, &g.cmd), "command_buffer");
    VkFenceCreateInfo fci = { .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO };
    CK(p_vkCreateFence(g.dev, &fci, NULL, &g.fence), "fence");
    say("stage=setup ok");

    uint64_t state = opt.seed, sums[ROUNDS][2];
    int mismatched = 0;
    for (int round = 0; round < ROUNDS; round++) {
        uint32_t nonce_c = (uint32_t)splitmix(&state), nonce_a = (uint32_t)splitmix(&state),
                 nonce_b = (uint32_t)splitmix(&state);
        if (nonce_a == nonce_b)
            nonce_b ^= 1;
        say("round=%d nonces compute=0x%08x full=0x%08x rect=0x%08x rect=%u,%u %ux%u", round, nonce_c, nonce_a,
            nonce_b, rect.x, rect.y, rect.w, rect.h);
        for (uint32_t i = 0; i < N; i++) {
            ((uint32_t *)g.rb_comp.map)[i] = SENTINEL_READBACK;
            ((uint32_t *)g.rb_img.map)[i] = SENTINEL_READBACK;
        }
        CK(host_sync(&g.rb_comp, 1), "flush_readback");
        CK(host_sync(&g.rb_img, 1), "flush_readback");

        CK(p_vkResetCommandBuffer(g.cmd, 0), "reset_command_buffer");
        VkCommandBufferBeginInfo bi = { VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, NULL,
                                        VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT, NULL };
        CK(p_vkBeginCommandBuffer(g.cmd, &bi), "begin_command_buffer");

        p_vkCmdFillBuffer(g.cmd, g.dev_buf.buf, 0, VK_WHOLE_SIZE, SENTINEL_DEVICE);
        barrier(VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT | VK_PIPELINE_STAGE_TRANSFER_BIT,
                VK_ACCESS_TRANSFER_WRITE_BIT, VK_ACCESS_SHADER_WRITE_BIT | VK_ACCESS_TRANSFER_READ_BIT);
        if (strcmp(opt.inject, "skip-compute")) {
            uint32_t pc[2] = { nonce_c, N };
            p_vkCmdBindPipeline(g.cmd, VK_PIPELINE_BIND_POINT_COMPUTE, g.pipe_comp);
            p_vkCmdBindDescriptorSets(g.cmd, VK_PIPELINE_BIND_POINT_COMPUTE, g.pl_comp, 0, 1, &g.dset, 0, NULL);
            p_vkCmdPushConstants(g.cmd, g.pl_comp, VK_SHADER_STAGE_COMPUTE_BIT, 0, sizeof pc, pc);
            p_vkCmdDispatch(g.cmd, (N + 63) / 64, 1, 1);
        }
        barrier(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT, VK_ACCESS_SHADER_WRITE_BIT,
                VK_ACCESS_TRANSFER_READ_BIT);
        VkBufferCopy bc = { 0, 0, (VkDeviceSize)N * 4 };
        p_vkCmdCopyBuffer(g.cmd, g.dev_buf.buf, g.rb_comp.buf, 1, &bc);

        VkClearValue clear = { .color.uint32 = { CLEAR_VALUE, 0, 0, 0 } };
        VkRenderPassBeginInfo rpbi = { VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO, NULL, g.rp, g.fb,
                                       { { 0, 0 }, { W, H } }, 1, &clear };
        p_vkCmdBeginRenderPass(g.cmd, &rpbi, VK_SUBPASS_CONTENTS_INLINE);
        if (strcmp(opt.inject, "skip-draw")) {
            VkViewport vp = { 0, 0, (float)W, (float)H, 0, 1 };
            VkRect2D full = { { 0, 0 }, { W, H } }, part = { { (int32_t)rect.x, (int32_t)rect.y }, { rect.w, rect.h } };
            uint32_t pc_a[2] = { nonce_a, W }, pc_b[2] = { nonce_b, W };
            p_vkCmdBindPipeline(g.cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, g.pipe_gfx);
            p_vkCmdSetViewport(g.cmd, 0, 1, &vp);
            p_vkCmdSetScissor(g.cmd, 0, 1, &full);
            p_vkCmdPushConstants(g.cmd, g.pl_gfx, VK_SHADER_STAGE_FRAGMENT_BIT, 0, sizeof pc_a, pc_a);
            p_vkCmdDraw(g.cmd, 3, 1, 0, 0);
            p_vkCmdSetScissor(g.cmd, 0, 1, &part);
            p_vkCmdPushConstants(g.cmd, g.pl_gfx, VK_SHADER_STAGE_FRAGMENT_BIT, 0, sizeof pc_b, pc_b);
            p_vkCmdDraw(g.cmd, 3, 1, 0, 0);
        }
        p_vkCmdEndRenderPass(g.cmd);
        VkBufferImageCopy bic = { 0, 0, 0, { VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1 }, { 0, 0, 0 }, { W, H, 1 } };
        p_vkCmdCopyImageToBuffer(g.cmd, g.img, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, g.rb_img.buf, 1, &bic);
        barrier(VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_HOST_BIT, VK_ACCESS_TRANSFER_WRITE_BIT,
                VK_ACCESS_HOST_READ_BIT);
        CK(p_vkEndCommandBuffer(g.cmd), "end_command_buffer");

        CK(p_vkResetFences(g.dev, 1, &g.fence), "reset_fence");
        VkSubmitInfo si = { VK_STRUCTURE_TYPE_SUBMIT_INFO, NULL, 0, NULL, NULL, 1, &g.cmd, 0, NULL };
        double t_submit = now_ms();
        CK(p_vkQueueSubmit(g.queue, 1, &si, g.fence), "queue_submit");
        VkResult wr = p_vkWaitForFences(g.dev, 1, &g.fence, VK_TRUE, (uint64_t)opt.timeout_ms * 1000000ull);
        if (wr == VK_SUCCESS && !strcmp(opt.inject, "hang-fence")) {
            VkFence never;
            CK(p_vkCreateFence(g.dev, &fci, NULL, &never), "fence");
            wr = p_vkWaitForFences(g.dev, 1, &never, VK_TRUE, (uint64_t)opt.timeout_ms * 1000000ull);
            p_vkDestroyFence(g.dev, never, NULL);
        }
        if (wr == VK_TIMEOUT)
            g.unsafe = 1;
        CK(wr, "wait_fence");
        say("round=%d stage=gpu_done gpu_wall_ms=%.3f", round, now_ms() - t_submit);

        CK(host_sync(&g.rb_comp, 0), "invalidate_readback");
        CK(host_sync(&g.rb_img, 0), "invalidate_readback");
        uint32_t *comp = g.rb_comp.map, *img = g.rb_img.map;
        if (!strcmp(opt.inject, "corrupt"))
            img[(size_t)(H / 2) * W + W / 2] ^= 1u;
        g1_cmp cc = g1_check_compute(comp, N, nonce_c, SENTINEL_DEVICE);
        g1_cmp ci = g1_check_image(img, W, H, nonce_a, nonce_b, rect, SENTINEL_READBACK, CLEAR_VALUE);
        sums[round][0] = g1_fnv1a64(comp, (size_t)N * 4);
        sums[round][1] = g1_fnv1a64(img, (size_t)N * 4);
        say("round=%d compute words=%u mismatches=%zu unwritten=%zu fnv=0x%016" PRIx64, round, N, cc.mismatches,
            cc.unwritten, sums[round][0]);
        say("round=%d image pixels=%u mismatches=%zu unwritten=%zu fnv=0x%016" PRIx64, round, N, ci.mismatches,
            ci.unwritten, sums[round][1]);
        if (cc.mismatches)
            say("round=%d compute first_bad=%zu got=0x%08x want=0x%08x", round, cc.first_bad, cc.first_got,
                cc.first_want);
        if (ci.mismatches)
            say("round=%d image first_bad=(%zu,%zu) got=0x%08x want=0x%08x", round, ci.first_bad % W,
                ci.first_bad / W, ci.first_got, ci.first_want);
        mismatched |= cc.mismatches || ci.mismatches;
    }
    if (sums[0][0] == sums[1][0] || sums[0][1] == sums[1][1]) {
        say("rounds produced identical readback despite different nonces");
        mismatched = 1;
    }
    if (mismatched) {
        rc = EXIT_MISMATCH;
        verdict = "MISMATCH";
    } else if (is_cpu_device) {
        rc = EXIT_CPU_SELFTEST;
        verdict = "CPU_SELFTEST_PASS (software device - NOT GPU evidence)";
    } else {
        rc = EXIT_PASS;
        verdict = "GPU_OFFSCREEN_PASS (offscreen compute+raster+readback only)";
    }

done:
    cleanup();
    say("VERDICT %s exit=%d", verdict, rc);
    if (log_fd >= 0)
        close(log_fd);
    return rc;
}
