# R33：让 OGKM 修复真正进入最终候选

目标仍是 RTX 2050 正确初始化、真实离屏执行、正确像素、错误传播和安全结束。本轮只推进构建来源与两项已审查的源码修复；GPU 尚未执行，设备 NO-GO。

## R32b 独立审计结论

固定驱动源码 `051651ec0dfc43cfbb9c39534895a8fe4288f035`、run39186519502、artifact12158179549：1937个纯文本ZIP成员/1936个publication成员、1280个官方逐TU编译日志、10个NVRM C++ TU、31个NullMoth补丁往返、12个限定CPU场景/4个负控、候选链接及136布局/20接口形状已复算。最终候选runner哈希 `27ab33164927361339dbd4fac639131d945beeccdcccc4fa5bb8e59f412fd9f2`，不表示完整ABI或loader验收。

延迟队列遗漏疑点已排除：本地过时的full-build脚本只有九个C++源；远端固定源码已经包含第十个 `kms_deferred.cpp`。本次真实输入快照、对象哈希、编译命令与最终链接命令匹配，最终 `_kms_deferred_reset/push/drain/count` 均为定义且不在导入中。增强 `g1_verify_r32_native.py` 后复算通过，不能把本地过时脚本认作runner输入。

确认P1：R3空指针补丁只进入独立NVKAPI探针，完整官方KAPI对象仍是原始源码，且真实why_load确实拉入这个原始成员。历史route命令仍exit1，保留原始FAIL证据。[完整审计](R32B-NATIVE-ROUTE-NISO-20261019.md)。

## 最小实现

固定OGKM仍为 `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`，NullMoth仍为 `ac55984c473e746c2a8ebea7ba0913461aa7c393`；不替换版本、不改原始缓存。

`g1_ogkm_candidate.py` 建立明确命名的完整源码候选副本，放在CI文本采集目录之外。只允许R3与NISO两项补丁、两个源文件变化；哈希逐项固定，全部3871个文件名/内容比较，正向、反向恢复、重新应用及编译后再次比较。头文件与其他输入不得变化，拒绝符号链接和额外文件。

`g1_full_build.py` 仍从固定原树展开官方逐TU命令；仅将两个明确目标TU的源操作数换成候选副本文件，保留官方每TU flags、原始cwd、原始头路径与既有Darwin桥。其他1278个TU保持原源选择，五shader/NVLink路线不变。每个修改TU记录原始/候选双哈希、补丁身份、真实源路径、官方/实际ARGV、对象哈希和日志。不使用独立探针对象替换完整参数对象。

| 源 | 原始 SHA256 | 候选 SHA256 |
|---|---|---|
| nvkms-kapi.c | 66437bc38d96d3b4f15546c3e6f7a8c0caccc158b35893c2406f80f2e6e8816b | 7e5492e0a0961e45ea75f664d2a16c49c66d728b93b8e3e87dca3ae9ebe38200 |
| nvkms-kapi-notifiers.c | 78d310ca74ab282beec5c18d2c208ab4862d1344566f3db088017c9fe972c641 | 527df580bab9c6c0226edfdcaf3663dc2ed9d42c2151bfbf7efbc80f586c098c |

`g1_ogkm_patch_route.py` 新门禁逐项检查：候选身份、官方参数转换、真实成功编译日志、完整归档实际ARGV、最终实际链接ARGV、每个候选成员的why_load，以及 `_nvKmsKapiGetFunctionsTableInternal` / `_nvKmsKapiFreeNisoSurface` 的最终真实定义。任何缺项非零退出。保持历史无候选manifest的run返回原FAIL，不把历史改绿。

NISO补丁只有两行，把错误清理 `device->notifier` 改为传入的 `surface`。仅关闭成功路径的参数身份与重复清理错误；注销/解映射失败传播、完整Device释放语义没有修复。

## 已实际运行与待验收

本地全树候选正反向/原树只读通过：原始树 `66276173d370220c6f1ff8b140727b18291ccefcb3dc11b58ed47136ae9a22a7` → 候选树 `528d7063c36d2643e5f08b4422f58b589c638ae7caa69b6d59b5bff2b602ed3d`，3871文件，仅两源变化。WSL现有g++运行候选真实NISO函数合同，3/3通过，compile0/run0。原版3FAIL与编译负控已保留在niso-owner-evidence。

工具测试：候选delta两项、route两项（包含错误源/参数/cwd/失败编译/漏归档成员/缺定义/换链接/失败nm负控）、full-build11项、full-ABI12项通过；历史回归10/10、5/5、7/7通过。模拟工具fixture不是驱动编译证据。

**R33 Darwin/最终候选路线尚待本轮CI执行。** 既有R32b成功不替代R33。工作流仅CPU测试/原生编译/链接和文本取证，无签名/安装/加载/GPU操作。发布后触发已获授权的手动类型workflow_dispatch；结果单独记录commit/run/artifact，不预填成功。

## 持续断点与 NO-GO

正常close eventBusy无界join、P0-4 KMS拒绝但上层仍销毁Device、RM门忙仍STANDBY继续FAIL；容量64溢出、open rollback漏队列、计数差值、模块卸载仍开放。R32a只保wrapper的异步正常close设计已经撤销，不能复用其绿色run作安全证据。

本轮CI若通过，只关闭“这两项补丁实际进入官方参数归档及最终链接”的来源缺口。下一步沿真实FreeDevice/KmsFreeDevice调用链处理完整Device所有权和可失败的关闭传播；不能把void末尾记录失败当成停止了析构。RTX2050初始化、GPU执行、像素读回和安全结束尚未运行，仍然不能提供可部署驱动。

回退限于本轮指定文本修改或回到原始源选择；不得通过删除FAIL、使用旧对象/探针对象、放宽参数比较来回退。没有新建分支/worktree、没有.agent写入、没有设备或系统修改。


## 发布后的复核与当前运行

驱动构建源码已推送 `7a5cb7188ef6477b7383f9529228bbb4426aa1fd`；[run39189188122](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39189188122)已按授权触发，最近查询仍排队、未分配runner。没有R33原生完成结论，等待真实日志及文本产物后才能验收。

检查工具随后补强两点，均不改本次驱动输入：缺少完整候选manifest时，即使单个探针源相同也必须exit1；离线复核使用PurePosixPath保留runner路径身份，避免Windows路径分隔符造成误判。三项route测试（包含多种负控）在Windows与WSL Python通过；不能用修改元数据的工具fixture当原生编译。当前CI使用7a5cb71中的检查工具，后续产物还要用补强后的工具独立复算，无需因此重复1280编译。

对本轮R3候选真实FreeDevice再运行backend-refused合同：源码7e5492e0...、OS7d86b6b...，compile0/run1；backend_close0、wrapper_free0、queue1、RM_free1、Device_free1。这是关闭拒绝仍继续销毁的CPU反例，非内核UAF观察；本轮源码修复没有关闭P0-4。证据见[r33-followup-evidence](r33-followup-evidence/)。

下一接手点是读取此run的真实状态和产物：失败仅按第一条错误修；成功则用当前route工具复核双源/官方参数/归档成员/最终定义并保存结果。若runner继续排队，不重复触发，不写成编译失败或成功。确认来源后再实现完整Device生命周期，不能用void close尾端补丁冒充停止了上层析构。
