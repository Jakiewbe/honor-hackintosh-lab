#include <IOKit/pci/IOPCIDevice.h>
#include <IOKit/acpi/IOACPIPlatformDevice.h>
extern "C" auto kc_read8(IOPCIDevice* p, IOByteCount o) { return p->extendedConfigRead8(o); }
extern "C" void kc_write8(IOPCIDevice* p, IOByteCount o, UInt8 v) { p->extendedConfigWrite8(o, v); }
extern "C" auto kc_read16(IOPCIDevice* p, IOByteCount o) { return p->extendedConfigRead16(o); }
extern "C" void kc_write16(IOPCIDevice* p, IOByteCount o, UInt16 v) { p->extendedConfigWrite16(o, v); }
extern "C" auto kc_read32(IOPCIDevice* p, IOByteCount o) { return p->extendedConfigRead32(o); }
extern "C" void kc_write32(IOPCIDevice* p, IOByteCount o, UInt32 v) { p->extendedConfigWrite32(o, v); }
extern "C" const void* kc_pci_meta() { return &IOPCIDevice::metaClass; }
extern "C" const void* kc_acpi_meta() { return &IOACPIPlatformDevice::metaClass; }
