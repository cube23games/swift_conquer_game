from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import json

from io_utils import relative_files, sha256_file, write_json


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def seal_evidence(root: Path, summary: dict) -> None:
    root.mkdir(parents=True, exist_ok=True)
    summary['created_utc'] = utc_now()
    write_json(root / 'summary.json', summary)

    lines = [
        'SwiftConquer SC-213–SC-270 Master Shadow Sweep',
        f'passed={summary["passed"]}',
        f'stages={summary["stage_count"]}',
        f'stage_failures={summary["stage_failure_count"]}',
        f'command_failures={summary["command_failure_count"]}',
    ]
    (root / 'RESULT.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')

    manifest = []
    for path in relative_files(root):
        if path.name == 'SHA256SUMS.txt':
            continue
        manifest.append(
            f'{sha256_file(path)}  {path.relative_to(root).as_posix()}'
        )
    (root / 'SHA256SUMS.txt').write_text(
        '\n'.join(manifest) + '\n',
        encoding='utf-8',
    )
