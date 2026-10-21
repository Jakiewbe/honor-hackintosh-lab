#!/usr/bin/env python3
"""Name attribution against archived runner evidence; never loader/ABI acceptance."""
from collections import Counter
import hashlib
import plistlib

NVLINK = {'_nvlink_'+n+'Lock' for n in ('alloc', 'acquire', 'release', 'free')}


def attribute(imports, evidence):
    plist = evidence/'kernel-symbolsets-decoded.txt'
    kernel = evidence/'runner-kernel-nm-raw.txt'
    families = [evidence/(name+'-kext-allowlist-raw.txt') for name in ('IOPCIFamily', 'IOACPIFamily')]
    sets = plistlib.loads(plist.read_bytes())['SymbolsSets']
    # Explicit names only: no blanket prefix acceptance or inference from an old import count.
    kpi = {}
    for group in sets:
        for row in group['Symbols']:
            if 'SymbolName' in row:
                kpi.setdefault(row['SymbolName'], []).append((group['CFBundleIdentifier'],
                    row.get('AliasTarget', row['SymbolName'])))
    actual = {line.split()[-1] for line in kernel.read_text(encoding='utf-8').splitlines()
              if len(line.split()) >= 3 and line.split()[-2].isupper() and line.split()[-2] != 'U'}
    exports = {p.name.split('-')[0]: {s.strip() for s in p.read_text(encoding='utf-8').splitlines()
               if s.strip().startswith('_') and ' ' not in s.strip()} for p in families}
    rows = []
    for name in sorted(set(imports)):
        row = dict(symbol=name, abi='UNVERIFIED', user_device_binding='UNVERIFIED')
        observed = [(bundle, target) for bundle, target in kpi.get(name, []) if target in actual]
        if observed:
            row.update(category='HISTORICAL_RUNNER_KPI_AND_DEFINITION',
                       providers=[dict(bundle=b, alias_target=t) for b, t in observed])
        elif any(name in names for names in exports.values()):
            row.update(category='HISTORICAL_FAMILY_ALLOWLIST_ONLY',
                       providers=[family for family, names in exports.items() if name in names])
        elif name.startswith('_nvKms'):
            row.update(category='INTERNAL_NVKMS_NOT_LINKED',
                       next_evidence='Compile/link fixed nvidia-modeset; prefix alone is not provider proof')
        elif name in NVLINK:
            row.update(category='INTERNAL_NVLINK_OS_BACKEND_MISSING',
                       contract='OGKM src/common/nvlink/interface/nvlink_os.h:56-60',
                       next_evidence='Explicit real Darwin backend plus same-run definition/import delta')
        else:
            row.update(category='UNKNOWN')
        rows.append(row)
    return dict(level='HISTORICAL_SYMBOL_NAME_ATTRIBUTION_NOT_LOADER_OR_ABI_ACCEPTANCE',
                count=len(rows), counts=dict(Counter(r['category'] for r in rows)), rows=rows,
                provider_evidence_sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                                         for p in [plist, kernel, *families]})
