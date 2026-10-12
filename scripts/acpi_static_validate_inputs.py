"""Offline ACPI evidence validation. Never reads hardware or executes AML."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
SURVEY = ROOT / 'docs/hardware-survey-20261012'


def validate(survey=SURVEY):
    manifest = {}
    for line in (survey / 'FILES_SHA256.txt').read_text(encoding='utf-8-sig').splitlines():
        sha, name = line.split(None, 1)
        name = name.strip().replace('\\', '/')
        if name in manifest or len(sha) != 64 or name.startswith('/') or '..' in Path(name).parts:
            raise ValueError('Invalid/duplicate manifest path')
        manifest[name] = sha.lower()
    for name in ['evidence/P40_acpi_tables.json', 'evidence/P41_intel_display_firmware.json', 'evidence/P42_acpi_context.json', 'hardware.json', 'REPORT.md']:
        if hashlib.sha256((survey / name).read_bytes()).hexdigest() != manifest[name]:
            raise ValueError('Evidence metadata hash mismatch: ' + name)
    p40 = json.loads((survey / 'evidence/P40_acpi_tables.json').read_text(encoding='utf-8-sig'))['data']
    rows = []
    primary = []
    for section in ['registry_tables', 'firmware_api_tables']:
        for entry in p40[section]:
            if 'file' not in entry:
                continue
            name = entry['file']
            if name not in manifest or name.startswith('/') or '..' in Path(name).parts:
                raise ValueError('Unlisted/unsafe input: ' + name)
            data = (survey / name).read_bytes()
            sha = hashlib.sha256(data).hexdigest()
            length = struct.unpack_from('<I', data, 4)[0]
            checksum = sum(data) & 255
            signature = data[:4].decode('ascii')
            if sha != manifest[name] or sha != entry['sha256'].lower():
                raise ValueError('Input hash mismatch: ' + name)
            if len(data) != entry['length'] or length != entry['header_length'] or length != len(data):
                raise ValueError('Input length mismatch: ' + name)
            if checksum != 0 or entry['checksum_ok'] is not True or signature != entry['signature']:
                raise ValueError('Input checksum/header mismatch: ' + name)
            role = 'PRIMARY_AML' if section == 'registry_tables' and signature in ['DSDT', 'SSDT'] else 'CROSSCHECK_ONLY'
            row = dict(file=name,sha256=sha,length=len(data),header_length=length,checksum_sum_mod256=checksum,checksum_byte=data[9],signature=signature,oem_table_id=data[16:24].decode('ascii').strip(),role=role)
            rows.append(row)
            if role == 'PRIMARY_AML':
                primary.append(row)
    if len(primary) != 16 or sum(x['signature'] == 'DSDT' for x in primary) != 1:
        raise ValueError('Expected DSDT + 15 SSDTs')
    primary_paths = {x['file'] for x in primary}
    actual_paths = {'evidence/acpi/' + p.name for p in (survey / 'evidence/acpi').glob('reg_*.bin') if p.read_bytes()[:4] in [b'DSDT', b'SSDT']}
    if primary_paths != actual_paths:
        raise ValueError('Primary AML table set mismatch')
    for row in rows:
        if row['file'].endswith('fw_DSDT.bin'):
            dsdt = next(x for x in primary if x['signature'] == 'DSDT')
            if row['sha256'] != dsdt['sha256']:
                raise ValueError('Firmware/registry DSDT mismatch')
    return dict(schema=1,evidence_level='SOURCE-STATIC',runtime='RUNTIME_NO_GO',primary_count=16,files=rows,
                checksum_manifest_sha256=hashlib.sha256((survey/'FILES_SHA256.txt').read_bytes()).hexdigest(),
                metadata_sha256={k:manifest[k] for k in ['evidence/P40_acpi_tables.json','evidence/P41_intel_display_firmware.json','evidence/P42_acpi_context.json','FILES_SHA256.txt'] if k in manifest})


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--survey', type=Path, default=SURVEY)
    p.add_argument('--output', type=Path)
    args = p.parse_args()
    result = validate(args.survey)
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_bytes((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode())
    print(json.dumps({'inputs':'PASS','primary_tables':16,'verified_tables':len(result['files'])}))


if __name__ == '__main__':
    main()
