# NullMoth 2.3.1 / 2.3.2 / 2.3.3 源码与发行包静态核对

本报告是普通 Python/归档静态证据，不是 REA Evidence。未执行任何包内代码、未解出任何二进制或固件、未安装软件、未修改源码快照或系统配置。固件只列路径，不打开成员；gzip容器遍历必然顺序解压容器流，但未把固件成员作为数据读取或落盘。

## 结论

2.3.3 发行包的 NVRM、NVRMFB、NVRMAGDC、macOS 15 与 26 的 NVAccel 与 2.3.1 相应二进制 SHA256 完全相同。检查的26个驱动/运行时成员中，只有 NVMTLDriver 本体发生变化，其他25个相同。这个结论来自实际成员哈希，独立于发行说明。

NVMTLDriver 本体两版都是 1,483,456 字节，但 SHA256 不同；静态读取 Mach-O64 头与 load commands，实测 LC_BUILD_VERSION 的 minos 从26.0.0改为15.0.0；SDK均26.5.0，platform均1（macOS），CPU均16777223（x86_64），链接工具版本均1267.0.0。此结果证明部署下限字段改变，不能独自证明只有此字段改变、不能证明完整代码相同或插件对应哪个源码commit。

2.3.3 源码tag不是2.3.1源码回退：保留2.3.2插件/安装器/日志修改，并继续修改NVRM accelerator和NVRMFB；不能拿tag源码中的新增功能当作2.3.3已发行kext的实现。包内元数据不足以把二进制可信地绑定到任一固定源码commit。

## 输入与完整性

源码只读输入：evidence/source-lock.json 固定的三个commit：418051b47f219e1751c30e361f509e71a1101132、7a32692db59990d98df03293474470972c913556、ac55984c473e746c2a8ebea7ba0913461aa7c393。每个文件内容哈希见source-files-sha256.json。

发行包完整SHA256由本脚本重算并强制匹配：

- 2.3.1：3522e2f5481b70a88ead5abcaeea7e236f01cc08088000e74ccab2be42ca6429
- 2.3.2：33bf069592903c59a52de7393fc2c4104298d9820c378c9287ae39cfa3944a4e
- 2.3.3：869a3f34f5d1c4350d09347f876967821156091c8c8d677234f25c57ea001122

三个tar各116成员。完整路径/类型/大小、17个JSON/plist/版本manifest及26个驱动成员的哈希，分别保存于v2.3.1-archive-audit.json、v2.3.2-archive-audit.json与v2.3.3-archive-audit.json。三包全部已完成静态核对。

## 三包实际构建成员关系

以下A/B/C只表示实测字节哈希分组，不代表源码commit：

| 成员 | 2.3.1 | 2.3.2 | 2.3.3 |
|---|---|---|---|
| NVRM | A | B | A |
| NVRMFB | A | B | A |
| NVAccel，macOS 15缓存及默认Extensions副本 | A | A | A |
| NVAccel，macOS 26缓存 | A | B | A |
| NVRMAGDC | A | A | A |
| NVMTLDriver | A | B | C |
| NVK libvulkan_nouveau.dylib | A | A | A |
| 其余已检驱动/运行时成员 | A | A | A |

因此2.3.2相对2.3.1只改变26个已检成员中的4个（NVRM、NVRMFB、NVAccel 26、Metal）；2.3.2→2.3.3也改变相同4个路径，其中3个内核驱动恢复2.3.1字节，Metal则为第三个不同哈希。macOS 15 NVAccel三包字节始终相同，即使对应源码文件在2.3.2有修改；这限制了将2.3.2源码变更直接认作Sequoia实发行为的推断。没有复编译或指令级比对，不能仅由源码改动加哈希判断其具体构建历史/优化结果。

完整三版逐成员SHA见package-driver-threeway.json，以下列出会变化的4个成员：

| 成员 | 2.3.1 SHA256 | 2.3.2 SHA256 | 2.3.3 SHA256 |
|---|---|---|---|
| Library/Extensions/NVRM.kext/Contents/MacOS/NVRM | cb3775fa7f8261641cc08328e12793aa7c3698d12a3264c443a68c4f55fb1bdb | 19de7ea08d7ce97a74a3f37efc75bf60222fcaa5ba393b9ab832415e8aa58afa | cb3775fa7f8261641cc08328e12793aa7c3698d12a3264c443a68c4f55fb1bdb |
| Library/Extensions/NVRMFB.kext/Contents/MacOS/NVRMFB | 6b8befff08e286d92f5e911c27e92e5b2951964e781eb4bea6b5554baafad1e4 | ac5dd6133cd9c7a4e1235feeceaa0d943e3f5a4aea5934589143162efba676b9 | 6b8befff08e286d92f5e911c27e92e5b2951964e781eb4bea6b5554baafad1e4 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/NVMTLDriver | bda8aca1e3d1d2c7dda9c15a149b903b5fd8c7091497c498ce3f61baf9dd9b05 | 39f2ecc8dd7db952dcac7e25ac727ff6b065e94e2dd7ba564a2add4a243e4171 | c3f6bce53e14ae1274f478e9b11d1c4aecc821e8e2920a93aa9efb94457b062d |
| Library/NullMoth/kexts/26/NVAccel.kext/Contents/MacOS/NVAccel | 09747ce0ad0b7a4f26de9e0099710b2982054452305c6eed55ed6dafe7e1354b | c54cd1a30adb8124316f20ffcc15c37f73ab0ed6aa0d64f9770349d1ee6a88d7 | 09747ce0ad0b7a4f26de9e0099710b2982054452305c6eed55ed6dafe7e1354b |

### 三包Mach-O部署字段

| 成员 | 2.3.1 minOS / SDK | 2.3.2 minOS / SDK | 2.3.3 minOS / SDK |
|---|---|---|---|
| NVMTLDriver | 26.0.0 / 26.5.0 | 15.0.0 / 26.5.0 | 15.0.0 / 26.5.0 |
| NVK | 15.5.0 / 15.5.0 | 15.5.0 / 15.5.0 | 15.5.0 / 15.5.0 |
| 所检kext（含NVAccel 15/26） | 未见上述版本load command | 同左 | 同左 |

实测8个目标成员/包的Mach-O头与有界load command记录见driver-macho-build.json。所有目标都是thin x86_64 Mach-O64；kext filetype=11，Metal=8，NVK=6。kext未发现LC_BUILD_VERSION或LC_VERSION_MIN_MACOSX，不能凭本次头字段核对证明kext的macOS部署下限。NVK的minOS15.5与Metal minOS15.0不同，单独把Metal下限称为整个运行时下限并不准确。

### 三包manifest身份

三包17个元数据成员中，每相邻版本均仅BASELINE-IDENTITY.json、SHA256SUMS、VERSION本体变化；所有Info.plist与MANIFEST.txt三包相同。BASELINE-IDENTITY.json的package_version依次2.3.1/2.3.2/2.3.3，previous_package_version依次2.3.0/2.3.1/2.3.2，previous_archive_sha256在2.3.2、2.3.3分别指向本次已核验2.3.1、2.3.2归档哈希。这建立包之间声明的先后链，不能绑定源码commit。

2.3.1→2.3.2的SHA256SUMS声明共7路径变化：四个驱动成员、BASELINE-IDENTITY.json、VERSION、install.sh；2.3.2→2.3.3共6路径变化：四个驱动成员、身份JSON、VERSION，install.sh不变。2.3.1包install.sh声明哈希只匹配2.3.1源码，2.3.2与2.3.3包install.sh声明哈希均匹配2.3.2/2.3.3源码。其余源commit绑定证据仍缺失。明细见threeway-summary.json。

三个BASELINE-IDENTITY.json均包含历史scope/unqualified文案与同一runtime_qualification；报告不把这些元数据宣称的硬件测试结果当作本次已执行的测试。

## 2.3.1与2.3.3驱动哈希对照

| 包内相对路径（去掉pkgroot/） | 2.3.1 SHA256 | 2.3.3 SHA256 | 相同 |
|---|---|---|---|
| Library/Extensions/NVAccel.kext/Contents/MacOS/NVAccel | f0edef4ec10372255fd407efd4009a74abc312172db351bbe65e683979d26b54 | f0edef4ec10372255fd407efd4009a74abc312172db351bbe65e683979d26b54 | 是 |
| Library/Extensions/NVRM.kext/Contents/MacOS/NVRM | cb3775fa7f8261641cc08328e12793aa7c3698d12a3264c443a68c4f55fb1bdb | cb3775fa7f8261641cc08328e12793aa7c3698d12a3264c443a68c4f55fb1bdb | 是 |
| Library/Extensions/NVRMAGDC.kext/Contents/MacOS/NVRMAGDC | 223a327f0b94ecd9a0ca321f5d69f149d8c4275b0a4e8f6be63d0c6266c6b2de | 223a327f0b94ecd9a0ca321f5d69f149d8c4275b0a4e8f6be63d0c6266c6b2de | 是 |
| Library/Extensions/NVRMFB.kext/Contents/MacOS/NVRMFB | 6b8befff08e286d92f5e911c27e92e5b2951964e781eb4bea6b5554baafad1e4 | 6b8befff08e286d92f5e911c27e92e5b2951964e781eb4bea6b5554baafad1e4 | 是 |
| Library/GPUBundles/NVIDIAShared.bundle/Contents/MacOS/NVIDIAShared | 7dda95a2b437438a222b5d5305d2c1094737bdd1493670d6587a418cfb8e9bf4 | 7dda95a2b437438a222b5d5305d2c1094737bdd1493670d6587a418cfb8e9bf4 | 是 |
| Library/GPUBundles/NVIDIAShared.bundle/Contents/PlugIns/libLLVM.dylib | 2a6d807ce8f3a3ab772e8f861ff40cff63363b90ee1d80ca7e289147b39405aa | 2a6d807ce8f3a3ab772e8f861ff40cff63363b90ee1d80ca7e289147b39405aa | 是 |
| Library/GPUBundles/NVIDIAShared.bundle/Contents/PlugIns/libnvidia-nvvm.nocanary.so | 993f398aa62575d021d8e1a864c7b375396a50fec6f97c62e79dd4b17c8bfce1 | 993f398aa62575d021d8e1a864c7b375396a50fec6f97c62e79dd4b17c8bfce1 | 是 |
| Library/GPUBundles/NVIDIAShared.bundle/Contents/PlugIns/libnvidia-ptxjitcompiler.so.610.57.04 | 0df88a5dc3c2effdd3f895f664572c8a7485152fa1db134db8fcdaf80d4fbc7d | 0df88a5dc3c2effdd3f895f664572c8a7485152fa1db134db8fcdaf80d4fbc7d | 是 |
| Library/GPUBundles/NVIDIAShared.bundle/Contents/PlugIns/libzstd.1.dylib | afd5adc5ce9592369b1067f8bcf1ba8b7ea5b75e752e4edadd4a0f254fcdb6d0 | afd5adc5ce9592369b1067f8bcf1ba8b7ea5b75e752e4edadd4a0f254fcdb6d0 | 是 |
| Library/GPUBundles/NVIDIAShared.bundle/Contents/PlugIns/nvvmdrive | 6ffa7f740f810f800ffa0c6fa98cb4f495a7e86251bf8b061065ab93a39f7a92 | 6ffa7f740f810f800ffa0c6fa98cb4f495a7e86251bf8b061065ab93a39f7a92 | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/NVMTLDriver | bda8aca1e3d1d2c7dda9c15a149b903b5fd8c7091497c498ce3f61baf9dd9b05 | c3f6bce53e14ae1274f478e9b11d1c4aecc821e8e2920a93aa9efb94457b062d | 否 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/air-runtime/libLLVM.dylib | c8f4db33ebf63a2e691690435b4a8bf470c0f307b10a09a0c8c58930f0dc499d | c8f4db33ebf63a2e691690435b4a8bf470c0f307b10a09a0c8c58930f0dc499d | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/air-runtime/libzstd.1.dylib | 261ca1b875b5f4bbc6b01d405cabc61d9ad9988f0aaab59e420f5b14ec94a0e3 | 261ca1b875b5f4bbc6b01d405cabc61d9ad9988f0aaab59e420f5b14ec94a0e3 | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/libnvdec_h264.dylib | 6068bacc3ef379c87985d28e4e177bd5b0b28f09c4263c4e786bc4bd3d3f16d0 | 6068bacc3ef379c87985d28e4e177bd5b0b28f09c4263c4e786bc4bd3d3f16d0 | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/libnvdec_h264_t2d.dylib | fdfd6e9c356bb4eac42d6841d950db3545cb97e6bcb2b039132d190119a52de3 | fdfd6e9c356bb4eac42d6841d950db3545cb97e6bcb2b039132d190119a52de3 | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/libnvdec_hevc.dylib | 64b2353a900dc8bb6feb6c4b0037b948bdcb5d568d4573693cc56f3b7ba1e537 | 64b2353a900dc8bb6feb6c4b0037b948bdcb5d568d4573693cc56f3b7ba1e537 | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/libnvenc_h264.dylib | c78e21aae60f746cd915f8c9fa6e27728b9704304ab837b1bf30e5beffef5813 | c78e21aae60f746cd915f8c9fa6e27728b9704304ab837b1bf30e5beffef5813 | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/libnvenc_hevc.dylib | aa6b8b2e76bda34217ee39370285c702fcce644bb8c47f5dfb0684a8f7935256 | aa6b8b2e76bda34217ee39370285c702fcce644bb8c47f5dfb0684a8f7935256 | 是 |
| Library/GPUBundles/NVMTLDriver.bundle/Contents/MacOS/libnvmtl_translate.dylib | 0654076e66c7e78a58d9750c585cca259874e2adc03a10206a748783e829a3e0 | 0654076e66c7e78a58d9750c585cca259874e2adc03a10206a748783e829a3e0 | 是 |
| Library/GPUBundles/nvmtl/air-opt | 8c41049c46b4c4fe1fa3bf0746aa0754ca7f18d23a1b98985dca9e088fc26922 | 8c41049c46b4c4fe1fa3bf0746aa0754ca7f18d23a1b98985dca9e088fc26922 | 是 |
| Library/GPUBundles/nvmtl/libvulkan.1.4.362.dylib | dc81d04917bd1aad88b2ec150ff3150f44dd24b786b227874492aae62e7c9c6e | dc81d04917bd1aad88b2ec150ff3150f44dd24b786b227874492aae62e7c9c6e | 是 |
| Library/GPUBundles/nvmtl/libvulkan_nouveau.dylib | a3a6451e7a193cbe2e71b5a6d769d14f8fd75b8728412bc28af944646d0af914 | a3a6451e7a193cbe2e71b5a6d769d14f8fd75b8728412bc28af944646d0af914 | 是 |
| Library/GPUBundles/nvmtl/libvulkan_nouveau.dylib.syms | 10170125bf4c28c6a5790874fa304187aea1095d370c833aa0545955ec6d2c6d | 10170125bf4c28c6a5790874fa304187aea1095d370c833aa0545955ec6d2c6d | 是 |
| Library/NullMoth/kexts/15/NVAccel.kext/Contents/MacOS/NVAccel | f0edef4ec10372255fd407efd4009a74abc312172db351bbe65e683979d26b54 | f0edef4ec10372255fd407efd4009a74abc312172db351bbe65e683979d26b54 | 是 |
| Library/NullMoth/kexts/26/NVAccel.kext/Contents/MacOS/NVAccel | 09747ce0ad0b7a4f26de9e0099710b2982054452305c6eed55ed6dafe7e1354b | 09747ce0ad0b7a4f26de9e0099710b2982054452305c6eed55ed6dafe7e1354b | 是 |
| nullmoth-runtime-check | 0659fa6c49841794762d63a1b5dc7084f77b013b6f20c8966683978d7d033a16 | 0659fa6c49841794762d63a1b5dc7084f77b013b6f20c8966683978d7d033a16 | 是 |

## 包内身份与源码绑定的限制

- BASELINE-IDENTITY.json中package_version/previous_package_version分别随包更新，但没有源码commit、源码树hash、完整构建命令或工具链锁定。paired_kexts四个SHA与实测吻合。
- 两包Info.plist全部相同，主要bundle版本仍为0.1（NVIDIAShared为1.0），无法凭bundle版本识别2.3.x源码或二进制。
- BASELINE-IDENTITY.json继续保留scope中的“1.1.0 plus”“only on macOS 15”和unqualified中的“macOS 26”“fix planned for 1.2”。这些是包内原文，说明此身份文件混有历史资格说明；不能把它当作当前完整构建证明。runtime_minimum_macos为15.5，与Metal自身minOS15.0是不同层面的声明。
- SHA256SUMS两版只有BASELINE-IDENTITY.json、VERSION、install.sh、NVMTLDriver四条记录不同；MANIFEST.txt本体不变。这里是manifest记录比对，未重新读取/哈希所有包内文件，尤其没有验证固件或脚本内容。
- 2.3.3包SHA256SUMS对install.sh声明的哈希79899394a6c2c18b5bdcbccb1dd9b86c757718f7a1ac602c1b397ad97a805e2a，与2.3.2/2.3.3源码package/install.sh的实测哈希相同，和2.3.1不同。这支持安装器保留新版修复，但仍是包manifest所声明的对应关系，未读取包内脚本重算。
- Metal minOS真实字段证据见metal-macho-build.json；构建脚本build/build_plugin_release.sh:16请求-mmacosx-version-min=15.0、:23-24检查15.0，脚本的存在不是本次发行实际执行过该脚本的证明。该脚本接受独立git revision参数，不能推断自动使用tag HEAD。

## 三源码快照差异

| 区间 | 新增 | 删除 | 修改 |
|---|---:|---:|---:|
|2.3.1 → 2.3.2|2|0|13|
|2.3.2 → 2.3.3|1|0|5|
|2.3.1 → 2.3.3|3|0|15|

完整文件名见source-diff-summary.json，逐行差异见三份v2.3.x..v2.3.y.diff。

2.3.2→2.3.3仅修改CHANGELOG.md、kexts/NVRM/accel/nvaccel_stubs.h、kexts/NVRM/accel/nvrm-accel.cpp、kexts/NVRMFB/fb/nvrm-fb.cpp、tools/test_boot_raster_modes.py，新增tools/test_iop_flip_gate.py。其余2.3.2变更直接保留，例如plugin/NVMTLEventSync.m:120的surface dirty提交标记、plugin/nvmtl_vk.c:2815的空纹理句柄保护、package/install.sh中的版本回滚修复。

2.3.3额外引入NVResource::fPluginWroteCookie；nvrm-accel.cpp:1144加入nvAccelIopVramFlippable，要求VRAM newest且插件写过当前allocation；相应copy/pageoff门槛亦改变。NVRMFB在:270增加fKmsModesLogged并增添模式枚举诊断。它们存在于tag源码，但2.3.3实发对应kext与2.3.1字节完全相同，因此不能据此宣称它们进入实发驱动。

## 原生构建仍不明确的事项

未进行macOS原生构建/链接、签名验证、加载或硬件测试。源码build/accel_build.sh依赖xcrun SDK/Kernel.framework headers、外部OGKM树与该树_out/Darwin_x86_64/compile_cmds.sh宏定义；build_plugin_release.sh依赖远端mini和/Volumes/MiniData/build/gpu-src/mesa/include。快照中的脚本与包身份未把所有这些构建输入、具体构建revision与每个发行成员绑定。需要可审核的构建输入锁定/日志/证明或可重复原生构建结果，才能建立源码commit→发行二进制的强对应；现有证据只支撑包间字节同一性与上述头字段。

## 可复核工具与证据

audit_sources.py产生三源码哈希、文件变化汇总与完整diff；audit_packages.py只列tar清单、读取JSON/plist/版本manifest并流式哈希目标驱动成员；read_macho_build.py只在内存读取Metal、NVK与必要kext头和有界load command区；summarize_threeway.py对已落盘JSON证据生成三包差异与身份汇总。所有脚本和产物均位于本目录。
