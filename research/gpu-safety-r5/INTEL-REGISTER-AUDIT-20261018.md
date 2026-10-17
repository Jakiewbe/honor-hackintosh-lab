# Intel 寄存器常数审计（2026-10-18）

对照对象：Linux `v6.1` 固定 commit `830b3c68c1fb1e9176028d02ef86f3cf76aa2476` 的
`drivers/gpu/drm/i915/i915_reg.h`（已存 `reference/i915_reg_v61.h`，358,525 B）。
被审对象：`kexts/NMIntelFB/intelfb.cpp` 第 50–67 行的常数表。

## 1. 已核对一致（可复核）

| 驱动定义 | i915 v6.1 定义 | 结论 |
|---|---|---|
| `PLANE_CTL(p) 0x70180 + p*0x1000` | `_PLANE_CTL_1_A 0x70180` | 基址一致 |
| `PLANE_STRIDE(p) 0x70188` | `_PLANE_STRIDE_1_A 0x70188` | 一致 |
| `PLANE_SIZE(p) 0x70190` | `_PLANE_SIZE_1_A 0x70190` | 一致 |
| `PLANE_SURF(p) 0x7019C` | `_PLANE_SURF_1_A 0x7019c` | 一致 |
| `HTOTAL(t) 0x60000` | `_HTOTAL_A 0x60000` | 基址一致 |
| `FRMCOUNT(p) 0x70040` | `_PIPEA_FRMCOUNT_G4X 0x70040` | 一致 |

也就是说：**A 管/转码器上的六个基址全部正确**，没有写错偏移。

## 2. 未能核实（BLOCKED，本轮不下结论）

驱动用 `+ p*0x1000` 线性推出 B/C/D 的偏移。但在 i915 v6.1 里，这些寄存器是通过**偏移表**展开的：

```c
#define _MMIO_PIPE2(pipe, reg)  _MMIO(INTEL_INFO(dev_priv)->display.pipe_offsets[(pipe)] -
                                      INTEL_INFO(dev_priv)->display.pipe_offsets[PIPE_A] + ... + (reg))
#define _MMIO_TRANS2(tran, reg) ... display.trans_offsets[(tran)] ...
```

`pipe_offsets[]` / `trans_offsets[]` 的**实际取值**在显示设备信息表里，本轮两次尝试获取都被拦：

- `raw.githubusercontent.com` 首次 429（限流），重试成功取到 `i915_reg.h`；
- `display/intel_display_device.c` 路径 404（该文件在 v6.1 里叫别的名字，需先定位）；
- `git.kernel.org` 返回反爬挑战页，不可用。

**因此"管 D / 转码器 D"的线性假设没有被验证。** i915 历史上 D 转码器的基址不是线性的
（存在 `_TRANSCODER_D` 专用偏移），如果实机上固件把面板放在 D，这段 `for (p = 0..3)` 会读到
0x63000/0x73008 一类错误地址，可能误判或读到垃圾。

**这不是"发现 bug"，是"发现未验证"。** 在没有偏移表之前，不能据此改代码，也不能据此排除风险。

## 3. 关闭这一项需要什么

1. 取到 i915 v6.1 的 `pipe_offsets[]` / `trans_offsets[]` 表（正确的文件路径或镜像）；
2. 或者实机只读：用 `-nvfbsurvey` 式的只读寄存器快照（当前 `intelfb.cpp` 已有 `-nvfbsurvey` 打印 BAR 结构），
   把 `p=0..3` 的 `TRANSCONF/PLANE_CTL` 原始值打出来，看哪个 pipe 真的有 enable 位。
   这属于实机操作，需要授权。

## 4. 审计结论

- **能核的都核了**：A 管/转码器的基址与 i915 v6.1 完全一致；
- **核不了的明确标出**：D 管的偏移表未取得，"线性 +p*0x1000"属于未验证假设；
- 本轮**没有**改动代码——在未取得偏移表之前改常数等于凭猜测写硬件地址，违反项目规则。

## 5. 证据

- `reference/i915_reg_v61.h`（358,525 B，来自 `torvalds/linux` @ `830b3c68`）
- 审计对象：`kexts/NMIntelFB/intelfb.cpp:50-67`（`constexpr` 偏移表）与 `adoptFirmwareMode()`（读取路径）
