#!/usr/bin/env python3
"""Recompute R32b CPU/native/full-link text bindings; never accepts device safety."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from g1_full_abi import successful_argv
from g1_full_build import read_defined_log

SOURCE='051651ec0dfc43cfbb9c39534895a8fe4288f035'
OS_SHA='7d86b6b96c0911b2aebd3fdc567fa5ba1dde1122630c515db28b271c3f1f4430'
NVRM_SHA='f284893a1dc8e5a2ab7ae1071598ec528db25cfd248c613d8a523059b79a5469'
PATCH_SHA='a9c5a4f3d2bf1eae90a23767aded5b332e95021e71b14c93b40650f38f018912'


def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def require(ok, message):
    if not ok: raise ValueError(message)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--artifact-dir',type=Path,required=True)
    p.add_argument('--run-meta',type=Path,required=True,help='GitHub API run metadata fetched independently')
    p.add_argument('--out',type=Path,required=True)
    args=p.parse_args()
    src=args.artifact_dir
    meta=read(args.run_meta); receipt=read(src/'local-artifact-binding.json')
    require(meta['id']==receipt['run_id'] and meta['head_sha']==SOURCE and
            meta['status']=='completed' and meta['conclusion']=='success', 'run/source/status differs')
    members=receipt['members']
    require(len({r['path'] for r in members})==len(members),'duplicate ZIP members')
    for r in members:
        name=Path(r['path'])
        require(not name.is_absolute() and '..' not in name.parts,'member escape')
        path=src/name
        require(path.stat().st_size==r['bytes'] and sha(path)==r['sha256'],'ZIP member differs: '+r['path'])
    publication=read(src/'diagnostic-publication.json')
    for r in publication['included']:
        require(sha(src/r['path'])==r['sha256'],'publication differs: '+r['path'])
    native=read(src/'native-report.json'); full=read(src/'full-source/report.json')
    series=read(src/'r28-series/report.json'); abi=read(src/'full-flags-abi/full-abi-report.json')
    host=read(src/'close-retry-host/report.json'); controls=read(src/'close-retry-controls/report.json')
    queue=read(src/'deferred-owner-host/report.json')
    require(len(native['patches'])==32 and len(series['patches'])==31 and series['result']=='PASS' and
            series['pristine_sha256']==series['restored_sha256'],'complete series differs')
    require(series['patches'][-1]['name']=='nullmoth-r32-close-retry.patch' and
            series['patches'][-1]['sha256']==PATCH_SHA,'wrong R32 patch')
    require(len(native['nvrm_units'])==10 and set(native['nvrm_units'].values())=={0},'native NVRM objects failed')
    fb=[r for r in native['objects'] if r['profile']=='candidate' and r['unit']=='NVRMFB']
    require(len(fb)==1 and fb[0]['compile_exit']==0 and fb[0]['source_sha256']==
            '4849c2f4fcdac03f25c221e72372dc7c9cf8bca9957b5c0d6689deb2e8df7453','NVRMFB caller source differs')
    for name,expected in [('os-nvkms-xnu.cpp',OS_SHA),('NVRM.cpp',NVRM_SHA)]:
        require(host['source_sha256'][name]==expected and controls['source_sha256'][name]==expected,'CPU source differs')
    require(host['binding']=='NATIVE_SNAPSHOTS_MATCH' and host['compile_exit']==0 and host['status']=='PASS_CPU_ONLY' and
            len(host['scenarios'])==12 and all(r['exit']==0 for r in host['scenarios']),'close retry CPU differs')
    require(host['snapshot_sha256']['os']==sha(src/'input-snapshots/uni-os-nvkms-xnu_cpp.json') and
            host['snapshot_sha256']['queue']==sha(src/'input-snapshots/uni-kms_deferred_cpp.json') and
            host['fixture_sha256']==sha(src/'close-retry-host/fixture.cpp'),'CPU snapshot/fixture differs')
    for file,expected in [('uni-os-nvkms-xnu_cpp.json',('os-nvkms-xnu.cpp',OS_SHA)),
                          ('uni-NVRM_cpp.json',('NVRM.cpp',NVRM_SHA))]:
        data=read(src/'input-snapshots'/file)
        selected=[r for r in data['inputs'] if r['resolved_path'].endswith('/'+expected[0])]
        require(len(selected)==1 and selected[0]['sha256']==expected[1],'actual object source differs')
    require(controls['status']=='PASS' and len(controls['controls'])==4 and len(controls['structural'])==4 and
            all(controls['structural'].values()) and all(r['control_rejected'] for r in controls['controls']),
            'negative controls/structure differ')
    negative=read(src/'close-retry-controls/compile-failure/report.json')
    require(negative['compile_exit']!=0 and not negative['binary_exists'] and not negative['scenarios'],
            'compile failure ran stale binary')
    require(queue['compile_exit']==queue['run_exit']==0 and queue['binding']=='NATIVE_SNAPSHOT_MATCH','queue CPU differs')
    count=0
    for comp,total in [('nvidia',1055),('nvidia-modeset',225)]:
        expected={(r['source'],r['source_sha256']) for r in full['source_inventory'][comp]}
        rows=[r for r in full['objects'] if r['component']==comp and r['source'].endswith(('.c','.cpp'))]
        actual={(r['source'],r['source_sha256']) for r in rows}
        require(len(rows)==len(actual)==total and len(expected)==total-1 and expected<=actual and
                {n for n,h in actual-expected}=={comp+'/generated/g_nvid_string.c'},'official TU set differs')
        for row in rows:
            require(row['compile_exit']==0 and successful_argv(src/'full-source'/row['log'])==row['candidate_argv'],
                    'compile report/log differs: '+row['source'])
            count+=1
    require(count==1280 and len(full['objects'])==1285 and full['compiler_failures']==0 and
            all(r['compile_exit']==0 for r in full['objects']) and full['link']['exit']==0 and
            len(full['link']['undefined_symbols'])==472,'complete build/link differs')
    queue_row, = [r for r in native['build_manifest'] if r['role']=='nvrm-unified' and
                  r['source']=='kexts/NVRM/kms_deferred.cpp']
    snapshot=read(src/'input-snapshots/uni-kms_deferred_cpp.json')
    require(queue_row['compile_exit']==0 and snapshot['object']==queue_row['object'] and
            snapshot['object_sha256']==queue_row['object_sha256'] and
            successful_argv(src/'uni-kms_deferred_cpp.txt')==snapshot['compile_argv'],
            'actual queue compile/snapshot/object binding differs')
    require(full['link']['baseline_objects'].count(queue_row['object'])==1 and
            successful_argv(src/'full-source/full-nvrm-link.txt').count(queue_row['object'])==1,
            'queue object missing or repeated in actual final link')
    queue_symbols={'_kms_deferred_'+name for name in ('reset','push','drain','count')}
    require(queue_symbols<=read_defined_log(src/'full-source/full-nvrm-defined.txt') and
            not queue_symbols.intersection(full['link']['undefined_symbols']),
            'queue functions must be final definitions, not imports')
    require(not abi['failures'] and abi['layouts']['compared_values']==136 and abi['signatures']['symbols']==20 and
            abi['full_report_sha256']==sha(src/'full-source/report.json') and
            abi['native_report_sha256']==sha(src/'native-report.json') and
            abi['candidate_sha256']==full['link']['artifact_sha256'],'selected ABI binding differs')
    preserved=['native-report.json','full-flags-abi/full-abi-report.json','toolchain.txt',
        'input-snapshots/uni-os-nvkms-xnu_cpp.json','input-snapshots/uni-NVRM_cpp.json',
        'input-snapshots/uni-kms_deferred_cpp.json','r28-series/report.json',
        'full-source/full-nvrm-link.txt','full-source/full-nvrm-defined.txt','uni-kms_deferred_cpp.txt',
        'local-artifact-binding.json','close-retry-host/report.json',
        'close-retry-host/fixture.cpp','close-retry-host/compile.txt',
        'close-retry-controls/report.json','close-retry-controls/compile-failure/report.json',
        'close-retry-controls/compile-failure/compile.txt']
    preserved += ['close-retry-host/'+r['scenario']+'.txt' for r in host['scenarios']]
    args.out.mkdir(parents=True,exist_ok=False)
    for name in preserved:
        dest=args.out/name; dest.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(src/name,dest)
    shutil.copyfile(args.run_meta,args.out/'run-meta.json')
    result={'run_id':meta['id'],'source_head':SOURCE,'artifact_id':receipt['artifact_id'],
        'artifact_sha256':receipt['artifact_sha256'],'verified_zip_members':len(members),
        'verified_publication_members':len(publication['included']),'official_c_cpp_units':count,
        'actual_compile_logs_checked':count,'shader_payloads':5,'native_nvrm_cpp_units':10,
        'native_patch_records':32,'nullmoth_patch_records':31,'series_reverse_restore':'PASS',
        'nvrmfb_caller_source_sha256':fb[0]['source_sha256'],
        'complete_candidate_sha256':full['link']['artifact_sha256'],'remaining_imports':472,
        'queue_route':'ACTUAL_SNAPSHOT_OBJECT_LINK_AND_FOUR_FINAL_DEFINITIONS_MATCH',
        'full_report_sha256':sha(src/'full-source/report.json'),'native_report_sha256':sha(src/'native-report.json'),
        'retry_cpu':'12 scoped contracts PASS; bound to native snapshots','negative_controls':'4 rejected',
        'selected_layout_values':136,'selected_function_shapes':20,'full_abi_loader':'NOT_ACCEPTED',
        'normal_busy_join':'OPEN_FAIL; not covered by scoped native CPU PASS',
        'kapi_device_owner':'OPEN_FAIL; see actual OGKM/driver CPU counterexamples',
        'pm_busy_standby':'FAIL_NOT_FIXED','capacity_overflow':'OPEN_NOT_FIXED',
        'kext_load':'NO-GO','gpu_runtime':'NOT_RUN',
        'preserved_sha256':{n:sha(args.out/n) for n in preserved}}
    (args.out/'result.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result))


if __name__=='__main__': main()
