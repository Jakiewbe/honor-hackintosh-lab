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
