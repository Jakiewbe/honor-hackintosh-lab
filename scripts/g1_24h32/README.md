# 24H32 NVAccel native object/link gate

Manual workflow only, authorized by the user on 2026-10-27. Fetches two fixed public
source commits, applies the reviewed three-file forwarder patch, uses the explicit
reconstruction profile, and compiles/links two NVAccel variants with Xcode16.4/SDK15.5.
The profile does not reproduce private published build inputs.

`native_gate.py` and its input-binding helper are the reviewed local gate sources.
`ci_prepare.py` constructs a fresh source-only package and verifies all three patched
file identities. `route-proof.json` is static evidence for the already returned
24H32 collection, not a replacement runner kernel or dynamic ABI proof.

Outputs are text diagnostics only. Generated objects/kexts remain on the ephemeral
runner and are never installed, loaded or run. This job does not compile the separate
userland owner-retention patch or establish kernel PM/headless/drain safety.
GPU NOT RUN / NO-GO even if the object/link gate passes.

NullMoth-derived material retains PolyForm-Noncommercial-1.0.0 and the full included
license. Full fixed OGKM source includes its original COPYING at preparation time.
