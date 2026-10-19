#!/usr/bin/env python3
"""Retired acceptance path. Original fixture survives only as an ASan negative control."""
import sys


def main():
    print('RETIRED_R35_FALSE_ACCEPTANCE: fixture did not free Device; post-free query is unsafe.', file=sys.stderr)
    print('Use gpu-safety-r5-native.yml and g1_r36_try_free_contract.py; GPU remains NO-GO.', file=sys.stderr)
    return 2


if __name__ == '__main__':
    raise SystemExit(main())
