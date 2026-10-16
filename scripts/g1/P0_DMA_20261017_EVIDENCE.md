# 2026-10-17 G1 P0-DMA：40 项真实 CI 验收与 HONOR DMAR 原始拓扑

## 1. 运行与实际证据（不代替实机 GPU 验证）

- Workflow: [HONOR G1 P0 DMA contract #38939252741](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741)，[Job #117102441290](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741/job/117102441290)；触发类型 `workflow_dispatch`，运行 HEAD `791ba38a9bef3e5acb8a8a1e6901b3e434b37d2e`；整个 Job/workflow SUCCESS。
- 真实 Runner 输出：`test_dma_contract.py` **10/10 PASS**；`test_dma_transaction.py` **13/13 PASS**；`test_dma_rm_path.py` **11/11 PASS**；`test_dmar_evidence.py` **6/6 PASS**；合计 **40/40**。上一次 `//` 注释使函数不闭合的两个负向 fixture 已修复并得到 CI 验证。
- 后续实际取得 NullMoth `cd8e2bb04da48d2fa70cf1895879608f3588dbfb` 与 NVIDIA OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb` 固定源码，三个证据 JSON 完整生成、成功上传；不存在测试中断后虚报解析完成。
- Artifact：[honor-g1-p0-dma-source-contract (ID 12062915390)](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741/artifacts/12062915390)。实际 ZIP 2730 字节，SHA256 `c9385ac96e52e24767b562cf1dd29ac8767f02388f2e14e2bca02e3affca80a1`。GitHub Actions 证据保留期有限，此文保留可检索数值与文件摘要。

| 原始 JSON | SHA256 | 结论 |
|---|---|---|
| `dma-source-contract.json` | `cf0a96798056dd53679a40485c496d86f8e7b9929c6e50e30d625d469b3c0540` | 固定源码 7 项事实全部 true；`BLOCKED_DEVICE_DMA_MAPPING_UNVERIFIED` |
| `dma-rm-path.json` | `42bfc3910414cd89858df11460a38a1909c14c8e56d975d67eb25eace46849f7` | 固定 RM→DMA 数据流 10 项事实全部 true；`BLOCKED_RM_IOVA_OWNER_AND_DMA_UNVERIFIED` |
| `dmar-topology.json` | `2f0c8a4d7e13877b4438b54cb93f754fad55fc9cb4514ff8b30d6c69447a60e3` | 静态固件拓扑通过，`DMAR_TABLE_STRUCTURE_ONLY_RUNTIME_IOMMU_UNVERIFIED` |

## 2. 真实 HONOR GLO-FX6P DMAR 拓扑

- 来源：此前主力 Windows **只读采集**，文件 `docs/hardware-survey-20261012/evidence/acpi/fw_DMAR.bin`，长度 136 bytes，原文件 SHA256 `e84c886dfcc89640faf9c3386d5fbb4dc77483901c816eb38fdcb22a6c298f86`。ACPI checksum PASS；OEM 原始字段包含 `HONOR` 后的 NUL 填充；表报告 Host Address Width = **39 bits**，Interrupt Remapping supported flag = 1（只表明固件能力标志）。
- **DRHD-A**：type 0，length 24，PCI segment 0，register base `0xFED90000`，`include_all=false`；device scope type 1，start bus 00，PCI path device 2/function 0，即 `00:02.0`（Intel Iris Xe `8086:46A6`）。
- **DRHD-B**：type 0，length 32，PCI segment 0，register base `0xFED91000`，`include_all=true`；附带 scope `00:1E.7`（type 3：IOAPIC）和 `00:1E.6`（type 4：MSI-capable HPET）。这些 scope 不是 RTX GPU 路径。
- **RMRR**：type 1，length 32，PCI segment 0，base `0x4C000000`，inclusive limit `0x503FFFFF`，大小 **68 MiB**；device scope `00:02.0`（核显），而不是 RTX GPU。
- 对照已归档 `docs/hardware-survey-20261012/REPORT.md`：RTX 2050 `10DE:25A9` 是 **`01:00.0`**，位于 `00:06.0` PEG60 根端口之后（Windows PCI 路径 `PCIROOT(0)#PCI(0600)#PCI(0000)`）；核显为 `00:02.0`。因此固定 DMAR 声明的 **DRHD-B include-all 预期涵盖 RTX 2050 所在路径**，而 DRHD-A 和 RMRR 则显式列核显。

## 3. 严格的不可推导结论

1. DMAR 描述固件声明的 DMA Remapping Hardware Units 与设备 scope，**不能**证明 macOS 正在开启 Intel VT-d，也不能证明该启动配置已经为 `01:00.0` 分配可用 IOMMU Domain / IOVA page tables。
2. `include_all=true` 是该 PCI segment 的覆盖声明，存在作用域例外/覆盖关系；它**不是**直接读出 RTX 2050 runtime domain，也未验明驱动 `IOMapper` 与 `IODMACommand` 的实际使用。
3. RMRR `00:02.0` 的保留区域不意味着 RTX dGPU 也被同样保留，也不能将 39-bit DMAR host width 误用为 RTX 2050 可 DMA 地址 mask。
4. `dma-rm-path.json` 证明固定版本的源码分支条件：NullMoth 将局部映射 `priv` 置 NULL，RM 把返回值保存 `pOsData` 并用 NULL 判别 peer，底层 DMA unmap 错误后可能失去 owner；**不能**据此断言硬件已经发生该分支或发生真实泄漏。
5. 同项目先前 [Darwin SDK Probe #38931389598](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931389598) 的 C++ x86_64 compile-only PASS，只证明 SDK 编译，不证明符号在目标 macOS Build 下可链接/加载或 IOMMU/GSP/PCI 生命周期安全。

**结论：P0-DMA 40/40 合成与只读源码/固件解析 CI 验收 PASS；RTX 2050 实际 IOVA、IOMapper、DMA/GSP、目标 macOS 内核 ABI 仍全部 NO-GO。未修改 BIOS、EFI、磁盘或实际电脑。**
