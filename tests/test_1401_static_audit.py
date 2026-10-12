"""1401 v1.14.2 static audit against the measured GLO-FX6P facts (code-level only, NOT boot or install validation).

Feeds facts from docs/hardware-survey-20261012/hardware.json into 1401's own pure rule functions
(p1401.nullmoth, p1401.panel_guard) and text-checks policy constants. Nothing here touches disks, EFI, NVRAM,
the network or the registry; the only subprocess is a read-only `git rev-parse` of the pinned upstream checkout.

The GPU/Monitor dicts below are a minimal stand-in using the field names 1401's code reads. They are NOT a
Hardware-Sniffer Report.json; 1401's real scan output for this machine has never been produced.

Run: python tests/test_1401_static_audit.py
"""
import json
import os
import plistlib
import subprocess
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UP = os.path.join(ROOT, "upstream", "1401")
DRV = os.path.join(ROOT, "upstream", "nvidia-macos-driver")
HW = os.path.join(ROOT, "docs", "hardware-survey-20261012", "hardware.json")
PINNED_SHA = "46d9fee308bbb8e373807d59773823e6a93c1f63"  # nullmoth/1401 tag v1.14.2
DRIVER_SHA = "1083a98db33a0bb824290556de255f9a95ca5403"  # nullmoth/nvidia-macos-driver tag v1.14.2

IGPU = "Intel(R) Iris(R) Xe Graphics"
DGPU = "NVIDIA GeForce RTX 2050"


def load_hw():
    with open(HW, encoding="utf-8-sig") as f:
        return json.load(f)


def gpu(hw, vendor):
    return next(g for g in hw["gpus"] if g["ids"]["vendor_id"] == vendor)


def stand_in_report():
    return {"GPU": {DGPU: {"Manufacturer": "NVIDIA", "Device Type": "Discrete GPU", "Device ID": "10DE-25A9"},
                    IGPU: {"Manufacturer": "Intel", "Device Type": "Integrated GPU", "Device ID": "8086-46A6",
                           "Compatibility": (None, None)}},
            "Monitor": {"BOE0893": {"Connector Type": "Internal", "Connected GPU": IGPU}}}


@unittest.skipUnless(os.path.isdir(os.path.join(UP, "p1401")), "upstream/1401 not cloned")
class Pinned(unittest.TestCase):
    def test_upstream_checkout_is_the_audited_tag(self):
        sha = subprocess.run(["git", "-C", UP, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        self.assertEqual(sha, PINNED_SHA, "upstream/1401 moved: re-audit before trusting the other assertions")


class MeasuredFacts(unittest.TestCase):
    """Facts from the 2026-10-12 read-only survey that the audit conclusions depend on."""

    def setUp(self):
        self.hw = load_hw()

    def test_dgpu_is_a_3d_controller_without_display_sources(self):
        nv = gpu(self.hw, "10DE")
        self.assertEqual(nv["ids"]["device_id"], "25A9")
        self.assertIn("PCI\\VEN_10DE&DEV_25A9&CC_0302", nv["hardware_ids"])
        self.assertFalse(nv["wddm"]["display_supported"])
        self.assertEqual(nv["wddm"]["num_of_sources"], 0)
        self.assertEqual(self.hw["displays"]["connector_targets_exposed_by_driver"]["nvidia_25A9"]["total"], 0)

    def test_internal_panel_is_driven_by_the_intel_igpu(self):
        paths = self.hw["displays"]["active_paths"]
        self.assertEqual(len(paths), 1)
        self.assertEqual(paths[0]["display_adapter_is"], "Intel 8086:46A6")
        self.assertEqual(paths[0]["output_technology"], "INTERNAL")
        self.assertEqual(gpu(self.hw, "8086")["ids"]["device_id"], "46A6")

    def test_mux_presence_is_still_unknown(self):
        self.assertIsNone(self.hw["hybrid_graphics"]["mux_present"])


@unittest.skipUnless(os.path.isdir(os.path.join(UP, "p1401")), "upstream/1401 not cloned")
class RulesOnThisMachine(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if UP not in sys.path:
            sys.path.insert(0, UP)
        from p1401 import nullmoth, panel_guard  # noqa: PLC0415 - pure modules, no I/O beyond reading their JSON
        cls.nm, cls.pg = nullmoth, panel_guard

    def test_rtx_2050_is_in_the_gsp_table_but_never_hardware_tested(self):
        self.assertIn("25A9", self.nm.TABLE["ids"])
        self.assertNotIn("25A9", self.nm.TABLE["tested"])
        self.assertEqual(self.nm.tested(stand_in_report()), [])

    def test_table_hit_alone_marks_the_card_macos_15(self):
        report = stand_in_report()
        self.assertEqual(self.nm.mark(report), [DGPU])
        self.assertEqual(report["GPU"][DGPU]["Compatibility"], self.nm.SEQUOIA)

    def test_panel_on_intel_triggers_the_dark_screen_note(self):
        note = self.nm.mux_help(stand_in_report())
        self.assertIsNotNone(note)
        self.assertIn("built-in screen stays dark", note)

    def test_panel_guard_keeps_the_unsupported_igpu_on(self):
        disabled = {"GPU: " + IGPU: {"Device Type": "Integrated GPU", "Device ID": "8086-46A6",
                                     "Compatibility": (None, None)}}
        capture = {"device_map": {"graphics": {"status": "measured", "value": [
            {"vendor_id": "8086", "device_id": "46A6", "displays": [
                {"internal_panel": True, "active": True,
                 "routing_source": "QueryDisplayConfig targetInfo.adapterId"}]}]}}}
        self.assertEqual(self.pg.intel_panel_keys(disabled, capture), ["GPU: " + IGPU])
        self.assertIn("works in macOS through the firmware display", self.pg.KEEP_NOTE)

    def test_driver_policy_relaxes_sip_and_amfi(self):
        self.assertEqual(self.nm.SIP_DRIVER, bytes.fromhex("430A0000"))
        for arg in ("amfi_get_out_of_my_way=0x1", "amfi=0x80", "ipc_control_port_options=0"):
            self.assertIn(arg, self.nm.BOOT_ARGS)


@unittest.skipUnless(os.path.isdir(os.path.join(UP, "p1401")), "upstream/1401 not cloned")
class PolicyText(unittest.TestCase):
    def read(self, *parts):
        with open(os.path.join(UP, *parts), encoding="utf-8") as f:
            return f.read()

    def test_installer_bar_rule(self):
        src = self.read("p1401", "policy.py")
        self.assertIn('cfg["Booter"]["Quirks"]["ResizeAppleGpuBars"] = 0', src)
        self.assertIn('cfg["UEFI"]["Quirks"]["ResizeGpuBars"] = -1', src)

    def test_iasl_is_fetched_unpinned_when_absent(self):
        src = self.read("upstream", "OpCore-Simplify", "Scripts", "dsdt.py")
        self.assertIn("def check_iasl", src)
        self.assertIn("acpica", src)
        # plan path: OCPE() -> ACPIGuru() -> DSDT() -> check_iasl() downloads when this file is missing
        self.assertFalse(os.path.exists(os.path.join(UP, "upstream", "OpCore-Simplify", "Scripts", "iasl.exe")))


@unittest.skipUnless(os.path.isdir(os.path.join(DRV, "kexts")), "upstream/nvidia-macos-driver not cloned")
class DriverFramebufferClaim(unittest.TestCase):
    """driver#119 / PR #131: NVRMFBClaim also takes an Intel iGPU's IOFramebuffer slot."""

    def test_driver_checkout_is_the_audited_tag(self):
        sha = subprocess.run(["git", "-C", DRV, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        self.assertEqual(sha, DRIVER_SHA, "nvidia-macos-driver moved: re-audit (PR #131 may have landed)")

    def test_nvrmfbclaim_matches_any_display_named_pci_device(self):
        with open(os.path.join(DRV, "kexts", "NVRMFB", "fb", "Info.plist"), "rb") as f:
            claim = plistlib.load(f)["IOKitPersonalities"]["NVRMFBClaim"]
        self.assertEqual(claim["IOProviderClass"], "IOPCIDevice")
        self.assertEqual(claim["IONameMatch"], "display")
        self.assertEqual(claim["IOMatchCategory"], "IOFramebuffer")
        self.assertGreater(claim["IOProbeScore"], 20000)  # outranks IONDRVFramebuffer
        for vendor_filter in ("IOPCIMatch", "IOPCIPrimaryMatch", "IOPCIClassMatch"):
            self.assertNotIn(vendor_filter, claim)


if __name__ == "__main__":
    unittest.main(verbosity=2)
