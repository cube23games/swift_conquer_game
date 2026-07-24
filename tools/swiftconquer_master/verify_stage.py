#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import json
import sys

RUNTIME = Path(__file__).resolve().parents[2] / '.auto-agent' / 'swiftconquer_master'
sys.path.insert(0, str(RUNTIME))

from io_utils import load_json
from stage_verify import verify_stage


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('stage')
    parser.add_argument('--repo', default='.')
    parser.add_argument('--json-output')
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    config = load_json(repo / '.auto-agent/swiftconquer_master/config.json')
    stage_root = repo / 'master_train' / 'stages' / args.stage
    result = verify_stage(repo, stage_root, config['dart_line_limit'])

    if args.json_output:
        Path(args.json_output).write_text(
            json.dumps(result, indent=2, sort_keys=True) + '\n',
            encoding='utf-8',
        )

    print(json.dumps({
        'stage': result['stage'],
        'passed': result['passed'],
        'checks': len(result['checks']),
    }, sort_keys=True))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
