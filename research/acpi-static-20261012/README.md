# R1.4-C0-pre｜GLO-FX6P ACPI 原表静态解析

**不能推出：物理 MUX 有无、GPIO 电气走线、Windows 未枚举 NHI 的真实原因、OpRegion/VBT 内容、有效 eDP/DDI/AUX 参数、macOS 显示/背光/电源成功。不能把 `_DSM` 位图或单表反汇编成功当作运行时证据。** 当前内屏接 Intel `8086:46A6` 已知；独显是 RTX2050 `10DE:25A9`。保持 **RUNTIME_NO_GO**。

本轮为 **SOURCE-STATIC**：同一20250404按显式冲突组选择13张外部表后，**逐表16通过、0失败**。目标16张原表都解析，原AML不改。退出0不是所有External已闭合，更不是运行时证据；DSDT仍有外部方法警告，EDMX仍UnknownObj。

## 输入和工具实际执行

原证据来自已合并 PR #1 的提交 `195e465`，本地与前两轮研究合并后的起点 `8d1333307ae37329e1bb6442543a5d1fecc77d03`。未改动 [原调查目录](../../docs/hardware-survey-20261012/REPORT.md) 任何文件。

[inputs.json](inputs.json) 按 P40 长度、header长度、checksum_ok、原始累加校验和和 FILES_SHA256 逐项核验；36 份原表全部一致，主输入 DSDT+15 SSDT 共16份。fw只交叉核对，fw_DSDT与reg_DSDT字节一致，没有把只返回首个SSDT的firmware API副本代替15表。

固定 [ACPICA Debian 包](https://packages.debian.org/trixie/acpica-tools) `20250404-1`，`iasl -v` 为20250404；包/可执行文件SHA256和完整命令见 [toolchain.txt](toolchain.txt)、[tool-source.json](tool-source.json)。先用20200925-8遇到同一冲突，旧工具与失败日志保留作诊断，不作为成功版本。

解析器仅在无网络、只读根目录、非root UID65534、无宿主目录挂载、无特权的临时Linux容器执行。原字节通过标准输入复制到容器内存目录；未在Windows安装或运行iasl；未执行AML方法，未访问宿主ACPI/PCI/物理内存。

- `iasl -da <reg_DSDT及全部15个reg_SSDT>`：两个固定版本均退出255。首先在 `\_SB.PC00.PEG1.PEGP._S0W` 创建时报AE_ALREADY_EXISTS，随后命名空间出现连带错误。[20250404日志第19–20行](iasl-disassembly.log)、[20200925日志](iasl-20200925-joint-failed.log)。未删除表、未改AML、未忽略错误来制造成功。
- 历史 `iasl -d <单表>`：16份分别退出0，命令/输出见 [individual-runs.json](individual-runs.json)。当时DSL见ffbc8fd；当前 [清单与哈希](disassembly-manifest.json) 已对应本轮选表-e输出。DSDT外部方法警告中的“141 found/397 resolved/4294967040 unresolved”计数不可靠，不能按巨大无符号数声称缺了这么多方法。
- 本次按 [external-plan.json](external-plan.json) 执行 `iasl -e <13张选定外部表> -d <目标>`：**16通过、0失败**。每次完整列表、两个排除理由、退出码和输出摘要见 [selected-external-runs.json](selected-external-runs.json)。
- 两组重复为PEG1.PEGP._S0W（SaSsdt/SSDT9）及HS10.SADX（DSDT/xh_adlLP）。用户确认PEG1为空闲端口，调查记录独显在PEG0、NVMe在PEG2，HS10是蓝牙；两组重复与MUX/内屏/OpRegion无关。
- 首次组内选SSD9+DSDT暴露触摸板I2C0.TPD0._PS0/_PS3重复（2通过14失败）；改选SaSsdt+DSDT，SSD9作目标时改选xh_adlLP，仍只排除两组各一个成员，随后16通过。原始失败日志保留，详见 [external-review.md](external-review.md)。不忽略错误，不改目标表。
- 旧单表16通过、旧-da两版本失败及全外部表-e16失败是历史诊断；当前DSL为选表-e成功输出。DSDT外部方法警告仍存在，其下溢计数不可靠，不按该数值宣称缺多少方法。
- [findings-changes.json](findings-changes.json)、[dsl-changes.json](dsl-changes.json) 对照ffbc8fd列变化；NvdTable和IgfxSsdt文本完全相同，位图和关键显示方法结论未变。离线测试记录见verification.json。

## 混合显卡：位图、stub 与非空路径

下表是 **function0声明**，bit0表示查询支持，数字集合只列子功能。原表支持函数的实际运行可达性未知。所有 GUID 分发证据为 NvdTable DSL187–224；完整结论逐行见 [findings.csv](findings.csv)。

| 方法 | function0原始字节 | 声明子功能 | 前提与证据行 |
|---|---|---|---|
| NVOP | `01 00 00 0C` | 26、27 | Arg1=0x100；NvdTable266–283 |
| JT/GC6（NVJT） | `1B 00 00 00` | 1、3、4 | Arg1>=0x100且GC6S!=0；511–527。方法体另有Case2，不能据此扩大位图支持集合 |
| NBCI | `01 00 11 00` | 16、20 | Arg1=0x102且NBCS!=0；701–717 |
| GPS | `01 00 08 00 01 04 00 00` | 19、32、42 | Arg1=0x200且GPSS!=0；368–385 |
| MXM（AML NameSeg为MXM_） | `01 00 01 01` | 16、24 | function0无revision门禁；1314–1324 |

**MXDS**：1307–1312两个空If后返回0，是本方法体的stub。**MXMX**：1282–1305调用P8XH，参数0/1返回1，2/其他返回0；DSDT31346–31374的P8XH→D8XH是受MDBG存在条件控制的调试端口写，不是已证明的显示切换。**MXM_**：1325–1346在revision0x300和MXBS非零时读取NOPR中的MXMB；function24返回Unicode("0")。它不是完全空实现；MXBS/MXMB实际内容未取得。

**PEGP._DOD**：NvdTable1274–1280返回 `Package{0x80087330}`，核实旧手工解读。这只确认ACPI输出ID常量，不证明NVIDIA物理连接或活动输出。

**PEG0电源**：SSDT9 `ADL-P-M`3146起的PEG0 scope中，4406–4420的_PR0/_PR3都返回PXP；4252–4305的PXP._ON/_OFF及4378–4404的PON/POFF包含PCI字段、PIN方法和EC.ENSG操作，非空。RSTG/PWRG从DG2R/DGR2/DG2P/DGP2得到，见3148–3163；名称不能代替GPIO含义。NvdTable465–507的GC6I/GC6O还访问EC.IGC6/RGC6和SGOV，含无计次等待，不能继承为有时限的XNU错误合同。

**三选一结论：无法判断。** Intel IgfxSsdt function21在2936–2964经EDMX调用GGOV/SGOV；DSDT13704–13733有对应的SystemMemory位读写路径，DSDT另声明GNVS中的同名EDMX字段（4860）；Igfx的GFX0.EDMX在成功输出中仍为UnknownObj，不能与GNVS同名字段自动等同。这是一条非空候选控制路径；EDMX对象绑定、实际值、引脚功能和运行条件未证明，不能确认为MUX控制实现，也不能把所有ACPI路径称为只有stub。更不能写“确认没有MUX”。

## Intel 显示声明

**GFX0._DOD** 不是恒定设备表：IgfxSsdt112–188进入方法先设NDID=2，再根据OpRegion DIDL/DDL2..DD15更新NVS DID1..DIDF。208–227的两项默认表达式为 `0x10000|DID1` 与 `IPTP==1 ? 0x23480 : (0x10000|DID2)`。其他包长度分支保留到713行；实际ID/列表值UNKNOWN，不能拿Windows连接器列表替入。

[device-addresses.csv](device-addresses.csv) 保存全部17个DD节点的_ADR原方法体、行号和UNKNOWN运行值：DD01..DD0F通常在DIDn为0或类型为0x400时返回节点序号，否则返回DIDn低16位，并可能修改EDPV/NXDX/DIDX；DD02还处理第二内屏路径。DD1F的_ADR是 `EDPV==0 ? 0x1F : (DIDX&0xFFFF)`（1467–1477），DD2F见1652–1667，不能把它们都写成常量地址。

DD1F：_DCS按EDPV返回0或CDDS(DIDX)（1479–1489）；_DGS按HGMD/SNXD返回NXDX或NDDS(DIDX)（1491–1499）；_DSS调用DSST（1501–1504）。状态依赖的OpRegion及NVS内容未取得。_BCL调用PBCL或返回103项包：80/50、0..100（1506–1621）；_BCM仅接受0..100，调用AINT(1,Arg0)并写BRTL，_BQC返回BRTL（1623–1635）。AINT有TCHE/PARD检查，并写BCLP/ASLC/ASLE（2606–2616、2694–2712）；不证明硬件亮度已经改变。

IGD _DSM GUID `3e5b41c6-eb1d-4260-9d15-c71fbadae414` 在Arg1=1的function0返回**Integer**0x002DE7FF（2733–2764），声明1–10、13、14、15、16、18、19、21。bit15被声明但该方法没有Case0x0F，不能声称每一声明功能都已有有效实现。

**IGDM字段布局**：2080声明 `OperationRegion(IGDM,SystemMemory,ASLB,0x2000)`，2081–2187的98项字段详见 [opregion-layout.csv](opregion-layout.csv)，bit/byte偏移全部来自声明。Header从0起；视频mailbox0x100（DIDL0x120）、SWSCI0x200、ASLE0x300（BCLP/CBLV/RVDA/RVDS）、RVBT0x400，RVBT之后还有PHED/BDDC声明。

**ASLB由谁赋值：UNKNOWN。** DSDT2761–2764中它是SANV首个32bit字段、偏移0；SANV使用SANB/SANL（936–937）。在本轮16个选表-e DSL里没有找到ASLB赋值语句；外部固件填充只是一种推断，不能当已确认赋值者。Igfx的PCI_Config IGDP区域从0x40起，区域内0xBC声明ASLS（2051–2077），位置计算0x40+0xBC=0xFC；IGDM却使用ASLB，两个运行值是否一致UNKNOWN。

**OpRegion/VBT实际内容仍然未取得。ACPI只给出声明。** P41的两个obtained均false；RVBT字段声明并不是VBT数据，ASLB声明也不是实测物理指针。未读未知寄存器或内存。

## TcssSsdt：只能解释条件，不能确认原因

TDM0 _ADR=0xD0002，_STA在DME0==1时返回0x0F，否则0（1505–1521）。TDM1 _ADR=0xD0003，条件为DME1（2201–2217）。DME0/1是DSDT SANV字段（2889–2890），本次无内容。

**推断**：若对应DME!=1，该DMA的ACPI节点会报告不在位状态，PCI枚举并不完全由_STA决定。这是Windows未枚举NHI的可能解释；实际DME值、固件策略、PCI设备可达性及硬件实现UNKNOWN。不能从未枚举推断没有Thunderbolt/USB4硬件。

## 如何输入 R1.4-C0 T2

[T2-platform-map.md](T2-platform-map.md) 对照固定 Linux v6.1 `830b3c68c1fb1e9176028d02ef86f3cf76aa2476` 与 drm-kmod6.1-lts `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4` 的实际源码，pin/blob/许可头见 [upstream-sources.json](upstream-sources.json)。只新增声明与接口要求，不关闭VBT/OpRegion节点。

下一步仍为 **R1.4-C0 T0→T4**：T0复用选表-e成功与重复对象记录，保留外部方法警告，不重复解析或已知硬件归属调查；T1固定原表/工具/上游源；T2以本轮ASLB/IGDM/DSM/显示方法声明作为平台输入，补真实ACPI evaluator、PCI配置/物理映射/资源所有权、通知消费者和背光语义；T3失败停止；T4交付证据。OpRegion/VBT内容和eDP实际参数缺口不因本报告消失，不进入驱动实现或硬件读取。
