"""Verify archived native contract text against its executed Git commit; no device access."""
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]
RUN = '39752747199'
COMMIT = 'ea9c688e216f753ec030f3db2f7ba99d54c9cdc1'


def require(condition, reason):
    if not condition:
        raise ValueError(reason)


def main():
    directory = ROOT / 'evidence' / RUN / 'offline'
    receipt = json.loads((directory / 'archive-binding.json').read_text(encoding='utf-8'))
    require((receipt['run_id'], receipt['head_sha'], receipt['event'], receipt['conclusion']) ==
            (int(RUN), COMMIT, 'workflow_dispatch', 'success'), 'run identity/result differs')
    expected = {'contracts.txt', 'regression.txt', 'environment.txt', 'source-binding.json'}
    require(set(receipt['members']) == expected, 'artifact text member set differs')
    for name, identity in receipt['members'].items():
        raw = (directory / name).read_bytes()
        raw.decode('utf-8')
        require(len(raw) == identity['bytes'] and
                hashlib.sha256(raw).hexdigest() == identity['sha256'], 'member bytes differ: ' + name)
    binding = json.loads((directory / 'source-binding.json').read_text(encoding='utf-8'))
    require((binding['commit'], binding['run_id'], binding['scope']) ==
            (COMMIT, RUN, 'CONTRACTS_ONLY_NO_FULL_DRIVER_BUILD'), 'source binding differs')
    required = {'scripts/g1/offline_build.py', 'scripts/g1/stock_v243_kext_link.py',
                'tests/test_stock_v243_offline.py',
                'research/stock-v243-offscreen-20261021/g1-first-touch.command',
                'research/stock-v243-offscreen-20261021/device-kextutil.sh'}
    require(required <= binding['files'].keys(), 'critical source binding missing')
    for name, digest in binding['files'].items():
        path = PurePosixPath(name)
        require(not path.is_absolute() and '..' not in path.parts, 'unsafe source path')
        raw = subprocess.run(['git', '-C', str(REPO), 'show', COMMIT + ':' + name],
                             check=True, capture_output=True).stdout
        require(hashlib.sha256(raw).hexdigest() == digest, 'executed Git blob differs: ' + name)
    environment = (directory / 'environment.txt').read_text(encoding='utf-8')
    require(re.search(r'^Python 3\.9\.\d+\s*$', environment, re.M) and
            'GNU bash, version 3.2.' in environment, 'native Python/bash identity differs')
    for name, count in (('contracts.txt', 16), ('regression.txt', 128)):
        log = (directory / name).read_text(encoding='utf-8')
        require(re.search(r'^Ran ' + str(count) + r' tests in ', log, re.M) and
                log.rstrip().endswith('\nOK') and
                len(re.findall(r'^test_.* \.\.\. ok$', log, re.M)) == count,
                'test result/count/skip differs: ' + name)
    print(json.dumps(dict(run_id=int(RUN), commit=COMMIT,
        source_blobs_verified=len(binding['files']), contracts=16, regression=128,
        scope='NATIVE_TOOL_CONTRACTS_ONLY', full_device_build='NOT_RUN',
        load='NO_GO', gpu='NOT_RUN'), indent=2))


if __name__ == '__main__':
    main()
