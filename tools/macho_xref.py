#!/usr/bin/env python3
"""Read exact LC_DYSYMTAB external relocations of a zero-based x86_64 kext.

No instruction-byte scan, no execution. A symbol interval is a static container,
not proof of a runtime call. Unsupported layouts fail rather than guessing bases.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from g1_kc8 import bounded, header
from macho_imports import parse_bytes


def observe(data, want):
    imports = parse_bytes(data)
    if want not in imports: raise ValueError('requested exact Mach-O import not found')
    h = header(data)
    text = [s for s in h['segments'] if s['name']=='__TEXT']
    if h['filetype'] != 11 or len(text)!=1 or text[0]['vmaddr']!=0 or text[0]['fileoff']!=0:
        raise ValueError('only zero-based thin x86_64 MH_KEXT_BUNDLE supported')
    commands=[c for c in h['load_commands'] if int(c['cmd'],16)==0xb]
    if len(commands)!=1 or commands[0]['bytes']!=80:
        raise ValueError('one bounded LC_DYSYMTAB required')
    fields=struct.unpack('<18I',bounded(data,commands[0]['offset']+8,72))
    table=h['symtab'];strings=bounded(data,table['stroff'],table['strsize'])
    symbols=[]
    for i in range(table['nsyms']):
        at=table['symoff']+16*i
        index,kind,sect,desc,value=struct.unpack('<IBBHQ',bounded(data,at,16))
        # parse_bytes already validated every string entry's bounds/termination.
        end=strings.index(b'\0',index)
        symbols.append({'index':i,'name':strings[index:end].decode('utf-8'),
            'type':kind,'section':sect,'value':value,'nlist_file_offset':at})
    target=[s for s in symbols if s['name']==want and s['type']==1 and s['value']==0 and s['section']==0]
    if len(target)!=1: raise ValueError('one ordinary external undefined symbol required')
    target=target[0]
    undef_start,undef_count=fields[4:6]
    if undef_start+undef_count>len(symbols) or not undef_start<=target['index']<undef_start+undef_count:
        raise ValueError('target outside declared undefined symbol range')
    ext_start,ext_count=fields[14:16]
    bounded(data,ext_start,ext_count*8)
    # Linkedit table bounds are checked against the actual segment as well.
    for at,size in [(table['symoff'],16*table['nsyms']),(table['stroff'],table['strsize']),
                    (ext_start,ext_count*8)]:
        if not any(s['name']=='__LINKEDIT' and s['fileoff']<=at and at+size<=s['fileoff']+s['filesize'] for s in h['segments']):
            raise ValueError('symbol/relocation table outside __LINKEDIT')
    definitions=[s for s in symbols if not s['type']&0xe0 and s['type']&0x0e==0x0e]
    refs=[]
    for i in range(ext_count):
        at=ext_start+8*i;raw=bounded(data,at,8)
        address,word=struct.unpack('<iI',raw)
        if address<0: raise ValueError('scattered/negative external relocation unsupported')
        index,external=word&0xffffff,(word>>27)&1
        if not external or index>=len(symbols): raise ValueError('invalid external relocation symbol index')
        if index!=target['index']:continue
        width=1<<((word>>25)&3)
        sections=[s for s in h['sections'] if s['address']<=address and address+width<=s['address']+s['size']]
        if len(sections)!=1:raise ValueError('relocation target outside unique section')
        sec=sections[0]
        if sec['flags']&0xff in (1,0xc,0x12):raise ValueError('relocation into non-file-backed section unsupported')
        filepos=sec['offset']+address-sec['address']
        value=bounded(data,filepos,width)
        if not any(s['fileoff']<=filepos and filepos+width<=s['fileoff']+s['filesize'] and
                   s['vmaddr']+filepos-s['fileoff']==address for s in h['segments']):
            raise ValueError('relocation section/file/VM mapping differs')
        same=[s for s in definitions if s['section']==sec['ordinal']]
        previous=[s for s in same if sec['address']<=s['value']<=address]
        if not previous:raise ValueError('no bounded preceding definition')
        begin=max(s['value'] for s in previous)
        owners=[s for s in previous if s['value']==begin]
        stop=min([s['value'] for s in same if s['value']>begin]+[sec['address']+sec['size']])
        if address+width>stop:raise ValueError('relocation overlaps next symbol interval')
        refs.append({'ordinal':i,'relocation_file_offset':at,'relocation_bytes_hex':raw.hex(),
            'address':address,'file_offset':filepos,'symbol_index':index,'pcrel':(word>>24)&1,
            'length_log2':(word>>25)&3,'external':external,'type':word>>28,
            'value_bytes_hex':value.hex(),'section':sec,'container_symbols':owners,
            'container_start':begin,'container_end_exclusive':stop,'offset_in_container':address-begin,
            'classification':'CODE_REFERENCE_NOT_DISASSEMBLED' if sec['flags']&0x80000400 else 'DATA_REFERENCE_NOT_A_DIRECT_CALL'})
    return {'schema':'honor.g1.kext-external-refs.v1','binary_sha256':hashlib.sha256(data).hexdigest(),
        'binary_bytes':len(data),'symbol':want,'target_nlist':target,'load_command_count':len(h['load_commands']),
        'extreloff':ext_start,'nextrel':ext_count,'references':refs,
        'status':'EXACT_EXTERNAL_RELOCATIONS_OBSERVED' if refs else 'NO_SELECTED_EXTERNAL_RELOCATIONS_OBSERVED',
        'limits':['zero-based Intel kext only; no inferred alternate relocation base',
            'symbol intervals may include aliases; not proof of source TU or executed call',
            'no-reference result does not rule out dynamic/vtable calls'], 'kext_load':'NO-GO'}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('binary',type=Path);p.add_argument('--symbol',required=True);p.add_argument('--json',type=Path,required=True)
    args=p.parse_args()
    report=observe(args.binary.read_bytes(),args.symbol)
    args.json.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'status':report['status'],'external_relocations':report['nextrel'],'selected_references':len(report['references'])}))
    return 0 if report['references'] else 2


if __name__=='__main__':raise SystemExit(main())
