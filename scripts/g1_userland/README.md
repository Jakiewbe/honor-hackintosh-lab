# GPU submission owner candidate: native compile gate

The mainline objective is real RTX 2050 execution with correct failure propagation
and safe stopping. This gate closes the previously missing full userland compilation
step. It does not run GPU APIs, load the bundle, install anything or prove safe stop.

Manual workflow only. NullMoth 272ccd9, the four-file previously reviewed owner
patch, and explicitly selected Vulkan-Headers v1.4.335 commit 2fa2034 are fixed.
The tag object d55a082 peels to that commit. This is a documented reconstruction,
not reproduction of the upstream private published header/build configuration.

Baseline and candidate each compile the entire nvmtl_vk.c and the entire
NVMTLDevice.m amalgamated plugin (including EventSync), then link the latter as a
bundle. No source snippets or stand-in production headers are used. All patched
files must appear in the applicable compiler dependency snapshots. Input hashes
are checked before and after, minOS must be 15.0 and architecture x86_64.
The Objective-C warning switches and frameworks follow build_plugin_release.sh;
availability errors stay errors. No undefined-dynamic-lookup option is introduced.

Only text diagnostics are uploaded. Runtime behavior, external ObjC resource
lifetimes, kernel PM/callback/close, loader acceptance, and GPU stop/reset remain
unverified. GPU NOT RUN / NO-GO even on success.

NullMoth-derived patch/header material retains the included full license.
The fixed header archive contains its original license files. Neither upstream
build scripts nor generated objects/bundles are executed.
