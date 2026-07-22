#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path.cwd().resolve()
MANIFEST = ROOT / '.auto-agent' / 'shadow_manifest.json'
RESULTS = Path(os.environ.get('RUNNER_TEMP', tempfile.gettempdir())) / 'auto-agent-shadow-results'


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def run_command(command: list[str], cwd: Path, timeout: int) -> dict[str, Any]:
    started = now()
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'},
        )
        output = result.stdout or ''
        return {
            'command': command,
            'started_utc': started,
            'finished_utc': now(),
            'exit_code': result.returncode,
            'passed': result.returncode == 0,
            'output': output,
        }
    except subprocess.TimeoutExpired as exc:
        output = ''
        if exc.stdout:
            output += exc.stdout if isinstance(exc.stdout, str) else exc.stdout.decode(errors='replace')
        return {
            'command': command,
            'started_utc': started,
            'finished_utc': now(),
            'exit_code': 124,
            'passed': False,
            'timed_out': True,
            'output': output,
        }


def command_list(manifest: dict, tree: dict) -> list[tuple[str, list[str]]]:
    result: list[tuple[str, list[str]]] = []
    for command in manifest.get('setup_commands', []):
        result.append(('setup', command))
    for command in manifest.get('validation_commands', []):
        result.append(('validation', command))
    for command in manifest.get('verifier_commands', []):
        result.append(('verifier', command))
    for command in tree.get('verifier_commands', []):
        result.append(('tree_verifier', command))
    return result


def write_stage_logs(stage_id: str, records: list[dict]) -> None:
    stage_dir = RESULTS / 'logs' / stage_id
    stage_dir.mkdir(parents=True, exist_ok=True)
    for index, record in enumerate(records, start=1):
        name = f'{index:02d}_{record["kind"]}.log'
        command = ' '.join(record['command'])
        text = (
            f'command: {command}\n'
            f'exit_code: {record["exit_code"]}\n'
            f'passed: {record["passed"]}\n\n'
            f'{record.get("output", "")}'
        )
        (stage_dir / name).write_text(text, encoding='utf-8')


def add_worktree(commit: str, path: Path) -> None:
    subprocess.run(
        ['git', 'worktree', 'add', '--detach', str(path), commit],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def remove_worktree(path: Path) -> None:
    subprocess.run(
        ['git', 'worktree', 'remove', '--force', str(path)],
        cwd=ROOT,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def main() -> int:
    if not MANIFEST.is_file():
        raise SystemExit(f'Missing shadow manifest: {MANIFEST}')
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    shutil.rmtree(RESULTS, ignore_errors=True)
    RESULTS.mkdir(parents=True, exist_ok=True)
    timeout = int(manifest.get('command_timeout_seconds', 1800))
    report: dict[str, Any] = {
        'schema_version': 1,
        'project_name': manifest.get('project_name', ROOT.name),
        'started_utc': now(),
        'base_commit': manifest.get('base_commit'),
        'control_commit': manifest.get('control_commit'),
        'trees': [],
        'platform_simulation': [],
    }
    all_passed = True
    final_worktree: Path | None = None

    for tree in manifest.get('trees', []):
        stage_id = tree['stage_id']
        commit = tree['commit']
        worktree: Path | None = Path(tempfile.mkdtemp(prefix=f'auto_agent_{stage_id}_'))
        shutil.rmtree(worktree)
        records: list[dict[str, Any]] = []
        try:
            assert worktree is not None
            add_worktree(commit, worktree)
            for kind, command in command_list(manifest, tree):
                record = run_command(command, worktree, timeout)
                record['kind'] = kind
                records.append(record)
                if not record['passed']:
                    all_passed = False
            report['trees'].append({
                'stage_id': stage_id,
                'commit': commit,
                'passed': all(record['passed'] for record in records),
                'commands': records,
            })
            write_stage_logs(stage_id, records)
            if tree.get('final'):
                final_worktree = worktree
                worktree = None
        finally:
            if worktree is not None and worktree.exists():
                remove_worktree(worktree)
                shutil.rmtree(worktree, ignore_errors=True)

    if final_worktree is not None:
        platform_records: list[dict[str, Any]] = []
        for command in manifest.get('platform_simulation_commands', []):
            record = run_command(command, final_worktree, timeout)
            record['kind'] = 'platform_simulation'
            platform_records.append(record)
            if not record['passed']:
                all_passed = False
        report['platform_simulation'] = platform_records
        write_stage_logs('PLATFORM_SIMULATION', platform_records)
        remove_worktree(final_worktree)
        shutil.rmtree(final_worktree, ignore_errors=True)

    report['finished_utc'] = now()
    report['passed'] = all_passed
    (RESULTS / 'results.json').write_text(
        json.dumps(report, indent=2, sort_keys=True) + '\n', encoding='utf-8'
    )

    summary = ['# Auto-Agent Shadow CI Summary', '']
    failures: list[str] = []
    for tree in report['trees']:
        icon = 'PASS' if tree['passed'] else 'FAIL'
        summary.append(f'- {tree["stage_id"]} `{tree["commit"]}`: **{icon}**')
        for record in tree['commands']:
            if not record['passed']:
                command = ' '.join(record['command'])
                failures.append(
                    f'{tree["stage_id"]}: exit {record["exit_code"]}: {command}'
                )
    for record in report['platform_simulation']:
        if not record['passed']:
            command = ' '.join(record['command'])
            failures.append(f'PLATFORM_SIMULATION: exit {record["exit_code"]}: {command}')
    summary.extend(['', f'Overall: **{"PASS" if all_passed else "FAIL"}**', ''])
    (RESULTS / 'SUMMARY.md').write_text('\n'.join(summary), encoding='utf-8')
    (RESULTS / 'FAILURES.txt').write_text(
        ('\n'.join(failures) + '\n') if failures else '', encoding='utf-8'
    )
    if all_passed:
        (RESULTS / 'PASS').write_text('shadow green\n', encoding='utf-8')
    return 0 if all_passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
