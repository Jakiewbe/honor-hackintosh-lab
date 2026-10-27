# Migration destination ownership candidate

This is a separate combined patch against fixed NullMoth 272ccd9, retaining the
previously reviewed four-file owner patch. The parent owner.patch/manifest stay
unchanged. Invoke the native gate with --profile migration.

The additive outcome API separates completed, no submission for this call, and
registered retained work whose completion is unproven. Legacy integer return
values remain compatible; -2 is not proof that QueueSubmit was called.

Before submitting the synchronous image/buffer migration copy, the heap owner
copies private destination image/view/buffer/memory handles. Uncertain failures
leave those handles in the registry and leave the caller's source unchanged;
pre-registration failure and success retain normal cleanup responsibility.

This does not repair migration batching, arbitrary source/imported/ObjC resource
pinning, staging-pool bookkeeping, kernel PM/close/callbacks, or provide a safe
stop/reset reclamation API. No GPU execution or installation is authorized.
NullMoth-derived code retains the parent LICENSE-NullMoth.txt license.
