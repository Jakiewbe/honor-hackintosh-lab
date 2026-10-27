"""Exact-name section-definition check. Never a loader/export/full-ABI claim."""


def check_imports(actual, contract):
    if contract['schema'] != 'honor.target-section-import-contract.v1':
        raise ValueError('unsupported target import contract')
    expected_list=contract['expected_imports']
    expected=set(expected_list)
    if not expected or len(expected)!=len(expected_list):
        raise ValueError('empty/duplicate expected import list')
    identities={r['name']:r['sha256'] for r in contract['collections']}
    definitions=contract['definitions']
    if set(definitions)!=expected: raise ValueError('definition/expected-name set mismatch')
    for name,rows in definitions.items():
        if not rows: raise ValueError('empty provider observation for '+name)
        for row in rows:
            sec=row['section']
            if (identities.get(row['collection'])!=row['collection_sha256'] or
                row['status']!='KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI' or
                row['n_type']!=15 or row['n_sect']!=sec['ordinal'] or
                not sec['address']<=row['value']<sec['address']+sec['size']):
                raise ValueError('invalid provider observation for '+name)
    unobserved=sorted(actual-set(definitions))
    unexpected=sorted(actual-expected)
    omitted=sorted(expected-actual)
    old_retained=sorted(actual&set(contract['enum_renames']))
    replacements_missing=sorted(set(contract['enum_renames'].values())-actual)
    passed=not any((unobserved,unexpected,omitted,old_retained,replacements_missing))
    return dict(status='ALL_IMPORT_NAMES_HAVE_SECTION_DEFINITIONS_NOT_ABI_OR_LOADER' if passed else 'FAILED',
        actual_count=len(actual),expected_count=len(expected),observed_count=len(actual)-len(unobserved),
        unobserved=unobserved,unexpected=unexpected,omitted=omitted,
        old_enum_imports_retained=old_retained,enum_replacements_missing=replacements_missing,
        full_abi='UNVERIFIED',loader='UNVERIFIED',passed=passed)
