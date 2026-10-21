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
import struct
import sys

import stock_v243_kext_link as base
from stock_v243_internal_link import PASS as INTERNAL_PASS

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
import g1_kc8 as kc
from g1_target_providers import section_bounds

PASS = 'PASS_STATIC_KERNEL_BUNDLES_NOT_LOADER_ABI_OR_GPU_ACCEPTANCE'
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
            if f and compatible(required, f['info']) and name in f['definitions']:
                allow = exports.get(bid)
                # An actual KC definition is not by itself an export declaration.
                providers.append(dict(bundle=bid, target=name,
                    version=f['info']['CFBundleVersion'], required=required,
                    compatible=f['info'].get('OSBundleCompatibleVersion'),
                    evidence='KC_EXTERNAL_DEFINITION',
                    explicit_export=(name in allow) if allow is not None else 'UNVERIFIED'))
        rows.append(dict(symbol=name, providers=providers,
            status='DECLARED_VERSION_AND_DEFINITION' if providers else 'UNRESOLVED'))
    return dict(count=len(rows), unresolved=[r['symbol'] for r in rows if not r['providers']],
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
    for name in ('_kmod_info', '__realmain', '__antimain'):
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
    if deployment != [(0x000f0500, 0x000f0500)]:
        raise ValueError('expected macOS deployment and SDK 15.5: '+str(deployment))
    return dict(sha256=base.digest(path), bytes=len(raw), header=h, kmod_name=name,
        kmod_version=ver, minimum_macos='15.5', sdk='15.5', imports=sorted(imports),
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
        info = plistlib.loads(path.read_bytes())
        if info['CFBundleIdentifier'] != bid:
            raise ValueError('family identity differs')
        definitions = sorted({r['macho_symbol'] for o in observations for m in o['members']
            if m['bundle_id'] == bid for r in m['symbols']['records']
            if r['status'] == 'KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI'})
        families[bid] = dict(info=info, definitions=definitions, plist_sha256=base.digest(path))
        (logs/(short+'.plist.txt')).write_bytes(plistlib.dumps(info))
        if short in ('IOPCIFamily', 'IOACPIFamily'):
            rel = 'config/' if short == 'IOPCIFamily' else ''
            text = (path.parent/'Resources'/rel/(short+'.exports')).read_text()
            (logs/(short+'.exports.txt')).write_text(text)
            exports[bid] = {s.strip() for s in text.splitlines() if s.strip().startswith('_')}
    base.save(logs/'provider-binding.json', dict(kernel_sha256=kernel_sha,
        symbolsets_sha256=hashlib.sha256(raw[off:off+size]).hexdigest(),
        families={k:dict(plist_sha256=v['plist_sha256'], defined_count=len(v['definitions'])) for k,v in families.items()}))
    return sets, actual, families, exports


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
        base.link_checked(link, tree, binary, args.out/(name+'-ld.txt'))
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
        metadata = binary_metadata(bundle/'MacOS'/name, info)
        if metadata['sha256'] != base.digest(binary):
            raise ValueError('bundle copy differs')
        base.checked_run(['/usr/bin/plutil', '-lint', bundle/'Info.plist'], tree, args.out/(name+'-plutil.txt'))
        base.checked_run(['xcrun', 'otool', '-l', bundle/'MacOS'/name], tree, args.out/(name+'-otool.txt'))
        (args.out/(name+'-Info.plist.txt')).write_bytes(info_raw)
        report['bundles'][name] = dict(info=info, plist_sha256=base.digest(bundle/'Info.plist'), **metadata)
    report['stage'] = 'runner-dependencies'
    all_names = {n for b in report['bundles'].values() for n in b['imports']}
    sets, actual, families, exports = native_providers(all_names, args.out)
    for name, bundle in report['bundles'].items():
        audit = audit_imports(bundle['imports'], bundle['info']['OSBundleLibraries'], sets, actual, families, exports)
        bundle['providers'] = audit
        base.save(args.out/(name+'-providers.json'), audit)
    report['unresolved'] = {name:b['providers']['unresolved'] for name,b in report['bundles'].items() if b['providers']['unresolved']}
    if report['unresolved']:
        raise ValueError('declared provider/version/definition unresolved; see per-bundle provider reports')
    # Bind before/after hashes and exact consumed compilation dependencies.
    for record in report.get('compiled', {}).values():
        if any(base.digest(p) != sha for p,sha in record['dependencies'].items()):
            raise ValueError('companion dependency changed after link')
    if base.digest(original) != previous['integrated_link']['sha256']:
        raise ValueError('integrated binary changed after inspection')
    report.update(status=PASS, stage='complete', internal_binary_sha256=base.digest(original),
        user_system='UNVERIFIED', full_abi='UNVERIFIED', gpu='NOT_RUN', kext_load='NO_GO',
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
    return 0 if report['status'] == PASS else 2


if __name__ == '__main__':
    raise SystemExit(main())
