> **2026-10-18 NVLink ��˺�ѡ��** �Ѽ����ĸ���ʵ Darwin semaphore �ӿڼ� CPU ����/���Ϻ�ͬ��������������ͬ run ��/�޺�˵����Ӷ��ա����ȴ��ж����ԣ����� void �ӿڲ��ɻָ�����Ϊ���� panic��free ��Ҫ����÷��ſա����߼���ѹ���CPU C++ ��ͬ���� Darwin/������δִ�У�δ������ȱ���ѹرգ��豸���� NO-GO��[��������](../research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md)��

> **2026-10-18 ʵ�ʹ�����չ��** [run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) �ѳɹ�ִ��Դ���ύ `30485ae`��ȫ��1,280��C TU��5��shader����ͨ����RM/modeset�����鵵��NVRM�ؽ���ѡ�����ӡ���ǰ����UNKNOWN��������nm�й۲쵽���壻�����ĸ���֪NVLink���ڲ����룬����471��Ŀ�굼��/ABIδ���ա�������profileѡ������һ�²����Ǳ���������TU������**��ʼ����GPU��Ⱦ�����ض��ؾ�δִ�У������в��ɽ������豸NO-GO��** ��һ�����ĸ���ʵDarwin���ӿڡ���������ABI��Ŀ�굼�����顣[�����֤��](../research/gpu-safety-r5/FULL-SOURCE-BUILD-20261018.md)��[��ҳ��ֻ������prompt](../research/gpu-safety-r5/FULL-SOURCE-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R80 ������������Դ��** ���� Mach-O ת C ����ʱɾ���»��ߵ����⣻���� UNKNOWN �����λΪ�������ݡ�һ�����һ������ݼ�һ�������䷽��ѡ���ѽ��뱾����ʽ�����ϣ/��ȷ����ȡ֤��47��߲��Լ�������ʷ�ع�ͨ������ Darwin/�����ṩ��/����/ABI ��δ���У������հ����豸�� NO-GO��[����](../research/gpu-safety-r5/R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md)��[��ҳ�˸��� prompt](../research/gpu-safety-r5/R80-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R79 ��ƾ�����** �ѳ��ء�45�����ű�Դ���롰351��667֤�������հ�����������������ͬ������ʽ�����嵥���ޡ��̶�346������ɨ��Ϊ337���ʷ���ѡ��9��UNKNOWN���зǶ���հ���27��߲��Ժ�������ʷ�ع�ͨ����������TUѡ��ABI����������ϸ��ı���������Darwin/����/ABI��δִ�С��� [���ֱ���](../research/gpu-safety-r5/R79-AUDIT-CLOSURE-GATE-20261018.md)�������հ���ʵ������NO-GO��

> **2026-10-18 R28 ������** ��ʵ���� owner-copy �Ĵ��󴫲�������ѡ�޸��� CPU ����������ͬ��15/15��R27 ͬ�� 6 ��Ԥ��ʧ�ܡ�Unsupported ֮�ⲻ���ˣ�symbol ����ʧ�ܷ��� NoMemory��ԭ���Ž���׷�� R28�������������ͬ���ԣ���δִ�С�[����](../research/gpu-safety-r5/R28-OWNER-COPY-ERRORS-20261018.md)�����ı� P0-1/P0-4 ������ NO-GO����һ������Ϊ��ȷ��/���� inventory�������հ��� ABI��

> **2026-10-18 ��ǰ GPU �ϵ���£������հ����ƽ̨ ABI��** 42 ��ԭ�����ṩ�ߵ��롱�����к�ѡ�������壬�����ٰ� R13/R48 ���ĳ�Դ��ȱʧ��̬�з�����������������ȷ�� 35 �� OGKM Ŀ��λ�� 5 �� TU��20 �� runtime ��ʹ���߿� 3 �� TU���̶� NullMoth ���߶����� 31 �� NULL ջ���á��Ƿ����� altstack ����ȷԤ����ȡ֤����� [��ǰ�������һ�ϵ�](../research/gpu-safety-r5/G1-CLOSURE-ABI-AUDIT-20261018.md)���嵥Ԫ�ɱ�������ʵ�� artifact digest ���ˣ�������/�����ṩ�߲ɼ���δ���С�P0-1/P0-4 �� BLOCKED/OPEN��KEXT-LOAD NO-GO���·���ʷ�������ؽ�/Դ���ѵ���/����ֻ��һ���ļ����ȱ�������Ϊ��ǰ���ۡ�

> **�����ֲᣨ2026-10-18��**��[REPRODUCTION-20261018.md](../research/gpu-safety-r5/REPRODUCTION-20261018.md)
> �� R1�CR20 ��������飬�г�ÿ������������������״�롸����ê�㡹���������ϲ������õı�ʶ������
> ����һ�ľ�֪���ļ���������ʧЧ�������ɲ��������������ɣ�������д��

## 2026-10-18 ˫�����վ���һҳ����ȱʲô��

[NVIDIA �� Intel �����վ���](../research/gpu-safety-r5/ACCEPTANCE-MATRIX-20261018.md)��ÿ���Ž���Ҫʲô֤�ݡ�
���ڵ��ġ�����˭������ȫ��ȡ�� `evidence/ci-r5/verification.json` ������Ž����档

Ҫ�㣺**NVIDIA ��**Դ���빹���ѵ�����18 ������16/16 ����NVAccel 248584 B������ NVRMFB 315744 B��
�ر�ʧ�ܲ����ϱ��� OGKM �� `void` �ӿھ����ģ���Ϊ���ɹرգ���**Intel ��** R16�CR19 ��ͣ����owner-copy��
������ȫ��kva ����ȫ�������꣬��һ����ֻ��ȷ��������״�����Ǽ����Ĵ��롣

**���Ḵ��**��R16�CR19 δ���� FreeBSD base/LinuxKPI �հ���`BLOCKED_FREEBSD_BASE_SELECTION` ��ǰ��δ�䣬
i915/eDP ������**���ؿ�**��

## 2026-10-18 GPU R8�CR13���豸�������ڱջ��������ļ�������NVRM �����ؽ�

- **R8/R10**��`kapiInit()` ʧ�ܡ�`super::start()` ʧ�ܡ�`stop()` ����·������ `dropKapiDevice()`������ Device
  �� `gDevUsers` ���������һ��ʹ���߲� `freeDevice()`��
- **R9**��������뷢���� `nvkms_xnu_pm_running()` Ϊ��ʱ��OGKM �� `ReleaseOwnership`/`KmsFreeDevice` ����
  `nvkms_ioctl_from_kapi`������ʱ�� 30 �롢LOST ʱ���󱻾ܶ� `FreeDevice` ���ͷ� RM �� �� ���� + ˺�ѣ���
- **R10����Ҫ������**���ֿ��������� `nvrm-fb.cpp`��**���а� NVRMFB �� `kexts/NVRMFB/fb/` ����**�����ж����ƺ���
  �����ַ�����������һ�ݵģ�`package/install.sh` �����β���Ҳֻ����������R7�CR9 �ĵ� `kexts/NVRM/fb/` ������������
  �Է������������ã�R10 ��ȫ���޸���ֲ�������ļ����Ž�ͬʱ�������ߡ�
- **R11**��`finishOrphanedDevice()` ����һ�� start ʱ����"PM �����ö�����"�Ĺ¶��豸��
- **R12**��`dropKapiDevice()` ԭ���� `stop()` ĩβ**����**ִ�У���� `startLock()` �� `kapiInit()` ��̬�������߶�ȡ
  `NVRMDisplayGate`���ݹ��������ò���������������־��
- **R13���������**��`kexts/NVRM/` ȫ�� 9 ���� TU �������ӵ� 361768 B / 649 ���ţ����а�Ϊ 16787920 B / 34302 ����
  ��Լ 2%�����ֿ�����Ԥ������� �� **NVRM.kext �޷��ù���Դ���ؽ�**��`KEXT-LINK` ��������ֻ�� NVAccel �� NVRMFB��

֤�ݵȼ���`DARWIN-COMPILE` + `KEXT-LINK`��NVAccel 244400 B������ NVRMFB 311488 B����`KEXT-LOAD` ��֮�� **NO-GO**��
��������ֹ���жϼ� [FEASIBILITY-STOPLOSS-20261018.md](../research/gpu-safety-r5/FEASIBILITY-STOPLOSS-20261018.md)��

## 2026-10-18 GPU R5�CR7 ԭ���Ž��״�ͨ����DARWIN-COMPILE + KEXT-LINK��

[Run 39048772269](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39048772269) �� `bfa7c3e` �� `completed success`��Xcode 16.4 (16F6) / clang 17.0.0 /
macOS SDK 15.5 / macOS 15.7.9 Intel runner��R1��R7 �߸������� OGKM ����ȫ��Ӧ�ã�original �� candidate
�� 6 �� TU �� **12/12 �������ɹ�**��ÿ�������Ϊ Mach-O 64-bit x86_64 `MH_OBJECT`��**�澯������**
��ÿ��Ԫ original/candidate ��ȫ��ͬ����NVAccel kext ���������������ɣ�244400 B��
`sha256 89f9839e��5e6cf1`��`KEXT-LINK_ONLY_NOT_LOADED`��

**֤�ݵȼ��ƽ��� DARWIN-COMPILE + KEXT-LINK��KEXT-LOAD �� GPU/���������� NO-GO**��������û�м���
�κ�������Ҳû�з��� GPU��������������ȱ `-mmacosx-version-min=15.5`������ ld ����Ŀ�꾯�棬�����ò�һ�£���
F5b��`super::start` ʧ�������һ�� framebuffer/kext ж�صĶԳ����٣���δʵ�֡����
[research/gpu-safety-r5/README.md](../research/gpu-safety-r5/README.md)��
���䣺[Run 39049023927](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049023927) �� `3ef269e` �ϸ���ͬ��ͨ���������в��� `-mmacosx-version-min=15.5` ������ ld ����Ŀ�꾯����ʧ��kext �ֽ����״�������ȫ��ͬ��244400 B��ͬһ sha256����˵���ò���ֻ��������ϡ�δ�ı���


## 2026-10-18 GPU Դ���ѡ R5�CR7��Դ�� + �������ԣ�ԭ��������δ���У�

R5 �� `kexts/NVRM/os-nvkms-xnu.cpp:kms_close_common` ����ʵ use-after-free��GPU ����/��ʧ���� PM �ȴ�ʧ��ʱ��
�ɴ������� `data` ���ͷ� wrapper���� `nvidia-modeset-os-interface.h` �涨��ָ����� NVKMS ֮��ش�
`nvkms_event_queue_changed()` �� `pOpenKernel`���ָ�Ϊʧ�ܼ����� per-open/wrapper/worker���� `closing` ���ܾ���
ioctl��R6 ������̬���Ͽɹ۲�����ߣ�������� + ���ѳɹ����� PM �̻߳��� + ֻ�� sysctl
`debug.nvrm_kms_close_deferred`��R7 �� `kapiInit()` ʧ�ܺ����µİ��ʼ������ Device�����Խ� Device ��
`releaseOwnership` + `freeDevice` + �� `gDev`������·���黹 head λ�������� Device������ OGKM `e4a5faa` ��
`nvkms-kapi.h`���������������� void������ʧ�ܲ����ϱ�����

ʵ�⣺7 ��������Դ�������� exit 0������ϣ�ص� `ea9467f4��`�����رպ�ͬ 40/40����ǰ���� ASan �� UAF����
bridge-owner 9/9���ع������� 15/15�����õ��ͬ 12/12���ع��ṹ��ͬ 14/14��
**DARWIN-COMPILE / KEXT-LINK δ���У�KEXT-LOAD �� GPU/��������һ�� NO-GO��** ���
[research/gpu-safety-r5/README.md](../research/gpu-safety-r5/README.md)��

## 2026-10-17 GPU R4 ��ǰ���ֺ˲飨�û����� GPU ���ȣ����� NO-GO��

�û���ȷ�ָ� RTX 2050 `10DE:25A9` GPU �������ȣ�H2 �����ݻ���Intel `8086:46A6` �������л�����ʾ������չ�� Head 4/Intel Metal/G2/G3��D-17/D-18 ����ʷ���߲�ɾ������ָ������� H4 �������ȼ����������豸��ȫȨ�ޡ�

Զ�� `main` �ں˲�ʱΪ `7c9f50dee8b5d940cf6726c31f6fd236fb3857ca`�����޻�����һ�ύ���� Actions����� R4 [#39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733) ʹ�� `b7ac4b0`��NVKAPI C ������ͨ����ԭ��/��ѡ��ʮ�� C++ ����ʧ�ܡ��޸� `-Wno-error=deprecated-declarations` �д��û��ֶ�ԭ����֤�����������´���򹹽��ɹ���

�����̶�Դ�� SOURCE-REVIEW��`NVRM::gpuSuspend` �� PM users ������Խ��� RM STANDBY��`kms_close_common` �� KAPI per-open ����ʧ���޷��� OGKM `KmsFreeDevice/FreeDevice` �� void �ͷ���������`nv_xnu_lookup_fd` �������ص���Ƕ��ָ���������ú�ͬ����� [��ȷ�������� NO-GO ���](../research/gpu-safety-20261017/PM-R4-REVIEW-20261017.zh-CN.md)��**���µ� DARWIN-COMPILE��KEXT-LINK��LOAD��GPU ���������гɹ�֤�ݡ�**

## 2026-10-17 GPU R4 ԭ�������Ž���ϣ�����ʧ�ܣ����� NO-GO��

R4 Ϊ NVRMUserClient �ⲿ�����ַ���ӳ��͹ر����Ӵ��лỰ�Ž���NVKMS bridge close ʧ��ʱ���� per-open �� owner���ṩ��ʽ���ԣ����� PM ʱԤ�ȷ��� gate��PM owner ����� gate ����ִ�С�RM users ��ʱ�Կ��ܽ��� standby��KAPI Device owner���ص��ſա����� RM/DMA quiescence ���� lookup_fd ���ú�ͬ��δ�պϡ�

�û��ֶ����� [Actions #39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733)������Ϊ `b7ac4b0aacf9951f6105c18e3bd5c7777e173d86`��Xcode 16.4 Build 16F6 / macOS SDK 15.5������ NVKAPI C �������ͨ������� C++ ���뵥Ԫ��ԭ�����ѡ�� 10 ��������� `IOPCIDevice` ������ϱ� `-Werror` ������ʧ�ܡ�NVRM ��־�ﵽ�������������ޣ����������δ����ȷ�ϡ�

��ѡ�Ž��ű������� `-Wno-error=deprecated-declarations`���������þ������������ `-Werror` ��鲻�䣻��������δ�� macOS runner ����֤�����û��ֶ����ܡ��ô�����δ���� Kext��δ����������δ�����豸��δ���� GPU���رհ�ȫ�� BLOCKED��ʵ������/���� NO-GO����� [R4 ����](../research/gpu-safety-20261017/DELIVERY-R4.zh-CN.md) �� [��ϰ�](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733/artifacts/12104692976) (SHA-256 `e0042ef033b4e7e71f919ce61603bf51234d77315fe1d6d41ccc75ff602b4367`).

��һ�� R4 ԭ��������֤�Խ����û��ֶ����������� `H4 ����` �� D-18 �ľ����ȼ����ѱ��û���ǰ GPU ����ָ��ǣ����ı�ԭ��ʵ����ʵ��ϵͳ���豸��Actions Ȩ�ޡ�

## 2026-10-17 GPU R3 ������Դ��/������֤������ NO-GO��

�޸� OGKM �״η���ʧ�ܵ� FreeDevice(NULL) �������������� KAPI ԭ��/��ѡ����ͨ����ʵ���ͷź��������ѡ����ͨ�������� R2 thread_call_free ���ͣ�δ���ư�ȫ�ر��ѽ����ԭ��ʮ�����Ž���׼����δ���У�Kext ���� BLOCKED��ʵ������/��Ⱦ NO-GO��PM busy ���� standby ���� pre-quiesce ��ͬ��

�ֶ� Actions��HONOR GPU safety R3 native object gate���״� Xcode_16.4�����Զ�������NullMoth Դ��˳�� R1��R2��R3ע�ͣ�OGKM ����Ӧ�� R3 NULL �������ؽ� profile ������ Makefile �����飬����������ʵ�����û򷢲��︴�֡�


�������棺[R3](../research/gpu-safety-20261017/reports/DELIVERY-R3.zh-CN.md)�������Ž���δ���У�PM/��;����/�ر�ʧ�ܴ�����������R2 thread_call_free ʧ��ԭ������� R3 ���� XNU ֤�ݾ��������±�����ʷ��¼��

## 2026-10-17 ���ַ�����Ȩ����

�û�Ҫ����ҳ��Э������ֱ���ύ����ʵ��ֿⲢ�ṩ�������ӡ��������� GPU R1/R2 Դ�벹����������֤�ݡ�R2 �ֶ������Ž�������������񣻲����� Actions������ .agent��������Ϊ�豸����������ڼ� [GPU R2 �о���¼](../research/gpu-safety-20261017/README.md)���·���δ�ύ/δ���͡������ɺ�ѡʱ����ʷ״̬�����ܾݴ˷��ϱ��η�����

## 2026-10-17 GPU ��ѡ R2 �����������ģ����� NO-GO��

������ ac55984 �ϰ� R1��R2 ˳��Ӧ�ò�����ָ���ͨ����R2 ���޸� os-nvkms-xnu.cpp��KAPI worker ����ʧ�ܲ��ٷ��سɹ� open���� KAPI Device �� kernel bridge ���������¼���ѯ��thread_call_free �ܾ�ʱ���沢���� wrapper��ʵ�ʺ���ƽ̨��������ע�� R2 13/13����ʵ�ְ��º�ͬ 7/13��Ԥ�ڸ�����գ������߳� HOST-TEST������ԭ��/����/GPU ֤�ݡ�ԭ���˶����ֶ��Ž� ci-export-r2 ��׼����δ���С�PM ʧ�ܡ�close �Եȴ�����; ioctl ���ú��ϲ� void freeDevice �����ͷ��������������� stop ��ȫ����һ����� OGKM/XNU �� freeDevice ǰ��ʧ�� pre-quiesce ��ͬ������ research/gpu-safety-20261017/reports/DELIVERY-R2.zh-CN.md��δ�ύ�����͡����� Actions���� .agent ���豸��

## 2026-10-17 �û���ȷ���� GPU ���ߣ�Դ���ѡ R1�������� NO-GO

�����û���������ȷ GPU ���ȡ������ݻ������� D-18 �����ȼ����᣻������ϵͳ���豸Ȩ�ޡ��̶����� NullMoth v2.3.3/ac55984 ���� gpu-safety-r1.patch��CPU �����߽硢IOSurface GPU �ȴ�ʧ�ܡ�ע��״̬�ύ������������ԴӦ��/����ع�����ʵ CPU ͼ�񿽱��Ѳ��ԣ�Darwin ����/Kext ����δ���С�v2.3.3ʵ��kext��2.3.1�ֽ���ͬ����tagԴ�뺬�°��������ɻ��������ݡ�BRIDGE-06���0002ʵ��ȱʧ��δ���ƻָ���stop��ӳ�侺̬����ͷ�ڴ�owner����ʵDMA/GSP���������о�֤�ݺ�native�ֶ��������� research/gpu-safety-20261017/�������Ǵ����ĸ��ǲ㣬δ����/δ��.agent��

# 02����ǰ��ʵ����������ߣ�Codex ����״̬��

## 2026-10-17 Ψһ���ߵ�ǰ״̬��H1 �ѽ������棬H2/H3 ���ȣ�H4 ����

Ȩ���������ƫ�ƹ���[12_MAINLINE_ALIGNMENT.md](12_MAINLINE_ALIGNMENT.md)��**��Ӧ�ӱ��ĺ���� DMA ���������ж���Ŀ����������**��ʵ�� 2026-10-15 �״ν������ SSD macOS ��ʽ���棬Intel ���� 2160��1440�����̿��ã�Wi-Fi/���ذ岻���ã����������ȡ�������˯�ߵ�δ�������գ��� GPU No Kext Loaded�����濨�١�H1 ��װ/������Ŀ���Ѵ�ɣ��������ٴ������� Windows/���˸���ȱ֤�ݡ�H2 �豸�����Ծ���Ϊ��ǰ��������H3 ��ʾԴ�����ˢ����֤�ݣ�H4 NVIDIA DMA/GSP ��ǰ����Ϊ�о���������ʷ [DMA 40/40](../scripts/g1/P0_DMA_20261017_EVIDENCE.md) PASS �;� Xcode API ���� PASS �����ڼ��٣����� 17 �� C++ / Segment64 SDK ��֤��δ���У��ݲ����������������������;���Ȩ��ֻ��ʵ��ȡ֤������ϵͳ�޸���Ȩ��


## 2026-10-17 P0-DMA ���� IOVM64��RM page-array C++ ��ͬ��δ������ CI��

Դ���ύ 410ad56���������ֵ�ַ��ת������17 �� CPU-only C++ ������ Apple IODMACommand Segment64 �� compile-only �Ž�Դ���ύ 71e6b5d ��չ macOS 15 Intel/Xcode16.4 ̽�룬ֻ���������/nm/ɢ���ı��������������Ծ�δ���У����ܳ�Ϯ 40/40 �ɲ��Ի�� native SDK �� PASS��������ͬ�� scripts/g1/IOVM_PAGE_ARRAY_CONTRACT.md����ʵ mapper ��Դ��nv_xnu_alloc::md prepare ���ݡ�RM pOsData ownership��GSP DMA/quiescence �� KDK ABI ȫ�� NO-GO��


## 2026-10-17 G1 P0-DMA 40/40 CI & ��ʵ DMAR ���� PASS�����а�ȫ�� NO-GO��

[Actions #38939252741](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741) ���ύ `791ba38a9bef3e5acb8a8a1e6901b3e434b37d2e` ʵ�����У�10+13+11+6 **40/40 PASS**�������̶�������Դ���������ʵ�� 136-byte DMAR ��̬���˽���ȫ PASS��������ʵ JSON �� SHA256 �����ü��� [ר��֤��](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)�����������ظ�������ȫ��ͬ�� CI��DMAR ����Ϊ���� DRHD��`0xFED90000` ��Ժ��� `00:02.0`��`0xFED91000` �� `include_all=true`��RMRR ����Ժ��� `00:02.0`����Χ `0x4C000000�C0x503FFFFF`��68 MiB������ǰ Windows RTX 2050 `01:00.0` Ԥ�����ڵڶ� DRHD �Ĺ̼���Χ�������� OS ��������ʵ IOMMU domain��Ŀ�� macOS IOVA/GSP/DMA/stop һ�� `NO-GO`��


## 2026-10-17 ���� P0-DMA ��������ʵ���ۣ��������޸���

- [Darwin DMA SDK #38931389598](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931389598) ���� **SUCCESS**������ `71ebc42`��Xcode 16.4��16F6����SDK macOS 15.5��Intel x86_64��`CLANG_RC=0`���ձ�����־��Mach-O 64-bit object x86_64��֤�� artifact 12059785493��ֻ��֤ C++ API ������룬��֤���ں����ӡ���ʵ IOVA/IOMapper/GSP DMA��
- [P0-DMA #38931378828](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931378828) **FAILURE**��10/10 Դ��+13/13 ����ģ�Ͳ���ͨ����RM 11 ��� 9 ��ͨ�������� 2 ��� `//` ע���̵���ͬ�� `}`�����²��Դ������������˲��պ� C �������쳣��Ϣ����Բ������� `set -e`���̶�����ȡ֤�� DMAR JSON �����**δ����**��
- ���޸��������� fixture��[`636ac9a`](https://github.com/Jakiewbe/honor-hackintosh-lab/commit/636ac9a967b4825750bc163f6e8ec3348778b254) ���� `/* ... */`����Ҫ��ע��α��ĸ�ֵ����ͨ�� RM audit�����޸�**��δͨ���µ� CI**����Ӧ��ǰ���� 40/40 PASS��ʵ������/GSP/PCI/EFI/BIOS �� NO-GO��


## 2026-10-16 P0-DMA ���£�Դ����Ʒ������� + ʵ�� ACPI DMAR ����ȡ֤�����ƶ� CI��

���� [RM ��������������޸�](https://github.com/Jakiewbe/honor-hackintosh-lab/commit/479e3459ef17e99e8f459219dd963b781ec13d5e)����ǰ����ʹƥ�䵽 **ע���еĸ�ֵ**Ҳ�ᱻ������ʵ�� `pOsData=pPriv`���ڸ��뻷�����Ѹ��֡��������޳�ע��/�ַ������ٺ˶�ʵ�� peer ��֧�� NULL �ĸ�ֵ�� failed-unmap �Ƿ���ǰ�˳������������������RM ר��������� 7 �� 11��**�����صȼ۲�����֤��Զ�̵�ǰ�ύ��δ����**��

ͬʱ���� [DMAR �ṹ��������](https://github.com/Jakiewbe/honor-hackintosh-lab/commit/444e959421edaa61beac09ffc1dd0360cff58e67)���ֿ����ʵ�� Windows P40 ACPI ֤�� `docs/hardware-survey-20261012/evidence/acpi/fw_DMAR.bin`��136 �ֽڡ�ǩ�� DMAR��ACPI У����� P40 ������Ϊ�棬SHA256 `e84c886dfcc89640faf9c3386d5fbb4dc77483901c816eb38fdcb22a6c298f86`���� `dmar_evidence.py` ����ǩ������ DRHD��RMRR��ATSR �� PCI device scopes������ `dmar-topology.json`���� 6 ��ϳɱ��ṹ/������������ PASS��**ʵ��ʵ�� DMAR ����ϸ�û���� CI ����**��DMAR ACPI �����ڲ�����Ŀ�� OS �������� Intel VT-d���������� RTX2050/GSP ����ȷ DMA��RUNTIME NO-GO ���䡣


## 2026-10-16 P0-DMA RM IOVA ӳ������Ȩ��֤�ݣ������� CI��

�̶� NVIDIA 610.57.04 �� [os.c](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia/arch/nvalloc/unix/src/os.c)��Git blob `b441a66fe735e834f830bae9344333c31b16c1f2`����ȷ�ϣ�`osIovaMap` ͨ���ֲ� `pPriv=memdescGetMemData(...)` ��ӳ���ַ���齻�� `nv_dma_map_alloc`���������ؾ����¼Ϊ `pIovaMapping->pOsData`��NullMoth �̶� `os-xnu2.cpp` ��ӳ��ص����þֲ�ָ����ղ����� `NV_OK`��ʹϵͳ�ڴ�ӳ���¼�ڸ�·����Ϊ NULL��RM `osIovaUnmap` �� `pOsData` �Ƿ� NULL ѡ�� system DMA �� peer DMA �Ľ��·�����������ڵײ� DMA unmap ʧ�ܺ�����ո�ӳ���¼��**��Щ��Դ���������������֧֤�ݣ�����ִ�е�Ӳ��·����**

���ȹ��ڡ�ԭʼ���� `nv_xnu_alloc` ָ���Ȼ��ʧ�����жϲ��������� RM ����·���þֲ�������ԭʼ�����¼�Դ��� memory descriptor���� `osFreePagesInternal` ʹ�á��� [`dma_rm_path.py`](../scripts/g1/dma_rm_path.py) �� 7 ��������д���ֶ� DMA CI��**�²�����δ����**����Դ��汾�����������������̲�ͬ��Ҫ�������˹���顣ԭ [Darwin SDK ̽��](../.github/workflows/g1-darwin-dma-sdk.yml) ͬ����δ���С�ʵ�� IOMMU/GSP/�豸 DMA/Ŀ���ں� ABI һ�ɱ��� `RUNTIME_NO_GO`��


## 2026-10-16 P0-DMA ���¹�����Darwin API ԭ����������ִ��

[P0-DMA 23/23 �ϳɲ���](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38903242709) ����ʵͨ�����̶�Դ����Ʒ��� `BLOCKED_DEVICE_DMA_MAPPING_UNVERIFIED`���������� `scripts/g1/dma_sdk_probe.cpp` ��Ĭ���ֶ� `.github/workflows/g1-darwin-dma-sdk.yml`���˶� Xcode 16.4/macOS15 Intel SDK �е� `IODMACommand` ���� C++ API �� x86_64 �ں˶�����롣**��ǰ������δ���У����ܱ�� SDK BUILD PASS����ʵ IOMMU/IOVA��GSP/DMA ��Ŀ���ں� ABI �� NO-GO��**


## 2026-10-15 �����������ѽ������棬�Կ�������δ��֤

�û�ͨ�� H1-COUNT Խ�� EXITBS�������� SSD ��װ��������ʽ���棻���� 2160��1440 ����ʾ������ GPU ��ϵͳ�����Ϊ No Kext Loaded�����濨�٣�����Ӳ���������ա��û��ѹػ������׶�ֻ���Կ����������Ե��У�û�а�װ��������������޸� BIOS �����򴥷� CI��

����[���й鵵](../research/gpu-feasibility-20261015/README.md)��·�߱Ƚϡ��̶�Դ��汾�����¼��RTX2050 ��Ⱦ�� Intel �����Ž��Ǵ���֤��������ǰ��¼�� 31 ��ͨ����0 ��ʧ�ܽ�ΪԴ��/�ĵ���飻û����ԭ��������Ӳ�����ԡ������ϴ��ѻ��û���ȷ��Ȩ��ԭʼ��Ƭ���豸��־��EFI �����������Ʋ��ϴ���

**���±�����ʷ��¼�����С��Կ� EXITBS������δ���� macOS���������Ѳ����������û�ʵ�⡣������������δ���ս����Գ�����.agent/ ����δǨ�ƣ�����ʱ���ȶ�����������**

---


**����ʱ�㣺2026-10-12��������̱���R1.4-C0.1 PCI/��Դ�ӿں�ͬ�������հ�δ���ա�**

**��״̬��`R14C01_POWER_CONTRACTS_BLOCKED / R14C0_SOURCE_SLICE_RECORDED / FREEBSD_BASE_CANDIDATE_PINNED / DEPENDENCY_CLOSURE_BLOCKED / NO_INDEPENDENT_DRIVER_BUILD / NO_HARDWARE_RUNTIME / RUNTIME_NO_GO`��**

> ����ļ��ǡ�������ô������**��һ���**����ʷ�����¼��ʱ����ʵ����������������ж϶���д�ɡ���ʱ�Ѿ�֪��������һ�׶���ɺ����ͬ�����´��ļ���

## �����Ѿ�ȷ��������

- [R1.4-C0](../docs/R1.4-C0_����i915Դ����ӿ���������.md)�����̶����β��Ծ������ FreeBSD `release/14.3.0` Ϊ��ѡ `8c9ce319fef765890ce518cab85d3a470b669849`��156 ��Դ��/ͷ�ļ�/����/�����ı�����92 ����/79 Դ���ϵ���������߲��� **25 ͨ����0 ʧ��**�������հ��Ž�**�˳� 2���ܾ�����**��û�� native/ABI/Ӳ���ɹ���
- base PM �ճɹ���GT/uc ���� probe ������ ADL-P plane �ص��Ѷ�λ��DMC ȱ payload ʱ���α�����Դ���á�14 ����� XNU Э��δʵ�֣��� [�ӿں�ͬ](../research/independent-i915/required-apis.md)��

- ��ҫ GLO-FX6P��Intel 12500H��Intel 46A6��RTX 2050 25A9 ����ʵӲ��������**��ǰ�������� Intel** ��ȷ�ϣ����ܰ� RTX 3050 ����������δ֪��չ���о���
- `NMIntelFB` ������ GitHub `macos-15-intel` Runner ����� **x86_64 real + virtual ���ַ�֧ԭ������� kext ��̬����**��R1.2-C ��ʽ [Actions #38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450)������**�ɺ�ѡ�� BUILD-PASS**���������ǵ����� Intel-only kext��
- Apple �ٷ� macOS 15.5 �� IOGraphics-599/XNU 11417.121.6 ����Դ���Ѻ˶԰汾�� SYS��FB ����[R1.2-F Actions #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259)��
- VBL 40/40 ����ο�ģ�� + 10 ����ʵ Apple IOFramebuffer VBL consumer �ṹ����ͨ����[R1.2-G Actions #38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141)��**Դ�������δ�ر�**���Ҹý׶�û���ں˰�ȫ֤����
- NullMoth v1.14.2 �ṩʵ���� NMXGPU Intel i915��DRM��IOFramebuffer Դ��·����**�����ĵ���ȷδ������ Intel GPU �ϼ�����֤**��NMXGPUFB �Ļص�ע��/����ԭ��Ϊ��ʵ�֣�timer/stop/ͬ����ֹ��Ǳ���������ڷ��ա�
- R1.3-D [Actions #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373) �˶� v1.14.2 ���ʲ� SHA256������ 172 ��·������ NMXGPU kext binary��**δ����֪���Ƶ� GPU �����嵥/Դ��/����Ŀ¼**����ֻ����**�������η�����**������ֹѡ�񹫿�Դ�������з���
- �� NullMoth ��ʽ�ύ [Issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146) ��ȡʵ�ʱ������룻���ٿ��ظ� Issue����ǰ���ʱ [PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131) δ�ϲ���`NVRMFBClaim` ����ƥ�� Intel ��ʾ��������δ�õ��汾֤�����޸���
- ���ҵ������з���**�汾ϵ�к�ѡ** Linux [v6.1 `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`](https://github.com/torvalds/linux/tree/830b3c68c1fb1e9176028d02ef86f3cf76aa2476) + FreeBSD [drm-kmod/6.1-lts `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`](https://github.com/freebsd/drm-kmod/tree/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4)���� FreeBSD `i915_pciids.h` �п��� `0x46A6`��**δ֤����ֿ� ABI �� FreeBSD base LinuxKPI �汾ƥ�䡣**

## ��ǰ���뱣�� BLOCKED ����Ŀ

| Gate | ����ȱʲô | ��Ӧ��Ρ������ |
|---|---|---|
| **P0-SOURCE** | base ��ѡ�ѹ̶�����������/���� includes/��������δ�պϣ�12 �����ļ�������֤��ȱʧ���������δ���� | ���Ѳ��Ծ������гɹ�������Դ�� slice �������հ� |
| **P0-ABI** | XNU �� LinuxKPI �������жϡ��ڴ�/PM/DMA��IOKit ��ԴЭ����δͨ����ִ�еĵȼ�����֤ | ���� `return 0` Stub α�칩��/�̼�/ӳ��ɹ� |
| **P0-SCANOUT** | ����ACPI�Ѹ�IGDM/ASLB�ֶΡ�����_DOD/_ADR�뱳��֪ͨ������OpRegion/VBT������δȡ�ã�ASLB��ֵ��UNKNOWN���̶�20250404ѡ��-e���16ͨ��0ʧ�ܣ�DSDT�����ⲿ�������棬EDMX��UnknownObj��AUX/CDCLK/Power Well/PLL/PHY��GGTT backing��ʵ��scanout��δ֤�� | ���ٶ� Stolen base = GGTT 0 = Framebuffer����ֱ��дδ֪����/PCI �Ĵ��� |
| **P0-PLATFORM** | Intel 12500H P/E ��Ϻ��� macOS �ں�/ACPI/�����ɿ���δ�������� | ���� GPU ����ͨ�������������� |
| **P0-LIFETIME** | VBL ע��/ע����ֹͣ/�ص��ͷš�SYS/FB ����ȶ���ʵ�ֵ�֤��ȱʧ | ���ظ��ѵ�ԭ `NMIntelFB` VBL ΢�� |
| **P0-NV** | RTX2050 `10DE:25A9` ACPIλͼ/PEGP._DOD/��Դ�������о�̬��¼��MUX���޷��жϣ�NOPR/GPIO/ECʵ��״̬δ֪������GSP/NVRM/NVAccel/Metal��ʵ��֤�ݣ�r610��ȱDarwin���� | ���� PCI ID �ڱ��л� Metal ��Ϣ�ַ�����Ϊ��ʵ���� |
| **P0-SAFETY** | �޶��� Intel Xe Ӳ���ָ����������� Windows �ķ���/BitLocker/EFI/�ָ�����δ�� | ������������װ���޸� BIOS/EFI���ر� SIP ����� kext |

## ������ʲô��������ʲô

**��ǰR1.4-C0-pre��̬����ѽ�����ѡ��-e���16ͨ��0ʧ�ܣ�ԭ����ͻ������Ϊ������������һ������R1.4-C0 T0��T4���Ѷ�λPEG1/HS10�ظ��ʹ������Դ�ظ���ѡ�������ɹ���T2���뱾����������ʵACPI/PCI/OpRegion�����ߺ�ͬ��C0.1ʵ������/Ԥ������IOPCIFamily��Դ��ȱ�ڼ���������** �����հ��ͱ�Ҫ�ӿڹر�ǰ�������� native ����� kext ԭ�͡�

**��֪ʶ��/AGENTS.md ���ύֻ��һ��ƽ��ĵ�����ɣ������ƽ� kernel �������еȼ���**

�鿴 [10 Codex ����](10_CODEX_HANDOFF.md) �� [08 ���������ƻ�](08_ENGINEERING_ROADMAP.md)����ʵ���ÿһ����ʽ CI �������� [03 ��ʷ](03_RESEARCH_HISTORY.md)��[04 ֤��](04_EVIDENCE_LEDGER.md)��

## 2026-10-13 ���䣺1401 ֻ�����֧�ߣ�D-16��

- ��� 1401 v1.14.2��`46d9fee`�������� v1.14.2��`1083a98`����Դ����ƣ������ [INITIAL_AUDIT](../reports/INITIAL_AUDIT.md)��**δ���� 1401��δ���� EFI��δд�κδ���/�̼���**
- ����ȡ��Ӳ����ʵ��RTX 2050 PCI ���� **`0x0302`��3D ��������**������ʾԴ 0������Ŀ�� 0 һ�� �� ǿ��ָ�� muxless���ƶϣ���
- 1401 ��ƾ�豸���� `25A9` ��Ϊ macOS 15 ���ã�`tested` ֻ�� `2D05`����ͬʱ�Ա��������໥ì�ܵ�������ʾ��װ������ `NVRMFBClaim` ��ռ Intel ֡���壨driver#119���޸� PR #131/#133 δ�ϲ�����
- ������`nullmoth/1401#26` ����ʵ��ͬ CPU��i5-12500H���������� [11 �� 5 ��](11_EARLY_RESEARCH_AND_1401.md)��
- ��״̬���䣺`RUNTIME_NO_GO`��L1 ������һ������ R1.4-C0��
- ͬ�պ������û�����׼����ɳ�������� 1401 ɨ��/plan/build�����ɺ�ѡ EFI ��ͨ�� OpenCore 1.0.9 ocvalidate�����ṹУ�飩��EFI δд���κδ��̡��� [docs/1401-plan-run-20261013](../docs/1401-plan-run-20261013/SUMMARY.md)����һ����δ���� 1401��δ���� EFI���ǻỰ 1 ��ʱ״̬��

## R1.4-C0.1 ������������һ��
55��Դ�������C0����26�ļ�����32����/14ֱ�ӵ��ã�ʵ��BSD������������������/Ԥ������δִ�С�
21ͨ��0ʧ�ܣ��ṹ�˳�0���հ��˳�2����Դ��ʱ������hw_enabled��ֵ֤���ɹ���XNU PM��ֵ���Ǿܾ�����
16���ļ�������δ֤����76��slice��include������XNU��ͬBLOCKED�����±����Ӳ��֤�ݡ�
��һ��C0.2�̶�IOPCIFamily/PCI-MMIO-PM������������������飬���[����](../docs/R1.4-C0.1_PCI���Դ���ӿں�ͬ.md)��

## R1.4-C0-pre��SOURCE-STATIC��
[ԭ����̬֤��](../research/acpi-static-20261012/README.md)��36��У��ͨ����ͬһiasl20250404ѡ���ⲿ�������16ͨ��0ʧ�ܣ���ʷʧ����־������38��findings�ж�λ�������ظ���Ӧ����PEG1������HS10����MUX/����/OpRegion�޹ء�DSDT�ⲿ����������EDMX UnknownObj�Ա�����NVS/OpRegion����δȡ�ã�RUNTIME_NO_GO��


