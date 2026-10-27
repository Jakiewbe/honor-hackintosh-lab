"""Complete NVRM.cpp Darwin TU and kext FORMAT gate; never a complete RM driver.

Only source and text diagnostics are transferred. The upstream RM providers are
not linked here, so a successful MH_KEXT_BUNDLE does not close dependency/loader
or device gates. No driver output is executed, installed, or loaded.
"""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts/g1_userland'))
import native as shared
from g1_compile_inputs import bound_compile

PINS={'nm':'272ccd9da04ff5de95c2791b902fe17a3fa77ce7',
      'ogkm':'e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb'}
REL='kexts/NVRM/NVRM.cpp'
# The admission patch also changes a second translation unit (the NVKMS RM hook) and a header.
# A header is not compiled on its own; the TU that includes it is, so that is what is gated.
KMS='kexts/NVRM/os-nvkms-xnu.cpp'
PM=ROOT/'scripts/g1_userland/kernel-pm'
ADMIT=ROOT/'scripts/g1_userland/kernel-pm-admit'
PROFILE=ROOT/'scripts/g1_24h32/PROFILE.json'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def patch_manifest():
    m=json.loads((PM/'pm-manifest.json').read_text(encoding='utf-8'))
    if m['pin']!=PINS['nm'] or m['patch_sha256']!=sha(PM/'pm.patch'):
        raise ValueError('PM pin/patch identity differs')
    if [r['path'] for r in m['files']]!=[REL] or set(m['baseline_sha256'])!={REL}:
        raise ValueError('expected exactly one changed PM translation unit')
    return m

def admission_manifest():
    a=json.loads((ADMIT/'pm-admit-manifest.json').read_text(encoding='utf-8'))
    if a['pin']!=PINS['nm'] or a['admission_patch_sha256']!=sha(ADMIT/'pm-admit.patch'):
        raise ValueError('admission pin/patch identity differs')
    if a['base_patch']['sha256']!=sha(PM/'pm.patch'):
        raise ValueError('the admission patch no longer stacks on the reviewed rollback patch')
    if sorted(r['path'] for r in a['files'])!=sorted([REL,KMS,'kexts/NVRM/nv-xnu.h']):
        raise ValueError('unexpected set of admission-changed files')
    return a

def config():
    p=json.loads(PROFILE.read_text(encoding='utf-8'))
    if p['pins']!=PINS or any(x.split('=')[0]=='-DNV_LINUX' for x in p['rm_definitions']):
        raise ValueError('invalid Darwin reconstruction profile')
    names=p['rm_include_dirs']+p['nvaccel_extra_include_dirs']
    if len(names)!=len(set(names)) or any(Path(n).is_absolute() or '..' in Path(n).parts or '\\' in n for n in names):
        raise ValueError('invalid include directory declaration')
    return p,names

def prepare(nm,ogkm,workspace):
    m=patch_manifest();a=admission_manifest();workspace.mkdir(parents=True,exist_ok=False)
    counts={k:shared.export(tree,PINS[k],workspace/k) for k,tree in [('nm',nm),('ogkm',ogkm)]}
    baseline=workspace/'nm'
    for rel,digest in a['baseline_sha256'].items():
        if sha(baseline/rel)!=digest:raise ValueError('admission baseline differs: '+rel)
    if sha(baseline/REL)!=m['baseline_sha256'][REL]:raise ValueError('PM baseline differs')
    candidate=workspace/'candidate';shutil.copytree(baseline,candidate)
    for patch in (PM/'pm.patch',ADMIT/'pm-admit.patch'):
        for flags in (['--check'],[]):
            subprocess.run(['git','-c','core.autocrlf=false','apply',*flags,str(patch)],cwd=candidate,check=True)
    for row in a['files']:
        p=candidate/row['path']
        if sha(p)!=row['sha256'] or p.stat().st_size!=row['bytes']:
            raise ValueError('patched source differs: '+row['path'])
    for patch in (ADMIT/'pm-admit.patch',PM/'pm.patch'):
        subprocess.run(['git','-c','core.autocrlf=false','apply','--reverse','--check',str(patch)],cwd=candidate,check=True)
    files=[dict(path=p.relative_to(workspace).as_posix(),bytes=p.stat().st_size,sha256=sha(p))
           for p in sorted(workspace.rglob('*')) if p.is_file()]
    result=dict(pins=PINS,source_files=counts,files=files,pm_manifest_sha256=sha(PM/'pm-manifest.json'),
        admission_manifest_sha256=sha(ADMIT/'pm-admit-manifest.json'),
        profile_sha256=sha(PROFILE),go_authorized=False)
    (workspace/'INPUTS.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    return result

def verify_inputs(workspace,inputs):
    shared.verify_inputs(workspace,inputs)
    if inputs['pm_manifest_sha256']!=sha(PM/'pm-manifest.json') or inputs['profile_sha256']!=sha(PROFILE):
        raise ValueError('reviewed PM manifest/profile changed')
    if inputs['admission_manifest_sha256']!=sha(ADMIT/'pm-admit-manifest.json'):
        raise ValueError('reviewed admission manifest changed')
    patch_manifest();admission_manifest()

def imports(text):
    rows=text.splitlines()
    if len(set(rows))!=len(rows) or any(not x.startswith('_') or any(c.isspace() for c in x) for x in rows):
        raise ValueError('malformed/duplicate actual nm import')
    return set(rows)

def binding_source(label,tree,binding,m,tu=REL):
    snap=json.loads(Path(binding['path']).read_text(encoding='utf-8'))
    if sha(Path(binding['path']))!=binding['sha256']:raise ValueError('dependency snapshot changed')
    actual=[r for r in snap['inputs'] if Path(r['resolved_path']).resolve()==(tree/tu).resolve()]
    if label=='baseline':expected=m['baseline_sha256'][tu]
    elif tu==REL:expected=m['files'][0]['sha256']
    else:expected=next(r['sha256'] for r in m['files'] if r['path']==tu)
    if len(actual)!=1 or actual[0]['sha256']!=expected or sha(tree/tu)!=expected:
        raise ValueError('actual compiler did not see reviewed bytes for '+tu)
    return expected

TUS=(REL,KMS)
def complete(r):
    want={(l,t) for l in ('baseline','candidate') for t in TUS}
    return (not r['errors'] and r['compiler_failures']==0
        and len(r['objects'])==len(r['format_links'])==len(want)
        and {(x['label'],x['source']) for x in r['objects']}==want
        and {(x['label'],x['source']) for x in r['format_links']}==want
        and all(x['exit']==0 and x['filetype']==1 and x['source_bound'] for x in r['objects'])
        and all(x['exit']==0 and x['filetype']==11 for x in r['format_links'])
        and all(r.get(k)==dict(added=[],removed=[]) for k in
                [n+'_import_delta_'+t.split('/')[-1] for n in ('object','linked') for t in TUS]))

def run(workspace,out,tools):
    r=dict(status='FAILED',level='DARWIN_COMPLETE_TWO_TU_AND_KEXT_FORMAT_ONLY',pins=PINS,
        objects=[],format_links=[],errors=[],compiler_failures=0,complete_driver_link='NOT_ATTEMPTED',
        dependency_provider_closure='NOT_VERIFIED',
        # This patch now implements an admission verdict; what it still cannot do is make IOPM keep the
        # slot powered (R24), and the refusal's own completion bound is not proven.
        rm_admission_denial='IMPLEMENTED_SOURCE_HOST_ONLY_NOT_DARWIN_NOT_DEVICE',
        rm_admission_bound='NOT_PROVEN',
        full_abi='UNVERIFIED',loader='NOT_RUN',gpu='NOT_RUN',runtime='NOT_RUN',go_authorized=False)
    try:
        inputs=json.loads((workspace/'INPUTS.json').read_text(encoding='utf-8'));verify_inputs(workspace,inputs)
        profile,dirs=config();r.update(source_files=inputs['source_files'],profile=profile)
        sdk=Path(tools.capture(['/usr/bin/xcrun','--show-sdk-path'],out,'sdk').strip())
        version=tools.capture(['/usr/bin/xcrun','--show-sdk-version'],out,'sdk-version').strip()
        if version!='15.5':raise ValueError('expected SDK 15.5')
        khdr=sdk/'System/Library/Frameworks/Kernel.framework/Headers'
        if not (khdr/'IOKit/IOService.h').is_file():raise ValueError('Kernel SDK headers missing')
        clang=tools.capture(['/usr/bin/xcrun','--find','clang++'],out,'compiler-path').strip()
        r.update(compiler=tools.capture([clang,'--version'],out,'compiler-version'),
            xcode=tools.capture(['/usr/bin/xcodebuild','-version'],out,'xcode'),sdk_version=version)
        absent=sorted(d for d in dirs if not (workspace/'ogkm'/d).is_dir())
        if absent!=sorted(profile['make_include_directories_absent']):raise ValueError('profile include existence differs')
        flags=['-arch','x86_64','-mmacosx-version-min=15.5','-isysroot',str(sdk),'-fapple-kext','-mkernel',
            '-nostdinc','-I'+str(khdr),'-DKERNEL','-DKERNEL_PRIVATE','-DDRIVER_PRIVATE','-DAPPLE','-DNeXT',
            *profile['rm_definitions'],'-std=c++17','-fno-rtti','-fno-exceptions','-fno-builtin','-fno-common',
            '-O2','-Wall','-Wno-unused-parameter','-Wno-inconsistent-missing-override','-Wno-unused-function']
        obj_imports={};link_imports={}
        a=admission_manifest()
        for tu in (REL,KMS):
            key=tu.split('/')[-1]
            for label,tree in [('baseline',workspace/'nm'),('candidate',workspace/'candidate')]:
                obj=out/(label+'-'+key+'.o');source=tree/tu
                inc=['-I'+str(workspace/'ogkm'/d) for d in dirs]+['-I'+str(source.parent)]
                argv=[clang,*flags,*inc,'-c',str(source),'-o',str(obj)]
                macros=tools.capture([clang,*flags,*inc,'-dM','-E',str(source)],out,label+'-'+key+'-macros')
                if '#define NVOS_IS_LINUX 0' not in macros.splitlines() or any(x.startswith('#define NV_LINUX ') for x in macros.splitlines()):
                    raise ValueError('Darwin preprocess selects Linux')
                record=dict(label=label,source=tu,exit=None,source_bound=False);r['objects'].append(record)
                rc,binding,actual=bound_compile(argv,tree,out/(label+'-'+key+'-compile.txt'),out/(label+'-'+key+'-deps'),tools.execute)
                record.update(exit=rc,binding=binding,command=actual)
                if rc:r['compiler_failures']+=1;raise ValueError(label+' '+key+' actual TU compilation failed')
                digest=binding_source(label,tree,binding,a,tu)
                record.update(shared.macho(obj,1),source_bound=True,source_sha256=digest)
                obj_imports[label,key]=imports(tools.capture(['/usr/bin/xcrun','nm','-u','-j',str(obj)],out,label+'-'+key+'-undefined').strip())
                tools.capture(['/usr/bin/xcrun','nm','-gU',str(obj)],out,label+'-'+key+'-defined')
                tools.capture(['/usr/bin/xcrun','otool','-rv',str(obj)],out,label+'-'+key+'-relocations')
                binary=out/(label+'-'+key+'-TU-format-only')
                link=[clang,'-arch','x86_64','-mmacosx-version-min=15.5','-isysroot',str(sdk),'-fapple-kext',
                    '-nostdlib','-Xlinker','-kext','-lkmodc++','-lkmod','-lcc_kext',str(obj),'-o',str(binary)]
                rc=tools.execute(link,out,out/(label+'-'+key+'-link.txt'))
                entry=dict(label=label,source=tu,command=link,exit=rc,scope='SINGLE_TU_FORMAT_NOT_COMPLETE_'+key);r['format_links'].append(entry)
                if rc:raise ValueError(label+' '+key+' kext format link failed')
                entry.update(shared.macho(binary,11))
                tools.capture(['/usr/bin/xcrun','otool','-l',str(binary)],out,label+'-'+key+'-load-commands')
                link_imports[label,key]=imports(tools.capture(['/usr/bin/xcrun','nm','-u','-j',str(binary)],out,label+'-'+key+'-linked-undefined').strip())
        for name,sets in [('object',obj_imports),('linked',link_imports)]:
            for key in ('NVRM.cpp','os-nvkms-xnu.cpp'):
                s={'baseline':sets['baseline',key],'candidate':sets['candidate',key]}
                r[name+'_import_delta_'+key]=dict(added=sorted(s['candidate']-s['baseline']),removed=sorted(s['baseline']-s['candidate']))
        r['object_import_counts']={k[0]+':'+k[1]:len(v) for k,v in obj_imports.items()}
        r['linked_import_counts']={k[0]+':'+k[1]:len(v) for k,v in link_imports.items()}
        verify_inputs(workspace,inputs)
        if not complete(r):raise ValueError('native acceptance incomplete or unexpected import change')
        r['status']='PM_TWO_TU_OBJECT_AND_KEXT_FORMAT_PASS_NOT_DRIVER_LINK_OR_GO'
    except (OSError,ValueError,KeyError,TypeError,subprocess.SubprocessError) as e:r['errors'].append(str(e))
    finally:
        (out/'RESULT.json').write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8')
        with zipfile.ZipFile(out/'native-pm-text.zip','x',compression=zipfile.ZIP_DEFLATED) as z:
            for p in out.rglob('*'):
                if p.is_file() and p.suffix in ('.txt','.json','.d'):z.write(p,p.relative_to(out).as_posix())
    return r

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--nm',type=Path,required=True);p.add_argument('--ogkm',type=Path,required=True)
    p.add_argument('--workspace',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
    p.add_argument('--prepare-only',action='store_true');a=p.parse_args()
    a.out.mkdir(parents=True,exist_ok=False)
    try:inputs=prepare(a.nm,a.ogkm,a.workspace)
    except (OSError,ValueError,KeyError,subprocess.SubprocessError) as e:
        (a.out/'PREPARATION-ERROR.txt').write_text(str(e),encoding='utf-8');return 1
    if a.prepare_only:
        verify_inputs(a.workspace,inputs);print('FIXED_PM_INPUTS_VERIFIED_NOT_DARWIN');return 0
    if platform.system()!='Darwin':raise SystemExit('Darwin required to compile the actual complete TU')
    result=run(a.workspace,a.out,shared.Tools());print(json.dumps(result,indent=2))
    return 0 if complete(result) else 1

if __name__=='__main__':raise SystemExit(main())
