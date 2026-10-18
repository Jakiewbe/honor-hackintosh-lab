# G1 R80：符号身份、九项来源与对象取证（2026-10-18）

## 结论与目标距离

R79 的九项函数索引 UNKNOWN 均已有公开来源候选：六项数据定义候选、一项函数定义候选、一项宏数据定义候选、一项构建生成配方。此结论不等于九项 Darwin 对象提供者已经观察到，也不等于完整 NVRM 可以构建或加载。完整构建、ABI、初始化、真实 GPU 渲染、像素读回、错误传播与安全结束仍未验收；P0-1/P0-4 保持 BLOCKED/OPEN，设备 NO-GO。

本轮父基线为 main `4dcd1554e08209d2e0a02cc71e04832f4f7efb9d`。固定 OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`、NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393` 未变。本轮只修改证据工具和既有原生门禁，没有修改驱动行为或扩大批链接源文件集合。

## 修正的具体问题

旧 `classify-imports.py` 用 `lstrip("_")` 删除全部前导下划线，破坏了真正的 C 名称。例如 Mach-O `___nvoc_dynamicCast` 对应 C `__nvoc_dynamicCast`，而不是 `nvoc_dynamicCast`。名称分类只能作为启发式，不能证明符号由内核或某个 TU 提供。

新工具保留 `macho_symbol`、精确 `source_spelling` 和名称种类，转换只去掉一个 Mach-O ABI 下划线。Itanium C++ 名称保留 `_Z`。同时更正旧工具的使用说明：未定义输入来自 `nm -u`；`nm -gU` 用来列外部定义。包装日志必须有对应的 `ARGV` 和最终 `EXIT=0`，未知行、编译产物定义行、失败或截断日志直接拒绝，不静默丢弃。JSON 保留全部记录和全部未分类名称。

## 九项来源候选

| 精确 C 名称 | 固定源码位置 | 证据性质 |
|---|---|---|
| `PEX_DSM_GUID` | `src/nvidia/src/kernel/platform/guids.c:81` | `GUID_CONST` 调用；宏体在同文件35行，展开为 const 数据定义 |
| `g_pSys` | `src/nvidia/src/kernel/core/system.c:74` | 有初值的数据定义 |
| `g_resServ` | `src/nvidia/src/kernel/rmapi/rmapi.c:55` | C tentative definition；不是 extern 声明 |
| `nvEvoGlobal` | `src/nvidia-modeset/src/nvkms-evo.c:148` | 有初值的数据定义 |
| `__nvoc_class_def_Memory` | `src/nvidia/generated/g_mem_nvoc.c:84` | const 数据定义候选 |
| `__nvoc_class_def_RmResource` | `src/nvidia/generated/g_resource_nvoc.c:177` | const 数据定义候选 |
| `__nvoc_dynamicCast` | `src/nvidia/src/libraries/nvoc/src/runtime.c:282` | 函数定义候选 |
| `__nvoc_rtti_provider` | `src/nvidia/src/libraries/nvoc/src/runtime.c:46` | const 数据定义 |
| `pNV_KMS_ID` | `src/nvidia-modeset/Makefile:248`；`utils.mk:555–567` | 前者调用 `GENERATE_NVIDSTRING`，后者生成 `g_nvid_string.c`，包含指向 `NV_KMS_ID + 11` 的 const 指针；本轮未生成/编译该 TU |

详细锚点、原文片段和文件 SHA256 见 [rm-special-sources.json](rm-special-sources.json)。工具在3836个 tracked C/C++/头文件/Makefile/.mk 的明确范围中保留全部原始 token 命中和文件哈希，完整正文在 CI 生成并作为文本诊断上传。原始文本命中包含注释和未激活分支，本身不当作定义证明。小摘要的完整证据规范 JSON SHA256 为 `435abbedf04591c7cbc13883c35ff037c1a71c2d9580df3aa0bb55fe63a82a92`。

九个精确 Mach-O 名称来自旧 run [39102081484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39102081484) 的统一链接 `nm -u`，全部是旧829名称清单的成员；输入、成员哈希及原 artifact API digest 登记在 [r80-evidence/input-binding.json](r80-evidence/input-binding.json)。这只是旧输入绑定，不是 R80 原生运行结果。R79 的346个历史输入、337/9词法结果和旧摘要保持原样，不将新解释倒填为过去的对象证据。

## 下一次原生门禁增加的真实观测

现有 R79 批集合已含 `system.c`、`rmapi.c`、`nvkms-evo.c` 和 NVOC `runtime.c`；还不含 `guids.c`、`g_mem_nvoc.c`、`g_resource_nvoc.c` 或生成的标识 TU。本轮不靠新增空定义消掉这些导入。

新 `g1_special_object_providers.py` 只读取本轮 `build_manifest`，不 glob 旧对象，也不编译或执行驱动。对已成功编译的候选源核对固定源码哈希、对象路径、对象哈希及 x86_64 MH_OBJECT，再用 `xcrun nm -gU` 检查精确 Mach-O 名称。报告区分 `NOT_BUILT`、`COMPILE_FAILED`、`COMPILED_WITHOUT_TARGET_EXPORT` 与 `OBJECT_PROVIDER_OBSERVED`；标识生成项保持 recipe-only。该报告观察选定提供者，不是完整闭包门禁。

既有工作流还会重新生成九项来源证据、比较已提交摘要，并对本轮统一链接生成完整符号身份 JSON。所有17个工作流仍只有 `workflow_dispatch`。对象只在 runner 内用于编译/链接取证，发布仍经过文本白名单，不上传驱动二进制。

## 实际验证与限制

- 工具测试47/47通过，其中本轮新增20项；含精确下划线、extern/定义、注释伪锚点、失败/截断 nm、源/对象哈希不符、对象越界、共享对象缓存及 nm 失败反例。
- 历史回归 WP1 10/10、FBClaim 5/5、B2 7/7；Python语法和17工作流手动触发检查通过。
- 对固定源码完整重扫两次，摘要及规范摘要哈希一致；九个名称全部存在于旧829名称输入。
- 测试中的人工 Mach-O 头只验证工具拒绝/解析逻辑，不是编译证据。未运行新 Darwin 对象观测、链接或六TU ABI；不能称为原生通过。

本轮复盘：函数索引的 UNKNOWN 必须继续区分数据、宏、构建生成和精确符号拼写。源码存在与实际对象导出必须分别取证；类别数量与绿色 report-only 步骤不能代替闭包验收。

## 当前断点

R79/R80 新原生工作流尚未触发。本机 credential helper 不可用、GitHub 连接器没有 dispatch 工具、浏览器自动化初始化失败；另尝试 DevSpace 接口也返回内部错误。用户授权已有，不重复申请权限，也不用旧提交的 rerun 冒充新 head。

可用手动入口：[gpu-safety-r5-native.yml](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/workflows/gpu-safety-r5-native.yml)，main / Xcode_16.4。拿到新 head 的结果后，先核对完整源码摘要与 `special-object-providers/report.json`，再读 `native-report.json` 同基线导入变化和 `rm-abi/rm-abi-report.json`。按首个真实失败修复；若已有对象证据支持，再单独设计三项遗漏源和官方标识生成 TU 的候选扩展。完整目标未完成，设备继续 NO-GO。
