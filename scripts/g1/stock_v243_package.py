#!/usr/bin/env python3
"""Offline/native bundle evidence, never a loader, signer or GPU test.

Consumes the same-run internal link. Builds the two other kernel components
separately, records bundle/KMOD identity, bounded Mach-O metadata, and exact
declared provider/version matches. A PASS is deliberately narrower than loadability.
"""
import argparse
import collections
import hashlib
import json
import plistlib
from pathlib import Path
import re
import shutil
import subprocess
import struct
import sys

import stock_v243_kext_link as base
from stock_v243_internal_link import PASS as INTERNAL_PASS, patch_run

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
import g1_kc8 as kc
from g1_target_providers import section_bounds

PASS = 'PASS_STATIC_KERNEL_BUNDLES_NOT_LOADER_ABI_OR_GPU_ACCEPTANCE'
PASS_LOCAL_ONLY = PASS + '_LOCAL_ONLY_EXPORTS_UNVERIFIED'
SPECS = {
    'NVRM': ('kexts/NVRM/Info.plist', None),
    'NVRMFB': ('kexts/NVRMFB/fb/Info.plist', 'kexts/NVRMFB/fb/nvrm-fb.cpp'),
    'NVAccel': ('kexts/NVRM/accel/Info.plist', 'kexts/NVRM/accel/nvrm-accel.cpp'),
}


def version(value):
    # OSKext's numeric fields and development stages, not lexicographic strings.
    m = re.fullmatch(r'(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:(d|a|b|fc)(\d+))?', value)
    if not m:
        raise ValueError('unsupported bundle version: '+str(value))
    nums = tuple(int(v or 0) for v in m.group(1, 2, 3))
    if any(v > 9999 for v in nums) or int(m[5] or 0) > 255:
        raise ValueError('bundle version out of range')
    return (*nums, {None:4, 'd':0, 'a':1, 'b':2, 'fc':3}[m[4]], int(m[5] or 0))


def compatible(required, provider):
    # No compatible-version metadata means exact-version only; never assume 0.
    current = provider['CFBundleVersion']
    lower = provider.get('OSBundleCompatibleVersion', current)
    return version(lower) <= version(required) <= version(current)


def declared_dependencies(declared, symbolsets, families):
    """Every declaration matters, even when no current import uses that dependency."""
    groups = {g['CFBundleIdentifier']: g for g in symbolsets['SymbolsSets']}
    rows = []
    for bid, required in declared.items():
        version(required)
        f = families.get(bid)
        info = groups.get(bid) or (f.get('info') if f else None)
        if info:
            status = 'VERSION_COMPATIBLE' if compatible(required, info) else 'VERSION_INCOMPATIBLE'
        elif f and f.get('present_in_collection'):
            status = 'IDENTITY_OBSERVED_VERSION_UNVERIFIED'
        else:
            status = 'DEPENDENCY_ABSENT'
        rows.append(dict(bundle=bid, required=required, status=status))
    return dict(rows=rows, rejected=[r for r in rows if r['status'] in ('VERSION_INCOMPATIBLE', 'DEPENDENCY_ABSENT')],
        unverified=[r for r in rows if r['status'] == 'IDENTITY_OBSERVED_VERSION_UNVERIFIED'])


def accept_declared_dependencies(declared, symbolsets, families):
    result = declared_dependencies(declared, symbolsets, families)
    if result['rejected']:
        raise ValueError('declared dependency rejected: '+str(result['rejected']))
    return result


VTABLE_HELPERS = None


def vtable_evidence():
    """Symbols whose definition is proven by a vtable slot rather than by an nlist name.

    The kernel collection strips local names, so a function can exist and be called through a vtable
    while the static nlist has no entry for it. The scan records the slot, which is definition evidence.
    """
    global VTABLE_HELPERS
    if VTABLE_HELPERS is None:
        path = ROOT/'research/stock-v243-offscreen-20261021/iogfx-vtable-20261021.json'
        data = json.loads(path.read_text())
        VTABLE_HELPERS = {entry['symbol']: entry['slot'] for entry in data.get('slots', [])}
    return VTABLE_HELPERS


def audit_imports(names, declared, symbolsets, actual_kernel, families, exports):
    groups = {g['CFBundleIdentifier']: g for g in symbolsets['SymbolsSets']}
    if len(groups) != len(symbolsets['SymbolsSets']):
        raise ValueError('duplicate KPI provider')
    rows = []
    for name in sorted(set(names)):
        providers = []
        for bid, required in declared.items():
            g = groups.get(bid)
            if g and compatible(required, g):
                for entry in g['Symbols']:
                    if entry.get('SymbolName') == name:
                        target = entry.get('AliasTarget', name)
                        if target in actual_kernel:
                            providers.append(dict(bundle=bid, target=target,
                                version=g['CFBundleVersion'], required=required,
                                compatible=g.get('OSBundleCompatibleVersion'),
                                evidence='EXACT_KPI_ENTRY_AND_KERNEL_DEFINITION'))
            f = families.get(bid)
            if f and (f['info'] is None or compatible(required, f['info'])) and name in f['definitions']:
                allow = exports.get(bid)
                # An actual KC definition is not by itself an export declaration.
                providers.append(dict(bundle=bid, target=name,
                    version=(f['info'] or {}).get('CFBundleVersion', 'UNVERIFIED'),
                    required=required,
                    compatible=(f['info'].get('OSBundleCompatibleVersion')
                                if f['info'] else 'UNVERIFIED_NO_DISK_INFO_PLIST'),
                    evidence='KC_EXTERNAL_DEFINITION',
                    explicit_export=(name in allow) if allow is not None else 'UNVERIFIED'))
        if not providers:
            local = [bid for bid, f in families.items()
                     if bid in declared and f and (f['info'] is None or compatible(declared[bid], f['info']))
                     and name in f.get('local_definitions', ())]
            if local:
                rows.append(dict(symbol=name, providers=[], local_definitions=local,
                    status='LOCAL_DEFINITION_OBSERVED_EXPORT_UNVERIFIED'))
                continue
        row = dict(symbol=name, providers=providers,
            status='DECLARED_VERSION_AND_DEFINITION' if providers else 'UNRESOLVED')
        if not providers and name in vtable_evidence():
            # A virtual dispatch target does not establish an external linkable symbol.
            row['historical_vtable_observation'] = vtable_evidence()[name]
        rows.append(row)
    return dict(count=len(rows), unresolved=[r['symbol'] for r in rows if not r['providers']
                and r['status'] == 'UNRESOLVED'],
        local_only=[r['symbol'] for r in rows if r['status'] == 'LOCAL_DEFINITION_OBSERVED_EXPORT_UNVERIFIED'],
        vtable_only=[r['symbol'] for r in rows if r['status'] == 'VTABLE_SLOT_OBSERVED_LOCAL_NAME_STRIPPED'],
        rows=rows, level='STATIC_RUNNER_PROVIDER_MATCH_NOT_LOADER_OR_FULL_ABI')


def binary_metadata(path, info):
    raw = path.read_bytes()
    h = kc.header(raw)
    if h['filetype'] != 11:
        raise ValueError('not MH_KEXT_BUNDLE')
    # Validate all file-backed ranges, including zero-fill section exceptions.
    for seg in h['segments']:
        kc.bounded(raw, seg['fileoff'], seg['filesize'])
    for sec in h['sections']:
        if sec['flags'] & 0xff not in (1, 0xc, 0x12):
            kc.bounded(raw, sec['offset'], sec['size'])
    table = h['symtab']
    if not table:
        raise ValueError('missing symbol table')
    kc.bounded(raw, table['symoff'], table['nsyms']*16)
    strings = kc.bounded(raw, table['stroff'], table['strsize'])
    definitions = collections.defaultdict(list)
    imports = set()
    for i in range(table['nsyms']):
        index, typ, sect, desc, value = struct.unpack_from('<IBBHQ', raw, table['symoff']+i*16)
        if index >= len(strings) or strings.find(b'\0', index) < 0:
            raise ValueError('invalid symbol string bounds')
        name = strings[index:strings.find(b'\0', index)].decode('utf-8')
        if typ & 0xe0:
            continue
        if typ & 0x0e == 0x0e:
            if not 1 <= sect <= len(h['sections']):
                raise ValueError('invalid symbol section')
            if typ & 1:
                definitions[name].append((sect, value))
        if typ & 0x0e == 0 and typ & 1:
            if value:
                raise ValueError('unallocated common symbol')
            imports.add(name)
    # _realmain/_antimain are optional null globals explicitly added by NVRM,
    # not the KMOD entry points generated for every companion.
    for name in ('_kmod_info', '__start', '__stop'):
        if len(definitions[name]) != 1:
            raise ValueError('missing or duplicate KMOD definition: '+name)
    ordinal, addr = definitions['_kmod_info'][0]
    sec = h['sections'][ordinal-1]
    if sec['flags'] & 0xff in (1, 0xc, 0x12) or addr < sec['address'] or addr+144 > sec['address']+sec['size']:
        raise ValueError('KMOD outside file-backed section')
    off = sec['offset']+addr-sec['address']
    # kmod_info_64: next(8), info_version(4), id(4), name(64), version(64).
    kmod = kc.bounded(raw, off, 144)
    name = kc.zstring(kmod[16:80]); ver = kc.zstring(kmod[80:144])
    if (name, ver) != (info['CFBundleIdentifier'], info['CFBundleVersion']):
        raise ValueError('KMOD/plist identity mismatch: '+name+' '+ver)
    deployment = []
    for cmd in h['load_commands']:
        off = cmd['offset']; kind = int(cmd['cmd'], 16)
        if kind == 0x32:
            platform, minimum, sdk, ntools = struct.unpack_from('<4I', raw, off+8)
            if cmd['bytes'] != 24+ntools*8 or platform != 1:
                raise ValueError('invalid macOS build version')
            deployment.append((minimum, sdk))
        elif kind == 0x24:
            if cmd['bytes'] != 16:
                raise ValueError('invalid minimum-version command')
            deployment.append(struct.unpack_from('<II', raw, off+8))
    if deployment and deployment != [(0x000f0500, 0x000f0500)]:
        raise ValueError('expected macOS deployment and SDK 15.5: '+str(deployment))
    return dict(sha256=base.digest(path), bytes=len(raw), header=h, kmod_name=name,
        kmod_version=ver, minimum_macos='15.5' if deployment else None,
        sdk='15.5' if deployment else None,
        deployment_command='PRESENT' if deployment else 'ABSENT_NOT_INFERRED', imports=sorted(imports),
        code_signature='NOT_VERIFIED', loader='NOT_RUN', full_abi='UNVERIFIED')


def native_providers(names, logs):
    kernel = Path('/System/Library/Kernels/kernel')
    kernel_sha = base.digest(kernel)
    base.checked_run(['xcrun', 'nm', '-gU', kernel], logs, logs/'kernel-nm.txt')
    actual = base.nm_names(logs/'kernel-nm.txt')
    base.checked_run(['xcrun', 'otool', '-l', kernel], logs, logs/'kernel-otool.txt')
    raw = kernel.read_bytes()
    off, size = section_bounds((logs/'kernel-otool.txt').read_text(), '__LINKINFO', '__symbolsets', len(raw))
    sets = plistlib.loads(raw[off:off+size].rstrip(b'\0'))
    (logs/'symbolsets.plist.txt').write_bytes(plistlib.dumps(sets))
    if base.digest(kernel) != kernel_sha:
        raise ValueError('kernel changed during observation')
    # All family symbols needed by any component, using actual KC definitions.
    family_ids = ('IOPCIFamily', 'IOACPIFamily', 'IOGraphicsFamily', 'IOAcceleratorFamily2', 'IOSurface')
    kc.TARGETS = {'com.apple.iokit.'+n: sorted(names) for n in family_ids}
    observations = [kc.observe_collection(Path('/System/Library/KernelCollections')/n)
        for n in ('BootKernelExtensions.kc', 'SystemKernelExtensions.kc')]
    base.save(logs/'family-kc.json', observations)
    if any(o['observation'] != 'FILESET_PARSED' for o in observations):
        raise ValueError('KC observation failed')
    families, exports = {}, {}
    for short in family_ids:
        bid = 'com.apple.iokit.'+short
        path = Path('/System/Library/Extensions')/(short+'.kext')/'Contents/Info.plist'
        definitions = sorted({r['macho_symbol'] for o in observations for m in o['members']
            if m['bundle_id'] == bid for r in m['symbols']['records']
            if r['status'] == 'KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI'})
        # Local (non-N_EXT) section definitions: the code is present in the family image, but the static
        # export status is unverified. Kept apart from exported definitions so no provider is invented.
        local_definitions = sorted({r['macho_symbol'] for o in observations for m in o['members']
            if m['bundle_id'] == bid for r in m['symbols']['records']
            if r['status'] == 'NOT_A_PUBLIC_SECTION_DEFINITION' and (r['n_type'] & 0x0e) == 0x0e})
        if path.is_file():
            info = plistlib.loads(path.read_bytes())
            if info['CFBundleIdentifier'] != bid:
                raise ValueError('family identity differs')
            families[bid] = dict(info=info, definitions=definitions, local_definitions=local_definitions,
                plist_sha256=base.digest(path), identity_source='DISK_INFO_PLIST')
            (logs/(short+'.plist.txt')).write_bytes(plistlib.dumps(info))
        else:
            # macOS 15 ships these families inside the kernel collections; there is no kext directory to
            # read. Identity comes from the collection's fileset entry id, and version compatibility is
            # recorded as unverified instead of being invented.
            families[bid] = dict(info=None, definitions=definitions, local_definitions=local_definitions,
                plist_sha256=None, identity_source='KC_FILESET_ENTRY_ID_DISK_PLIST_ABSENT')
            (logs/(short+'.plist.txt')).write_text('INFO_PLIST_ABSENT_OBSERVED_IN_KERNEL_COLLECTION\\n')
        families[bid]['present_in_collection'] = any(m['bundle_id'] == bid
            for observation in observations for m in observation['members'])
        if short in ('IOPCIFamily', 'IOACPIFamily'):
            rel = 'config/' if short == 'IOPCIFamily' else ''
            text = (path.parent/'Resources'/rel/(short+'.exports')).read_text()
            (logs/(short+'.exports.txt')).write_text(text)
            exports[bid] = {s.strip() for s in text.splitlines() if s.strip().startswith('_')}
    base.save(logs/'provider-binding.json', dict(kernel_sha256=kernel_sha,
        symbolsets_sha256=hashlib.sha256(raw[off:off+size]).hexdigest(),
        families={k:dict(plist_sha256=v['plist_sha256'], identity_source=v['identity_source'],
                         defined_count=len(v['definitions'])) for k,v in families.items()}))
    return sets, actual, families, exports


def _add_missing_dependency(bundle):
    info_path = bundle/'Contents/Info.plist'
    info = plistlib.loads(info_path.read_bytes())
    info.setdefault('OSBundleLibraries', {})['com.example.g1-missing'] = '9.9.9'
    info_path.write_bytes(plistlib.dumps(info))


def bundle_identity(bundle):
    """Bind a diagnostic to both exact bundle inputs; never search installed names."""
    bundle = Path(bundle).resolve()
    info_path = bundle/'Contents/Info.plist'
    info = plistlib.loads(info_path.read_bytes())
    name = info['CFBundleExecutable']
    if not isinstance(name, str) or Path(name).name != name or name in ('', '.', '..'):
        raise ValueError('unsafe bundle executable')
    executable = bundle/'Contents/MacOS'/name
    return dict(bundle=str(bundle), executable=str(executable),
        bundle_sha256=base.digest(executable), plist_sha256=base.digest(info_path),
        bundle_id=info['CFBundleIdentifier'])


def accept_loader_diagnostics(loaders, expected):
    """Reject diagnostic failures, without promoting exit 0 into loader acceptance."""
    if set(loaders) != set(SPECS) or set(expected) != set(SPECS):
        raise ValueError('kextutil diagnostic inventory differs')
    for name, record in loaders.items():
        if type(record.get('exit')) is not int or record['exit'] != 0 or record.get('unresolved') != []:
            raise ValueError('kextutil diagnostic failed: '+name)
        for key in ('bundle', 'executable', 'bundle_sha256', 'plist_sha256', 'bundle_id'):
            if not record.get(key) or record[key] != expected[name].get(key):
                raise ValueError('kextutil candidate identity differs: '+name+' '+key)
    return dict(status='DIAGNOSTICS_ONLY_NO_LOADER_ACCEPTANCE',
        exclusive_candidate_dependency_binding='UNVERIFIED',
        authentication='NOT_TESTED_BY_KEXTUTIL_N', loader_acceptance='UNVERIFIED')


def loader_diagnostics(products, out, records=None, runner=None, bindings=None):
    """Same production path for real native calls and subprocess fault injection."""
    runner = runner or base.run
    expected = {name:bundle_identity(products/(name+'.kext')) for name in SPECS}
    if bindings is not None:
        if set(bindings) != set(SPECS):
            raise ValueError('compiled bundle inventory differs')
        for name, identity in expected.items():
            if identity['bundle_sha256'] != bindings[name]['sha256'] or identity['plist_sha256'] != bindings[name]['plist_sha256']:
                raise ValueError('diagnostic target differs from compiled bundle: '+name)
    records = {} if records is None else records
    for name, identity in expected.items():
        log = out/(name+'-kextutil.txt')
        rc = runner(['xcrun', 'kextutil', '-n', identity['bundle']], products, log)
        text = log.read_text(encoding='utf-8', errors='replace')
        unresolved = sorted({line.strip() for line in text.splitlines() if re.search(
            r"can't\s+resolve|cannot\s+resolve|unresolved|undefined\s+symbol", line, re.I)})
        records[name] = dict(exit=rc, unresolved=unresolved, log=log.name, **identity)
        after = bundle_identity(identity['bundle'])
        if after != identity:
            raise ValueError('candidate changed during kextutil diagnostic: '+name)
    verdict = accept_loader_diagnostics(records, expected)
    return records, verdict


def static_status(report):
    # Capability probes never establish authentication, dependency binding or ABI.
    return (PASS_LOCAL_ONLY if report.get('local_only_imports') else PASS) + '_KEXTUTIL_INFORMATIONAL_ONLY'


def accepted_status(status):
    return status in (PASS+'_KEXTUTIL_INFORMATIONAL_ONLY', PASS_LOCAL_ONLY+'_KEXTUTIL_INFORMATIONAL_ONLY')


def run(args, report):
    previous = json.loads((args.internal_text/'report.json').read_text())
    if previous['status'] != INTERNAL_PASS:
        raise ValueError('same-run internal link did not pass')
    tree = args.work/'nm-candidate'
    original = args.work/'NVRM-internal-integration'
    if base.digest(original) != previous['integrated_link']['sha256']:
        raise ValueError('integrated binary changed')
    for row in previous['tu_objects']:
        if base.digest(tree/row['source']) != row['source_sha256']:
            raise ValueError('candidate source changed')
    for entry in json.loads((args.internal_text/'candidate-input-snapshots.json').read_text()).items():
        if base.digest(tree/entry[0]) != entry[1]:
            raise ValueError('candidate dependency changed')
    # A first hypothesis removed seven IOAccel virtuals as "macOS 26 only". The kernel-collection
    # reverse engineering disproved it: slots 322-325 of IOAccelSurface carry set_shape,
    # set_shape_backing_length_ext, surface_lock_options and surface_unlock_options in this exact order,
    # The declarations stay. Local slot evidence must not substitute for an external provider.
    # The vtable observation kept the layout and moved the fix to the type declarations: the IOFamily
    # enum types were typedefs to unsigned int, so the base-class imports mangled as 'j' while the real
    # symbols carry the enum names. Apply that narrow patch and verify it against its lock.
    overlay = ROOT/'research/stock-v243-offscreen-20261021/iofam-enum-types.patch'
    overlay_lock = json.loads((ROOT/'research/stock-v243-offscreen-20261021/iofam-lock.json').read_text())
    if base.digest(overlay) != overlay_lock['sha256']:
        raise ValueError('io_fam type patch differs from its lock')
    for argv, name in ((['git','apply','--check','--unsafe-paths',overlay], 'iofam-types-check.txt'),
                       (['git','apply','--unsafe-paths',overlay], 'iofam-types-apply.txt')):
        if patch_run([str(v) for v in argv], tree, args.out/name):
            raise ValueError('io_fam type patch failed: ' + name)
    report['iofam_overlay'] = dict(applied=True, sha256=overlay_lock['sha256'],
        scope=overlay_lock['scope'], reason=overlay_lock['reason'],
        vtable_evidence='research/stock-v243-offscreen-20261021/iogfx-vtable-20261021.json')
    products = args.work/'package-products'; products.mkdir(exist_ok=False)
    # Reuse the exact accepted NVRM compile flags, changing only local include paths
    # and language macros as in the fixed stock accelerator recipe (not executing it).
    line = (args.internal_text/'tu-NVRM.cpp.txt').read_text().splitlines()[0]
    flags = json.loads(line.removeprefix('ARGV='))
    flags = flags[:flags.index('-MD')]
    flags = [v for v in flags if v not in ('-DNVRM', '-D_LANGUAGE_C')]
    report['stage'] = 'companion-objects'
    built = {'NVRM': original}
    for name in ('NVRMFB', 'NVAccel'):
        rel = SPECS[name][1]; obj = products/(name+'.o')
        include = [tree/'kexts/NVRM', tree/'kexts/NVRMFB', tree/'kexts/NVRM/accel',
                   tree/'kexts/NVRM/accel/iofam', tree/'kexts/NVRM/accel/re']
        argv = [*flags, *['-I'+str(p) for p in include]]
        pre, post = args.out/(name+'-pre.d'), args.out/(name+'-post.d')
        base.checked_run([*argv, '-M', '-MT', 'bound', '-MF', pre, tree/rel], tree, args.out/(name+'-deps.txt'))
        before = base.dependencies(pre, tree)
        record = base.compile_checked([*argv, '-MD', '-MT', 'bound', '-MF', post, '-c', tree/rel, '-o', obj],
            tree, obj, args.out/(name+'-compile.txt'))
        if before != base.dependencies(post, tree):
            raise ValueError('companion transitive input changed')
        report.setdefault('compiled', {})[name] = dict(source=rel, source_sha256=base.digest(tree/rel),
            dependencies=before, **record)
        binary = products/name
        link = ['xcrun', 'clang++', '-arch', 'x86_64', '-mmacosx-version-min=15.5',
            '-isysroot', previous['toolchain']['sdk'], '-fapple-kext', '-nostdlib',
            '-Xlinker', '-kext', '-lkmodc++', '-lkmod', '-lcc_kext', obj, '-o', binary]
        report.setdefault('links', {})[name]=base.link_checked(link, tree, binary, args.out/(name+'-ld.txt'))
        built[name] = binary
    report['stage'] = 'bundle-format'
    report['bundles'] = {}
    for name, binary in built.items():
        info_raw = (tree/SPECS[name][0]).read_bytes(); info = plistlib.loads(info_raw)
        if info['CFBundleExecutable'] != name or info['CFBundlePackageType'] != 'KEXT':
            raise ValueError('bundle executable or type differs')
        bundle = products/(name+'.kext')/'Contents'
        (bundle/'MacOS').mkdir(parents=True, exist_ok=False)
        shutil.copyfile(binary, bundle/'MacOS'/name)
        (bundle/'Info.plist').write_bytes(info_raw)
        base.checked_run(['xcrun', 'otool', '-l', bundle/'MacOS'/name], tree, args.out/(name+'-otool.txt'))
        base.checked_run(['xcrun', 'nm', '-am', bundle/'MacOS'/name], tree, args.out/(name+'-nm.txt'))
        metadata = binary_metadata(bundle/'MacOS'/name, info)
        if metadata['sha256'] != base.digest(binary):
            raise ValueError('bundle copy differs')
        base.checked_run(['/usr/bin/plutil', '-lint', bundle/'Info.plist'], tree, args.out/(name+'-plutil.txt'))
        (args.out/(name+'-Info.plist.txt')).write_bytes(info_raw)
        report['bundles'][name] = dict(info=info, plist_sha256=base.digest(bundle/'Info.plist'), **metadata)
    report['compiler_target']='15.5_FROM_EXPLICIT_SAME_RUN_ARGUMENTS_NOT_INFERRED_BINARY_MINIMUM'
    # kextutil -n is an informational diagnostic. Observed exit 0 on malformed bundles
    # means it cannot certify loader resolution, authentication, or exclusive dependency binding.
    report['stage'] = 'loader-diagnostics'
    report['loader_dry_run'] = {}
    _, report['loader_diagnostic_acceptance'] = loader_diagnostics(
        products, args.out, report['loader_dry_run'], bindings=report['bundles'])

    # Capability probe, not a negative control: kextutil -n turned out to accept both a bundle whose
    # executable is missing and one that declares a dependency which does not exist. It therefore cannot
    # validate a bundle; it can only report the diagnostics it happens to emit. Record the observation and
    # fail only when it reports unresolved symbols for the real bundles.
    report['stage'] = 'kextutil-capability-probe'
    probe = {}
    for case, mutate in (
            ('missing executable', lambda bundle: (bundle/'Contents'/'MacOS'/'NVAccel').unlink()),
            ('missing declared dependency', lambda bundle: _add_missing_dependency(bundle))):
        bundle = products/('NVAccel-probe-%d.kext' % len(probe))
        shutil.copytree(products/'NVAccel.kext', bundle)
        mutate(bundle)
        log = args.out/('kextutil-probe-%d.txt' % len(probe))
        with log.open('w', encoding='utf-8') as stream:
            stream.write('ARGV='+repr(['xcrun', 'kextutil', '-n', str(bundle)])+'\n'); stream.flush()
            result = subprocess.run(['xcrun', 'kextutil', '-n', str(bundle)], cwd=tree,
                                    stdout=stream, stderr=subprocess.STDOUT, timeout=300)
            stream.write('\nEXIT='+str(result.returncode)+'\n')
        probe[case] = dict(exit=result.returncode, accepted=result.returncode == 0, log=log.name)
    report['kextutil_capability_probe'] = probe
    report['kextutil_is_a_validation_gate'] = False
    try:
        bundle_identity(products/'NVAccel-probe-0.kext')
    except FileNotFoundError:
        report['missing_executable_control'] = dict(rejected=True,
            checker='PRODUCTION_BUNDLE_IDENTITY_CHECK_NOT_KEXTUTIL')
    else:
        raise ValueError('missing-executable control was accepted by identity checker')
    for name, record in report['loader_dry_run'].items():
        if record['unresolved']:
            raise ValueError('kextutil -n reported unresolved symbols for %s: %r'
                             % (name, record['unresolved'][:3]))

    report['stage'] = 'runner-dependencies'
    all_names = {n for b in report['bundles'].values() for n in b['imports']}
    sets, actual, families, exports = native_providers(all_names, args.out)
    report['declared_dependencies'] = {name:declared_dependencies(
        bundle['info']['OSBundleLibraries'], sets, families) for name,bundle in report['bundles'].items()}
    report['dependency_versions'] = ('PARTIALLY_UNVERIFIED' if any(r['unverified']
        for r in report['declared_dependencies'].values()) else 'RUNNER_METADATA_MATCHED_NOT_USER_SYSTEM')
    if any(r['rejected'] for r in report['declared_dependencies'].values()):
        raise ValueError('declared dependency absent or version incompatible; see report')
    # This is a negative control of our production checker, irrespective of kextutil's limitations.
    missing_info = plistlib.loads((products/'NVAccel-probe-1.kext/Contents/Info.plist').read_bytes())
    observed = declared_dependencies(missing_info['OSBundleLibraries'], sets, families)
    absent = [r for r in observed['rejected'] if r['bundle'] == 'com.example.g1-missing']
    if len(absent) != 1 or absent[0]['status'] != 'DEPENDENCY_ABSENT':
        raise ValueError('missing-dependency control did not identify the injected dependency')
    try:
        accept_declared_dependencies(missing_info['OSBundleLibraries'], sets, families)
    except ValueError:
        report['missing_dependency_control'] = dict(rejected=True, injected=absent[0],
            checker='PRODUCTION_DECLARED_DEPENDENCY_CHECK_NOT_KEXTUTIL')
    else:
        raise ValueError('missing-dependency control was accepted')
    for name, bundle in report['bundles'].items():
        audit = audit_imports(bundle['imports'], bundle['info']['OSBundleLibraries'], sets, actual, families, exports)
        bundle['providers'] = audit
        base.save(args.out/(name+'-providers.json'), audit)
    report['unresolved'] = {name:b['providers']['unresolved'] for name,b in report['bundles'].items() if b['providers']['unresolved']}
    report['local_only_imports'] = {name:b['providers']['local_only'] for name,b in report['bundles'].items()
                                    if b['providers'].get('local_only')}
    if report['unresolved']:
        raise ValueError('declared provider/version/definition unresolved; see per-bundle provider reports')
    if report['local_only_imports']:
        print('STATIC_LOCAL_ONLY_IMPORTS ' + ','.join(
            '%s=%d' % (k, len(v)) for k, v in sorted(report['local_only_imports'].items())), flush=True)
    # Bind before/after hashes and exact consumed compilation dependencies.
    for record in report.get('compiled', {}).values():
        if any(base.digest(p) != sha for p,sha in record['dependencies'].items()):
            raise ValueError('companion dependency changed after link')
    if base.digest(original) != previous['integrated_link']['sha256']:
        raise ValueError('integrated binary changed after inspection')
    final_status = static_status(report)
    report.update(status=final_status, stage='complete', internal_binary_sha256=base.digest(original),
        user_system='UNVERIFIED', full_abi='UNVERIFIED', gpu='NOT_RUN', kext_load='NO_GO',
        milestone='PRE_DEVICE_STATIC_INTEGRATION_CONDITIONAL_PASS',
        loader_resolution='UNVERIFIED', exports_acceptance='UNVERIFIED',
        exclusive_candidate_dependency_binding='UNVERIFIED',
        metal_plugin='NOT_BUILT_OR_EXECUTED', gsp='NOT_EXECUTED', signing='NOT_RUN')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for key in ('work', 'internal-text', 'out'):
        parser.add_argument('--'+key, required=True, type=Path)
    args = parser.parse_args(); args.out.mkdir(parents=True, exist_ok=False)
    report = dict(status='FAILED', stage='preflight', run_id=__import__('os').environ.get('GITHUB_RUN_ID'),
        commit=__import__('os').environ.get('GITHUB_SHA'), kext_load='NO_GO', gpu='NOT_RUN')
    try:
        run(args, report)
    except Exception as error:
        report['error'] = str(error)
        print('::error::PACKAGE_STATIC_FAILED '+report['stage']+' :: '+str(error)[:300])
    finally:
        base.save(args.out/'package-report.json', report)
    print(report['status'], report['stage'], report.get('error',''))
    return 0 if accepted_status(report['status']) else 2


if __name__ == '__main__':
    raise SystemExit(main())
