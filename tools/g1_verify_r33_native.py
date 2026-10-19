#!/usr/bin/env python3
"""Fixed R33 run: independently recheck text artifact, full recipes and patch route.

No binary download/runtime claim. Baseline report must be the already audited
R32b report, bound by its digest; only the two explicit OGKM source deltas apply.
"""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import posixpath
import shutil
from g1_compile_inputs import BOUND_RM, command_with_dependencies
from g1_full_build import darwin_command, read_defined_log
from g1_full_abi import successful_argv
from g1_ogkm_candidate import SPECS
from g1_ogkm_patch_route import check_candidate_route
from g1_verify_r32_native import OS_SHA, NVRM_SHA, PATCH_SHA

RUN=39189188122
SOURCE='7a5cb7188ef6477b7383f9529228bbb4426aa1fd'
ARTIFACT=12159721676
ZIP='bb358a648b789c07710395935d9cd55d8dfbaac0e79318491db2fd60d48b03f5'
BASELINE='0124b5735fce476873ca697fb91d4984158b92edf192336c34f5b4c14ec25dff'
RECEIPT='c3bfa70bcc7097d3b0021853581d2b45a29abb2255ce0a5eebd07161978bdef8'
PUBLICATION='44eb00d9716cec77a9e84f8d6bed8b0ebaed7969a725f8b32693448c0fd77fc7'
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def need(ok, message):
    if not ok: raise ValueError(message)


def verify(src, meta_path, baseline_path):
    meta=read(meta_path); receipt=read(src/'local-artifact-binding.json')
    need(meta['id']==RUN and meta['head_sha']==SOURCE and meta['status']=='completed' and
        meta['conclusion']=='success','run/source/status mismatch')
    need(receipt['run_id']==RUN and receipt['artifact_id']==ARTIFACT and receipt['artifact_sha256']==ZIP,
        'external artifact identity mismatch')
    # Fixed receipt was generated while validating the actual downloaded ZIP digest.
    # Do not let a reduced self-consistent member list hide absent evidence.
    need(sha(src/'local-artifact-binding.json')==RECEIPT and len(receipt['members'])==1954,
        'fixed verified ZIP receipt differs')
    need(len({r['path'] for r in receipt['members']})==len(receipt['members']),'duplicate ZIP member')
    for r in receipt['members']:
        p=src/r['path']
        need(p.resolve().is_relative_to(src.resolve()) and not p.is_symlink(),'member escape')
        need(p.stat().st_size==r['bytes'] and sha(p)==r['sha256'],'member bytes differ: '+r['path'])
    publication=read(src/'diagnostic-publication.json')
    need(sha(src/'diagnostic-publication.json')==PUBLICATION and len(publication['included'])==1953 and
        {r['path'] for r in receipt['members']}==
        {r['path'] for r in publication['included']}|{'diagnostic-publication.json'},
        'fixed publication/member set differs')
    for r in publication['included']:
        need(sha(src/r['path'])==r['sha256'],'publication member differs')
    need(sha(baseline_path)==BASELINE,'wrong audited baseline report')
    baseline=read(baseline_path); full=read(src/'full-source/report.json'); native=read(src/'native-report.json')
    need(full['source_inventory']==baseline['source_inventory'] and full['pins']==baseline['pins'],
        'official fixed source inventory/pins changed')
    need(full['compiler_failures']==0 and len(full['objects'])==1285 and full['link']['exit']==0 and
        all(r['compile_exit']==0 and len(r['object_sha256'])==64 for r in full['objects']) and
        len({r['object'] for r in full['objects']})==1285,
        'full compile/link incomplete')
    patches={s['source']:s for s in SPECS}; checked=0; languages={'.c':0,'.cpp':0}
    for component,total in [('nvidia',1055),('nvidia-modeset',225)]:
        expected={r['source']:r['source_sha256'] for r in full['source_inventory'][component]}
        for name,s in patches.items():
            if name in expected:
                need(expected[name]==s['original_sha256'],'patch base source differs')
                expected[name]=s['candidate_sha256']
        rows=[r for r in full['objects'] if r['component']==component and r['source'].endswith(('.c','.cpp'))]
        need(len(rows)==total and len({r['source'] for r in rows})==total,'missing/duplicate official TU')
        actual={r['source']:r['source_sha256'] for r in rows}
        need({k:v for k,v in actual.items() if k in expected}==expected and
            set(actual)-set(expected)=={component+'/generated/g_nvid_string.c'},'official source/hash set differs')
        for r in rows:
            cwd=PurePosixPath(r['compile_cwd']); official=r['official_argv']
            source=PurePosixPath(posixpath.normpath(str(cwd/official[official.index('-c')+1])))
            if r['source'] in patches: source=PurePosixPath(r['compiled_source'])
            obj=PurePosixPath(r['object']); headers=PurePosixPath(full['sdk'])/'System/Library/Frameworks/Kernel.framework/Headers'
            argv=darwin_command(official,source,obj,full['sdk'],headers)
            if r['source'] in BOUND_RM:
                argv=command_with_dependencies(argv,obj.parent.parent/'input-snapshots'/(obj.stem+'.d'))
            need(r['compile_exit']==0 and len(r['object_sha256'])==64 and
                r['candidate_argv']==argv and successful_argv(src/'full-source'/r['log'])==argv,
                'official transformation/actual compile log mismatch: '+r['source'])
            languages[PurePosixPath(r['source']).suffix]+=1;checked+=1
    need(checked==1280 and languages=={'.c':1240,'.cpp':40},'official language counts differ')
    shaders=[r for r in full['objects'] if not r['source'].endswith(('.c','.cpp'))]
    old_shaders=[r for r in baseline['objects'] if not r['source'].endswith(('.c','.cpp'))]
    need(len(shaders)==5 and [(r['source'],r['source_sha256'],r['xz_sha256']) for r in shaders]==
        [(r['source'],r['source_sha256'],r['xz_sha256']) for r in old_shaders],'fixed shader payloads differ')
    for component,count in [('nvidia',1055),('nvidia-modeset',230)]:
        rows=[r for r in full['objects'] if r['component']==component]
        archive,=[r for r in full['archives'] if r['component']==component]
        archive_path,=[p for p in full['link']['archive_order'] if PurePosixPath(p).name=='lib'+component+'.a']
        need(archive['objects']==len(rows)==count and successful_argv(src/'full-source'/(component+'-archive.txt'))==
            ['xcrun','ar','rcs',archive_path,*[r['object'] for r in rows]],'full archive source/object inputs differ')
    route=check_candidate_route(src,native,full)
    need(route==read(src/'ogkm-patch-route/report.json'),'CI/current independent route results differ')
    candidate=full['ogkm_candidate']
    need(candidate['files']==3871 and candidate['original_tree_sha256']==
        '66276173d370220c6f1ff8b140727b18291ccefcb3dc11b58ed47136ae9a22a7' and
        candidate['candidate_tree_sha256']=='528d7063c36d2643e5f08b4422f58b589c638ae7caa69b6d59b5bff2b602ed3d',
        'CI whole candidate trees differ from local independently verified trees')
    series=read(src/'r28-series/report.json');host=read(src/'close-retry-host/report.json')
    controls=read(src/'close-retry-controls/report.json');niso=read(src/'niso-owner-host/report.json')
    need(len(series['patches'])==31 and series['result']=='PASS' and series['candidate_sha256']==
        '28a9125ec7279a3c11fc51bbb10abf8d5fcc6d1798dcda83bea0fa4622b5a37d' and
        series['pristine_sha256']==series['restored_sha256'] and series['patches'][-1]['sha256']==PATCH_SHA,
        'NullMoth patch series differs')
    need(len(native['nvrm_units'])==10 and set(native['nvrm_units'].values())=={0},'native NVRM units failed')
    need(host['source_sha256']['os-nvkms-xnu.cpp']==OS_SHA and host['source_sha256']['NVRM.cpp']==NVRM_SHA and
        host['binding']=='NATIVE_SNAPSHOTS_MATCH' and host['compile_exit']==0 and len(host['scenarios'])==12 and
        all(r['exit']==0 for r in host['scenarios']),'scoped close CPU failed')
    for name,expected in [('os-nvkms-xnu.cpp',OS_SHA),('NVRM.cpp',NVRM_SHA),
            ('kms_deferred.cpp','c500f4734abb0a8897bb414c32e64f2301524d23f53d55a88847b8864820370c')]:
        stem='uni-'+name.replace('.','_')
        snap=read(src/'input-snapshots'/(stem+'.json'))
        selected=[r for r in snap['inputs'] if PurePosixPath(r['resolved_path']).name==name]
        row,=[r for r in native['build_manifest'] if r['role']=='nvrm-unified' and r['source']=='kexts/NVRM/'+name]
        need(len(selected)==1 and selected[0]['sha256']==expected and snap['object']==row['object'] and
            snap['object_sha256']==row['object_sha256'] and row['source_sha256']==expected and
            successful_argv(src/(stem+'.txt'))==snap['compile_argv'],'actual native source/object/recipe binding differs')
    need(host['snapshot_sha256']['os']==sha(src/'input-snapshots/uni-os-nvkms-xnu_cpp.json') and
        host['snapshot_sha256']['queue']==sha(src/'input-snapshots/uni-kms_deferred_cpp.json') and
        host['fixture_sha256']==sha(src/'close-retry-host/fixture.cpp'),'host/native snapshot hashes differ')
    need(controls['status']=='PASS' and len(controls['controls'])==4 and
        all(r['control_rejected'] for r in controls['controls']) and all(controls['structural'].values()),
        'negative controls failed')
    negative=read(src/'close-retry-controls/compile-failure/report.json')
    need(negative['compile_exit']!=0 and not negative['binary_exists'] and not negative['scenarios'],
        'failed compile ran a binary')
    need(niso['source_sha256']==SPECS[1]['candidate_sha256'] and niso['compile_exit']==niso['run_exit']==0 and
        niso['status']=='PASS_CPU_ONLY' and niso['fixture_sha256']==sha(src/'niso-owner-host/fixture.cpp') and
        all(label+' PASS' in niso['output'] for label in ('parameter_identity','sequential_cleanup','repeat_cleanup')),
        'NISO success-only CPU contract failed')
    queue,=[r for r in native['build_manifest'] if r['role']=='nvrm-unified' and r['source']=='kexts/NVRM/kms_deferred.cpp']
    qsymbols={'_kms_deferred_'+s for s in ('reset','push','drain','count')}
    need(full['link']['baseline_objects'].count(queue['object'])==1 and
        successful_argv(src/'full-source/full-nvrm-link.txt').count(queue['object'])==1 and
        qsymbols<=read_defined_log(src/'full-source/full-nvrm-defined.txt') and
        not qsymbols.intersection(full['link']['undefined_symbols']),'actual queue route differs')
    abi=read(src/'full-flags-abi/full-abi-report.json')
    need(not abi['failures'] and abi['layouts']['compared_values']==136 and abi['signatures']['symbols']==20 and
        abi['full_report_sha256']==sha(src/'full-source/report.json') and
        abi['native_report_sha256']==sha(src/'native-report.json') and
        abi['candidate_sha256']==full['link']['artifact_sha256'],'selected ABI/result binding differs')
    return {'status':'PASS_FIXED_R33_TEXT_BUILD_ROUTE_ONLY','source':SOURCE,'run_id':RUN,'artifact_id':ARTIFACT,
        'artifact_zip_sha256':ZIP,'verified_zip_members':len(receipt['members']),
        'verified_publication_members':len(publication['included']),'official_recipes_and_compile_logs_checked':checked,
        'language_counts':languages,'native_nvrm_cpp_units':10,'nullmoth_patches':31,'full_ogkm_patches':2,
        'candidate_sha256':full['link']['artifact_sha256'],'imports':len(full['link']['undefined_symbols']),
        'ogkm_route':route,'niso_cpu':'3 success-path contracts PASS','retry_cpu':'12 scoped PASS; 4 controls rejected',
        'selected_abi':'136 values / 20 shapes PASS; full ABI NOT ACCEPTED',
        'device_owner':'FAIL_NOT_FIXED','normal_busy_join':'FAIL_NOT_FIXED','rm_busy_standby':'FAIL_NOT_FIXED',
        'gpu_runtime':'NOT_RUN','kext_load':'NO-GO'}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--artifact-dir',type=Path,required=True);p.add_argument('--run-meta',type=Path,required=True)
    p.add_argument('--baseline-report',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args(); result=verify(a.artifact_dir,a.run_meta,a.baseline_report)
    a.out.mkdir(parents=True,exist_ok=False)
    keep=['toolchain.txt','local-artifact-binding.json','ogkm-patch-route/report.json',
        'niso-owner-host/report.json','niso-owner-host/fixture.cpp','niso-owner-host/compile.txt','niso-owner-host/run.txt',
        'full-source/full-nvrm-link.txt','full-source/full-nvrm-defined.txt','full-source/nvidia-modeset-archive.txt',
        'full-source/nvidia-archive.txt',
        'full-flags-abi/full-abi-report.json','close-retry-host/report.json','close-retry-controls/report.json',
        'r28-series/report.json','native-report.json']
    full=read(a.artifact_dir/'full-source/report.json')
    keep += ['full-source/'+r['log'] for r in full['objects'] if r['source'] in {s['source'] for s in SPECS}]
    for name in keep:
        dest=a.out/name;dest.parent.mkdir(exist_ok=True,parents=True);shutil.copyfile(a.artifact_dir/name,dest)
    shutil.copyfile(a.run_meta,a.out/'run-meta.json')
    result['preserved_sha256']={name:sha(a.out/name) for name in keep}
    (a.out/'result.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result))


if __name__=='__main__': main()
