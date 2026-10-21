# Evidence replay: python this-file.py 39531652222 <text-artifact.zip>
from pathlib import Path,PurePosixPath
import hashlib,json,sys,zipfile,subprocess
repo=Path(__file__).resolve().parents[4];sys.path.insert(0,str(repo/'scripts/g1'))
from stock_v243_internal_link import NVKMS,NVLINK,validate_archive_names
from stock_v243_import_audit import attribute
runid=int(sys.argv[1]);archive=Path(sys.argv[2]) if len(sys.argv)>2 else repo.parent/'g1-stock-work'/('internal-link-'+str(runid)+'.zip')
with zipfile.ZipFile(archive) as z:
    def report(name):return json.loads(z.read(name))
    def names(name):return {l.split()[-1] for l in z.read(name).decode().splitlines() if l.strip() and not l.startswith(('ARGV=','EXIT='))}
    r=report('report.json')
    assert r['status']=='PASS_INTERNAL_LINK_INTEGRATION_EXTERNAL_ABI_UNVERIFIED'
    assert len(r['rm_objects'])==1055 and len(r['tu_objects'])==12 and len(r['modeset_objects'])==225 and len(r['rm_replacements'])==2
    for n in ('make-nvidia.log','make-modeset.log','ld.txt','paired-ld.txt','integrated-ld.txt','nvlink-compile.txt'):
        assert z.read(n).decode().rstrip().endswith('EXIT=0'),n
    baseline=names('NVRM-undefined.txt');paired=names('paired-undefined.txt');final=names('integrated-undefined.txt');definitions=names('integrated-defined.txt')
    assert baseline==set(r['imports'])==set(r['same_run_baseline']['imports']) and len(baseline)==493
    assert set(r['final_imports'])==final
    removed=baseline-paired;assert NVKMS<=removed and not NVKMS&paired and removed-NVKMS<={'_SHA1Init','_SHA1Update','_SHA1Final'} and removed<=definitions and not paired-baseline
    assert paired-final==NVLINK and final-paired<={'_panic'} and (NVKMS|NVLINK)<=definitions and not (NVKMS|NVLINK)&final
    assert names('nvlink-defined.txt')==NVLINK
    inventory=validate_archive_names(z.read('modeset-archive-members.txt').decode().splitlines(),[Path(row['path']).name for row in r['modeset_objects']])
    lock=json.loads((repo/'research/stock-v243-once-20261021/internal-link-lock.json').read_text())
    assert r['integration_lock_sha256']==hashlib.sha256((repo/'research/stock-v243-once-20261021/internal-link-lock.json').read_bytes()).hexdigest()
    assert {row['source']:row['source_sha256'] for row in r['rm_replacements']}==lock['patches'][-1]['after']
    assert r['paired_candidate']['reverse_restores_original'] and r['paired_candidate']['replay_identical'] and len(r['paired_candidate']['steps'])==12
    assert all(p['raw_bytes_equal'] for p in r['shaders']['payloads']) and len(r['shaders']['payloads'])==5
    baseline_args=report('link-inputs.json')['argv'];args=report('internal-link-inputs.json')['argv']
    replacements={Path(row['source']).stem:row['path'] for row in r['rm_replacements']}
    oldpaths={row['path'] for row in r['rm_objects']}
    expected=[replacements[Path(a).stem] if a in oldpaths and Path(a).stem in replacements else a for a in baseline_args]
    expected[-1]=args[-1];expected[expected.index('-o'):expected.index('-o')]=[str(PurePosixPath(args[-1]).parent/'libnvkms-paired.a'),str(PurePosixPath(args[-1]).parent/'nvlink-darwin.o')]
    assert expected==args
    attrib=attribute(final,repo/'research/gpu-safety-r5/target-provider-evidence/native')
    assert {k:v for k,v in attrib.items() if k!='provider_evidence_sha256'}=={k:v for k,v in r['final_attribution'].items() if k!='provider_evidence_sha256'}
    for name,sha in r['final_attribution']['provider_evidence_sha256'].items():
        raw=subprocess.check_output(['git','-C',str(repo),'show','3e383c5cad2f9efbce58701f2c064a4de662b841:research/gpu-safety-r5/target-provider-evidence/native/'+name])
        assert hashlib.sha256(raw).hexdigest()==sha
    assert not any(k.startswith('INTERNAL_') or k=='UNKNOWN' for k in attrib['counts'])
    result=dict(level='INDEPENDENT_TEXT_CONSISTENCY_NOT_BINARY_LOAD_OR_ABI_ACCEPTANCE',run=runid,baseline_imports=len(baseline),paired_imports=len(paired),final_imports=len(final),nvkms_stage_removed=sorted(removed),nvlink_stage_removed=sorted(paired-final),nvlink_stage_added=sorted(final-paired),archive_indexes=inventory['index_members'],source_objects=225,rm_replacements=2,all_16_final_definitions_observed=True,all_16_unresolved_absent=True,final_attribution_counts=attrib['counts'],actual_link_argv_delta_exact=True,driver_execution='NOT_RUN',device='NO_GO')
    out=repo/'research/stock-v243-once-20261021/internal-link-evidence'/str(runid)/'independent-text-acceptance.json'
    encoded=(json.dumps(result,indent=2)+'\n').encode('utf-8')
    if out.exists():
        assert out.read_bytes()==encoded, 'existing acceptance differs; do not overwrite'
    else:
        out.write_bytes(encoded)
    print(json.dumps(result))
