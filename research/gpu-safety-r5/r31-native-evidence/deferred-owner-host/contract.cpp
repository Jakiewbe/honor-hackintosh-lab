
#include "kms_deferred.h"
#include <cstdio>
static int closes, frees, nested;
static kms_deferred_ops ops;
static void close_cb(void *, void *) { ++closes; }
static int free_cb(void *, void *) {
    ++frees;
    if (nested == 1) { nested = 2; kms_deferred_drain(&ops, 1, nullptr); }
    return 1;
}
int main() {
    ops.close = close_cb; ops.try_free = free_cb;
    int nodes[KMS_DEFERRED_CAPACITY + 1] = {};
    kms_deferred_reset();
    int first = kms_deferred_push(&nodes[0], &nodes[0]);
    int repeated = kms_deferred_push(&nodes[0], &nodes[0]);
    unsigned duplicate_count = kms_deferred_count();
    kms_deferred_drain(&ops, 1, nullptr);
    bool unique = first == 0 && repeated == 0 && duplicate_count == 1 && closes == 1 && frees == 1;
    std::printf("duplicate unique_node=%s entries=%u close_calls=%d free_calls=%d\n",
                unique ? "PASS" : "FAIL", duplicate_count, closes, frees);
    kms_deferred_reset(); closes = frees = 0; nested = 1;
    kms_deferred_push(&nodes[0], &nodes[0]);
    kms_deferred_drain(&ops, 1, nullptr);
    bool owned = closes == 1 && frees == 1 && kms_deferred_count() == 0;
    std::printf("reentrant unique_free=%s close_calls=%d free_calls=%d\n",
                owned ? "PASS" : "FAIL", closes, frees);
    kms_deferred_reset(); closes = frees = nested = 0;
    int overflow = 0;
    for (unsigned i = 0; i < KMS_DEFERRED_CAPACITY + 1; ++i)
        if (kms_deferred_push(&nodes[i], &nodes[i]) != 0) ++overflow;
    kms_deferred_drain(&ops, 1, nullptr);
    bool capacity = overflow == 1 && closes == KMS_DEFERRED_CAPACITY && frees == KMS_DEFERRED_CAPACITY;
    std::printf("capacity overflow_observable=%s unqueued=%d close_calls=%d free_calls=%d\n",
                capacity ? "PASS" : "FAIL", overflow, closes, frees);
    // This test verifies the queue's rejection, NOT a caller's recovery of it.
    return unique && owned && capacity ? 0 : 1;
}
