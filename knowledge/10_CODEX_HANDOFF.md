> **2026-10-18 NVLink ��˺�ѡ��** �Ѽ����ĸ���ʵ Darwin semaphore �ӿڼ� CPU ����/���Ϻ�ͬ��������������ͬ run ��/�޺�˵����Ӷ��ա����ȴ��ж����ԣ����� void �ӿڲ��ɻָ�����Ϊ���� panic��free ��Ҫ����÷��ſա����߼���ѹ���CPU C++ ��ͬ���� Darwin/������δִ�У�δ������ȱ���ѹرգ��豸���� NO-GO��[��������](../research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md)��

> **2026-10-18 ʵ�ʹ�����չ��** [run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) �ѳɹ�ִ��Դ���ύ `30485ae`��ȫ��1,280��C TU��5��shader����ͨ����RM/modeset�����鵵��NVRM�ؽ���ѡ�����ӡ���ǰ����UNKNOWN��������nm�й۲쵽���壻�����ĸ���֪NVLink���ڲ����룬����471��Ŀ�굼��/ABIδ���ա�������profileѡ������һ�²����Ǳ���������TU������**��ʼ����GPU��Ⱦ�����ض��ؾ�δִ�У������в��ɽ������豸NO-GO��** ��һ�����ĸ���ʵDarwin���ӿڡ���������ABI��Ŀ�굼�����顣[�����֤��](../research/gpu-safety-r5/FULL-SOURCE-BUILD-20261018.md)��[��ҳ��ֻ������prompt](../research/gpu-safety-r5/FULL-SOURCE-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R80 ������������Դ��** ���� Mach-O ת C ����ʱɾ���»��ߵ����⣻���� UNKNOWN �����λΪ�������ݡ�һ�����һ������ݼ�һ�������䷽��ѡ���ѽ��뱾����ʽ�����ϣ/��ȷ����ȡ֤��47��߲��Լ�������ʷ�ع�ͨ������ Darwin/�����ṩ��/����/ABI ��δ���У������հ����豸�� NO-GO��[����](../research/gpu-safety-r5/R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md)��[��ҳ�˸��� prompt](../research/gpu-safety-r5/R80-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R79 ��ƾ�����** �ѳ��ء�45�����ű�Դ���롰351��667֤�������հ�����������������ͬ������ʽ�����嵥���ޡ��̶�346������ɨ��Ϊ337���ʷ���ѡ��9��UNKNOWN���зǶ���հ���27��߲��Ժ�������ʷ�ع�ͨ����������TUѡ��ABI����������ϸ��ı���������Darwin/����/ABI��δִ�С��� [���ֱ���](../research/gpu-safety-r5/R79-AUDIT-CLOSURE-GATE-20261018.md)�������հ���ʵ������NO-GO��

> **R28 ���ֲ��䣺** [��ʵ������󴫲�](../research/gpu-safety-r5/R28-OWNER-COPY-ERRORS-20261018.md) �����Դ��/CPU ��ͬ��ѡ������ head �� Darwin �Ž������� `gpu-safety-r5-native.yml` / `Xcode_16.4` ��ͬʱ��ȡ `r28-host/report.json`��`r28-series/report.json` �� `g1-probe-inventory.json`�������þɳɹ� run ���ա������հ��� ABI ���ȼ����䡣

> **2026-10-18 ������ڣ�** ��ȡ [G1 �����հ��� ABI ���](../research/gpu-safety-r5/G1-CLOSURE-ABI-AUDIT-20261018.md)���������µ� `g1-probe-inventory.json`���嵥Ԫ���/���� include/��ʵ�����壬����չ RM/modeset ���ıհ����˶� Darwin ABI����Ҫ�ظ����Ҳ��� 35 �����塱����ͨ�����嵥Ԫ�״α��롣�û�����Ȩ��������� main ��������� compile-only Actions��ʵ���� NO-GO������ .agent��

## 2026-10-18 ��β���ӣ��� 24 �֣�

### һ�������ȫ������֤��

```bash
python tools/verify-all.py --workspace <������>
```

11 ������ȫ�̣�bundle 30/30��structure-nvidia 60/60��structure-intel 30/30������Ӧ����������ԭ
������ϣ `ea9467f4cca9c823`����publish 7/7��ASan �������ԡ�����ĩβ�̶���ӡ
**"not covered: KEXT-LOAD and above (needs the machine)"**����ֹ������ȫ�̶����������á�

### �Ѿ�֤���ģ����ߣ�

| �� | ���� |
|---|---|
| PRE-LOAD | 6 �� bundle �� plist �����Ӳ���һ�£���ʶ��Ψһ��**����˳�� NVRM �� NVRMFB/NVAccel** |
| PATCH-APPLIED | 20 ���������������� 611 �ļ�����ԭ |
| HOST-TEST | 38/38��ASan����"��ǰ�� UAF"�Ķ��գ� |
| SOURCE-STRUCTURE | NVIDIA 60/60��Intel 30/30 |
| DARWIN-COMPILE | 16/16 ��Ԫ���澯����������ʵ Xcode 16.4�� |
| KEXT-LINK | NVAccel 248584 B��NVRMFB 315848 B��NMIntelFB 44824 B��Intel ���� 58752 B |

### û��֤���ģ���Ҫ������

`KEXT-LOAD`��`GPU-RUNTIME`��`DISPLAY-RUNTIME`��`ACCELERATED-DESKTOP` ȫ��δ����
**�κμ�����Դ��Ķ��������ڲ�**����Ϊ��һ�ι۲��������ʵ����

### ���������㣨ֻ�����û�ѡ��

1. **��Ȩһ�θ���� NVRM ����**���ű���Ĭ�Ͻ��ã�`exit 90` ���������ָ�������ȷͬ�⣻
   ����֤����**����Ԥ���������������ܷ�����**���������ǵĴ��롣
2. **��һ��ֻ���ɼ�**��`tools/gpu-forensics/collect.sh`����װ�κζ������ش�"������ǰ��˭����"��
3. **��������Ԥ�����**����ʽ�ر� 2050 ���Խ�·�ߣ�REA ��֤�����а溬 7.93 MB ��͸���غɣ��޷���Դ���ؽ�����

### ��֪�ġ��޷��ڱ���Ŀ�رյ�����

- `nvKmsClose`/`FreeDevice` �� `void`���ܾ��ر�**�޷����ϴ���**��R21 �������ɼ������ɷ��ࡢ���º��ж�����
- NVRM.kext ���ɴӹ���Դ���ؽ������Ÿ��� 3.7%����� 2.15%���Һ���͸���غɣ���
- i915/eDP ������ͣ�� `BLOCKED_FREEBSD_BASE_SELECTION`��R16�CR20 δ�ı���ǰ�ᡣ

## 2026-10-18 ���ӣ������վ����ƽ�����Ҫ��д�� 20 ������

[���վ���](../research/gpu-safety-r5/ACCEPTANCE-MATRIX-20261018.md) �ǵ�ǰΨһ��ڡ������춼����
"Դ�������֪ȱ�ݡ�ֻʣ����֤��"��λ�ã�

- NVIDIA������ʵ��ű�Ĭ�Ͻ��ã�P0-3�����ָ���Ҫ�û�������Ȩ��NVRM �����ؽ����� REA ����֤����
- Intel����Ҫһ��ֻ���ɼ���`tools/gpu-forensics/collect.sh` �� 50�C54 �ȷ��������˭������

ֻ����ʵ��֤�ݻ��µ����β��ϳ��ֺ�ſ�������Դ��Ķ���

**2026-10-18 ���ӵ���** [research/gpu-safety-r5/HANDOFF-20261018.md](../research/gpu-safety-r5/HANDOFF-20261018.md) ���� ��״����������Ž����з�ʽ������ʵ������Լ���Ҫ�û������������£�A ȡ֤ʵ�� / B �Ƿ�������� NVRM / C �Ƿ�ֹ�𣩡�

## 2026-10-18 GPU R8�CR13 ���ӣ����߹����ѵ��߽磬��һ����Ҫ�û�����

R7�CR12 �� NVIDIA ���豸���������޵�"ʧ�ܼ����������ʹ�����ͷš�PM �����ò��𡢹¶��´λ��ա�״̬ת�����л�"��
ȫ��������������ṹ��ͬ������ Xcode 16.4 �ϱ��루16/16 ���󣩡�R10 ������"�Ĵ��ļ�"������ NVRMFB ��
`kexts/NVRMFB/fb/`����R13 �Ǹ������`NVRM.kext` �޷��ù���Դ���ؽ���

**��һ��ֻ�����֣�**
1. �û���Ȩһ�θ���� `KEXT-LOAD` ȡ֤ʵ�飨���� NVAccel/NVRMFB + ���� NVRM������־���������ˣ��� �ſ��ܽ���
   `GPU-RUNTIME`��
2. �û����������޹���֤�ݵ� NVRM �� ��Ϊ"������֤"��ֹͣ NVIDIA ����
3. ʵ����ʾ RM/GSP �޷���ʼ�� �� ������ֹ����ۡ�

�ж������������� [FEASIBILITY-STOPLOSS-20261018.md](../research/gpu-safety-r5/FEASIBILITY-STOPLOSS-20261018.md)��
�����������߲�����������ֱ�ӷ�������������֮һ��

## 2026-10-18 �Ž���ͨ����DARWIN-COMPILE + KEXT-LINK������һ���Ǽ���ǰ�ĶԳ��������ڴ� owner

[Run 39048772269](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39048772269) �״�ͨ����12/12 ���󡢸澯��������NVAccel kext ���ӳɹ���244400 B��
`sha256 89f9839e��`����**��֤������"�ܱ��롢������"������"�ܼ��ء����� GPU"��**

��˳�����һ����
1. **R8��Դ�룩**���� F5b����`super::start()` �� `kapiInit` �ɹ���ʧ��ʱ��ͬһ RAII �ع������Խ� Device��
   ���һ�� framebuffer ֹͣ / kext ж��ȱ�Գ����٣������ȶ���"���� Device �����ʹ����"�ж������ü�����
   owner �ƽ����������ڵ��� framebuffer �� `stop()` ��ֱ�� `freeDevice()`��
2. **�Ž�����**�������в� `-mmacosx-version-min=15.5`��������������Ŀ�겻һ�µ� ld ���档
3. R8 ����������Ž���ͨ��������� KEXT-LOAD����Ҫ�û���ʵ��������Ȩ���� GPU ���С�
4. ��һ�ڴ� owner��`NVRM.cpp` + `nvrm_gpuva.cpp`�������� F5b ֮��

## 2026-10-18 GPU R5�CR7 ���ӣ���һ���������ֶ�����ԭ���Ž������Ǽ���д����

��Ч���� R1��R2��R3ע�͡�R4��R5��R6��R7������Դ�� 7 ������������֤ͨ����R5 �޹ر�·�� UAF��R6 �����ɹ۲�
�����ߣ�R7 �޳�ʼ��ʧ�����µİ��ʼ������ Device�����߾����������Ի�ṹ��ͬ����**û���κ�һ������
Darwin ����**��

1. �� [HONOR GPU safety R5 native object and kext link gate](../.github/workflows/gpu-safety-r5-native.yml)
   �ֶ�ѡ�� `main`��`xcode=Xcode_16.4` ���У��˶���ʵ `head_sha`��`native-report.json` ���������־��
   **���Ž��Ѹ�Ϊ���� `build/accel_build.sh` �ھ�**��ȥ���Լӵ� `-Wextra -Werror`����������"��ѡ���ñ�ԭ��
   ��澯"�Ĳ�ּ���� NVAccel kext ���Ӳ��衣
2. ��ʧ�ܣ��ȱ� original/candidate ͬһ TU�����д�������������/����/ͷ�ļ����⣬����ѡʧ�ܲ�׷ R1��R7 diff��
3. �õ�ԭ�������F5b��`super::start` ʧ�������һ�� framebuffer/kext ж�صĶԳ����٣��� ��һ�ڴ� owner
   ��`NVRM.cpp` + `nvm_gpuva.cpp` �е� GPUVA ·������ modeset ownership �� Device �������ڽ��� �� ��̸
   GSP/DMA/Metal/�Žӡ�

## ��ǰִ�жϵ��R4 ԭ�������Ž��� KAPI owner���������ľ� H2/H4 ��������

1. �û���һ���ֶ��� [HONOR GPU safety R4 native object gate](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/workflows/gpu-safety-r4-native.yml) ѡ�� `main`������ `xcode=Xcode_16.4` ���У��˶�ʵ�� `head_sha`��`native_compile.py` �� Git blob��`native-report.json` �����ж��������־��**���ɴ�����������**
2. �������µ�ԭ����������ȱȽ� original/candidate ͬһ TU��˫�����еĴ����ǹ�������/�������/ͷ�ļ���ѡ���⣻����ѡʧ�ܲ�׷ R1��R4 diff������ obj �����Է� Kext ���ӡ�
3. ���� SOURCE-REVIEW P0��`gpuSuspend` busy ���� STANDBY��KAPI `kms_close_common` ��ʧ���޷�ͨ�� void `nvkms_close_from_kapi` ���� OGKM `KmsFreeDevice/FreeDevice`��`nv_xnu_lookup_fd` ����ָ��������������δ֤����δȷ�� XNU PM/veto �� per-open callback/drain/owner ֮ǰ**���ύΣ������ʱ����**����� [R4 Դ�����](../research/gpu-safety-20261017/PM-R4-REVIEW-20261017.zh-CN.md)��
4. �̶� NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393` �� OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`��˳��Ӧ���ĸ� NullMoth ������һ�� OGKM �������κ��²����������š���С������ʵ����֤�ȼ�����ˡ�ϵͳʵ���� NO-GO��

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

## 2026-10-17 ���� GPU ���ֶϵ㣨�û���ȷѡ�񣬴����ģ�

�ȶ�research/gpu-safety-20261017/������ac55984����Դ���Ͻ�Ӧ��gpu-safety-r1.patch��������2.3.3����kext����B3-B10��ȱʧBRIDGE-01��06��CPU/����Ӧ��֤�����У����ظ�ˢͬ��ģ�͡���һ����Ĳ������ύmanual native�����Ž������û���ҳ���У�֮���Ƚ��os-nvkms-xnu.cpp:kms_close_common�Եȴ�/��ʧ�ܹرգ��ٰ�DeviceΨһowner����NVRM��VRAM/GPUVA������ʾ������ǰNMIntelFB��kva/stop����ʵDMA/GSP��NO-GO��������Head4��ʵ�鹦�ܡ�û������/����/�豸��Ȩ����ǰH1����������ʵ���䡣

# 10��Codex ��ʽ���ӵ������ڽ�����ʲô

## 2026-10-17 ���� Codex Ψһ���Ƚ��ӣ�H1��H2��H3��H4 ����

**�ȶ� [���߸�λ���ƫ���Ž�](12_MAINLINE_ALIGNMENT.md)**�����ļ������ NVIDIA DMA ������������ H4 ��ʷ��**���ǵ�ǰ��һ������**�����ʵ������� SSD ��װ��ɲ����� 2160��1440 ���棻���̿��á�Wi-Fi �ʹ��ذ岻���ã����� GPU Ϊ No Kext Loaded�����濨�٣���Ƶ/����/����/˯����ȱʵ�⡣H1 �����������/Windows �������֤��H2 ��������������ȣ�H3 Intel ��ʾ�ṩ�ߵ��������С�

**���ּ���һ����������С����/�ĵ�����**���������� H1 ����֤�ݡ�H2 ÿ����Χ������ѡ�����˷��ա�H3 �� IORegistry/WindowServer/Framebuffer �´�ֻ���ɼ��嵥�����������������ԡ��޸� EFI/SIP/BIOS����װ/���� kext �򴥷� Actions��ֻ����Щ��������ʵʹ��״̬���������پ����Ƿ�Ҫ�ָ� H4��**��������д�µ� NVIDIA DMA/Page-array/ABI ģ��**��

## 2026-10-17 P0-DMA ���� IOVM64��RM page-array C++ ��ͬ��δ������ CI��

Դ���ύ 410ad56���������ֵ�ַ��ת������17 �� CPU-only C++ ������ Apple IODMACommand Segment64 �� compile-only �Ž�Դ���ύ 71e6b5d ��չ macOS 15 Intel/Xcode16.4 ̽�룬ֻ���������/nm/ɢ���ı��������������Ծ�δ���У����ܳ�Ϯ 40/40 �ɲ��Ի�� native SDK �� PASS��������ͬ�� scripts/g1/IOVM_PAGE_ARRAY_CONTRACT.md����ʵ mapper ��Դ��nv_xnu_alloc::md prepare ���ݡ�RM pOsData ownership��GSP DMA/quiescence �� KDK ABI ȫ�� NO-GO��

��һ������ main �ֶ����� DMA workflow ���� 17 �� C++ host ���ԣ��Լ� Darwin SDK ��ԭ������ compile-only�������� md->prepare �Ѵ��ڵ�ǰ�ᡢIOMapper provider ��˫��Դ owner �Ĵ���ع����֤�ݺ�ͬ���������� Windows/EFI/BIOS��


## 2026-10-17 ������֤�ڵ���ת��������Ҫ�ظ� CI��

`P0-DMA Contract` [run #38939252741](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741) ��ȡ�� 40/40 PASS ������ԭʼ JSON �� SHA256���̶� DMAR ��ʾ 2 �� DRHD������ר�á��ڶ��� include-all�������� RMRR���鵵�� [ר��](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)��[Darwin SDK Probe #38931389598](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931389598) ����ԭ������ PASS�������ظ���**��һ���Դ��/���뻷��������** ���� NVIDIA `nv_dma_map_alloc` �� RM `pPriv/pOsData` ˫���������� macOS ��ʵ IODMACommand ��Դ״̬����ʧ��ʱ���������ͬ�������˲�Ŀ�� Build/KDK��IOMapper provider �� `01:00.0` ����̬ IOMMU ���á����ɽ���̬ DMAR include-all ������ӳ������̬֤�ݣ�NO-GO��


## 2026-10-17 P0-DMA ��һ��������֤����

���õ� Xcode 16.4/macOS SDK15.5 `IODMACommand` compile-only �ɹ�֤�ݣ�run 38931389598����**�������ظ����и� SDK ̽��**���ֶ����и��º�� [P0-DMA contract](../.github/workflows/g1-dma-contract.yml) �� `main`����������ύ `636ac9a`��������ԭ 10+13���޸���� RM 11��ACPI DMAR 6���� 40 ����Ԫ���ԣ������� `dma-source-contract.json`��`dma-rm-path.json`��`dmar-topology.json`��ע��ǰһ���� 38931378828 �������� fixture �� `//` �Ե���ͬ�� `}`��������Ч C ���������ύ�� block-comment �޸���δ���ͼ��Ҫ��**���� CI �������ǰ���������� PASS��** DMAR �̼���̬���˼�ʹ�ɽ�����Ҳ����֤�� OS runtime VT-d/DMA ҳ��/RTX2050 GSP �ѹ�����NO-GO��


## 2026-10-16 P0-DMA �½����ص㣺������ʵ DMAR + �޸���� RM ���������

1. �� `main` �ֶ����� [G1 P0 DMA contract](../.github/workflows/g1-dma-contract.yml)��Ӧ�ܼ��� 23 + ���� RM 11 + �� DMAR 6 ��**40 ��Ԥ�ںϳɲ���**��ȷ�������̶���Դ���ֿ�ʵ�� `fw_DMAR.bin` �� SHA256����������ӳ��Դ��ͬ JSON �������� `dmar-topology.json`���˶� DRHD �� segment/include_all���� PCI device scopes/RMRR��**Ŀǰ�� CI δ���У�������ǰ���ͨ��**��
2. �Դ����� [Darwin DMA SDK API compile-only](../.github/workflows/g1-darwin-dma-sdk.yml)����֤��ʵ Xcode16.4 `IODMACommand` API ���͡������δ������ţ�������/���� kext��
3. ֮������ʵ Windows BIOS/ACPI PCI BDF �� DMAR device scopes ����̬����Է���������� macOS IOMapper �� allocation mapping ownership��DMAR ���ڻ� DRHD include_all ��������ʱ IOMMU ֤�������޸� Windows/EFI/BIOS�������� GPU��ά���豸 **NO-GO**��


## 2026-10-16 P0-DMA �½��ӣ������֤α�Ž�

(1) �ֶ����� [DMA source contract](../.github/workflows/g1-dma-contract.yml) ���������� `test_dma_rm_path.py` �� 7 ��������������ʵ�̶�Դ�� `dma_rm_path.py` �� `dma-rm-path.json`���ص�۲�ϵͳ�ڴ� DMA ·���� `pOsData=NULL` ����Ϊ peer���Լ�ʧ��ʱ����ӳ���¼�Ŀ���������ֻ��֤��**Դ���֧�ɴ�����**��û�� GPU ִ�С�

(2) �����Ѵ��ڵĶ��� [Darwin DMA SDK compile-only](../.github/workflows/g1-darwin-dma-sdk.yml) ���� Xcode 16.4 ����ʵ API ���ͣ���������δʵ�����У����ֶ������������Ƿ����ɹ�������Ӳ�� NO-GO��

֮������� `pOsData` �� `memdescGetMemData` ���׶�����Դ�ĺϷ��ͷ�˳��`bReadOnlyDeviceMap` �Ĵ��ݣ��Լ������� IOMMU/provider ԭ���ӿڣ��ڴ�֮ǰ��ֹ�Էǿռپ����identity ��ַ��ɹ� Stub ����ʵ�����ء�


## 2026-10-16 �½��ӣ�ֻ�����ֶ���

�Ѿ��̶� P0-DMA 23/23 �ϳɲ��ԣ������ظ���[�ֶ�ִ�� G1 Darwin DMA SDK API compile-only](../.github/workflows/g1-darwin-dma-sdk.yml)������ `main`���˶� `toolchain.txt`��`compile.log`��`undefined-symbols.txt` ����ʱ x86_64 Mach-O `MH_OBJECT` ֤�ݣ���Ҫ����/�ϴ��ɼ������������޸� HONOR ������������ʧ�ܣ���λ Xcode16.4 ʵ�� Kernel.framework ͷ�ļ���̶����� XNU �������죬������С probe��**�����ƹ� SDK �����α�ƿ���**������ͨ�����RUNTIME_NO_GO�������������� macOS Build/KDK��IOMapper provider ������rm `nv_dma_map_alloc` ��Դ�� DMA ֹͣ��ͬ��


## 2026-10-15 �����������ѽ������棬�Կ�������δ��֤

�û�ͨ�� H1-COUNT Խ�� EXITBS�������� SSD ��װ��������ʽ���棻���� 2160��1440 ����ʾ������ GPU ��ϵͳ�����Ϊ No Kext Loaded�����濨�٣�����Ӳ���������ա��û��ѹػ������׶�ֻ���Կ����������Ե��У�û�а�װ��������������޸� BIOS �����򴥷� CI��

����[���й鵵](../research/gpu-feasibility-20261015/README.md)��·�߱Ƚϡ��̶�Դ��汾�����¼��RTX2050 ��Ⱦ�� Intel �����Ž��Ǵ���֤��������ǰ��¼�� 31 ��ͨ����0 ��ʧ�ܽ�ΪԴ��/�ĵ���飻û����ԭ��������Ӳ�����ԡ������ϴ��ѻ��û���ȷ��Ȩ��ԭʼ��Ƭ���豸��־��EFI �����������Ʋ��ϴ���

**���±�����ʷ��¼�����С��Կ� EXITBS������δ���� macOS���������Ѳ����������û�ʵ�⡣������������δ���ս����Գ�����.agent/ ����δǨ�ƣ�����ʱ���ȶ�����������**

---


**����ʱ�㣺2026-10-12���ֿ�����֧ main������ R1.4-B ��˺�ķ��������ĵ���ִ������˵�������ǡ�������ʵ�֡���**

**���¶ϵ㣺** R1.4-C0 ����̨�˺͸���̬����ѽ�����base ��ѡ `release/14.3.0 / 8c9ce319fef765890ce518cab85d3a470b669849` �ѹ̶������� B0/B1 �հ��� BLOCKED���·�����ԭ�����壬��ʱ��base ���顱����������δȡ�� SHA���� [���](../docs/R1.4-C0_����i915Դ����ӿ���������.md)��

**�������� R1.4-C0.1��** [��ʽ����](../docs/R1.4-C0.1_PCI���Դ���ӿں�ͬ.md)��ʵ�ʹ̶����ɹ���/���룬��ʵ�ṩ�����Դʧ�ܴ�����21ͨ��0ʧ�ܡ�û�����ʵ������չ��/Ԥ�����հ���Power Well ��ʱ���������棬XNU setPowerState ��ֵ��ȷ�ϣ������ͬδʵ�֡�

**Next Task R1.4-C0.2��** �̶� macOS15.5 IOPCIFamily ԭʼ��Դ/commit���� PCI BAR��PM��IRQ ���ͷ��������ڣ����� PCI_MMIO_OWNER/PM_ACK_SEMANTICS���� XNU ��Դ�����顣��Ҫ����ȱ֤�ݼ�ֹͣ�������� B2/B3 �� kext��

## R1.4-C0-pre����ƽ̨��������һ��

[����ACPI��̬���](../research/acpi-static-20261012/README.md)�Ѹ�_DSMλͼ��PEGP_DOD��DD�ڵ�������IGDM���֣�ͬһiasl20250404�������ͻѡ�ⲿ���������16ͨ��0ʧ�ܣ�PEG1._S0W/HS10.SADX���������Դ�ظ����о�ȷ��¼����MUX/����/OpRegion�����޹أ�DSDT�����ⲿ�������棬EDMX��UnknownObj����ð������External�հ������гɹ���OpRegion/VBT������δȡ�ã�MUX��ѡһΪ�޷��жϡ��̶�BSD��intel_acpi�����ŽӺ���Ϊ�գ����ܵ�XNU�ɹ�ʵ�֡�

**��һ����ΪR1.4-C0 T0��T4**��T0����ѡ��-e�ɹ���ԭ��ͻ���/���ظ�Ӳ���������飻T1����ԭ������������������T2��ASLB/SANV��IGDM/ASLS��_DSM/_DOD/_ADR��ASLE������������VBT/OpRegion�ڵ㣬������ʵ����/ACPI evaluator/PCIӳ��/������/ʧ������ȱ�ڣ�T3ʧ��ֹͣ��T4֤�ݽ�����IOPCIFamily��C0.1���ñհ�������ɣ������β�����native/kext��Ӳ����ȡ��

## �ȶ��������

1. ִ�� [`AGENTS.md`](../AGENTS.md)���ٶ� [��ǰ״̬](02_CURRENT_STATE.md)��[Ŀ��](00_PROJECT_CHARTER.md)��[�汾��](05_SOURCE_LOCKS.md)��[��������](06_ARCHITECTURE_AND_RISKS.md)��[����](07_DECISIONS.md)��
2. ���� Windows ��ֹ�Ķ���������/��װ kext/EFI/BIOS/SIP�����Լ�����/rerun Actions�������ظ����� Issue��
3. ��֪������ Intel `8086:46A6`��RTX Ϊ `10DE:25A9` �� **2050**������ 3050��**�Ѿ�ȷ�ϵ�Ӳ����Ҫ�����û��ظ���**��
4. `RUNTIME_NO_GO`��R1.2-C �ɺ�ѡ�� real+virtual BUILD-PASS����**���ǵ���������û���κ� native build**����Ҫ������

## �Ƽ� Codex �׸���������R1.4-C0��B0 + B1�������������ں˲���

**����Ŀ�꣺** ����FreeBSD drm-kmod 6.1-lts + Linux v6.1 ����Ϊ���� Intel 46A6 KMS �о����롱�ļ�����ʵΪ**��֤�ݵİ汾����С����/���������հ�**��**�����������Ƚ���ԭʼԴ��׷�ݡ�C ABI ��ͬ�Ϳ�֤α�������󣬲�Ӧ���Ʋ����ɼ��� AlderFB.kext��**

### �ѹ̶������ѡ�����ð�����

- Linux v6.1 commit `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`
- FreeBSD drm-kmod 6.1-lts commit `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`
- Apple XNU macOS 15.5 commit `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`
- Apple IOGraphics macOS 15.5 commit `4d3fd008c80d1414c9da8f02ea67d534b47158c2`
- **FreeBSD base LinuxKPI ��Ӧ�汾�� commit ���飬���ܱ��졣** �ȴ� FreeBSD drm-kmod 6.1-lts ��ʵ����˵����Makefiles��includes �� FreeBSD Release ��֧ѡ��һ������� SHA��

### ���� Codex ����ʵʩ�Ĳ���

**T0���ֿ⸴��/����Լ��**

- ��һ�г� [��ʷ/�����˱�](03_RESEARCH_HISTORY.md)��[֤��̨��](04_EVIDENCE_LEDGER.md) ���� B0/B1 �ظ��Ĺ�����**����������Щ������**��
- ������вֿ⻹���ⲿ�û��޸ģ��ȱ����ͻ�������ǡ�

**T1��Դ�汾/����֤�հ�**

- �� `research/independent-i915/` �����ı���ʽ `README.md`��`source-lock.json`��`license-manifest.csv` �� `compat-notes.md`��
- `source-lock.json` ÿ�����ٺ� `repo`��`commit`��`path`��`blob_sha`��`role`��`status`��ȱʧ commit ��Ϊ `BLOCKED`��**������һ������������ࡱ�Ĺ�ϣ**��
- ѡ�� FreeBSD base/LinuxKPI **����ɹ�����ʵ�İ汾**����� DRM 6.1 includes �Ƿ�ȷʵ������֮ƥ��Ľӿں� licensed symbols��չʾȱ�ڡ�
- �� GPL/dual-license/MIT/BSD �����ļ���ע SPDX/������Դ���Ƿ����������طַ���û������֤������Ĭ�Ϻϲ�Ϊ�ɷַ���Դ kext��

**T2����� 46A6 ��������С����ͼ**

- �� FreeBSD `i915_pciids.h:INTEL_ADLP_IDS`��`i915_pci.c` �� ADL-P display/eDP ��غ��ĺ��������� **`pci-probe �� VBT/OpRegion �� Power Wells/CDCLK/PLL �� eDP AUX/link training �� GEM/GGTT plane backing �� IOFramebuffer publication`** �Ĵ��汾��Դͼ��
- ��� `callgraph.md`��`symbol-inventory.csv`��`required-apis.md`��ÿ����¼д���ṩ����ľ���Դ��/�����Լ��ں��߳�/�ж������ģ�Ŀǰδʶ�����ȷ��ע `UNRESOLVED`��
- ��ֱ�Ӱ��̶��� `intel_edp.c`��`i915_gem_gtt.c` �������������ڵ� Linux v6.1 �ļ���eDP �� DP/panel��GGTT �� `gt/intel_ggtt.c`��
- `IOFramebuffer::getInformationForDisplayMode` ��ģʽ��Ϣ API���������� frame buffer ��ַӳ�� API���� `getApertureRange` �� pinned API ����Žӡ�

**T3�����������飨����ȷ����Ϣ������**

- ����д�ű���ֻ��**������/ִ�����ζ����ơ�����дӲ��**�� manifest/schema У�飺����Դ commit ���·��/blob Ψһ��source-object mapping ����©������ȱʧ fail-closed���ؼ� API ��������δʵ�ֵ����سɹ�����
- �������߲���Ӧ������ȱ�ļ�/ȱ����/�ظ�����/�汾����Ӧ��**�˳�����������������**�������ü�����֤����ʵ���αհ���
- **������������û��������֤������ GitHub Actions**����ʹ�������ֶ� workflow��ҲҪ���û�ͨ�� GitHub UI ���д�����

**T4���ύ�ͽ��ӱ���**

- ���� **��ʵ�Ķ��ļ���Git �ύ���ⲿ�̶� SHA��ʵ����ı����������������ȷ��δ���еĲ��衢δ������ź�����֤**��
- ����ʵ�ʽ������ `knowledge/02_CURRENT_STATE.md`��`knowledge/04_EVIDENCE_LEDGER.md`����ʵ����֤�Ÿģ���`knowledge/07_DECISIONS.md`������Ҫ����������ļ��� Next Task��
- ���� FreeBSD base �汾���޷�֤����Ӧ�ڸô�ͣ�±��� `BLOCKED_FREEBSD_BASE_SELECTION`��������Ϊ���ƽ�������ģȱʵ�ֵ� Stub��

### ��������**����**

- ���������� 6.1 �ں˵��ֿ⡢���������ģԴ�ļ�Ӳ���ã�������һ�ν������� `AlderFB.kext`��
- ��д�� `BDSM + 0`��`GGTT 0`��δ֪ Stolen Memory���������������� PCI config/MMIO��
- �������ÿշ��غ���������� Power Well��DMC/�̼���DMA/ҳӳ�䡢���� eDP link training��
- ���о� Metal shader/RTX ����Կ������޸� OpenCore/EFI������������ Windows��

## ��������һ��

��һ�� PR/commit Ӧ�� **T1/T2 �ı�Դ�հ�** ������ʵ��Ϣ��������ȷ���� Intel `8086:46A6` �� PCI/display/eDP ·�����ܸ���ÿ�� external commit �����ɡ�**��ҪΪ�ˡ��������������޷�֤���� kext Stub**��

ֻ�� B0/B1 ���ղ������Ҫ�Ľӿ��������������������滮 B2/B3 ������ macOS hosted native compile������̬���� B4 GGTT/scanout memory contract��

**����ʱ����һ����ʾ���� Codex ֱ��ʹ�ã�**��

> **2026-10-13 ��ע**�������û���Ȩ�� 1401 ֻ�����֧�ߣ�D-16������ϵ��������ʽ�� [`logs/RESEARCH_LOG.md`](../logs/RESEARCH_LOG.md) ��������Ӱ���·� R1.4-C0 �������ݡ��û�δָ��֧��ʱ�����·�����Ϊ׼��

> �Ķ���Ŀ¼ AGENTS.md��knowledge/README.md��knowledge/02_CURRENT_STATE.md��knowledge/10_CODEX_HANDOFF.md ������ԭʼ�ĵ����� R1.4-C0 �� T0��T4 ִ�У����� GitHub �˶Լ��гɹ������ظ���׷�� FreeBSD drm-kmod 6.1-lts ��Ҫ�� FreeBSD base/LinuxKPI �̶� commit��������С Intel 8086:46A6 i915/eDP ��Դ/����/����֤/�ӿ������嵥�� FAIL-CLOSED ��顣���ü��ء���װ��ǩ���ں����������������� Windows/EFI/BIOS������������ Actions����д�ٳɹ� Stub���ύ�����뱨�棬������ʵ���Ժ�δ�ر����������� RUNTIME_NO_GO��


