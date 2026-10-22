#!/usr/bin/env python3
"""Python >=3.9 offline compile/link entry. No deletion, network, install or load."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[2]
NM_PIN = '272ccd9da04ff5de95c2791b902fe17a3fa77ce7'
NV_PIN = 'e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb'
# Existing staged GNU make archive, rehashed 2026-10-22. Not downloaded by this tool.
MAKE_SHA = 'dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3'
ENTRY_FILES = ('research/stock-v243-offscreen-20261021/g1-first-touch.command',
               'research/stock-v243-offscreen-20261021/device-kextutil.sh',
               'research/stock-v243-offscreen-20261021/first-touch.sh')
MARKER = '.g1-offline-work.json'


def save(path, value):
    with Path(path).open('w', encoding='utf-8', newline='\n') as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n')


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def command(argv, cwd=None, env=None):
    result = subprocess.run(list(map(str, argv)), cwd=cwd, env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
    if result.returncode:
        raise ValueError('command failed (%d): %s :: %s' %
                         (result.returncode, argv[0], result.stderr.decode('utf-8', 'replace')[:300]))
    return result.stdout.decode('utf-8', 'strict').strip()


def git(root, *args):
    # Trust exactly this directory; never grant safe.directory=* or change persistent config.
    env = {k:v for k,v in os.environ.items() if not k.startswith('GIT_')}
    env.update(GIT_TERMINAL_PROMPT='0', GIT_CONFIG_NOSYSTEM='1')
    return command(['git', '-c', 'safe.directory='+str(root), '-c', 'core.fsmonitor=false',
                    '-C', root, *args], env=env)


def source(root, expected, metadata_ok=False):
    root = Path(root).resolve(strict=True)
    if not (root/'.git').is_dir() or (root/'.git').is_symlink():
        raise ValueError('ordinary self-contained Git checkout required: '+str(root))
    if (root/'.git/objects/info/alternates').exists():
        raise ValueError('external Git object store not supported')
    if not re.fullmatch('[0-9a-f]{40}', expected or ''):
        raise ValueError('explicit full expected repo commit required (G1_EXPECTED_COMMIT)')
    head = git(root, 'rev-parse', 'HEAD')
    if head != expected:
        raise ValueError('commit mismatch: '+head+' expected '+expected)
    status = git(root, 'status', '--porcelain', '--untracked-files=all')
    dirty = []
    for line in status.splitlines():
        # Finder files may be ignored only when UNTRACKED; changed tracked data is never excused.
        base = PurePosixPath(line[3:]).name
        if metadata_ok and line.startswith('?? ') and (base == '.DS_Store' or base.startswith('._')):
            continue
        dirty.append(line)
    if dirty:
        raise ValueError('dirty source: '+str(root)+' :: '+str(dirty[:3]))
    return dict(path=str(root), commit=head)


def workspace(work, inputs):
    original = Path(work).expanduser().absolute()
    if original.is_symlink():
        raise ValueError('WORK may not be a symlink')
    work = original.resolve()
    protected = (Path(work.anchor), Path.home().resolve(), (Path.home()/'Desktop').resolve(),
                 Path('/System'), Path('/Library'), Path('/Applications'), Path('/Volumes'))
    if work in protected:
        raise ValueError('WORK is not a dedicated workspace')
    for item in inputs:
        item = Path(item).resolve()
        if work == item or work in item.parents or item in work.parents:
            raise ValueError('WORK overlaps an input: '+str(item))
    marker = work/MARKER
    if work.exists():
        if not work.is_dir():
            raise ValueError('WORK is not a directory')
        if marker.is_symlink() or not marker.is_file():
            raise ValueError('existing WORK lacks managed marker; choose a new empty path')
        data = json.loads(marker.read_text(encoding='utf-8'))
        if data != dict(schema=1, purpose='G1_OFFLINE_BUILD', root=str(work)):
            raise ValueError('managed WORK identity differs')
    return work


def archive(path, expected=MAKE_SHA, snapshot=False):
    path = Path(path).resolve(strict=True)
    raw=path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected:
        raise ValueError('GNU make archive SHA256 mismatch')
    with tarfile.open(fileobj=io.BytesIO(raw), mode='r:gz') as tar:
        names = set()
        for member in tar.getmembers():
            parts = PurePosixPath(member.name).parts
            if (not parts or parts[0] != 'make-4.4.1' or '..' in parts or
                '\\' in member.name or not (member.isfile() or member.isdir()) or
                member.name in names):
                raise ValueError('unsafe GNU make archive member: '+member.name)
            names.add(member.name)
    return raw if snapshot else path


def make_version(path, query=command):
    text = query([str(path), '--version'])
    first = text.splitlines()[0] if text else ''
    if not re.fullmatch(r'GNU Make 4\.\d+(?:\.\d+)?', first):
        raise ValueError('real GNU Make 4 required: '+first)
    return first


def preflight(args, query=command):
    """Stable check IDs; command failures remain failures, even when stdout is empty."""
    rows = []
    def check(key, action):
        try:
            value = action()
            rows.append(dict(id=key, status='PASS', detail=value))
            return value
        except Exception as error:
            rows.append(dict(id=key, status='FAIL', error=str(error)))
            return None
    def equal(actual, expected):
        if actual != expected:
            raise ValueError('expected %s, got %s' % (expected, actual))
        return actual
    def nonempty(value):
        if not value:
            raise ValueError('required tool returned empty identity')
        return value
    check('host-os', lambda:equal(query(['uname','-s']), 'Darwin'))
    check('host-arch', lambda:equal(query(['uname','-m']), 'x86_64'))
    check('python', lambda:equal(sys.version_info >= (3,9), True))
    def developer():
        selected=nonempty(query(['xcode-select','-p']))
        sdk=Path(nonempty(query(['xcrun','--show-sdk-path'])))
        if not (sdk/'System/Library/Frameworks/Kernel.framework/Headers/IOKit/IOService.h').is_file():
            raise ValueError('selected SDK lacks Kernel.framework/Headers/IOKit/IOService.h')
        return dict(developer=selected,sdk=str(sdk))
    check('developer-tools', developer)
    check('sdk', lambda:equal(query(['xcrun','--show-sdk-version']), '15.5'))
    check('clang', lambda:nonempty(query(['xcrun','clang','--version'])))
    check('repository', lambda:source(args.repo, args.expected_commit))
    check('nullmoth', lambda:source(args.nm, NM_PIN, True))
    check('ogkm', lambda:source(args.nv, NV_PIN, True))
    def endings():
        for name in ENTRY_FILES:
            if b'\r' in (Path(args.repo)/name).read_bytes():
                raise ValueError('CRLF entry rejected; obtain an LF checkout: '+name)
        return list(ENTRY_FILES)
    check('shell-lf', endings)
    def assets():
        sys.path.insert(0, str(Path(args.repo)/'scripts/g1'))
        from stock_v243_once_native import validate_lock
        path = Path(args.repo)/'research/stock-v243-once-20261021'
        validate_lock(json.loads((path/'source-lock.json').read_text(encoding='utf-8')), path)
        enum_path=Path(args.repo)/'research/stock-v243-offscreen-20261021'
        lock=json.loads((enum_path/'iofam-lock.json').read_text(encoding='utf-8'))
        equal(sha(enum_path/'iofam-enum-types.patch'), lock['sha256'])
        return 'candidate patches match locks'
    check('assets', assets)
    def make():
        for name in ('gmake','make'):
            path = shutil.which(name)
            if path:
                try:
                    return dict(binary=path, version=make_version(path,query), sha256=sha(path))
                except ValueError:
                    pass
        path=archive(args.make_archive)
        # System make is permitted only to bootstrap the verified GNU source, never as gmake.
        query(['make','--version'])
        return dict(archive=str(path), sha256=sha(path))
    selected=check('gnu-make', make)
    work=check('workspace', lambda:str(workspace(args.work, (args.repo,args.nm,args.nv))))
    def disk():
        path=Path(work) if work else Path(args.work).resolve()
        while not path.exists():path=path.parent
        # No shell parsing and no empty/non-numeric df fallback.
        free=shutil.disk_usage(path).free
        if not isinstance(free,int) or free < args.min_free_bytes:
            raise ValueError('insufficient free bytes: '+str(free))
        return free
    check('disk-space', disk)
    return dict(status='PASS' if all(r['status']=='PASS' for r in rows) else 'FAILED',
        checks=rows, check_count=len(rows), selected_make=selected, repo_commit=args.expected_commit,
        python=sys.version, entry_sha256=sha(Path(__file__)), device='NO_GO', gpu='NOT_RUN')


def logged(argv, cwd, log, env=None):
    with Path(log).open('w', encoding='utf-8', newline='\n') as stream:
        stream.write('ARGV='+json.dumps(list(map(str,argv)))+'\n');stream.flush()
        result=subprocess.run(list(map(str,argv)),cwd=cwd,env=env,stdout=stream,
                              stderr=subprocess.STDOUT)
        stream.write('\nEXIT='+str(result.returncode)+'\n')
    if result.returncode:
        raise ValueError('build command failed: '+str(log))


def build(args, query=command, pipeline=None):
    # Both menu and direct shell invocation reach this unconditional gate.
    report=preflight(args,query)
    if report['status'] != 'PASS':
        return report
    work=workspace(args.work,(args.repo,args.nm,args.nv))
    if not work.exists():
        work.mkdir(parents=True,exist_ok=False)
        save(work/MARKER,dict(schema=1,purpose='G1_OFFLINE_BUILD',root=str(work)))
    # Never rm/rmtree old data. Every attempt owns an exclusive new directory.
    session=Path(tempfile.mkdtemp(prefix='run-',dir=str(work)))
    report.update(stage='copy-inputs',session=str(session),status='FAILED')
    save(session/'build-report.json',report)
    try:
        for name,original,pin in (('nm',args.nm,NM_PIN),('nv',args.nv,NV_PIN)):
            source(original,pin,True)
            dest=session/name
            shutil.copytree(original,dest,symlinks=True,ignore=shutil.ignore_patterns('.DS_Store','._*'))
            # Allow Finder metadata only in original; copied inputs must be completely clean.
            source(dest,pin)
        source(args.repo,args.expected_commit)
        env=dict(os.environ, GIT_TERMINAL_PROMPT='0')
        selected=report['selected_make']
        if 'archive' in selected:
            report['stage']='gnu-make-bootstrap'
            raw=archive(selected['archive'],snapshot=True)
            tools=session/'tools';tools.mkdir()
            with tarfile.open(fileobj=io.BytesIO(raw),mode='r:gz') as tar:tar.extractall(tools)
            tree=tools/'make-4.4.1'
            logged(['./configure','--prefix='+str(tools/'installed')],tree,session/'make-configure.txt')
            logged(['make','-j4'],tree,session/'make-build.txt')
            binary=tree/'make'
        else:
            binary=Path(selected['binary'])
            if sha(binary)!=selected['sha256']:raise ValueError('GNU make changed after preflight')
        make_version(binary)
        # This shim points exclusively at a verified GNU Make 4 binary.
        bin_dir=session/'bin';bin_dir.mkdir();(bin_dir/'gmake').symlink_to(binary.resolve())
        env['PATH']=str(bin_dir)+os.pathsep+env.get('PATH','')
        env['GITHUB_SHA']=args.expected_commit
        report['stage']='native-pipeline'
        if pipeline is not None:
            # Tests inject only the expensive pipeline, after real gate and copy checks.
            pipeline(session,env)
            report.update(status='PASS_ORCHESTRATION_FIXTURE_NO_NATIVE_BUILD',stage='complete')
        else:
            common=[sys.executable,str(Path(args.repo)/'scripts/g1')]
            logged([common[0],Path(common[1])/'stock_v243_internal_link.py',
                '--nm',session/'nm','--nv',session/'nv',
                '--assets',Path(args.repo)/'research/stock-v243-once-20261021',
                '--out',session/'internal-text','--work',session/'internal-products'],args.repo,session/'internal.txt',env)
            logged([common[0],Path(common[1])/'stock_v243_package.py',
                '--internal-text',session/'internal-text','--work',session/'internal-products',
                '--out',session/'package-text'],args.repo,session/'package.txt',env)
            from stock_v243_package import accepted_status
            package=json.loads((session/'package-text/package-report.json').read_text(encoding='utf-8'))
            if (not accepted_status(package['status']) or package['commit']!=args.expected_commit or
                set(package['bundles'])!={'NVRM','NVRMFB','NVAccel'}):
                raise ValueError('package verdict or commit binding differs')
            report['artifacts']={}
            for name,record in package['bundles'].items():
                bundle=session/'internal-products/package-products'/(name+'.kext')/'Contents'
                executable=bundle/'MacOS'/name
                if sha(executable)!=record['sha256'] or sha(bundle/'Info.plist')!=record['plist_sha256']:
                    raise ValueError('package output changed: '+name)
                report['artifacts'][name]=dict(sha256=record['sha256'],plist_sha256=record['plist_sha256'])
            report['package_report_sha256']=sha(session/'package-text/package-report.json')
            report.update(status='PASS_COMPILE_LINK_ONLY_NOT_LOAD_OR_GPU',stage='complete')
    except Exception as error:
        report['error']=str(error)
    finally:
        save(session/'build-report.json',report)
    return report


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('action',choices=('preflight','build'))
    p.add_argument('--repo',type=Path,default=ROOT)
    p.add_argument('--expected-commit',default=os.environ.get('G1_EXPECTED_COMMIT',''))
    p.add_argument('--nm',type=Path,default=os.environ.get('NM_SRC','/nonexistent/nm'))
    p.add_argument('--nv',type=Path,default=os.environ.get('NV_SRC','/nonexistent/nv'))
    p.add_argument('--make-archive',type=Path,default=Path(os.environ.get('G1_TOOLS','/nonexistent'))/'make-4.4.1.tar.gz')
    p.add_argument('--work',type=Path,default=Path(os.environ.get('WORK',str(Path.home()/'Desktop/g1-kextutil'))))
    p.add_argument('--min-free-bytes',type=int,default=8*1024**3,help=argparse.SUPPRESS)
    args=p.parse_args()
    args.repo=args.repo.resolve()
    args.nm=args.nm.resolve()
    args.nv=args.nv.resolve()
    if args.repo.resolve() != ROOT:
        p.error('--repo must be the checkout containing this entry point')
    # Space is a real mandatory precondition; callers cannot waive it via CLI.
    args.min_free_bytes=max(args.min_free_bytes,8*1024**3)
    result=preflight(args) if args.action=='preflight' else build(args)
    print(json.dumps(result,indent=2))
    return 0 if result['status'] in ('PASS','PASS_COMPILE_LINK_ONLY_NOT_LOAD_OR_GPU') else 2


if __name__=='__main__':
    raise SystemExit(main())
