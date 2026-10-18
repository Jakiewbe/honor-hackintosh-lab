#!/usr/bin/env python3
"""Observe selected RM shared-record layouts under the real recorded TU flags.

Diagnostic wrappers include the complete unchanged input source and append an
LLVM-only constant table. Nothing here is linked, loaded or executed as a driver.
Layout equality is necessary evidence, not full ABI or runtime acceptance.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

from g1_dependency_audit import balanced, definitions, mask, no_directives, OGKM_PIN

RM_SOURCES = [
    'src/nvidia/arch/nvalloc/unix/src/unix_intr.c',
    'src/nvidia/arch/nvalloc/unix/src/osapi.c',
    'src/nvidia/arch/nvalloc/unix/src/dynamic-power.c',
]
CPP_PROFILES = [
    ('uni-NVRM_cpp', 'kexts/NVRM/NVRM.cpp'),
    ('uni-os-nvkms-xnu_cpp', 'kexts/NVRM/os-nvkms-xnu.cpp'),
    ('uni-os-xnu2_cpp', 'kexts/NVRM/os-xnu2.cpp'),
]
# Explicit partial field contract. Unlisted fields and nested layouts remain open.
FIELDS = {
    'nv_state_t': ['priv','os_state','flags','pci_info','subsystem_id','subsystem_vendor',
        'gpu_id','iovaspace_id','nv_uuid_cache','handle','pci_cfg_space','bars','regs','fb',
        'event_list','event_spinlock','kern_mappings','dma_dev','queue','request_firmware',
        'rmapi','cached_gpu_info','is_pm_unsupported','is_cxl_dev'],
    'nvidia_stack_t': ['size','top','stack'],
    'nv_file_private_t': ['handles','maxHandles','deviceInstance','gpuInstanceId','metadata',
        'ctl_nvfp','ctl_nvfp_priv','register_or_refcount','event_posting_refcount','bCleanupRmapi'],
    'nv_aperture_t': ['cpu_address','size','offset','map','map_u'],
    'nv_pci_info_t': [],
}
SELECTORS = ['__use_altstack__','QA_BUILD','NVCPU_X86_64','NVRM','NV_UNIX','NV_LINUX',
    'NV_MACINTOSH','NV_MACINTOSH_OSX','__APPLE__','__MACH__','__cplusplus',
    'NV_KERNEL_INTERFACE_LAYER','PORT_ATOMIC','NV_API_CALL','NV_ENTER_RM_RUNTIME','NV_EXIT_RM_RUNTIME']
TABLE = 'honor_g1_rm_layout_diagnostic'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def layout_expressions():
    result = []
    for typ, fields in FIELDS.items():
        result.extend([(typ+'.sizeof',f'sizeof({typ})'),(typ+'.alignof',f'__alignof__({typ})')])
        for field in fields:
            key=typ+'.'+field
            result.extend([(key+'.offset',f'__builtin_offsetof({typ}, {field})'),
                (key+'.sizeof',f'sizeof((({typ} *)0)->{field})'),
                (key+'.alignof',f'__alignof__((({typ} *)0)->{field})')])
    return result


def wrapper(source):
    include=source.resolve().as_posix()
    if any(c in include for c in ['"','\n','\r']):
        raise ValueError('unsupported source path for include')
    if TABLE in source.read_text(encoding='utf-8'):
        raise ValueError('diagnostic symbol collides with input source')
    expressions=layout_expressions()
    values=',\n'.join('    (unsigned long long)('+expr+')' for _,expr in expressions)
    return (f'// Diagnostic only: include the full original TU without editing it.\n#include "{include}"\n'
        '#ifdef __cplusplus\nextern "C" {\n#endif\n'
        f'__attribute__((used)) unsigned long long {TABLE}[] = {{\n{values}\n}};\n'
        '#ifdef __cplusplus\n}\n#endif\n')


def diagnostic_base(argv, source):
    if argv[:2] not in [['xcrun','clang'],['xcrun','clang++']] or argv.count('-c')!=1 or argv.count('-o')!=1:
        raise ValueError('expected one direct recorded Clang compile')
    ci,oi=argv.index('-c'),argv.index('-o')
    if ci+1>=len(argv) or oi!=len(argv)-2 or Path(argv[ci+1]).resolve()!=source.resolve():
        raise ValueError('source/output mismatch')
    removed={ci,ci+1,oi,oi+1}
    for flag in ['-MF','-MT','-MQ','-MJ']:
        if argv.count(flag)>1:
            raise ValueError('duplicate dependency output flag')
        if flag in argv:
            i=argv.index(flag)
            if i+1>=len(argv) or i+1 in removed:
                raise ValueError('malformed dependency output')
            removed.update([i,i+1])
    removed.update(i for i,v in enumerate(argv) if v in ['-MD','-MMD','-MP'])
    base=[v for i,v in enumerate(argv) if i not in removed]
    if any(v.startswith('@') or v in ['-E','-S','-emit-llvm','-fsyntax-only'] for v in base):
        raise ValueError('unexpected prior diagnostic/response-file action')
    return base,[argv[i] for i in sorted(removed)]


def parse_layout(ir):
    triple=re.search(r'^target triple = "([^"]+)"$',ir,re.M)
    if not triple or not triple.group(1).startswith('x86_64-apple-'):
        raise ValueError('expected Darwin x86_64 LLVM IR')
    pattern=rf'^@{TABLE}\s*=.*?\bglobal\s+\[(\d+) x i64\]\s+\[([^\n]*)\]'
    rows=list(re.finditer(pattern,ir,re.M))
    if len(rows)!=1:
        raise ValueError('missing or duplicate diagnostic table')
    count=int(rows[0].group(1))
    tokens=rows[0].group(2).split(',')
    values=[]
    for token in tokens:
        m=re.fullmatch(r'\s*i64 (\d+)\s*',token)
        if not m:
            raise ValueError('non-integer/unresolved layout value')
        values.append(int(m.group(1)))
    specs=layout_expressions()
    if count!=len(specs) or len(values)!=count:
        raise ValueError('layout cardinality mismatch')
    return triple.group(1),dict(zip([name for name,_ in specs],values))


def compare_layouts(units, rm_prefix='probe-'):
    expected=[rm_prefix+rel.replace('/','_') for rel in RM_SOURCES]+[x[0] for x in CPP_PROFILES]
    if len(units)!=len(expected) or sorted(x['profile'] for x in units)!=sorted(expected) or any('layout' not in u for u in units):
        return {'status':'INCOMPLETE','differences':[]}
    keys=[k for k,_ in layout_expressions()]
    if any(set(u['layout'])!=set(keys) for u in units):
        raise ValueError('incomplete layout schema')
    differences=[]
    for key in keys:
        observed={u['profile']:u['layout'][key] for u in units}
        if len(set(observed.values()))!=1:
            differences.append({'key':key,'values':observed})
    return {'status':'SELECTED_LAYOUT_MISMATCH' if differences else 'SELECTED_LAYOUT_MATCH',
            'compared_values':len(keys),'differences':differences}


def first_argument_end(clean, opening, end):
    depth=0
    for i in range(opening+1,end):
        if clean[i] in '([{':
            depth+=1
        elif clean[i] in ')]}':
            depth-=1
        elif clean[i]==',' and depth==0:
            return i
    return end


def altstack_conflicts(units,audit,rm_prefix='probe-'):
    null_names={x['name'] for x in audit['occurrences'] if x['literal_null']}
    result=[]
    for rel in RM_SOURCES:
        profile=rm_prefix+rel.replace('/','_')
        matches=[x for x in units if x['profile']==profile]
        if len(matches)!=1 or not matches[0].get('altstack_defined'):
            continue
        names={x['name'] for x in audit['runtime_targets'] if x['path']==rel}
        conflicts=sorted(names & null_names)
        if conflicts:
            result.append({'profile':profile,'symbols_with_literal_null_calls':conflicts})
    return result


def source_audit(nv, nm, names):
    runtime=[]
    for rel in RM_SOURCES:
        text=(nv/rel).read_text(encoding='utf-8')
        for item in definitions(text,names):
            if any(x['name']=='NV_ENTER_RM_RUNTIME' for x in item['call_like_occurrences']):
                runtime.append({'name':item['name'],'path':rel,'line':item['line'],
                    'source_sha256':sha(nv/rel),'body_sha256':item['body_sha256']})
    targets={x['name'] for x in runtime}
    manifest=[]
    occurrences=[]
    for path in sorted((nm/'kexts/NVRM').rglob('*'),key=lambda p:p.relative_to(nm).as_posix()):
        if not path.is_file() or path.suffix not in ['.c','.cpp','.h','.hpp','.cc']:
            continue
        text=path.read_text(encoding='utf-8')
        rel=path.relative_to(nm).as_posix()
        manifest.append({'path':rel,'sha256':sha(path)})
        clean=no_directives(mask(text))
        for m in re.finditer(r'\b([A-Za-z_]\w*)\s*\(',clean):
            if m.group(1) not in targets:
                continue
            opening=clean.index('(',m.start())
            end=balanced(clean,opening)
            first_end=first_argument_end(clean,opening,end)
            argument=clean[opening+1:first_end].strip()
            occurrences.append({'name':m.group(1),'path':rel,'line':text.count('\n',0,m.start())+1,
                'first_argument':text[opening+1:first_end].strip(),
                'literal_null':argument in ['NULL','nullptr','0'],
                'limitation':'lexical occurrence; non-null text is not a validity proof'})
    return {'scope':'all C/C++/headers under candidate kexts/NVRM; three fixed RM TU definition bodies',
            'manifest':manifest,'runtime_targets':runtime,'occurrences':occurrences,
            'literal_null_count':sum(x['literal_null'] for x in occurrences)}


def execute(argv,cwd,stdout,stderr):
    with stdout.open('w',encoding='utf-8') as out,stderr.open('w',encoding='utf-8') as err:
        try:
            return subprocess.run(argv,cwd=cwd,stdout=out,stderr=err,timeout=180).returncode
        except subprocess.TimeoutExpired:
            err.write('TIMEOUT after 180 seconds\n')
            return 124


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--nv',required=True,type=Path)
    ap.add_argument('--candidate',required=True,type=Path)
    ap.add_argument('--definitions',required=True,type=Path)
    ap.add_argument('--logs',type=Path)
    ap.add_argument('--out',required=True,type=Path)
    ap.add_argument('--source-only',action='store_true')
    args=ap.parse_args()
    nv,nm,out=args.nv.resolve(),args.candidate.resolve(),args.out.resolve()
    if not args.source_only and not args.logs:
        ap.error('--logs required for native diagnostics')
    out.mkdir(parents=True,exist_ok=False)
    head=subprocess.check_output(['git','-C',str(nv),'rev-parse','HEAD'],text=True).strip()
    dirty=subprocess.check_output(['git','-C',str(nv),'status','--porcelain','--untracked-files=all'],text=True).strip()
    if head!=OGKM_PIN or dirty:
        raise ValueError('OGKM must be clean at fixed input')
    names=set(json.loads(args.definitions.read_text(encoding='utf-8'))['found'])
    audit=source_audit(nv,nm,names)
    if len(audit['runtime_targets'])!=20 or len({x['name'] for x in audit['runtime_targets']})!=20:
        raise ValueError('fixed-input runtime target audit is incomplete')
    (out/'source-inputs.json').write_text(json.dumps(audit,indent=2)+'\n',encoding='utf-8')
    report={'level':'SOURCE-LEXICAL-ONLY' if args.source_only else 'SELECTED-RM-RECORD-LAYOUTS-NOT-FULL-ABI',
        'ogkm_pin':head,'source_audit':'source-inputs.json','units':[],'failures':[],
        'limitations':['selected top-level fields only; nested structures/enum/signature/calling convention remain open',
            'wrapper includes full unchanged TU; include level/base file differ from original compilation',
            'final TU macros are not a header-time trace; identical layout does not prove ownership or atomic semantics'],
        'kext_load':'NO-GO','gpu_runtime':'NOT_RUN'}
    if args.source_only:
        report['result']='NATIVE_LAYOUT_NOT_RUN'
    else:
        profiles=[('probe-'+rel.replace('/','_'),nv/rel) for rel in RM_SOURCES]
        profiles += [(label,nm/rel) for label,rel in CPP_PROFILES]
        logs=args.logs.resolve()
        for profile,source in profiles:
            entry={'profile':profile,'source_sha256':sha(source),'source':str(source)}
            report['units'].append(entry)
            try:
                compile_log=logs/(profile+('-compile.txt' if profile.startswith('candidate-') else '.txt'))
                text=compile_log.read_text(encoding='utf-8')
                if not text.startswith('ARGV=') or re.findall(r'^EXIT=(-?\d+)\s*$',text,re.M)!=['0']:
                    raise ValueError('input compile log does not show exactly one success')
                argv=json.loads(text.splitlines()[0][5:])
                base,removed=diagnostic_base(argv,source)
                entry.update({'compile_log':compile_log.name,'compile_log_sha256':sha(compile_log),
                    'original_argv':argv,'removed_action_arguments':removed})
                generated=out/(profile+source.suffix)
                generated.write_text(wrapper(source),encoding='utf-8')
                entry['wrapper_sha256']=sha(generated)
                ir=out/(profile+'.ll')
                command=[*base,'-S','-emit-llvm',str(generated),'-o',str(ir)]
                rc=execute(command,nv,out/(profile+'-ir.stdout.txt'),out/(profile+'-ir.stderr.txt'))
                entry['llvm_command']=command
                entry['llvm_exit']=rc
                if rc:
                    raise ValueError('LLVM diagnostic compilation failed')
                entry['llvm_sha256']=sha(ir)
                entry['target_triple'],entry['layout']=parse_layout(ir.read_text(encoding='utf-8'))
                macro_file=out/(profile+'-macros.txt')
                command=[*base,'-E','-dM',str(generated)]
                rc=execute(command,nv,macro_file,out/(profile+'-macros.stderr.txt'))
                entry['macro_command']=command
                entry['macro_exit']=rc
                if rc:
                    raise ValueError('macro diagnostic failed')
                macro_text=macro_file.read_text(encoding='utf-8')
                macros=dict(re.findall(r'^#define[ \t]+(\w+)[ \t]*([^\n]*)$',macro_text,re.M))
                entry['selectors']={k:macros.get(k) for k in SELECTORS}
                entry['altstack_defined']='__use_altstack__' in macros
                entry['status']='OBSERVED'
            except (ValueError,OSError) as error:
                entry['status']='INCOMPLETE'
                entry['error']=str(error)
                report['failures'].append(profile)
        report['comparison']=compare_layouts(report['units'])
        conflicts=altstack_conflicts(report['units'],audit)
        report['altstack_null_conflicts']=conflicts
        report['result']='OBSERVED_NO_SELECTED_MISMATCH' if not report['failures'] and not conflicts and report['comparison']['status']=='SELECTED_LAYOUT_MATCH' else 'BLOCKED_OR_INCOMPLETE'
    (out/'rm-abi-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'result':report['result'],'runtime_targets':len(audit['runtime_targets']),
        'candidate_literal_null_occurrences':audit['literal_null_count'],'units':len(report['units'])}))
    return 0 if report['result'] in ['NATIVE_LAYOUT_NOT_RUN','OBSERVED_NO_SELECTED_MISMATCH'] else 2


if __name__=='__main__':
    raise SystemExit(main())
