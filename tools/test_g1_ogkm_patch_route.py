"""Synthetic route metadata negative controls; not compilation/driver evidence."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from g1_ogkm_candidate import SPECS
from g1_ogkm_patch_route import check_candidate_route
from g1_full_build import darwin_command


def log(path, argv, body=''):
    path.write_text('ARGV='+json.dumps(argv)+'\n'+body+'\nEXIT=0\n',encoding='utf-8')


class RouteTests(unittest.TestCase):
    def fixture(self, root):
        out=root/'full-source'; out.mkdir()
        original=(root/'original').resolve(); candidate=(root/'candidate').resolve()
        cwd=original/'src/nvidia-modeset'; sdk='/fixture-sdk'
        full={'status':'COMPLETE_SOURCE_CANDIDATE_LINKED_NOT_CLOSURE_OR_ABI_ACCEPTED',
            'compiler_failures':0,'sdk':sdk,'objects':[],
            'ogkm_candidate':{'original_root':str(original),'candidate_root':str(candidate),
                'patches':list(SPECS),'reverse_restores_original':True,'exact_two_source_delta':True}}
        for index,s in enumerate(SPECS):
            obj=out/('actual-'+str(index)+'.o'); source=candidate/s['source']
            official=['clang','-DOFFICIAL_TU_'+str(index)+'=1','-c',str(original/s['source']),'-o','old.o']
            argv=darwin_command(official,source,obj,sdk,Path(sdk)/'System/Library/Frameworks/Kernel.framework/Headers')
            row={'source':s['source'],'component':'nvidia-modeset','source_sha256':s['candidate_sha256'],
                'original_source_sha256':s['original_sha256'],'compiled_source':str(source),
                'candidate_patch':dict(s),'compile_cwd':str(cwd),'compile_exit':0,'object_sha256':'fixture-hash',
                'object':str(obj),'official_argv':official,'candidate_argv':argv,'log':str(index)+'.txt'}
            log(out/row['log'],argv); full['objects'].append(row)
        archive=str(out/'libnvidia-modeset.a')
        full['link']={'exit':0,'archive_order':[archive],'baseline_objects':[],
            'extra_objects':[],'artifact_sha256':'fixture-not-an-artifact'}
        dest=str(out/'NVRM-complete-source-candidate.kext/Contents/MacOS/NVRM')
        link=['xcrun','clang++','-arch','x86_64','-mmacosx-version-min=15.5','-fapple-kext',
            '-isysroot',sdk,'-nostdlib','-Xlinker','-kext','-Wl,-why_load',archive,
            '-lkmodc++','-lkmod','-lcc_kext','-o',dest]
        body='\n'.join(s['defined_symbol']+' forced load of '+archive+'('+Path(r['object']).name+')'
            for s,r in zip(SPECS,full['objects']))
        log(out/'full-nvrm-link.txt',link,body)
        log(out/'nvidia-modeset-archive.txt',['xcrun','ar','rcs',archive,*[r['object'] for r in full['objects']]])
        log(out/'full-nvrm-defined.txt',['xcrun','nm','-gU',dest],
            '\n'.join('000000 T '+s['defined_symbol'] for s in SPECS))
        native={'objects':[{'unit':'NVKAPI','profile':'candidate','compile_exit':0,
            'source_sha256':SPECS[0]['candidate_sha256']}]}
        (root/'native-report.json').write_text(json.dumps(native))
        (out/'report.json').write_text(json.dumps(full))
        return native,full

    def test_rejects_wrong_source_probe_flags_cwd_and_failed_compilation(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); native,full=self.fixture(root)
            self.assertTrue(check_candidate_route(root,native,full)['status'].startswith('PASS_'))
            for key,value in [('source_sha256',SPECS[0]['original_sha256']),
                    ('original_source_sha256','different'),('compiled_source','probe.c'),
                    ('compile_cwd','probe-dir'),('compile_exit',1),('object_sha256',''),
                    ('candidate_argv',['clang','-DPROBE=1'])]:
                bad=copy.deepcopy(full); bad['objects'][0][key]=value
                with self.subTest(key=key), self.assertRaises(ValueError):
                    check_candidate_route(root,native,bad)

    def test_rejects_missing_archive_load_definition_and_changed_link(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); native,full=self.fixture(root); out=root/'full-source'
            for file,old,new in [('full-nvrm-link.txt','forced load of','unrelated'),
                    ('full-nvrm-defined.txt',' T _nvKmsKapiFreeNisoSurface',' T _unrelated'),
                    ('nvidia-modeset-archive.txt','actual-0.o','probe.o'),
                    ('full-nvrm-link.txt','-Wl,-why_load','-Wl,other'),
                    ('full-nvrm-defined.txt','EXIT=0','EXIT=1')]:
                p=out/file; good=p.read_text(); p.write_text(good.replace(old,new))
                try:
                    with self.subTest(file=file,old=old), self.assertRaises(ValueError):
                        check_candidate_route(root,native,full)
                finally: p.write_text(good)


if __name__=='__main__': unittest.main()
