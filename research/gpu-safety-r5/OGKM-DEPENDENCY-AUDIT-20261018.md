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
