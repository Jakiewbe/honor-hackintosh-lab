#!/usr/bin/env python3
"""Pure Python fake of DMA address/ownership transactions, NEVER an IOMMU driver.

Input address array is host addresses; successful map() publishes device IOVAs
in place, and replaces a one-element private slot with an opaque receipt.
Failure must roll back without publishing addresses. Unmap may only release
resources owned by the exact device+receipt. Incomplete rollback/unmap poisons
the model and retains an explicit outstanding lease ledger.
"""
from dataclasses import dataclass, field

PAGE = 4096
U64 = (1 << 64) - 1


class DmaError(Exception):
    pass


class Poisoned(DmaError):
    pass


@dataclass(eq=False)
class Receipt:
    device: str
    host: tuple
    iovas: tuple
    pages: int
    leases: list = field(default_factory=list)
    status: str = "ACTIVE"


class FakeBackend:
    """Artificial address translation and fault injection; no real DMA."""
    def __init__(self, offset=0x20000000):
        self.offset, self.active, self.serial = offset, {}, 0
        self.map_calls = self.unmap_calls = 0
        self.fail_map_at = self.fail_unmap_at = None

    def map_range(self, device, host, length):
        index = self.map_calls
        self.map_calls += 1
        if index == self.fail_map_at:
            raise DmaError("injected map failure")
        address = host + self.offset
        if address > U64 or length - 1 > U64 - address:
            raise DmaError("IOVA overflow")
        lease = self.serial
        self.serial += 1
        self.active[lease] = (device, address, length)
        return lease, address

    def unmap_range(self, lease):
        index = self.unmap_calls
        self.unmap_calls += 1
        if index == self.fail_unmap_at:
            raise DmaError("injected unmap failure")
        if lease not in self.active:
            raise DmaError("already released")
        del self.active[lease]


class TransactionalDma:
    """Demonstrates publication/rollback/ownership, NOT Apple DMA ABI."""
    def __init__(self, device, limit, backend):
        if not device or type(limit) is not int or not 0 <= limit <= U64:
            raise ValueError("invalid DMA device/aperture")
        self.device, self.limit, self.backend = device, limit, backend
        self.receipts, self.quarantined, self.poisoned = set(), [], False

    @staticmethod
    def checked(address, length, limit):
        if (type(address) is not int or length < 1 or address < 0 or
                address % PAGE or address > limit or length - 1 > limit - address):
            raise DmaError("invalid device address, alignment or range")

    def map(self, device, va, priv, pages, contiguous=False):
        if self.poisoned:
            raise Poisoned("unresolved mapping ownership")
        if device != self.device or not isinstance(va, list) or not isinstance(priv, list) or len(priv) != 1:
            raise DmaError("wrong device / array / private slot")
        if type(pages) is not int or not 1 <= pages <= U64 // PAGE:
            raise DmaError("invalid page count")
        expected = 1 if contiguous else pages
        if len(va) != expected or isinstance(priv[0], Receipt):
            raise DmaError("wrong array shape or active mapping handle")
        lengths = [pages * PAGE] if contiguous else [PAGE] * pages
        old = tuple(va)
        for address, length in zip(old, lengths):
            self.checked(address, length, U64)
        leases, mapped = [], []
        try:
            for address, length in zip(old, lengths):
                lease, bus = self.backend.map_range(self.device, address, length)
                leases.append(lease)
                self.checked(bus, length, self.limit)
                mapped.append(bus)
        except Exception as error:
            unreleased = set(leases)
            for lease in reversed(leases):
                try:
                    self.backend.unmap_range(lease)
                    unreleased.remove(lease)
                except Exception:
                    pass
            if unreleased:
                self.quarantined.extend(sorted(unreleased))
                self.poisoned = True
                raise Poisoned("rollback incomplete; backend leases quarantined") from error
            raise DmaError("failed; map was rolled back without publication") from error
        receipt = Receipt(self.device, old, tuple(mapped), pages, list(leases))
        va[:] = mapped
        priv[0] = receipt
        self.receipts.add(receipt)
        return receipt

    def unmap(self, device, va, priv, pages):
        if device != self.device or not isinstance(priv, list) or len(priv) != 1:
            raise DmaError("wrong device/private slot")
        rec = priv[0]
        if not isinstance(rec, Receipt) or rec not in self.receipts:
            raise DmaError("missing, alien or stale receipt")
        if (type(pages) is not int or pages != rec.pages or
                not isinstance(va, list) or tuple(va) != rec.iovas):
            raise DmaError("page count / IOVA array mismatch")
        for lease in list(reversed(rec.leases)):
            try:
                self.backend.unmap_range(lease)
                rec.leases.remove(lease)
            except Exception as error:
                rec.status = "INCOMPLETE_UNMAP"
                self.poisoned = True
                raise Poisoned("unmap incomplete; receipt retained") from error
        rec.status = "RELEASED"
        self.receipts.remove(rec)
        priv[0] = None
        # Do not pretend va is restored: Linux's actual post-unmap pointer
        # behavior differs by allocation/SGT path. The stale IOVAs are invalid.

    def retry_unmap_synthetic(self, device, va, priv, pages):
        """Lab-only recovery after injected failure; never real DMA quiescence."""
        self.unmap(device, va, priv, pages)
        if not self.quarantined and not any(
                r.status == "INCOMPLETE_UNMAP" for r in self.receipts):
            self.poisoned = False
