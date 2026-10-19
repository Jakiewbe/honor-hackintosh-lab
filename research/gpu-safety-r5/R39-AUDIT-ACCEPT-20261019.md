
# R39：接受独立审计结论与本轮修正（2026-10-19）

基线 8be05d95c83c29d8233f5bbcd40beb27f9532fae 的独立审计给出 **NO-GO**，并列出 5 项 P0、5 项 P1/P2。
我逐条核对，**全部接受**，本轮修掉其中属于我的两处工具/草案问题。

## 一、已确认成立的缺陷（接受，不辩解）

| 编号 | 结论 | 我的核对 |
|---|---|---|
| P0-1 | R36 先释放 NISO、后 FREE_DEVICE、最后才 quiesce | 我用 check-kapi-free-order.py 在干净 R36 上复现为 **FAIL**（quiesce absent；NISO 13/71 < ioctl 376） |
| P0-2 | 我的 R37 草案在 commit 已成功后再调 suspend_abort 是**空操作**，且把 GpuPm 改回 Running 会让唤醒跳过 NVKMS resume | 已核对候选源码：suspend_abort 仅在 gKmsSuspendPending && seq 匹配 时生效（374-385），而 commit 已把 pending 置 false（364）→ **成立** |
| P0-3 | RM busy 后仍 STANDBY | check-pm-exclusion.py 31/32、exit 1，未变 |
| P0-4 | allocate 失败与 legacy oid 路径没有可靠 owner | 与 R36 文档"未闭合"一致 |
| P0-5 | legacy 正常关闭仍有无界 IOLockSleep 等 eventBusy | 源码事实 |

## 二、本轮修正的两处（都是我的问题）

### 1. 顺序检查器的假阳性（P1）

审计给出的可复现负控成立：只含一次 quiesce 的 KmsFreeDevice 会 **PASS**（exit 0）。
我已重写 	ools/check-kapi-free-order.py：

- 先剥离 // 与 /* */ 注释，注释不能充当步骤；
- 四个步骤（quiesce / FREE_DEVICE / NISO semaphore / NISO notifier）必须**各出现且仅出现一次**，
  缺失或重复一律 FAIL；
- 顺序要求 quiesce < FREE_DEVICE < 两个 NISO；
- FREE_DEVICE 必须被 if (!nvkms_ioctl_from_kapi …) 守卫；
- 新增 --self-test：complete / incomplete / comment_only / reversed / duplicate / unguarded 六个控制。

**结果**：自检 6/6；审计给的不完整输入从 PASS 变 **FAIL**（缺 3 步）；干净 R36 仍 **FAIL**；
R38 草案应用后 **PASS**。

### 2. 检查器没有接入门禁（P1）

新增 	ools/test_check_kapi_free_order.py，把自检与两条断言包成 unittest。
门禁的 unittest discover 会执行它：本轮 3 tests、**OK**。
这样"检查器仍然拒绝不完整/重复/注释/未守卫/逆序输入"变成阻塞项，而不是靠人记得跑。

### 3. R37 草案已撤下

draft-r37-refuse-standby-when-busy.patch → ttic/withdrawn-r37-refuse-standby-when-busy.patch。
原因即 P0-2：它不是"不完整"，而是**错误**——在 commit 之后 abort 无效，只改 GpuPm 会让
RM/NVKMS/XNU 三方状态分裂。重做前必须先写出 commit → RM busy → abort/recovery → wake 的完整状态机。

## 三、仍未做（与审计一致）

- P0-1 修复（R38 草案）未合入，且**检查器 PASS 不等于关闭安全**；
- P0-4/P0-5 未处理；
- 安全合同未接入阻塞型 CI job（只接了检查器自检，不是 check-pm-exclusion）；
- 472/471、8 KC 符号、六个 PCI 方法仍只是"名称/调用侧"证据，不是 loader/ABI 验收；
- 构建成功 ≠ 可加载，KEXT-LOAD 及以上 NO-GO。

## 四、我对自己表述的修正

- 不再把"1280 TU + 链接成功"称为"构建到顶"；
- 不再把 R37 当作可用方案；
- 不再用"检查 PASS"暗示"关闭安全"。
