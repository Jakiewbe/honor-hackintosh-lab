/* SPDX-License-Identifier: MIT
 * Deferred NVKMS close bookkeeping, kept free of IOKit so it can be tested on a plain CPU.
 *
 * Why this unit exists: a close that cannot run while the GPU is suspended must be remembered and
 * finished after the resume. The original code only counted such closes, so the per-open, its wrapper
 * and its event call leaked until unload. Putting the list here means the drain logic is the same code
 * the driver runs, and it can be exercised by a host test without mocking IOKit.
 *
 * The unit never allocates: capacity is fixed and an overflow is reported, not hidden.
 */
#ifndef KMS_DEFERRED_H
#define KMS_DEFERRED_H

#ifdef __cplusplus
extern "C" {
#endif

#define KMS_DEFERRED_CAPACITY 64

struct kms_deferred_ops {
    /* Close the NVKMS per-open. Called at most once per entry. */
    void (*close)(void *data, void *arg);
    /* Try to release the wrapper. Nonzero means the node was freed and can leave the list. */
    int (*try_free)(void *node, void *arg);
};

/* Drop every entry without calling anything. */
void kms_deferred_reset(void);

/* Remember one node. Returns 0 on success, -1 when the table is full (the caller must then keep the
 * resources and refuse further deferred closes loudly rather than silently forgetting one). */
int kms_deferred_push(void *node, void *data);

/* Finish remembered closes. Does nothing unless pm_running is nonzero, because NVKMS must not touch the
 * display engine in any other state. Returns the number of entries freed by this call. */
unsigned kms_deferred_drain(const struct kms_deferred_ops *ops, int pm_running, void *arg);

/* Entries still remembered (closed-but-not-freed entries included). */
unsigned kms_deferred_count(void);

#ifdef __cplusplus
}
#endif

#endif
