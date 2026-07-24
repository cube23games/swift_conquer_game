from __future__ import annotations

from pathlib import Path

from io_utils import load_json, sha256_file


def _line_count(path: Path) -> int:
    return len(path.read_text(encoding='utf-8').splitlines())


def verify_stage(repo: Path, stage_root: Path, line_limit: int) -> dict:
    manifest = load_json(stage_root / 'STAGE.json')
    checks: list[dict] = []

    for record in manifest['files']:
        relative = record['path']
        target = repo / relative
        exists = target.is_file()
        checks.append({
            'name': f'exists:{relative}',
            'passed': exists,
            'detail': relative,
        })
        if not exists:
            continue
        actual = sha256_file(target)
        checks.append({
            'name': f'hash:{relative}',
            'passed': actual == record['sha256'],
            'detail': actual,
        })
        if target.suffix == '.dart':
            count = _line_count(target)
            checks.append({
                'name': f'line_limit:{relative}',
                'passed': count <= line_limit,
                'detail': f'{count}/{line_limit}',
            })

    for token in manifest.get('required_tokens', []):
        target = repo / token['path']
        content = target.read_text(encoding='utf-8') if target.is_file() else ''
        checks.append({
            'name': f'token:{token["path"]}:{token["value"]}',
            'passed': token['value'] in content,
            'detail': token['value'],
        })

    passed = all(item['passed'] for item in checks)
    return {
        'stage': manifest['stage'],
        'title': manifest['title'],
        'device_gate': manifest.get('device_gate', False),
        'passed': passed,
        'checks': checks,
    }
