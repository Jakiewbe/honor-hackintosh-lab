"""Independently recompute text evidence identities; no binary or device execution."""
from pathlib import Path
import hashlib,json,subprocess

if not __debug__:
    raise RuntimeError('run this evidence verifier without Python -O')

repo=Path(__file__).resolve().parents[2]
root=repo/'research/stock-v243-audit-20261021/evidence/39609383942'
head='da20a569b622a71b26ae91675c70e3899bbf0b3a'
def read(path):return json.loads(path.read_text(encoding='utf-8'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
receipts={}
for kind in ('package','pm','abi'):
    folder=root/kind
    receipt=read(folder/'archive-binding.json')
    assert receipt['head_sha']==head and receipt['event']=='workflow_dispatch'
    assert receipt['conclusion']=='success'
    for path in folder.iterdir():
        if path.name=='archive-binding.json':continue
        entry=receipt['members'][path.name]
        assert path.stat().st_size==entry['bytes'] and sha(path)==entry['sha256']
    receipts[kind]={k:receipt[k] for k in ('artifact_id','archive_sha256','archive_bytes')}
p=read(root/'package/package-report.json')
assert p['commit']==head and p['run_id']=='39609383942' and p['stage']=='complete'
assert p['status']=='PASS_STATIC_KERNEL_BUNDLES_NOT_LOADER_ABI_OR_GPU_ACCEPTANCE_LOCAL_ONLY_EXPORTS_UNVERIFIED_KEXTUTIL_INFORMATIONAL_ONLY'
assert p['loader_resolution']==p['exports_acceptance']=='UNVERIFIED'
assert p['gpu']=='NOT_RUN' and p['kext_load']=='NO_GO'
assert p['kextutil_is_a_validation_gate'] is False
assert p['missing_dependency_control']['rejected'] is True
assert p['missing_executable_control']['rejected'] is True
bundles={}
local=set()
for name,b in p['bundles'].items():
    d=p['loader_dry_run'][name]
    assert type(d['exit']) is int and d['exit']==0 and d['unresolved']==[]
    assert d['bundle_sha256']==b['sha256'] and d['plist_sha256']==b['plist_sha256']
    assert d['bundle_id']==b['info']['CFBundleIdentifier']
    assert Path(d['executable']).name==name
    a=read(root/'package'/f'{name}-providers.json')
    assert a==b['providers'] and a['count']==len(b['imports'])
    assert set(b['imports'])=={r['symbol'] for r in a['rows']} and a['unresolved']==[]
    assert p['declared_dependencies'][name]['rejected']==[]
    assert {r['bundle'] for r in p['declared_dependencies'][name]['rows']}==set(b['info']['OSBundleLibraries'])
    local.update(a['local_only'])
    bundles[name]=dict(sha256=b['sha256'],bytes=b['bytes'],imports=len(b['imports']),
        local_only=len(a['local_only']),diagnostic_exit=d['exit'],
        dependency_unknown=p['declared_dependencies'][name]['unverified'])
abi=read(root/'abi/per-class-vtable.json')
assert abi['source_commit']==head and abi['source_run']=='39609383942'
parser_source=subprocess.run(['git','-C',str(repo),'show',head+':tools/g1_kc_vtable_bounded.py'],
    check=True,capture_output=True).stdout
assert abi['parser_sha256']==hashlib.sha256(parser_source).hexdigest()
classes=[]
for c in abi['classes']:
    assert c['status']=='BOUNDED_RAW_SLOT_OBSERVATION_NOT_FULL_LAYOUT'
    start=int(c['address'],16);end=int(c['upper_bound'],16);sec=c['section']
    assert sec['address']<=start<end<=sec['address']+sec['size']
    assert len(c['slots'])==(end-start-16)//8
    named=[]
    for i,s in enumerate(c['slots']):
        assert s['slot_relative_to_class']==i
        assert s['file_offset']==sec['offset']+start+16+i*8-sec['address']
        target=int(s['raw_word'],16)&0x3fffffff
        assert int(s['target30_candidate'],16)==target
        for r in s['definition_candidates']:
            assert r['value']==target
            named.append(dict(slot=i,symbol=r['name']))
    classes.append(dict(name=c['class_name'],address=c['address'],upper_bound=c['upper_bound'],
        observed_words=len(c['slots']),matched_words=sum(bool(s['definition_candidates']) for s in c['slots']),
        enum_methods=[r for r in named if any(v in r['symbol'] for v in ('set_shape','surface_lock_options','surface_unlock_options','processSwap','setStereo'))]))
pm=read(root/'pm/pm-report.json')
assert pm['stage']=='complete' and pm['kext_load']=='NO_GO' and pm['gpu']=='NOT_RUN'
assert pm['sleep_safety']=='UNVERIFIED' and pm['sleep_veto'] is False
assert pm['cpu']['invalid']['executed'] is False and pm['cpu']['invalid']['binary_exists'] is False
assert pm['cpu']['candidate']['exit']==0 and pm['cpu']['baseline']['exit']!=0
result=dict(run_id=39609383942,commit=head,event='workflow_dispatch',artifact_binding=receipts,
    level='TEXT_IDENTITIES_AND_ARITHMETIC_RECOMPUTED_NOT_BINARY_LOADER_OR_FULL_ABI',bundles=bundles,
    local_only_unique_names=len(local),collection_sha256=abi['collection_sha256'],member_uuid=abi['member_uuid'],
    classes=classes,pm_status=pm['status'],pm_link=pm['link'],gpu='NOT_RUN',device='NO_GO')
old=read(repo/'research/stock-v243-audit-20261021/evidence/39585922948/package/NVAccel-providers.json')
oldrows={r['symbol']:r for r in old['rows']}
family=read(root/'package/family-kc.json')
binding=[]
for name in sorted(local):
    observations=[]
    for collection in family:
        for member in collection['members']:
            if member['bundle_id']!='com.apple.iokit.IOAcceleratorFamily2':continue
            for symbol in member['symbols']['records']:
                if symbol['macho_symbol']!=name:continue
                assert symbol['n_type']==14
                section=member['header']['sections'][symbol['n_sect']-1]
                assert section['address']<=symbol['value']<section['address']+section['size']
                observations.append(dict(collection_sha256=collection['sha256'],member_uuid=member['header']['uuid'],
                    nlist=symbol,section=section))
    assert observations
    binding.append(dict(symbol=name,previous_classification=oldrows[name]['status'],
        observations=observations,external_export='UNVERIFIED'))
result['local_only_raw_records']=sum(len(r['observations']) for r in binding)
result['reclassified_from_vtable']=[r['symbol'] for r in binding if r['previous_classification']=='VTABLE_SLOT_OBSERVED_LOCAL_NAME_STRIPPED']
assert len(result['reclassified_from_vtable'])==7 and len(local)==27
(root/'local-only-binding.json').write_text(json.dumps(dict(run_id=39609383942,commit=head,
    nvaccel_sha256=p['bundles']['NVAccel']['sha256'],count=len(binding),
    raw_records=result['local_only_raw_records'],rows=binding),indent=2)+'\n',encoding='utf-8',newline='\n')
enum=read(repo/'research/stock-v243-audit-20261021/enum-native-binding.json')
enum_names={m['symbol'] for m in enum['methods']}
newrows={r['symbol']:r for r in p['bundles']['NVAccel']['providers']['rows']}
enum_rows=[]
for symbol in sorted(enum_names):
    hits=[dict(class_name=c['name'],slot=m['slot']) for c in classes for m in c['enum_methods'] if m['symbol']==symbol]
    assert len(hits)==1 and symbol in p['bundles']['NVAccel']['imports']
    enum_rows.append(dict(symbol=symbol,vtable_observation=hits[0],import_audit=newrows[symbol]))
(root/'enum-slot-binding.json').write_text(json.dumps(dict(run_id=39609383942,commit=head,
    nvaccel_sha256=p['bundles']['NVAccel']['sha256'],collection_sha256=abi['collection_sha256'],
    pointer_interpretation=abi['pointer_interpretation'],full_abi='UNVERIFIED',methods=enum_rows),indent=2)+'\n',encoding='utf-8',newline='\n')
(root/'independent-review.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
