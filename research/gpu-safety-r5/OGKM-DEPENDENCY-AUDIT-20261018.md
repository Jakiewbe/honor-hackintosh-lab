# 35 个符号的定义与依赖审计（R50 第二单元）

固定输入：OGKM `e4a5faa`，3821 个源文件。工具：`tools/find-symbol-defs.py`、`tools/dep-survey.py`。

## 一、先修掉工具自身的假阳性

第一版匹配器把 `kernel-open/nvidia/nv.c:721` 当成 `rm_init_rm` 的定义，实际那是调用点：

```c
if (!rm_init_rm(*sp))
{
```

原因：正则 `name(...) {` 允许 `[^;{}]*` 吞掉一个多余的 `)`，从而把 `if (!call(...))` + `{` 误判为函数体。

**已修正**：要求函数名之前同一行的文本必须为空（名字在行首）或只含类型记号（`[A-Za-z_][A-Za-z0-9_ \t\*]*`），
出现 `(`、`=`、`!`、`,` 一律拒绝。修正后 `kernel-open/` 的 4 个命中全部消失。

## 二、修正后的结果：35/35，且只落在 5 个翻译单元

| 文件 | 行数 | include | 其中 Linux/Unix 相关 | 用 `NV_ENTER_RM_RUNTIME` | 提及 `__use_altstack__` |
|---|---|---|---|---|---|
| `src/nvidia-modeset/src/nvkms.c` | 7100 | 30 | **0** | 否 | 否 |
| `src/nvidia-modeset/kapi/src/nvkms-kapi.c` | 4258 | 30 | **1** | 否 | 否 |
| `src/nvidia/arch/nvalloc/unix/src/osapi.c` | 6285 | 52 | **1** | **是** | **是** |
| `src/nvidia/arch/nvalloc/unix/src/dynamic-power.c` | 3186 | 19 | **1** | **是** | 否 |
| `src/nvidia/arch/nvalloc/unix/src/unix_intr.c` | 1051 | 14 | **0** | **是** | 否 |

聚合：5 个文件，3 个含 Linux/Unix 相关 include，3 个使用 RM runtime 宏，1 个提及 altstack。

## 三、这条结果的意义

1. **构建闭包问题缩小到 5 个 TU**，且全部位于**跨平台的 Unix / modeset 层**，不是 `kernel-open/` 那批 Linux glue。
2. Linux/Unix 相关 include 每个文件只有 **0–1 个**，说明这几层本来就用抽象层隔离了平台差异。
3. ABI 风险**定位到一个文件**：`osapi.c`（唯一提及 `__use_altstack__` 的文件，同时使用 `NV_ENTER_RM_RUNTIME`）。

## 四、仍未证明的

- 这 5 个 TU 能否在 Darwin 工具链下编译（未尝试，禁止靠加 `-D` 试错）；
- `NV_ENTER_RM_RUNTIME` 在 altstack 路径下修改 `%rbp` 与本站传 `NULL` 栈的冲突；
- 编译通过后能否链接、以及链接后 kext 是否可加载。

## 五、下一步

在**隔离构建**（不污染现有 9 单元门禁）中逐个尝试这 5 个 TU 的 Darwin 对象编译，
记录首个真实错误、所需的最小 include 路径与宏，产出一张"可编译 / 需适配 / 不可编译"的三分表。
每次只加一个文件，失败即记录，不做参数试错。

## 六、隔离编译探针的首批真实结果（R49，run 39089285626）

门禁新增 ogkm_probe：把 5 个 TU 各自编译成 Darwin 对象，**不加入链接**，失败只记录不判失败。

| 文件 | 结果 | 首个错误 |
|---|---|---|
| unix_intr.c | COMPILE_FAILED | 
voc/prelude.h:249: anonymous bit-field cannot have qualifiers |
| osapi.c | COMPILE_FAILED | 同上 |
| dynamic-power.c | COMPILE_FAILED | 同上 |
| 
vkms.c | COMPILE_FAILED | 
vkms-types.h:1645: expected ';' after struct |
| 
vkms-kapi.c | COMPILE_FAILED | 同上 |

两类错误都指向**编译语言选择**：这些文件是 C，而门禁的 common_flags 带着 -std=c++17 -fno-rtti
-fno-exceptions（C++ 专用）。"anonymous bit-field cannot have qualifiers" 与 "expected ';' after struct"
在 C 语义下通常不出现。

**下一轮的唯一动作**：把探针改为 C 编译（-x c，去掉 C++ 专用 flag），重跑，记录首批真实错误。
不调其它参数，不试 -D。

探针实现过程中的两次错误也记录在此，避免重复：probe_root 曾取成 
vroot.parent（应为两级上），
导致全部 MISSING；随后又把不存在的 include 目录传给 -I，clang 直接报 "no such file"。两处已修。

## 七、改成 C 编译后的结果（R50，run 39089494955）

| 文件 | 结果 | 说明 |
|---|---|---|
| **src/nvidia-modeset/src/nvkms.c** | **COMPILED** | 首个在 Xcode 16.4 工具链下产出 Darwin 对象的 OGKM 跨平台 TU |
| osapi.c / unix_intr.c / dynamic-power.c | COMPILE_FAILED | 
v-priv.h:233: unknown type name 'nv_dynamic_power_mode_t' |
| 
vkms-kapi.c | COMPILE_FAILED | 
vkms-softfloat.h:32: 'nv-softfloat.h' file not found |

### 两个失败的性质不同

1. **
vkms-kapi.c 是 include 路径问题**：
v-softfloat.h 实际在 src/common/softfloat/nvidia/，
   探针没有把这个目录加进 -I。属于构建配置遗漏，可直接修。
2. **三个 RM 文件是平台层 typedef 缺失**：
v_dynamic_power_mode_t 定义在
   kernel-open/common/inc/nv.h:757——那是 **Linux/FreeBSD 的 kernel-open 层**；
   Darwin 的 
v-xnu.h 里没有等价定义。这不是"加个宏"能解决的，属于移植层缺口。

### 意义


vkms.c 编译通过说明：**OGKM 的 modeset 核心层不需要 Linux 才能编译**，之前的失败全部来自语言选择
（C++ 当 C 编）。这一条把"公开源码路线不可行"的怀疑削掉了一大块——同时也说明我此前把
"编译失败"归因于"源码不可用"是过早的。

### 下一轮

先修 include 路径（
v-softfloat.h），看 
vkms-kapi.c 能否也编过；RM 那三个文件另算，
需要评估 Darwin 层要提供哪些 typedef，而不是把 kernel-open/common/inc/nv.h 整个拖进来
（那会把 Linux 依赖一起带进来）。

## 八、include 修正后的结果（R51）

| 文件 | 结果 |
|---|---|
| 
vkms.c | **COMPILED** |
| 
vkms-kapi.c | **COMPILED**（修好 softfloat.h 路径后） |
| osapi.c / unix_intr.c / dynamic-power.c | 失败：
v-priv.h:233: unknown type name 'nv_dynamic_power_mode_t' |

两处 include 修正都是**构建配置遗漏**，不是移植性问题：

v-softfloat.h 在 src/common/softfloat/nvidia/，它又 include 的 softfloat.h 在
src/common/softfloat/source/include/。

## 剩下的唯一阻塞：一个平台 typedef


v_dynamic_power_mode_t 定义在 kernel-open/common/inc/nv.h:757：

`c
typedef enum { NV_DYNAMIC_PM_NEVER, NV_DYNAMIC_PM_COARSE, NV_DYNAMIC_PM_FINE } nv_dynamic_power_mode_t;
`

那是 Linux/FreeBSD 的 kernel-open 层。**本站 kexts/NVRM 里完全没有这个类型**（已检索，零命中）。

因此三个 RM 文件的失败原因可以精确表述为：

> Darwin 移植层缺少 kernel-open/common/inc/nv.h 中的平台公共类型，而不是缺少函数实现。

## 为什么不能直接 include 那个头

kernel-open/common/inc/nv.h 会连带引入 Linux 内核设施（linux/…、
v-linux.h），
把它整个拖进 Darwin 构建等于把 Linux 依赖带进来。正确做法是提供一个**最小的 Darwin 等价头**，
只定义 RM 通用层需要的类型（
v_dynamic_power_mode_t、
v_pm_action_level_t 等），
再逐步看还缺什么。

## 下一轮

在探针里加一个最小的 Darwin 兼容头（只放 typedef，不含任何 Linux include），
看三个 RM 文件能推进到哪一步。每次只补一个类型，缺什么记什么，不做整体搬运。

## 九、平台宏实验（R52）

两个实验，结论都很具体：

### 实验 A：强制加最小 Darwin 兼容头

esearch/gpu-safety-r5/darwin-compat/nv-darwin-compat.h 只放 
v_dynamic_power_mode_t（纯 typedef，
无任何 Linux include），用 -include 强制引入。结果：三个 RM 文件的错误从

v_dynamic_power_mode_t 推进到 osapi.h:108: must use 'struct' tag to refer to type 'nv_state_t'。

→ 说明 compat 头方向正确，下一个缺的是 
v_state_t 的 typedef 归属。

### 实验 B：去掉 -DNV_LINUX

门禁的宏来自 Linux 干跑，天然带 -DNV_LINUX。去掉后：

| 文件 | 结果 |
|---|---|
| 
vkms.c / 
vkms-kapi.c | **失败**：
vUnixVersion.h:12: "should only be included in UNIX builds" |
| 三个 RM 文件 | 仍是 must use 'struct' tag ... nv_state_t |

→ **平台宏是必需的**，不能靠"不声明平台"绕过。没有 NV_LINUX/NV_FREEBSD 之一，modeset 头直接拒绝编译。

## 因此真正的结论


v_state_t 在 src/nvidia/arch/nvalloc/unix/include/nv.h:646 有 } nv_state_t;，但那个定义在
-DNV_LINUX 下并不生效（否则不会报"必须用 struct 标签"）。也就是说：

> 这三个 RM 文件的类型定义按平台分支：Linux 走 kernel-open/common/inc/nv.h，
> FreeBSD 走 
v-freebsd.h，**Darwin 需要自己的那一份**。

而 NullMoth 的 kexts/NVRM/nv-xnu.h 正是为 Darwin 写的那一层。所以下一步不应继续在探针里
逐个补 typedef，而应把探针的 include 路径换成"OGKM 交叉层 + NullMoth 的 Darwin 平台头"，
看能否形成一次真实编译。这才是移植层该做的事，也解释了为什么单补 typedef 走不通。

## 本轮未做

- 未修改任何 OGKM 源码；
- 未把探针加入链接；
- 未把 compat 头接进生产构建（它只用于探针实验）。

## 十、混合链接实验（R54，run 39090712869）

把 9 个已知单元与 5 个探针对象一起链接（独立产物 NVRM-ogkm.kext，不影响原来那个）：

| 指标 | 9 单元 | 9+5 单元 |
|---|---|---|
| 链接 | exit 0 | **exit 0** |
| 产物大小 | 362,472 B | **591,624 B** |
| 导入总数 | 517 | **821** |
| 缺口类（nvKms*/rm_*/nvrm_*） | **42** | **23** |

**缺口从 42 降到 23。** 剩下的 23 个是 _nvKmsKapiAllocateChannelEvent、_nvKmsGetSurfaceMemoryFormatInfo
一类——属于 5 个 TU 之外的其他 nvidia-modeset 源文件。

## 但导入总数上升了 304

这是必须记下的另一面：osapi.c 一旦参与链接，就会调用 RM 核心的 API，于是新出现
_Nv04AllocContextDmaKernel、_Nv01AllocMemoryKernel、_RmDisableAdapter 等约 39 个已归类的 RM core 符号
（另有约 287 个同类符号我的分类器还没覆盖，数字待精确）。

结论：**只补 Unix 适配层不够，RM 核心本身也要进来**。这与"源码都在公开树里"的判断一致，
但把工作量从 5 个 TU 扩大到 RM core。

## 边界

- 这是**独立实验产物**，没有替换生产链接目标，也没有改变 9 单元门禁；
- 两个产物混用了不同宏配置（探针带 -DNVRM，9 单元不带），**ABI/ODR 一致性未验证**，因此这个混合产物
  **不可用于加载**，只用于统计缺口；
- 未加载、未签名、未操作实机。

## 十一、altstack ABI 风险在当前配置下不成立（R57）

NV_ENTER_RM_RUNTIME 的 altstack 分支只在 #if defined(__use_altstack__) 时启用
（src/nvidia/arch/nvalloc/unix/include/osapi.h:34）。

检索 OGKM 树内全部 23 个构建文件（Makefile / *.mk / *.sh / Kbuild）：

`
grep -rn 'altstack' → 无任何命中
`

也就是说 **OGKM 自己的构建系统不定义 __use_altstack__**。我们的探针使用由 Linux 干跑提取的宏，
因此该宏同样不存在 → 编译出的 NV_ENTER_RM_RUNTIME 走的是**平凡分支**，没有 %rbp 改写。

结论（限定范围）：**在当前探针配置下，altstack ABI 风险不激活。**

同时必须写清反面：一旦有构建流程加入 -D__use_altstack__，本站在 31 处传 NULL 栈的 RM 调用
（该计数来自并行提交 1dc3567 的审计）就会变成真实风险。所以这不是"已解决"，而是"当前未激活"。

## 十二、与并行产出的关系

1dc3567 已完成逐符号依赖清单（dependency-audit/dependencies.json，3824 文件、tree SHA 绑定），
252775 已处理 owner-copy 的真实错误传播。本轮不重复这两项，只补它们未覆盖的编译侧实测：
5/5 TU 编译通过、混合链接 42→23、以及本条 altstack 配置判定。

## 十三、加入三个 modeset TU 后：缺口 42 → 11（R58，run 39095068216）

新增探针单元：
vkms-kapi-sync.c、
vkms-kapi-notifiers.c、
vkms/lib/nvkms-format.c。

| 指标 | R54（5 TU） | R58（8 TU） |
|---|---|---|
| 探针编译 | 5/5 | **8/8** |
| 混合链接 | exit 0 | **exit 0** |
| 产物大小 | 591,624 B | **600,840 B** |
| 导入总数 | 821 | **810** |
| **缺口符号** | 23 | **11** |

## 剩余 11 个，分成两类

**a) 3 个 modeset 符号**：_nvKmsParseSemaphore、_nvKmsResetNotifier、_nvKmsResetSemaphore
—— 仍属 nvidia-modeset，尚未纳入探针（继续加文件即可）。

**b) 8 个本站符号**：7 个 _nvrm_*（定义在 kexts/NVRM/nvrm_pageoff.c）+
_rm_is_vgpu_supported_device（OGKM 里应有定义，需再定位）。

## 一个此前失败的线索现在有解


vrm_pageoff.c 早先三种方式都编不过，其中一版失败原因正是 unknown type name 'nv_dynamic_power_mode_t'
与 
v_state_t 缺 typedef——**那和探针最初遇到的错误是同一类**。而探针后来靠 **-DNVRM** 解决了。
所以下一轮应当用探针现在的配置（-x c + -DNVRM + OGKM include）重新尝试 
vrm_pageoff.c，
而不是继续把它当成"编不了"。

## 十四、缺口 11 → **2**（R59，run 39095634270 / 39095755616）

两步：

1. 加 
vkms-sync.c 与 os-hypervisor.c → 10/10 编译，缺口 11 → 7；
2. 把**我们自己的** kexts/NVRM/nvrm_pageoff.c 按探针配置（-x c -std=gnu11 -DNVRM + 候选树 include）编译
   → **编译通过**，缺口 7 → **2**。

| 阶段 | 探针 TU | 缺口 |
|---|---|---|
| R54 | 5 | 23 |
| R58 | 8 | 11 |
| R59a | 10 | 7 |
| **R59b** | **11（含本站 1 个）** | **2** |

混合链接产物 615,856 B，exit 0。

## 剩余 2 个

_nvrm_kapi_dev_handles、_nvrm_kapi_mem_handle —— 在 
vrm_surfshare.cpp:18 与

vrm_gpuva.cpp:41 都只以 extern "C" **声明**形式出现，真正的定义文件尚未定位（不在 9 单元里）。

## 需要强调的口径

这**不是**"NVRM 可构建了"。混合链接里的 11 个 TU 使用了两种宏配置（探针带 -DNVRM，原 9 单元不带），
ABI/ODR 一致性未验证；
vrm_pageoff.c 能编译只说明它在该配置下语法与依赖成立。
产物仍只是统计工具，**不可加载**。

## 十五、缺口归零（R60，run 39095910253）


vrm_kapi_fields.c（定义最后两个符号 
vrm_kapi_dev_handles / 
vrm_kapi_mem_handle）
加入探针后：

| 指标 | 值 |
|---|---|
| 探针编译 | **12/12** |
| 混合链接 | **exit 0**，615,792 B |
| **缺口符号（nvKms*/rm_*/nvrm_*）** | **0** |

累计轨迹：**42 → 23 → 11 → 7 → 2 → 0**。

## 这证明了什么，不证明什么

**证明**：42 个曾经"无提供者"的导入符号，其定义全部存在于公开源码（OGKM + 本仓库），并且
在正确的构建配置下（-x c -std=gnu11 -DNVRM，加上 Linux 干跑提取的宏）**都能编译成 Darwin 对象**，
放进同一个链接后**没有一个残留未定义**。

**不证明**：
1. 这个混合链接**混用了两种宏配置**（探针 12 个带 -DNVRM，原 9 个单元不带），ABI/ODR 一致性未验证；
2. 链接成功 ≠ 可加载：Mach-O 里的导入符号仍需在加载时解析；
3. 仍无任何实机运行证据，KEXT-LOAD / GPU-RUNTIME / 像素读回全部未执行。

## 因此下一步的性质变了

之前的任务是"补符号"，现在变成"**统一配置 + 验证一致性**"：
把原 9 个单元也切到 -DNVRM 配置（或证明不需要），让整个 kext 只有一套 ABI，
然后再看链接与导入情况。这是从"统计缺口"走向"真实可构建"的一步。

## 十六、统一配置实验（R61，run 39096103191）

把原 9 个单元也切到 -DNVRM（与探针同配置），编译后与 12 个探针对象一起链接：

| 指标 | 结果 |
|---|---|
| 9 个原单元编译 | **9/9 exit 0** |
| 统一链接（21 对象） | **exit 0**，615,792 B |
| 缺口符号 | **0** |
| 未定义总数 | 823 |

## 但统一配置不是免费的

相对生产配置（0 告警增量），-DNVRM 下的告警：

| 单元 | 告警 |
|---|---|
| NVRM.cpp | **33** |
| os-nvkms-xnu.cpp | **14** |
| os-xnu.cpp | 11 |
| 
vrm_gpuva.cpp | 10 |
| os-xnu2.cpp | 8 |
| 
v_xnu_stubs.cpp / 
vrm_fbinfo.cpp / 
vrm_surfshare.cpp | 各 6 |
| 
vkms_shaders.cpp | 0 |
| **合计** | **94** |

原因是 -DNVRM 会打开不同的头文件分支，进而暴露不同的类型/符号声明。

## 结论

1. **统一配置在技术上可行**：9/9 编译、链接成功、缺口 0；
2. **但不能直接采用**：94 条新告警必须先逐条判定（哪些是无害的类型转换、哪些是真实的 ABI 风险）；
3. 生产门禁仍是原配置（9 单元、0 告警增量），**未改动**；统一产物 NVRM-unified.kext 只是实验。

## 下一步

把 94 条告警按文件归类、抽样判定性质，产出一张"统一配置代价表"。只有这张表证明新增告警全部无害，
才谈得上把生产门禁切到统一配置。

## 十七、统一配置的代价表（R62）

94 条告警按类型归类（取自 run 39096103191 的 uni-*.txt）：

| 类型 | 数量 | 位置/性质 |
|---|---|---|
| -Wdeprecated-declarations | **40** | 绝大多数是 IOPCIDevice 一类 Apple 弃用 API（NVRM 24 条），与 ABI 无关 |
| -Wsign-conversion | **44** | 抽样均为 
vport/inline/util_gcc_clang.h 的 int → NvU32，即 OGKM 自身的宏/内联层 |
| -Wimplicit-int-conversion | **2** | ①NVRM.cpp:1229 unsigned int → UInt8；②
v_common_utils.h:96 unsigned → unsigned short |
| -Wunused-variable | **1** | os-xnu2.cpp |
| 其他 | 7 | 归入上面各类统计余量 |

### 需要单独处理的两条

-Wimplicit-int-conversion 是唯一可能丢精度的类别：

1. kexts/NVRM/NVRM.cpp:1229 —— **我们的代码**，unsigned int 收窄到 UInt8；
2. src/common/unix/common/inc/nv_common_utils.h:96 —— OGKM 头文件。

两条都指向"值域受控的枚举/索引"，但**未逐行核对值域**，所以不能判定无害。

### 结论

- 94 条里 **84 条属于弃用警告与符号性问题**，不改变对象布局，不构成 ABI 风险；
- **2 条窄化转换需要人工确认值域**（一条在我们代码里，可以在补丁里显式转换消除）；
- 因此"统一切到 -DNVRM"的代价是**可控的**，但不是一个可以静默接受的动作。

### 下一步

在补丁里把 NVRM.cpp:1229 的窄化显式化（如 (UInt8)(x & 0xFF) 或改用 NvU8），
再评估 OGKM 那条是否需要同样处理；之后才可能把生产门禁切到统一配置。

## 十八、对"缺口 0"的更正（R64）

统一产物 NVRM-unified.kext 的未定义符号表（823 条）按提供者分类：

| 类别 | 数量 |
|---|---|
| iokit/libkern | 404 |
| **ogkm-rm-core** | **341** |
| mach/kern | 66 |
| c++ runtime | 2 |
| 未归类 | 10（如 _kvgpumgrCreateRequestVgpu） |

**关键：那 341 条 RM core 符号仍然未定义**，而我们只把 nvKms*/rm_*/nvrm_* 这三族统计为"缺口"，
所以之前的"缺口 0"只对**那三类**成立，不等于整个 kext 无未定义符号。

-kext -nostdlib 链接**允许**未解析导入（加载期才解析），所以链接成功并不表示自足。

## 加载期会发生什么

kexts/NVRM/Info.plist 声明了 com.apple.kpi.iokit/libkern/bsd/mach/unsupported，
覆盖 404 + 66 的系统符号；但 **341 个 _Nv04*/_Rm*/__nvoc_* 没有提供者**，
它们既不在系统 KPI 里，也不在我们这 21 个对象里 → **加载会因未解析符号失败**。

## 结论

1. 之前"42 → 0"是正确的，但**范围被我表述得过宽**：它只是被审计的那三个符号族；
2. 真正的闭环要求是：**RM 核心也要编进来**（或找到提供者），否则 kext 不可能加载；
3. 这把工作量的量级从"再补几个 TU"改成"把 RM core 纳入构建"，与 R54 的观察一致。

## 下一步

先量化 RM core 的规模：src/nvidia/src/... 里定义这些符号的 TU 有多少、依赖多少 Linux 设施。
在拿到这个数字之前，不谈"可加载"。
