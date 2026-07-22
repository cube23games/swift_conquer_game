#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from evidence import seal_directory


FORBIDDEN_SUFFIXES = {'.pem', '.key', '.jks', '.p12', '.keystore'}


def inspect(source: Path) -> None:
    for path in source.rglob('*'):
        if '__pycache__' in path.parts or path.suffix == '.pyc':
            if path.is_dir():
                shutil.rmtree(path)
            elif path.exists():
                path.unlink()
            continue
        if path.is_file() and path.suffix.lower() in FORBIDDEN_SUFFIXES:
            raise RuntimeError(f'Secret-like file is forbidden: {path}')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    source = Path(args.source).expanduser().resolve()
    output = Path(args.output).expanduser().resolve()
    inspect(source)
    _, checksum, digest = seal_directory(source, output)
    print(output)
    print(checksum)
    print(digest)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
