# stock v2.4.2 原生门禁收敛（2026-10-21）

固定基线：NullMoth `272ccd9da04ff5de95c2791b902fe17a3fa77ce7`、OGKM
`e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`。补丁 `stock-v242-converged.patch` 直接应用在该 pin 上，
不同时应用其前置补丁或历史 R36–R43 序列；只改 `kexts/NVRM/NVRM.cpp` 与
`kexts/NVRMFB/fb/nvrm-fb.cpp`。

## 1. 最终结果

| 项 | 值 |
|---|---|
| 运行 | [39452257558](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39452257558)（head `e518452`） |
| 结论 | **success** |
| 状态字符串 | `PASS_DARWIN_TWO_TU_OBJECTS_WITH_ACCEPTED_DIAGNOSTICS` |
| artifact | `12279222611`，226155 B，SHA256 `77891e3c103895d27285d69ee9c4aacfa18e0fb70ae8135e48d864674a37fb36` |
| 工具链 | Intel macOS / Xcode 16.4 / SDK 15.5 / Apple clang 17.0.0 |

五个阶段全部通过：

```json
{"object_compilation": {"ok": true},
 "input_consistency": {"ok": true, "files": 429},
 "diagnostics_acceptance": {"ok": true, "accepted": 3, "unexpected": 0, "missing": 0},
 "symbol_integration": {"ok": true, "new_undefined": 2, "missing_undefined": 0,
                        "new_defined": 15, "missing_defined": 0},
 "compiler_negative_control": {"ok": true, "exit": 1}}
```

对象（x86_64 MH_OBJECT，编译后即删除，artifact 只有文本）：

| 角色 | TU | 大小 | SHA256 前缀 |
|---|---|---|---|
| original | NVRM.cpp | 133328 | `d16fb65f0b5ad8b9` |
| candidate | NVRM.cpp | 139736 | `c2c44cc23009fa64` |
| original | nvrm-fb.cpp | 327528 | `7845ac1bbd137aff` |
| candidate | nvrm-fb.cpp | 328320 | `476dec05a23502cc` |

## 2. 三条诊断：从"零新增告警"改为封闭例外

上一轮失败不是编译错误，而是候选 NVRM 的 3 条 `-Wdeprecated-declarations`。它们对应的代码是：

| 位置 | 代码 | 编译器原文（artifact 12276826783 独立核对） |
|---|---|---|
| 1579:13 | `IOPCIDevice *pci;` | `'IOPCIDevice' is deprecated: Use PCIDriverKit` |
| 1587:43 | 构造函数参数 `IOPCIDevice *p` | `'IOPCIDevice' is deprecated: Use PCIDriverKit` |
| 1599:22 | `pci->setBusMasterEnable(...)` | `'setBusMasterEnable' is deprecated: first deprecated in macOS 12.4` |

这三处都在**失败回滚**路径上（恢复 PCI 命令寄存器的总线主控与内存使能），删掉会留下 DMA 已开启的
残状态；把 kext 迁到 PCIDriverKit 也不是本次两 TU 收敛的范围。因此接受为**有据例外**，
并明确不再声称"零新增告警"。

例外清单在 `source-lock.json` 的 `diagnostics_exceptions`，每条绑定：受控 TU 路径、文件名、
行、列、`-Wdeprecated-declarations` 类别、**逐字消息**、计数 1、理由、证据来源。
判定规则（`classify_diagnostics`）：

- 先按位置匹配例外（避免同文本的旧告警掩盖它）；
- 其余与原件同文本的算既有告警；
- 任何未匹配的新诊断 → 拒收；
- 登记的例外少出现一条 → 也拒收（记录已不描述这份构建）。

## 3. 符号级链接集成（最小必要验证，不链接）

用 `nm -u` / `nm -gU` 对四个对象取符号，比较原件与候选：

| TU | undefined | defined |
|---|---|---|
| NVRM.cpp | 466 → 468（+2，均在清单内） | 130 → 145（+15，均登记） |
| nvrm-fb.cpp | 478 → 478 | 177 → 177 |

两个新增外部依赖都有仓库内可追溯证据：

| 符号 | 提供者 | 证据 |
|---|---|---|
| `__ZNK9IOService10isInactiveEv` | XNU 内核 | `runner-kernel-nm-raw.txt:6584`：`T ffffff80009ec9a0 __ZNK9IOService10isInactiveEv` |
| `_rm_disable_adapter` | OGKM RM（`osapi.c:1832`） | `full-nvrm-defined.txt:15838`：`T 0xa3fb0 _rm_disable_adapter`（此前一次完整 NVRM 链接中定义） |

另核对：`rm_disable_adapter(NULL, &fNv)` 传 `NULL` 作为 `nvidia_stack_t*`。
`NV_ENTER_RM_RUNTIME` 只有在定义了 `__use_altstack__` 时才解引用 `sp->top`
（`osapi.h:34`、`:80-85`）；本树与官方 Darwin 构建均未定义该宏（全树只有测试，无赋值），
因此该调用不构成空指针解引用。**这是源码推论，不是运行证据。**

## 4. 本轮在收敛过程中发现并修掉的三个门禁缺陷

1. **报告阶段错位**：`stage` 停在最后一个 TU，真实失败点是告警比较 →
   改为 `stage` 表示当前阶段、失败置 `failed`，并用 `failed_stage` 与 `staged_results` 分开记录。
2. **负控被跳过**：负控位于告警比较之后，告警一失败就不执行 → 改为诊断失败只记录，
   负控始终执行；负控预置 stale 对象，要求退出码非零、stale 对象被删除、最终无对象文件。
3. **报告序列化崩溃**：把 `set` 放进 report 导致 `json.dumps` 抛错，`finally` 里写报告失败，
   artifact 里**没有 report.json**（run 39448180535 就是这样）。改为存排序列表，
   并给写报告加兜底注解，确保失败也有报告。

第三条尤其值得记：一次"门禁失败"可能只是报告写不出来，而不是验收结论。

## 5. 本地验证（无需 macOS）

`tests/test_stock_v242_diagnostics.py`（19 项）与 `tests/test_stock_v242_symbols.py`（9 项），
共 28 项全通过。覆盖：四条告警、位置/列/类别/消息差一位、重复计数、例外缺失、
对象记录带额外字段、未批准的新 undefined、消失的 defined、负控放行与残留 stale 对象、
锁的越界文件/缺字段/计数为 0。

## 6. 仍然没有的东西

- 没有链接、没有加载、没有 GPU 执行；`kext_link='NOT_RUN'`；
- 符号比较只覆盖这两个 TU 的对象，不等于整包 ABI 验收；
- 设备侧三类阻塞未变：stop 入口与对象生命周期、全部使用者排空、电源转换；
- 与 v2.4.2 其余组件的**整包**链接集成仍待验证（下一步）。
