#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import hashlib
import json
import subprocess
import sys


BASE = 'dbedc8dd830b380b11e36d9f8e6bf3c8065973c4'
GREEN = '23210b91e9fdb98c7f4981943132b7652608b075'


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            value.update(block)
    return value.hexdigest()


def command(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def main() -> int:
    root = Path('.').resolve()
    registry = json.loads(
        (root / '.auto-agent/promotion/registry.json').read_text()
    )
    lines = command(
        'git', 'log', '--reverse', '--format=%s', f'{BASE}..HEAD'
    ).splitlines()
    if len(lines) != 58:
        print(f'FAIL: expected 58 commits, got {len(lines)}')
        return 1

    failures: list[str] = []
    for index, item in enumerate(registry['stages']):
        stage = item['stage']
        manifest = json.loads(
            (root / '.auto-agent/promotion/stages' / f'{stage}.json')
            .read_text()
        )
        if lines[index] != manifest['commit_message']:
            failures.append(f'{stage}: commit message mismatch')
        for record in manifest['files']:
            target = root / record['path']
            if not target.is_file():
                failures.append(f'{stage}: missing {record["path"]}')
            elif digest(target) != record['sha256']:
                failures.append(f'{stage}: hash mismatch {record["path"]}')

    diff = subprocess.run([
        'git', 'diff', '--exit-code', GREEN, '--',
        'lib/main.dart', 'lib/sc_master', 'test/sc_master',
    ], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if diff.returncode != 0:
        failures.append('final tree differs from green Shadow specimen')

    dart_files = list((root / 'lib/sc_master').rglob('*.dart'))
    dart_files += list((root / 'test/sc_master').rglob('*.dart'))
    for path in dart_files:
        count = len(path.read_text().splitlines())
        if count > 160:
            failures.append(
                f'line limit exceeded: {path.relative_to(root)}={count}'
            )

    if failures:
        print('\n'.join(f'FAIL: {value}' for value in failures))
        return 1
    print('PASS: 58 ordered commits match green Shadow specimen')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
