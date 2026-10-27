# Kernel PM candidate native gate

Compile the COMPLETE pinned `kexts/NVRM/NVRM.cpp` and `os-nvkms-xnu.cpp`
translation units, baseline and rollback-plus-admission candidate, with Xcode 16.4 / SDK
15.5 kernel headers. Source identities and the actual compiler dependency file
are bound before/after compilation. The existing explicit reconstruction profile
in `scripts/g1_24h32/PROFILE.json` is reused without injecting `NV_LINUX`.

The pinned OGKM `nvUnixVersion.h` rejects its version string on Darwin. The
explicit `darwin-version.patch` adds only the already compiler-derived
`NV_MACINTOSH` to that header's guard. Its version value remains 610.57.04;
both sides use the same patched exported header, bound by a separate manifest.
Reference trees remain untouched. This is an explicit reconstruction with a
portability patch, not a reproduction of the upstream release configuration.

The required local linker step produces x86_64 MH_KEXT_BUNDLE FORMAT from each
single TU. It deliberately does not provide the rest of the NVRM/RM objects and
does not prove complete driver linking, dependencies, loader, ABI, or hardware
behavior. No fake provider, stub, or dynamic_lookup flag is used to supply them.
The report records `complete_driver_link=NOT_ATTEMPTED`. Only text is uploaded.

This candidate rejects this driver's STANDBY when existing RM users fail to drain
and attempts local rollback. It implements COUNTED/UNCOUNTED/DENIED admission
and rejection propagation at the four RM entry points. Both final TU source
hashes are checked against the admission manifest, including NVRM.cpp after
both patches. clientClose still lacks an independent retirement owner/retry.
The NVKMS hook must replace exactly `_nv_xnu_pm_enter` with `_nv_xnu_pm_admit`
in its imports; the companion NVRM object must really define the new API.
It cannot veto
IOPM power removal, bound NVKMS lock acquisition/resume, or prove a restored GPU.

No binary is run, installed, loaded, or published. No Metal/device/USB/NVRAM/EFI
action occurs. Device remains NO-GO. The host test fixtures are orchestration
failure controls only, and never native or GPU evidence.

Run `python -B scripts/g1_kernel_pm/gate.py --nm <fixed tree> --ogkm <fixed tree>
--workspace <new directory> --out <new directory> [--prepare-only]`.
