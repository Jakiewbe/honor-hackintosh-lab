#!/usr/bin/env python3
"""R35 heap-UAF negative control and R36 compile-negative control; CPU only."""
from pathlib import Path
import argparse,hashlib,json,subprocess,sys

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate',type=Path,required=True);p.add_argument('--ogkm-kapi',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True);p.add_argument('--cxx',default='g++')
    a=p.parse_args();a.out.mkdir(parents=True,exist_ok=False)
    root=Path(__file__).resolve().parents[1];old=root/'research/gpu-safety-r5/r35-caller-evidence'
    raw=(old/'fixture.cpp').read_text(encoding='utf-8');s=raw
    needle='static void nvKmsKapiFree(NvKmsKapiDevice *) { ++device_frees; }'
    assert s.count(needle)==1
    s=s.replace(needle,'static void nvKmsKapiFree(NvKmsKapiDevice *p) { ++device_frees; delete p; }')
    needle='    NvKmsKapiDevice device = {};';assert s.count(needle)==1
    s=s.replace(needle,'    auto *heap = new NvKmsKapiDevice{};\n    NvKmsKapiDevice &device = *heap;')
    source=a.out/'r35-real-free-control.cpp';source.write_text(s,encoding='utf-8')
    exe=a.out/'r35-asan'
    argv=[a.cxx,'-std=c++17','-O1','-g','-fsanitize=address','-fno-omit-frame-pointer',
          '-I'+str(old),str(source),str(old/'kms_deferred.cpp'),'-o',str(exe)]
    c=subprocess.run(argv,capture_output=True,text=True,timeout=60)
    (a.out/'r35-compile.txt').write_text(c.stdout+c.stderr,encoding='utf-8')
    assert c.returncode==0 and exe.is_file(),'old negative control did not compile'
    r=subprocess.run([str(exe),'drop-success'],capture_output=True,text=True,timeout=10)
    output=r.stdout+r.stderr;(a.out/'r35-asan.txt').write_text(output,encoding='utf-8')
    assert (r.returncode!=0 and 'heap-use-after-free' in output and
            'nvKmsKapiDeviceFreeCompleted' in output), 'old query must fail after real Device free'
    args=[sys.executable,str(root/'tools/g1_r36_try_free_contract.py'),'--candidate',str(a.candidate),
      '--ogkm-kapi',str(a.ogkm_kapi),'--out',str(a.out/'compile-negative'),'--cxx',a.cxx,'--negative-compile']
    n=subprocess.run(args,capture_output=True,text=True,timeout=90)
    nr=json.loads((a.out/'compile-negative/report.json').read_text())
    assert n.returncode!=0 and nr['compile_exit']!=0 and not nr['binary_exists'] and not nr['scenarios']
    report={'status':'CONTROLS_REJECTED_NOT_DRIVER_ACCEPTANCE','r35_original_fixture_sha256':hashlib.sha256(raw.encode()).hexdigest(),
      'r35_real_free_control_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
      'r35_compile_argv':argv,'r35_compile_exit':c.returncode,'r35_asan_exit':r.returncode,
      'r35_observation':'heap-use-after-free in nvKmsKapiDeviceFreeCompleted',
      'r36_compile_negative':'NONZERO_NO_BINARY_NO_SCENARIOS','device':'NO-GO'}
    (a.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report));return 0

if __name__=='__main__':raise SystemExit(main())
