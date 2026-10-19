#!/usr/bin/env python3
"""Reparse preserved native IR; optionally re-read the exact release binary.

Default is text evidence only, with no compiler, network or device access.
--binary accepts a local forensic copy and compares every observed relocation.
The driver is never executed and its bytes are never published by this script.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from g1_full_abi import split_parameters
from macho_xref import observe


def require(value, message):
    if not value:
        raise ValueError(message)


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary', type=Path)
    args = parser.parse_args()
    release = read(HERE / 'release-relocations.json')
    selected = read(HERE / 'candidate-ir-selection.json')
    callers = HERE.parent / 'pci-caller-evidence'
    receipt = read(callers / 'local-artifact-binding.json')
    raw = (callers / 'uni-NVRM_cpp.ll').read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    require(selected['run_id'] == receipt['run_id'] == 39140902850, 'wrong run')
    require(selected['source_head'] == '9015c246bdfd119c5f13a64b34c170533694ea92', 'wrong source')
    member = next(m for m in receipt['members'] if m['path'] == 'uni-NVRM_cpp.ll')
    require(digest == selected['original_ir_sha256'] == member['sha256'] ==
            'de4904a8e0118229c5af5bbcb76b502b87f567a312d795d2543e909578136396', 'IR digest mismatch')
    require(len(raw) == member['bytes'], 'IR size mismatch')
    ir = raw.decode('utf-8')
    require(len(selected['vtables']) == 2, 'expected two selected vtables')
    expected = {'_ZTV14NVRMUserClient', '_ZTV17IOAccelNVRMBridge'}
    require({v['llvm_symbol'] for v in selected['vtables']} == expected, 'wrong candidate owners')
    for table in selected['vtables']:
        lines = [line for line in ir.splitlines() if line.startswith('@' + table['llvm_symbol'] + ' = ')]
        require(len(lines) == 1 and lines[0] == table['raw_definition_line'], 'vtable selection differs')
        match = re.search(r'\{ \[(\d+) x ptr\] \[(.*)\] \}, align 8$', lines[0])
        require(match is not None, 'unsupported vtable initializer')
        entries = split_parameters(match[2])
        require(len(entries) == int(match[1]) and table['raw_table_index'] == 20 and
                table['byte_offset'] == 160 and entries[20] == table['entry'] ==
                'ptr @_ZN14NVRMUserClient4freeEv', 'candidate slot differs')
    match = re.search(r'^define void @_ZN14NVRMUserClient4freeEv\([^\n]*\n[\s\S]*?^}', ir, re.M)
    require(match is not None and match[0] == selected['free_definition'], 'free body differs')
    load = re.search(r'(%\d+) = load ptr, ptr getelementptr inbounds '
                     r'\(i8, ptr @_ZTV12IOUserClient, i64 160\), align 8', match[0])
    require(load is not None, 'parent vtable load missing')
    require(re.search(r'tail call void ' + re.escape(load[1]) +
                      r'\(ptr noundef nonnull %0\)', match[0]) is not None, 'loaded pointer not called')
    require('@_ZN12IOUserClient4freeEv' not in ir, 'unexpected direct parent symbol')
    require(release['binary_sha256'] == 'cb3775fa7f8261641cc08328e12793aa7c3698d12a3264c443a68c4f55fb1bdb' and
            release['binary_bytes'] == 16787920 and release['nextrel'] == 3397, 'wrong release')
    require(release['symbol'] == '__ZN12IOUserClient4freeEv' and len(release['references']) == 2, 'wrong references')
    require({r['container_symbols'][0]['name'] for r in release['references']} ==
            {'_' + n for n in expected}, 'wrong release containers')
    require({r['address'] for r in release['references']} == {0xd81380, 0xd81df0}, 'wrong addresses')
    for ref in release['references']:
        address, word = struct.unpack('<iI', bytes.fromhex(ref['relocation_bytes_hex']))
        require(address == ref['address'] and word & 0xffffff == ref['symbol_index'] == 33915,
                'relocation raw fields differ')
        require((word >> 24 & 1, word >> 25 & 3, word >> 27 & 1, word >> 28) ==
                (ref['pcrel'], ref['length_log2'], ref['external'], ref['type']) == (0, 3, 1, 0),
                'not an external 64-bit UNSIGNED data reference')
        require(ref['offset_in_container'] == address - ref['container_start'] == 160 and
                ref['classification'] == 'DATA_REFERENCE_NOT_A_DIRECT_CALL', 'not the selected data slot')
    if args.binary:
        require(observe(args.binary.read_bytes(), release['symbol']) == release, 'binary observation differs')
        print('PASS: exact release binary reread; 3397 external relocations, two selected vtable data references')
    else:
        print('PASS: preserved relocation-text consistency only; release binary not reread (use --binary)')
    print('PASS: native IR hash/receipt, both derived slot20 entries, parent vtable+160 load -> same pointer call')
    print('NOT ACCEPTED: publication recipe, complete ABI/loader, executed call, GPU runtime; device NO-GO')


if __name__ == '__main__':
    main()
