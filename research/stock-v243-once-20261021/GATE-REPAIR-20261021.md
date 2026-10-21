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
运行中 enter 置 RESCHEDULE，普通 cancel 无法清除，finish 后才重新入队；同一 call 不重叠。

在明确命名的临时 OGKM 副本上，现有 WSL make 实际展开官方 ALL_SRCS/BUILD_OBJECT_LIST：
1055项清单通过新解析器。只展开清单，没有编译驱动；原始输入未改。
三个配方文件 SHA256 从固定 Git blob 计算，未使用 Windows CRLF 检出的字节。
三个 workflow YAML 均可解析，触发器均只有 workflow_dispatch。

最终493项导入的文本产物SHA256已绑定，逐项矩阵见 FINAL-IMPORTS-BASELINE-20261021.json。
名称归属为469历史KPI+定义、8历史IOFamily名单、12未集成NVKMS、4缺失NVLink OS后端。
未将历史runner的定义观察提升为用户设备可绑定性或ABI证明。

新的 Darwin 编译/链接待运行与验收；真实编译器/链接器负控仅在原生CI中执行。
本地负控使用实际非零Python进程及验收函数故障注入，不能冒充Darwin负控。
新SDK/部署目标均为15.5，结果不覆盖15.0–15.4。
下一步先验收修复后的门禁，再按12+4项内部导入缺口做明确集成，不追求数量相近。
设备 NO-GO。
