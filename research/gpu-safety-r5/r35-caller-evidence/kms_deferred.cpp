/* SPDX-License-Identifier: MIT */
#include "kms_deferred.h"

namespace {
struct Entry {
    void *node;
    void *data;      /* NULL once closed */
    int closed;
};
Entry gEntries[KMS_DEFERRED_CAPACITY];
unsigned gCount;
}  // namespace

extern "C" void kms_deferred_reset(void)
{
    for (unsigned i = 0; i < KMS_DEFERRED_CAPACITY; i++) {
        gEntries[i].node = nullptr;
        gEntries[i].data = nullptr;
        gEntries[i].closed = 0;
    }
    gCount = 0;
}

extern "C" int kms_deferred_push(void *node, void *data)
{
    if (!node) return -1;
    for (unsigned i = 0; i < KMS_DEFERRED_CAPACITY; i++) {
        if (gEntries[i].node == nullptr) {
            gEntries[i].node = node;
            gEntries[i].data = data;
            gEntries[i].closed = 0;
            gCount++;
            return 0;
        }
    }
    return -1;  /* full: caller keeps the resources and must report the loss */
}

extern "C" unsigned kms_deferred_drain(const struct kms_deferred_ops *ops, int pm_running, void *arg)
{
    if (!ops || !pm_running) return 0;
    unsigned freed = 0;
    for (unsigned i = 0; i < KMS_DEFERRED_CAPACITY; i++) {
        Entry &e = gEntries[i];
        if (!e.node) continue;
        if (!e.closed && e.data) {
            ops->close(e.data, arg);
            e.data = nullptr;
            e.closed = 1;
        }
        if (ops->try_free(e.node, arg)) {
            e.node = nullptr;
            e.data = nullptr;
            e.closed = 0;
            if (gCount) gCount--;
            freed++;
        }
    }
    return freed;
}

extern "C" unsigned kms_deferred_count(void)
{
    return gCount;
}
