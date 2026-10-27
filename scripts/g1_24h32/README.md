# 24H32 NVAccel native object/link gate

Manual workflow only, authorized by the user on 2026-10-27. Fetches two fixed public
source commits, applies the reviewed four-file forwarder/opaque-enum patch, uses the explicit
reconstruction profile, and compiles/links two NVAccel variants with Xcode16.4/SDK15.5.
The profile does not reproduce private published build inputs.

`native_gate.py` and its input-binding helper are the reviewed local gate sources.
`ci_prepare.py` constructs a fresh source-only package and verifies all four patched
file identities. `route-proof.json` is static evidence for the already returned
24H32 collection, not a replacement runner kernel or dynamic ABI proof.

The enum revision changes four aliases in the single common `iofam_types.h` to
opaque enums with fixed unsigned-int representation and no invented enumerators.
This repairs seven mangled names; it does not remove their function references.
The expected candidate import count remains 864, not 857.

`target-symbols.json` records exact-name external section definitions observed in
the three returned target KCs and kernel. `import_contract.py` checks every candidate
import, including inherited imports, and rejects old enum spellings, unknown names,
or missing expected references. Section definitions do not prove loader exports,
dependency selection, calling conventions, or full ABI.

The corrected profile does not inject NV_LINUX. Actual clang macro output must
report NVOS_IS_LINUX=0. Include paths come from the recorded Darwin make dry-run
(29 directories) plus nine explicitly documented NVAccel KAPI/modeset additions.
Seven make-listed directories are absent from the pinned tree and recorded as
such; clang tolerates nonexistent search directories. No directories or headers
are fabricated to satisfy them. The profile remains an explicit reconstruction.

Outputs are text diagnostics only. Generated objects/kexts remain on the ephemeral
runner and are never installed, loaded or run. This job does not compile the separate
userland owner-retention patch or establish kernel PM/headless/drain safety.
GPU NOT RUN / NO-GO even if the object/link gate passes.

NullMoth-derived material retains PolyForm-Noncommercial-1.0.0 and the full included
license. Full fixed OGKM source includes its original COPYING at preparation time.
