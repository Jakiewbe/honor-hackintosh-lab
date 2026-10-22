# 离线构建链审计整改（2026-10-22）

固定被审基线：7fa7fdc9b44f035329c4d36a17d3025f34f87e7c。用户提交的BUILD/LOAD NO-GO裁定成立。
本轮只修构建准入及证据，不执行设备动作；原生兼容合同结果尚待新CI。

## 修复与证据等级

| 项 | 实现与限制 |
|---|---|
| Python3.9 | 共用save改为Path.open(newline=...)；PM生成夹具同改；基础及失败报告路径测试。真正3.9等待CI |
| xcodebuild | 原生once入口也可选；仍强制实际SDK15.5及Kernel头，不把任意新SDK当等价输入 |
| preflight | offline_build.py共用14个固定ID；菜单2和直接shell都调用build()，build()必先检查，失败不创建构建工作目录 |
| 仓库身份 | 要求外部提供完整G1_EXPECTED_COMMIT，核对当前HEAD与干净度；不自动把当前HEAD赋给期望值 |
| 输入源码 | 固定pin、Git命令返回码、tracked与untracked检查；仅容忍未跟踪的Finder元数据，不忽略tracked修改 |
| GNU Make | 真实执行版本检查；系统旧make只可引导构建已固定SHA的make源码，绝不伪装gmake；已有4.x不要求tarball |
| 离线 | 取消clone/fetch/brew/工具安装兜底；缺本地输入就失败；归档固定SHA且检查路径/链接，解包使用同一已验证内存快照 |
| 删除风险 | 取消所有旧目录删除；专用根要求路径隔离与管理标记；每次新建run-*，旧数据不清理 |
| 身份/日志 | 固定提交、运行脚本SHA、工具身份和每次独立目录报告；原生管线失败保留FAILED；成功须核对三产物及plist SHA |
| 安装/回退 | 两个first-touch入口均无sudo/KC/NVRAM写入；旧install/rollback立即exit42。未提供新的未验证设备事务 |
| 导出探针 | 去掉工作流||true；解析错误/正控缺失/反控命中非零，精确匹配Mach-O名称；附件仅文本、不上传dylib |

稳定14项：host-os、host-arch、python、developer-tools、sdk、clang、repository、nullmoth、ogkm、
shell-lf、assets、gnu-make、workspace、disk-space。空间直接调用disk_usage，不再解析可为空的df。
源码路径的safe.directory仅按单次Git命令限定，不修改全局配置。

现有本地make-4.4.1.tar.gz再次复算SHA：
`dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3`。
这是既有暂存归档的字节固定，不是本轮重新下载或新的第三方安全背书；本机没有执行configure。

## 验证记录（随真实结果更新）

- Windows Python3.12：128项回归，125通过/3项POSIX测试跳过；离线合同16项中13通过/3跳过。
- 现有WSL Python3.12/Bash5.2：离线合同16/16通过，含真实shell入口拒收和同一生产build()的失败保存。
- 导出工具实际CLI夹具3/3通过：正控、负控、破损trie；没有执行本地生成的Mach-O数据。
- 新CI `g1-offline-contract.yml`：仅workflow_dispatch，macos-15-intel，Python3.9、/bin/bash3.2。
  只运行合同及工具回归，不编译完整驱动、不加载、不执行GPU；结果待验收。

测试中的微型Git仓库、工具版本/SDK文件夹具和昂贵管线替代只用于验证准入与失败控制流，
成功标记为`PASS_ORCHESTRATION_FIXTURE_NO_NATIVE_BUILD`，没有把夹具当真实原生编译。
CI源文件哈希清单将绑定执行SHA，不以工作流success代替日志验收。

### 第一轮原生合同：保留失败证据

run39749482514 / `0b92d0e2fdfcc5f7711422001b051f1d9d783abb`，workflow_dispatch，failure。
实际Python3.9.25与Apple Bash3.2.57；离线合同15/16通过，只有归档夹具的路径断言失败：
生产archive()返回规范化的`/private/var/...`，测试错误地与`/var/...`未规范化路径比较。
更正为比较`path.resolve()`；未放宽归档哈希、成员限制或任何生产准入条件。
完整日志、环境及执行源码SHA清单在`evidence/39749482514/offline/`，修正后等待新run。

### 导出探针：真实正控与有限观察

run39749607753 / 同一`0b92d0e`，workflow_dispatch，success。artifact12412269543，
原始8个成员全部为文本，归档SHA/成员SHA在`evidence/39749607753/export/archive-binding.json`。
同run新编译的非驱动dylib未执行、未上传；解析器找到`_g1_export_probe`且反控不命中，controls_passed=true。
KC观察绑定`12913116…67c2`及IOAccel成员UUID，27请求、未见所检查导出命令、观察命中0；
仍为`EXPORT_TRIE_ABSENT_NOT_OBSERVABLE`，不是全部导出机制不存在或运行时必然失败。

### 补齐原始设备JSON供复算

在既有本地工作缓存找到`device-vtable.json`，按原始字节归档至`evidence/device-text-20261022/`。
其文本SHA为`98cb257b1dd945213fcd74b0e1e8a1ec47f99ce267445aeba683cd88861f9c7a`；
`verify_device_text.py`复算字数、文件偏移、目标候选及七方法槽号，并与已归档CI观察比较，一致。
其中parser SHA匹配7fa7fdc的工具Git blob；source_commit/source_run原值均null，继续保留未知。
本轮没有读取设备KC二进制，KC SHA/字节数/UUID只是该JSON报告的身份，不能称本轮重新哈希过设备KC。
不上传KC二进制、不宣称完整指针链/继承/成员偏移/调用约定或完整ABI已通过。

## 可审查的使用边界

新的离线入口不需要修改已暂存源码或系统策略。先从本轮已审交付取完整SHA，明确设置：

```bash
export G1_EXPECTED_COMMIT='<本轮交付的完整40位SHA>'
export NM_SRC='/本地固定NullMoth检出'
export NV_SRC='/本地固定OGKM检出'
export G1_TOOLS='/本地已核对make归档目录'
export WORK="$HOME/Desktop/g1-kextutil-audited"
bash research/stock-v243-offscreen-20261021/g1-first-touch.command preflight
```

这些是预检查用法，不是要求现在启动设备构建。不要自动用当前HEAD填期望SHA；
不要使用已有旧版WORK或覆盖原有数据，选择不存在的新专用目录；每个run保留自己的产物与报告。
preflight通过只说明可进入固定参数的编译/链接，不证明离线整条驱动管线已在GLO-FX6P成功。

## 保留的设备阻塞与结论

设备KC的有界观察不得升级为完整ABI；27项未见所查导出形式不能升级为运行时必然不可用。
-nvrmnogo检查之前可能调用placeLargeBar1等写硬件路径，不是只读或零初始化保证。
Recovery独立入口、卷组识别、AuxKC与扩展状态恢复及重新启动均没有本轮实测。
原始四次设备崩溃未重现，30分钟目标机驱动构建未执行，加载/GPU未执行。

构建层：整改与合同测试已进行，Python3.9/Bash3.2原生及完整设备构建尚未验收。
设备层：**LOAD NO-GO / GPU NOT RUN**。不以脚本可运行代替设备授权。

复盘：去掉不必要的删除与部署入口，比给未经验证的恢复流程加“成功”提示更可靠；
执行检查必须连接真实入口，并明确区分工具合同、原生驱动构建和设备行为。
