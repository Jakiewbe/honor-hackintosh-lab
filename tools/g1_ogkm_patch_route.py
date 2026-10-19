#!/usr/bin/env python3
"""Require the KAPI candidate probe source to reach the complete final archive.

An isolated probe is not a final-link input. Source equality is necessary here,
not complete ABI or byte-identical object acceptance (flags intentionally differ).
"""
import argparse
import hashlib
import json
from pathlib import Path
from g1_full_abi import successful_argv
from g1_full_build import darwin_command, read_defined_log
from g1_ogkm_candidate import SPECS


def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def check_candidate_route(src, native, full):
    manifest = full['ogkm_candidate']
    if (manifest['patches'] != list(SPECS) or not manifest['reverse_restores_original'] or
            not manifest['exact_two_source_delta']):
        raise ValueError('exact approved OGKM candidate manifest required')
    if (full['status'] != 'COMPLETE_SOURCE_CANDIDATE_LINKED_NOT_CLOSURE_OR_ABI_ACCEPTED' or
            full['link']['exit'] or full['compiler_failures']):
        raise ValueError('successful full compilation/link required')
    directory = src/'full-source'
    link = successful_argv(directory/'full-nvrm-link.txt')
    archive_root = Path(full['link']['archive_order'][0]).parent
    destination = archive_root/'NVRM-complete-source-candidate.kext/Contents/MacOS/NVRM'
    expected_link = ['xcrun','clang++','-arch','x86_64','-mmacosx-version-min=15.5','-fapple-kext',
        '-isysroot',full['sdk'],'-nostdlib','-Xlinker','-kext','-Wl,-why_load',
        *full['link']['baseline_objects'], *full['link']['archive_order'], *full['link']['extra_objects'],
        '-lkmodc++','-lkmod','-lcc_kext','-o',str(destination)]
    if link != expected_link:
        raise ValueError('actual final link differs from complete candidate inputs')
    loaded = (directory/'full-nvrm-link.txt').read_text(encoding='utf-8').splitlines()
    defined = read_defined_log(directory/'full-nvrm-defined.txt')
    if successful_argv(directory/'full-nvrm-defined.txt') != ['xcrun','nm','-gU',str(destination)]:
        raise ValueError('definitions do not describe the actual final candidate')
    kms = [r for r in full['objects'] if r['component']=='nvidia-modeset']
    archive, = [a for a in full['link']['archive_order'] if Path(a).name=='libnvidia-modeset.a']
    if link.count(archive) != 1:
        raise ValueError('actual final link must include modeset archive exactly once')
    ar = successful_argv(directory/'nvidia-modeset-archive.txt')
    if ar != ['xcrun','ar','rcs',archive,*[r['object'] for r in kms]]:
        raise ValueError('archive ARGV differs from exact full-flag object inventory')
    rows = []
    for spec in SPECS:
        row, = [r for r in kms if r['source']==spec['source']]
        actual = str(Path(manifest['candidate_root'])/spec['source'])
        original = Path(manifest['original_root'])/spec['source']
        cwd = str(Path(manifest['original_root'])/'src/nvidia-modeset')
        if (row['source_sha256'] != spec['candidate_sha256'] or
                row['original_source_sha256'] != spec['original_sha256'] or
                row['compiled_source'] != actual or row['candidate_patch'] != spec or
                row['compile_cwd'] != cwd or row['compile_exit'] or not row['object_sha256']):
            raise ValueError('patched TU source/compile identity differs: '+spec['source'])
        official = row['official_argv']
        if official.count('-c') != 1 or (Path(cwd)/official[official.index('-c')+1]).resolve() != original.resolve():
            raise ValueError('official command must still identify fixed original TU')
        headers = Path(full['sdk'])/'System/Library/Frameworks/Kernel.framework/Headers'
        expected = darwin_command(official, Path(actual), Path(row['object']), full['sdk'], headers)
        if row['candidate_argv'] != expected or successful_argv(directory/row['log']) != expected:
            raise ValueError('full flags changed or compile log differs')
        marker = archive+'('+Path(row['object']).name+')'
        why = [line for line in loaded if 'forced load of '+marker in line]
        if not why or spec['defined_symbol'] not in defined:
            raise ValueError('patched archive member/expected final definition absent')
        rows.append({'source':spec['source'], 'patch':spec['patch'],
            'original_sha256':spec['original_sha256'], 'candidate_sha256':spec['candidate_sha256'],
            'compiled_source':actual, 'object':row['object'],'object_sha256':row['object_sha256'],
            'actual_archive_load':why,'final_definition':spec['defined_symbol'],
            'compile_log_sha256':sha(directory/row['log'])})
    probes = [r for r in native['objects'] if r['unit']=='NVKAPI' and r['profile']=='candidate']
    if len(probes)!=1 or probes[0]['compile_exit'] or probes[0]['source_sha256'] != SPECS[0]['candidate_sha256']:
        raise ValueError('independent R3 probe source differs')
    return {'status':'PASS_SOURCE_FULL_FLAGS_ARCHIVE_AND_FINAL_DEFINITIONS_ONLY',
        'level':'TEXT_SOURCE_OBJECT_ARCHIVE_LINK_NOT_RUNTIME','routes':rows,
        'native_report_sha256':sha(src/'native-report.json'),
        'full_report_sha256':sha(directory/'report.json'), 'candidate_sha256':full['link']['artifact_sha256'],
        'full_abi_loader':'NOT_ACCEPTED','gpu':'NOT_RUN','kext_load':'NO-GO'}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--artifact-dir',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True)
    args=p.parse_args(); args.out.mkdir(parents=True,exist_ok=False)
    src=args.artifact_dir
    native=read(src/'native-report.json'); full=read(src/'full-source/report.json')
    if 'ogkm_candidate' in full:
        try:
            report=check_candidate_route(src,native,full)
            rc=0
        except (ValueError, KeyError, OSError) as error:
            report={'status':'FAIL_CANDIDATE_ROUTE','error':str(error),'kext_load':'NO-GO'}
            rc=1
        (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print(json.dumps(report))
        return rc
    probes=[r for r in native['objects'] if r['unit']=='NVKAPI' and r['profile']=='candidate']
    finals=[r for r in full['objects'] if r['source'].endswith('/kapi/src/nvkms-kapi.c')]
    if len(probes)!=1 or len(finals)!=1: raise ValueError('expected unique candidate probe and full KAPI source')
    probe,final=probes[0],finals[0]
    if probe['compile_exit'] or final['compile_exit'] or full['link']['exit']:
        raise ValueError('successful probe/full compile/link required before route check')
    if successful_argv(src/'full-source'/final['log'])!=final['candidate_argv']:
        raise ValueError('full compile log/ARGV differs')
    link=src/'full-source/full-nvrm-link.txt'
    why=[line for line in link.read_text(encoding='utf-8').splitlines() if 'forced load of' in line and
         '('+Path(final['object']).name+')' in line]
    if not why: raise ValueError('actual archive member load not observed')
    same=probe['source_sha256']==final['source_sha256']
    report={'level':'SOURCE_COMPILE_LOG_AND_ARCHIVE_LOAD_NOT_RUNTIME',
        'status':'PASS_SOURCE_ROUTE_ONLY' if same else 'FAIL_PROBE_PATCH_NOT_IN_FINAL_SOURCE',
        'candidate_probe':probe,'final_compiled_source':{k:final[k] for k in
            ('component','source','source_sha256','object','object_sha256','compile_exit','log')},
        'probe_and_final_source_equal':same,'archive_member_load':why,
        'native_report_sha256':sha(src/'native-report.json'),'full_report_sha256':sha(src/'full-source/report.json'),
        'full_compile_log_sha256':sha(src/'full-source'/final['log']),'link_log_sha256':sha(link),
        'complete_build_success_not_retracted':True,'abi_loader_gpu':'NOT_ACCEPTED'}
    (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 0 if same else 1


if __name__=='__main__': raise SystemExit(main())
