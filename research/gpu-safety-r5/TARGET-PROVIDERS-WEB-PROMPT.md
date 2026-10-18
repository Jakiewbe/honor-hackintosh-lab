# 网页端独立审查：472项导入的提供者证据

请只读审查Jakiewbe/honor-hackintosh-lab本轮TARGET-PROVIDERS-20261018.md、tools/g1_target_providers.py、对应测试、g1-target-providers.yml以及报告注明的原生run文本证据。原始目标为HONOR GLO-FX6P RTX2050初始化→真实GPU渲染→正确像素读回→错误传播→安全结束，Intel基础显示所有权保持；设备NO-GO。

重点查：472导入是否绑定历史完整候选而非同run伪称重建；Mach-O下划线、函数/数据/间接符号是否混淆；解析失败是否被当成成功；文件hash、精确命令与bundle版本是否对应真实观察；内核全局定义、SDK声明/导出名单、系统KPI符号集、IO家族全局定义及用户目标系统导出是否混成一层；runner是否冒充最终目标系统；符号同名是否被说成完整C/C++ABI一致。指出真实缺陷、源码位置、影响与最小修复，不扩展设备权限，不要求加载或改EFI。给出下一项可在源码/CPU/原生编译/链接/只读文本CI完成的实质动作。


本轮实测入口：[run 39130439405](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39130439405)，源码1a481ba2d5a57ada56648eb7a1ae25868fc90861；原生采集器9项通过。新增tools/g1_provider_evidence.py及6项Windows测试是离线解释原生文本，不宣称其已在Darwin运行。请从原始nm、otool、符号集XML/节绑定、两份family.exports和固定源Info.plist独立复算464/8与14项别名，不只信native-result.json或作者数字。检查12个SymbolPrefix和那个带尾空格的resourcesEv是否被错误当成精确导出；当前结论是未计入。两项内容破坏负控已执行。仓库有消费文件与原始manifest；未消费的kc-prelink-raw.json保留在artifact，不能把它称完整artifact仓库副本。

下一步请具体评估如何只读证明余下7个IOPCIDevice和1个IOACPIPlatformDevice在Intel Kernel Collection中的定义及C++ ABI，避免把family导出名单、KPI名称、版本门槛和运行闭环合并。保留初始化/渲染/读回/关闭未验收、设备NO-GO。不要重复已完成的1280TU完整构建或重新审计NVLink四锁是否有提供者。
