#!/usr/bin/env python3
from pathlib import Path
import json,subprocess,hashlib,shlex
R=Path('/mnt/d/Hactk/gpu-mainline-20261017')
NV=Path('/mnt/d/Hactk/g1-dev-20261015/upstream/open-gpu-kernel-modules')
OUT=R/'evidence/r3'
p=json.loads((OUT/'kapi-host-profile.json').read_text())
base=NV/'src/nvidia-modeset'
flags=['-std=gnu11','-Wall','-Wextra','-Werror','-Wno-unused-parameter','-Wno-missing-field-initializers','-Wno-sign-compare','-O2','-ffreestanding','-fno-builtin',
       *p['platform_definitions'],*p['make_definitions'],'-include',str(NV/'src/common/sdk/nvidia/inc/cpuopsys.h')]
flags += ['-I'+str((base/inc).resolve()) for inc in p['includes_relative_to_modeset']]
report={'level':'HOST-COMPILE only; entire real KAPI translation unit, not Darwin or GPU execution','profile':p,'checks':[]}
for label,src in [('original',base/'kapi/src/nvkms-kapi.c'),('candidate',R/'candidate/ogkm-e4a5faa-kapi-null-free-r3/src/nvidia-modeset/kapi/src/nvkms-kapi.c')]:
    args=['gcc',*flags,'-MMD','-MF',str(OUT/(label+'-kapi.d')),'-c',str(src),'-o',str(OUT/(label+'-kapi.o'))]
    with (OUT/(label+'-kapi-compile.txt')).open('w') as log:
        log.write('ARGV='+json.dumps(args)+'\n');log.flush()
        rc=subprocess.run(args,cwd=base,stdout=log,stderr=subprocess.STDOUT).returncode
        log.write('\nEXIT='+str(rc)+'\n')
    item={'label':label,'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'compile_exit':rc,'object_sha256':None}
    report['checks'].append(item)
    if rc==0:
        obj=OUT/(label+'-kapi.o');item['object_sha256']=hashlib.sha256(obj.read_bytes()).hexdigest()
        for name,cmd in [('undefined',['nm','-u']),('defined',['nm','--defined-only'])]:
            with (OUT/(label+'-kapi-'+name+'.txt')).open('w') as log:
                item[name+'_exit']=subprocess.run([*cmd,str(obj)],stdout=log,stderr=subprocess.STDOUT).returncode
    print(label,'full KAPI compile exit',rc)
(OUT/'kapi-host-compile.json').write_text(json.dumps(report,indent=1))
raise SystemExit(0 if all(i['compile_exit']==0 for i in report['checks']) else 1)
