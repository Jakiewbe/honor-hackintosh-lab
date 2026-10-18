# 42 个无提供者导入：最终更正（R50）

## 结论先行

用**窗口匹配**（要求 `name (...)` 后接 `{`）在固定 OGKM 提交 `e4a5faa` 上重新检索 **3821 个源文件**：

> **35/35 被测符号都有函数定义，missing: none。**

覆盖 23 个 `_rm_*`、4 个 `nvKmsKapi*`、8 个 `nvKms*`。加上本站树里的 7 个 `_nvrm_*`，
**42 个导入全部已有候选源码提供者**。

证据文件：`research/gpu-safety-r5/symbol-definitions.json`，工具：`tools/find-symbol-defs.py`。

## 我连续三次错在哪

| 轮次 | 错误 | 症状 |
|---|---|---|
| R48 | 路径 glob `src\nvidia\**\*.c` | **PowerShell 不支持 `**` 递归**，`arch/nvalloc/unix/src/` 从未被扫 |
| R49 | 改用 `-Recurse` 但 `Select-Object -First 1` | `nv.h` 的**声明**字母序在前，定义被丢弃 |
| R49 | 正则假设 `TYPE name(` 同行 | 真实定义常写成 `TYPE name` 换行 `(`，**跨行漏检** |

三次都不是"源码没有"，而是**检索方法没有覆盖定义的真实形态**。这次的窗口匹配同时解决三点：
按符号取 600 字符窗口、允许换行、用 `后接 {` 区分定义与声明。

## 更正后的分类表

| 家族 | 数量 | 定义位置 | 缺口性质 |
|---|---|---|---|
| `_rm_*` | 23 | `arch/nvalloc/unix/src/osapi.c`（20）、`dynamic-power.c`（1）、`unix_intr.c`（2） | **构建闭包** |
| `_nvKmsKapi*` | 4 | `src/nvidia-modeset/kapi/src/nvkms-kapi.c:3827/3946/3978/4122` | **构建闭包** |
| `_nvKms*` | 8 | `src/nvidia-modeset/src/nvkms.c`（含 `nvKmsModuleLoad` 在 `kernel-open/…/nvidia-modeset-linux.c:2150`） | **构建闭包** |
| `_nvrm_*` | 7 | 本仓库 `kexts/NVRM/nvrm_pageoff.c` | 门禁配方（三次失败） |

**没有任何一项可以再被称为"结构性源码缺失"。** 我此前把 4 个 `nvKmsKapi*` 判为结构性，是错的。

## 这并不等于可加载

"有定义"只消除"找不到源码"。仍未验证：

1. 这些翻译单元能否在 Darwin 工具链下编译（`arch/nvalloc/unix/src/` 是 Linux/Unix 适配层）；
2. `NV_ENTER_RM_RUNTIME` 在 `__use_altstack__` 下会改 `%rbp`，而本站存在传 `NULL` 栈的 RM 调用——ABI 风险；
3. PM/关闭安全（P0-1/P0-4）未关闭；
4. 真实 RTX 2050 初始化、离屏、读回未开始。

**KEXT-LOAD 维持 NO-GO。**

## 下一单元

按逐符号的依赖审计推进：对 35 个已定位定义，各列出所在编译单元、直接依赖的 Linux/Unix 设施、
本站已有的 Darwin 对应实现。用 `tools/find-symbol-defs.py` 产出机器可核对的表，不再靠人工首个命中。
