#!/usr/bin/env python3
"""Recompute runner KPI name/alias evidence offline, without accepting ABI/load."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import plistlib
import re

from g1_target_providers import (IMPORTS_SHA256, load_imports, match_records,
    parse_allowlist, parse_globals, section_bounds, sha, write)

PLIST_SHA256 = '934914c01b15ad266fa4ff2f62e03671e2bc6849660564710bbebfc429ac91b6'
SYMBOL = re.compile(r'_[A-Za-z0-9_.$]+\Z')


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def read_nm_log(text, expected_argv, expected_stdout_hash):
    first, rest = text.split('\n', 1)
    if not first.startswith('ARGV=') or json.loads(first[5:]) != expected_argv:
        raise ValueError('raw nm argv mismatch')
    stdout, trailer = rest.rsplit('\nEXIT=', 1)
    if trailer != '0\n' or sha(stdout.encode('utf-8')) != expected_stdout_hash:
        raise ValueError('raw nm exit or stdout hash mismatch')
    return parse_globals(stdout)


def symbolset_entries(value, names, globals_, declared):
    if not isinstance(value, dict) or not isinstance(value.get('SymbolsSets'), list):
        raise ValueError('unrecognised symbolset top-level schema')
    result = {name: [] for name in names}
    prefixes = []
    identifiers = set()
    for group in value['SymbolsSets']:
        provider = group['CFBundleIdentifier']
        if provider in identifiers:
            raise ValueError('duplicate symbolset provider')
        identifiers.add(provider)
        if not isinstance(group.get('Symbols'), list):
            raise ValueError('symbolset entries must be a list')
        seen = set()
        for entry in group['Symbols']:
            if set(entry) == {'SymbolPrefix'}:
                # Prefix metadata is not silently expanded into exact entries.
                prefix = entry['SymbolPrefix']
                if not isinstance(prefix, str) or not SYMBOL.fullmatch(prefix):
                    raise ValueError('invalid symbol prefix metadata')
                prefixes.append({'provider': provider, 'prefix': prefix,
                    'matching_imports': [n for n in names if n.startswith(prefix)],
                    'level': 'PREFIX_METADATA_ONLY_NOT_EXACT_ENTRY'})
                continue
            if set(entry) not in ({'SymbolName'}, {'SymbolName', 'AliasTarget'}):
                raise ValueError('unknown symbolset entry syntax')
            name = entry['SymbolName']
            target = entry.get('AliasTarget', name)
            if not all(isinstance(n, str) and n and not any(c in n for c in '\0\n\r') for n in (name, target)):
                raise ValueError('invalid symbolset name carrier')
            if not all(SYMBOL.fullmatch(n) for n in (name, target)):
                # The real 24G830 iokit set contains resourcesEv + a trailing
                # space. Preserve literal identity; never strip it into a hit.
                prefixes.append({'provider': provider, 'raw_entry': entry,
                    'level': 'OPAQUE_NAME_METADATA_NOT_NORMALIZED'})
            if name in seen:
                raise ValueError('duplicate symbol in provider set')
            seen.add(name)
            if name in result:
                result[name].append({'provider': provider,
                    'provider_version': group['CFBundleVersion'],
                    'provider_compatible_version': group['OSBundleCompatibleVersion'],
                    'source_declares_library_id': provider in declared,
                    'source_required_version': declared.get(provider),
                    'selector': 'EXACT_SYMBOL_NAME', 'symbol': name,
                    'alias_target': entry.get('AliasTarget'), 'target_global': target,
                    'target_global_kind': globals_.get(target),
                    'target_global_observed': target in globals_})
    return result, prefixes


def verify_publication(root):
    manifest = read_json(root/'diagnostic-publication.json')
    required = {'report.json', 'runner-kernel-nm-raw.txt', 'kernel-symbolsets-binding.json',
        'kernel-symbolsets-decoded.txt', 'kernel-load-commands.json',
        'IOPCIFamily-kext-allowlist-raw.txt', 'IOACPIFamily-kext-allowlist-raw.txt'}
    seen, unavailable, verified = set(), [], []
    for entry in manifest['included']:
        rel = Path(entry['path'])
        if rel.is_absolute() or '..' in rel.parts or entry['path'] in seen:
            raise ValueError('unsafe publication path')
        seen.add(entry['path'])
        if not (root/rel).is_file() and entry['path'] not in required:
            unavailable.append(entry['path'])
            continue
        data = (root/rel).read_bytes()
        if len(data) != entry['bytes'] or sha(data) != entry['sha256']:
            raise ValueError('publication content mismatch: '+entry['path'])
        verified.append(entry['path'])
    if required-seen:
        raise ValueError('required evidence missing from original publication manifest')
    return {'verified': verified, 'unavailable_unconsumed_members': unavailable,
        'level': 'CONSUMED_FILES_VERIFIED_NOT_CLAIMING_COMPLETE_ARTIFACT_COPY'}


def verify_expected_identity(root, *, expected_run_id, expected_source_commit,
                             expected_artifact_id, expected_artifact_sha256):
    """Compare caller-supplied trusted identity with the download attestation.

    The downloader verifies the ZIP digest before extracting. This offline
    check binds consumed files to that attestation; it does not rehash a ZIP
    which is absent here or independently authenticate a forged attestation.
    """
    if (type(expected_run_id) is not int or expected_run_id <= 0 or
            type(expected_artifact_id) is not int or expected_artifact_id <= 0 or
            not re.fullmatch('[0-9a-f]{40}', expected_source_commit) or
            not re.fullmatch('[0-9a-f]{64}', expected_artifact_sha256)):
        raise ValueError('invalid externally expected evidence identity')
    binding = read_json(root/'local-artifact-binding.json')
    for key, value in [('run_id', expected_run_id), ('artifact_id', expected_artifact_id),
                       ('artifact_sha256', expected_artifact_sha256)]:
        if type(binding.get(key)) is not type(value) or binding[key] != value:
            raise ValueError('external artifact identity mismatch: '+key)
    seen, verified = set(), []
    for entry in binding['members']:
        rel = Path(entry['path'])
        if (rel.is_absolute() or '..' in rel.parts or ':' in entry['path'] or
                '\\' in entry['path'] or entry['path'] in seen):
            raise ValueError('unsafe artifact member identity')
        seen.add(entry['path'])
        path = root/rel
        if path.is_file():
            raw = path.read_bytes()
            if len(raw) != entry['bytes'] or sha(raw) != entry['sha256']:
                raise ValueError('downloaded artifact member mismatch: '+entry['path'])
            verified.append(entry['path'])
    # The manifest subsequently binds every consumed observation; both it and
    # the report must themselves be attested members of the downloaded ZIP.
    if not {'report.json', 'diagnostic-publication.json'} <= set(verified):
        raise ValueError('report or publication manifest absent from artifact binding')
    report = read_json(root/'report.json')
    if report.get('source_commit') != expected_source_commit:
        raise ValueError('external source commit mismatch')
    # Historical reports predate source_run_id. Their run is attested by the
    # verified downloader; new reports additionally carry the runner's run ID.
    if 'source_run_id' in report and str(report['source_run_id']) != str(expected_run_id):
        raise ValueError('native source run ID mismatch')
    return {'run_id': expected_run_id, 'source_commit': expected_source_commit,
        'artifact_id': expected_artifact_id, 'artifact_sha256': expected_artifact_sha256,
        'verified_members': verified,
        'level': 'EXTERNAL_EXPECTATIONS_MATCH_VERIFIED_DOWNLOADER_ATTESTATION_NOT_ZIP_REHASH'}


def analyse(root, imports, info_path, *, expected_run_id, expected_source_commit,
            expected_artifact_id, expected_artifact_sha256):
    external_identity = verify_expected_identity(root,
        expected_run_id=expected_run_id, expected_source_commit=expected_source_commit,
        expected_artifact_id=expected_artifact_id, expected_artifact_sha256=expected_artifact_sha256)
    publication = verify_publication(root)
    report = read_json(root/'report.json')
    names = load_imports(imports)
    if report['frozen_candidate']['imports_sha256'] != IMPORTS_SHA256:
        raise ValueError('native frozen inventory identity mismatch')
    if report['records'] != match_records(names, report['providers']):
        raise ValueError('native record inventory or matches not reproducible')
    if report['counts'] != dict(Counter(r['status'] for r in report['records'])):
        raise ValueError('native count mismatch')
    info_bytes = info_path.read_bytes()
    if sha(info_bytes) != PLIST_SHA256:
        raise ValueError('fixed public NVRM Info.plist source hash mismatch')
    declared = plistlib.loads(info_bytes)['OSBundleLibraries']
    kernel = next(p for p in report['providers'] if p['id'] == 'runner-kernel')
    if kernel['observation'] != 'PARSED' or kernel['exit'] != 0:
        raise ValueError('kernel global observation failed')
    globals_ = read_nm_log((root/'runner-kernel-nm-raw.txt').read_text(encoding='utf-8'),
        kernel['argv'], kernel['stdout_sha256'])
    if len(globals_) != kernel['global_symbol_count'] or kernel['matches'] != {n: globals_[n] for n in names if n in globals_}:
        raise ValueError('kernel global report not reproducible')
    binding = read_json(root/'kernel-symbolsets-binding.json')
    xml = (root/'kernel-symbolsets-decoded.txt').read_bytes()
    if binding['observation'] != 'PLIST_DECODED' or sha(xml) != binding['decoded_xml_sha256'] or binding['kernel_sha256'] != kernel['sha256']:
        raise ValueError('kernel symbolset binding mismatch')
    otool = read_json(root/'kernel-load-commands.json')
    if otool['exit'] != 0 or otool['argv'] != ['xcrun', 'otool', '-l', kernel['path']]:
        raise ValueError('kernel section command identity mismatch')
    if section_bounds(otool['stdout'], '__LINKINFO', '__symbolsets', kernel['bytes']) != (binding['offset'], binding['bytes']):
        raise ValueError('kernel section boundary mismatch')
    entries, prefixes = symbolset_entries(plistlib.loads(xml), names, globals_, declared)
    allowlists = {}
    for p in report['providers']:
        if p['id'].endswith('-allowlist'):
            raw = (root/(p['id']+'-raw.txt')).read_bytes()
            if p['observation'] != 'PARSED' or sha(raw) != p['sha256']:
                raise ValueError('family allowlist binding failed')
            expected = {n: 'ALLOWLIST_ENTRY' for n in names if n in parse_allowlist(raw.decode('utf-8'))}
            if expected != p['matches']:
                raise ValueError('family allowlist report mismatch')
            allowlists[p['id']] = p
    rows = []
    for native in report['records']:
        name = native['macho_symbol']
        accepted_names = [e for e in entries[name] if e['source_declares_library_id'] and e['target_global_observed']]
        family = [o for o in native['observations'] if o['kind'] == 'ALLOWLIST_ENTRY']
        rows.append({'macho_symbol': name, 'source_spelling': native['source_spelling'],
            'kernel_symbolsets': entries[name], 'family_allowlists': family,
            'name_evidence': ('RUNNER_KPI_EXACT_ENTRY_AND_TARGET_GLOBAL' if accepted_names else
                'FAMILY_ALLOWLIST_ONLY_BINARY_UNVERIFIED' if family else 'UNRESOLVED'),
            'abi': 'NOT_VERIFIED', 'user_target_system': 'NOT_VERIFIED'})
    counts = dict(Counter(r['name_evidence'] for r in rows))
    aliases = [dict(macho_symbol=r['macho_symbol'], **e) for r in rows
               for e in r['kernel_symbolsets'] if e['alias_target'] and e['source_declares_library_id']]
    return {'schema': 'honor.g1.runner-provider-evidence.v1',
        'level': 'OFFLINE_RECOMPUTATION_OF_NATIVE_TEXT_NOT_DRIVER_EXECUTION',
        'environment': report['environment'], 'native_source_commit': report['source_commit'],
        'publication_verification': publication, 'external_identity_verification': external_identity,
        'frozen_candidate': report['frozen_candidate'], 'counts': counts,
        'fixed_source_plist': {'nullmoth_pin': 'ac55984c473e746c2a8ebea7ba0913461aa7c393',
            'path': 'kexts/NVRM/Info.plist', 'sha256': PLIST_SHA256,
            'git_blob_sha1': hashlib.sha1(b'blob '+str(len(info_bytes)).encode()+b'\0'+info_bytes).hexdigest(),
            'OSBundleLibraries': declared, 'level': 'PUBLIC_SOURCE_DECLARATION_NOT_PACKAGED_BUNDLE_ACCEPTANCE'},
        'kernel_binding': binding, 'kernel_global_count': len(globals_),
        'aliases': aliases, 'non_exact_metadata': prefixes, 'records': rows,
        'version_compatibility': 'RECORDED_NOT_EVALUATED', 'full_abi': 'NOT_VERIFIED',
        'target_export_abi_acceptance': 'NOT_VERIFIED', 'kext_load': 'NO-GO', 'gpu_execution': False}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--native-text', type=Path, required=True)
    p.add_argument('--imports', type=Path, required=True)
    p.add_argument('--source-info-plist', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--expected-run-id', type=int, required=True)
    p.add_argument('--expected-source-commit', required=True)
    p.add_argument('--expected-artifact-id', type=int, required=True)
    p.add_argument('--expected-artifact-sha256', required=True)
    args = p.parse_args()
    result = analyse(args.native_text, args.imports, args.source_info_plist,
        expected_run_id=args.expected_run_id, expected_source_commit=args.expected_source_commit,
        expected_artifact_id=args.expected_artifact_id, expected_artifact_sha256=args.expected_artifact_sha256)
    write(args.out, result)
    print(json.dumps({'counts': result['counts'], 'aliases': len(result['aliases']),
        'kernel_globals': result['kernel_global_count'], 'target_export_abi_acceptance': result['target_export_abi_acceptance']}))


if __name__ == '__main__':
    main()
