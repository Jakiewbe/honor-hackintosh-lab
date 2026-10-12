"""Optional test-fixture preflight; production source gates never skip checks."""
import hashlib
import json
from pathlib import Path

from r14c0_validate_dependency_baseline import PINS, blob_id, safe_path


def require_source_cache(test, source_lock, cache):
    missing = []
    for row in json.loads(Path(source_lock).read_text(encoding='utf-8'))['files']:
        if row['component'] not in PINS:
            raise ValueError('Unknown source-cache component')
        path = safe_path(Path(cache) / row['component'], row['path'])
        if not path.exists():
            missing.append(row['component'] + '/' + row['path'])
            continue
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != row['sha256'] or blob_id(data) != row['blob_sha']:
            test.fail('Upstream cache hash mismatch: ' + row['component'] + '/' + row['path'])
    if missing:
        test.skipTest('Fixed upstream source cache unavailable: missing ' + str(len(missing))
                      + ' files; first: ' + missing[0]
                      + '. Source verification NOT RUN; production gates still fail closed.')
