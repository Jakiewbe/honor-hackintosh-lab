# Batch migration ledger R2

Independent combined patch against NullMoth 272ccd9. Use --profile batching-r2.
The original owner, migration and batching profiles remain unchanged.

A fixed-capacity heap block is allocated before opening the batch command buffer.
The pending block itself becomes the retained ledger on an unproven submission;
settling that submission performs no allocation. A failed initial allocation
does not open a batch. The owning pager pairs each migrate with one pend call.

Repeated end calls preserve the submission verdict until settle; begin refuses
an ended, unsettled block. Threshold flush errors travel through pend to the
ObjC pager, which stops its pressure pass before its completion epoch and
paged-success report. The legacy submit error is separate from retention.

Retained entries store source and target descriptions with no dangling rstate
pointer. No stop/reset reclamation exists; retained storage grows. This is not
complete ObjC/imported-resource pinning, thread-exit recovery, staging-pool
repair, ABI/loader verification, or GPU/stop/reset evidence. The early dealloc
heap/alias paths remain outside this patch. No device execution is authorized.

Derived code retains the upstream LICENSE-NullMoth.txt license.
