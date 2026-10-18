"""Recompute fixed native text contracts; never independently attest KC bytes."""
import hashlib
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(root/'tools'))
from g1_kc8 import TARGETS
from g1_kc8_sdk import compare

native = root/'research/gpu-safety-r5/kc8-evidence/native'
checks = []

def check(label, condition):
    if not condition:
        raise ValueError('fixed KC8 result check failed: '+label)
    checks.append(label)

def load(path):
    return json.loads(path.read_text(encoding='utf-8'))

binding = load(native/'local-artifact-binding.json')
check('external run', binding['run_id'] == 39134085153)
check('external artifact', binding['artifact_id'] == 12138578202)
check('external ZIP digest', binding['artifact_sha256'] == '7d569be4fda4145a2eb45457189a75dddb05857f1802bdaa748c4128ea9bd0a8')
for entry in binding['members']:
    raw = (native/entry['path']).read_bytes()
    check('download member '+entry['path'], len(raw) == entry['bytes'] and hashlib.sha256(raw).hexdigest() == entry['sha256'])
manifest = load(native/'diagnostic-publication.json')
for entry in manifest['included']:
    raw = (native/entry['path']).read_bytes()
    check('publication member '+entry['path'], len(raw) == entry['bytes'] and hashlib.sha256(raw).hexdigest() == entry['sha256'])
report = load(native/'kc/kc8-report.json')
check('native source', report['source_commit'] == '4c36e828edc62bec765e89e149b475d11799c7c5')
check('native run', report['source_run_id'] == '39134085153')
check('eight exact targets', {r['macho_symbol'] for r in report['records']} == {n for ns in TARGETS.values() for n in ns} and len(report['records']) == 8)
queries = {}
for q in report['kmutil_queries']:
    raw = load(native/'kc'/q['file'])
    check('query identity '+q['flag'], raw['exit'] == q['exit'] == 0 and
          hashlib.sha256(raw['stdout'].encode()).hexdigest() == q['stdout_sha256'] and raw['argv'][-1] == q['flag'])
    queries[q['flag']] = raw['stdout']
members = []
for collection in report['collections']:
    check('KC parse '+collection['path'], collection['observation'] == 'FILESET_PARSED')
    for member in collection['members']:
        bundle = member['bundle_id']
        entry, uuid = member['entry'], member['header']['uuid']
        wanted = ('vmaddr:'+hex(entry['vmaddr'])+' fileoff:'+str(entry['fileoff'])+' entry:'+bundle)
        check('fileset crosscheck '+bundle, wanted in queries['--show-fileset-entries'])
        line = [l for l in queries['--show-kext-uuids'].splitlines() if l.startswith(bundle+'\t')]
        check('uuid unique '+bundle, len(line) == 1)
        match = re.search(r'\(([A-Fa-f0-9-]{36})\)', line[0])
        check('uuid crosscheck '+bundle, bool(match) and match[1].replace('-', '').lower() == uuid)
        load_lines = [l for l in queries['--show-kext-load-addresses'].splitlines() if l.startswith(bundle+'\t')]
        # This kmutil build prints no numerical address with this flag.
        # Use the actual FILESET vmaddr as a collection coordinate, not a
        # fabricated live kernel load address or a zero for unknown.
        check('load-view bundle presence '+bundle, len(load_lines) == 1)
        members.append({'bundle_id': bundle, 'uuid': uuid, 'version': line[0].split('\t')[1],
            'collection_fileoff': entry['fileoff'], 'collection_vmaddr_hex': hex(entry['vmaddr']),
            'kmutil_numeric_load_address': 'NOT_OBSERVED', 'symbol_table': member['header']['symtab']})
for record in report['records']:
    check('one actual definition '+record['macho_symbol'], len(record['observations']) == 1 and
          record['status'] == 'KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI')
    definition = record['observations'][0]['definition']
    check('exact external section role '+record['macho_symbol'], definition['n_type'] == 15 and
          definition['observed_kind'] == ('DATA_SECTION' if record['macho_symbol'].endswith('metaClassE') else 'FUNCTION_SECTION'))
sdk = load(native/'sdk/sdk-report.json')
ir = (native/'sdk/sdk-methods.ll').read_bytes()
check('SDK IR digest', hashlib.sha256(ir).hexdigest() == sdk['ir_sha256'])
caller = load(root/'research/gpu-safety-r5/kc8-caller-selection.json')
check('SDK compiler shapes recomputed', compare(ir.decode(), caller) == sdk['records'])
check('five match one unknown', [r['status'] for r in sdk['records']].count('SDK_CALLER_TYPE_MATCH') == 5 and
      [r['status'] for r in sdk['records']].count('HISTORICAL_CALLER_IR_NOT_OBSERVED') == 1)
check('SDK15.5', sdk['environment']['sdk_version']['stdout'].strip() == '15.5')
result = {'status': 'FIXED_NATIVE_TEXT_CROSSCHECKS_PASSED', 'checks_passed': len(checks), 'checks': checks,
    'source_commit': report['source_commit'], 'run_id': binding['run_id'], 'artifact_id': binding['artifact_id'],
    'artifact_zip_sha256': binding['artifact_sha256'], 'members': members,
    'definitions': [{'macho_symbol': r['macho_symbol'],
        'vmaddr_hex': hex(r['observations'][0]['definition']['value']),
        'fileoff': r['observations'][0]['definition']['definition_file_offset'],
        'role': r['observations'][0]['definition']['observed_kind']} for r in report['records']],
    'actual_section_definitions': 8, 'function_sections': 6, 'data_sections': 2,
    'selected_caller_matches': 5, 'selected_caller_unknown': 1,
    'limitations': ['Binary definitions and collection SHA256 are native collector witnesses; KC bytes not published.',
        'Text crosschecks do not independently recompute raw KC nlist/section bytes or whole-file digests.',
        'KPI export permission, full C++ ABI, versions and user target system remain unaccepted.',
        'kmutil load-address flag emitted no numeric addresses; fileset VM coordinates are not live ASLR addresses.'],
    'gpu_execution': False, 'device': 'NO-GO'}
dest = root/'research/gpu-safety-r5/kc8-evidence'
dest.mkdir(exist_ok=True)
(dest/'crosschecks.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k: v for k, v in result.items() if k not in ['checks', 'members', 'definitions', 'limitations']}))
