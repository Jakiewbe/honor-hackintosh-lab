# 两个候选对象的符号闭包（链接前的最小验证）

本轮完成了原生门禁（run 39470420908，提交 `378b508`，结论 **success**，
artifact `12286607574` / SHA256 `b6209029a94a43a76a86289a67c75976d2cb986e5e50bb8b4d572c58eb0d70b2`），
随后用该次运行产出的对象符号做了链接前的闭包核对。

**这仍不是链接**：下面是"每个未定义符号能否指出提供者"的静态核对，不是 `ld` 的结果。

## 1. 输入

| 输入 | 来源 | 绑定 |
|---|---|---|
| 两个候选对象的 `nm -u` | 本次 artifact 的 `candidate-NVRM-undefined.txt` / `candidate-NVRMFB-undefined.txt` | 提交 `378b508`（与本轮 HEAD 的代码文件逐字节相同，差异只有 README/knowledge） |
| 内核导出符号 | `runner-kernel-nm-raw.txt`（23,426 行）与 `kernel-symbolsets-decoded.txt` | 同一次真机 runner 抓取 |
| NVRM 自有对象定义 | `full-nvrm-defined.txt`（17,703 行） | **旧提交的完整 NVRM 链接**，只用于"驱动自己有没有这个定义"，不作为本次构建的证明 |
| IOPCIFamily / IOACPIFamily 允许表 | `IOPCIFamily-kext-allowlist.json`、`IOACPIFamily-kext-allowlist.json` | 来自 runner 的 kext exports |
| 驱动源码定义 | `kexts/NVRM/{os-xnu.cpp:278, nv_xnu_power.cpp:40, os-nvkms-xnu.cpp:195}` | 固定 pin `272ccd9` |

## 2. 结果

| TU | 未定义符号总数 | 内核 | IOFamily 允许表 | NVRM 自有对象 | 驱动源码 | IOGraphics | 无法归属 |
|---|---|---|---|---|---|---|---|
| `NVRM.cpp` | 468 | 412 | 7 | 46 | 3 | 0 | **0** |
| `nvm-fb.cpp`（NVRMFB） | 478 | 363 | 0 | 0 | 0 | 115 | **0** |

三点说明：

1. **本轮新增/变化的三个符号都能落到提供者**：
   `_thread_call_allocate_with_options`（内核，`runner-kernel-nm-raw.txt:20704`）、
   `__ZNK9IOService10isInactiveEv`（内核，`:6584`）、`_rm_disable_adapter`（NVRM 自有对象，
   `full-nvrm-defined.txt:15838`）。消失的 `_thread_call_allocate` 已在 lock 里登记为"已批准的移除"。
2. `NVRMFB` 的 115 个 IOGraphics 符号（`IOFramebuffer::*`、`IODisplay::*`、
   `IODisplayParameterHandler::*`、`gIODisplay*`）**目前没有导出清单证据**：仓库里有
   IOPCIFamily/IOACPIFamily 的 allowlist，没有 IOGraphics 的。
3. `nv_xnu_maps_init`、`nv_xnu_power_refresh`、`nvkms_xnu_suspend` 不在旧完整链接的定义表里，
   但在固定 pin 的驱动源码中有定义（行号见上），属于同一 kext 的其它 TU，不是外部依赖。

## 3. 真正的链接还缺什么（精确到输入）

| 缺口 | 需要的东西 | 可执行获取方式 |
|---|---|---|
| IOGraphics 导出证据 | `/System/Library/Extensions/IOGraphics.kext/Contents/Resources/config/IOGraphics.exports` 的条目清单 | 在 macOS runner 上读该文件（与现有 IOPCIFamily allowlist 同一采集方式），一次即可 |
| 链接对象集 | NVRM 其余 TU 的 `.o`（或整包 link-only 运行） | 复用仓库既有的完整构建配方；只有闭包证明必要时才扩大（本闭包尚未证明必须全量重编） |
| RM 对象提供者 | OGKM `e4a5faa` 构建出的 RM 对象 | 同一 link-only 运行内的 OGKM 构建步骤 |

## 4. 这层证据能说明什么、不能说明什么

- 能说明：两个候选对象**没有"指不出提供者"的外部依赖**，三个新符号都有提供侧证据，
  且没有重复定义冲突的迹象（定义集与原件相比只有 15 个新增 NVRM 方法，无删除）。
- 不能说明：kext 真的能链接、ABI 真的成立、能加载、GPU 能执行。`ld` 未运行，
  `kext_link` 仍未验收；设备继续 NO-GO。

## 5. 一个必须先回答的链接问题：`_kmod_info` 等三个符号在两个 TU 里都定义了

本轮把两个候选对象的 `nm -gU` 逐符号对比后发现：

| 符号 | NVRM 候选 | NVRMFB 候选 | 原始对象 |
|---|---|---|---|
| `__start` | `T 0x0` | `T 0x0` | 同样存在 |
| `__stop` | `T 0x10` | `T 0x10` | 同样存在 |
| `_kmod_info` | `D 0xcfe0` | `D 0x18f10` | 同样存在 |

也就是说，**两个 TU 各自都有强定义**。我一度给门禁加了 `ld -r` 合并两个对象这一步，
随后撤回了：在这组对象上它必然因这三个符号报重复定义，而这不是本次 ONCE 改动造成的
（原始对象同样如此），会让门禁产生与被测改动无关的失败。

这条不是坏消息，而是把"最小链接还缺什么"钉得更准：

- 真实 kext 链接必须由构建配方保证 `_kmod_info` / `__start` / `__stop` 只定义一次
  （或者用工程自己的规则处理），而我们目前的"单 TU 编译"配方会在每个 TU 里生成它们；
- 因此链接验证不能简单地把两个 `.o` 用 `ld -r` 拼起来，必须复用工程的真实链接规则。
  这条规则是当前缺失的输入之一（见 §3 的"链接对象集"行）。

## 6. 重复定义与新增定义的核对（本轮）

- 候选 NVRM 新增的 15 个定义，在旧完整链接的定义表里**一个都不存在**（0 冲突）。
- NVRMFB 的定义集与原件完全一致（177 → 177），无新增。
- 两个候选对象之间的共享定义只有 `__start` / `__stop` / `_kmod_info`（见 §5），
  与本次 ONCE 改动无关。
