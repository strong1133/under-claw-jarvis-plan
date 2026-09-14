#!/usr/bin/env python3
"""Package the common contract into each independently installable skill."""
import argparse
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ('under-claw-jarvis-plan', 'under-claw-jarvis-plan-loop', 'under-claw-meta-prompt')


def snapshot(root):
    return {p.relative_to(root): p.read_bytes() for p in root.rglob('*')
            if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    source = ROOT / 'shared'
    expected = snapshot(source)
    different = []
    for name in SKILLS:
        target = ROOT / 'skills' / name / 'shared'
        if snapshot(target) == expected:
            continue
        if args.check:
            different.append(name)
        else:
            target.mkdir(parents=True, exist_ok=True)
            for rel in snapshot(target).keys() - expected.keys():
                (target / rel).unlink()
            for rel in expected:
                (target / rel).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source / rel, target / rel)
    if different:
        print('Shared bundle drift: ' + ', '.join(different))
        return 1
    print('Shared bundles synchronized')
    return 0


if __name__ == '__main__':
    sys.exit(main())
