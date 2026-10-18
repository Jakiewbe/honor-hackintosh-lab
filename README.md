> **2026-10-18 NVLink ��˺�ѡ��** �Ѽ����ĸ���ʵ Darwin semaphore �ӿڼ� CPU ����/���Ϻ�ͬ��������������ͬ run ��/�޺�˵����Ӷ��ա����ȴ��ж����ԣ����� void �ӿڲ��ɻָ�����Ϊ���� panic��free ��Ҫ����÷��ſա����߼���ѹ���CPU C++ ��ͬ���� Darwin/������δִ�У�δ������ȱ���ѹرգ��豸���� NO-GO��[��������](research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md)��

> **2026-10-18 ʵ�ʹ�����չ��** [run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) �ѳɹ�ִ��Դ���ύ `30485ae`��ȫ��1,280��C TU��5��shader����ͨ����RM/modeset�����鵵��NVRM�ؽ���ѡ�����ӡ���ǰ����UNKNOWN��������nm�й۲쵽���壻�����ĸ���֪NVLink���ڲ����룬����471��Ŀ�굼��/ABIδ���ա�������profileѡ������һ�²����Ǳ���������TU������**��ʼ����GPU��Ⱦ�����ض��ؾ�δִ�У������в��ɽ������豸NO-GO��** ��һ�����ĸ���ʵDarwin���ӿڡ���������ABI��Ŀ�굼�����顣[�����֤��](research/gpu-safety-r5/FULL-SOURCE-BUILD-20261018.md)��[��ҳ��ֻ������prompt](research/gpu-safety-r5/FULL-SOURCE-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R80 ������������Դ��** ���� Mach-O ת C ����ʱɾ���»��ߵ����⣻���� UNKNOWN �����λΪ�������ݡ�һ�����һ������ݼ�һ�������䷽��ѡ���ѽ��뱾����ʽ�����ϣ/��ȷ����ȡ֤��47��߲��Լ�������ʷ�ع�ͨ������ Darwin/�����ṩ��/����/ABI ��δ���У������հ����豸�� NO-GO��[����](research/gpu-safety-r5/R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md)��[��ҳ�˸��� prompt](research/gpu-safety-r5/R80-WEB-REVIEW-PROMPT.md)��

> **2026-10-18 R79 ��ƾ�����** �ѳ��ء�45�����ű�Դ���롰351��667֤�������հ�����������������ͬ������ʽ�����嵥���ޡ��̶�346������ɨ��Ϊ337���ʷ���ѡ��9��UNKNOWN���зǶ���հ���27��߲��Ժ�������ʷ�ع�ͨ����������TUѡ��ABI����������ϸ��ı���������Darwin/����/ABI��δִ�С��� [���ֱ���](research/gpu-safety-r5/R79-AUDIT-CLOSURE-GATE-20261018.md)�������հ���ʵ������NO-GO��

> **2026-10-18 R28 ��ѡ��** ��ʵ `performTransaction()` ���� owner-copy ���� Unsupported ʱ���ˣ���������ԭ��������CPU ��ʵ������ͬ 15/15���ɻ��� 6 ��Ԥ��ʧ�ܣ�����ʧ�ܸ���ͨ���������������п�����ʱ����������ָ����ѽ���ԭ���Ž���Darwin/������δ���У�[ʵ����֤��](research/gpu-safety-r5/R28-OWNER-COPY-ERRORS-20261018.md)�����������հ�/ABI �������ߣ�ʵ�� NO-GO��

> **2026-10-18 ��ǰ G1 �ϵ㣺�����հ��� ABI��** �Ѷ�λ�Ĺ����ṩ�����贫�������벼�ֺ��飻�����Ծ� R13/R48 �ĵ��϶�Դ��ȱʧ�����תʵ������ [������������һ��](research/gpu-safety-r5/G1-CLOSURE-ABI-AUDIT-20261018.md)���������� 35 ������������������ TU �� altstack/NULL ջ��������֤�ݼ���ȷԭ��Ԥ����/�����ṩ�߲ɼ���ڣ�����ԭ��ȡ֤��δ���С�P0-1/P0-4 �Կ��ţ�KEXT-LOAD NO-GO��

> **��ǰ��Ч�������ȼ���2026-10-17����GPU P0��** �û���ȷ�ָ� RTX 2050 �� NVRM/GSP����ʵ��Ⱦ/�����밲ȫ�ر��з��������ݻ���Intel ����������״���·� H4 ����Ķ��������Ϊ��ʷ��R4 `7c9f50d` �� C++ ���þ��洦�������� macOS runner �������� [R4 PM/KAPI owner ���](research/gpu-safety-20261017/PM-R4-REVIEW-20261017.zh-CN.md)��

# ���½�����GPU Դ���ѡ R4��2026-10-17��

[��������](research/gpu-safety-20261017/DELIVERY-R4.zh-CN.md) �� [R4 ����](research/gpu-safety-20261017/nullmoth-r4-bridge-owner.patch) �� [��ҳ������� WEB005](research/gpu-safety-20261017/WEB-REVIEW-005.md)��

## R4 ����ԭ�������Ž����������ʧ�ܣ����� NO-GO��

R4 Ϊ NVRMUserClient �ⲿ�����ַ���ӳ��͹ر����Ӵ��лỰ�Ž���NVKMS bridge close ʧ��ʱ���� per-open �� owner���ṩ��ʽ���ԣ����� PM ʱԤ�ȷ��� gate��PM owner ����� gate ����ִ�С�RM users ��ʱ�Կ��ܽ��� standby��KAPI Device owner���ص��ſա����� RM/DMA quiescence ���� lookup_fd ���ú�ͬ��δ�պϡ�

�û��ֶ����� [Actions #39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733)������Ϊ `b7ac4b0aacf9951f6105c18e3bd5c7777e173d86`��Xcode 16.4 Build 16F6 / macOS SDK 15.5������ NVKAPI C �������ͨ������� C++ ���뵥Ԫ��ԭ�����ѡ�� 10 ��������� `IOPCIDevice` ������ϱ� `-Werror` ������ʧ�ܡ�NVRM ��־�ﵽ�������������ޣ����������δ����ȷ�ϡ�

��ѡ�Ž��ű������� `-Wno-error=deprecated-declarations`���������þ������������ `-Werror` ��鲻�䣻��������δ�� macOS runner ����֤�����û��ֶ����ܡ��ô�����δ���� Kext��δ����������δ�����豸��δ���� GPU���رհ�ȫ�� BLOCKED��ʵ������/���� NO-GO����� [R4 ����](research/gpu-safety-20261017/DELIVERY-R4.zh-CN.md) �� [��ϰ�](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733/artifacts/12104692976) (SHA-256 `e0042ef033b4e7e71f919ce61603bf51234d77315fe1d6d41ccc75ff602b4367`).

��һ�� R4 ԭ��������֤�Խ����û��ֶ����������ε� `H4 ����` �Ǿ� D-18 ���ȼ��������û���ǰ GPU ����ָ��ǣ����ı� H1/H2/H3 ��ʷ���ջ��豸��Windows��EFI��Actions Ȩ�ޡ�

---
# HONOR Hackintosh Lab �� Intel + NVIDIA macOS Compatibility Research

**2026-10-17 ���߸�λ���� [H1�CH4 ����״̬���ƫ���Ž�](knowledge/12_MAINLINE_ALIGNMENT.md) Ϊ��ǰΨһ�������ȼ���** 10-15 ������� SSD ���� macOS ���棻Wi-Fi/���ذ岻���ã�Intel/NVIDIA �� No Kext Loaded��ͼ�μ���δ֤����H4 NVIDIA DMA/GSP �ֽ׶ι鵵���ᣬ��һ�׶��� H1 �ع�֤�ݡ�H2 �������� H3 ��ʾ�ṩ�ߵ�ֻ�����顣���¾ɽ׶εġ����¡���ָ�䷢��ʱ�㣬���ܸǹ�����ڡ�

## 2026-10-15 �����������ѽ������棬�Կ�������δ��֤

�û�ͨ�� H1-COUNT Խ�� EXITBS�������� SSD ��װ��������ʽ���棻���� 2160��1440 ����ʾ������ GPU ��ϵͳ�����Ϊ No Kext Loaded�����濨�٣�����Ӳ���������ա��û��ѹػ������׶�ֻ���Կ����������Ե��У�û�а�װ��������������޸� BIOS �����򴥷� CI��

����[���й鵵](research/gpu-feasibility-20261015/README.md)��·�߱Ƚϡ��̶�Դ��汾�����¼��RTX2050 ��Ⱦ�� Intel �����Ž��Ǵ���֤��������ǰ��¼�� 31 ��ͨ����0 ��ʧ�ܽ�ΪԴ��/�ĵ���飻û����ԭ��������Ӳ�����ԡ������ϴ��ѻ��û���ȷ��Ȩ��ԭʼ��Ƭ���豸��־��EFI �����������Ʋ��ϴ���

**���±�����ʷ��¼�����С��Կ� EXITBS������δ���� macOS���������Ѳ����������û�ʵ�⡣������������δ���ս����Գ�����.agent/ ����δǨ�ƣ�����ʱ���ȶ�����������**

---


> **Codex handoff / ��ǰȨ����ڣ�2026-10-12��**��**�ȶ� [AGENTS.md](AGENTS.md) �� [knowledge/README.md](knowledge/README.md) �� [��ǰ״̬](knowledge/02_CURRENT_STATE.md) �� [Codex ��������](knowledge/10_CODEX_HANDOFF.md)**��ԭ README ���µ� R0.6�CR1.4-B �½���**��ʷ���̼�¼**�����ܵ���������ǰ׼��ȼ����׶�/Դ��/ʵ�顢���Ṥ����ʵ�� CI ��֪ʶ���ԭʼ����Ϊ׼��
>
> **���²��ԣ����� Intel `8086:46A6` ���� L1 �о���FreeBSD/Linux 6.1 ͬϵ��Դ���Ϊ��ѡ����������δ���� native build ��ʵ�����У�`RUNTIME_NO_GO`��** ��ȷ�������� Windows ���� Intel ���ԡ�����ʵ��Ϊ RTX 2050 `10DE:25A9`���� 3050����**���ô������� Windows��EFI��BIOS�����̡���ȫ���ã����ü���/ǩ�� kext�����ô��û����� Actions��**

> **R1.4-C0 ����������** FreeBSD 14.3.0 base ��ѡ�ѹ̶�Ϊ `8c9ce319fef765890ce518cab85d3a470b669849`��156 ���ı�Դ����92 �������塢79 ��Դ���ϵ���������߲��� **25 ͨ����0 ʧ��**��**���������հ��� BLOCKED����ֹ�������/����**���� [��ʽ����](docs/R1.4-C0_����i915Դ����ӿ���������.md) �� [�������](research/independent-i915/README.md)��

**R1.4-C0-pre��2026-10-13��**��[����ACPI��̬����](research/acpi-static-20261012/README.md)���̶�iaslѡȡ��ͻ���е��ⲿ������16��Ŀ�귴���ȫ��ͨ����ԭ��δ�ģ������ظ���Ӧ����PEG1������HS10����MUX/����/OpRegion�޹ء�DSDT�ⲿ���������EDMXδ֪�����Ա�����OpRegion/VBTʵ������δȡ�ã���SOURCE-STATIC������RUNTIME_NO_GO��

## Codex �������з�֪ʶ��

- **[��ĿĿ����Ը��](knowledge/00_PROJECT_CHARTER.md)** �� **[Ӳ������](knowledge/01_HARDWARE_BASELINE.md)** �� **[��ǰ״̬](knowledge/02_CURRENT_STATE.md)** �� **[�׸����������](knowledge/10_CODEX_HANDOFF.md)**
- **[ȫ���о���ʷ](knowledge/03_RESEARCH_HISTORY.md)** �� **[��ʵ CI/֤���˱�](knowledge/04_EVIDENCE_LEDGER.md)** �� **[�ⲿԴ��汾����](knowledge/05_SOURCE_LOCKS.md)**
- **[�ܹ������](knowledge/06_ARCHITECTURE_AND_RISKS.md)** �� **[������־](knowledge/07_DECISIONS.md)** �� **[��������·��](knowledge/08_ENGINEERING_ROADMAP.md)** �� **[ԭ���ļ���������](knowledge/09_REPOSITORY_INVENTORY.md)** �� **[1401/OpenCore ���ڵ��������](knowledge/11_EARLY_RESEARCH_AND_1401.md)**

**R1.4-C0.1 �ѽ���**��[��Դ�ӿڱ���](docs/R1.4-C0.1_PCI���Դ���ӿں�ͬ.md)��55 ��Դ����32 ���ṩ�߶��塢������������������������ͬ��21 ͨ����0 ʧ�ܡ���λ��Դ��ʱ�������ñ�־��XNU ������ֵ��ȷ����������ؼ�������졣**��һ�� R1.4-C0.2**���̶� IOPCIFamily ��Դ�� PCI/MMIO/PM �������ڣ��� XNU �����飻�����հ��� BLOCKED����ϸ�������ֹ����� [10_CODEX_HANDOFF.md](knowledge/10_CODEX_HANDOFF.md)��

---


**Research-only repository. Do not deploy drivers to the primary Windows laptop.**

Target hardware:
- HONOR GLO-FX6P / Intel Core i5-12500H
- Intel Iris Xe iGPU: `8086:46A6` (internal display connected to Intel)
- NVIDIA RTX 2050 Laptop GPU: `10DE:25A9`

**Historical original reference (R0�CR1.2):** [NullMoth NVIDIA macOS Driver](https://github.com/nullmoth/nvidia-macos-driver), pinned at `0960b2ef5dbc4a573056d4c8e042a5bd2e15d651`. Later v1.14.2 and our independent Linux/FreeBSD 6.1 source candidates use **different commits**; see [source locks](knowledge/05_SOURCE_LOCKS.md).

## R0.6: Manual macOS Intel preflight

The [Actions workflow](.github/workflows/macos-preflight.yml) runs **only on explicit manual dispatch** using `macos-15-intel`. It requests GitHub token permission `contents: read`, has a 12-minute job timeout, and does not use secrets or upload artifacts.

### Run the first check

1. Go to **Actions** �� **HONOR R0.6 macOS Intel preflight**.
2. Choose **Run workflow** on `main`.
3. Choose **mode: preflight** and click **Run workflow**.
4. Wait for the run result. Share its run URL or copied failure details for analysis.
5. **Only after preflight succeeds**, optionally choose **mode: source**. It fetches the pinned upstream Git commit, checks known source blob hashes, and compiles a standalone C++ x86_64 ABI smoke binary.

The first check uses a hosted Mac and consumes GitHub Actions capacity; review your GitHub billing settings before triggering it. Public repository standard GitHub-hosted runners are generally free under GitHub's public-repository rules. No run has been initiated by this repository setup.

### Scope and validation limits

This workflow can check Xcode 16, x86_64, Kernel.framework headers, the selected macOS SDK, pinned source integrity and a standalone ABI layout smoke test.

It **does not** compile, sign, install, load, test or distribute an NVIDIA/Intel kernel extension. It never modifies an EFI, BIOS, disk partition, or the primary HONOR Windows installation. Success does **not** prove RTX 2050 Metal support or Intel Iris Xe laptop display output.

### Files

- [`.github/workflows/macos-preflight.yml`](.github/workflows/macos-preflight.yml) �� manual-only macOS Intel Actions workflow.
- [`scripts/verify_pinned_source.py`](scripts/verify_pinned_source.py) �� read-only commit and source blob integrity checks.
- [`tests/abi_smoke.cpp`](tests/abi_smoke.cpp) �� standalone C++ x86_64 ABI check, not a kext compile.

## R0.7: Real macOS kernel compilation gate (experimental)

The [manual-only R0.7 native build gate](.github/workflows/nvaccel-build-gate.yml) adds an x86_64 kernel-header compile probe, checks fixed NullMoth and NVIDIA r610 source commits, and reports whether the NVIDIA-generated Darwin compiler metadata is available. It does **not** install or load drivers; compiler outputs are never uploaded.

Start with **Actions �� HONOR R0.7 NVAccel build gate �� Run workflow �� mode: prerequisites**. Read the [R0.7 guide](docs/R0.7_build_gate.md) before running. A successful *prerequisites* check is **not** a successful NVAccel kext build: official NVIDIA Linux source currently lacks the required Darwin-generated build metadata.

## R0.9: Static NMIntelFB kext package audit

R0.8 successfully linked the original NMIntelFB source into an x86_64 Mach-O kext bundle, but that says nothing about whether it can load or drive a screen. The [R0.9 manual-only package inspection workflow](.github/workflows/intelfb-package-audit.yml) now verifies complete temporary bundle metadata, macOS 15.5 deployment target, Mach-O type and Intel `8086:46A6` source-table coverage without ever loading or publishing a driver.

[Detailed safety and test scope](docs/R0.9_static_kext_audit.md). Run manually on GitHub Actions only after reviewing your usage/billing settings.

## R1.0: Source security audit (no new cloud build)

The [cross-driver source audit and go/no-go checklist](docs/R1.0_��������ȫ�����׼�����.md) examines Intel MMIO bounds, the `nvScanoutInfo` capacity ABI, NVIDIA-to-Intel copy bounds, VBL lifetime and asynchronous transaction completion. This follows the successful **static** R0.9 CI, and must not be mistaken for real-device graphics support.

The standalone [13-case offline safety contract model](tests/test_r10_bounds_model.py) is runnable locally with `python3 tests/test_r10_bounds_model.py`. **The model tests proposed failure predicates, not existing NullMoth driver behavior or patched source.** No new workflow is needed. No hardware or Windows settings are changed.

## R1.1: Review-only fail-closed candidate patch

[Review the R1.1 safety patch and limitations](docs/R1.1_��ѡ�޸�����֤�߽�.md). The [candidate unified diff](patches/r11_scanout_bounds_and_mmio.patch) fixes NMIntelFB's BAR0 read window guard and scanout mapping-size reporting, adds source/destination bounds checks to NVAccel's active display-pipe copy path, and disables the unreviewed async flip enqueue site. It is **not** installed or automatically applied to any machine.

The [manual-only qualification workflow](.github/workflows/r11-review-patch.yml) validates a pinned temporary upstream checkout, checks patch reversibility and offline bounds cases, then attempts to compile only the patched Intel framebuffer source on hosted macOS. NVIDIA NVAccel native compilation, driver loadability, VBL lifetime and real hardware acceleration remain unverified.

## R1.2-A: VBL lifetime design, before a kernel patch

The [R1.2-A XNU API review and state-machine analysis](docs/R1.2-A_VBL״̬����XNU�ӿ����.md) documents timer reentrancy hazards, workloop-gate semantics, interrupt unregister obligations and stop/release ordering. The [deterministic Python model](tests/test_r12_vbl_lifecycle_model.py) passed 10 tests and explored 61 unique states up to depth 9 locally. **No R1.2 kernel patch is claimed or deployed**; reentrant stop from inside a callback remains a hard blocker. Existing R1.1 source fixes are unchanged.

## R1.2-B: Review-only gated VBL patch (not runtime qualified)

The [R1.2-B technical note](docs/R1.2-B_VBL��ѡ������׼��.md) records a [stacked VBL patch](patches/r12b_vbl_workloop_gate.patch) that follows R1.1, replacing raw VBL thread calls with `IOTimerEventSource` and serializing callback registration/unregistration with `IOWorkLoop::runAction`.

[Manual-only cloud qualification](.github/workflows/r12b-vbl-review.yml) checks the pinned two-patch stack, runs offline capacity and lifecycle models, and attempts the patched Intel framebuffer native build. **No R1.2-B macOS build has run yet.** Callback-reentrant stop and runtime timer failure recovery remain unresolved; the candidate is not suitable for loading or installing.

## R1.2-C: Callback owner/sender lifetime candidate (not runtime qualified)

The [R1.2-C callback lifetime patch](patches/r12c_vbl_callback_lifetime.patch) is designed to be stacked **after** R1.1 and R1.2-B. It retains the `NMIntelFB` owner and `IOTimerEventSource` sender while an external VBL callback may synchronously unregister or stop the framebuffer, then releases both only after post-callback state checks. This addresses one potential dangling-access window; it **does not** establish safe reentrant `IOFramebuffer::stop`.

The [manual R1.2-C CI](.github/workflows/r12c-reentrant-vbl-review.yml) has now **passed in full** in [run #38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450): pinned reversible R1.1 + R1.2-B + R1.2-C patches, **37/37 abstract reference model tests**, all source-invariant gates, and native x86_64 compile+link for **both real and `NMINTELFB_VIRTUAL` builds** with Xcode 16.4 / macOS 15.5 SDK. Both are Mach-O kext bundles. [Detailed evidence and remaining blockers](docs/R1.2-C_�ص��������ñ�����������.md). This does **not** prove safe recursive `IOFramebuffer::stop`, kernel loadability, panel takeover, NVAccel, RTX 2050, or Metal. No binaries were uploaded or installed.

## R1.2-D: Two-workloop lock-order audit (runtime NO-GO)

The [R1.2-D lock-order audit](docs/R1.2-D_˫Workloop����������ֹͣ�������.md) cross-references public Apple IOGraphics `IOFramebuffer::stop` (`SYS �� FB`) with the R1.2-C VBL callback which invokes external code while holding the framebuffer controller gate (`FB`). If that callback synchronously requests stop while another thread already holds SYS and waits for FB, the two threads can form an **ABBA wait cycle**. This is a **conditional source-derived risk**, *not an observed macOS 15.5 or HONOR deadlock*.

The [12-case reference lock-order test script](tests/test_r12d_lock_order_model.py) documents the counterexample, correct gate release, deferred-stop ordering and recursion conditions. This script has **not been run in GitHub Actions**. No new kext patch or workflow was launched: R1.2-C remains both-mode native **BUILD-PASS / RUNTIME-NO-GO**. The next gate requires an independently reviewable non-reentrant quiesce/finalize design and version-matched IOGraphics evidence.

## R1.2-E: Two-stage stop model and explicit runtime no-go

The [R1.2-E design review](docs/R1.2-E_���׶�ֹͣģ�����ں�׼������.md) documents the quiesce/finalize reference protocol for callback-triggered `stop()`, `terminate()`, and target destructor reentrancy. Its [12-case deterministic model](tests/test_r12e_quiesce_finalize_model.py) passed locally and explored 113 states through depth 8; **this models a hypothetical safe external finalizer, which has not been implemented or proven in IOKit**. An additional [source risk gate](scripts/r12e_stop_source_gate.py) explicitly returns NO_GO on the existing three-patch candidate rather than inferring hardware safety from a green build.

**No R1.2-E kernel patch, new CI run, or device changes.** R1.2-C still has successful real/virtual x86_64 links, but the reverse `FB��SYS` lock acquisition and callback target final release remain unresolved, as do NVIDIA NVAccel native build and RTX 2050 Metal support.

## R1.2-F: Official macOS 15.5 release-matched SYS/FB evidence

Apple's official [`distribution-macOS/macos-155/release.json`](https://github.com/apple-oss-distributions/distribution-macOS/blob/macos-155/release.json) pins **IOGraphics-599** at `4d3fd008c80d1414c9da8f02ea67d534b47158c2` and **xnu-11417.121.6** at `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`. At those exact release source revisions, both `IOFramebuffer::stop` and `terminate` acquire **SYS before FB**, while the VBL event action invokes external callbacks under the controller FB gate. This validates the conditional lock-order inversion risk for the **official macOS 15.5 public source**; it does not demonstrate that a particular Mac or the HONOR actually deadlocks.

The [detailed R1.2-F evidence report](docs/R1.2-F_macOS15.5����Դ���������.md) records source Git blob SHAs, matched functions and unresolved callback contracts. The [read-only pinned-source checker](scripts/r12f_verify_macos155_sources.py) and [manual-only GitHub Actions audit](.github/workflows/r12f-apple-155-lock-audit.yml) have now been verified by [successful run #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259): **5/5 Apple Git blobs**, **12/12 source contracts**, and **24/24 abstract lock-order/stop model tests** (113 enumerated stop states). No kernel patch, kext loading, deployment, or local machine action has occurred. Current state: **R1.2-C dual native BUILD-PASS / R1.2-F RELEASE-SOURCE-MATCHED / RUNTIME-NO-GO**.

## R1.2-G: VBL dispatch outside FB gate �� reference model, NOT a driver patch

The [R1.2-G architecture review](docs/R1.2-G_VBL�������ɷ��������������.md) cross-checks macOS 15.5's IOGraphics `handleVBL` consumer against the published `IOFramebuffer::stop` resource-release path. **Moving the external VBL callback outside the FB workloop gate may avoid one ABBA path, but it introduces unresolved callback self-join and concurrent framebuffer shared-state teardown hazards.** `handleVBL` updates VBL timing/counters, signals semaphores and schedules timer events; retaining the target alone does not protect all associated resources.

The [out-of-gate callback ticket/epoch reference model](tests/test_r12g_vbl_ticket_model.py) passed **16/16 local tests**, enumerating **363 states at depth 8**. The [IOGraphics-599 pinned VBL contract checker](scripts/r12g_verify_iofb_vbl_consumer.py) confirms 10 source facts (checked against pinned Apple source through the GitHub connector). The [manual-only R1.2-G workflow](.github/workflows/r12g-vbl-dispatch-review.yml) **passed in [Actions #38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141)**: 10/10 pinned IOGraphics VBL source contracts, 40/40 D/E/G reference tests, R1.2-E 113 states and R1.2-G 363 states. Passing these offline models does not establish that an out-of-gate callback worker or synchronous `IOService::stop` can be implemented safely. No kernel patch, kext load or primary-Windows change. **R1.2-G remains RUNTIME_NO_GO.**

## R1.2-H: Re-focus on actual HONOR graphics feasibility �� freeze VBL patches

**Project goal:** determine whether the HONOR GLO-FX6P / i5-12500H / Intel Iris Xe `8086:46A6` / NVIDIA RTX 2050 Laptop `10DE:25A9` can obtain **usable macOS graphics**, not just compile an isolated Intel framebuffer object. [R1.2-H route evaluation and strict no-go gates](docs/R1.2-H_HONOR����·��������׼���Ž�.md).

**Decision: VBL PATCHES FROZEN / RUNTIME-NO-GO.** R1.2-C real and virtual modules compile; R1.2-F/G confirm version-matched Apple source contracts and reference models, but no runtime or hardware proof follows. Further VBL micro-patches should wait until real graphics routing and accelerator viability are established.

The currently published [NullMoth v1.14.2 release](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v1.14.2) is a relevant **unverified vendor-supplied** build lead, not approval for installation. [CARD-SUPPORT.md](https://github.com/nullmoth/nvidia-macos-driver/blob/main/docs/CARD-SUPPORT.md) still lists Ampere physical validation as pending; the `25A9` RTX 2050 device ID is in the table but has no qualifying test. The new **NMXGPU** path for Intel Iris Xe is explicitly a test driver with **no verified Intel GPU run** as of its release notes. [An issue on a muxless MSI laptop (#135)](https://github.com/nullmoth/nvidia-macos-driver/issues/135) reports an NVIDIA device showing Metal 3 while the internal panel remains frozen �� independent self-report, not evidence about this HONOR.

**The HONOR internal panel is already confirmed connected to Intel Iris Xe in Windows** (previous user test, re-affirmed on 2026-10-12): do **not** request the same ��Advanced display �� Connected to�� internal-screen screenshot again. The user also reported a working USB-C��DP 1080p/200 Hz external screen, which establishes display capability, **not** which GPU owns that port. HDMI/USB-C GPU ownership and MUX switching are still unverified. The [canonical hardware evidence ledger](docs/HONOR_GLO-FX6P_Ӳ��ʵ����֤�ݵȼ�.md) differentiates these facts. Focus next on Intel `8086:46A6` macOS scanout (or a proven NVIDIA��Intel scanout bridge), independent RTX 2050 Metal evidence, and only optionally external-port routing. The [Windows read-only probe](scripts/r12h_windows_readonly_display_probe.ps1) is available for non-duplicative follow-up, but is **not required to re-prove panel ownership**. No Windows, EFI, BIOS, partition, SIP or macOS security changes; do not run third-party installers.

## R1.3-A: Intel Iris Xe 8086:46A6 scanout is now the primary feasibility gate

The HONOR internal panel is **already confirmed to scan out through Intel Iris Xe in Windows**. [R1.3-A source-anchored route review](docs/R1.3-A_IntelXe46A6��ʾ���˫·��Դ�����.md) compares two **unverified macOS** approaches against NullMoth [v1.14.2 commit `1083a98db33a0bb824290556de255f9a95ca5403`](https://github.com/nullmoth/nvidia-macos-driver/tree/1083a98db33a0bb824290556de255f9a95ca5403):

- **Old `NMIntelFB` + NVIDIA NVAccel** only adopts a **still-active firmware Intel pipe** with a **linear XRGB8888 plane**, then exposes an Intel scanout CPU mapping for NVIDIA's head-4 copy path. Its successful R1.2-C native build does **not** show this firmware state survives actual macOS takeover or that RTX 2050 accelerates.
- **New `NMXGPU` Intel `i915` + DRM client modeset + `NMXGPUFB`** has a real source path for setting display modes and publishing a scanout buffer, more directly aligned with the HONOR panel. However upstream explicitly states its GPU port **has not been loaded on hardware**. `NMXGPUFB::unregisterInterrupt()` and `setInterruptState()` are currently no-ops, and its raw VBL timer and synchronous `stop()` still lack proven lifetime synchronization. No Intel 46A6 macOS scanout or Metal runtime evidence.
- The [source-only R1.3-A gate](scripts/r13a_intel_scanout_source_audit.py) pins seven upstream Git blob SHAs and 18 observed structures; **18/18 were inspected directly from GitHub, not run as CI**. It always retains **RUNTIME_NO_GO**.

**Decision: VBL PATCHES FROZEN; prioritize independent physical evidence for the Intel `8086:46A6` i915 bridge, then consider the NVIDIA��Intel display-copy route only if hardware evidence justifies it.** The AMD/Intel `vk_chip_matrix` 41/41 results use a mock/noop DRM shim, not real GPU execution. No GitHub workflow launched, kernel patch installed, or HONOR Windows/EFI/BIOS/disk change.

## R1.3-B: Alder Lake-P 46A6 i915 build-input and GGTT scanout preconditions

[**R1.3-B report**](docs/R1.3-B_46A6_i915����������GGTT_eDP׼��˲�.md) first cross-checked **all existing repository reports, scripts, tests and workflows**, then pursued the unresolved upstream i915 provenance and actual framebuffer mapping.

- NullMoth [v1.14.2 `1083a98...`](https://github.com/nullmoth/nvidia-macos-driver/tree/1083a98db33a0bb824290556de255f9a95ca5403) builds i915 from **external** `drm-kmod` and FreeBSD LinuxKPI trees, and Linux 6.14, through local `/Volumes/MiniData/build/gpu-src/` paths and generated flags/object lists. The exact external dependencies and actual linked `46A6` path are **not established** by this release repository.
- An **independent, candidate-only** [FreeBSD drm-kmod snapshot `c16de0f...`](https://github.com/freebsd/drm-kmod/tree/c16de0f9fa84f70b9551f69fde837a7f3a73c0e9) confirms `0x46A6` under `INTEL_ADLP_IDS` and the corresponding i915 PCI/display device tables, along with eDP and GGTT source code. **Its identity with NullMoth's build inputs is unverified.**
- `nmx_fb_bridge.c` requires the scanout CPU mapping's page translations to present one **physically consecutive address range**, using `pmap_find_phys`; i915's GGTT address continuity alone does not prove that contract. The actual mapping may be RAM or BAR-backed, so this is a **conditional compatibility gate**, not a demonstrated failure on the HONOR.
- **No further VBL patch or repeated CI** until the build provenance, buffer backing and i915 eDP scanout path are auditable. Intel internal-panel ownership is already confirmed; no screenshot repeat or host changes.

To prevent repetitive work, **read the [persistent research gate ledger](docs/�о�״̬�˱�_���ظ���������.md) before every future phase**: it lists verified CI outcomes, unresolved P0 gates, and explicit stop/duplication rules. **R1.3-B SOURCE-REVIEW COMPLETE / BUILD-PROVENANCE-BLOCKED / SCANOUT-UNPROVEN / RUNTIME-NO-GO.**

## R1.3-C: upstream NMXGPU/i915 build provenance remains unverified

Before proceeding, the [project evidence ledger](docs/�о�״̬�˱�_���ظ���������.md) and [R1.3-B report](docs/R1.3-B_46A6_i915����������GGTT_eDP׼��˲�.md) were checked; no previous CI or VBL reference tests were rerun.

The [R1.3-C release-pinned audit](docs/R1.3-C_NMXGPU������Դ������������Ž�.md) identifies **three distinct missing completeness checks in NullMoth v1.14.2**: `srclist.py` emits missing-source messages to stderr but `all-i915.sh` suppresses them; `all-i915.sh` counts compiler failures without a mandatory nonzero exit; and `obj-i915/*.o` can be linked by `kext/build.sh` without a clean-object manifest or strict source/object set comparison. These are **conditional build-integrity weaknesses**, not proof the distributed binary is incomplete.

The v1.14.2 GitHub Release has a compiler-input **NMXNPU** source archive generated by `kext-npu/mksource.sh`, but no separately listed equivalent NMXGPU GPU-source archive. The contents of the 371 MB distribution tarball have **not** been audited; therefore we do not assert that no GPU-related source files exist inside it. The actual drm-kmod, FreeBSD LinuxKPI and Linux source commits, generated `amd.flags`, `srcs-i915.txt`, per-object SHA records and linker manifest **remain missing from our evidence**. The independent FreeBSD candidate commit from R1.3-B is **not** proven to be the release's build input.

**Decision:** No new kernel patch, repetitive build CI or host modification. Prioritize a **version-matched upstream build-input and object manifest** before resuming Intel GGTT/eDP scanout mapping research. **R1.3-C PROVENANCE-UNRESOLVED / RUNTIME-NO-GO**.

## R1.3-D: obtain actual upstream release evidence; new Intel framebuffer conflict

After reviewing the [research ledger](docs/�о�״̬�˱�_���ظ���������.md) and [R1.3-C](docs/R1.3-C_NMXGPU������Դ������������Ž�.md), the [R1.3-D source/evidence assessment](docs/R1.3-D_���а�֤�������Intel��Ļ��ռ����.md) found **one new release-artifact question and one new independent display-integration risk**:

- Published NullMoth [v1.14.2](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v1.14.2) offers a complete compiler-dependency source bundle for **NMXNPU**, but no separately named NMXGPU/i915 source bundle. The **371,689,122-byte** distribution tar has now been SHA256-verified and **inventoried in [manual Actions #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373)**: 172 archive paths, one published `NMXGPU.kext/Contents/MacOS/NMXGPU` binary, and **zero path matches for known `amd.flags`, `srcs-i915.txt`, i915 objects, drm-kmod/FreeBSD/Linux input trees or compiler/link manifests**. The [manual-only workflow](.github/workflows/r13d-release-provenance-index.yml) listed filenames without extraction/execution and uploaded **text only**. This does not rule out differently named or externally published source records. **Do not rerun; this release archive index is complete.**
- [Upstream Issue #119](https://github.com/nullmoth/nvidia-macos-driver/issues/119) records a **different** muxless Intel-panel laptop without a working GUI because NVIDIA's `NVRMFBClaim` took Intel's `IOFramebuffer` matching category. The **exact v1.14.2** [`NVRMFB/fb/Info.plist`](https://github.com/nullmoth/nvidia-macos-driver/blob/1083a98db33a0bb824290556de255f9a95ca5403/kexts/NVRMFB/fb/Info.plist) still includes an unrestricted `IONameMatch=display` `NVRMFBClaim` with probe score 30000. [Upstream PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131) proposing NVIDIA vendor/class matching is **open/unmerged as reviewed**. This is **conditional risk**, not proof the HONOR itself black-screens.
- The scoped [English upstream build-manifest request](docs/R1.3-D_NullMoth_NMXGPU_����֤������_EN.md) was **publicly submitted as [NullMoth issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146)** on 2026-10-12 after confirming no matching answered issue. It requests the real v1.14.2 drm-kmod/FreeBSD/Linux source commits, `amd.flags`, i915 source/object inventory and link evidence. The issue is **open; no build provenance has been provided or verified yet**.

**No repeat CI, new VBL patch, NMXGPU build, actual driver execution, or host change.** The v1.14.2 archive has now been inventoried with a verifiable hash and the **upstream source-provenance request was submitted as issue #146**. Next action: review substantive maintainer replies or a new version-matched source/manifest, **not** repeat CI or open duplicate issues. **R1.3-D RELEASE-INDEX-PASS / I915-PROVENANCE-BLOCKED / IGPU-FBCLAIM-RISK / RUNTIME-NO-GO.**

## R1.4-A: independent Intel 46A6 macOS display-driver research

**We are no longer blocked on NullMoth's own unreleased compiler manifests to begin original development.** They remain necessary only to reproduce **its particular published NMXGPU binary**. [R1.4-A engineering architecture and hardware gates](docs/R1.4-A_��������Intel46A6_�����ܹ�����С����·��.md) defines a **new, independently version-pinned source and object chain** built from verifiable FreeBSD DRM/i915 + LinuxKPI + XNU/IOGraphics macOS 15.5 APIs. The target is the HONOR GLO-FX6P's **already verified Intel-connected internal panel**.

**The development order is strict:**
1. **L1 basic panel image:** firmware scanout handoff if its premises can be proven, otherwise independent Intel i915/DRM KMS��IOFramebuffer path; single internal panel, fixed mode, XRGB8888, no acceleration claim.
2. **L2 Intel acceleration:** only after scanout/display/stop lifecycle is genuinely observed on isolated non-primary Intel Xe hardware; Linux i915 code alone does not provide macOS Metal/IOAccelerator.
3. **L3 RTX 2050 Metal + NVIDIA��Intel composition:** independent future project after L1/L2 hardware evidence.

**First engineering gate R1.4-B:** pin our own FreeBSD source SHA (the previous [drm-kmod `c16de0f...`](https://github.com/freebsd/drm-kmod/tree/c16de0f9fa84f70b9551f69fde837a7f3a73c0e9) is a **candidate**), FreeBSD LinuxKPI, XNU/IOGraphics references, compile flags, per-file licenses, source/object sets and missing symbols; fail closed when missing. Design an **Intel-only** object subset, not the entire AMD/xe/NVIDIA port. Existing R1.2 CI and R1.3-D release archive inventory stay frozen; NVRMFBClaim's Intel slot conflict and CPU P/E-core platform boot requirements remain unresolved.

**Status: INDEPENDENT_PORT_DESIGN_ONLY / NO_NEW_DRIVER_BUILT / NO_RUNTIME_PROOF / RUNTIME_NO_GO.** No kernel extensions installed/loaded, no new Actions started, no main-Windows/BIOS/EFI/disk changes.

## R1.4-B: review of Intel 46A6 minimum-display assumptions

[First-principles technical review](docs/R1.4-B_������������������Դ���׼.md) checks the proposed BIOS framebuffer reuse, stolen memory, i915 dependency trimming, IOGraphics interface and build acceptance criteria.

**Accepted:** investigate basic Intel scanout before acceleration. **Not established:** a macOS 15 WindowServer desktop automatically appears with any IOFramebuffer; GOP output guarantees firmware scanout survives takeover; stolen DRAM begins at GGTT offset zero; source linkage implies a loadable driver.

The 12th-gen Intel **BDSM 0xB0 belongs to the host bridge 00:00.0** and yields a stolen DRAM base, not a writable display plane. Linux 6.1 skips or reserves parts of stolen memory. An essential firmware, power, memory, or synchronization operation must not be replaced by a success-returning stub.

New independently pinned **candidate version pairing**: [FreeBSD drm-kmod 6.1-lts `dba60e1...`](https://github.com/freebsd/drm-kmod/tree/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4) and [Linux v6.1 `830b3c6...`](https://github.com/torvalds/linux/tree/830b3c68c1fb1e9176028d02ef86f3cf76aa2476), plus our previously pinned Apple IOGraphics 599. The FreeBSD base/LinuxKPI commit and true ABI/object closure are **not yet established**; a matched version label alone does not imply compatibility.

**Next:** identify the actual minimal i915/KMS/DRM/LinuxKPI/XNU source/symbol/ownership/licensing dependencies and verify them against a clean, reproducible build. No new driver build or hardware run has occurred. **RUNTIME_NO_GO** remains.

## Safety and evidence

The original NullMoth source carries a PolyForm Noncommercial license. No upstream source code or vendor firmware is copied into this repository. All upstream code is fetched from its public GitHub repository into an ephemeral runner only when source mode is explicitly requested.

The NVIDIA and Intel graphics bridge remains experimental. PCI device IDs in a source table and simulated tests are not sufficient proof of hardware acceleration or a working laptop screen.

## 1401 compatibility audit (2026-10-13, read-only side track)

A source-level audit of [NullMoth 1401 v1.14.2](https://github.com/nullmoth/1401/tree/46d9fee308bbb8e373807d59773823e6a93c1f63) and [nvidia-macos-driver v1.14.2](https://github.com/nullmoth/nvidia-macos-driver/tree/1083a98db33a0bb824290556de255f9a95ca5403) against this laptop: [initial audit report](reports/INITIAL_AUDIT.md), [hardware facts](research/HARDWARE.md), [sources](research/SOURCES.md), [compatibility matrix](research/COMPATIBILITY.md), [risks](research/RISK_ASSESSMENT.md), [open questions](research/OPEN_QUESTIONS.md), [research log](logs/RESEARCH_LOG.md).

Key finding: the RTX 2050 is a PCI 3D controller (class `0x0302`) with no display sources, and the panel is on Intel 46A6, which macOS cannot accelerate. 1401 still marks `10DE:25A9` as macOS 15 capable because the ID is in NVIDIA's table (never hardware-tested), while emitting contradictory panel notes. No 1401 binary was run, no EFI was generated, nothing was written to disks or firmware.


