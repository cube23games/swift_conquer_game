from __future__ import annotations

from pathlib import Path

from io_utils import copy_file, load_json, sha256_file


class StageApplyError(RuntimeError):
    pass


def apply_stage(repo: Path, stage_root: Path) -> dict:
    manifest = load_json(stage_root / 'STAGE.json')
    payload = stage_root / 'payload'
    applied: list[dict] = []

    for record in manifest['files']:
        relative = record['path']
        source = payload / relative
        target = repo / relative
        if not source.is_file():
            raise StageApplyError(f'missing payload file: {relative}')
        digest = sha256_file(source)
        if digest != record['sha256']:
            raise StageApplyError(f'payload hash mismatch: {relative}')
        copy_file(source, target)
        if sha256_file(target) != digest:
            raise StageApplyError(f'copy verification failed: {relative}')
        applied.append({'path': relative, 'sha256': digest})

    return {
        'stage': manifest['stage'],
        'title': manifest['title'],
        'files': applied,
    }
