# 链接门禁审计修复

固定审计基线：`b97785ea020349a5441ae416c1724363388f1e40`。上游仍为
NullMoth `272ccd9da04ff5de95c2791b902fe17a3fa77ce7`、OGKM
`e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`；两个候选源码和补丁身份不变。

目标：让对象缺失、编译失败和链接失败可靠地终止门禁，保留原始错误和文本报告。
假设：固定 OGKM Makefile 的 `ALL_SRCS`/`BUILD_OBJECT_LIST` 可提供完整对象清单，
直接请求这些对象目标无需执行不兼容的最终 ELF 链接。该假设须在 Darwin CI 验证。

修改范围：编译/链接工作流及专用脚本、负控、ONCE 语义测试、相关说明。
不修改驱动候选、固定取证输入或 `.agent`，不安装、签名、加载或执行驱动。
回退为撤销本轮门禁文件修改；历史 run 39498653458 的真实成功证据继续有效。

验收：精确的 source→object 清单；必要对象缺失为失败；编译器/链接器错误返回非零；
失败报告仍上传；SDK/部署目标明确；负控使用同一验收函数，旧产物不能被消费。
绿灯仅代表链接探测成功，外部导入/KPI/依赖/ABI、加载、GPU 运行不随之验收。

## 审计发现

- 旧工作流 TU 编译失败仍显式 `exit 0`，链接失败分支未返回错误。无文件写入的 shell
  模拟已复现 `link_exit=1` 但最终退出 0。历史真实链接 exit 0 不因此撤销。
- 1055 才是实际 RM 对象数；3167 是输出目录所有条目数。
- 最终 493 项导入不同于两个单 TU 的 468/478 项集合，尚未完成逐项可绑定性验证。
- 普通 ALLOC/ONCE call 的 free 不等待运行结束；ONCE 保证同一 call 执行不重叠，
  不等于停止屏障，也不保证参数生命周期。
- 三个相关工作流均曾带 push 触发器。本轮恢复为 workflow_dispatch。

## 本轮结果

本地 `python -m unittest discover -s tests -p 'test_stock_v24*.py' -v`：56/56。
包含14项新增验收路径测试、既有35项诊断/符号检查、7项ONCE检查。ONCE参考模型已纠正：
运行中 enter 置 RESCHEDULE；cancel 可清除并返回 true，但不等待当前回调；未取消时 finish 后重新入队。
同一 call 不重叠。第一次审计/提交6c8783b曾错误沿用“cancel无法清除”推断，现明确撤回，
按固定XNU thread_call_cancel_locked L1347–1352 纠正文档和参考模型，不影响门禁失败传播代码。

在明确命名的临时 OGKM 副本上，现有 WSL make 实际展开官方 ALL_SRCS/BUILD_OBJECT_LIST：
1055项清单通过新解析器。只展开清单，没有编译驱动；原始输入未改。
三个配方文件 SHA256 从固定 Git blob 计算，未使用 Windows CRLF 检出的字节。
三个 workflow YAML 均可解析，触发器均只有 workflow_dispatch。

最终493项导入的文本产物SHA256已绑定，逐项矩阵见 FINAL-IMPORTS-BASELINE-20261021.json。
名称归属为469历史KPI+定义、8历史IOFamily名单、12未集成NVKMS、4缺失NVLink OS后端。
未将历史runner的定义观察提升为用户设备可绑定性或ABI证明。

提交前状态（已由下节实测更新）：当时新的 Darwin 编译/链接待验收；真实编译器/链接器负控仅在原生CI中执行。
本地负控使用实际非零Python进程及验收函数故障注入，不能冒充Darwin负控。
新SDK/部署目标均为15.5，结果不覆盖15.0–15.4。
下一步先验收修复后的门禁，再按12+4项内部导入缺口做明确集成，不追求数量相近。
设备 NO-GO。

## Darwin 实际验收

运行 [39526958107](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39526958107)，
workflow_dispatch，源码提交 `6c8783be4470efe74637ef3fef71013914af1342`，success。
文本产物12312664213，896099 B，SHA256
`0da1e48e05354154b801509e329ada2bb1bbf9d802876d7bfde49aa74eac894a`，下载后已复核。

| 项目 | 实际结果 |
|---|---|
| CI验收路径检查 | 14/14 |
| 真实编译失败负控 | exit1，被拒，旧对象已删除 |
| 必要对象缺失负控 | 被同一对象集检查器拒绝 |
| 真实链接失败负控 | 确实到达ld；非法选项使exit1，被拒，旧产物已删除 |
| RM make | 只请求对象目标，exit0，不再容忍末端ELF链接失败 |
| RM对象集 | 1055/1055，均为x86_64 MH_OBJECT，逐项哈希保存 |
| NVRM源码/对象 | 12/12，编译全部exit0，传递依赖及输入前后校验通过 |
| 新链接 | exit0，x86_64 MH_KEXT_BUNDLE，16185000 B |
| 新二进制SHA256 | `562b365a9c7233d165e14f1fb52243670937b41264f3b12de0bd7d3fecf8445c` |
| 最终导入 | 493，分类仍为469/8/12/4；内部16项缺口尚未集成 |

SDK与部署目标均为15.5，ld日志无旧15.0/15.5版本告警。
驱动编译日志仍有537条warning行：RM406行、NVRM各TU合计131行。
NVRM每TU的消息/类别多重集与旧run相同；RM并发输出有交错，不能由行数相同推断诊断增量为零。
这是诊断观察，不是全量诊断准入或完整ABI验收，不能宣称零告警或全量零增量。

证据保存于 [gate-repair-evidence/review.json](gate-repair-evidence/review.json)，
并保存RM对象清单、真实链接ARGV、失败负控、最终导入和64个原始文本成员哈希。
不保存/上传驱动二进制。本轮失败即停止门禁的Darwin路径已验收。

另行纠正的ONCE cancel语义只涉及文档/参考模型，未改门禁构建脚本或驱动候选；
56项本地检查已按固定XNU正确语义重跑通过。历史6c8783b文本中的错误不作为事实。

复盘：对象清单应来自固定Makefile；进程失败须贯穿顶层退出；源码分支必须读完整，
不能由摘要或函数片段推断cancel行为。下一断点为12项NVKMS配对归档与4项真实NVLink锁后端，
使用明确来源和同run导入/定义差分验收，不恢复无关补丁扩展。设备仍NO-GO。
