> **2026-10-18 NVLink ��˺�ѡ��** �Ѽ����ĸ���ʵ Darwin semaphore �ӿڼ� CPU ����/���Ϻ�ͬ��������������ͬ run ��/�޺�˵����Ӷ��ա����ȴ��ж����ԣ����� void �ӿڲ��ɻָ�����Ϊ���� panic��free ��Ҫ����÷��ſա����߼���ѹ���CPU C++ ��ͬ���� Darwin/������δִ�У�δ������ȱ���ѹرգ��豸���� NO-GO��[��������](NVLINK-DARWIN-LOCKS-20261018.md)��

> **2026-10-18 ʵ�ʹ�����չ��** [run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) �ѳɹ�ִ��Դ���ύ `30485ae`��ȫ��1,280��C TU��5��shader����ͨ����RM/modeset�����鵵��NVRM�ؽ���ѡ�����ӡ���ǰ����UNKNOWN��������nm�й۲쵽���壻�����ĸ���֪NVLink���ڲ����룬����471��Ŀ�굼��/ABIδ���ա�������profileѡ������һ�²����Ǳ���������TU������**��ʼ����GPU��Ⱦ�����ض��ؾ�δִ�У������в��ɽ������豸NO-GO��** ��һ�����ĸ���ʵDarwin���ӿڡ���������ABI��Ŀ�굼�����顣[�����֤��](FULL-SOURCE-BUILD-20261018.md)��[��ҳ��ֻ������prompt](FULL-SOURCE-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R80 ������������Դ��** ���� Mach-O ת C ����ʱɾ���»��ߵ����⣻���� UNKNOWN �����λΪ�������ݡ�һ�����һ������ݼ�һ�������䷽��ѡ���ѽ��뱾����ʽ�����ϣ/��ȷ����ȡ֤��47��߲��Լ�������ʷ�ع�ͨ������ Darwin/�����ṩ��/����/ABI ��δ���У������հ����豸�� NO-GO��[����](R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md)��[��ҳ�˸��� prompt](R80-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R79 ��ƾ�����** �ѳ��ء�45�����ű�Դ���롰351��667֤�������հ�����������������ͬ������ʽ�����嵥���ޡ��̶�346������ɨ��Ϊ337���ʷ���ѡ��9��UNKNOWN���зǶ���հ���27��߲��Ժ�������ʷ�ع�ͨ����������TUѡ��ABI����������ϸ��ı���������Darwin/����/ABI��δִ�С��� [���ֱ���](R79-AUDIT-CLOSURE-GATE-20261018.md)�������հ���ʵ������NO-GO��

> **R28����ʵ���� owner-copy ���󴫲���ѡ��** �� Unsupported ���ˣ�����ִ�д���ԭ�����أ�symbol ����ʧ�ܷ��� NoMemory����ʵ���� CPU ��ͬ 15/15���ɻ��� 6 ��Ԥ��ʧ�ܡ�����ʧ�ܸ��غ�������������ͨ��������ԭ���Ž���δִ�С�[������֤��](R28-OWNER-COPY-ERRORS-20261018.md)�������հ�/ABI �� P0-1/P0-4 �������ţ�ʵ�� NO-GO��

> **2026-10-18 ��ǰ G1 �ϵ㣺�����հ��� ABI��** �Ѷ�λ�Ĺ����ṩ�����贫�������벼�ֺ��飻�����Ծ� R13/R48 �ĵ��϶�Դ��ȱʧ�����תʵ������ [������������һ��](G1-CLOSURE-ABI-AUDIT-20261018.md)���������� 35 ������������������ TU �� altstack/NULL ջ��������֤�ݼ���ȷԭ��Ԥ����/�����ṩ�߲ɼ���ڣ�����ԭ��ȡ֤��δ���С�P0-1/P0-4 �Կ��ţ�KEXT-LOAD NO-GO��

# GPU ���� R5�CR7���ر�·�������������ʼ���ع�

״̬��**SOURCE-REVIEW + HOST-TEST + PATCH-APPLIED �Ѵ�ɣ�DARWIN-COMPILE / KEXT-LINK δ���У�KEXT-LOAD �� GPU/�������� NO-GO��**

�̶����룺NullMoth `v2.3.3` / `ac55984c473e746c2a8ebea7ba0913461aa7c393`��OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`��

## ������������ʲô

| ���� | �ļ� | ���� | �޷� |
|---|---|---|---|
| `nullmoth-r5-kms-close-deferred.patch` | `kexts/NVRM/os-nvkms-xnu.cpp` | `kms_close_common()` �� PM �ȴ�ʧ�ܺ����� `popen->data` ���ͷ� wrapper���� `nvidia-modeset-os-interface.h:288-301` �涨��ָ����� NVKMS ֮��ش� `nvkms_event_queue_changed()` �� `pOpenKernel`������ NVKMS ��д�����ͷ��ڴ� | ʧ�ܼ����� per-open / wrapper / event worker���� `closing`���ܾ��� ioctl������ʧ�ܣ����ٰ�"û�س�"��"�غ���" |
| `nullmoth-r6-kms-close-reclaim.patch` | `kexts/NVRM/NVRM.cpp` | r5 ֮�����̬û�л����ߣ�Ψһ���������û�е����ߣ�й©�޽��Ҳ��ɹ۲� | ����ʱ������`gpuResume()` �� `nv_xnu_pm_open()` ֮��PM �̡߳��ǻص�������ɨһ�λ��գ�ֻ�� sysctl `debug.nvrm_kms_close_deferred`������ʧ��ʱ���ݼ�������װ�ɹ� |
| `nullmoth-r7-kapi-device-rollback.patch` | `kexts/NVRM/fb/nvrm-fb.cpp` | `kapiInit()` �Ƚ����� `NvKmsKapiDevice`��`gDev`���� `grabOwnership`���ٲ���ʾ�����鲻���ͷ���ʧ�ܣ����������ջء����� framebuffer �Ḵ������������ `privateData`/`eventCallback` ָ����ʧ�ܵ�ʵ�� | RAII �ع������Խ� Device �� `releaseOwnership` + `freeDevice` + �� `gDev`������·������ Device�����黹����ռ�õ� head λ���ɹ�ʱ��� |

Ӧ��˳��˳�����У�ȱһ���ɣ���

```
gpu-safety-r1.patch �� gpu-safety-r2-kms-open.patch �� nullmoth-r3-thread-call-comment.patch
�� nullmoth-r4-bridge-owner.patch �� nullmoth-r5-kms-close-deferred.patch
�� nullmoth-r6-kms-close-reclaim.patch �� nullmoth-r7-kapi-device-rollback.patch
```

## ��ʵ�⣨�������빤���� `D:\Hactk\gpu-r5-20261017`��

| �� | ���� | ��� |
|---|---|---|
| 7 ��������Դ������ + ���� | PATCH-APPLIED | ȫ�� exit 0��611 �ļ�����ϣ pristine `ea9467f4��` �� applied �� ��ԭ `ea9467f4��` |
| �رպ�ͬ����ʵ������ + ASan/UBSan�� | HOST-TEST | ��ѡ 40/40����ǰʵ�ִ��� heap-use-after-free���ͷ�ջ�� `kms_close_common` �� |
| bridge-owner������������� | HOST-TEST | 9/9 |
| �ع������� | HOST-TEST | 15/15 |
| ���õ�/������ͬ | SOURCE-STRUCTURE | 12/12 |
| �ع�������/����Ȩ��ͬ | SOURCE-STRUCTURE | 14/14 |

## ͬ�ּ�¼��֤������

- **R4 �Ž��ھ�**��`scripts/gpu-safety-r4/native_compile.py` �Լ� `-Wextra -Werror`�������� `build/accel_build.sh` ֻ�� `-Wall` + ���� `-Wno-*`������ϴ� R4 ������**δ�Ķ���ԭ�����**��Ҳʧ�ܣ�`IOPCIDevice` ���ñ�����Ϊ���󣩣��Ժ�ѡ����Ϣ����r5 �Ž���Ϊ���οھ���������"��ѡ���ñ�ԭ���澯"�Ĳ�ּ���� NVAccel kext ���Ӳ��衣
- **R4 fixture �����ղ�����һ��**���ѷ����� `evidence/r4/bridge-owner-actual.cpp` �� `sKms`/`sKmsEvents` ���������ղ����������ڵĻỰ����`inputs.json` ��¼�� `NVRM.cpp` ��ϣҲ��˲��ɸ��֡�����**���ܲ���**��`externalMethod` �ѳַǵݹ� `IOLock` �ٷַ��� `sKms`���ڶ��λ�ȡ��������

## ������б��Ž������ֶ���

GitHub UI �� Actions �� **HONOR GPU safety R5 native object and kext link gate** �� Run workflow��
��֧ `main`��`xcode=Xcode_16.4`�����᣺

1. У�������̶� commit��
2. ������Դ���ϰ��� `git apply --check` ��Ӧ�� r1�Cr7��
3. ������ `accel_build.sh` �ھ����� original/candidate ��� C++ TU �� KAPI C ��Ԫ��
4. �Ƚ�ÿ��Ԫ�澯������ѡ���ö���ԭ�棩��
5. ���������������� NVAccel kext��ֻ���ӣ������أ���
6. �ϴ��ı������ `native-report.json`��

**����**��װ�����ء�ǩ���������κ�������Ҳ������ GPU��

## ��δ�պ�

- `super::start()` �� `kapiInit` �ɹ���ʧ�ܣ��Լ����һ�� framebuffer ֹͣ / kext ж�أ���û�жԳ�����·����F5b����
- `freeDevice()` ���� void������ʧ�ܲ����ϱ�����·�������Ⱦ�ԭ���Ž���
- KAPI �¼��ص��� Device ���ٵ��Ⱥ�˳��PM busy ���Խ� standby��VRAM/GPUVA �� sleep �޴��ʡ���ʵ IOMapper/IOVA �� GSP DMA ��Ĭ����ȫ��δ��֤��

## R8 �Ž�����ץ�����Լ��ı��������ͨ����2026-10-18��

���� R8 �������������У����̱����ǽ��۵�һ���֣�

1. [Run 39049358408](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049358408) `success` �� ���鿴
   `native-report.json` �ŷ��֣��Ž��ı��뵥Ԫ��**û�� `kexts/NVRM/fb/nvrm-fb.cpp`**���� R7/R8 �ĵ���������ļ���
   Ҳ����˵�Ƿ�"ͨ��"�� R7/R8 �㸲�ǡ�
2. �� `NVRMFB` �����Ž���[Run 39049526982](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049526982) **failure**��
   `error: 'dropKapiDevice' is a protected member of 'NVRMNVDAFramebuffer'`����**R8 ԭ�����벻��**��
   ��Ϊ�ع������������ռ�������Ľṹ�壬��Ȩ���� protected ��Ա������������ṹ�Ž���û���֣�ֻ��������
   Darwin �����ܷ��֡�
3. �������ĳ�**����Ƕ����**��`NVRMNVDAFramebuffer::KapiRollback`���������� R1..R7 Ϊ��׼���ɲ�����
   [Run 39049760247](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049760247) `success`��8 �� NullMoth ���� + OGKM ����ȫ��Ӧ�ã�
   **14/14 �������ɹ�**��original �� candidate �� 7 �� TU������ NVRMFB����profile �� exit 0���澯 25/25 ��ͬ����
   NVAccel kext ��Ȼ���ӳɹ���244400 B��`sha256 89f9839e��`����

��ѵд�����̣�**"�Ž�ͨ��"�����Ⱥ˶��Ž����ױ�������Щ�ļ�**��������ֻ��֤����û��������ǲ���û���⡣
### R9 �Ž������2026-10-18��

[Run 39050097952](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050097952) `success`���ύ `c5e04ca`����**10 ������**��9 �� NullMoth + OGKM��ȫ��Ӧ�ã�
**14/14 �������ɹ�**���� NVRMFB����ÿ��Ԫ�澯���� original ��ͬ��NVAccel kext ���ӳɹ���244400 B����

### R22��2026-10-18������ȫ���� ���� ����"�Ĵ��˵ط�"

������ R17�CR19 �ĵ���**������**�������������Ҹ��˺�ȷ�ϣ�

```
$ grep -n nvAccelCopyToScanout kexts/NVRM/accel/nvrm-accel.cpp
32:   static bool nvAccelCopyToScanout(IOAccelResource2 *res);      �� ����
2113: static bool nvAccelCopyToScanout(IOAccelResource2 *res)       �� ����
```

**����õ㡣** �����ܵ��� `NVDisplayPipe::performTransaction()`������ `askFramebufferForScanout()` ֮��
ֱ���� `q.kva` ������R17/R19 �� owner-copy �Ž���û�˵��õĺ��������û�ġ�

### R22 �޵�����

1. **owner-copy �ӽ���ʵ·��**��P0 ����ȱ�ڣ���`performTransaction()` �������ü�����Ϣ����
   `NVRM_VRAM_FN_COPY`���ɹ������ء���**���� kva**��ֻ�жԶ˲�ʵ��ʱ�Ż��˵��ɵ� `q.kva` ������
   `q.kva` ��"����"����Ϊ"����"��
2. **�¶� grab ծ��ĳɼ���**������ P0-2����`gOrphanGrab` ������Ϊ `gOrphanGrabs` ������
   ���� framebuffer �� NVKMS ������ʱ�Ⱥ�ֹͣ�������ծ��`finishOrphanedDevice()` ��
   `while (gOrphanGrabs > 0)` ��ʹ黹�������ع鳡�� 16������ծ �� ���� release �� һ�� free����
3. **VBL ���ó��ж�������**������ P0-3����`armVbl()` `retain()`���� `stop()` �н細�������޷�
   `thread_call_free`��������ý����ص����ص��� `fStopping` ��֧�� `release()`��
   ����"ֹͣ�������õȴ�"��ͬʱ��**���󲻻�����**��

### R22 û���޵���������ʵ��¼��

- **P0-1��`nvkms_xnu_suspend()` ���� 5 s ��ʱ���������**��pin ֻ���ʹ��ڣ������ɻ��⡣
  ��ȷ�����ǰѹ���ĳ�"pin δ�������Ƴٵ����һ�� unpin ִ��"������Ҫ��˯��ʱ�������޷�����������֤��
  **���ֲ���**������ R23 �ĵ�һĿ�ꡣ
- **P0-4��`freeDevice()` ֮���ֹرձ��ܣ���Ȼ�����ͷ�**��R21 ֻ������¼��Ҫ������ֹ��
  ��Ҫ�� `freeDevice` ֮ǰ��ȷ��"�رջ᲻�ᱻ��"��������Ҫ OGKM �ı� void �ӿڡ������ڱ���Ŀ������Χ�ڡ�

### ˳�����֣����Լ��Ĳ��Խű����ͨ��

�ĳɼ������������Ա� `COMPILE=1` ȴ�Դ�ӡ `38/38 passed`������Ϊ������ʧ�ܺ�**������һ�εľɶ�����**��
���� `run-r11-test.sh`������ʧ��ֱ�� `exit 2`����ɾ���ɲ����Ҳ��ζ�� **R21 �Ǵ�"38/38"��ʵû��
�����**��ȱ `nvkms_xnu_kms_close_deferred_count` ׮�����Ǿɶ��������ܡ��Ѳ�׮������ **43/43 ��ͨ��**��

### ʵ��

[Run 39058264569](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39058264569) `success`��**22 ������**��**16/16 ����**���澯��������
NVAccel **248768 B**��R21 �� 248584��+184 ���ǽӽ���ʵ·���Ĵ��룩������ NVRMFB 315848 B��
�ṹ��ͬ 61/61 + 30/30���������� **43/43**��20 ��������������ϣ��ԭ��

## R21��2026-10-18������"�����ϱ�"���"�ɼ��������ж�"

P0-2 ����һ���ǽӿ���״���⣺`nvKmsClose()` / `FreeDevice()` ���� `void`��NVKMS �ܾ��رպ���÷�������֪����
֮ǰ��ֻ����Ϊ"���ɹر�"����"�������ϴ���"������"�޷��۲�"��

- `kms_close_common()` ���Ƴٷ�֧���ۼ� `gKmsCloseDeferred`����**����ԭ��**��PM δ���� vs GPU LOST �� `gKmsCloseDeferredLost`����
- ���� `nvkms_xnu_kms_close_deferred_count()` �����·��ȡ����
- `dropKapiDevice()` �� `freeDevice()` **ǰ��**��ȡһ�μ��������������ͼ�¼��
  "freeDevice returned but NVKMS refused the close �� RM state may be split; the void interface cannot report this upward"��

����һ����ʵ���غ���־����ֱ�ӻش�"�豸���׹ظɾ���û��"��������ֻ�ܿ���"���÷����ˡ�����֪�����"��

**��ʵ�ı߽�**������Ȼ**����**���󴫲��������÷��ò���ʧ�ܡ�����"����֪"����Ϊ"�º���ж�"��
P0-2 ��״̬��˴ӡ����ɹرա���Ϊ����̬�ѹرգ�R15��+ ʧ�ܿɼ�����R21��+ �޷����ϴ������ӿ����ƣ��Կ��ţ�����

ʵ�⣨[Run 39057316645](RUN_URL)��`success`����**21 ������**��**16/16 ����**���澯��������
���� NVRMFB **315848 B**��R20 ʱ 315744���� 104 B ����ȡ������־����NVAccel 248584 B��
�ṹ��ͬ **60/60**������ 6 �����������Ƴٷ�֧��ԭ����ࡢ������ס freeDevice���ܾ��ؼ���־����

## R15��2026-10-18������ pin �����ǿ��գ��ص� P0-2 �ľ�̬����

����ָ����`nvkms_xnu_pm_running()` ֻ��һ��״̬���գ�����굽�����ͷ�֮�� PM ���ܱ仯���ټ�һ�μ���Ǳ��ݣ�
������θĵ��ǻ��ƣ�

- `os-nvkms-xnu.cpp` ���� `nvkms_xnu_pm_pin()/unpin()`��**ֻ���� NVKMS RUNNING ʱ�����õ� pin**��
- `nvkms_xnu_suspend()` ���е� SUSPENDED ֮ǰ**�ȴ� pin ����**������ 5 s����ʱ��¼������������������ÿ�ס����
- `dropKapiDevice()` �� `finishOrphanedDevice()` �ĳ�**���� pin �ٲ��**��ÿ�����ڶ� `unpin`��
  �ò��� pin ����"���� + �� grab ծ��"�ļ���·����

��Ȼ**û��**�رյĲ��֣���ʵ��¼����`nvKmsClose`/`FreeDevice` ���� `void`��NVKMS �ܾ��رպ� `FreeDevice()`
�����ͷ� RM �ࡪ������ OGKM �Ľӿ���״�����ģ�ֻ����"��Ҫ������"��һ����������pin + ʹ���߼�������
�޷���ʧ�����ϴ�����P0-2 ��Ϊ**"��̬�����ѹرգ������ϱ��Ĳ��ֱ���"**��

ʵ�⣨[Run 39054729764](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39054729764)��`success`����**15 ������**��**16/16 ����**���澯��������
NVRMFB kext **315744 B / 174 ����**���������� **38/38**������ 4 �� pin ƽ����ԣ���"�ܾ� pin ʱ�����"����
�ṹ��ͬ **50/50**������ pin ���ɡ�suspend �ȴ� pin��`!fDev` ���˲��� pin����

## R14��2026-10-18���������ֵ� P0-1 ���� ���� �¶����ջ���ǰ�ͷ�

��������ķ����������Ҹ��ֲ����ˣ�

> A��B ���� `gDev`��`gDevUsers = 2`���� GPU ����ʱ A ֹͣ �� �� `gDevOrphaned` ��**��ǰ return��û�м�С����**
> �� GPU �ָ���C ��ʼ��ʱ `finishOrphanedDevice()` **����黹��˭����**��ֱ�� `freeDevice` ���Ѽ�������
> �� B �� `fDev` ��Ϊ����ָ�룬�� B �Լ��Ǵ� `grabOwnership` ��Զû������ͷš�

����ȱ�ݣ�һ����ƸĶ���

1. **PM-off �� stop ���ڷ����Լ��Ĳ�λ**��`gDevUsers--`������Ƿ�µ� grab �ǳ� `gOrphanGrab`��
   Ȼ���ٰѱ����� `fDev` ��ա�������������ʹ���ߡ�
2. **`finishOrphanedDevice()` �ȿ� `gDevUsers`**���������þ�**ֻ�黹���ߵ� grab**�����ͷ��豸��
   ֻ������ʹ��ʱ�� `freeDevice`�������"ȫ��ʹ�����˳�"��������
3. **�����߱� retain ���豸����Ϊֹ**��`allocateDevice()` �� `privateData`/`eventCallback` �ս��˴����߶���
   ���Դ����߱�����豸��þã�����ʹ������ȷ���ص���ָ�����ͷŵĶ����豸�����ͷ�ʱ���� drop ��� retain��

�������**δ�ر�**�ģ���ʵ��¼����

- **P0-2��NVKMS �ر�ʧ�ܲ����ϱ���**��`nvKmsClose`/`FreeDevice` ���� `void`��NVKMS �ܾ��رպ� `FreeDevice()`
  �Ի��ͷ� RM �ࣻ`nvkms_xnu_pm_running()` ֻ��һ�ο��գ���������֮�� PM ״̬�ɱ䡣
  **�������޷��Ǹ� OS ���һ�� pin��������ϣ����壬�������ټ�һ�μ��**��������Ҫ�� `os-nvkms-xnu.cpp`
  �� suspend ·������δʵʩ��
- **P0-3�����ؽű���**����**Ĭ�Ͻ���**���� `LOAD-EXPERIMENT-20261018.md` ������ű��ڵ� exit 90 ������
  �ĵ���"�û�����Ȩ"�ı�����ɾ����
- **R13 �ھ�**����Ϊ"�������� 649/17,679 �� 3.7%����� �� 2.15%"����ע�����߲�ͬ�ھ���
  ��� REA �� 7.93 MB ��͸���غɣ�"9 �� TU �����Ը���"��������**����**�ݴ��ƶ�����ʵ�ֲ�������

ʵ�⣨[Run 39054243492](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39054243492)��`success`����**14 ������**��**16/16 ����**���澯��������
NVRMFB kext **315680 B / 174 ����**���� R12 �� 311488 B �� 4 KB�������������Ȩ�޸�����������
�������� **34/34**������"����ʹ���� + ����ֹͣ + �����߻���"��"Ψһʹ���� + ���� + ����"������������
�ṹ��ͬ **45/45**������ 9 ���������ݼ���grab ծ�񡢹¶���ԽȨ�ͷš������� retain ��ԣ���

## R13��2026-10-18����NVRM.kext �޷��ù���Դ���ؽ���������������֣�

���⣺����ֻ���� `NVRM.kext` �����ƣ�û�й����䷽���ܲ����Լ���һ����

�������� `kexts/NVRM/` ��Ŀ¼��**ȫ�� 9 �� C++ ���뵥Ԫ**��`NVRM.cpp`��`os-xnu.cpp`��`os-xnu2.cpp`��
`os-nvkms-xnu.cpp`��`nv_xnu_stubs.cpp`��`nvrm_gpuva.cpp`��`nvrm_fbinfo.cpp`��`nvrm_surfshare.cpp`��
`nvkms_shaders.cpp`������ accel/agdc/fb ��Щ���� bundle�����벢���ӳ� `NVRM.kext`
��[Run 39051715396](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39051715396)��`success`��9/9 ���� exit 0������ exit 0����

����뷢�а���գ�Mach-O ���������ǹ��㣩��

| | ���ǵ����Ӳ��� | ���а� `NVRM.kext/Contents/MacOS/NVRM` |
|---|---|---|
| ��С | **361,768 B** | **16,787,920 B**��2.15%�� |
| `__TEXT` | �� | 14,155,776 B |
| �������� | 649 ���� | **34,302**��33,830 defined / 17,679 external�� |

���ۣ�**����"�ɹ�"��ֻ���Ƿ��а�Լ 2% �ķ���**���ֿ���Ҳû���κ�Ԥ�������`kexts/NVRM` ��ֻ��Դ�룬
������ 325 KB �� `nvkms_shaders.cpp`����Ҳ����˵ `NVRM.kext` �ľ��󲿷����벻�ڹ���������������
OGKM �� `nvidia-modeset` ����Դ��˽�й����ﱻһ����ȥ��

��ˣ�**`KEXT-LINK` �ĸ�������Ȼֻ�� NVAccel �� NVRMFB**�����ܰ���ε� NVRM ���ﵱ��"NVRM kext �ɹ���"��
�Ž��ֶ��Ѹ�Ϊ `KEXT-LINK_INCOMPLETE_UNIT_SET`��������һ���������

��һ���������������ߣ����� OGKM `src/nvidia-modeset/**.c` ���� NVRM �����ٱȷ��Ÿ��ǡ���������һ��������
���������ұ����Ȱ� `nvkms-kapi.h` ֮����ڲ�ͷ�ļ��հ��̶�������

## R12��2026-10-18�������� Device ״̬�ľ�̬

**��ȡ֤���ٸġ�** ������������Դ��������Ʋ⣺

1. **˭����������� Device��** OGKM `nvkms-kapi.c`���̶� `e4a5faa`���`FreeDevice()` ֻ��һ���Ǳ�����õ㡪��
   `AllocateDevice()` �Լ��� `failed:` ��֧��L988����ʱ�豸��δ�������ǣ���Ҳ����˵��**�豸һ������ɹ���
   ���������Լ��� `freeDevice()` ֮��û���κ�·����������**����֤�� `nvkms_xnu_pm_running()` ��Ϊ"
   �豸�Ƿ��ܱ���ȫ���"���о��ǳ�ֵģ����ش���� NVKMS �ܲ����� GPU���������豸�Ƿ���ڣ���
2. **`dropKapiDevice()` û�г�����** `kapiInit()` �� `startLock()`��`IORecursiveLock`�����ܣ�
   `stop()` ֻ�ڸ��� `gFBs[]` ʱ���ݳ�����Ȼ��**������**�ں���ĩβ���� `dropKapiDevice()`��
   �� `gDev` / `gDevUsers` / `gDevOrphaned` / `gHeadsTaken` ��ȫ�ֹ����ġ���һ�� framebuffer �� stop��
   ��һ���� start���ͻ�����Щȫ�����Ͻ�����

R12��`dropKapiDevice()` �� `finishOrphanedDevice()` ����ȡ `NVRMDisplayGate`������ `startLock()` �� RAII
�������ݹ��������� `kapiInit` �ڵĻع����԰�ȫ���룩���ò�������**�����豸������־**���������������

ʵ�⣨[Run 39051324224](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39051324224)��`success`����**13 ������**��**16/16 ����**���澯��������
NVAccel kext 244400 B��NVRMFB kext **311488 B / 174 ����**���� R11 �� 311376 B �� 112 B����Ӧ��������������
�������� **22/22**���ṹ��ͬ **36/36**����"drop ��ȡ gate""�ܾ��������""bind ·�������� kapiInit"����

## R11��2026-10-18������"����"�Ĺ��� Device һ���ָ�·��

R10 �Ĺ�����"NVKMS ���ܵ���ʱ�����"���������н�й©��R11 �����й©��ɿɻָ���

- `dropKapiDevice()` �� PM ��֧���� `gDevOrphaned = true` �����������
- ���� `finishOrphanedDevice()`��**����һ�� start ʱ**ִ�У���ʱ NVKMS ��Ȼ�ɵ��ã���
  ������ȷ�� `nvkms_xnu_pm_running()`���� `releaseOwnership()`���Ǹ�������ʵ��ץ�����Ҵ�δ�ͷŵ�����һ�Σ�
  �� `freeDevice()` �� �� `gDev` / `gDevOrphaned` / `gDevUsers`��
- `kapiInit()` ��һ���¾��ǵ�������Ȼ��ſ��Ǹ��û��½� Device��

����"˯����ж��"���µĹ¶��豸������ÿ��˯�������ۻ���������һ�μ���ʱ������������ʱ GPU �Բ����ã�
�ͼ�������������һ�Ρ�

ʵ�⣨[Run 39051079369](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39051079369)��`success`����**12 ������**��**16/16 ����**���澯��������
NVAccel kext 244400 B��**NVRMFB kext 311376 B��174 ����������**���� R10 �� 311192 B / 173 ������һ��㣬
���ö�Ӧ�������Ǹ����������������� **22/22**��12 �鳡������"�¶��� PM �ָ��󱻻���"��"�Թ������������"����
�ṹ��ͬ **32/32**������Դ�ļ�����������ֵ��ͬ����

## ���� NVRMFB �� kext ���ӣ�2026-10-18��

��һ��֮ǰ��`KEXT-LINK` ֻ���� NVAccel�����ְ�**����** `NVRMFB`���� TU��Ҳ����������
�������� NVAccel ���л������� bundle������û��Ϊ NVRMFB ���������У���һ���ڱ������ע����

[Run 39050754261](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050754261) `success`��

| �� | ��� |
|---|---|
| ���� | 16/16 exit 0��ԭ�����ѡ�� 8 TU�������� `NVRMFB` ������ `NVRMFB_LEGACY`�� |
| NVAccel kext | ���ӳɹ���244400 B |
| **NVRMFB kext** | **���ӳɹ�**��311192 B��`sha256 f845538e��`���������� 173��δ������� 481���ں�/�������룬������ |
| ���а� NVRMFB ���� | 306736 B��`sha256 6B8BEFFF��`�����ǵĲ���� 1.5%���������� SDK ��ͬ + �������룩 |

������ `KEXT-LINK_ONLY_NOT_LOADED`��ֻ֤��"������ Mach-O kext"��û���κ�ǩ������ء�

### �������ۣ�`kexts/NVRM/fb/` ����������

- `package/install.sh` �� `KEXTS="NVRM NVAccel NVRMFB NVRMAGDC"`��װ���� `kexts/NVRMFB`��
- �����Դ����ԣ�`test_bar1_budget.py`��`test_boot_raster_modes.py`��`test_display_power_retry.py` �ȣ�ȫ����
  `kexts/NVRMFB/fb/nvrm-fb.cpp`��
- û���κι����ű���������� `kexts/NVRM/fb/nvrm-fb.cpp`��

���� R7�CR9 ���Ƿݾɿ������޸���**�������޸�**���Է���������Ӱ�죬��������ֻ��Ϊ�˲���д����֤�Ĳ������У�
������Ч���� R10���Ž�ͬʱ�������ߣ���Ϊ����"�ķݱ��ġ��ķ�û������"���ٿ��ܱ����ԡ�

## R10 �Ž������2026-10-18��

- [Run 39050444884](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050444884) **failure**�������ļ��� `extern "C" NvBool ��` ������ `NvBool` �ɼ�֮ǰ ��
  `error: unknown type name 'NvBool'`��ͬһ�ֻ���¶ `rollback.armed = false` ��д�� `return true` **֮��**
  �����ɴ� �� �ɹ�ʱ������豸�����ɽṹ��ͬ�� "disarm before the success return" ���ץ����
- ������ [Run 39050580870](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050580870) `success`��**11 ������**��**16/16 ����**��original �� candidate �� 8 �� TU��
  ������ `NVRMFB` ��ɵ� `NVRMFB_LEGACY`����ÿ��Ԫ�澯���� original ��ȫ��ͬ������ NVRMFB 34/34����
  NVAccel kext ���ӳɹ���

## R10��2026-10-18����R7�CR9 �޴����ļ��������� NVRMFB ����һ�� `nvrm-fb.cpp`

�ֿ��������� `nvrm-fb.cpp`�����ߵ� `Info.plist`��`com.nullmoth.NVRMFB`��**��ȫһ��**��

| ·�� | ���� | ��С | ���ݲ��� |
|---|---|---|---|
| `kexts/NVRM/fb/nvrm-fb.cpp` | 1631 | 90725 B | R1/R7/R8/R9 һֱ�ڸ���� |
| `kexts/NVRMFB/fb/nvrm-fb.cpp` | **3406** | **210016 B** | ������� `nvrm-fb-safety.h`��`nvrm-allocation-table.h`��`nvrm_eld.h` |

�÷��а� `release-v2.3.3.tar.gz` ��� `NVRMFB.kext/Contents/MacOS/NVRMFB`��306736 B��
`sha256 6B8BEFFF��`�����ַ����б�

- ���ļ����д� **����**��`hot-plug: display 0x%x �� connected after boot`��`home flip #%u: pure`��`fbmodes: boot raster`
- С�ļ����д� **������**��`getPixelInformation ap %d`��`park ceiling reached`

Ҳ����˵**���а� NVRMFB �Ǵ� `kexts/NVRMFB/fb/nvrm-fb.cpp` ������**��R7/R8/R9 �ѹر�·���빲�� Device
��������������С�ļ��ϣ�����������**û���κ�����**���������ļ����ͬһ��ȱ�ݣ�`kapiInit` ʧ������
`gDev`��`super::start` ʧ�ܲ����ա�`stop()` �Ӳ��ͷţ���Ȼ���ڡ�

R10 ����Щ�޸���ֲ�������ļ���`extern "C" NvBool nvkms_xnu_pm_running(void)`��`gDevUsers` ������
`dropKapiDevice()`��PM δ������������Ƕ�� `KapiRollback`��`kapiInit` �ڰ󶨼�����
`fGrabbedOwnership`��`super::start` ʧ���� `stop()` �Ĳ�����á������ļ����� `fOwnsHead`��head λ����
���л��ƶ������¼��ֶΡ�

�Ž�ͬʱ��Ϊ����**����**�ļ���`NVRMFB`���������� `NVRMFB_LEGACY`���ɿ������������ٴγ���"������û��ʹ��
���ļ�"���ּ�ͨ����

�ṹ��ͬ�������ļ�����һ�飺**32/32**����"disarm �����ڳɹ�����֮ǰ"��������ץ��������ֲʱ��
`rollback.armed = false` д�� `return true` ֮��Ĵ��󣩡�

## R9��2026-10-18�������ֻ���������� NVKMS ���� GPU ��ʱ��

R8 �� `stop()` Ҳ�� `dropKapiDevice()`����**û�м�� NVKMS ��ʱ�ܲ��ܱ�����**���� OGKM Դ��
��`nvkms-kapi.c`���̶� `e4a5faa`����ȷ����������Σ�յģ�

- `ReleaseOwnership()` �� `KmsFreeDevice()` ������ `nvkms_ioctl_from_kapi()`
  ��`NVKMS_IOCTL_RELEASE_OWNERSHIP` / `NVKMS_IOCTL_FREE_DEVICE`����
- ���ǵ� OS ��� `nvkms_ioctl_from_kapi` ӳ�䵽 `kms_ioctl_common()`��������
  `kms_pm_wait_locked(false, 30000)` **���� 30 ��**��GPU LOST ʱֱ�ӷ���ʧ�ܣ�
- `FreeDevice()` �������Щ ioctl �ķ���ֵ���Ի����ִ�� `RmFreeDevice()` �� `nvkms_close_gpu()`��

����ڹ���/��ʧ״̬�´� `stop()` �����������������**� 30 �������**���Լ�**RM �౻�ͷš�KMS �౻�ܾ�**
��˺��״̬������ R5 �� `kms_close_common()` �ֻ���ʧ��ʱ���� per-open�������Ǹ� per-open �� `device` ָ��
ָ���ѱ��ͷŵĶ���

R9 ������������ `nvkms_xnu_pm_running()`���� `gKmsLock` �¶� `gKmsPmState == kKmsPmRunning`����
`dropKapiDevice()` ���ͷ� ownership / ���� `freeDevice()` ֮ǰ�������������������**ԭ������**����¼��־��
head λ�ճ��黹������������н�й©������"���� + ˺��"��

ʵ�⣺9 ��������Դ�������� exit 0������ϣ�ص� `ea9467f4��`����`dropKapiDevice()` ��ʵ�������������� **16/16**
����"NVKMS δ����ʱ�����"���������������ڽṹ��ͬ **27/27**����ν��λ�������ڶ�ȡ����

## R8��2026-10-18�������� Device ���������ڱջ�

R7 ֻ������ `kapiInit()` �ڲ�ʧ�ܡ�R8 ��ͬһ�������ɿɸ��õĳ�Ա���� `dropKapiDevice()`��������·�����ã�

| ·�� | ֮ǰ | ���� |
|---|---|---|
| `kapiInit()` ��һ��ʧ�� | R7 ��������ع� | ͬһ�� `dropKapiDevice()`���� RAII ���ã� |
| `super::start()` �� `kapiInit` �ɹ���ʧ�� | **Device ���� `gDev`��`privateData` ָ�򼴽��ͷŵ�ʵ��** | ���� `dropKapiDevice()` |
| `stop()` / kext ж�� | **�Ӳ��ͷţ�����й©** | �黹�Լ��� ownership �� head λ�����һ��ʹ���߲� `freeDevice()` |

���� `gDevUsers` ������ÿ�ΰ� +1��ÿ�� drop -1��`remaining > 0` ʱֻ�����Լ������á������� Device��
����ʱ�� `freeDevice()` ���� `gDev`���������ݱȶԣ����������Ĺ����豸����"�豸���ܱ����� owner ��ø���"
���������ȷ�ж�������������"ֻ��һ�� framebuffer"�ļ��衣

ʵ�⣺8 ��������Դ�������� exit 0������ϣ�ص� `ea9467f4��`����`dropKapiDevice()` ��ʵ��������������
**12/12**��ASan+UBSan�����������ڽṹ��ͬ **19/19**��

## ԭ���Ž������2026-10-18���״�ͨ����

[Run 39048772269](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39048772269) �� `completed success`���ύ `bfa7c3e`��`workflow_dispatch`��Intel runner��

- ��������macOS 15.7.9 (24G830) / Xcode 16.4 (16F6) / Apple clang 17.0.0 / macOS SDK 15.5 / GNU Make 4.4.1
- ��������ȫ��Ӧ�ã�r1 �� r2 �� r3ע�� �� r4 �� r5 �� r6 �� r7 �� OGKM
- **12/12 �������ɹ�**��original �� candidate �� 6 �� TU��NMIntelFB��NMIntelFBVirtual��NVAccel��NVKMSOS��NVRM��NVKAPI����ÿ���������Ž�У��Ϊ Mach-O 64-bit x86_64 `MH_OBJECT`
- **�澯������**��original/candidate ÿ��Ԫ�澯����ȫ��ͬ��7/8/24/14/33��������û�������κ������
- **KEXT-LINK ͨ��**��NVAccel kext ������ `build/accel_build.sh` ���������ɣ�244400 �ֽڣ�
  `sha256 89f9839e0f39bccf1336672e0f8a5e8c047dfd8408d3fe5d1d4e6128095e6cf1`��
  Ψһ��������� `ld` ���棨SDK 15.5 ��̬�ⰴ 15.0 ����Ŀ�����ӣ�

**���ִﵽ��֤�ݵȼ���`DARWIN-COMPILE` + `KEXT-LINK`�������ӣ�δǩ����δ���أ���**
`KEXT-LOAD` / `GPU-RUNTIME` / `DISPLAY-RUNTIME` / `ACCELERATED-DESKTOP` ��Ϊ **NO-GO**��
����û�м����κ�������Ҳû�з��� GPU��

### �ڶ������У����Ӳ������������κ���ϣ�

[Run 39049023927](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049023927) �� `3ef269e` ��ͬ�� `completed success`�������в� `-mmacosx-version-min=15.5`
�������һ�£������� ld ����Ŀ�꾯����ʧ��������־ֻʣ `ARGV` �� `EXIT=0`��
**kext �ֽ����һ����ȫ��ͬ**��244400 B��`sha256 89f9839e��5e6cf1`������˵���ò���ֻ��������ϣ�
û�иı�����Ҳ��֤��һ�εĸ澯���������ò�һ�¶���Դ�����⡣

��֪������`super::start()` �� `kapiInit` �ɹ���ʧ�ܡ��Լ����һ�� framebuffer ֹͣ / kext ж��ʱ��
�Գ�������ȱ��F5b�������� Device ��"���ʹ����"�ж���δ���塣


