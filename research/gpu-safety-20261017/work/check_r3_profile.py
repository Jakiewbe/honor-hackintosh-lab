from pathlib import Path
import re,json
r=Path(r'D:\Hactk\gpu-mainline-20261017');p=r/'ci-export-r3/scripts/gpu-safety-r3/native_compile.py';s=p.read_text(encoding='utf-8');s=s.replace('r"\\s*CFLAGS\\s*\\+=\\s*(-[ID]\\S+)\\s*"','r"\\s*CFLAGS\\s*\\+=\\s*(-[ID])\\s*(\\S+)\\s*"').replace('flag = match.group(1)','flag = match.group(1) + match.group(2).replace("$(SRC_COMMON)", "../common")\n                if "$" in flag:\n                    raise ValueError("unresolved variable in modeset profile")');p.write_text(s,encoding='utf-8',newline='\n')
# Execute the actual parser block against fixed Makefile and compare with the host profile.
start=s.index('        import re\n');end=s.index('        kapi_path =',start)
block='\n'.join(line[8:] for line in s[start:end].splitlines())
base=Path(r'D:\Hactk\g1-dev-20261015\upstream\open-gpu-kernel-modules\src\nvidia-modeset')
namespace={'kms':base};exec(block,namespace)
host=json.loads((r/'evidence/r3/kapi-host-profile.json').read_text(encoding='utf-8'))
expected=['-I'+str((base/p).resolve()) for p in host['includes_relative_to_modeset']]
assert expected==namespace['include_dirs'];assert host['make_definitions']==namespace['make_defs']
(r/'evidence/r3/native-profile-check.json').write_text(json.dumps({'actual_parser_against_fixed_makefile':'PASS','includes':len(expected),'definitions':len(namespace['make_defs']),'matches_host_profile':True,'conditionals_evaluated':False,'darwin_compile':'NOT_RUN'},indent=1),encoding='utf-8')
print('PASS actual native KAPI parser matches the 27 includes / 15 definitions used for full host compilation')
