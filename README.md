# HONOR Hackintosh Lab — Intel + NVIDIA macOS Compatibility Research

**Research-only repository. Do not deploy drivers to the primary Windows laptop.**

Target hardware:
- HONOR GLO-FX6P / Intel Core i5-12500H
- Intel Iris Xe iGPU: `8086:46A6` (internal display connected to Intel)
- NVIDIA RTX 2050 Laptop GPU: `10DE:25A9`

Upstream source reference: [NullMoth NVIDIA macOS Driver](https://github.com/nullmoth/nvidia-macos-driver), pinned at `0960b2ef5dbc4a573056d4c8e042a5bd2e15d651`.

## R0.6: Manual macOS Intel preflight

The [Actions workflow](.github/workflows/macos-preflight.yml) runs **only on explicit manual dispatch** using `macos-15-intel`. It requests GitHub token permission `contents: read`, has a 12-minute job timeout, and does not use secrets or upload artifacts.

### Run the first check

1. Go to **Actions** → **HONOR R0.6 macOS Intel preflight**.
2. Choose **Run workflow** on `main`.
3. Choose **mode: preflight** and click **Run workflow**.
4. Wait for the run result. Share its run URL or copied failure details for analysis.
5. **Only after preflight succeeds**, optionally choose **mode: source**. It fetches the pinned upstream Git commit, checks known source blob hashes, and compiles a standalone C++ x86_64 ABI smoke binary.

The first check uses a hosted Mac and consumes GitHub Actions capacity; review your GitHub billing settings before triggering it. Public repository standard GitHub-hosted runners are generally free under GitHub's public-repository rules. No run has been initiated by this repository setup.

### Scope and validation limits

This workflow can check Xcode 16, x86_64, Kernel.framework headers, the selected macOS SDK, pinned source integrity and a standalone ABI layout smoke test.

It **does not** compile, sign, install, load, test or distribute an NVIDIA/Intel kernel extension. It never modifies an EFI, BIOS, disk partition, or the primary HONOR Windows installation. Success does **not** prove RTX 2050 Metal support or Intel Iris Xe laptop display output.

### Files

- [`.github/workflows/macos-preflight.yml`](.github/workflows/macos-preflight.yml) — manual-only macOS Intel Actions workflow.
- [`scripts/verify_pinned_source.py`](scripts/verify_pinned_source.py) — read-only commit and source blob integrity checks.
- [`tests/abi_smoke.cpp`](tests/abi_smoke.cpp) — standalone C++ x86_64 ABI check, not a kext compile.

## R0.7: Real macOS kernel compilation gate (experimental)

The [manual-only R0.7 native build gate](.github/workflows/nvaccel-build-gate.yml) adds an x86_64 kernel-header compile probe, checks fixed NullMoth and NVIDIA r610 source commits, and reports whether the NVIDIA-generated Darwin compiler metadata is available. It does **not** install or load drivers; compiler outputs are never uploaded.

Start with **Actions → HONOR R0.7 NVAccel build gate → Run workflow → mode: prerequisites**. Read the [R0.7 guide](docs/R0.7_build_gate.md) before running. A successful *prerequisites* check is **not** a successful NVAccel kext build: official NVIDIA Linux source currently lacks the required Darwin-generated build metadata.

## R0.9: Static NMIntelFB kext package audit

R0.8 successfully linked the original NMIntelFB source into an x86_64 Mach-O kext bundle, but that says nothing about whether it can load or drive a screen. The [R0.9 manual-only package inspection workflow](.github/workflows/intelfb-package-audit.yml) now verifies complete temporary bundle metadata, macOS 15.5 deployment target, Mach-O type and Intel `8086:46A6` source-table coverage without ever loading or publishing a driver.

[Detailed safety and test scope](docs/R0.9_static_kext_audit.md). Run manually on GitHub Actions only after reviewing your usage/billing settings.

## R1.0: Source security audit (no new cloud build)

The [cross-driver source audit and go/no-go checklist](docs/R1.0_跨驱动安全审计与准入结论.md) examines Intel MMIO bounds, the `nvScanoutInfo` capacity ABI, NVIDIA-to-Intel copy bounds, VBL lifetime and asynchronous transaction completion. This follows the successful **static** R0.9 CI, and must not be mistaken for real-device graphics support.

The standalone [13-case offline safety contract model](tests/test_r10_bounds_model.py) is runnable locally with `python3 tests/test_r10_bounds_model.py`. **The model tests proposed failure predicates, not existing NullMoth driver behavior or patched source.** No new workflow is needed. No hardware or Windows settings are changed.

## R1.1: Review-only fail-closed candidate patch

[Review the R1.1 safety patch and limitations](docs/R1.1_候选修复与验证边界.md). The [candidate unified diff](patches/r11_scanout_bounds_and_mmio.patch) fixes NMIntelFB's BAR0 read window guard and scanout mapping-size reporting, adds source/destination bounds checks to NVAccel's active display-pipe copy path, and disables the unreviewed async flip enqueue site. It is **not** installed or automatically applied to any machine.

The [manual-only qualification workflow](.github/workflows/r11-review-patch.yml) validates a pinned temporary upstream checkout, checks patch reversibility and offline bounds cases, then attempts to compile only the patched Intel framebuffer source on hosted macOS. NVIDIA NVAccel native compilation, driver loadability, VBL lifetime and real hardware acceleration remain unverified.

## Safety and evidence

The original NullMoth source carries a PolyForm Noncommercial license. No upstream source code or vendor firmware is copied into this repository. All upstream code is fetched from its public GitHub repository into an ephemeral runner only when source mode is explicitly requested.

The NVIDIA and Intel graphics bridge remains experimental. PCI device IDs in a source table and simulated tests are not sufficient proof of hardware acceleration or a working laptop screen.
