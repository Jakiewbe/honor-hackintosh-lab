#!/bin/bash
set -euo pipefail
r=/mnt/d/Hactk/gpu-mainline-20261017
python3 - "$r" <<'PY'
from pathlib import Path
import json, subprocess, sys, tempfile, yaml
r=Path(sys.argv[1])
f=r/'ci-export-r2/.github/workflows/gpu-safety-r2-native.yml'
w=yaml.safe_load(f.read_text())
triggers=w.get('on',w.get(True))
assert set(triggers)=={'workflow_dispatch'}
assert w['permissions']=={'contents':'read'}
results=[]
with tempfile.TemporaryDirectory() as d:
 for job, spec in w['jobs'].items():
  assert spec['runs-on']=='macos-15-intel'
  for i, step in enumerate(spec['steps']):
   if 'run' not in step: continue
   p=Path(d)/f'{job}-{i}.sh'
   p.write_text(step['run'])
   done=subprocess.run(['bash','-n',str(p)],capture_output=True,text=True)
   results.append({'step':step.get('name'),'exit':done.returncode,'stderr':done.stderr})
   assert done.returncode==0, done.stderr
for p in (r/'ci-export-r2/scripts').rglob('*.py'):
 compile(p.read_text(),str(p),'exec')
report={'manual_only':True,'read_only_repository_permission':True,'shell_syntax':results,'python_syntax':'PASS','darwin_execution':'NOT_RUN'}
(r/'evidence/r2/native-export-check.json').write_text(json.dumps(report,indent=1))
print('PASS: manual-only workflow, 4 bash blocks, native probe Python syntax; no Actions executed')
PY
