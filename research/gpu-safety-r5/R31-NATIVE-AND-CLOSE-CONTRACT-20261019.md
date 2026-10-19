# R31 原生交付与真实关闭函数合同

R31 实际补丁已通过原生对象与完整候选链接；设备安全与 GPU 运行仍未验收。驱动源码固定 `bc8e1d56343483e695cd47b414b0adcb669bedf8`，证据提交另行快进，不混淆二者。

[run39184119617](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39184119617)，artifact12157153122，ZIP SHA256 `5fcdb6ae035ceafb22ace2362ba0d52118a7f53d9098789bf5936c996de51578`。下载后逐项验哈希：1851个ZIP纯文本成员，1850个publication成员；未下载或上传驱动二进制。

## 已验证

- 31个native补丁记录：30个NullMoth补丁加OGKM适配；完整序列正向/反向恢复原树。
- 十个NVRM C++ TU均成功。实际R31队列单元与本次原生对象依赖快照绑定，去重/回调重入/容量拒绝的CPU合同均通过；容量拒绝不等于溢出资源已回收。
- 官方1280个C/C++ TU（1240C/40C++）全部成功，逐条读取1280份真实编译日志，命令与report一致且最终exit0；另五个shader payload和独立NVLink后端进入完整候选。
- 完整NVRM候选链接exit0，runner记录的SHA256 `39653e55198431d577522e51848550635e405ca176cc932a78ffa02aab65d95a`；472个导入。此哈希来自runner对产物的真实计算，本地只复核文本绑定。
- 六profile136布局值/20函数形状通过；不构成完整ABI/loader验收。

原始文本与绑定：[r31-native-evidence](r31-native-evidence/)。此前PCI六方法和发布物free虚表差异的独立复算见[调用链报告](CALLERS-FREE-R30-R31-20261019.md)。

## 继续向真实关闭路径推进：两例失败保留

新增 `tools/g1_kms_close_contract.py` 从完整真实源码提取 `kms_pm_wait_locked`、`kms_close_common`、`kms_deferred_close_impl`、`kms_deferred_try_free_impl`，连同实际R31队列编译运行。OS源码SHA256 `071567c3ea376a612a6e65b75dcc2bab2bfa6e69d86e78e53e42fc4d9814fb72`，与真实原生快照一致。IOKit/NVKMS服务是注入边界，每个场景独立新进程；不真实释放内存，不运行内核。

| 场景 | 结果 | 真实观察 |
|---|---|---|
| 挂起期间close超时 | PASS | 后端close0、wrapper free0、入队1，真实等待走deadline |
| 延迟close后恢复 | PASS | 后端close1、wrapper free1、队列归零 |
| 正常close，thread_call_free失败 | **FAIL** | 后端close1、wrapper free0、队列0：保留的wrapper未被新队列跟踪 |
| eventBusy持续不结束 | **FAIL** | 真实try_free循环再次无界sleep；测试边界第三次sleep主动中止，未等待系统卡死 |

后两例的命令实际exit1，未折算为“预期失败所以全部通过”。这是CPU注入合同，停滞回调用测试异常终止，不证明真实XNU死锁、调度时序或可触发UAF。R31只修队列独占，未宣称修复这两条集成路径。[原始结果](r31-native-evidence/close-integration-cpu/report.json)。提取代码保留原版权/SPDX，许可证与NOTICE见 [NullMoth许可证](../gpu-safety-20261017/licenses/NullMoth-LICENSE.txt)及[NOTICE](../gpu-safety-20261017/licenses/NullMoth-NOTICE.txt)。

## GO/NO-GO 与下一断点

RM门忙后仍进入STANDBY继续为**31/32 FAIL**；P0-4、延迟close最终回收、容量耗尽、回调等待/PM交错、计数合同仍开放。没有安装/签名/加载/卸载kext，没有设备初始化、GPU命令执行、正确像素或安全结束实测。Intel基础显示保持；不扩大显示所有权。

下一实质改动以以上失败合同为起点，补正常close释放失败的可追踪所有权，并让回调等待有界且保留可重试资源；必须核对恢复线程/RM门顺序和回调引用，不能用简单计数或删等待制造PASS。完整构建已验证，不再重复源码存在性或首次1280编译。目标保持active，真实GPU闭环未完成。

本轮复盘：对象/IR/外部重定位解释调用来源；完整编译日志验证构建；可执行合同暴露关闭缺陷。三者各回答各自层级，绿色链接不能代替安全结束。
