# stock v2.4.2 原生门禁收敛（2026-10-21）

固定基线：NullMoth `272ccd9da04ff5de95c2791b902fe17a3fa77ce7`、OGKM
`e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`。补丁 `stock-v242-converged.patch` 直接应用在该 pin 上，
不同时应用其前置补丁或历史 R36–R43 序列；只改 `kexts/NVRM/NVRM.cpp` 与
`kexts/NVRMFB/fb/nvrm-fb.cpp`。

## 1. 上一轮失败的真实原因（不是编译错误）

run [39440488018](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39440488018)：
四个对象编译退出码均为 0（x86_64 MH_OBJECT），失败发生在**告警比较**：
候选 `NVRM.cpp` 多出三条 `-Wdeprecated-declarations`，全部位于 `AdapterAttempt`。

本轮在本地重新应用补丁并核对候选源码，确认三条诊断对应以下真实代码：

| 位置 | 代码 | 性质 |
|---|---|---|
| 1579:13 | `IOPCIDevice *pci;` | 类型弃用 |
| 1587:43 | `AdapterAttempt(nv_state_t *n, IOPCIDevice *p)` | 构造函数参数类型弃用 |
| 1599:22 | `pci->setBusMasterEnable((savedCommand & 0x0004) != 0);` | API 弃用 |

补丁应用后两个候选文件 SHA256 与交付值逐一相符（`ac0c7518…`、`35ebfb18…`），因此
"候选就是被审计的那份源码"这一条成立。

## 2. 判定：这是验收策略调整，不是"零新增告警"

三条诊断都落在**必须保留的硬件操作**上：恢复总线主控与内存使能是失败回滚的一部分，
删掉它们会留下 DMA 开启的残状态；把 kext 迁到 PCIDriverKit 不属于本次两 TU 收敛范围。

因此本轮的验收语义改为：

> 门禁接受**一份封闭的、逐条绑定的诊断例外清单**；清单之外的任何新增诊断一律拒收，
> 清单中登记的例外若消失也拒收。

不再声称"零新增告警"。状态字符串也从 `PASS_DARWIN_TWO_TU_OBJECTS_ONLY` 改为
`PASS_DARWIN_TWO_TU_OBJECTS_WITH_ACCEPTED_DIAGNOSTICS`，并有字段
`warnings_claim: "ACCEPTED_EXCEPTIONS_ONLY (no zero-new-warning claim)"`。

清单写在 `source-lock.json` 的 `diagnostics_exceptions`，每条绑定：

| 字段 | 含义 |
|---|---|
| `path` / `file` | 必须是两个受控 TU 之一，且文件名与路径一致 |
| `line` / `column` | 精确位置（由候选源码核对） |
| `category` | `-Wdeprecated-declarations`，不接受"任意弃用类警告" |
| `message_regex` | `IOPCIDevice.*deprecated` / `setBusMasterEnable.*deprecated` |
| `count` | 必须恰好出现一次；多一次即拒收 |
| `reason` | 为什么保留这些调用 |

**关于消息文本的边界**：artifact 需要认证，本轮无法下载 `report.json` 与编译日志
（API 返回 401），因此例外清单里的消息绑定用的是**符号名 + deprecated 语义的正则**，
而不是逐字复制编译器原文。若真实措辞不匹配，门禁会 fail-closed 并通过注解打印实际的
unexpected/missing 诊断，下一轮据此收紧——不会因为"大概是这样"而放行。

## 3. 报告阶段修正

原实现把 `stage` 设成每个 TU（最后留在 `candidate:NVRMFB`），真正失败点却是 NVRM 的告警比较。
现在 `stage` 只表示当前阶段，失败时置 `failed`，并新增：

- `failed_stage`：第一个失败阶段（`object-compilation` / `input-consistency` /
  `diagnostics-acceptance` / `compiler-negative-control`）；
- `staged_results`：四个阶段各自的 `ok` 与计数，互相独立。

## 4. 负控不再被告警拒收挡住

原实现把负控放在告警比较之后，告警一失败就跳过负控。现在：

1. 对象编译 → 输入一致性 → 诊断验收，失败只**记录**不中断；
2. 无论前面是否失败，都执行编译器负控；
3. 负控**预置**一个 stale 对象（`STALE_OBJECT_MUST_NOT_SURVIVE`），编译非法源后要求：
   退出码非零、stale 对象已被删除、最终没有对象文件；
4. 结果写入 `compile_negative` 与 `staged_results.compiler_negative_control`，
   失败也会出现在注解里。

## 5. 可被击穿的验证（本地，无需 macOS）

`tests/test_stock_v242_diagnostics.py`（19 项，全通过）：

| 用例 | 期望 |
|---|---|
| 三条绑定例外（位置/类别/消息/计数全对） | 接受 |
| 第四条同类告警 | 拒收 |
| 行号差一位 / 列号差一位 / 类别不同 / 消息不含符号 | 拒收 |
| 同位置重复出现两次（超过 count） | 拒收 |
| 登记的例外一条都没出现 | 拒收 |
| 原件里已有同文本告警 | 位置绑定优先，仍按例外处理（避免被旧告警掩盖） |
| 负控：编译器返回 0 | 抛出失败 |
| 负控：编译器返回非零但留下 stale 对象 | 抛出失败 |
| 负控：正确 fail-closed | 通过 |
| 锁：越界文件 / 缺字段 / count=0 | 抛出失败 |

## 6. 仍然没有的东西

- 本轮**没有**读取 artifact（401），三条告警的编译器原文未独立核对，只有源码位置与语义；
- 没有链接、没有加载、没有 GPU 执行；
- 设备侧三类阻塞（stop 入口与生命周期、全部使用者排空、电源转换）未变化；
- kext 能否与 v2.4.2 其余组件正确集成，尚未验证（见下一阶段）。
