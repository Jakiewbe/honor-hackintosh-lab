# 网页端独立审查 prompt：R35真实失败与R36直接关闭结果

请只读审查 https://github.com/Jakiewbe/honor-hackintosh-lab ，固定本文所在完整commit。先读 R36-R35-AUDIT-TRY-FREE-20261019.md、r36-local-evidence/、ACCEPTANCE-MATRIX-20261018.md。目标为RTX2050初始化→真实GPU执行→正确像素读回→错误传播→安全结束，Intel保留基础显示；设备始终NO-GO。本审查不授权修改仓库、触发Actions、发送上游消息或操作设备。

核对R35 run39207578260/source393d00b5899c84b74309c2fd4ab16919b63f9271/artifact12166357598，ZIP a5552c7f240dbe55905824c9ae0a07436000edf2f3d1178615713e205ee7968d：1280尝试、1279成功、KAPI缺bFreeCompleted字段，未归档/未链接。不要再称artifact凭据阻塞或推断CHAIN导致本次编译失败。

审查两份R36补丁、g1_ogkm_candidate.py、g1_full_build.py、g1_ogkm_patch_route.py、native_compile.py与正式native workflow。核对不改公开表布局；直接返回try-free结果，成功后无Device解引用；FREE_DEVICE及per-open拒绝保留Device/creator/句柄；drop/orphan两个真实调用者都消费结果，kapiInit不复用部分关闭孤儿。完整官方逐TU参数/cwd必须保留，R3→R36叠加的pre/post及正反重放逐步受约束；历史R33复算仍可用。独立probe的源不等于最终官方参数对象，不得混称。

检查g1_r36_try_free_contract.py是否实际提取固定三源完整函数、真实new/delete＋ASan，12场景是否能发现拒绝路径丢owner/重复free；IOKit/锁/NISO/RM/backend注入的局限是什么。检查g1_r36_controls.py将历史R35 free改成真实delete后确实因post-free查询触发ASan；不能据CPU负控宣称实机UAF。#error负控需无二进制、无场景执行；不能跑旧产物。旧R35工作流与工具须exit2并停止上传二进制；正式门禁必须只发布文本。

不要将R36当作全部P0-4解决：重点沿真实KmsFreeDevice检查callback静默是否早于NISO销毁，注销/解映射失败是否传播；legacy/allocate失败完整owner、回收、容量64、锁序、PM忙→STANDBY及无界join仍有何漏洞。为下一轮给出最小可实现的“入口先静默、拒绝保留owner、成功恰好一次”合同与反例，避免再增加只验证计数的模型。

按P0/P1/P2列出固定commit文件/行号、触发条件、后果、建议和证据局限。若native结果尚未归档，明确原生未验收、导入数未知；若已有结果，逐项读文本而非只看总绿。最后用几句话回答真实驱动适配到了哪一层、离GPU闭环还缺什么，不以审计轮次代表加速完成度。
