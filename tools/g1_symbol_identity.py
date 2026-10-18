#!/usr/bin/env python3
"""Keep Mach-O spelling distinct from C/Itanium spelling; parse nm -u only."""
import re

SYMBOL = re.compile(r'_[A-Za-z0-9_.$]+\Z')


def source_spelling(macho):
    if not SYMBOL.fullmatch(macho):
        raise ValueError('expected a Mach-O external symbol with its ABI underscore')
    return macho[1:]


def identity(macho):
    spelling = source_spelling(macho)
    kind = 'itanium-cxx-mangled' if spelling.startswith('_Z') else 'c-or-assembler'
    return {'macho_symbol': macho, 'source_spelling': spelling, 'name_kind': kind}


def parse_nm_undefined(text):
    """Accept Darwin nm -u bare names or nm default U records; reject ambiguity.

    Optional ARGV/EXIT lines belong to our execute() log wrapper. A wrapped
    inventory requires a final EXIT=0; failed or truncated nm output is rejected.
    Defined symbols, archive headers and diagnostics are not silently skipped.
    """
    symbols = []
    wrapped, exited = False, False
    for line_no, line in enumerate(text.splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        if line_no == 1 and line.startswith('ARGV='):
            import json
            argv = json.loads(line[5:])
            if not (isinstance(argv, list) and all(isinstance(a, str) for a in argv)
                    and 'nm' in argv and '-u' in argv and '-gU' not in argv):
                raise ValueError('ARGV must describe nm -u')
            wrapped = True
            continue
        if wrapped and line == 'EXIT=0' and not exited:
            exited = True
            continue
        if exited:
            raise ValueError('unexpected content after nm exit record')
        match = re.fullmatch(r'(?:U\s+)?(_[A-Za-z0-9_.$]+)', line)
        if not match:
            raise ValueError(f'unrecognised nm undefined record at line {line_no}')
        symbols.append(match.group(1))
    if wrapped and not exited:
        raise ValueError('wrapped nm inventory is incomplete or failed')
    if not symbols:
        raise ValueError('empty undefined inventory needs independent nm exit evidence')
    return symbols
