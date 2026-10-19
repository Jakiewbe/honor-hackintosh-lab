# 给独立审查者的 Prompt（HONOR G1 主线 + 当前代码）

> 用法：把下面整段内容发给审查模型。它要求审查者**只读**仓库、逐项复算数字、并把"已验证"与"未验证"分开。

---

你是一名独立审计者。请审查仓库 `https://github.com/Jakiewbe/honor-hackintosh-lab` 的一条硬件适配主线，
判断它当前宣称的进度是否成立、当前代码是否存在会阻止安全加载的缺陷。**只读**：不要修改仓库、不要触发
GitHub Actions、不要下载或运行任何驱动二进制、不要给出"可以上机"的结论。

## 1. 项目与目标

硬件：HONOR GLO-FX6P，i5-12500H，Intel Iris Xe `8086:46A6`（内屏 2160×1440 在 Windows 下由它驱动），
NVIDIA RTX 2050 Laptop `10DE:25A9`（macOS 下目标为混合加速）。macOS 15 装在外接 SSD，内置 NVMe 与
Windows 一律不动。

主线目标：让 RTX 2050 具备**可复现构建 → 正确初始化 → 真实离屏渲染 → 正确像素读回 → 错误传播 → 安全结束**；
Intel 核显保持现有基础显示与显示所有权。任何 kext 加载/安装都需要用户逐项授权，当前状态是 **NO-GO**。

验收阶梯（上一级不能替代下一级）：
`SOURCE-REVIEW → HOST-TEST → PATCH-APPLIED → DARWIN-COMPILE → KEXT-LINK → KEXT-LOAD → GPU-RUNTIME → DISPLAY-RUNTIME → 加速桌面`

## 2. 固定基线（请从这里开始，不要用别的版本）

| 项 | 值 |
|---|---|
| 审查起点 HEAD | `8be05d95c83c29d8233f5bbcd40beb27f9532fae` |
| NullMoth 候选源码 pin | `ac55984c473e746c2a8ebea7ba0913461aa7c393` |
| OGKM pin | `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb` |
| XNU pin | `a1e26a70f38d1d7daa7b49b258e2f8538ad81650` |
| 补丁序列 | `scripts/gpu-safety-r5/native_compile.py` 内 32 项元组 |
| 最近一次门禁绿灯 | run `39238579665`（`gpu-safety-r5-native.yml`，19 步 success） |
| 最近一次完整构建独立验收 | run `39189188122`（1280 TU + 5 shader + 归档 + 链接 EXIT=0） |

## 3. 当前声称的状态（请逐条验真，不要默认成立）

**构建层**
1. 官方完整构建：1280 个官方 TU（1240 C + 40 C++）、5 个 shader 对象、两份 OGKM 归档、候选 kext 链接 EXIT=0。
2. 候选导入面 472 项，与发行版 `NVRM`（Mach-O `LC_SYMTAB` 解析）472 项交集 **471**；
   差异只有候选的 `_panic` 与发行版的 `__ZN12IOUserClient4freeEv`。
3. `Info.plist` 的 `OSBundleLibraries` 覆盖全部 472 个导入的提供者（其中 8 个只走 `IOPCIFamily`/`IOACPIFamily`）。

**关闭语义层（重点）**
4. R35（我曾提出的方案）用"释放后查询 `nvKmsKapiDeviceFreeCompleted(fDev)`"判断关闭是否成功，
   被审计判定为 **heap-use-after-free**；R36 改为 `nvKmsKapiTryFreeDevice()` 直接返回结果，已合入序列。
5. R38 草案（未合入）主张把 callback quiescence 提前到破坏性 NISO 清理之前。
   我用 `tools/check-kapi-free-order.py` 在 R36 候选（sha `895de47a…`）上测得顺序为：
   NISO 释放(112/170) → `FREE_DEVICE`(497) → quiesce(811)，即 **失败**；应用 R38 草案后变为
   quiesce(255) → `FREE_DEVICE`(655) → NISO(990/1048)，即 PASS。

**未验证（必须当作空白）**
6. KEXT 加载、GPU 初始化、离屏渲染、像素读回、安全结束：全部未执行。
7. 完整 C++ ABI、loader 导出、最终用户系统差异、卸载安全：未验收。
8. P0-3（RM 门忙超时后仍进入 STANDBY）：`tools/check-pm-exclusion.py` 当前 **31/32、exit 1**；
   R37 草案给出"拒绝 STANDBY"的实现，但未合入、未实机。

## 4. 审查规则（本项目已多次踩坑，请严格执行）

- **证据口径先确认**：一个数字来自哪条命令？是单对象还是链接产物？是声明还是定义？
- **禁止代理指标**：延迟计数器、名称覆盖率、词法索引命中，都不能替代"对象/IR/调用链"证据。
- **fail-closed**：编译/链接/夹具不完整必须非零退出；发现"部分链接却返回 0"要按缺陷报。
- **不得把危险行为写成通过项**：曾有一条检查把"RM 门忙仍 STANDBY"断言成必须满足，是错的。
- **负控必须检验真实语义**：曾有一条 UAF 负控因 `-O1` 内联导致 ASan 帧名不含目标函数，被误判为"未复现"。

## 5. 请重点审查的六个方向

**A. 构建来源是否可复现**
- `tools/g1_full_build.py`、`tools/g1_ogkm_candidate.py`、`tools/g1_ogkm_patch_route.py`：
  候选树是否只改动了被批准的源文件？正向/反向/重放哈希是否真的被验证？`ar` 与 `why_load` 证据是否指向最终产物？
- `scripts/gpu-safety-r5/native_compile.py` 的 32 项序列是否与 `patches/` 中的文件哈希一致？

**B. 关闭失败传播（P0-4）是否真的闭合**
- `patches/` 中 R36 两份（OGKM + NullMoth）与 `research/gpu-safety-r5/R36-R35-AUDIT-TRY-FREE-20261019.md`；
- `KmsFreeDevice` 的清理顺序（用 `tools/check-kapi-free-order.py` 复核我的数字）；
- `nvkms_xnu_try_close_kapi` 在 callback 在途、`thread_call_free` 拒绝、PM 不可用三种情况下是否都**保留**状态；
- 调用方 `kexts/NVRMFB/.../nvrm-fb.cpp` 的 `dropKapiDevice()` / `finishOrphanedDevice()` 是否在失败时保留 `gDev` 与 creator retain；
- 反向点：`AllocateDevice()` 中途失败时 framebuffer 拿不到指针，现有方案是否漏了 owner。

**C. PM 风险（P0-3、P0-2）**
- `kexts/NVRM/NVRM.cpp::gpuSuspend()` 里 `nv_xnu_pm_close(10000)` 之后的行为；
- XNU `IOServicePM.cpp:4525` 语义（负返回值等同 implied ack）是否被正确理解；
- R37 草案的"拒绝 STANDBY"是否引入更严重的问题（GPU 未进低功耗态被断电）；
- `eventBusy` 是否还有无界等待。

**D. 导入面与目标系统**
- `research/gpu-safety-r5/target-provider-evidence/`、`kc8-evidence/`、`shipped-nvrm-imports.json`：
  472/471、8 个 Intel KC 符号、六个 PCI 方法的调用侧证据是否成立；
- 哪些只是"名称/符号存在"，被误当成 ABI 或运行证据。

**E. 门禁工程本身**
- `.github/workflows/*.yml` 与 `tools/*.py`：是否还有"失败仍返回 0"、跳过步骤仍绿、
  注解掩盖真实 status、artifact 缺失时结论不可复核的问题；
- `tools/g1_full_rm_probe.py` 已退役（曾出现 135/988 部分链接仍 exit 0），确认它无法被再次启用。

**F. 文档与证据一致性**
- `knowledge/02_CURRENT_STATE.md`、`research/gpu-safety-r5/ACCEPTANCE-MATRIX-20261018.md`、
  `R36-*`、`R37-*`、`R38-*`：文档里的数字能否被仓库内脚本重现；
- 是否存在把"构建通过"写成"可加载"、把"CPU 合同"写成"运行验证"的表述。

## 6. 可以运行的只读命令（示例）

```bash
python3 tools/check_kapi_free_order.py <candidate>/src/nvidia-modeset/kapi/src/nvkms-kapi.c
python3 tools/check-pm-exclusion.py --source <candidate> --out /tmp/pm
python3 tools/g1_srcs_inventory.py --nv <ogkm>
python3 tools/macho_imports.py <NVRM binary> --grep IOUserClient
python3 -m unittest discover -s tools -p 'test_*.py'
```
（若某条命令需要 macOS 或特定 SDK，请明确写"未运行"，不要推测结果。）

## 7. 输出格式

1. **结论表**：六个方向各给 `PASS / FAIL / NOT VERIFIED`，附一句理由；
2. **缺陷清单**：按 P0/P1/P2 分级，每条给出 `文件:行号`、复现命令、错在哪、如何证明；
3. **被高估的声明**：指出文档中哪些数字被过度解释（构建→加载、名称→ABI、合同→安全）；
4. **必须先做什么**：按"不接触设备就能做"与"需要实机授权"分开列；
5. **你无法验证的部分**：明确写出来，不要用推理补足。

请特别警惕：本项目历史上出现过"假绿门禁""把危险行为写成 PASS""用名称覆盖率代替语义证据"三类错误。
如果你发现同类问题的残留或新实例，请直接指出。
