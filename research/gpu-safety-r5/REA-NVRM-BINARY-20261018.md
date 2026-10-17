# REA：发行版 NVRM.kext 逆向取证（2026-10-18）

**方法**：Mach-O 结构解析 + 段/节熵分析 + 符号族统计 + 内嵌容器解压。
**没有**反编译、**没有**执行任何代码。REA MCP 引擎（Ghidra/IDA）在本会话不可用，故走"结构级逆向"路线；
本报告只回答**组成与来源**问题，不回答任何函数行为。

目标产物：`release-v2.3.3.tar.gz` 内 `NVRM.kext/Contents/MacOS/NVRM`（16,787,920 B，
UUID `bee3d9da52963211aea72739054a65f4`）。对照：`NVRMFB.kext`（306,736 B，UUID `a3b59a1e…`）。

## 1. 观察（可复核，附偏移/大小）

### 1.1 段与节

| 节 | 大小 | 熵 | 说明 |
|---|---|---|---|
| `__TEXT,__text` | 4,757,867 | 6.33 | 真实代码 |
| `__TEXT,__cstring` | 896,112 | 5.59 | 字符串 |
| `__TEXT,__const` | **8,500,128** | **7.98** | 混合：压缩流 + 表 + 不透明大块 |
| `__DATA,__const` | 340,448 | 3.28 | 表 |
| `__DATA,__bss` | 952,736 | — | 未初始化 |

符号表：**17,679 个 defined external**；按作用域：`__text` 30,170、`__const` 1,318、其它 2,342。
构建信息：只有 `LC_UUID`，**没有 `LC_BUILD_VERSION`/`LC_VERSION_MIN_MACOSX`**，`LC_SOURCE_VERSION = 0`。

### 1.2 `__const` 里有什么

1. **5 个 XZ 流**，偏移 `0 / 17504 / 34112 / 53360 / 70352`，各自解压后
   **244,480 / 253,184 / 252,288 / 244,224 / 247,296 字节**，头部形如 `81040X02…`。
   5 份、尺寸相近、结构一致 → 与 `nvkms_shaders.cpp`（5 组着色器表）相符。
2. **EDID/模式名表**：可读字符串 `CEA-861B:#0`(×68)、`VESA Established`(×58)、`VESA DMT/RB`(×26)。
3. **约 7.93 MB 不透明块**：偏移 `407680..8337536`，256 种字节值近似均匀分布
   （计数 30,145..73,395），无容器 magic（gzip/zstd/xz/zip/ELF/NVFW 全部只是随机误命中），无任何 ≥10 字符可读串。

### 1.3 代码组成

| 符号族 | 数量 | 含义 |
|---|---|---|
| `nvKmsKapi*` | **31** | OGKM 的 NVKMS-KAPI 层**被编进了 NVRM**（`_nvKmsKapiAllocateDevice` 等） |
| `nv_xnu*` | 40 | NullMoth 的 macOS OS 层（与我们补丁的代码同族） |
| `NVRM*` | 110 | kext 主体 |
| `gsp`/`Gsp` | 214/118 | GSP 相关 |
| `rm_`/`Rm` | 146/1133 | RM 层 |

对照我们自己的构建（R13）：`candidate-NVRM` 对象 **0** 个 `nvKmsKapi*` 符号，`os-nvkms-xnu` 对象 68 个
`nvkms_*` OS 层符号。差距不在"我们少写了代码"，而在"我们没编译 OGKM 的 NVKMS 源"。

## 2. 推断（明确标注为推断）

1. 7.93 MB 均匀高熵块**最可能是加密/混淆后的固件或微码**（GSP/FSP 一类）。理由：整段无结构、无 magic、
   无字符串、字节分布近似均匀——这是加密数据的典型特征，而不是压缩数据（压缩流通常能被识别容器头）。
2. 5 个 XZ 流与 `nvkms_shaders.cpp` 的 5 组表对应，但**未逐字节比对**，只是尺寸与数量吻合。
3. NVRM.kext = NullMoth 的 macOS 层（我们的 TU 同族）+ OGKM NVKMS/KAPI + 固件数据。
   这解释 R13 的 2%：缺的不是"几个源文件"，而是 **NVKMS 全量 + 一个 7.93 MB 我们无法生成的载荷**。

## 3. 未知（不做假设）

- 7.93 MB 的**具体身份**（GSP？FSP？RM 微码？）未证实——需要能解密/识别该格式，或拿到上游构建脚本。
- 该载荷是否与 GPU 型号相关、是否覆盖 `25A9`，未知。
- 5 个 XZ 流是否与我们源码里的 shader 表逐字节一致，未验证。
- 二进制是否由公开 commit 构建，未证实：没有 `LC_BUILD_VERSION`，`LC_SOURCE_VERSION=0`，唯一可对的是 UUID。

## 4. 对"缺口"的结论

- **不能靠公开源码重建 NVRM.kext**：即使把 OGKM `nvidia-modeset` 全部编进来补上 `nvKmsKapi*`，
  那 7.93 MB 不透明载荷仍然无法从源码生成。
- 因此"自建 NVRM"这条路在可预见范围内是**关闭**的；要用 NVRM 就必须接受上游预编译件。
- 这与 `FEASIBILITY-STOPLOSS-20261018.md` 的判断一致，但依据更硬：不是"我们没找齐文件"，
  而是"文件里有一段我们无法生成的固件数据"。

## 5. 可继续的下一步（若还想推进）

1. 用同一方法分析 `NVRMFB.kext`（已做基础结构：306,736 B / 169 符号，`__DATA,__data` 100 KB 熵 0.06）
   —— 它是我们**能**构建的那个，做逐节比对更有意义。
2. 只针对 `__TEXT,__text` 做 Ghidra 反编译（需要引擎），回答"R9/R10 的拆除语义在发行版里原本是怎么写的"。
   这需要在有 Ghidra 的机器上跑 REA，当前会话没有该 provider。
3. 把 7.93 MB 载荷的哈希登记为"已知 opaque 资产"，将来若上游发布构建脚本可直接比对。

## 6. 证据文件

`D:\Hactk\gpu-r5-20261017\evidence\rea\`：`macho-structure.json`、`const-and-nvkms.json`、
`const-streams.json`、`const-profile.json`、`firmware-blob.json`。
