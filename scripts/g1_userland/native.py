"""Compile real baseline/candidate plugin source; never load or execute outputs."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import platform
import shutil
import struct
import subprocess
import tarfile
import zipfile

from g1_compile_inputs import bound_compile

HERE=Path(__file__).resolve().parent
PINS={'nm':'272ccd9da04ff5de95c2791b902fe17a3fa77ce7',
      'vk':'2fa203425eb4af9dfc6b03f97ef72b0b5bcb8350'}
FRAMEWORKS=('Foundation','Metal','IOSurface','IOKit','CoreFoundation')


def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def export(tree,pin,dest):
    if subprocess.check_output(['git','-C',str(tree),'rev-parse','HEAD'],text=True).strip()!=pin:
        raise ValueError('fixed source commit mismatch')
    raw=subprocess.check_output(['git','-C',str(tree),'archive','--format=tar',pin])
    count=0
    with tarfile.open(fileobj=io.BytesIO(raw)) as z:
        for entry in z:
            p=PurePosixPath(entry.name)
            if p.is_absolute() or '..' in p.parts or '\\' in entry.name: raise ValueError('unsafe source path')
            if entry.isdir(): continue
            if not entry.isfile(): raise ValueError('nonregular source')
            target=dest/entry.name
            if target.exists(): raise ValueError('duplicate source')
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(z.extractfile(entry).read());count+=1
    return count


def prepare(nm,vk,workspace):
    workspace.mkdir(parents=True,exist_ok=False)
    manifest=json.loads((HERE/'owner-manifest.json').read_text(encoding='utf-8'))
    if manifest['pin']!=PINS['nm'] or sha(HERE/'owner.patch')!=manifest['patch_sha256']:
        raise ValueError('owner patch pin/digest changed')
    counts={name:export(tree,PINS[name],workspace/name) for name,tree in [('nm',nm),('vk',vk)]}
    baseline=workspace/'nm'
    for rel,digest in manifest['baseline_sha256'].items():
        if sha(baseline/rel)!=digest: raise ValueError('owner patch baseline changed')
    candidate=workspace/'candidate'
    shutil.copytree(baseline,candidate)
    for flags in (['--check'],[]):
        subprocess.run(['git','-c','core.autocrlf=false','apply',*flags,str(HERE/'owner.patch')],cwd=candidate,check=True)
    for row in manifest['files']:
        p=candidate/row['path']
        if p.stat().st_size!=row['bytes'] or sha(p)!=row['sha256']: raise ValueError('patched source identity differs')
    subprocess.run(['git','-c','core.autocrlf=false','apply','--reverse','--check',str(HERE/'owner.patch')],cwd=candidate,check=True)
    rows=[dict(path=p.relative_to(workspace).as_posix(),bytes=p.stat().st_size,sha256=sha(p))
          for p in sorted(workspace.rglob('*'),key=lambda p:p.as_posix()) if p.is_file()]
    inputs=dict(pins=PINS,source_files=counts,files=rows,owner_manifest_sha256=sha(HERE/'owner-manifest.json'),
        header_profile='EXPLICIT_VULKAN_HEADERS_v1.4.335_NOT_PUBLISHED_BUILD_REPRODUCTION')
    (workspace/'INPUTS.json').write_text(json.dumps(inputs,indent=2)+'\n',encoding='utf-8',newline='\n')
    return inputs


def verify_inputs(workspace,inputs):
    expected={r['path'] for r in inputs['files']}
    actual={p.relative_to(workspace).as_posix() for p in workspace.rglob('*') if p.is_file() or p.is_symlink()}
    if actual!=expected|{'INPUTS.json'}: raise ValueError('source input set changed')
    for r in inputs['files']:
        p=workspace/r['path']
        if p.is_symlink() or p.stat().st_size!=r['bytes'] or sha(p)!=r['sha256']: raise ValueError('source input bytes changed')


class Tools:
    def execute(self,argv,cwd,log):
        with log.open('w',encoding='utf-8') as f:
            f.write('ARGV='+json.dumps(argv)+'\n');f.flush()
            try:
                code=subprocess.run(argv,cwd=cwd,stdout=f,stderr=subprocess.STDOUT,timeout=600,
                    env=dict(os.environ,LC_ALL='C',PYTHONDONTWRITEBYTECODE='1')).returncode
            except subprocess.TimeoutExpired: code=124;f.write('TIMEOUT\n')
            f.write('\nEXIT='+str(code)+'\n')
        return code

    def capture(self,argv,cwd,name):
        r=subprocess.run(argv,cwd=cwd,capture_output=True,timeout=90)
        (cwd/(name+'.stdout.txt')).write_bytes(r.stdout)
        (cwd/(name+'.stderr.txt')).write_bytes(r.stderr)
        if r.returncode: raise ValueError('tool failed: '+name)
        return r.stdout.decode('utf-8')


def macho(path,kind,minos=None):
    raw=path.read_bytes()
    if len(raw)<32: raise ValueError('truncated Mach-O')
    magic,cpu,_,actual,ncmds,cmdsize,_,_=struct.unpack_from('<8I',raw)
    if (magic,cpu,actual)!=(0xfeedfacf,0x01000007,kind) or cmdsize>len(raw)-32:
        raise ValueError('wrong Mach-O kind/architecture')
    cursor=32;versions=[]
    for _ in range(ncmds):
        if cursor+8>32+cmdsize: raise ValueError('bad Mach-O load command')
        cmd,size=struct.unpack_from('<2I',raw,cursor)
        if size<8 or size%8 or cursor+size>32+cmdsize: raise ValueError('bad Mach-O command size')
        if cmd==0x32:
            if size<24: raise ValueError('truncated build-version command')
            plat,version=struct.unpack_from('<2I',raw,cursor+8)
            if plat!=1: raise ValueError('wrong platform')
            versions.append(version)
        elif cmd==0x24:
            if size<16: raise ValueError('truncated minimum-version command')
            versions.append(struct.unpack_from('<I',raw,cursor+8)[0])
        cursor+=size
    if cursor!=32+cmdsize: raise ValueError('unconsumed Mach-O commands')
    if minos is not None and versions!=[minos]: raise ValueError('wrong/missing deployment version')
    return dict(bytes=len(raw),sha256=sha(path),filetype=kind,minos=versions)


def check_patch_dependencies(label,kind,binding,manifest,workspace):
    if kind!='plugin': raise ValueError('only the complete upstream plugin translation unit is supported')
    if label!='candidate': return []
    snapshot=json.loads(Path(binding['path']).read_text(encoding='utf-8'))
    actual={Path(r['resolved_path']).resolve() for r in snapshot['inputs']}
    expected=manifest['files']
    for row in expected:
        p=workspace/'candidate'/row['path']
        if p.resolve() not in actual or sha(p)!=row['sha256']:
            raise ValueError('patched file absent/wrong in real compiler dependency snapshot: '+row['path'])
    return [r['path'] for r in expected]


def complete(report):
    """Require both real plugin objects and both linked bundles, with no errors."""
    return (not report['errors']
        and len(report['objects'])==2 and len(report['bundles'])==2
        and {r['label'] for r in report['objects']}=={'baseline','candidate'}
        and {r['label'] for r in report['bundles']}=={'baseline','candidate'}
        and all(r['kind']=='plugin' and r['status']=='OBJECT_PASS' for r in report['objects'])
        and all(r['exit']==0 for r in report['bundles'])
        and report.get('bundle_import_delta')==dict(added=[],removed=[]))


def run_gate(workspace,out,tools):
    report=dict(status='FAILED',level='DARWIN_USERLAND_OBJECT_AND_BUNDLE_ONLY',objects=[],bundles=[],errors=[],
        pins=PINS,compiler_failures=0,runtime='NOT_RUN',gpu='NOT_RUN',device='NO_GO',go_authorized=False,
        full_external_resource_lifetime='UNVERIFIED',kernel_pm_callback_stop='NOT_IMPLEMENTED_HERE',
        candidate_profile=HERE.name,
        production_translation_unit='plugin/NVMTLDevice.m includes nvmtl_vk.c and all plugin implementations',
        standalone_c='NOT_AN_UPSTREAM_TRANSLATION_UNIT; first failed probe retained separately')
    try:
        inputs=json.loads((workspace/'INPUTS.json').read_text(encoding='utf-8'))
        verify_inputs(workspace,inputs);before=sha(workspace/'INPUTS.json');report['inputs_sha256']=before
        report['source_files']=inputs['source_files'];report['header_profile']=inputs['header_profile']
        manifest=json.loads((HERE/'owner-manifest.json').read_text(encoding='utf-8'))
        if sha(HERE/'owner-manifest.json')!=inputs['owner_manifest_sha256']: raise ValueError('candidate manifest changed')
        clang=tools.capture(['/usr/bin/xcrun','--find','clang'],out,'clang-path').strip()
        sdk=tools.capture(['/usr/bin/xcrun','--sdk','macosx','--show-sdk-path'],out,'sdk').strip()
        report['compiler']=dict(path=clang,sha256=sha(Path(clang)),version=tools.capture([clang,'--version'],out,'clang-version'))
        report['xcode']=tools.capture(['/usr/bin/xcodebuild','-version'],out,'xcode')
        report['sdk_version']=tools.capture(['/usr/bin/xcrun','--sdk','macosx','--show-sdk-version'],out,'sdk-version').strip()
        if report['sdk_version']!='15.5': raise ValueError('unexpected SDK profile')
        common=['-arch','x86_64','-mmacosx-version-min=15.0','-isysroot',sdk,'-O1','-fblocks',
            '-DNVMTL_RELEASE=1','-Werror=unguarded-availability-new','-I'+str(workspace/'vk/include')]
        imports={}
        for label in ('baseline','candidate'):
            tree=workspace/('nm' if label=='baseline' else label)
            # build_plugin_release.sh compiles one amalgamated Objective-C TU.
            # nvmtl_vk.c relies on preceding ObjC types/static declarations and
            # is not independently compilable C; compile it through the real TU.
            kind,name='plugin','NVMTLDevice.m'
            obj=out/(label+'-'+kind+'.o');stem=obj.stem
            flags=['-fobjc-arc','-Wno-protocol','-Wno-incomplete-implementation']
            argv=[clang,*common,*flags,'-c',str(tree/'plugin'/name),'-o',str(obj)]
            record=dict(label=label,kind=kind,source_sha256=sha(tree/'plugin'/name),status='FAILED')
            report['objects'].append(record)
            try:
                rc,binding,actual=bound_compile(argv,tree,out/(stem+'-compile.txt'),out/(stem+'-deps'),tools.execute)
                record['exit']=rc
                if rc: report['compiler_failures']+=1;raise ValueError(stem+' compile failed')
                record.update(macho(obj,1,15<<16),binding=binding,command=actual)
                record['patched_dependency_files']=check_patch_dependencies(label,kind,binding,manifest,workspace)
                record['status']='OBJECT_PASS'
                undef=tools.capture(['/usr/bin/xcrun','nm','-u','-j',str(obj)],out,stem+'-undefined')
                tools.capture(['/usr/bin/xcrun','nm','-gU',str(obj)],out,stem+'-defined')
                binary=out/(label+'-NVMTLDriver')
                link=[clang,'-arch','x86_64','-mmacosx-version-min=15.0','-isysroot',sdk,'-bundle',str(obj)]
                for framework in FRAMEWORKS: link+=['-framework',framework]
                link+=['-o',str(binary)]
                code=tools.execute(link,out,out/(label+'-link.txt'))
                entry=dict(label=label,exit=code,command=link);report['bundles'].append(entry)
                if code: raise ValueError(label+' bundle link failed')
                entry.update(macho(binary,8,15<<16))
                imports[label]=set(tools.capture(['/usr/bin/xcrun','nm','-u','-j',str(binary)],out,label+'-bundle-undefined').splitlines())
                tools.capture(['/usr/bin/xcrun','otool','-L',str(binary)],out,label+'-libraries')
                tools.capture(['/usr/bin/xcrun','otool','-l',str(binary)],out,label+'-load-commands')
            except (ValueError,OSError,subprocess.SubprocessError) as e: report['errors'].append(str(e))
        if set(imports)=={'baseline','candidate'}:
            report['bundle_import_delta']=dict(added=sorted(imports['candidate']-imports['baseline']),removed=sorted(imports['baseline']-imports['candidate']))
            if report['bundle_import_delta']['added'] or report['bundle_import_delta']['removed']:
                report['errors'].append('unexpected bundle dependency symbol delta')
        verify_inputs(workspace,inputs)
        if sha(workspace/'INPUTS.json')!=before: raise ValueError('input manifest changed during build')
        if complete(report):
            report['status']='USERLAND_OBJECT_AND_BUNDLE_PASS_NOT_GO'
    except (ValueError,OSError,KeyError,TypeError,subprocess.SubprocessError) as e: report['errors'].append(str(e))
    finally:
        (out/'RESULT.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        with zipfile.ZipFile(out/'native-userland-text.zip','x',compression=zipfile.ZIP_DEFLATED) as z:
            for p in out.rglob('*'):
                if p.is_file() and p.suffix in ('.json','.txt','.d'): z.write(p,p.relative_to(out).as_posix())
    return report


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--nm',type=Path,required=True);p.add_argument('--vk',type=Path,required=True)
    p.add_argument('--workspace',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
    p.add_argument('--profile',choices=('owner','migration'),default='owner')
    p.add_argument('--prepare-only',action='store_true');a=p.parse_args()
    if a.profile=='migration': HERE=HERE/'migration'
    a.out.mkdir(parents=True,exist_ok=False)
    try:
        inputs=prepare(a.nm,a.vk,a.workspace)
        (a.out/'PREPARATION.json').write_text(json.dumps({k:v for k,v in inputs.items() if k!='files'},indent=2)+'\n',encoding='utf-8')
    except (ValueError,OSError,KeyError,subprocess.SubprocessError) as e:
        (a.out/'PREPARATION-ERROR.txt').write_text(str(e),encoding='utf-8');raise SystemExit(1)
    if a.prepare_only:
        verify_inputs(a.workspace,inputs);print('SOURCE_INPUTS_VERIFIED_NOT_DARWIN');raise SystemExit(0)
    if platform.system()!='Darwin': raise SystemExit('Darwin required for actual compilation')
    result=run_gate(a.workspace,a.out,Tools());print(json.dumps(result,indent=2))
    raise SystemExit(0 if result['status']=='USERLAND_OBJECT_AND_BUNDLE_PASS_NOT_GO' else 1)
