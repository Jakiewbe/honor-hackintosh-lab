"""Recompute supplied device JSON against CI JSON; never read or execute device/KC binaries."""
from pathlib import Path
import hashlib
import json
import subprocess

if not __debug__:
    raise RuntimeError('run without Python -O')
ROOT=Path(__file__).resolve().parent
def load(path):return json.loads(path.read_text(encoding='utf-8'))
path=ROOT/'evidence/device-text-20261022/device-vtable.json'
device=load(path)
ci=load(ROOT/'evidence/39609383942/abi/per-class-vtable.json')
methods=load(ROOT/'evidence/39609383942/enum-slot-binding.json')['methods']
parser=subprocess.run(['git','-C',str(ROOT.parents[1]),'show',
    '7fa7fdc9b44f035329c4d36a17d3025f34f87e7c:tools/g1_kc_vtable_bounded.py'],
    check=True,capture_output=True).stdout
assert hashlib.sha256(parser).hexdigest()==device['parser_sha256']
classes=[]
for row in device['classes']:
    start=int(row['address'],16);end=int(row['upper_bound'],16);section=row['section']
    assert row['status']=='BOUNDED_RAW_SLOT_OBSERVATION_NOT_FULL_LAYOUT'
    assert section['address']<=start<end<=section['address']+section['size']
    assert len(row['slots'])==(end-start-16)//8
    for i,slot in enumerate(row['slots']):
        assert slot['slot_relative_to_class']==i
        assert slot['file_offset']==section['offset']+start+16+i*8-section['address']
        target=int(slot['raw_word'],16)&0x3fffffff
        assert int(slot['target30_candidate'],16)==target
        assert all(n['value']==target for n in slot['definition_candidates'])
    prior=next(c for c in ci['classes'] if c['class_name']==row['class_name'])
    assert len(row['slots'])==len(prior['slots'])
    hits=[]
    for method in methods:
        if method['vtable_observation']['class_name']!=row['class_name']:continue
        expected=method['vtable_observation']['slot']
        actual=[s['slot_relative_to_class'] for s in row['slots']
                if any(n['name']==method['symbol'] for n in s['definition_candidates'])]
        assert actual==[expected]
        hits.append(dict(symbol=method['symbol'],slot=expected))
    classes.append(dict(name=row['class_name'],observed_words=len(row['slots']),methods=hits))
report=dict(input_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
    scope='SUPPLIED_JSON_IDENTITIES_AND_ARITHMETIC_ONLY_NOT_KC_BINARY_RECOMPUTATION',
    collection_sha256_reported=device['collection_sha256'],collection_bytes_reported=device['collection_bytes'],
    member_uuid_reported=device['member_uuid'],source_commit_reported=device['source_commit'],
    source_run_reported=device['source_run'],parser_blob_matches_audit_baseline=True,
    binary_collection_rehashed_in_this_round=False,classes=classes,full_abi='UNVERIFIED',device='NO_GO')
(path.parent/'text-review.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
