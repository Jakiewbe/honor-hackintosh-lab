> **2026-10-18 NVLink ��˺�ѡ��** �Ѽ����ĸ���ʵ Darwin semaphore �ӿڼ� CPU ����/���Ϻ�ͬ��������������ͬ run ��/�޺�˵����Ӷ��ա����ȴ��ж����ԣ����� void �ӿڲ��ɻָ�����Ϊ���� panic��free ��Ҫ����÷��ſա����߼���ѹ���CPU C++ ��ͬ���� Darwin/������δִ�У�δ������ȱ���ѹرգ��豸���� NO-GO��[��������](../research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md)��

> **2026-10-18 ʵ�ʹ�����չ��** [run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) �ѳɹ�ִ��Դ���ύ `30485ae`��ȫ��1,280��C TU��5��shader����ͨ����RM/modeset�����鵵��NVRM�ؽ���ѡ�����ӡ���ǰ����UNKNOWN��������nm�й۲쵽���壻�����ĸ���֪NVLink���ڲ����룬����471��Ŀ�굼��/ABIδ���ա�������profileѡ������һ�²����Ǳ���������TU������**��ʼ����GPU��Ⱦ�����ض��ؾ�δִ�У������в��ɽ������豸NO-GO��** ��һ�����ĸ���ʵDarwin���ӿڡ���������ABI��Ŀ�굼�����顣[�����֤��](../research/gpu-safety-r5/FULL-SOURCE-BUILD-20261018.md)��[��ҳ��ֻ������prompt](../research/gpu-safety-r5/FULL-SOURCE-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R80 ������������Դ��** ���� Mach-O ת C ����ʱɾ���»��ߵ����⣻���� UNKNOWN �����λΪ�������ݡ�һ�����һ������ݼ�һ�������䷽��ѡ���ѽ��뱾����ʽ�����ϣ/��ȷ����ȡ֤��47��߲��Լ�������ʷ�ع�ͨ������ Darwin/�����ṩ��/����/ABI ��δ���У������հ����豸�� NO-GO��[����](../research/gpu-safety-r5/R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md)��[��ҳ�˸��� prompt](../research/gpu-safety-r5/R80-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R79 ��ƾ�����** �ѳ��ء�45�����ű�Դ���롰351��667֤�������հ�����������������ͬ������ʽ�����嵥���ޡ��̶�346������ɨ��Ϊ337���ʷ���ѡ��9��UNKNOWN���зǶ���հ���27��߲��Ժ�������ʷ�ع�ͨ����������TUѡ��ABI����������ϸ��ı���������Darwin/����/ABI��δִ�С��� [���ֱ���](../research/gpu-safety-r5/R79-AUDIT-CLOSURE-GATE-20261018.md)�������հ���ʵ������NO-GO��

> **R28 SOURCE / CPU-CONTRACT / PATCH-APPLIED��** [�����������ı�֤��](../research/gpu-safety-r5/R28-OWNER-COPY-ERRORS-20261018.md)��g++ 13.3 / ASan+UBSan��������ʵ�����ѡ 15/15��R27 ����Ԥ��ʧ�� 6 �����ʧ�ܸ����޲���/δִ�У�27 �� NullMoth ��������������ָ������м��� OGKM ������Darwin/����δִ�У��� GPU ���豸֤�ݡ�

> **2026-10-18 ���� SOURCE-LEXICAL ֤�ݣ�** [35 ���������� RM ջ ABI ���](../research/gpu-safety-r5/G1-CLOSURE-ABI-AUDIT-20261018.md)����ȫ���ʷ����С��̶������ϣ��71 �� Darwin Դ blob ����;���߻ع顣�� run [39090712869](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39090712869) ���嵥Ԫ����/����������� artifact `12123001015` �� SHA256 �󶨸��ˣ������µĹ���ͨ����������ȷԤ����/�����ṩ��ȡ֤��δ���С���ʵ��֤�ݡ�

| R8�CR12 �豸�������� | HOST-TEST / SOURCE-STRUCTURE | 22/22��36/36����Դ�ļ���������ֵ�� | `research/gpu-safety-r5/README.md` |
| R10 �����ļ����� | DARWIN-COMPILE | 16/16 ���󣨺����� NVRMFB ���������������澯������ | run 39050580870 |
| R11 �¶����� | DARWIN-COMPILE | NVRMFB kext 311376 B / 174 ���� | run 39051079369 |
| R12 ���л� | DARWIN-COMPILE | NVRMFB kext 311488 B / 174 ���� | run 39051324224 |
| R13 NVRM ���� | ����� | 361768 B / 649 ���� vs ���а� 16787920 B / 34302��Լ 2%�� | run 39051715396 |
| Ŀ�� GPU �� OGKM ֧�ֱ� | SOURCE-REVIEW | 610.57.04 `README.md` ���� `RTX 2050 / 25A9` | `reference/OGKM-README.md` |

| R5�CR7 ԭ�������Ž� | DARWIN-COMPILE | 12/12 ���� exit 0��original+candidate �� 6 TU�����澯������ | run 39048772269 |
| R5�CR7 NVAccel kext ���� | KEXT-LINK | exit 0��244400 B��`sha256 89f9839e��5e6cf1` | run 39048772269 |
| ǩ�� / ���� / GPU ִ�� | �� | **δ���У�NO-GO** | �� |

| R5�CR7 ȫ�������� | PATCH-APPLIED | 7 ��������/���� exit 0������ϣ `ea9467f4��` �� `adbad235��` �� `ea9467f4��`��611 �ļ��� | `research/gpu-safety-r5/README.md` |
| R5 �رպ�ͬ | HOST-TEST | ��ѡ 40/40����ǰ���� heap-use-after-free���ͷ�ջ�� `kms_close_common`�� | ͬ�� |
| R6 bridge-owner + ������� | HOST-TEST | 9/9 | ͬ�� |
| R7 �ع������� | HOST-TEST | 15/15 | ͬ�� |
| R6/R7 �ṹ��ͬ | SOURCE-STRUCTURE | 12/12��14/14 | ͬ�� |
| R5�CR7 ԭ������/���� | �� | **δ����** | `.github/workflows/gpu-safety-r5-native.yml`�����ֶ��� |

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

## 2026-10-17 GPU ���� R1 ����֤�ݣ������ģ�δ���ͣ�

����v2.3.3Դ��611�ļ��� git apply --check=0��ʵ��Ӧ�ú�612�ļ����ѡȫ����ϣһ�£�����Ӧ�ûָ�ȫ��ԭʼ�ļ���v2.3.1/2.3.2�����ȷʧ�ܣ����ܿ�汾ä�á�ʵ��C++ CPU����������GCC�ϸ񾯸桢ASan/UBSan���У�2160��1440��257��131���ء�padding���߽���ܾ���֧ͨ������Darwin������ֻ��ԭ��/��ѡ��ʵ���뵥Ԫ���������ƣ���δ���У����ܼ̳о�NMIntelFB��B10�ĳɹ������а���̬��Ա��ϣ��汾�ֶκ˶�����SOURCE-REVIEW�����������С�ϸ��/ԭʼ��־��research/gpu-safety-20261017/��

# 04���ɺ�ʵ֤���˱�����ʽ CI���ű�������

## 2026-10-17 ֤�ݷ�Χ�������޶�

�������� 2026-10-15 [ʵ���׶α���](../research/gpu-feasibility-20261015/README.md)��H1 �ѽ������ SSD macOS ���棬Wi-Fi/���ذ�δ�������Կ�����/����δ��֤��H4 �� [P0 DMA 40/40 CI](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)��ԭ�� B10 ���Ӻ;� SDK ԭ�� API �����Ϊ��ͬ����ļ���֤�ݣ�������Ϊ H2/H3 ���ա�2026-10-17 �� IOVM64 C++/SDK ��֤�����ڴ��룬**δʵ������**���������ȼ��� [12](12_MAINLINE_ALIGNMENT.md)�����ֽ�����������������֪ʶ�⣬����������Ӳ���� GPU ���ԡ�


## 2026-10-17 P0-DMA ���� IOVM64��RM page-array C++ ��ͬ��δ������ CI��

Դ���ύ 410ad56���������ֵ�ַ��ת������17 �� CPU-only C++ ������ Apple IODMACommand Segment64 �� compile-only �Ž�Դ���ύ 71e6b5d ��չ macOS 15 Intel/Xcode16.4 ̽�룬ֻ���������/nm/ɢ���ı��������������Ծ�δ���У����ܳ�Ϯ 40/40 �ɲ��Ի�� native SDK �� PASS��������ͬ�� scripts/g1/IOVM_PAGE_ARRAY_CONTRACT.md����ʵ mapper ��Դ��nv_xnu_alloc::md prepare ���ݡ�RM pOsData ownership��GSP DMA/quiescence �� KDK ABI ȫ�� NO-GO��


## 2026-10-17 ʵ�� P0-DMA ���� JSON ֤��

[Actions #38939252741](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741)��`791ba38`��������/Job SUCCESS��10/10+13/13+11/11+6/6��Artifact 12062915390 ZIP SHA256 `c9385ac96e52e24767b562cf1dd29ac8767f02388f2e14e2bca02e3affca80a1`����� [P0 DMA 2026-10-17 ר��](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)���������� JSON SHA���̶���Դ blob������ DRHD �� RMRR������ȷ�� OS runtime NO-GO����Ӳ�����ء�


## 2026-10-17 �ƶ�ԭ�� SDK �� DMA CI ����ʵ������

- Xcode 16.4 Build 16F6 / macOS SDK 15.5��[run 38931389598](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931389598) SUCCESS��`CLANG_RC=0`��`Mach-O 64-bit object x86_64`��Artifact `honor-g1-darwin-dma-sdk-evidence` ID 12059785493��ZIP SHA256 `a9552330c2b26b353617f358d843bffa0f5b47f94c31fdcd67648cf73e06d65b`��̽��Դ SHA256 `9362ff4c0cb8ccf712a9abdcaf0e383ea5e94e5fd6e96541e93365aa2c1773bb`����ʱ `.o` SHA256 `e9bc99109f81904b80137155d0872b79b236f12494334284fd2c3dd267b45018`��nm undefined ����Ϊ `IODMACommand::OutputHost64` �� `IODMACommand::withSpecification` ���� C++ ���ţ�virtual lifecycle ���ò�Ӧ�����Ϊ���������ָ�����ȫ�� ABI/����ʱ�ӿڡ�**����ͨ�����������ӻ�ɼ����ԡ�**
- [run 38931378828](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931378828) FAILED�������� 10+13 ��� PASS��`test_dma_rm_path.py` 11 ���� 2 �� FAIL����־�� `unterminated function body`�������ǲ��Թ����˷Ƿ� line-comment fixture����ʵ�ʹ̶�Դ�������� upstream �� DMAR ȡ֤δִ�У��ϴ� artifact Ϊ�ա����޸����� fixture ���ύ `636ac9a` �����͡�**��δ��������**���´�Ӧ�� 40 ����ԡ����� DMA ��ͬ JSON �� `dmar-topology.json` ȡ������֤�ݡ�


## 2026-10-16 P0-DMA ����֤�ݣ�RM ������ ACPI DMAR��

- �̶����� NullMoth/NVIDIA `osIovaMap/osIovaUnmap` Դ����������Ϊ P0��ϵͳ DMA ���� `pOsData=NULL` ���� peer ӳ���б��ͻ���Ҵ���·�����ܶ�ʧ mapping owner��������ִ��Ӳ�����ϡ�ԭ�������������ע�ͼ����ԣ��ύ `479e3459ef17e99e8f459219dd963b781ec13d5e` ��Ϊ����ע��/�ַ��������� 4 ��������Թ� 11 ����뻷����Ӧ�߼� 11/11 PASS��**��ǰ������ CI NOT RUN**��
- ��ǰ�Ѳɼ��� P40 ACPI DMAR��ʵ�� HONOR/ADL-P-M������ 136��revision 2��`checksum_ok=true`��SHA256 `e84c886dfcc89640faf9c3386d5fbb4dc77483901c816eb38fdcb22a6c298f86`���ύ `444e959421edaa61beac09ffc1dd0360cff58e67` ����ֻ�� `dmar_evidence.py` / 6 ��ϳɲ��ԣ�������һ���ֶ� [P0-DMA Contract](../.github/workflows/g1-dma-contract.yml) �Զ����� `dmar-topology.json`���˱�����δ���У���δ����ʵ 136 �ֽڱ��л�ȡ DRHD/PCI device scope ���ۡ�
- DMAR �� MMIO base��PCI scope��RMRR �ǹ̼���̬����������֤�� Intel IOMMU ��Ŀ�� macOS �п�����ʵ�ʷ�������豸ҳ���ɴ������֤�� NVIDIA 10DE:25A9 �� GSP DMA ��Ĭ�������豸������Ȼ **NO-GO**��


## 2026-10-16 P0-DMA RM ӳ������Ȩ������Ž�

- ��ʵ��ͨ����[Actions #38903242709](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38903242709)��ԭ�� 10+13 ��������ģ��/Դ���ͬ���� PASS�������Ƴ���ʵ GPU DMA��
- �µ�Դ����ʵ��NullMoth `nv_dma_map_alloc()` Ϊ `*priv=NULL; return NV_OK`���̶� NVIDIA `osIovaMap()` �� `&pPriv` ���ûص���Ȼ�� `pIovaMapping->pOsData=pPriv`��`osIovaUnmap()` �� `pOsData==NULL` ���� peer ·�����Ҵ���ʱ����ո��ֶΡ��̶� NVIDIA `os.c` Git blob `b441a66fe735e834f830bae9344333c31b16c1f2`���̶� NullMoth `os-xnu2.cpp` blob `c1fe41e9ff30649c6d02827aee5995f8eaa944b3`��
- [`dma_rm_path.py`](../scripts/g1/dma_rm_path.py) �� [`test_dma_rm_path.py`](../scripts/g1/test_dma_rm_path.py) ���ύ���˹����� [G1 P0 DMA contract](../.github/workflows/g1-dma-contract.yml) ����� `dma-rm-path.json`��**NOT RUN**�����ܽ�Դ����ͼ���������ʵ GPU �������֡�JSON verdict �̶� `BLOCKED_RM_IOVA_OWNER_AND_DMA_UNVERIFIED`��
- `osFreePagesInternal` ͨ�� `memdescGetMemData` ���յ��ǲ�ͬ�ķ���������Ӧ�������� `pOsData` DMA ӳ�������������뱣�����׶�������Ȩ����֤��ͬ���������ڡ�
- [Darwin Xcode ԭ�� SDK Probe](../.github/workflows/g1-darwin-dma-sdk.yml) �� **NOT RUN**������ Apple API Դ������ð��ԭ��������Ŀ������ݡ�


## 2026-10-16 P0-DMA �µ�ԭ���ӿ���֤�Ž�

- ʵ��Դ��ͬ / ģ�ͣ�[Actions #38903242709](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38903242709)��10+13 Python tests PASS����̬ 7 ����Դ���� PASS��ʵ���豸 DMA δ���ԡ�
- ���� `scripts/g1/dma_sdk_probe.cpp` �� [ֻ�����ֶ�������](../.github/workflows/g1-darwin-dma-sdk.yml)��**NOT RUN**���̶� Apple XNU macOS15.5 `a1e26a70f38d1d7daa7b49b258e2f8538ad81650` �� `iokit/IOKit/IODMACommand.h`��blob `c9e75dc4df8b6446788c154a893a7c670d063fd1`��Դ��������֤���Ѻ˶ԣ�`withSpecification` ���� `OSPtr<IODMACommand>`��`setMemoryDescriptor` Ĭ�� `autoPrepare=true`��`prepare` ��������`gen64IOVMSegments` �� 64 λ I/O ��ַ�νӿڡ��� CI �ṩ��ʵ SDK C++/Mach-O ����֤�ݡ�
- ������ Xcode Դ��̽�����ɹ���ͬ����ʵ DMA/GSP/�豸 IOMMU���ù��������ϴ�/���ж����ơ�


## 2026-10-15 �����������ѽ������棬�Կ�������δ��֤

�û�ͨ�� H1-COUNT Խ�� EXITBS�������� SSD ��װ��������ʽ���棻���� 2160��1440 ����ʾ������ GPU ��ϵͳ�����Ϊ No Kext Loaded�����濨�٣�����Ӳ���������ա��û��ѹػ������׶�ֻ���Կ����������Ե��У�û�а�װ��������������޸� BIOS �����򴥷� CI��

����[���й鵵](../research/gpu-feasibility-20261015/README.md)��·�߱Ƚϡ��̶�Դ��汾�����¼��RTX2050 ��Ⱦ�� Intel �����Ž��Ǵ���֤��������ǰ��¼�� 31 ��ͨ����0 ��ʧ�ܽ�ΪԴ��/�ĵ���飻û����ԭ��������Ӳ�����ԡ������ϴ��ѻ��û���ȷ��Ȩ��ԭʼ��Ƭ���豸��־��EFI �����������Ʋ��ϴ���

**���±�����ʷ��¼�����С��Կ� EXITBS������δ���� macOS���������Ѳ����������û�ʵ�⡣������������δ���ս����Գ�����.agent/ ����δǨ�ƣ�����ʱ���ȶ�����������**

---


> ��Σ�յĴ����ǰ� Actions SUCCESS д����ʵ GPU �����䡣�˱�ר�ż���**ʲôʵ�����й���ʲô��Ϊģ�͡�ʲô��û��**�����б����еĲ��֡������С�����ʷʱ�㣬���ܸ��Ǻ�����ʽ���м�¼��

## ����ʽ���е��ƶ�֤��

| ���� | ʵ�����������۲� | **�����Ƴ�** |
|---|---|---|
| [R0.8 #38197014657](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38197014657) | �� `NMIntelFB` x86_64 ��������ӳɹ����� SDK min target mismatch ���� | �����ɼ��� |
| R0.9����[����](../docs/R0.9_results_and_R1.0_gates.md)�� | ԭʼ Intel kext ��̬��ʽ��plist���豸�� `46A6`������Ŀ�� 15.5 ��� | �����Чɨ�� |
| [R1.1 #38199566264](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38199566264) | Intel �߽�/MMIO ������ѡԭ������������Լ����� | `NVAccel` ����ɹ� |
| [R1.2-C #38202526277](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38202526277) | ���� **FAILURE**��Դ/��������� 37/37 ģ��ͨ����native build ���� CI �ű�������ͻ | ���ܵ�������Դ����ʧ�ܻ� dual build-pass |
| [R1.2-C #38202869877](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38202869877) | ���� **FAILURE**��real native object+kext ���ӳɹ������ Bash 3.2 ��Сд��չ `${variant^^}` �����ݣ�virtual δ���� | ����˵ virtual ʧ�ܻ����� SUCCESS |
| **[R1.2-C #38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450)** | **SUCCESS**��`macos-15-intel` Xcode16.4/SDK15.5��real+virtual ���־� NMIntelFB native ����/���ӣ�37/37 ���߲ο����� | kext ��Ŀ����ɼ��أ���ʾ����� |
| **[R1.2-F #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259)** | **SUCCESS**��macOS 15.5 Apple Դ����ʽ������5 blob��12 �ṹ��� R1.2-D/E 24/24 �ο�ģ�ͣ�113 ״̬ | �����ں˶�������Ϊ֤�������������� |
| **[R0.7 #38210653466](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38210653466)** | **SUCCESS��ֻ�� prerequisites ģʽ��**��SDK smoke + NVIDIA r610.57.04 �����������飬���ֹ���Դ��ȱʧ `Darwin_x86_64/compile_cmds.sh` | NVAccel ������ Darwin native ���� |
| **[R1.2-G #38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141)** | **SUCCESS**��Apple `handleVBL` 10/10 Դ��ṹν�ʣ�D12/E12/G16 �� **40/40 �ο�ģ��**��E113/G363 ״̬��ֻ�����ı� | �ص��ɷ�/ֹͣ����ʵ�ں˶��󲢷���ȫ |
| **[R1.3-D #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373)** | **SUCCESS**������ `v1.14.2` `nullmoth-nvidia-1.14.2.tar.gz` SHA256 ƥ�� `7c7f7ac97dbcdd48786d4384ffcb2d19199b6d3bc0fb013c71f63b766dea6be5`��**172** ·����**1** NMXGPU binary����֪���Ƶ� `amd.flags`��`srcs-i915`���������/Դ��/manifest ƥ��� 0 | ���������ȱԴ��/��������ȫ���������Ƶ��嵥���������� |

## ����̬/���߶�����ʽ�ƶ�Ӳ������

- [R1.4-C0 ����](../docs/R1.4-C0_����i915Դ����ӿ���������.md)��Windows/Python 3.11��156 ���̶������ı�Դ��¼��92 ����/79 ��ϵ���ṹ����ͨ��������������� **25 ͨ����0 ʧ��**�������հ��Ž� **�˳� 2���ܾ�����**��ʵ�� [����/���](../research/independent-i915/verification.json)���� SOURCE-STATIC���� Actions/native/kext/hardware��

- [R1.3-A](../docs/R1.3-A_IntelXe46A6��ʾ���˫·��Դ�����.md)��ֱ�Ӻ˶� 7 �ݹ̶� NullMoth Git blob �� 18/18 Դ��ṹ������`scripts/r13a_intel_scanout_source_audit.py` ���ύ��**û�б�Ϊ CI PASS**��
- [R1.2-D/E/G](../docs/R1.2-G_VBL�������ɷ��������������.md)������/״̬���ǲο�ģ�ͣ�����ģ����ʵ�� Apple �ں��������������� GPU �жϡ�
- [R1.4-B](../docs/R1.4-B_������������������Դ���׼.md)��Linux/FreeBSD ��ѡԴ���Ѻ�ʵ�ӿ�λ�ã�**û��**�Լ��� Intel-only native object������ kext ��ʵ����ԡ�

## ���� Windows ֻ��ʵ�⣨�� CI��

| ��¼ | ʵ�����������۲� | **�����Ƴ�** |
|---|---|---|
| [2026-10-12 Ӳ������](../docs/hardware-survey-20261012/REPORT.md) | ��ͨȨ�� PowerShell 5.1 �� GLO-FX6P ��������ִ�� `collect.ps1`��26 ��ɼ����ɹ� 22 / ���ֳɹ� 1 / ʧ�� 3��Secure Boot cmdlet��manage-bde��reagentc �����Ա����`selfcheck.ps1` 41/41 ͨ����`FILES_SHA256.txt` ���� 74 ���ļ�����ǰģʽ NVIDIA ����ʾԴ/Ŀ�꣬������ Intel ɨ�������ACPI DSDT/SSDT ԭ���ѱ��� | MUX ���ޡ���ӿڹ�����VBT/eDP ������BitLocker/�ָ��������κ� macOS �㼶�������� `SOURCE-STATIC` �����κηּ��� |

## ����ʵ����յ�ּ�

`SOURCE-STATIC` �� `MODEL` �� `OBJECT-COMPILE` �� `KEXT-LINK-FORMAT` �� `KERNEL-LOAD` �� `PANEL-SCANOUT` �� `METAL-RENDER` �� `RECOVERY-VERIFIED`

�κ��±������ͬʱд����**���� commit + macOS SDK + ʵ��ִ���������ȷû��ִ�У�+ �ɹ�/ʧ����־ + ����ּ� + ��֤������Ŀ**������ CI �����ܶ����ش�ǰ P0 ����ʱ���ǣ������û��ֶ�����Ĭ���ϴ����ı���

**��ǰ��ʷ��߲㼶�����Ǿ� NMIntelFB �� KEXT-LINK-FORMAT��û�����ǵ����� kext link����û���κ�Ŀ��ʵ�����С�**

## R1.4-C0.1 ����ʵ����֤
[source/���м�¼](../research/independent-i915/c01/verification.json)��55��Դ�ֽں��飻21ͨ��0ʧ�ܣ��ṹ�˳�0���հ��˳�2����SOURCE-STATIC��XNU����̶�rawԴ��ȱ���������顣��Actions/native/Ӳ����

## R1.4-C0-pre������ԭ����̬����
�ȼ�SOURCE-STATIC��������ʱ֤�ݡ�[��¼](../research/acpi-static-20261012/README.md)��36��SHA/����/checksumһ�£�6���߲���ͨ��0ʧ�ܣ�iasl����16ͨ��0ʧ�ܣ�20200925/20250404����16�����˳�255��0ͨ��2ʧ�ܣ���2026-10-13ͬһ20250404���߸���-eȫ������15�����������0ͨ��16ʧ�ܡ���255���ظ�_S0W�����Ѷ�λ��SaSsdt/SSDT9��PEG1.PEGP����35��findings��external-review.md��ȫ�ⲿ������BLOCKED��DSDT�������ⲿ�������棻û��ִ��AML/����Actions�����Ӳ����

## 2026-10-13 C0-preѡ��-e�޶�
ͬһACPICA20250404/��20250404-1���������root������������������һѡ��2ͨ��14ʧ�ܣ���ȷ�¶���ΪDSDT/SSDT9��I2C0.TPD0._PS0/_PS3�����ı������ڴ�����16ͨ��0ʧ�ܡ�ÿĿ��13�ⲿ���������ų���selected-external-runs.json��ԭ16�ű�ȫ������Ŀ���Ҳ��ġ�38��findings��NV/Igfx������δ�䣬TCSS����PCIC(1)/PCID(4)������DSDT�ⲿ�������漰EDMX UnknownObj�����˳�0��ʧ����SOURCE-STATIC��RUNTIME_NO_GO��ԭ����Ŀ¼/workflows���䣬û��ִ��AML��Ӳ��������


