#!/usr/bin/env python3
"""Check preserved R30 native texts; optionally validate the whole extracted artifact.

No compiler, network or device access. --artifact-dir expects the original text
ZIP already verified against result.json's artifact_sha256 before extraction.
"""
import argparse
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def require(v, message):
    if not v: raise ValueError(message)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--artifact-dir', type=Path)
    args = p.parse_args()
    result = read(HERE/'result.json')
    receipt = read(HERE/'local-artifact-binding.json')
    require(receipt['run_id'] == result['run_id'] == 39143508201 and
            receipt['artifact_id'] == result['artifact_id'] == 12143225527, 'wrong artifact')
    require(receipt['artifact_sha256'] == result['artifact_sha256'] ==
            'e8f6ee5d9697b4cb64afee369f2f6d5a74bf5724c681744597f463aec937cc50', 'wrong ZIP digest')
    members = {r['path']:r for r in receipt['members']}
    require(len(members) == len(receipt['members']) == 1845, 'wrong/duplicate members')
    for name in result['preserved_artifact_members']:
        require(sha(HERE/name) == members[name]['sha256'] and
                (HERE/name).stat().st_size == members[name]['bytes'], 'preserved member differs: '+name)
    native = read(HERE/'native-report.json')
    abi = read(HERE/'full-flags-abi/full-abi-report.json')
    require(len(native['patches']) == 30 and native['nvrm_units'] == result['native_nvrm_cpp_units'] and
            len(native['nvrm_units']) == 10 and set(native['nvrm_units'].values()) == {0}, 'native units differ')
    require(abi['native_report_sha256'] == sha(HERE/'native-report.json') and
            abi['full_report_sha256'] == result['full_report_sha256'], 'report binding differs')
    require(abi['candidate_sha256'] == result['candidate_sha256'] ==
            '74ce9fe05c9a10f8a55fa39ce2e0a097e4b436e4c9e0298fabecca0b8a5f561b', 'candidate differs')
    require(abi['failures'] == [] and abi['layouts']['compared_values'] == 136 and
            abi['signatures']['symbols'] == 20, 'selected ABI differs')
    pm = read(HERE/'pm-structure.json')
    require(pm['result'] == 'FAIL' and len(pm['failures']) == 1 and len(pm['checks']) == 32, 'PM failure concealed')
    baseline, fixed, negative = [read(HERE/n/'report.json') for n in ('r30-host','r31-host','negative-host')]
    require(baseline['compile_exit'] == 0 and baseline['run_exit'] == 1 and
            fixed['compile_exit'] == fixed['run_exit'] == 0 and negative['compile_exit'] != 0 and
            negative['run_exit'] is None and negative['run'] == 'NOT_RUN', 'CPU or fail-closed evidence differs')
    if args.artifact_dir:
        src = args.artifact_dir
        for name, row in members.items():
            require(sha(src/name) == row['sha256'], 'full artifact member differs: '+name)
        full = read(src/'full-source/report.json')
        require(sha(src/'full-source/report.json') == result['full_report_sha256'], 'full report differs')
        for component, count in [('nvidia',1055), ('nvidia-modeset',225)]:
            inventory = {(r['source'],r['source_sha256']) for r in full['source_inventory'][component]}
            compiled = [(r['source'],r['source_sha256']) for r in full['objects']
                        if r['component'] == component and r['source'].endswith(('.c','.cpp'))]
            require(len(compiled) == len(set(compiled)) == count and len(inventory) == count-1 and
                    inventory <= set(compiled) and {n for n,h in set(compiled)-inventory} ==
                    {component+'/generated/g_nvid_string.c'}, 'official unit set differs')
        require(len(full['objects']) == 1285 and all(r['compile_exit'] == 0 for r in full['objects']) and
                full['link']['exit'] == 0 and len(full['link']['undefined_symbols']) == 472, 'full build differs')
        print('PASS: whole extracted artifact rehashed; 1280 C/C++ units + five shader payloads; 472 imports')
    else:
        print('PASS: preserved native/ABI/PM/CPU texts; full artifact not reread (use --artifact-dir)')
    print('NOT ACCEPTED: R31 Darwin build, full ABI/loader, PM safety or any GPU runtime; device NO-GO')


if __name__ == '__main__': main()
