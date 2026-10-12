# ACPI 声明 → T2 VBT/OpRegion节点

等级SOURCE-STATIC。固定commit/blob/实际字节及许可证头见upstream-sources.json。Linux intel_acpi.c为GPL-2.0；FreeBSD替代intel_acpi.c声明Public domain，二者不是相同实现。Linux acpi_video.c目前仅固定raw URL字节、未独立Git树核验；不能推升ABI验收。

| 必需平台合同 | Linux6.1真实源码行 | FreeBSD6.1真实源码行 | 本机ACPI能给什么 | 未闭合事项 |
|---|---|---|---|---|
| PCI ASLS/映射/校验 | display/intel_opregion.c897–933读取ASLS、memremap、验证签名/版本/mailbox | 同文件906–942 | IgfxSsdt2051–2077声明PCI_Config ASLS；2080声明ASLB/IGDM | 未取得ASLS/ASLB实际值与OpRegion内容；XNU PCI访问、映射属性/长度/所有权/失败清理 |
| VBT/RVDA | 969–1028外部VBT/RVDA/RVDS或base+0x400 VBT，实际验证有效性 | 对应路径989–1038 | Igfx2181–2186声明RVDA/RVDS/RVBT | 不能用字段布局代替VBT；子设备/DDI/AUX/链路/电源时序都缺实际数据 |
| _DSM handle/类型 | display/intel_acpi.c16–27定义两个GUID，134–150探测MUX信息，186–200执行BIOSdata function0 | intel_acpi.c6–8是空体；opregion.c1205仍调用该空函数 | Igfx2733–2764有BIOSdata GUID；NvdTable187–224是其他GUID分发 | XNU ACPI companion/评估器、revision/function/Buffer/Integer/Package返回类型、序列化语义。MUX信息GUID不能混同BIOSdata GUID |
| 输出子节点 | intel_acpi.c293–325为内屏尝试0x1F ACPI child，连接器顺序需已固定 | intel_acpi.c10–12为空体 | DD1F_ADR为条件表达式；GFX0_DOD依赖NVS/OpRegion | 实际_ADR/_DOD返回值、连接器与fwnode关联缺失；不能由节点名猜DDI |
| ACPI video协议 | drivers/acpi/acpi_video.c335–364执行_BCL/_BCM；1129读取_ADR；1289–1346执行/解析_DOD Package | 候选BSD i915并没有提供等价完整video协议证明 | GFX0_DOD和DD方法体存在；背光经AINT通知OpRegion | 真实_evaluator、通知/异步消费者及可验证硬件背光；DSDT选表-e成功输出仍有外部方法警告 |
| ASLE握手与背光 | opregion.c1170–1198设置drdy/ardy/tche并调用DSM；需真实共享内存消费者 | opregion.c476–483假设native背光并直接return0 | Igfx2606–2712按TCHE/PARD写BCLP/ASLC/ASLE | FreeBSD宿主忽略策略不是XNU完成请求；禁止复制为成功stub |

物理内容未取得并不授权读物理内存，本轮没有新增宿主操作。T2节点状态仍BLOCKED，选表-e16通过，DSDT外部方法警告及EDMX UnknownObj仍明确保留，不被SOURCE-STATIC清单成功覆盖。

原始源码链接：[Linux OpRegion](https://github.com/torvalds/linux/blob/830b3c68c1fb1e9176028d02ef86f3cf76aa2476/drivers/gpu/drm/i915/display/intel_opregion.c#L897)、[Linux ACPI桥](https://github.com/torvalds/linux/blob/830b3c68c1fb1e9176028d02ef86f3cf76aa2476/drivers/gpu/drm/i915/display/intel_acpi.c#L186)、[Linux video](https://github.com/torvalds/linux/blob/830b3c68c1fb1e9176028d02ef86f3cf76aa2476/drivers/acpi/acpi_video.c#L1289)、[BSD空桥](https://github.com/freebsd/drm-kmod/blob/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4/drivers/gpu/drm/i915/display/intel_acpi.c#L6)。
