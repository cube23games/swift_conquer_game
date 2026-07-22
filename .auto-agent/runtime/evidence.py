#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import zipfile
from pathlib import Path
from typing import Any


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n', encoding='utf-8')


def seal_directory(source: Path, output_zip: Path) -> tuple[Path, Path, str]:
    source = source.resolve()
    output_zip.parent.mkdir(parents=True, exist_ok=True)
    manifest = source / 'SHA256SUMS.txt'
    members = [
        path for path in sorted(source.rglob('*'))
        if path.is_file() and path != manifest
        and '__pycache__' not in path.parts and path.suffix != '.pyc'
    ]
    manifest.write_text(
        ''.join(f'{sha256(path)}  {path.relative_to(source)}\n' for path in members),
        encoding='utf-8',
    )
    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(source.rglob('*')):
            if path.is_file() and '__pycache__' not in path.parts and path.suffix != '.pyc':
                archive.write(path, f'{source.name}/{path.relative_to(source)}')
    with zipfile.ZipFile(output_zip) as archive:
        bad = archive.testzip()
        if bad is not None:
            raise RuntimeError(f'ZIP integrity failure: {bad}')
    digest = sha256(output_zip)
    checksum = output_zip.with_suffix(output_zip.suffix + '.sha256')
    checksum.write_text(f'{digest}  {output_zip.name}\n', encoding='utf-8')
    return output_zip, checksum, digest
