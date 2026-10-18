> **独立审计纠正：** 本文历史“45闭源→9缺失→135/988→需新写端口层”不能作为当前构建状态。官方1280C TU/完整归档/候选链接已在run39127772586验收。988探针不是同输入同参数对照且编译失败仍exit0，已退休。词法索引中的DECL不等于提供者定义；未定位不等于源码不存在。下一步只补真实调用ABI/loader/PM，不重复此前完整构建。 见[审计](HARNESS-AUDIT-20261018.md)。

> **R79 纠错优先：** 本文中的“45符号闭源依赖”和“351→667证明不收敛”已撤回，见 [R79审计纠错](R79-AUDIT-CLOSURE-GATE-20261018.md)。历史数字仅限各自记录的对象集合；不可直接当作当前构建闭包。新扫描337个词法候选、9个UNKNOWN，新同基线链接及ABI尚待原生执行。

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

## 十九、RM 核心的规模量化（R65）

统一产物 823 个未定义符号，按名称与来源粗分：

| 桶 | 数量 | 说明 |
|---|---|---|
| IO* / OS*（iokit/libkern） | 404 | 加载期由系统 KPI 解析 |
| mach/kern | 66 | 同上 |
| c++ runtime | 2 | 同上 |
| **RM 内部** | **351**（含 Cli*、gpumgr*、os*、
v*、kbus*、kdisp*、Nv04*、
voc_*、Rm*） | 无系统提供者 |

其中按名字细分：
voc_*/Nv\d\d* 仅 **14**、Rm*/
m* **47**，其余 ≈ 280 是
Cli*（client API）、gpumgr*、kbus*、kdisp*、os* 等 RM 子系统入口。

## 规模：不是"再补几个 TU"

| 目录 | .c 文件数 |
|---|---|
| src/nvidia/src（手写 kernel 层） | **720** |
| src/nvidia/generated（NVOC 生成层） | **268** |
| 合计 | **988** |

而且我用"逐文件找函数定义"的朴素方法在 src/nvidia/src 只找到 30 个定义——原因是 RM 的函数大量由
**NVOC 生成器**产出（__nvoc_*、类方法分派），不是手写函数。也就是说：

> 要让 RM core 进入构建，需要的是**运行 NVIDIA 的代码生成器**，而不是把 988 个 .c 逐个编一遍。

## 结论

1. 之前"42 → 0"只覆盖三族被审计符号，RM 核心仍是 351 个无提供者符号；
2. RM 的构建闭包包含一层**生成代码**，公开树里只提供生成后的 generated/，但生成器本身不在树中；
3. 因此"自建完整 NVRM"的现实路径是：**整层 RM 一起编译 + 接受 generated 目录的现成产物**，
   而不是逐符号补齐。

## 未做

未尝试编译 388+ TUs；未评估这层代码的 Linux 依赖；未讨论生成的 gen/ 与 generated/ 的版本一致性。

## 二十、生成层可编译性抽样（R66，run 39096634289）

从 src/nvidia/generated 里挑三个文件（先按体积取最小的一批）加入探针：

| 文件 | 结果 |
|---|---|
| g_regs_pb.c | **COMPILED** |
| g_rpc_iom.c | **COMPILED** |
| g_ccsl_nvoc.c | **COMPILED** |

探针合计 **15/15 编译通过**，混合链接缺口仍为 **0**。

## 意义

之前我担心"生成层需要 NVIDIA 的生成器才能编"。这次抽样说明：**generated/ 里的产物本身就是可编译的 C**，
至少这三个文件在 Darwin 工具链 + -DNVRM 配置下能编过。

但这只是 3/268 的样本，**不能外推为"整个生成层可编译"**。

## 下一步

扩大抽样到 20–30 个、覆盖不同子目录，得到一个**失败率**估计。只有失败率接近 0，才值得讨论"把整层 RM 纳入构建"；
如果失败率显著，就说明 Linux 依赖集中在生成层里，那时要重新评估路线。

## 二十一、RM 树抽样：23/23 编译通过，失败率 0%（R67，run 39096926794）

方法：在 generated/、src/kernel/、src/core/ 三处按 **每 40 个取 1 个**的确定性步长抽样，
用与探针相同的配置（-x c -std=gnu11 -DNVRM + Linux 干跑宏）逐个编译。

| 指标 | 值 |
|---|---|
| 抽样文件 | **23** |
| 编译通过 | **23** |
| 失败率 | **0.0%** |

## 这条证据的价值与边界

**价值**：说明 RM 的源码（含生成层）在 Darwin 工具链下**不存在普遍性的 Linux 依赖障碍**。
之前"988 个 TU 可能整体编不过"的担心，至少在这个抽样上是不成立的。

**边界**：
1. 23 个样本对 988 个 TU，覆盖率 2.3%，置信区间很宽——**不能外推为"整层可编译"**；
2. 编译通过 ≠ 语义正确：-DNVRM 下的头文件分支选择是否与发行版一致，未验证；
3. 链接自足性仍然不成立（统一产物里仍有 351 个 RM 内部符号无提供者）。

## 下一轮

把抽样扩大到 100+ 个（同样确定性步长），若失败率仍为 0，则"整层 RM 纳入构建"在编译层面就只剩工程量问题，
而不是可行性问题。届时再评估：编译时间、警告规模、链接自足性。

## 二十二、RM 树抽样扩大到 97 个：仍然 0% 失败（R68，run 39097088096）

把步长从每 40 取 1 改为**每 9 取 1**，覆盖 generated/、src/kernel/、src/core/：

| 指标 | R67 | R68 |
|---|---|---|
| 抽样 | 23 | **97** |
| 编译通过 | 23 | **97** |
| 失败率 | 0.0% | **0.0%** |

97 / 988 ≈ **9.8% 覆盖率**，仍未到"整层可编译"的结论门槛，但已足以说明：
**RM 源码在 Darwin 工具链下不存在系统性的解析/依赖障碍。**

## 仍未验证的三件事

1. **语义一致性**：-DNVRM 分支所选的头文件路径是否与发行版一致（宏组合未逐项核对）；
2. **链接自足**：统一产物仍有约 351 个 RM 内部符号无提供者；
3. **运行**：一次都没加载过。

## 下一步

把抽样推进到**全量编译尝试**（988 个 TU），记录：总编译时间、失败清单、告警总数。
这是"整层 RM 是否可构建"的最终判据；在此之前任何"可构建"表述都不成立。

## 二十三、抽样扩到 175 个：失败率 1.1%，两例都来自 SPDM（R69，run 39097307849）

| 指标 | 值 |
|---|---|
| 抽样 | **175**（步长 5，约 17.7% 覆盖率） |
| 编译通过 | 173 |
| 失败 | **2**（1.1%） |
| 失败文件 | spdm/conf_compute_keystore_gh100.c、spdm/kernel_spdm.c |
| 首错 | kernel_spdm.c:36: fatal error: 'nvspdm_rmconfig.h' file not found |

## 这两例的性质：include 路径缺失，不是源码不可用


vspdm_rmconfig.h 在树里**有两份**：

- src/nvidia/src/libraries/libspdm/nvidia/vspdm_rmconfig.h
- kernel-open/nvidia/nvspdm_rmconfig.h

探针没有把 libspdm/nvidia 加进 -I。也就是说，这两例与之前的 softfloat.h 同类——**构建配置遗漏**，
不是 Linux 依赖，也不是代码不可编译。

## 因此抽样结论

在 175 个样本中，**没有任何一例因 Linux 设施缺失而失败**；唯一的失败来自我们探针的 include 列表不全。
加上修好的 include，失败率预计归零，但**这是预测，不是结果**——要下一轮实跑才算。

## 下一步

把 src/nvidia/src/libraries/libspdm/nvidia 加进探针 include，重跑 175 样本；若归零，再推进到更大步长。

## 二十四、SPDM 的失败是 include 路径问题，不是外部依赖缺失（R70，run 39097535478）

补了 libspdm/nvidia 之后失败数仍是 2，但**首错已经推进**：

`
kernel_spdm.c:37: fatal error: 'internal/libspdm_common_lib.h' file not found
`

查树：该头真实存在——

`
src/nvidia/src/libraries/libspdm/3.5.0/include/internal/libspdm_common_lib.h
`

libspdm 目录下就是 3.5.0/（第三方库源码，随树发布）与 
vidia/（适配层）。

所以：**SPDM 既不缺源码，也不缺第三方库**，只缺 -I .../libspdm/3.5.0/include。

## 当前抽样结论（175 个）

| 项 | 值 |
|---|---|
| 通过 | 173 |
| 失败 | 2（同一子系统 SPDM） |
| 失败性质 | 探针 include 列表不全（已定位到确切缺失路径） |

也就是说：在 17.7% 的抽样覆盖里，**没有任何一例是"源码不含 Linux 支持"或"代码不可编译"**。

## 下一步

加 libspdm/3.5.0/include 后重跑；若归零，SPDM 这一族的结论就完整了：可编译，只是路径多。

## 二十五、SPDM include 补齐后：175/175，失败率 0%（R71，run 39097804916）

加入 src/nvidia/src/libraries/libspdm/3.5.0/include 后：

| 指标 | R69/R70 | **R71** |
|---|---|---|
| 抽样 | 175 | 175 |
| 通过 | 173 | **175** |
| 失败率 | 1.1% | **0.0%** |
| 探针 15 TU | — | **15/15** |

## 目前的证据链（全部为源码/编译层，无运行层）

| 项 | 结果 |
|---|---|
| 42 个原"无提供者"符号 | 全部有公开源码定义，且全部被 15 个 TU 覆盖后缺口归零 |
| RM 树抽样（17.7% 覆盖） | **175/175 编译通过** |
| 统一配置（-DNVRM 全量） | 9/9 编译、链接成功、缺口 0、93 条告警 |
| 三次失败尝试（C/C++/SPDM） | 全部归因于**构建配置**（语言选择、include 路径），非源码缺陷 |

## 仍未证明（与上表同等重要）

1. **链接自足**：统一产物仍有约 351 个 RM 内部符号无提供者 → 加载会失败；
2. **语义一致性**：-DNVRM 下的宏组合是否与发行版一致，未逐项核对；
3. **运行**：一次都没加载过；KEXT-LOAD / GPU-RUNTIME / 像素读回全部未执行；
4. **P0-1 / P0-4**：BLOCKED / OPEN，本轮未推进。

## 二十六、符号→文件索引（R73）

工具：	ools/index-definitions.py（单遍扫描、接受"同行 TYPE name(" 与"名字单独一行、括号在下一行"两种定义形态，
拒绝前面不是类型前缀的调用点）。

对统一产物里 760 个非系统未定义符号（去掉 IO*/OS*/kern_*/mach_* 后）：

| 指标 | 值 |
|---|---|
| 解析成功 | **216 / 760** |
| 未解析 | **544** |
| 出现定义的文件 | **79 个** |

## 两个必须注意的点

1. **79 个文件里混有 Linux 层**：kernel-open/nvidia-drm/…、
vidia-modeset-linux.c、uvm_*.c、
   linux_nvswitch.c、
vlink_linux.c 等。Darwin 构建**不应**用这些文件，它们正是"Linux 实现"。
   下一步必须先按 kernel-open/ vs src/nvidia/ 过滤，再谈批编译。
2. **544 个未解析**：单行/两行形态都覆盖不到，最可能是 __nvoc_* 这类**由宏/生成头提供的符号**，
   索引工具对这种形态无能为力。需要单独分析它们的来源（generated/ 头文件里的宏展开）。

## 结论

"把 RM 整层编进来"并不能简单等价于"编译 988 个 .c"：其中一部分符号由生成头/宏产生，
另一部分文件属于 Linux 专用层。这两类都要先分拣，否则批量编译的结果会被误读。

## 二十七、修正口径后的真实缺口画像（R73b）

上一轮把 760 个"非系统"符号当缺口，其中混进了 C++ 名字（_ZN…）与内核函数（PE_parse_boot_argn）。
用 classify-imports.py 只保留 ogkm-rm-core/ogkm-rm/ogkm-nvkms/
ullmoth-internal 后：

| 指标 | 值 |
|---|---|
| 真实缺口符号 | **346** |
| 已解析到定义文件 | **223** |
| 未解析 | **123** |
| 定义文件数 | **74** |
| 分层 | src/nvidia **45**、other（src/common 等）**29**、kernel-open **0** |

**注意 kernel-open 变成 0**：上一轮那 7 个 Linux 层文件全部是误报（它们定义的是同名但不同平台的函数，
或我的过滤没生效）。现在文件集合里没有 Linux 专用层，这对 Darwin 构建是好消息。

## 123 个未解析是什么

样本几乎全是宏生成族：

`
bitVectorClr_IMPL  bitVectorSet_IMPL  bitVectorOr_IMPL  bitVectorTest_IMPL
RmInitRm  CliSetGpuContext  PEX_DSM_GUID  RmPowerManagementTegra
`

*_IMPL 这类在 OGKM 里通常由 VALGRIND/NV_DEFINE_BITVECTOR 一类宏在 **.h** 中展开生成，
而我的索引只扫 .c。所以它们大概率不是"缺失"，而是**索引覆盖面不足**。

## 结论

- Darwin 相关的待编译文件集合是 **74 个**（45 个在 src/nvidia），不是一个上千 TU 的工程；
- 123 个未解析需要把索引扩展到头文件才能定性，现在不能算缺口。

## 下一步

把索引扩展到 .h（含宏定义行），重跑 346 个符号；若未解析降到接近 0，就可以按这 74 个文件做第一批受控编译。

## 二十八、索引扩展到"类型在上一行"的形态后：301/346（R74）

修 	ools/index-definitions.py：新增第三种定义形态——**类型在前一行、函数名单独成行**。
这解决了 itVectorClr_IMPL（src/nvidia/src/libraries/nvbitvector/nvbitvector.c:72）一类之前漏掉的定义。

| 指标 | R73 | **R74** |
|---|---|---|
| 解析 | 223 | **301** |
| 未解析 | 123 | **45** |
| 文件数 | 74 | **98** |

## 剩下 45 个的性质

样本：

`
RmInitRm  RmPowerManagementTegra  nvEvoGlobal  PEX_DSM_GUID  g_pSys  g_resServ
gpumgrGetGpuFromUuid  gpumgrQueryGpuDrainState  intrGetIntrEn_IMPL  kbusGetPciBarSize_IMPL
`

对 RmInitRm 做了全树、**不限扩展名**的检索：**没有任何定义**，只有 src/common/inc/rmosxfac.h:36
的 extern NvS32 RmInitRm(void);。

这说明它属于 **RM 的闭源部分**（
mosxfac = RM OS facility），公开树只给声明。

## 因此"缺口"现在是两段

| 段 | 数量 | 性质 |
|---|---|---|
| 有定义、需纳入构建 | 301 | 工程问题（98 个文件） |
| 只有声明、树内无定义 | **45** | **闭源依赖**，与 7.93 MB 不透明载荷同类 |

## 下一步

对 45 个逐个确认"树内只有声明"，产出一张**闭源符号清单**；然后按 98 个文件做第一批受控编译
（分批、记断点、每批固定上限）。若第一批通过，缺口就从"未知"变成"闭源 45 + 待编译若干"。

## 二十九、第一批受控编译：86/98（R75，run 39100887112）

按 
m-gap-index.json 里的 defining_files（已剔除 kernel-open/，共 98 个），逐个用探针配置编译：

| 指标 | 值 |
|---|---|
| 尝试 | 98 |
| 通过 | **86** |
| 失败 | **12** |

## 12 个失败分两类，都不是"代码不能用"

**① 6 个 softfloat 文件**：specialize.h 未找到。它实际在

`
src/common/softfloat/source/8086-SSE/specialize.h
`

—— 又是 include 路径缺失（和 softfloat.h、
vspdm_rmconfig.h 同类）。

**② src/common/src/nv_smg.c**：'pthread.h' file not found。

这个是**用户态库**（system management），依赖 POSIX 线程，本来就不属于 kext。它出现在清单里，
是因为索引把所有 .c 都算进去了。**应当从 kext 构建集合中排除**，而不是硬编。

## 结论

- 98 个文件里，**86 个可直接编成 Darwin 对象**；
- 12 个失败中，6 个是 include 路径（可修），6 个（softfloat 系列其余）同类；
- 
v_smg.c 类是**非 kext 代码**，需要按目录排除。

## 下一步

补 8086-SSE 的 include，重跑这批；同时在清单里排除用户态目录（如 src/common/src 里非 kernel 的部分），
再记录一次通过率。之后才谈"把 98 个对象连同 15 个探针对象一起链接"。

## 三十、批编译 90/97，链接仍因重复符号失败（R76）

| 指标 | R75 | **R76** |
|---|---|---|
| 批编译 | 86/98 | **90/97**（排除 src/common/src 后 97 个） |
| 失败 | 12 | **7** |
| 批量链接 | 未尝试 | **LINK_FAILED：duplicate symbol** |

### 7 个失败的具体原因（两条，同类）

1. 32_div.c:136: call to undeclared function 'softfloat_approxRecip32_1'
   —— 该函数定义在同目录的 s_approxRecip32_1.c，声明在 softfloat 的 primitives 头；
   单文件编译缺声明，属于**编译单元拆分问题**（需要把该头加入 include 或整组编译）。
2. 
vkms-headsurface-{ioctl,swapgroup}.c 与 
vkms-headsurface.c
   —— 
vidia-headsurface-types.h 找不到（它在 src/common/unix/nvidia-headsurface/，
   已加入 include，但**头内部还引用了别的相对路径头**，需要继续补）。

### 链接失败的原因是"重复符号"，不是缺符号

`
duplicate symbol '_nvKmsKapiAllocateVideoMemory'
duplicate symbol '_nvKmsKapiGetFunctionsTableInternal'
...
`

因为批编译清单里包含已经在探针里编过的同一批源文件（
vkms-kapi.c 等）。
我尝试用"对象名 stem 去重"修，但探针对象名是 probe-<路径下划线化>，与 at-<stem> 对不上，
所以**去重没有生效**（对象数仍是 105）。

### 正确的修法

按**源文件路径**去重，而不是按对象名：批编译前，先排除掉探针清单里已有的相对路径
（ogkm_probe 是静态列表，可直接做集合差）。

## 结论

- 批编译层面已到 90/97，剩余 7 个都是 include/单元拆分问题，**不是不可编译**；
- 链接阶段的失败是**我们自己的对象集合重复**，与缺符号无关；
- 这一轮没有取得"新产物未定义符号数"这个目标数字，原因已定位。

## 三十一、批链接成功，但未定义符号**变多**了（R77，run 39102081484）

修好路径去重后，批量链接首次成功：

| 指标 | 值 |
|---|---|
| 批编译 | 87/94 |
| 批量链接 | **LINKED**，102 个对象 |
| 未定义符号 | **1187** |

分类（classify-imports.py）：

| 类别 | 数量 |
|---|---|
| ogkm-rm-core | **667** |
| ogkm-os | 153 |
| 未归类（数据符号，如 _DSM_MXM_GUID） | 363 |
| mach/kern | 4 |

## 这是个关键的反直觉结果

加入 87 个"定义缺口符号的文件"后，**RM 内部未定义符号从 351 涨到 667**。

原因很直接：RM 是一个**稠密调用图**。每加入一个函数，它就引入若干新的被调用函数；
在只加入"98 个定义文件"的情况下，调用图的边界会持续外扩。

## 由此得到的判断

1. **增量收敛不成立**：不存在"再补 N 个文件就归零"的路径，除非把 RM 整层都编进来；
2. 这也解释了发行的 NVRM.kext 为什么会是 16.8 MB——它包含整个 RM；
3. 因此"链接自足性"的正确表述是：**要么整层纳入构建，要么承认这部分依赖闭源二进制**。

## 下一步（需要决策，而不是继续试）

两条路：
- **A**：整层编译（988 TU），量出完整未定义集合；工作量大但结论彻底；
- **B**：接受 RM 核心闭源，把 _Nv*/_Rm*/Cli* 一类当作外部依赖，转而验证"我们的 NVRM 层能否与该二进制对接"。

在没有明确选择前，继续按文件补只会让数字上下震荡，不会收敛。

## 三十二、整层构建的可行性测算（R78）

上一轮 run 39102081484 的实际耗时（GitHub API 读取）：

| 项 | 值 |
|---|---|
| job 
ative-objects | **3.6 分钟** |
| 该 job 内完成的编译 | 15 探针 + 175 抽样 + 94 批编译 = **284 个 TU** |
| 折算 | **≈ 0.63 秒/TU**（含链接与 nm） |

据此外推整层（988 TU）：

`
988 × 0.63 s ≈ 10.4 分钟 + 固定开销 ≈ 12–15 分钟
`

GitHub 单个 job 默认超时是 6 小时，因此**整层编译可以在一次运行内完成**，不需要分几十轮。

## 这条测算的意义

之前"整层要几周"的担心没有依据——按实测速率，它是一到两次 CI 运行的事。
真正的问题不是算力，而是**编译失败率**：175 抽样里 0 失败、94 批里 7 失败（都是 include/单元拆分）。

## 结论

选项 A（整层编译）在工程上可行，预计一次运行 12–15 分钟。
下一步就是实现它：编译 src/nvidia/src + src/nvidia/generated 下全部 .c，
统计通过/失败，并把通过的对象一起链接，量出**完整未定义集合**。

在此之前不再做增量补文件（上一轮已证明它不收敛）。

## 三十三、KC8 之后的实际 ABI 面：我们只用到 3 项（R80）

独立核对（kexts/ 下全部 .c/.cpp/.h，逐符号计数）：

| KC 符号 | 我们代码中的引用 |
|---|---|
| extendedConfigRead32 | **10** |
| extendedConfigWrite32 | **5** |
| IOACPIPlatformDevice | **9** |
| extendedConfigRead8 / Read16 | 0 |
| extendedConfigWrite8 / Write16 | 0 |

也就是说：KC8 里那 8 个符号，**当前候选代码只依赖其中 3 个**（read32、write32、ACPIPlatformDevice 的 metaClass 家族）。

## 这条事实的作用

1. 先前"8 项全都要拿到 C++ ABI 证据"的要求，对当前代码而言**只有 3 项是必需的**；
2. 其余 5 项（read8/read16/write8/write16）只在历史 IR 里出现过，当前树里没有调用点——
   它们不构成当前构建的 ABI 阻塞；
3. 这也解释了为什么 KC8 报告里 write8 未被观察到：**我们没调用它**。

## 与前序工作的关系

G1-KC-8（8/8 在 runner Boot KC 中定位到精确 Mach-O 符号、节角色、VM 地址与文件偏移）已由
run 39134085153 完成并记录于 KC8-20261018.md。本轮不重复该采集，只做"这对当前代码意味着什么"的收敛判断。

## 仍未解决

- IOPCIDevice::extendedConfigRead32/Write32 的**返回值宽度与调用约定**虽有 SDK IR 证据，但**未在实际加载时验证**；
- PM 关闭路径（P0-4）与初始化/渲染/读回/安全结束仍全部 NO-GO；
- 完整 C++ ABI 与最终用户系统差异未验证。

## 三十八、PM 关闭超时路径：补了 5 条结构契约（R85）

核对 kms_close_common（os-nvkms-xnu.cpp:132-166）的实际语义：

`cpp
if (!kms_pm_wait_locked(false, kKmsPmWaitMs)) {   // 30 s 有界等待
    popen->closing = true;
    popen->eventWanted = false;
    gKmsCloseDeferred++;
    if (gKmsPmState == kKmsPmLost) gKmsCloseDeferredLost++;
    IOLockUnlock(gKmsLock);
    kprintf("... close deferred ...");
    return;                       // 不调用 nvKmsClose，不释放 wrapper
}
`

即：**超时不是"关闭完成"**，而是"延迟关闭 + 资源保留 + 拒绝新工作"。这正是 R24 的设计。

	ools/check-pm-exclusion.py 之前只检查 commit 失败分支，**没有检查这条超时分支**。本轮新增 5 条：

| 检查 | 结果 |
|---|---|
| close 在接触 NVKMS 前必须先等 PM | PASS |
| 超时的 close 绝不调用 
vKmsClose | PASS |
| 超时的 close 不释放 wrapper | PASS |
| 超时的 close 拒绝新工作（closing = true） | PASS |
| 超时的 close 被计数 | PASS |

工具从 24 条增到 **29/29 PASS**。

## 这条测试的性质

这是**源码结构契约**，不是运行时测试：它证明"代码分支的写法满足不变式"，不证明 30 秒等待在真实
电源事件下真的能触发、也不证明延迟期间 NVKMS 不会访问已释放内存。后者必须实机。

## 三十九、延迟关闭没有"补完"路径：一个必须记录的开放问题（R86）

对 os-nvkms-xnu.cpp 全文件检索 gKmsCloseDeferred / closing：

- gKmsCloseDeferred++ 只出现在 kms_close_common 的超时分支（L145）；
- gKmsCloseDeferredLost++ 在其后（L146）；
- 两个计数器只被 
vkms_xnu_kms_close_deferred_count()（L303-306）**读出**，供 teardown 记录；
- **没有任何代码在 resume 之后重试这些关闭**，也没有释放被保留的 per-open / wrapper / event call。

也就是说：

> 一次超时的 close 会把 per-open、wrapper 与 event worker **永久保留**（直到 kext 卸载），
> 系统只能通过计数器"知道"发生过，无法回收。

## 这是不是缺陷？我的判断：**是开放性风险，不是已证实的 bug**

支持"可接受"的理由：
- 保留是为避免 NVKMS 仍持有指针时访问已释放内存（L136-141 的注释写明了这一点）；
- 每次超时只泄漏固定的少量对象，关闭次数受用户态打开次数约束。

不能判定"可接受"的理由：
- 没有上限检查，没有在 resume 后重试，也没有在 kext 卸载路径上回收；
- 
vkms_xnu_pm_close 的打开路径（L357-359）失败时返回 NV_FALSE 并**保留**两者，
  但调用方是否会重试，本轮未核实。

## 与目标第 (4) 项的关系

目标要求"freeDevice 关闭失败后的资源保留"必须明确。现状是：**保留是对的，但保留之后没有回收策略**。
这条已作为 OPEN QUESTION 记录，不写成"已关闭"。

## 下一步

先核实 
vkms_xnu_pm_close 的调用方（NVRM.cpp 的 teardown）在收到 NV_FALSE 后是否重试；
若没有，就把"延迟关闭的回收策略"列为需要在实机前解决的加载前风险。

## 四十、RM 门关闭被拒后的实际行为：记日志、继续睡眠（R87）

核实 NVRM.cpp 的唯一调用点（L1441-1447）：

`cpp
const int busy = nv_xnu_pm_close(10000);
if (busy) LOG("sleep #%u: %d RM call(s) still running after 10 s - suspending anyway", fPmCycles, busy);
NV_STATUS cst = rm_stop_user_channels(NULL, &fNv);
pciSaveForSleep();
NV_STATUS st = rm_power_management(NULL, &fNv, NV_PM_ACTION_STANDBY);
`

事实：

1. 
v_xnu_pm_close **每次睡眠只调用一次**，没有重试；
2. 失败（仍有 RM 调用在跑）时**只记一条日志，然后继续** 
m_stop_user_channels 与 STANDBY；
3. 注释本身就写着 "suspending anyway"。

## 这与 P0-1 的关系

这是 P0-1（XNU IOServicePM.cpp:4525 语义：负数返回值等同 implied ack、驱动无法拒绝睡眠）在代码层的直接后果：
既然拒绝不了睡眠，唯一负责的做法就是**记录"门没关干净"这一事实，然后尽力停**，而不是假装门关上了。

## 新增 3 条结构契约（工具 29 → **32/32 PASS**）

| 检查 | 结果 |
|---|---|
| RM 门关闭每次睡眠只尝试一次 | PASS |
| 门忙时必须有日志、不得静默 | PASS |
| 门忙时不得中止睡眠（因为中止也无效） | PASS |

## 仍未解决（与 R86 合并）

- **延迟的 KMS close 永不补完**：per-open/wrapper 保留到卸载；
- **RM 门未关干净也照样 STANDBY**：这会让"standby 期间无 RM 调用"成为**尽力保证**而非强制保证；
- 两者都是加载前风险，应进验收矩阵的 BLOCKED 项，而不是留在注释与日志里。

