#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import json
import os
import subprocess
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from command_runner import run_command
from evidence import seal_evidence
from io_utils import load_json, write_json
from small_file_audit import audit_small_dart_files
from stage_apply import apply_stage
from stage_verify import verify_stage


def _checkpoint_command(stage: str) -> list[str] | None:
    groups = {
        'SC-220': 'foundation',
        'SC-230': 'controls',
        'SC-240': 'economy',
        'SC-250': 'combat',
        'SC-260': 'domains',
        'SC-270': 'final',
    }
    group = groups.get(stage)
    if group is None:
        return None
    return ['flutter', 'test', f'test/sc_master/{group}']


def _record_command(evidence: Path, result) -> dict:
    safe = result.name.replace(' ', '_').replace('/', '_')
    log = evidence / 'commands' / f'{safe}.log'
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(
        f'command={" ".join(result.command)}\n'
        f'exit_code={result.exit_code}\n'
        f'seconds={result.seconds}\n\n'
        f'{result.output}',
        encoding='utf-8',
    )
    return {
        'name': result.name,
        'command': result.command,
        'exit_code': result.exit_code,
        'seconds': result.seconds,
        'passed': result.passed,
        'log': log.relative_to(evidence).as_posix(),
    }


def run_sweep(repo: Path, evidence: Path) -> int:
    config = load_json(repo / '.auto-agent/swiftconquer_master/config.json')
    registry = load_json(repo / '.auto-agent/swiftconquer_master/stage_registry.json')
    stage_results: list[dict] = []
    command_results: list[dict] = []

    pub_get = run_command(
        'flutter_pub_get',
        ['flutter', 'pub', 'get'],
        cwd=repo,
        timeout=1200,
    )
    command_results.append(_record_command(evidence, pub_get))

    for item in registry['stages']:
        stage = item['stage']
        stage_root = repo / 'master_train' / 'stages' / stage
        print(f'=== {stage}: {item["title"]} ===', flush=True)
        try:
            applied = apply_stage(repo, stage_root)
            verified = verify_stage(repo, stage_root, config['dart_line_limit'])
            result = {
                'stage': stage,
                'title': item['title'],
                'applied': applied,
                'verification': verified,
                'passed': verified['passed'],
            }
        except Exception as exc:
            result = {
                'stage': stage,
                'title': item['title'],
                'passed': False,
                'error': str(exc),
            }
        stage_results.append(result)
        write_json(evidence / 'stages' / f'{stage}.json', result)

        checkpoint = _checkpoint_command(stage)
        if checkpoint is not None:
            command = run_command(
                f'{stage}_checkpoint',
                checkpoint,
                cwd=repo,
                timeout=1200,
            )
            command_results.append(_record_command(evidence, command))

    small_files = audit_small_dart_files(repo, config['dart_line_limit'])
    write_json(evidence / 'small_file_audit.json', small_files)

    final_commands = [
        ('flutter_analyze', ['flutter', 'analyze'], 1800),
        ('flutter_test_all', ['flutter', 'test'], 2400),
        ('flutter_build_debug_apk', [
            'flutter', 'build', 'apk', '--debug',
            '--dart-define=SC_MASTER_SLICE=true',
        ], 3600),
    ]
    for name, command, timeout in final_commands:
        result = run_command(name, command, cwd=repo, timeout=timeout)
        command_results.append(_record_command(evidence, result))

    stage_failures = [item for item in stage_results if not item['passed']]
    command_failures = [item for item in command_results if not item['passed']]
    passed = (
        not stage_failures
        and not command_failures
        and small_files['passed']
        and len(stage_results) == 58
    )
    summary = {
        'schema_version': 1,
        'repository': config['repository'],
        'expected_base_commit': config['expected_base_commit'],
        'production_mutation': False,
        'automatic_tags': False,
        'stage_count': len(stage_results),
        'stage_failure_count': len(stage_failures),
        'command_failure_count': len(command_failures),
        'small_file_audit_passed': small_files['passed'],
        'passed': passed,
        'stages': stage_results,
        'commands': command_results,
    }
    seal_evidence(evidence, summary)
    return 0 if passed else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', default='.')
    parser.add_argument('--evidence', required=True)
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    evidence = Path(args.evidence).resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    return run_sweep(repo, evidence)


if __name__ == '__main__':
    raise SystemExit(main())
