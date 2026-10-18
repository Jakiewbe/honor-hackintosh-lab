# 决策页：整层构建 vs 接受闭源（2026-10-18，R89）

## 结论先行

**"接受 RM 闭源并链接它"这条路不存在。** RM 核心与 NVKMS 是**静态链接进 `NVRM.kext` 的**，
发行包不提供任何可链接的 RM 库；kext 也不能像 dylib 那样互相解析符号。

因此只剩两条真实路径：

| 路径 | 含义 |
|---|---|
| **A. 整层源码构建** | 把 `src/nvidia/src` + `src/nvidia/generated` 的 988 个 TU 纳入构建，产出自己的 NVRM |
| **C. 继续使用上游二进制** | 放弃"可复现构建"，只做加载与行为验证（且验的是上游预编译件） |

---

## 一、证据：RM 是静态链接的

对发行版 `NVRM`（16,787,920 B）解析 Mach-O 符号表：

| 指标 | 值 |
|---|---|
| 符号总数 | 34,302 |
| 已定义 | **33,830** |
| 未定义（导入） | 472 |

在其中查找我们此前统计为"缺口"的符号：

| 符号 | 状态 |
|---|---|
| `_RmInitRm` | **DEFINED** |
| `_Nv04AllocContextDmaKernel` | **DEFINED** |
| `_nvKmsOpen` | **DEFINED** |
| `_CliSetGpuContext` | **DEFINED** |

也就是说：**RM 核心、NVKMS、KAPI 全部被编进了 NVRM.kext 本体**，不是外部依赖。

---

## 二、路径 A 的代价（已实测）

| 项 | 数值 | 来源 |
|---|---|---|
| TU 数 | 988（720 `src` + 268 `generated`） | 目录统计 |
| 单 TU 编译耗时 | **0.63 秒** | run 39102081484 实测（284 TU / 3.6 min） |
| 整层预计 | **12–15 分钟/次** | 外推 |
| 抽样失败率 | 175/175 通过；批编译 87/94（失败全是 include/单元拆分） | R71、R77 |
| 已知闭源声明 | 45 个符号只有 `extern` 声明（`RmInitRm` 等） | R74 |

**但注意**：这 45 个"只有声明"的符号，在发行版二进制里是**有定义的**。
所以要么它们在源码树里以我索引没覆盖的形态存在（宏/表格/多行声明），要么确实缺失。
这一点未查清之前，不能断言"A 只能做到 943/988"。

## 三、路径 A 的收益

- 得到**完整未定义集合**（这是"能否加载"的唯一判据）；
- 消除"发行版 7.93 MB 不透明载荷"的不可审计性；
- 后续任何 ABI/行为问题都能对着自己的源码查。

## 四、路径 A 的风险

- RM 是稠密调用图，**增量不收敛**（R77 实测：加 87 个文件后未定义从 351 涨到 667）；
- 整层编译后仍可能因 45 个符号而无法闭合；
- 编译通过了也不等于语义正确（`-DNVRM` 宏组合未与上游逐项核对）。

---

## 五、建议

先做**一步小实验**再决定：把 45 个"只有声明"的符号，逐个在源码树里做**不限扩展名、不限形态**的检索。
如果它们其实都在（只是索引漏了），路径 A 的闭合前景就明确，值得投入整层构建；
如果确实缺失，就先解决"这 45 个从哪来"，再谈整层。

这一步不需要 CI、不需要实机、不改变任何代码。

## 四十一、45 个"只有声明"符号的树内形态（R90）

### 检索方法

- 对 OGKM 全树 3836 个文本文件（任意扩展名）搜这些名字：**639 处命中**；
- 再用"定义形态"正则（^\s*TYPE name(）过滤：**17 处**，且**全部是头文件里的声明**（以 ; 结尾），
  没有一处是函数体。

样本：

`
src/common/inc/rmosxfac.h          extern NvS32 RmInitRm(void);
src/nvidia/.../osapi.h             NV_STATUS RmPowerManagementTegra(OBJGPU *, nv_pm_action_t);
src/nvidia/generated/g_gpu_nvoc.h  NV_STATUS gpuEnterStandby_IMPL(struct OBJGPU *pGpu);
src/nvidia/generated/g_intr_nvoc.h NvU32 intrGetIntrMaskFlags_IMPL(struct Intr *pIntr);
`

### 关键发现：*_IMPL 是 NVOC 生成的，而生成源不在树里

- 树内 .nvoc 文件数：**0**（没有任何 NVOC 类定义源）；
- generated/*.c 里确实存在 _IMPL **定义** 1261 处 —— 说明部分类的生成结果随树发布；
- 但 RmInitRm 这类**不在** generated/*.c 里，只有 mosxfac.h 的声明，
  而发行版二进制里它是 **DEFINED**。

### 因此结论分两类

| 类 | 例子 | 树内状态 | 发行版状态 |
|---|---|---|---|
| A. 生成结果随树发布 | 多数 *_IMPL（1261 处定义） | ✅ 有定义 | DEFINED |
| B. 生成源不在树里 | RmInitRm、RmPowerManagementTegra、部分 gpumgr* | ❌ 只有声明 | **DEFINED** |

B 类是我们**无法从公开源码闭合**的部分：不是"我没找到"，而是树里确实没有 .nvoc 生成源，
也没有它们的生成结果。

### 这修正了上一轮决策页的一个前提

决策页写"45 个若都在，A 值得投入；若确实缺，先解决来源"。现在答案是**两者都有**：
一部分（生成结果随树发布的）在，另一部分（B 类）确实只有声明。

所以路径 A 的**上限不是 988/988**，而是"988 减去 B 类"。B 类具体多少个，需要把 45 个逐个归类后才能给出，本轮尚未逐个核完。

## 四十二、剩余符号最终归类：5 个真缺、4 个连发行版都没有（R91）

m-gap-index.json 当前的 missing 是 **9 个数据符号**（不是 45——45 是 R74 之前的旧数字，函数类的已被补上）。
逐个核对"树内定义"与"发行版二进制定义"：

| 符号 | 树内定义 | 发行版 NVRM |
|---|---|---|
| PEX_DSM_GUID | ❌ 仅引用 | **DEFINED** |
| g_pSys | ❌ 仅引用 | **DEFINED** |
| g_resServ | ❌ 仅引用 | **DEFINED** |
| 
vEvoGlobal | ⚠️ 1 处疑似定义 | **DEFINED** |
| pNV_KMS_ID | ❌ 仅引用 | **DEFINED** |
| 
voc_class_def_Memory | ❌ 零命中 | **absent** |
| 
voc_class_def_RmResource | ❌ 零命中 | **absent** |
| 
voc_dynamicCast | ❌ 零命中 | **absent** |
| 
voc_rtti_provider | ❌ 零命中 | **absent** |

## 分成两类，意义完全不同

**B 类（5 个）：源码里确实没有，但发行版有定义**
→ 这是真正的"公开源码无法闭合"部分。它们只能来自 NVIDIA 未随树发布的源（NVOC 运行时代码 / mosxfac）。

**C 类（4 个 
voc_*）：源码没有、发行版也没有**
→ 说明**发行版不需要它们**，是我们的构建多引用了。
这类不是缺口，而是**构建配置差异**（很可能是 NVOC 的 RTTI/动态转换路径，在上游构建里被裁掉）。

## 这给出了路径 A 的准确上限

> 从公开源码可闭合的部分 = 988 − 5（B 类）= **983 个 TU**
> 剩下 4 个 
voc_* 需要**查明是谁引用的**，而不是补实现。

这比上一轮"988 减 B 类"更精确：B 类是 5，且 C 类不该算进损失。

## 四十三、更正 R91 的 C 类结论：4 个 
voc_* **在树里都有定义**（R92）

R91 我写"
voc_* 源码零命中、发行版也没有"。**树内零命中这一半是错的**——那是我的索引漏了，
不是代码缺失。逐个核实：

| 符号 | 树内定义位置 |
|---|---|
| __nvoc_class_def_Memory | src/nvidia/generated/g_mem_nvoc.c:84 |
| __nvoc_class_def_RmResource | src/nvidia/generated/g_resource_nvoc.c:177 |
| __nvoc_rtti_provider | src/nvidia/src/libraries/nvoc/src/runtime.c:46 |
| __nvoc_dynamicCast | NVOC 运行时 untime.c（dynamicCast 的实现族，见 L62/166/235/281） |

也就是说 **NVOC 运行时源码随树发布**（src/nvidia/src/libraries/nvoc/src/runtime.c），
两个类描述符也在 generated/*.c 里。索引漏报的原因：这些定义不符合我索引的三种函数形态
（它们是变量定义或宏展开）。

## 因此 C 类不存在

原来的 9 个"未解析"里：

- **5 个数据符号**（PEX_DSM_GUID/g_pSys/g_resServ/
vEvoGlobal/pNV_KMS_ID）——
  树内确实只有引用，发行版有定义 → **真正的源码缺口**；
- **4 个 
voc_*** —— **树内有定义**，属于索引漏报 → 不是缺口。

## 修正后的路径 A 上限

> 从公开源码可闭合 = 988 − 5 = **983 个 TU**，且那 5 个是数据符号（全局表/状态对象），
> 不是函数逻辑。它们的替代（初始化代码）可能需要我们自己在 Darwin 层提供。

## 教训

这是本项目第 N 次同类错误：**"检索零命中"不等于"不存在"**。
我的索引只认三种函数形态，对变量定义与宏展开无能力。这一步应当写成工具约束，
而不是每次靠人肉再查一遍。

## 四十四、数据符号索引器：9 个中 5 个有树内定义（R93）

新增 	ools/index-data-defs.py（与函数索引分离，避免再混淆）：识别
TYPE name = / TYPE name[ 形态（排除 extern）与 #define name，并做**前导下划线归一化**
（__nvoc_class_def_Memory 这类符号在源码里比 Mach-O 名多一个下划线）。

运行结果（3824 文件）：

| 符号 | 树内定义 |
|---|---|
| g_pSys | ✅ src/nvidia/src/kernel/core/system.c:74 |
| 
vEvoGlobal | ✅ src/nvidia-modeset/src/nvkms-evo.c:148 |
| __nvoc_class_def_Memory | ✅ src/nvidia/generated/g_mem_nvoc.c:84 |
| __nvoc_class_def_RmResource | ✅ src/nvidia/generated/g_resource_nvoc.c:177 |
| __nvoc_rtti_provider | ✅ src/nvidia/src/libraries/nvoc/src/runtime.c:46 |
| PEX_DSM_GUID | ❌ |
| g_resServ | ❌ |
| pNV_KMS_ID | ❌ |
| __nvoc_dynamicCast | ❌ |

## 对 R92 的再次更正

R92 我写"4 个 
voc_* 都有定义"，其中 __nvoc_dynamicCast 那一行是**推断**（"runtime.c 里的 dynamicCast 实现族"），
不是核实过的定义。本轮工具查证：**3 个确认有定义，__nvoc_dynamicCast 仍未解析**。
我不该把推断写成表格里的一行。

## 剩余 4 个的性质（初步，未定论）

| 符号 | 线索 | 性质猜测 |
|---|---|---|
| pNV_KMS_ID | 
kms.c:5369 是 extern const char *const，值是版本文本串 | **构建期生成**（版本号），源码本就没有 |
| PEX_DSM_GUID | 用法 &PEX_DSM_GUID，ACPI DSM GUID 常量 | 可能在 Linux 专有 os_acpi.c 里 → **平台缺口**，可自备 |
| g_resServ | osapi.c 里 &g_resServ 传给 serverAcquireClient | 需再定位（可能结构体成员或另一 TU） |
| __nvoc_dynamicCast | 只见调用 __nvoc_dynamicCast(...)，未见定义 | 可能是 header 内联/宏，需扫头文件 |

以上四条都**尚未核实**，不得据此下"缺失"结论。

## 四十五、9 个符号全部核实完毕：**只有 1 个是构建期生成，没有源码缺口**（R94）

逐个核实结果（每条都有行号）：

| 符号 | 结论 | 位置 |
|---|---|---|
| g_pSys | ✅ 定义 | src/nvidia/src/kernel/core/system.c:74 |
| 
vEvoGlobal | ✅ 定义 | src/nvidia-modeset/src/nvkms-evo.c:148 |
| __nvoc_class_def_Memory | ✅ 定义 | src/nvidia/generated/g_mem_nvoc.c:84 |
| __nvoc_class_def_RmResource | ✅ 定义 | src/nvidia/generated/g_resource_nvoc.c:177 |
| __nvoc_rtti_provider | ✅ 定义 | src/nvidia/src/libraries/nvoc/src/runtime.c:46 |
| __nvoc_dynamicCast | ✅ 定义 | src/nvidia/src/libraries/nvoc/src/runtime.c:282 |
| g_resServ | ✅ 定义（无初值的暂定定义） | src/nvidia/src/kernel/rmapi/rmapi.c:55 |
| PEX_DSM_GUID | ✅ 宏生成的定义 | src/nvidia/src/kernel/platform/guids.c:81（GUID_CONST(...)） |
| pNV_KMS_ID | ⚙️ **构建期生成** | src/nvidia-modeset/Makefile:247-250（GENERATE_NVIDSTRING） |

## 三条被我的工具漏掉的原因（都是工具缺陷，不是源码缺失）

1. **无初值的暂定定义**：RsServer g_resServ; —— 我把它当"声明"排除了；
2. **宏生成的定义**：GUID_CONST(PEX_DSM_GUID, ...) —— 名字后面不是 =；
3. **构建期生成**：pNV_KMS_ID 由 Makefile 的 GENERATE_NVIDSTRING 产出，源码本就没有。

## 这修正了 R91 的核心结论

我之前说"5 个数据符号是真正的源码缺口"。**这个结论是错的**：其中 4 个树内有定义，
第 5 个（pNV_KMS_ID）是**构建步骤**产物，不是缺失。

因此：

> **从公开源码构建 NVRM 不存在"符号缺口"。** 988 个 TU 全部有源码；
> 唯一缺的是一个**构建步骤**（生成 NVIDIA ID 字符串）。

## 这条结论的分量与限制

- 它把"路径 A 只能到 983"推翻为"路径 A 可以到 988 + 一个生成步骤"；
- 但**不证明**整层能编译、能链接、能加载——那些仍未验证；
- 也不改变"发行版 7.93 MB 不透明载荷"的事实：那部分内容仍未解释。
