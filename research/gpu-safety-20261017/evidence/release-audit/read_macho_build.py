"""Static bounded header reads only; never execute or extract archive binaries."""
import pathlib,tarfile,struct,json
HERE=pathlib.Path(__file__).resolve().parent
def version(x):return f'{x>>16}.{(x>>8)&255}.{x&255}'
results={}
for tag in ['v2.3.1','v2.3.2','v2.3.3']:
    results[tag]={}
    with tarfile.open(HERE.parent.parent/'downloads'/('release-'+tag+'.tar.gz'),'r:gz') as tar:
        for m in tar:
            if not m.isfile() or pathlib.PurePosixPath(m.name).name not in ('NVMTLDriver','NVAccel','NVRM','NVRMFB','NVRMAGDC','libvulkan_nouveau.dylib'):continue
            with tar.extractfile(m) as f:
                h=f.read(32)
                if h[:4]!=b'\xcf\xfa\xed\xfe':raise ValueError(('not thin little-endian Mach-O64',m.name,h[:4].hex()))
                magic,cpu,subcpu,filetype,ncmds,sizeofcmds,flags,reserved=struct.unpack('<8I',h)
                if sizeofcmds>1024*1024:raise ValueError('unexpected header size')
                cmds=f.read(sizeofcmds)
            pos=0;build=[]
            for i in range(ncmds):
                cmd,size=struct.unpack_from('<II',cmds,pos)
                if size<8 or pos+size>len(cmds):raise ValueError('invalid load command')
                if cmd==0x32:
                    platform,minos,sdk,ntools=struct.unpack_from('<IIII',cmds,pos+8)
                    tools=[struct.unpack_from('<II',cmds,pos+24+j*8) for j in range(ntools)]
                    build.append({'command':'LC_BUILD_VERSION','platform':platform,'minos':version(minos),'sdk':version(sdk),'tools':[{'tool':t,'version':version(v)} for t,v in tools]})
                elif cmd==0x24:
                    minos,sdk=struct.unpack_from('<II',cmds,pos+8)
                    build.append({'command':'LC_VERSION_MIN_MACOSX','minos':version(minos),'sdk':version(sdk)})
                pos+=size
            results[tag][m.name]={'cpu':cpu,'subcpu':subcpu,'filetype':filetype,'ncmds':ncmds,'load_command_bytes':sizeofcmds,'build_version':build}
(HERE/'driver-macho-build.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
metal={tag:{name:value for name,value in members.items() if pathlib.PurePosixPath(name).name=='NVMTLDriver'} for tag,members in results.items()}
(HERE/'metal-macho-build.json').write_text(json.dumps(metal,indent=2),encoding='utf-8')
print(json.dumps(results,indent=2))
