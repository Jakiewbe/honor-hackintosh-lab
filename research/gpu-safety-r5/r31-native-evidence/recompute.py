#!/usr/bin/env python3
"""Recompute preserved R31 evidence. Optional whole extracted text artifact check.

Verify the original ZIP digest before extraction when using --artifact-dir.
No compiler, device, driver or network is invoked by this script.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from g1_full_abi import successful_argv
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def require(v, message):
    if not v: raise ValueError(message)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--artifact-dir',type=Path)
    args=p.parse_args()
    result=read(HERE/'result.json')
    receipt=read(HERE/'local-artifact-binding.json')
    require(result['source_head']=='bc8e1d56343483e695cd47b414b0adcb669bedf8' and
            receipt['run_id']==result['run_id']==39184119617 and
            receipt['artifact_id']==result['artifact_id']==12157153122, 'wrong source/run/artifact')
    require(receipt['artifact_sha256']==result['artifact_sha256']==
            '5fcdb6ae035ceafb22ace2362ba0d52118a7f53d9098789bf5936c996de51578', 'wrong ZIP digest')
    members={r['path']:r for r in receipt['members']}
    require(len(members)==len(receipt['members'])==1851, 'wrong/duplicate artifact members')
    for name in result['preserved_artifact_members']:
        require(sha(HERE/name)==members[name]['sha256'] and
                (HERE/name).stat().st_size==members[name]['bytes'], 'preserved member differs: '+name)
    native=read(HERE/'native-report.json')
    abi=read(HERE/'full-flags-abi/full-abi-report.json')
    host=read(HERE/'deferred-owner-host/report.json')
    series=read(HERE/'r28-series/report.json')
    require(len(native['patches'])==31 and len(native['nvrm_units'])==10 and
            set(native['nvrm_units'].values())=={0}, 'native objects/patches differ')
    require(len(series['patches'])==30 and series['result']=='PASS' and
            series['pristine_sha256']==series['restored_sha256'], 'patch sequence not restored')
    require(host['compile_exit']==host['run_exit']==0 and host['binding']=='NATIVE_SNAPSHOT_MATCH' and
            host['snapshot_sha256']==sha(HERE/'input-snapshots/uni-kms_deferred_cpp.json'), 'queue CPU binding differs')
    snapshot=read(HERE/'input-snapshots/uni-kms_deferred_cpp.json')
    for name, digest in host['source_sha256'].items():
        rows=[r for r in snapshot['inputs'] if r['resolved_path'].endswith('/'+name)]
        require(len(rows)==1 and rows[0]['sha256']==digest, 'queue source differs')
    require(abi['failures']==[] and abi['layouts']['compared_values']==136 and abi['signatures']['symbols']==20 and
            abi['full_report_sha256']==result['full_report_sha256'] and
            abi['native_report_sha256']==sha(HERE/'native-report.json'), 'selected ABI/report binding differs')
    require(abi['candidate_sha256']==result['complete_candidate_sha256']==
            '39653e55198431d577522e51848550635e405ca176cc932a78ffa02aab65d95a', 'candidate differs')
    close=read(HERE/'close-integration-cpu/report.json')
    require(close['compile_exit']==0 and [r['exit'] for r in close['scenarios']]==[0,0,1,1] and
            close['status']=='CONTRACT_FAIL' and
            close['fixture_sha256']==sha(HERE/'close-integration-cpu/fixture.cpp'), 'close failures concealed')
    os_snapshot=read(HERE/'input-snapshots/uni-os-nvkms-xnu_cpp.json')
    os_rows=[r for r in os_snapshot['inputs'] if r['resolved_path'].endswith('/os-nvkms-xnu.cpp')]
    require(len(os_rows)==1 and os_rows[0]['sha256']==close['os_source_sha256'] and
            host['source_sha256']['kms_deferred.cpp']==close['queue_sha256'], 'close source differs from native source')
    if args.artifact_dir:
        src=args.artifact_dir
        for name,row in members.items(): require(sha(src/name)==row['sha256'], 'whole artifact differs: '+name)
        full=read(src/'full-source/report.json')
        require(sha(src/'full-source/report.json')==result['full_report_sha256'], 'full report differs')
        total=0
        for component,count in [('nvidia',1055),('nvidia-modeset',225)]:
            inventory={(r['source'],r['source_sha256']) for r in full['source_inventory'][component]}
            compiled=[r for r in full['objects'] if r['component']==component and r['source'].endswith(('.c','.cpp'))]
            keys={(r['source'],r['source_sha256']) for r in compiled}
            require(len(compiled)==len(keys)==count and len(inventory)==count-1 and inventory<=keys and
                    {n for n,h in keys-inventory}=={component+'/generated/g_nvid_string.c'}, 'official unit set differs')
            for row in compiled:
                require(row['compile_exit']==0 and successful_argv(src/'full-source'/row['log'])==row['candidate_argv'],
                        'compile report/log differs: '+row['source'])
                total+=1
        require(total==1280 and len(full['objects'])==1285 and all(r['compile_exit']==0 for r in full['objects']) and
                full['link']['exit']==0 and len(full['link']['undefined_symbols'])==472 and
                full['link']['artifact_sha256']==result['complete_candidate_sha256'], 'complete build differs')
        print('PASS: whole text artifact; 1280 actual compile logs, full link and 472 imports')
    else:
        print('PASS: preserved native/ABI/source bindings; whole artifact not reread (use --artifact-dir)')
    print('CONFIRMED OPEN: two real-close CPU contract failures; PM busy->STANDBY remains FAIL')
    print('NOT ACCEPTED: complete ABI/loader, GPU initialization/render/readback/safe shutdown; device NO-GO')


if __name__=='__main__': main()
