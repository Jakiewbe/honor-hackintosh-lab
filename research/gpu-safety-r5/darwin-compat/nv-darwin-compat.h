/*
 * Minimal Darwin compatibility types for the OGKM cross-OS translation units.
 *
 * These are pure typedefs taken from the semantics of kernel-open/common/inc/nv.h (the Linux/FreeBSD
 * platform layer). They are kept here, alone, so that a Darwin build can satisfy the RM common layer
 * WITHOUT pulling in kernel-open/common/inc/nv.h and, with it, the Linux kernel interfaces.
 *
 * Only types that the cross-OS files actually need belong here. Nothing in this header may include a
 * Linux header.
 */
#pragma once

typedef enum
{
    NV_DYNAMIC_PM_NEVER,
    NV_DYNAMIC_PM_COARSE,
    NV_DYNAMIC_PM_FINE
} nv_dynamic_power_mode_t;
