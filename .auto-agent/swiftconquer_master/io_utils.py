from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding='utf-8'))


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + '\n',
        encoding='utf-8',
    )


def copy_file(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def relative_files(root: Path) -> list[Path]:
    return sorted(
        path for path in root.rglob('*')
        if path.is_file() and '__pycache__' not in path.parts
        and path.suffix != '.pyc'
    )
