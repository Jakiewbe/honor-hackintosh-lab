# Kernel PM candidate native gate

Compile the COMPLETE pinned `kexts/NVRM/NVRM.cpp` and `os-nvkms-xnu.cpp`
translation units, baseline and rollback-plus-admission candidate, with Xcode 16.4 / SDK
15.5 kernel headers. Source identities and the actual compiler dependency file
are bound before/after compilation. The existing explicit reconstruction profile
in `scripts/g1_24h32/PROFILE.json` is reused without injecting `NV_LINUX`.

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
It cannot veto
IOPM power removal, bound NVKMS lock acquisition/resume, or prove a restored GPU.

No binary is run, installed, loaded, or published. No Metal/device/USB/NVRAM/EFI
action occurs. Device remains NO-GO. The host test fixtures are orchestration
failure controls only, and never native or GPU evidence.

Run `python -B scripts/g1_kernel_pm/gate.py --nm <fixed tree> --ogkm <fixed tree>
--workspace <new directory> --out <new directory> [--prepare-only]`.
