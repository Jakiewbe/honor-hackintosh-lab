"""Offline manifest-only plan for per-target ACPI external-table disassembly."""
import argparse
import json
from pathlib import Path
from acpi_static_validate_inputs import validate

ROOT = Path(__file__).resolve().parents[1]
CONFLICT_GROUPS = (
    ('reg_SSD3_HONOR_SaSsdt__00003000.bin', 'reg_SSD9_HONOR_ADL-P-M_00000002.bin'),
    ('reg_SSDB_HONOR_xh_adlLP_00000000.bin', 'reg_DSDT_HONOR_ADL-P-M_00000002.bin'),
)


def select_externals(tables, target):
    """Keep the target untouched; avoid the observed DSDT/SSDT9 touchpad collision."""
    if len(tables) != 16 or len(set(tables)) != 16 or target not in tables:
        raise ValueError('Expected 16 unique primary tables and a known target')
    if not all(set(group) <= set(tables) for group in CONFLICT_GROUPS):
        raise ValueError('Missing conflict-group input')
    excluded = []
    for group in CONFLICT_GROUPS:
        if target in group:
            drop = next(name for name in group if name != target)
            reason = 'Target belongs to this group; exclude its other member'
        else:
            if group == CONFLICT_GROUPS[0]:
                drop = group[1]
                reason = 'Prefer SaSsdt; DSDT and SSDT9 also collide at I2C0.TPD0._PS0/_PS3'
            elif target == CONFLICT_GROUPS[0][1]:
                drop = group[1]
                reason = 'SSDT9 is the target; keep xh_adlLP to avoid DSDT/SSDT9 touchpad collision'
            else:
                drop = group[0]
                reason = 'Prefer DSDT when SSDT9 is neither target nor external'
        excluded.append({'file': drop, 'reason': reason, 'group': list(group)})
    drop_names = {row['file'] for row in excluded}
    return {'target': target,
            'externals': [name for name in tables if name != target and name not in drop_names],
            'excluded': excluded}


def build_plan():
    inputs = validate()
    tables = [Path(row['file']).name for row in inputs['files'] if row['role'] == 'PRIMARY_AML']
    return {'schema': 1, 'evidence_level': 'SOURCE-STATIC', 'runtime': 'RUNTIME_NO_GO',
            'policy': 'Exclude exactly two members of the declared groups; choose representatives also avoiding the observed DSDT/SSDT9 touchpad collision; never change target AML',
            'runs': [select_externals(tables, target) for target in tables]}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = build_plan()
    text = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    if args.output:
        args.output.write_text(text, encoding='utf-8')
    else:
        print(text, end='')
