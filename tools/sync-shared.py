#!/usr/bin/env python3
"""Package the common contract into each independently installable skill."""
import argparse
import json
from pathlib import Path
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
    common = snapshot(source)
    manifest = json.loads((source / 'components.json').read_text())
    for component in manifest['components']:
        if not component['skills'] or any(skill not in SKILLS for skill in component['skills']):
            print('Invalid component skill scope: ' + component['id'], file=sys.stderr)
            return 1
        if Path(component['adapter']) not in common:
            print('Missing component source: ' + component['adapter'], file=sys.stderr)
            return 1
    different = []
    for name in SKILLS:
        components = [c for c in manifest['components'] if name in c['skills']]
        adapters = {Path(c['adapter']) for c in components}
        expected = {rel: content for rel, content in common.items()
                    if rel.parts[0] != 'components' or rel in adapters}
        # The installed guide must only name adapter paths actually in this bundle.
        excluded = [c['adapter'] for c in manifest['components'] if c not in components]
        guide = common[Path('components.md')].decode()
        expected[Path('components.md')] = ''.join(
            line for line in guide.splitlines(keepends=True)
            if not (line.startswith('|') and any(adapter in line for adapter in excluded))
        ).encode()
        expected[Path('components.json')] = (json.dumps(
            dict(manifest, components=components), indent=2) + '\n').encode()
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
                (target / rel).write_bytes(expected[rel])
    if different:
        print('Shared bundle drift: ' + ', '.join(different))
        return 1
    print('Shared bundles synchronized')
    return 0


if __name__ == '__main__':
    sys.exit(main())
