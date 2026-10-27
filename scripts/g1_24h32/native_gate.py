"""Build two NVAccel objects/kexts locally. Never install, load, or run them."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import platform
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile

from g1_compile_inputs import bound_compile
from import_contract import check_imports


def sha(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda: f.read(1024*1024), b''): h.update(block)
    return h.hexdigest()


def verify(root):
    manifest = json.loads((root/'PACKAGE-MANIFEST.json').read_text(encoding='utf-8'))
    expected = set()
    for row in manifest['files']:
        name = row['path']
        p = PurePosixPath(name)
        if not name or p.is_absolute() or '..' in p.parts or '\\' in name or name in expected:
            raise ValueError('invalid/duplicate package path')
        expected.add(name)
        physical = root/name
        if physical.is_symlink() or not physical.is_file() or not physical.resolve().is_relative_to(root.resolve()):
            raise ValueError('missing/linked package input: '+name)
        if physical.stat().st_size != row['bytes'] or sha(physical) != row['sha256']:
            raise ValueError('package input changed: '+name)
    actual = {p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() or p.is_symlink()}
    if actual != expected | {'PACKAGE-MANIFEST.json'}:
        raise ValueError('unexpected package input')
    return manifest


class NativeTools:
    def __init__(self, out):
        self.out = out
        self.calls = []

    def execute(self, argv, cwd, log):
        self.calls.append(argv)
        with log.open('w', encoding='utf-8') as f:
            f.write('ARGV='+json.dumps(argv)+'\n'); f.flush()
            try:
                run = subprocess.run(argv, cwd=cwd, stdout=f, stderr=subprocess.STDOUT, timeout=300,
                                     env=dict(os.environ, LC_ALL='C', PYTHONDONTWRITEBYTECODE='1'))
                rc = run.returncode
            except subprocess.TimeoutExpired:
                f.write('\nTIMEOUT\n'); rc = 124
            f.write('\nEXIT='+str(rc)+'\n')
        return rc

    def capture(self, argv, cwd, name):
        run = subprocess.run(argv, cwd=cwd, capture_output=True, timeout=60)
        (self.out/(name+'.stdout.txt')).write_bytes(run.stdout)
        (self.out/(name+'.stderr.txt')).write_bytes(run.stderr)
        if run.returncode:
            raise ValueError('native tool failed: '+name)
        return run.stdout.decode('utf-8').strip()


# Historical R3 list retained for profile-difference provenance only.
# Compilation below exclusively uses PROFILE.json's make-derived and explicit extra lists.
NV_INCLUDES = [
    'src/nvidia/arch/nvalloc/unix/include', 'src/nvidia/arch/nvalloc/common/inc',
    'src/nvidia/arch/nvalloc/common/inc/gsp', 'src/common/sdk/nvidia/inc', 'src/common/sdk/nvidia/inc/hw',
    'src/common/inc', 'src/common/shared/inc', 'src/nvidia/inc', 'src/nvidia/inc/os',
    'src/nvidia/inc/kernel', 'src/nvidia/kernel/inc', 'src/nvidia/interface',
    'src/common/nvlink/interface', 'src/common/inc/swref', 'src/common/inc/swref/published',
    'src/nvidia/inc/libraries', 'src/nvidia/src/libraries', 'src/nvidia/generated',
    'src/nvidia/src/mm/uvm/interface', 'src/common/uproc/os/libos-v2.0.0/include',
    'src/common/uproc/os/common/include', 'src/common/inc/displayport', 'src/common/nvlink/inband/interface',
    'src/nvidia-modeset/os-interface/include', 'src/nvidia-modeset/kapi/interface',
    'src/nvidia-modeset/kapi/include', 'src/common/unix/nvidia-push/interface',
    'src/nvidia-modeset/interface', 'src/nvidia-modeset/include', 'src/common/unix/common/inc',
    'src/common/modeset', 'src/common/unix/common/utils/interface']


def validate_macho(path, kind):
    raw = path.read_bytes()
    if len(raw) < 32 or struct.unpack_from('<II', raw) != (0xfeedfacf, 0x01000007) or struct.unpack_from('<I', raw, 12)[0] != kind:
        raise ValueError('invalid x86_64 Mach-O output: '+str(path))
    return dict(path=str(path), bytes=len(raw), sha256=sha(path), filetype=kind)


def imports(text):
    rows = [line.strip() for line in text.splitlines() if line.strip()]
    if any(not r.startswith('_') or any(c.isspace() for c in r) for r in rows):
        raise ValueError('unexpected nm -uj output')
    return set(rows)


def run_gate(package, out, tools):
    """Internal orchestration; injected tools are only used by labelled host tests."""
    report = dict(status='FAILED', level='DARWIN_OBJECT_AND_LINK_ONLY', objects=[], links=[], errors=[],
                  compiler_failures=0, missing=None, full_abi='UNVERIFIED', loader='UNVERIFIED',
                  safety_implementation='SEPARATE_CANDIDATE_NOT_COMPILED_HERE', gpu='NOT_RUN', go_authorized=False)
    manifest_digest = None
    try:
        manifest = verify(package)
        manifest_digest = sha(package/'PACKAGE-MANIFEST.json')
        report['package_manifest_sha256'] = manifest_digest
        profile = json.loads((package/'PROFILE.json').read_text(encoding='utf-8'))
        proof = json.loads((package/'route-proof.json').read_text(encoding='utf-8'))
        contract = json.loads((package/'target-symbols.json').read_text(encoding='utf-8'))
        cm = json.loads((package/'forwarder-candidate/MANIFEST.json').read_text(encoding='utf-8'))
        if sha(package/'target-symbols.json') != cm['target_symbol_contract_sha256']:
            raise ValueError('target import contract binding failed')
        sdk = Path(tools.capture(['/usr/bin/xcrun', '--sdk', 'macosx', '--show-sdk-path'], out, 'sdk'))
        khdr = sdk/'System/Library/Frameworks/Kernel.framework/Headers'
        if not (khdr/'IOKit/IOService.h').is_file():
            report['missing'] = 1; raise ValueError('Kernel SDK headers missing')
        clang = Path(tools.capture(['/usr/bin/xcrun', '--find', 'clang++'], out, 'compiler-path'))
        report['compiler'] = dict(path=str(clang), sha256=sha(clang), version=tools.capture([str(clang), '--version'], out, 'compiler-version'))
        report['xcode'] = tools.capture(['/usr/bin/xcodebuild', '-version'], out, 'xcode')
        report['sdk'] = dict(path=str(sdk), version=tools.capture(['/usr/bin/xcrun', '--sdk', 'macosx', '--show-sdk-version'], out, 'sdk-version'))
        baseline = package/'inputs/nm'
        candidate = out/'candidate'
        shutil.copytree(baseline, candidate)
        for row in cm['files']:
            source = package/'forwarder-candidate/src'/row['path']
            if sha(source) != row['sha256']:
                raise ValueError('forwarder source binding failed')
            target = candidate/row['path']; target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
        nv = package/'inputs/ogkm'
        definitions = profile['rm_definitions']
        if not definitions or any(not d.startswith('-D') or '\n' in d or 'NM_TAHOE' in d or 'NM_SEQUOIA' in d for d in definitions):
            raise ValueError('invalid explicit reconstruction profile')
        if any(d.split('=')[0]=='-DNV_LINUX' for d in definitions):
            raise ValueError('Darwin profile must not inject NV_LINUX')
        include_names=profile['rm_include_dirs']+profile['nvaccel_extra_include_dirs']
        if not include_names or len(include_names)!=len(set(include_names)):
            raise ValueError('missing/duplicate declared profile include dirs')
        for name in include_names:
            rel=PurePosixPath(name)
            if rel.is_absolute() or '..' in rel.parts or '\\' in name:
                raise ValueError('unsafe profile include path')
        absent=sorted(name for name in include_names if not (nv/name).is_dir())
        if absent!=sorted(profile['make_include_directories_absent']):
            raise ValueError('profile include-directory existence differs from pinned source')
        report['include_directories_absent_as_in_make']=absent
        report['profile'] = profile
        base_flags = ['-arch','x86_64','-mmacosx-version-min=15.5','-isysroot',str(sdk),
                      '-fapple-kext','-mkernel','-nostdinc','-I'+str(khdr),
                      '-DKERNEL','-DKERNEL_PRIVATE','-DDRIVER_PRIVATE','-DAPPLE','-DNeXT',*definitions,
                      '-std=c++17','-fno-rtti','-fno-exceptions','-fno-builtin','-fno-common','-O2',
                      '-Wall','-Wno-unused-parameter','-Wno-inconsistent-missing-override','-Wno-unused-function',
                      '-Xclang','-fdump-record-layouts']
        nm_imports = {}
        for label, tree in [('baseline',baseline), ('candidate',candidate)]:
            obj = out/(label+'.o')
            source = tree/'kexts/NVRM/accel/nvrm-accel.cpp'
            inc = [nv/p for p in include_names]+[tree/'kexts/NVRM', source.parent, source.parent/'iofam', source.parent/'re']
            flags = [*base_flags,*['-I'+str(p) for p in inc]]
            if label == 'candidate': flags.append('-DNM_SEQUOIA_24H32_FWD=1')
            if label == 'baseline':
                macros=tools.capture([str(clang),*flags,'-dM','-E',str(source)],out,'darwin-macros')
                lines=set(macros.splitlines())
                if '#define NVOS_IS_LINUX 0' not in lines or any(s.startswith('#define NV_LINUX ') for s in lines):
                    raise ValueError('actual Darwin preprocessing still selects Linux OS')
                report['darwin_macro_check']=dict(NVOS_IS_LINUX=0,NV_LINUX_defined=False)
            argv = [str(clang),*flags,'-c',str(source),'-o',str(obj)]
            record = dict(label=label, source_sha256=sha(source), command=argv, status='FAILED')
            report['objects'].append(record)
            try:
                rc, binding, actual = bound_compile(argv, tree, out/(label+'-compile.txt'), out/(label+'-deps'), tools.execute)
                record['exit'] = rc
                if rc:
                    report['compiler_failures'] += 1; raise ValueError(label+' compile failed')
                record.update(validate_macho(obj,1)); record.update(binding=binding, command=actual, status='OBJECT_ONLY')
                text = tools.capture(['/usr/bin/xcrun','nm','-u','-j',str(obj)],out,label+'-undefined')
                nm_imports[label] = imports(text)
                tools.capture(['/usr/bin/xcrun','nm','-gU',str(obj)],out,label+'-defined')
                tools.capture(['/usr/bin/xcrun','otool','-rv',str(obj)],out,label+'-relocations')
                binary = out/(label+'-NVAccel')
                link = [str(clang),'-arch','x86_64','-mmacosx-version-min=15.5','-isysroot',str(sdk),
                        '-fapple-kext','-nostdlib','-Xlinker','-kext','-lkmodc++','-lkmod','-lcc_kext',str(obj),'-o',str(binary)]
                rc = tools.execute(link,out,out/(label+'-link.txt'))
                entry = dict(label=label,command=link,exit=rc); report['links'].append(entry)
                if rc: raise ValueError(label+' link failed')
                entry.update(validate_macho(binary,11))
                tools.capture(['/usr/bin/xcrun','otool','-l',str(binary)],out,label+'-load-commands')
                linked=imports(tools.capture(['/usr/bin/xcrun','nm','-u','-j',str(binary)],out,label+'-linked-undefined'))
                if linked!=nm_imports[label]: raise ValueError('linked/object import set differs: '+label)
            except (ValueError, OSError) as e:
                report['errors'].append(str(e))
        if set(nm_imports) == {'baseline','candidate'}:
            methods = {r['symbol'] for r in proof['routes']}
            added = nm_imports['candidate']-nm_imports['baseline']
            removed = nm_imports['baseline']-nm_imports['candidate']
            provider_names = {r['symbol'] for r in proof['vtables'].values() if r['external_section_observed']}
            provider_names |= set(contract['enum_renames'].values())
            report['target_import_observation']=check_imports(nm_imports['candidate'],contract)
            if not report['target_import_observation']['passed']:
                report['errors'].append('complete candidate import-name observation failed')
            report['import_delta'] = dict(added=sorted(added),removed=sorted(removed),
                methods_still_undefined=sorted(methods & nm_imports['candidate']),
                added_without_source_provider_observation=sorted(added-provider_names),
                target_collection_sha256=proof['collection_sha256'],provider_level='STATIC_OBSERVATION_NOT_LOADER')
            if methods & nm_imports['candidate'] or added-provider_names:
                report['errors'].append('unexpected/remaining candidate imports')
        else: report['errors'].append('both actual import sets required')
        verify(package)
        if sha(package/'PACKAGE-MANIFEST.json') != manifest_digest:
            raise ValueError('package manifest changed during run')
        if not report['errors'] and len(report['links']) == 2 and all(r['exit']==0 for r in report['links']):
            report['missing'] = 0
            report['status'] = 'OBJECT_LINK_AND_IMPORT_DELTA_PASS_NOT_GO'
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as e:
        report['errors'].append(str(e))
    finally:
        (out/'RESULT.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        # Text evidence is returned even on failure. Driver objects/binaries stay local.
        archive = out/'native-build-result.zip'
        with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED) as z:
            for p in out.rglob('*'):
                if p.is_file() and p.suffix in ('.txt','.json','.d') and 'candidate' not in p.relative_to(out).parts:
                    z.write(p,p.relative_to(out).as_posix())
    return report


def main():
    for stream in (sys.stdout, sys.stderr):
        try: stream.reconfigure(encoding='utf-8', errors='replace')
        except (AttributeError, OSError): pass
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify',action='store_true')
    parser.add_argument('--output-parent',type=Path)
    args = parser.parse_args()
    package=Path(__file__).resolve().parent
    if args.verify:
        verify(package); print('PACKAGE VERIFIED'); return 0
    if platform.system() != 'Darwin' or os.geteuid() == 0:
        raise SystemExit('STOP: run on macOS as an ordinary user; do not sudo')
    out=Path(tempfile.mkdtemp(prefix='G1-NATIVE-BUILD-',dir=args.output_parent or Path.home()/'Desktop'))
    report=run_gate(package,out,NativeTools(out))
    print('STATUS:',report['status']); print('RESULT ZIP:',out/'native-build-result.zip')
    return 0 if report['status']=='OBJECT_LINK_AND_IMPORT_DELTA_PASS_NOT_GO' else 1


if __name__=='__main__':
    sys.dont_write_bytecode=True
    raise SystemExit(main())
