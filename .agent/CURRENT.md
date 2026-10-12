# 当前断点

## 当前阶段
R1.4-C0-pre SOURCE-STATIC部分结果；完整联合namespace仍BLOCKED，RUNTIME_NO_GO。

## 当前任务
R14C0PRE blocked；两个iasl版本联合16表均AE_ALREADY_EXISTS退出255。
R14C0既有接口/许可/配置闭包保持blocked，不进入native/kext。

## 已完成工作
同步PR1硬件调查195e465；原证据不改。36表SHA/长度/checksum一致。
固定iasl20250404-1容器解析；单表16通过0失败，离线6通过0失败。
34项findings、17个DD_ADR方法体、98项IGDM字段、T2平台映射。
MXDS空分支、MXMX调试、MXM读NVS；IGD另有经EDMX的位操作；MUX无法判断。
BSD两个ACPI桥接函数为空，不能继承为XNU实现。OpRegion/VBT内容未取得。

## 当前阻塞
联合namespace冲突/外部方法与运行条件UNKNOWN；ASLB初始化者、DME值、GPIO含义未知。
完整源码/许可/实际配置/ACPI-PCI映射与通知消费者/电源退出合同未闭合。
无驱动对象/加载/实际scanout/WindowServer/恢复证据。

## 下一步动作
仍为R1.4-C0 T0→T4：T0复核namespace冲突；T2引入本机声明，补真实evaluator/ASLS映射/内容/消费者合同。
不读主力硬件、不触发Actions、不写假成功stub。

## 状态修订
以state.json/tasks.json为准，写入前status。

## Git 检查
起点8d133330（保留本地C0历史并同步已合并硬件原表），同main本地提交，不改写历史。
原调查目录/旧实验/workflows不改；临时解析容器已删除；没有推送或合并PR。
