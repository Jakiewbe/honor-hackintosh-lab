# 选定外部表的 -e 逐表复核（2026-10-13）

输入仍为不可变 registry DSDT + 15 SSDT；iasl 20250404、Debian 20250404-1，包和可执行文件哈希与 toolchain.txt 一致。解析器仅在无网络、无宿主挂载、非root容器运行，不执行AML，不访问用户硬件。

**当前16张目标全部退出0，16通过、0失败。** 每个目标原表不改，其余15表中排除两组各一个冲突成员，留下13张外部表。列表、理由、完整参数、退出码、输出和摘要见 [external-plan.json](external-plan.json)、[selected-external-runs.json](selected-external-runs.json)。这不是把16张原表同时装载进一个命名空间；退出0不证明全部External闭合或运行方法有效。

## 选择规则与第三处重复

- 第一组：SaSsdt / SSDT9。目标是其中一张时，排除另一张；其他目标默认保留SaSsdt。
- 第二组：xh_adlLP / DSDT。目标是其中一张时，排除另一张；其他目标默认保留DSDT，但SSDT9作目标时改保留xh_adlLP。
- 最初在两组外默认选SSDT9和DSDT，得到2通过14失败。新对象为触摸板 `\_SB.PC00.I2C0.TPD0._PS0/_PS3`，不是目标表损坏。DSDT:63911–63919与SSDT9:7554–7563各定义电源方法，实际触发日志见 [首次选择记录](selected-external-attempt1-runs.json)。
- 第二次仅调整上述两组内代表，避免DSDT/SSDT9同时出现，仍只排除两张外部表，随后16通过。未额外移除第三张表、修改原AML、使用猜测-fe声明或忽略错误。

历史-da/全15外部表-e失败及本次第一轮失败日志均保留，当前结果以selected-external-runs.json为准。

## 两组重复的位置与无关边界

| 对象 | 精确声明位置 | 与目标图形链的关系 |
|---|---|---|
| `\_SB.PC00.PEG1.PEGP._S0W` | SaSsdt:2112–2119（If PBR1内，0参数返回4）；SSDT9:2555–2568（0参数，RD3C==2返回4否则3） | 用户确认PEG1为空闲端口；原调查REPORT:69记录独显在PEG0，:142记录NVMe在PEG2，P21当前枚举没有PEG1端点。与MUX、内屏、OpRegion结论无关；不能推断端口永久物理空置 |
| `\_SB.PC00.XHCI.RHUB.HS10.SADX` | DSDT:62880–62903（PCHS条件内）；xh_adlLP:330–364（PU2C/WIST条件内） | 原调查REPORT:145记录HS10连接8087:0026蓝牙，与MUX、内屏、OpRegion无关 |

上述条件没有执行，操作系统实际装载策略未知；静态重复不能推断Windows有相同运行错误。

## 跨表条目与参数/类型复核

相对ffbc8fd，NvdTable和IgfxSsdt **全文字节不变**。因此NV/Intel位图、MXDS/MXMX/MXM方法体、PEGP._DOD、DD1F方法、IGDM布局结论不变。其他输出的逐项diff见 [dsl-changes.json](dsl-changes.json)，更新后的findings行号逐项核对原行文本，没有估算行号。

| 引用 | 成功输出中的证据 | 仍未证明的内容 |
|---|---|---|
| P8XH / D8XH | NvdTable:65仍是2参数；DSDT:31368 / 31353均为2参数，MXMX调用不变 | MDBG运行值、调试访问效果，不能称MUX切换 |
| GGIV / GGOV / SGOV | DSDT:13688 / 13704 / 13719，参数1 / 1 / 2；Nvd/Igfx External参数一致 | GPIO信号含义、GC6门禁和实际执行 |
| IMMC / GUAM / PBCL | Igfx:33 / 58 / 84，参数5 / 1 / 0；定义Tcss:298、DSDT:31852 / 31557对应一致 | 外部方法评估、背光通知消费者及实际亮度 |
| Tcss PCIC / PCID | Tcss:27–28新增1 / 4参数External，日志明确重解析两个外部方法 | 不是XNU PCI访问实现；TDM0/TDM1条件不变，行号更新为1505/2201起 |
| SaSsdt路由对象 | 新增_SB.AR02/AR0A/AR0B及PD02/PD0A/PD0B PkgObj、CPID FieldUnitObj，注释绑定_SB路径 | 不证明真实中断路由运行成功 |
| SSDT9 DGBA / SocGpe | SSDT9:31新增DGBA FieldUnitObj；SocGpe新增5项UnknownObj声明 | 不推升为实际内存内容或完整类型闭包 |
| EDMX / ASLB / DME | Igfx:28的GFX0.EDMX、:36的ASLB仍UnknownObj；DSDT:4860/2764/2889–2890有字段声明 | 同名GNVS EDMX不能等同GFX0.EDMX；NVS值与初始化者未取得 |

DSDT即使退出0，仍报告外部方法警告，其“unresolved”计数出现无符号下溢，不能用该数字宣称依赖数量。成功只解除逐表反汇编失败，不解除所有方法/对象未知项。

实质变化：MXMX、MUX三选一、ASLB来源与赋值者、联合命名空间验收、_S0W重复定义；新增HS10.SADX重复、触摸板电源重复、External增量。所有条目复核记录与行号变化见 [findings-changes.json](findings-changes.json)。保持SOURCE-STATIC / RUNTIME_NO_GO，OpRegion/VBT实际内容仍未取得。
