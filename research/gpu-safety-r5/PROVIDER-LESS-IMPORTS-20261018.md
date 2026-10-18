# 42 个无提供者导入的分类结论（R47）

对象：链接后 `NVRM.kext` 的 514 个导入里，无法由 kernel/IOKit 解析的 42 个。

## 分类

| 家族 | 数量 | 在固定 OGKM 树中 | 在我们树中 | 性质 |
|---|---|---|---|---|
| `_nvKms*` | 8 | **有定义**（`src/nvidia-modeset/nvkms.c`，如 `nvKmsOpen` L5344、`nvKmsClose` L5254、`nvKmsSuspend` L6873） | — | **未纳入构建**，可补（需引入 nvidia-modeset） |
| `_nvKmsKapi*` | 4 | **无** | 仅调用点（`os-nvkms-xnu.cpp` L201/L260/L293） | **结构性缺口**（公开树无定义） |
| `_nvrm_*` | 7 | — | 定义在 `kexts/NVRM/nvrm_pageoff.c` | 可补但**门禁编不了**（C/C++/加宏三次失败） |
| `_rm_*` | 23 | **无**（`src/nvidia` 无匹配定义） | 不在 `kexts/NVRM` 根目录 | 需继续定位（可能是 NullMoth 的另一层 glue） |

## 已经能下的结论

1. `_nvKms*`（8）与 `_nvKmsKapi*`（4）**不是一回事**：前者有公开源码，后者没有。此前把 12 个合并称为"可补"是错的。
2. `_rm_*`（23）既不在 OGKM 的 `src/nvidia`，也不在 `kexts/NVRM` 根目录——说明还有一层我没定位到。**未下结论**。

## 下一步

1. 在**整棵** NullMoth 树（不限 `kexts/NVRM` 根）检索 `rm_init_rm` 等定义位置；
2. 若在 `kexts/NVRM/<sub>/`，判断该 TU 能否进门禁；
3. 若整棵树都没有，则与 `_nvKmsKapi*` 同类，归为结构性缺口。

## 边界

本文件是**检索结论**，不是构建结论。除"8 个 `nvKms*` 在 OGKM 有定义"外，其余均为"未找到/未定位"，
不构成"不存在"的证明。
