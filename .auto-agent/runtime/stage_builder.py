#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(
        ['git', *args],
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and result.returncode != 0:
        raise RuntimeError((result.stderr or result.stdout).decode(errors='replace'))
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', default='.')
    parser.add_argument('--output-root', required=True)
    parser.add_argument('--stage-id', required=True)
    parser.add_argument('--number', type=int, required=True)
    parser.add_argument('--title', required=True)
    parser.add_argument('--commit-message', required=True)
    parser.add_argument('--base-ref', default='HEAD')
    parser.add_argument('--file', action='append', dest='files', required=True)
    parser.add_argument('--stage-verifier', action='append', default=[])
    parser.add_argument('--historical-verifier', action='append', default=[])
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    stage_root = Path(args.output_root).expanduser().resolve() / args.stage_id
    payload = stage_root / 'payload'
    if stage_root.exists():
        shutil.rmtree(stage_root)
    payload.mkdir(parents=True)

    records = []
    for relative in args.files:
        source = repo / relative
        if not source.is_file():
            raise RuntimeError(f'Missing output file: {relative}')
        baseline = git(repo, 'show', f'{args.base_ref}:{relative}', check=False)
        input_hash = sha256_bytes(baseline.stdout) if baseline.returncode == 0 else None
        target = payload / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        records.append({
            'path': relative,
            'input_sha256': input_hash,
            'output_sha256': sha256_file(target),
        })

    metadata = {
        'schema_version': 1,
        'stage_id': args.stage_id,
        'number': args.number,
        'title': args.title,
        'commit_message': args.commit_message,
        'files': records,
        'stage_verifiers': [item.split() for item in args.stage_verifier],
        'historical_verifiers': [item.split() for item in args.historical_verifier],
    }
    (stage_root / 'STAGE_METADATA.json').write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + '\n', encoding='utf-8'
    )
    print(stage_root)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
