# 27 项导出：加载器导出元数据定向取证（2026-10-21）

问题：27 个 local-only 名称是否有**外部导出**证据，能由"加载器实际消费的导出/链接元数据"给出？

结论：**在可合法取得的输入里，没有这类元数据；27 项保持 UNKNOWN。**

## 1. 输入与方法

- 输入：`/System/Library/KernelCollections/SystemKernelExtensions.kc`，
  SHA256 `12913116a90b3875e42f17ab42261875205e3cd5463fb7744b1a488b24df67c2`（365887488 B，macOS 15.7.9）。
- 方法：解析 fileset 成员 `com.apple.iokit.IOAcceleratorFamily2`（fileoff 344207360）的 load commands，
  找 `LC_DYLD_EXPORTS_TRIE`（0x80000033）与 `LC_DYLD_INFO(_ONLY)`（0x22/0x80000022），
  有则解析导出 trie 并逐个查 27 个名字。
- 工具：`tools/g1_kc_exports.py`，工作流 `.github/workflows/g1-kc-exports.yml`（只读，workflow_dispatch）。

## 2. 先证明解析器不是坏的（正/负对照）

在本 run 里现编一个 dylib：

```c
int g1_export_probe(void) { return 7; }
```

对它跑同一解析器：

| 项 | 值 |
|---|---|
| verdict | `EXPORT_TRIE_PRESENT` |
| trie 名称数 | 1 |
| 样本 | `["_g1_export_probe"]` |
| 必须命中 | `g1_export_probe` → **True** |
| 必须缺席 | `g1_definitely_absent_symbol` → **False** |

对照成立，说明"找不到"不是解析器 bug。（中间踩过两个坑并修正：trie 的边是 NUL 结尾字符串而不是长度前缀；
符号名带不带下划线都要接受。）

## 3. 目标成员的结果

| 项 | 值 |
|---|---|
| load commands | `0x2`(SYMTAB) `0xb` `0x19`(SEGMENT_64) `0x1b`(UUID) `0x2a` `0x80000034`(CHAINED_FIXUPS) |
| `LC_DYLD_EXPORTS_TRIE` | **不存在** |
| `LC_DYLD_INFO(_ONLY)` | **不存在** |
| 成员内 `__LINKINFO/__symbolsets` 等节 | **不存在**（符号集在内核里，不在 kext 成员里） |
| verdict | `EXPORT_TRIE_ABSENT_NOT_OBSERVABLE` |
| 27 项命中导出 | **0 / 27** |

## 4. 这说明了什么、没说明什么

说明：

- 内核集合里的 kext 成员**不带 dyld 导出 trie**；它们靠 `LC_SYMTAB` + chained fixups，
  由 `kmutil` 在**构建集合时**静态解析。
- 因此对这批名字，"外部导出"不是随包发布的元数据；在只有 KC 文本输入的前提下，
  无法证明也无法否证它们可被外部链接。

没说明：

- 不等于这些函数不存在（vtable 槽位 322-325 等已证明函数在）；
- 不等于加载一定失败；
- 不等于可以用局部 nlist 或槽位命中替代导出证明。

## 5. 若还要继续，只有三类输入能推进

| 输入 | 可得性 | 能回答什么 |
|---|---|---|
| Apple 构建期导出清单（IOPCIFamily/IOACPIFamily 那样的 `.exports` 文件） | IOGraphicsFamily/IOAcceleratorFamily2 在磁盘上没有对应文件；KC 里也没有 | 直接给出导出名单 |
| `kmutil install` 的真实解析结果 | **设备步骤**，当前 B 暂停 | 安装期是否解析成功 |
| 发行版二进制自身的导入表 | 需要下载发行包，**禁止** | 发行版是否也导入这些名字 |

在上述任一输入到手之前，这 27 项保持 `LOCAL_DEFINITION_OBSERVED_EXPORT_UNVERIFIED`，
状态字符串继续带 `LOCAL_ONLY_EXPORTS_UNVERIFIED`。

## 6. 证据

`evidence/39617435532/`：`export-probe.json`、`dylib-export-control.json`、`requested-names.json`、
`collection-sha256.txt`、`sw_vers.txt`，以及记录成员哈希的 `archive-binding.json`。
