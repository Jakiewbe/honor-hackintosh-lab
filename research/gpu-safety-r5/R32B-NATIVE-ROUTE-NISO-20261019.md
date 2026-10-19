# R32b原生通过；OGKM补丁未进入最终对象与NISO参数错误

R32b限定修改已通过原生与完整候选链接，关闭安全仍未验收。复核后新确认一项构建来源门禁缺陷，并给出独立的两行NISO候选；没有触及设备。

## 已确认的构建结果

驱动源码 `051651ec0dfc43cfbb9c39534895a8fe4288f035`；[run39186519502](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39186519502) success，artifact12158179549，ZIP SHA256 `60e8b9a7cf1edc0400ac76f99648934a6cbe166a295c24c0d2665467af617ff6`。纯文本1937个ZIP成员、1936个publication成员逐项核验。

31个NullMoth补丁完整正反向恢复；十个NVRM C++ TU通过。native报告共有32个补丁记录，其中另一个OGKM R3仅用于单对象探针，**不代表它已进入完整链接**。R32b的12个限定CPU场景与本次实际OS/queue对象依赖快照绑定；四负控和四结构检查通过。正常busy join另为FAIL，不计入12项。

官方1280个C/C++ TU（1240C/40C++）、五shader与独立NVLink后端进入完整归档和候选链接；逐条复核1280份真实编译ARGV/exit。最终候选SHA256由runner计算为 `27ab33164927361339dbd4fac639131d945beeccdcccc4fa5bb8e59f412fd9f2`，472导入；六profile136布局值/20形状通过。这里只复核文本与产物身份绑定，未下载驱动二进制，未验收完整ABI/loader。

证据：[r32b-native-evidence](r32b-native-evidence/)。复算：`python tools/g1_verify_r32_native.py --artifact-dir <完整纯文本产物目录> --run-meta <GitHub独立读取的run元数据> --out <新目录>`。源码局部细节与未解决项见[R32b说明](R32-CLOSE-RETRY-20261019.md)。

## P1：OGKM R3仅探针生效，完整候选未包含

`native_compile.py`建立稀疏OGKM候选并将`ogkm-r3-kapi-null-free.patch`用于NVKAPI探针。完整构建`g1_full_build.py`从固定原树生成官方命令，编译后归档；其baseline筛选只引入NullMoth的NVRM对象和两个局部C对象，没有取该探针对象或候选源。

同run证据：探针候选KAPI源码SHA256 `7e5492e0a0961e45ea75f664d2a16c49c66d728b93b8e3e87dca3ae9ebe38200`；完整归档实际源码仍为原始 `66437bc38d96d3b4f15546c3e6f7a8c0caccc158b35893c2406f80f2e6e8816b`。真实链接`-why_load`记录 `_nvKmsKapiGetFunctionsTableInternal`拉入`libnvidia-modeset.a(nvidia-modeset-nvkms-kapi-3a32632a4dc98297.o)`。因此不是“对象碰巧未使用”，而是实际选中了未打补丁的对象。

`tools/g1_ogkm_patch_route.py`核对两份源哈希、真实编译日志和实际归档拉入，**exit1 / FAIL_PROBE_PATCH_NOT_IN_FINAL_SOURCE**。见[r32b-ogkm-route-evidence](r32b-ogkm-route-evidence/)。不撤销完整构建成功，不把32条native补丁记录混称为32个进入最终候选的补丁；该门禁当前尚未接入workflow。

下一实质工作先把明确OGKM候选源纳入官方逐TU编译，再核对完整归档/最终链接。固定原始输入继续只读，记录原始/候选源码双哈希和补丁身份，不用探针对象替代官方参数对象。

## P1：NISO释放函数清错对象，已给出未原生编译候选

固定OGKM `nvkms-kapi-notifiers.c` SHA256 `78d310ca74ab282beec5c18d2c208ab4862d1344566f3db088017c9fe972c641`。`nvKmsKapiFreeNisoSurface(device,surface)`处理传入surface，却在注销/解映射后清`device->notifier.hKmsHandle`和`device->notifier.mapped`。`KmsFreeDevice`先传semaphore再传notifier：前一次会误改另一个对象，后一次跳过其注销和解映射；再次清理semaphore仍会重复工作。

用真实完整函数与成功返回的CPU边界复算：原始参数身份、顺序释放、重复释放三项均FAIL，命令exit1；只将两处字段改为`surface->...`的候选三项PASS、exit0；非法语句负控编译失败，无二进制、未执行。重复释放断言使用调用前后的计数差，不用固定总数避免前一步漏清理抵消后一步重复清理。

[两行补丁](ogkm-niso-surface-owner.patch)，SHA256 `e6f4293d09e6d24414a4cd1faba90be2a88ad8dc9f5b15817ab548ac207fb508`；候选源SHA256 `527df580bab9c6c0226edfdcaf3663dc2ed9d42c2151bfbf7efbc80f586c098c`。独立命名候选副本，正反向逐字节恢复原始/候选；[证据](niso-owner-evidence/)，工具`g1_niso_surface_contract.py`。保留NVIDIA版权/MIT许可。

**此补丁未接入native/full build、未原生编译链接。** 仅成功路径参数身份修复；注销/解映射失败后仍清字段、RM释放错误、Device整体销毁失败传播均未修，不把3/3当完整清理安全。

## 已知P0-4补强与仍失败的合同

`g1_kapi_close_owner_contract.py --scenario backend-refused`提取真实固定OGKM FreeDevice/KmsFreeDevice与事件函数，注入KMS释放拒绝后，真实函数仍走到RM/Device销毁；CPU计数backend close0、wrapper free0、queue1、RM free1、Device free1，编译0/运行1。见[原始失败](r32b-close-evidence/device-owner-contract/backend-refused/)。这是已知P0-4新增可执行证据，不是已观测内核UAF。

正常callback join依然无界，真实CPU命令exit1；初稿只保wrapper的异步正常close已撤销。RM busy仍STANDBY保持31/32 FAIL；容量64溢出、open rollback漏队列、计数差值合同、完整Device/creator引用仍OPEN。全局worker只按模块寿命设计，未支持卸载。

## GO/NO-GO与接手断点

源码/限定CPU/原生对象/完整链接：以上分别有证据；OGKM补丁路线门禁FAIL；NISO仅局部CPU候选。KEXT-LOAD及以上全部NO-GO，GPU初始化、真实执行、正确像素与安全结束均未运行，Intel基础显示保持。没有签名、安装、加载、卸载或设备测试。

先修官方构建的OGKM候选来源与验真门禁，将R3空指针修复及NISO两行修复真正纳入最终归档；再推进FreeDevice入口的callback准入、完整Device所有权与可失败的析构传播。不能只改void close末尾，不能把已有FAIL删除来让CI变绿。

复盘：真实函数CPU合同暴露生命周期边界；编译日志与why_load暴露最终源选择。构建成功和补丁进入最终产物是两个不同验收条件，本轮都保留原始记录。

R33后续：队列遗漏疑点已通过实际编译快照/最终ARGV/四项定义排除；官方OGKM双补丁候选路线已实现，本轮CI尚待执行。见[R33](R33-OGKM-FINAL-ROUTE-20261019.md)。本页历史FAIL保留。
