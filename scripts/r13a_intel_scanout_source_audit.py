#!/usr/bin/env python3
"""R1.3-A source-only audit of two Intel internal-screen driver architectures.

Input: an UNEXECUTED, read-only checkout of NullMoth commit
1083a98db33a0bb824290556de255f9a95ca5403 (v1.14.2).
Checks Git blob identity before making any claim. Contains no network calls,
kernel driver build/load, GPU access, or host configuration changes.

SOURCE_CONTRACTS_MATCH means the exact hazardous/limited structures were found.
It NEVER means driver safety or macOS internal-panel feasibility.
"""
import argparse
import hashlib
import json
from pathlib import Path

UPSTREAM = "nullmoth/nvidia-macos-driver"
RELEASE_COMMIT = "1083a98db33a0bb824290556de255f9a95ca5403"
BLOBS = {
    "gpu-port/README.md": "0f80732aaa0f51a3928835503aaa2168b46de3f9",
    "gpu-port/xkpi/xnu/nmx_kext.cpp": "b70d4c692a7ff431664186afb36f6d0c1482e116",
    "gpu-port/xkpi/xnu/nmx_fb.cpp": "b1796307c49a5daf60defb6316b1aa66b12c79e2",
    "gpu-port/xkpi/override/src/nmx_fb_bridge.c":
        "3d7bb9b6622b90c978dc0207bda30864baa463d2",
    "kexts/NMIntelFB/intelfb.cpp": "d3891a3884a1ab14c295b74ad34c980b5f1ea7f1",
    "kexts/NMIntelFB/display_ids.inc": "03fc18f018be25593fd60966799822e5f5d97b1e",
    "kexts/NVRM/accel/nvrm-accel.cpp":
        "23297f332ad5228198b6f95802dec54293810a94",
}


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(
        b"blob " + str(len(data)).encode("ascii") + b"\x00" + data
    ).hexdigest()


def check(root: Path):
    matched = {}
    files = {}
    for name, expected in BLOBS.items():
        raw = (root / name).read_bytes()
        matched[name] = git_blob_sha(raw) == expected
        files[name] = raw.decode("utf-8")
    if not all(matched.values()):
        return {
            "audit": "BLOCKED_SOURCE_MISMATCH",
            "source_git_blobs": matched,
            "runtime_decision": "NO_GO",
            "note": "Do not interpret unmatched source content or reuse old findings.",
        }

    intro = files["gpu-port/README.md"]
    nmx = files["gpu-port/xkpi/xnu/nmx_kext.cpp"]
    fb = files["gpu-port/xkpi/xnu/nmx_fb.cpp"]
    bridge = files["gpu-port/xkpi/override/src/nmx_fb_bridge.c"]
    old = files["kexts/NMIntelFB/intelfb.cpp"]
    ids = files["kexts/NMIntelFB/display_ids.inc"]
    accel = files["kexts/NVRM/accel/nvrm-accel.cpp"]

    contracts = {
        "8086_46a6_in_old_display_id_table": "{0x46a6, 13}," in ids,
        "nmxgpu_reports_no_physical_gpu_load":
            "It has not been loaded on hardware." in intro,
        "i915_claimed_for_alder_lake_in_documentation":
            "i915 covers Gen9 through Arrow Lake/Meteor Lake" in intro,
        "nmxgpu_requires_vendor_opt_in": "if (!opted_in(pci, vendor))" in nmx,
        "nmxgpu_publishes_drm_display_bridge":
            "fb_ = nmx_fb_publish(this, dev_);" in nmx,
        "nmxgpu_synchronous_fb_unpublish":
            "fbsvc->terminate(kIOServiceSynchronous);" in fb,
        "nmxgpu_vbl_callback_invoked_from_raw_timer":
            "if (me->fVbl.proc) me->fVbl.proc(me->fVbl.target, me->fVbl.ref);" in fb,
        "nmxgpu_unregister_is_noop":
            "IOReturn unregisterInterrupt(void *) override { return kIOReturnSuccess; }"
            in fb,
        "nmxgpu_set_interrupt_state_is_noop":
            "IOReturn setInterruptState(void *, UInt32) override { return kIOReturnSuccess; }"
            in fb,
        "nmxgpu_stop_retries_timed_thread_call_free":
            "while (!thread_call_free(fVblTimer))" in fb and "IOSleep(5)" in fb,
        "nmxgpu_fb_uses_drm_mode_commit":
            "drm_client_modeset_commit(&fb->client)" in bridge,
        "nmxgpu_fb_requires_physically_contiguous_scanout":
            "nmx_xnu_kva_to_phys(va + off) != base + off" in bridge,
        "old_intelfb_adopts_firmware_mode":
            "bool NMIntelFB::adoptFirmwareMode()" in old
            and "if (!adoptFirmwareMode())" in old,
        "old_intelfb_rejects_inactive_firmware_pipe":
            "no pipe is scanning out - the firmware left the panel off" in old,
        "old_intelfb_restricts_linear_xrgb8888":
            "if (fmtOf(ctl) != 8)" in old
            and "if (tileOf(ctl) != 0)" in old,
        "old_intelfb_export_cpu_copy_destination":
            "r->kva = (void *)fSurfMap->getVirtualAddress();" in old
            and "r->phys = 0;" in old,
        "nvaccel_describes_intel_panel_head4":
            "IOFBDependentIndex 4" in accel,
        "nvaccel_disallows_nvidia_flip_on_other_vendor_display":
            'if (!fb->metaCast("NVRMNVDAFramebuffer")) return false;' in accel,
    }
    return {
        "audit": "SOURCE_CONTRACTS_MATCH" if all(contracts.values())
                 else "BLOCKED_SOURCE_STRUCTURE_CHANGED",
        "upstream": UPSTREAM,
        "release_commit": RELEASE_COMMIT,
        "source_git_blobs": matched,
        "contracts": contracts,
        "runtime_decision": "NO_GO",
        "hardware": "HONOR GLO-FX6P / Intel 8086:46A6 / NVIDIA 10DE:25A9",
        "evidence_limit": (
            "Checks that documented architecture and risk patterns are present; "
            "does not validate Intel scanout, NVIDIA Metal, lock safety, "
            "driver loadability, panel physical wiring, or install readiness."
        ),
    }


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source-root", type=Path, required=True,
                   help="unexecuted checkout of the exact upstream commit")
    args = p.parse_args()
    try:
        output = check(args.source_root)
    except (OSError, UnicodeDecodeError, ValueError) as exc:
        output = {"audit": "BLOCKED_INPUT_ERROR", "reason": str(exc),
                  "runtime_decision": "NO_GO"}
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0 if output["audit"] == "SOURCE_CONTRACTS_MATCH" else 2


if __name__ == "__main__":
    raise SystemExit(main())
