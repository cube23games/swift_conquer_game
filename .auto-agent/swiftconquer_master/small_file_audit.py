from __future__ import annotations

from pathlib import Path


def audit_small_dart_files(repo: Path, limit: int) -> dict:
    roots = [repo / 'lib' / 'sc_master', repo / 'test' / 'sc_master']
    records: list[dict] = []
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob('*.dart')):
            count = len(path.read_text(encoding='utf-8').splitlines())
            records.append({
                'path': path.relative_to(repo).as_posix(),
                'lines': count,
                'limit': limit,
                'passed': count <= limit,
            })
    return {
        'passed': bool(records) and all(item['passed'] for item in records),
        'file_count': len(records),
        'records': records,
    }
