"""Bind selected native objects to compiler-discovered transitive file inputs.

Pre/post hashes detect persistent drift, not adversarial change-and-restore
during a compiler read. Compiler binaries, environment and directory negative
lookups are outside this file-content contract. No input files are modified.
"""
import hashlib
import json
from pathlib import Path

BOUND_RM = {
    'src/nvidia/arch/nvalloc/unix/src/unix_intr.c',
    'src/nvidia/arch/nvalloc/unix/src/osapi.c',
    'src/nvidia/arch/nvalloc/unix/src/dynamic-power.c',
}
TARGET = 'honor_g1_inputs'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def absolute(path, cwd):
    # Keep the compiler's logical spelling (including ..). Collapsing .. before
    # resolving symlink parents can change which actual file a path denotes.
    # file_inputs records the separately canonicalized physical identity.
    return path if path.is_absolute() else cwd/path


def dep_paths(text, cwd):
    text = text.replace('\\\r\n', '').replace('\\\n', '').strip()
    prefix = TARGET+':'
    if not text.startswith(prefix) or '\n' in text or '\r' in text:
        raise ValueError('expected one explicit compiler dependency rule')
    tokens, current, i = [], '', len(prefix)
    while i < len(text):
        char = text[i]
        if char == '\\':
            i += 1
            if i == len(text): raise ValueError('truncated dependency escape')
            current += text[i]
        elif char == '$':
            if text[i:i+2] != '$$': raise ValueError('dependency variable expansion forbidden')
            current += '$'
            i += 1
        elif char.isspace():
            if current: tokens.append(current); current = ''
        elif char == '#':
            raise ValueError('unescaped dependency comment')
        else: current += char
        i += 1
    if current: tokens.append(current)
    paths = [absolute(Path(x), cwd) for x in tokens]
    if not paths:
        raise ValueError('empty dependency paths')
    # Make prerequisites are a set. Identical logical paths may repeat; retain
    # distinct spellings (especially .. through symlink parents) separately.
    return sorted(set(paths), key=str)


def file_inputs(paths):
    return [{'path':str(p), 'resolved_path':str(p.resolve(strict=True)),
             'sha256':sha(p)} for p in paths]


def check_inputs(records):
    if not records or len({r['path'] for r in records}) != len(records):
        raise ValueError('missing/duplicate dependency snapshot paths')
    for row in records:
        path = Path(row['path'])
        if (not path.is_absolute() or str(absolute(path, Path.cwd())) != str(path)
                or str(path.resolve(strict=True)) != row['resolved_path']
                or sha(path) != row['sha256']):
            raise ValueError('transitive input changed: '+str(path))


def command_with_dependencies(argv, depfile):
    if argv.count('-c') != 1 or argv.count('-o') != 1 or argv[-2] != '-o':
        raise ValueError('expected a single direct compile action')
    if any(v.startswith(('-MF','-MT','-MQ','-MJ','-Wp,','@')) or v in ('-M','-MM','-MD','-MMD','-MP','-MG') for v in argv):
        raise ValueError('unreviewed prior dependency/preprocessor action')
    ci = argv.index('-c')
    return [*argv[:ci], '-MD', '-MF', str(depfile), '-MT', TARGET, *argv[ci:]]


def bound_compile(argv, cwd, log, directory, execute):
    """Scan/hash before, compile with -MD, compare exact paths/hash after."""
    cwd, directory = cwd.resolve(), directory.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    source = absolute(Path(argv[argv.index('-c')+1]), cwd)
    obj = absolute(Path(argv[-1]), cwd)
    stem = obj.stem
    before_dep, actual_dep = directory/(stem+'-before.d'), directory/(stem+'.d')
    snapshot = directory/(stem+'.json')
    if any(p.exists() for p in [obj, before_dep, actual_dep, snapshot]):
        raise ValueError('fresh object/dependency outputs required')
    actual = command_with_dependencies(argv, actual_dep)
    ci, oi = argv.index('-c'), argv.index('-o')
    scan = [v for i,v in enumerate(argv) if i not in {ci,ci+1,oi,oi+1}]
    scan += ['-M', '-MF', str(before_dep), '-MT', TARGET, str(source)]
    if execute(scan, cwd, directory/(stem+'-scan.txt')):
        raise ValueError('precompile dependency discovery failed: '+str(source))
    paths = dep_paths(before_dep.read_text(encoding='utf-8'), cwd)
    if source not in paths: raise ValueError('source absent from dependency rule')
    before = file_inputs(paths)
    rc = execute(actual, cwd, log)
    if rc: return rc, None, actual
    after_paths = dep_paths(actual_dep.read_text(encoding='utf-8'), cwd)
    if after_paths != paths or file_inputs(after_paths) != before:
        raise ValueError('compiler input set/content changed during object compilation')
    record = {'schema':'honor.g1.compile-inputs.v1', 'source':str(source.resolve()), 'object':str(obj.resolve()),
        'object_sha256':sha(obj), 'cwd':str(cwd), 'compile_argv':actual, 'inputs':before,
        'depfiles':[{'path':str(p), 'sha256':sha(p)} for p in [before_dep,actual_dep]],
        'limitations':['pre/post content equality does not detect adversarial mutate-and-restore',
            'compiler binaries, environment and negative include lookups not captured']}
    snapshot.write_text(json.dumps(record, indent=2)+'\n', encoding='utf-8')
    return 0, {'path':str(snapshot), 'sha256':sha(snapshot), 'files':len(before)}, actual


def verify_snapshot(descriptor, directory, source, obj, object_sha256, argv=None):
    path = directory.resolve()/(obj.stem+'.json')
    if (not isinstance(descriptor, dict) or descriptor.get('path') != str(path)
            or path.is_symlink() or sha(path) != descriptor.get('sha256')):
        raise ValueError('missing/wrong current-run dependency snapshot')
    record = json.loads(path.read_text(encoding='utf-8'))
    if (record.get('schema') != 'honor.g1.compile-inputs.v1'
            or record['source'] != str(source.resolve()) or record['object'] != str(obj.resolve())
            or record['object_sha256'] != object_sha256
            or len(record['inputs']) != descriptor['files']
            or (argv is not None and record['compile_argv'] != argv)):
        raise ValueError('dependency snapshot object/source/command mismatch')
    cwd = Path(record['cwd'])
    if not cwd.is_absolute(): raise ValueError('absolute compile cwd required')
    expected_depfiles = [directory.resolve()/(obj.stem+'-before.d'), directory.resolve()/(obj.stem+'.d')]
    if [r['path'] for r in record['depfiles']] != list(map(str, expected_depfiles)):
        raise ValueError('current-run dependency files required')
    for entry in record['depfiles']:
        dep = Path(entry['path'])
        if dep.is_symlink() or sha(dep) != entry['sha256']:
            raise ValueError('dependency rule changed')
        if list(map(str, dep_paths(dep.read_text(encoding='utf-8'), cwd))) != [r['path'] for r in record['inputs']]:
            raise ValueError('dependency file/snapshot set mismatch')
    if str(source.resolve()) not in [r['resolved_path'] for r in record['inputs']]:
        raise ValueError('source missing from input snapshot')
    check_inputs(record['inputs'])
    return record


def verify_diagnostic_dependencies(path, cwd, record, wrapper):
    check_inputs(record['inputs'])
    expected = sorted([*[r['path'] for r in record['inputs']], str(wrapper.resolve())])
    if list(map(str, dep_paths(path.read_text(encoding='utf-8'), cwd))) != expected:
        raise ValueError('diagnostic dependency set differs from actual object plus wrapper')
