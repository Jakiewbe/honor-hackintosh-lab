/* SPDX-License-Identifier: MIT
 * Host contract for the deferred-close unit. No IOKit: the unit takes function pointers, so this test
 * exercises the same code the driver calls.
 */
#include "kms_deferred.h"

#include <cstdio>
#include <cstring>

namespace {
int gFails;
int gCloseCalls, gFreeCalls;
bool gFreeSucceeds = true;
void *gLastClosed;

void check(bool ok, const char *what)
{
    std::printf("%s %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) gFails++;
}

void closeFn(void *data, void *) { gCloseCalls++; gLastClosed = data; }
int freeFn(void *node, void *)
{
    gFreeCalls++;
    if (!gFreeSucceeds) return 0;
    (void)node;
    return 1;
}
const struct kms_deferred_ops kOps = {closeFn, freeFn};

struct Node { int id; };
Node n1{1}, n2{2};
}  // namespace

int main()
{
    kms_deferred_reset();
    check(kms_deferred_count() == 0, "a reset unit remembers nothing");

    /* case 1: PM is not running, so nothing may be touched */
    kms_deferred_push(&n1, &n1);
    check(kms_deferred_drain(&kOps, 0, nullptr) == 0 && gCloseCalls == 0,
          "drain is inert while the GPU is not running");
    check(kms_deferred_count() == 1, "the entry survives an inert drain");

    /* case 2: running -> closed once, freed, count back to zero */
    unsigned freed = kms_deferred_drain(&kOps, 1, nullptr);
    check(freed == 1 && gCloseCalls == 1 && gLastClosed == &n1, "a running drain closes the per-open once");
    check(kms_deferred_count() == 0, "a freed entry leaves the table");

    /* case 3: free fails -> stay queued, but do not close twice */
    kms_deferred_reset();
    gCloseCalls = 0;
    gFreeSucceeds = false;
    kms_deferred_push(&n2, &n2);
    freed = kms_deferred_drain(&kOps, 1, nullptr);
    check(freed == 0 && kms_deferred_count() == 1, "a failed release keeps the entry queued");
    gFreeSucceeds = true;
    freed = kms_deferred_drain(&kOps, 1, nullptr);
    check(freed == 1 && gCloseCalls == 1, "the retry closes nothing twice and then frees");
    check(kms_deferred_count() == 0, "the retried entry leaves the table");

    /* case 4: no silent overflow */
    kms_deferred_reset();
    int pushed = 0;
    static Node many[KMS_DEFERRED_CAPACITY + 4];
    for (unsigned i = 0; i < KMS_DEFERRED_CAPACITY + 1; i++) {
        if (kms_deferred_push(&many[i], &many[i]) == 0) pushed++;
    }
    check(pushed == KMS_DEFERRED_CAPACITY, "the table reports overflow instead of forgetting an entry");

    std::printf("RESULT: %s (%d failure%s)\n", gFails ? "FAIL" : "PASS", gFails, gFails == 1 ? "" : "s");
    return gFails ? 1 : 0;
}
