#!/usr/bin/env python3
"""Recompute preserved real os-xnu six-call shapes and all nine snapshot bindings.

Run from any directory with Python; no compiler/device/network. For the complete
145 original texts, download artifact12141348433 and verify result.json's ZIP
digest first. The other eight IRs remain in that artifact, not duplicated here.
"""
import hashlib
import json
from pathlib import Path
import sys

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from g1_kc8_callers import METHODS, method_observation, object_imports
BASELINE_CPP={'kexts/NVRM/'+name for name in (
    'NVRM.cpp','os-xnu.cpp','os-xnu2.cpp','os-nvkms-xnu.cpp','nv_xnu_stubs.cpp',
    'nvrm_gpuva.cpp','nvrm_fbinfo.cpp','nvrm_surfshare.cpp','nvkms_shaders.cpp')}

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8'))

def main():
    result=read(HERE/'result.json')
    receipt=read(HERE/'local-artifact-binding.json')
    assert receipt['run_id']==result['run_id']==39140902850
    assert receipt['artifact_id']==result['artifact_id']==12141348433
    assert receipt['artifact_sha256']==result['artifact_sha256']=='60dc6f46f5ee0a38fd3936d0c7363800f5136da8703edfcdc110a2be206470b7'
    members={r['path']:r for r in receipt['members']}
    assert len(members)==len(receipt['members'])==145
    for name in result['preserved_artifact_members']:
        if name=='local-artifact-binding.json':continue # Local ZIP verification receipt, not a ZIP member.
        assert sha(HERE/name)==members[name]['sha256']
        assert (HERE/name).stat().st_size==members[name]['bytes']
    report=read(HERE/'caller-report.json')
    assert report['status']==result['result']=='SIX_METHOD_REAL_CALLER_SHAPES_MATCH_SDK'
    assert report['failures']==[] and report['unobserved_methods']==[]
    assert {u['source'] for u in report['units']}==BASELINE_CPP and len(report['units'])==9
    for u in report['units']:
        assert u['status']=='OBSERVED' and u['compile_exit']==u['ir_exit']==0
        snapshot=ROOT/u['historical_profile']['snapshot']
        assert sha(snapshot)==u['dependency_snapshot']['sha256']==u['historical_profile']['snapshot_sha256']
        stem='uni-'+Path(u['source']).name.replace('.','_')
        assert members['input-snapshots/'+stem+'.json']['sha256']==sha(snapshot)
        s=read(snapshot)
        assert s['object_sha256']==u['object_sha256'] and s['compile_argv']==u['compile_argv']
        assert next(r['sha256'] for r in s['inputs'] if r['resolved_path']==s['source'])==u['source_sha256']
    u=next(u for u in report['units'] if u['source']=='kexts/NVRM/os-xnu.cpp')
    ir=(HERE/'uni-os-xnu_cpp.ll').read_text(encoding='utf-8')
    sdk=(HERE/'sdk-methods.ll').read_text(encoding='utf-8')
    assert sha(HERE/'uni-os-xnu_cpp.ll')==u['ir_sha256'] and sha(HERE/'sdk-methods.ll')==report['sdk_ir_sha256']
    imports=object_imports(HERE/'uni-os-xnu_cpp-undefined.txt',u['compile_argv'][-1])
    rows=[method_observation(ir,n,imports,sdk) for n in METHODS]
    assert rows==u['records'] and all(r['calls'] for r in rows)
    w=next(r for r in rows if 'Write8' in r['macho_symbol'])
    assert len(w['calls'])==1 and '@os_pci_write_byte(' in w['calls'][0]['owner']
    assert w['calls'][0]==result['write8_call']
    print('PASS: preserved artifact hashes; nine actual object/source/command snapshot bindings; six real PCI calls including os_pci_write_byte -> write8')
    print('NOT ACCEPTED: full provider ABI, loader/version, GPU initialization/render/readback/safe shutdown; device NO-GO')

if __name__=='__main__':main()
