#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

EXIT_FAILURE = 20
EXIT_CI_FAILURE = 30
EXIT_PAUSED = 31


class AgentStop(RuntimeError):
    pass


class ConfirmedCiFailure(RuntimeError):
    pass


class VerificationUnavailable(RuntimeError):
    pass


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def stamp() -> str:
    return datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def run(
    args: list[str],
    *,
    cwd: Path | None = None,
    check: bool = True,
    stream: bool = False,
) -> subprocess.CompletedProcess[str]:
    env = {**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'}
    if stream:
        result = subprocess.run(args, cwd=cwd, text=True, env=env)
    else:
        result = subprocess.run(
            args,
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=env,
        )
    if check and result.returncode != 0:
        output = '' if stream else (result.stdout or '')
        raise AgentStop(f"Command failed ({result.returncode}): {' '.join(args)}\n{output}")
    return result


def git(repo: Path, *args: str, check: bool = True) -> str:
    return run(['git', *args], cwd=repo, check=check).stdout.strip()


def github_slug(value: str) -> str:
    value = value.strip().rstrip('/')
    if value.startswith('git@github.com:'):
        path = value.split(':', 1)[1]
    elif value.startswith('ssh://git@github.com/'):
        path = value.split('github.com/', 1)[1]
    else:
        parsed = urlparse(value)
        if (parsed.hostname or '').lower() != 'github.com':
            return value.lower()
        path = parsed.path.lstrip('/')
    if path.endswith('.git'):
        path = path[:-4]
    return path.lower()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding='utf-8'))


def origin_url(repo: Path) -> str:
    result = run(['git', 'remote', 'get-url', 'origin'], cwd=repo, check=False)
    return result.stdout.strip() if result.returncode == 0 else ''


def atomic_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    temp.replace(path)


def verify_internal_manifest(package_root: Path) -> None:
    manifest = package_root / 'SHA256SUMS.txt'
    if not manifest.is_file():
        raise AgentStop('Missing package SHA256SUMS.txt')
    expected: dict[str, str] = {}
    for raw in manifest.read_text(encoding='utf-8').splitlines():
        if raw.strip():
            digest, relative = raw.split('  ', 1)
            expected[relative] = digest
    actual = {
        str(path.relative_to(package_root))
        for path in package_root.rglob('*')
        if path.is_file() and path != manifest
        and '__pycache__' not in path.parts and path.suffix != '.pyc'
    }
    if set(expected) != actual:
        raise AgentStop(
            f'Package file-list mismatch: missing={sorted(set(expected)-actual)} '
            f'extra={sorted(actual-set(expected))}'
        )
    for relative, digest in expected.items():
        if sha256_file(package_root / relative) != digest:
            raise AgentStop(f'Package checksum mismatch: {relative}')


def load_stages(package_root: Path, train: dict) -> list[dict]:
    stages: list[dict] = []
    for item in train['stages']:
        root = package_root / 'stages' / item['stage_id']
        metadata = load_json(root / 'STAGE_METADATA.json')
        metadata['_root'] = str(root)
        stages.append(metadata)
    stages.sort(key=lambda item: item['number'])
    return stages


def verify_payloads(stages: list[dict]) -> None:
    for stage in stages:
        root = Path(stage['_root'])
        expected = {record['path'] for record in stage['files']}
        actual = {
            str(path.relative_to(root / 'payload'))
            for path in (root / 'payload').rglob('*')
            if path.is_file() and '__pycache__' not in path.parts and path.suffix != '.pyc'
        }
        if expected != actual:
            raise AgentStop(f'{stage["stage_id"]} payload file-list mismatch')
        for record in stage['files']:
            if sha256_file(root / 'payload' / record['path']) != record['output_sha256']:
                raise AgentStop(f'{stage["stage_id"]} payload hash mismatch: {record["path"]}')


def status_paths(repo: Path) -> set[str]:
    raw = run(
        ['git', 'status', '--porcelain=v1', '--untracked-files=all'],
        cwd=repo,
    ).stdout
    result: set[str] = set()
    for line in raw.splitlines():
        if len(line) < 4:
            raise AgentStop(f'Malformed git status line: {line!r}')
        path = line[3:]
        if ' -> ' in path:
            path = path.split(' -> ', 1)[1]
        result.add(path)
    return result


def repository_snapshot(repo: Path, project: dict) -> dict:
    branch = git(repo, 'branch', '--show-current')
    head = git(repo, 'rev-parse', 'HEAD')
    origin = origin_url(repo)
    origin_head = ''
    if origin:
        result = run(['git', 'rev-parse', f'origin/{branch}'], cwd=repo, check=False)
        origin_head = result.stdout.strip() if result.returncode == 0 else ''
    return {
        'captured_utc': utc_now(),
        'repository': project.get('repository', ''),
        'repo_path': str(repo),
        'branch': branch,
        'head': head,
        'origin': origin,
        'origin_head': origin_head,
        'clean': not bool(git(repo, 'status', '--porcelain')),
        'tags': git(repo, 'tag', '--list').splitlines(),
    }


def verify_project(repo: Path, project: dict, expected_head: str | None) -> dict:
    if not (repo / '.git').exists():
        raise AgentStop(f'Not a Git repository: {repo}')
    branch = git(repo, 'branch', '--show-current')
    origin = origin_url(repo)
    head = git(repo, 'rev-parse', 'HEAD')
    dirty = git(repo, 'status', '--porcelain')
    if project.get('branch') and branch != project['branch']:
        raise AgentStop(f'Wrong branch: {branch}; expected {project["branch"]}')
    if project.get('repository') and origin and github_slug(origin) != project['repository'].lower():
        raise AgentStop(f'Wrong repository origin: {origin}')
    if expected_head and head != expected_head:
        raise AgentStop(f'Wrong HEAD: {head}; expected {expected_head}')
    if dirty:
        raise AgentStop('Working tree is not clean.')
    for relative in project.get('forbidden_paths', []):
        if (repo / relative).exists():
            raise AgentStop(f'Forbidden path exists: {relative}')
    if project.get('required_github_account') and shutil.which('gh'):
        account = run(['gh', 'api', 'user', '--jq', '.login'], check=False)
        if account.returncode != 0:
            raise VerificationUnavailable(account.stdout or 'GitHub account unavailable')
        if account.stdout.strip() != project['required_github_account']:
            raise AgentStop(
                f'Wrong GitHub account: {account.stdout.strip()}; '
                f'expected {project["required_github_account"]}'
            )
    if origin:
        fetched = run(['git', 'fetch', '--prune', 'origin', branch], cwd=repo, check=False)
        if fetched.returncode != 0:
            raise VerificationUnavailable(fetched.stdout or 'Origin verification unavailable')
        origin_head = git(repo, 'rev-parse', f'origin/{branch}')
        if origin_head != head:
            raise AgentStop(f'HEAD/origin mismatch: {head} != {origin_head}')
    return repository_snapshot(repo, project)


def verify_shadow_lock(package_root: Path, train: dict) -> dict:
    lock_name = train.get('shadow_lock_file', 'SHADOW_GREEN_LOCK.json')
    lock_path = package_root / lock_name
    if not lock_path.is_file():
        raise AgentStop(f'Missing shadow-green lock: {lock_name}')
    lock = load_json(lock_path)
    if lock.get('conclusion') != 'success' and lock.get('passed') is not True:
        raise AgentStop('Shadow lock is not green.')
    locked_stages = [item['stage_id'] if isinstance(item, dict) else item for item in lock.get('stages', [])]
    train_stages = [item['stage_id'] for item in train['stages']]
    if locked_stages and locked_stages != train_stages:
        raise AgentStop('Shadow lock stage order does not match production train.')
    return lock


def create_safety_branch(repo: Path, name: str, baseline: str) -> None:
    result = run(
        ['git', 'show-ref', '--verify', '--hash', f'refs/heads/{name}'],
        cwd=repo,
        check=False,
    )
    if result.returncode == 0:
        existing = result.stdout.strip()
        if existing != baseline:
            raise AgentStop(f'Safety branch {name} points to {existing}, expected {baseline}')
        return
    run(['git', 'branch', name, baseline], cwd=repo)


def apply_stage(repo: Path, stage: dict) -> None:
    root = Path(stage['_root'])
    for record in stage['files']:
        target = repo / record['path']
        expected = record.get('input_sha256')
        if expected is None:
            if target.exists():
                raise AgentStop(f'{stage["stage_id"]} expected new file: {record["path"]}')
        elif not target.is_file() or sha256_file(target) != expected:
            actual = sha256_file(target) if target.is_file() else 'missing'
            raise AgentStop(
                f'{stage["stage_id"]} input mismatch {record["path"]}: '
                f'{actual} != {expected}'
            )
    for record in stage['files']:
        source = root / 'payload' / record['path']
        target = repo / record['path']
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        if sha256_file(target) != record['output_sha256']:
            raise AgentStop(f'Output mismatch after copy: {record["path"]}')
    expected_paths = {record['path'] for record in stage['files']}
    changed = status_paths(repo)
    if changed != expected_paths:
        raise AgentStop(
            f'{stage["stage_id"]} changed-file mismatch: '
            f'expected={sorted(expected_paths)} actual={sorted(changed)}'
        )


def run_verifiers(repo: Path, stage: dict, log_dir: Path) -> None:
    commands = [
        *stage.get('historical_verifiers', []),
        *stage.get('stage_verifiers', []),
    ]
    log_dir.mkdir(parents=True, exist_ok=True)
    for index, command in enumerate(commands, start=1):
        result = run(command, cwd=repo, check=False)
        (log_dir / f'{index:02d}.log').write_text(
            f'command: {" ".join(command)}\nexit_code: {result.returncode}\n\n{result.stdout or ""}',
            encoding='utf-8',
        )
        if result.returncode != 0:
            raise AgentStop(
                f'{stage["stage_id"]} verifier failed: {" ".join(command)}\n'
                f'{result.stdout or ""}'
            )


def remote_sha(repo: Path, branch: str) -> str | None:
    result = run(['git', 'ls-remote', '--heads', 'origin', branch], cwd=repo, check=False)
    if result.returncode != 0:
        return None
    line = (result.stdout or '').strip()
    return line.split()[0] if line else None


def push_with_confirmation(repo: Path, branch: str, intended: str) -> None:
    delays = [0, 3, 8]
    outputs: list[str] = []
    for delay in delays:
        if delay:
            time.sleep(delay)
        result = run(['git', 'push', 'origin', branch], cwd=repo, check=False)
        outputs.append(result.stdout or '')
        observed = remote_sha(repo, branch)
        if observed == intended:
            return
    raise VerificationUnavailable(
        'Push could not be confirmed.\n' + '\n'.join(outputs)
    )


def find_run_id(repo_slug: str, workflow: str, commit: str) -> int:
    deadline = time.time() + 300
    while time.time() < deadline:
        result = run([
            'gh', 'run', 'list', '--repo', repo_slug,
            '--workflow', workflow, '--commit', commit, '--limit', '20',
            '--json', 'databaseId,headSha,status,conclusion,createdAt',
        ], check=False)
        if result.returncode == 0:
            items = json.loads(result.stdout or '[]')
            exact = [item for item in items if item.get('headSha') == commit]
            if exact:
                exact.sort(key=lambda item: item.get('createdAt', ''), reverse=True)
                return int(exact[0]['databaseId'])
        time.sleep(5)
    raise VerificationUnavailable(f'No exact CI run appeared for commit {commit}')


def view_run(repo_slug: str, run_id: int) -> dict:
    result = run([
        'gh', 'run', 'view', str(run_id), '--repo', repo_slug,
        '--json', 'databaseId,headSha,status,conclusion,url,workflowName',
    ], check=False)
    if result.returncode != 0:
        raise VerificationUnavailable(result.stdout or f'Run {run_id} unavailable')
    return json.loads(result.stdout or '{}')


def watch_run(repo_slug: str, run_id: int, intended: str) -> dict:
    watch = run([
        'gh', 'run', 'watch', str(run_id), '--repo', repo_slug, '--exit-status'
    ], check=False, stream=True)
    data = view_run(repo_slug, run_id)
    if data.get('headSha') != intended:
        raise AgentStop(f'Run {run_id} belongs to {data.get("headSha")}, expected {intended}')
    if data.get('status') != 'completed':
        raise VerificationUnavailable(f'Run {run_id} is not completed: {data}')
    if data.get('conclusion') != 'success':
        raise ConfirmedCiFailure(
            f'Run {run_id} completed with {data.get("conclusion")}'
        )
    if watch.returncode != 0 and data.get('conclusion') == 'success':
        return data
    return data


def evidence_zip(
    output_dir: Path,
    kind: str,
    state: dict,
    snapshot: dict,
    message: str,
    logs_root: Path,
) -> tuple[Path, str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='auto_agent_evidence_') as temp_name:
        temp = Path(temp_name)
        result = {
            'kind': kind,
            'created_utc': utc_now(),
            'message': message,
            'verification_level': state.get('verification_level', 'implemented'),
            'state': state,
            'repository': snapshot,
        }
        (temp / 'RESULT.txt').write_text(
            f'{kind}\n{message}\nverification_level={result["verification_level"]}\n',
            encoding='utf-8',
        )
        (temp / 'result.json').write_text(
            json.dumps(result, indent=2, sort_keys=True) + '\n', encoding='utf-8'
        )
        if logs_root.exists():
            shutil.copytree(logs_root, temp / 'logs')
        manifest_lines = []
        for path in sorted(temp.rglob('*')):
            if path.is_file() and path.name != 'SHA256SUMS.txt':
                manifest_lines.append(f'{sha256_file(path)}  {path.relative_to(temp)}')
        (temp / 'SHA256SUMS.txt').write_text('\n'.join(manifest_lines) + '\n', encoding='utf-8')
        output = output_dir / f'AUTO_AGENT_{kind.upper()}_EVIDENCE_{stamp()}.zip'
        with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for path in sorted(temp.rglob('*')):
                if path.is_file():
                    archive.write(path, path.relative_to(temp))
        with zipfile.ZipFile(output) as archive:
            bad = archive.testzip()
            if bad is not None:
                raise AgentStop(f'Evidence ZIP integrity failure: {bad}')
        digest = sha256_file(output)
        output.with_suffix(output.suffix + '.sha256').write_text(
            f'{digest}  {output.name}\n', encoding='utf-8'
        )
        return output, digest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--package-root', required=True)
    parser.add_argument('--repo')
    args = parser.parse_args()

    package_root = Path(args.package_root).expanduser().resolve()
    train = load_json(package_root / 'TRAIN_METADATA.json')
    repo = Path(args.repo or train.get('local_path') or '.').expanduser().resolve()
    project = load_json(repo / '.auto-agent' / 'project.json')
    stages = load_stages(package_root, train)
    state_root = Path.home() / '.local' / 'state' / 'project_auto_agent' / train['train_id']
    state_file = state_root / 'state.json'
    logs_root = state_root / 'logs'
    output_dir = Path(project.get('evidence_output_directory', '~/storage/downloads')).expanduser()

    state = load_json(state_file) if state_file.is_file() else {
        'train_id': train['train_id'],
        'created_utc': utc_now(),
        'completed_stages': [],
        'stage_runs': {},
        'verification_level': 'implemented',
        'current_head': train['expected_start_commit'],
    }
    snapshot: dict = {}
    try:
        verify_internal_manifest(package_root)
        verify_payloads(stages)
        shadow_lock = verify_shadow_lock(package_root, train)
        state['shadow_lock'] = shadow_lock
        expected_head = state.get('current_head') or train['expected_start_commit']
        snapshot = verify_project(repo, project, expected_head)
        create_safety_branch(
            repo,
            train['safety_branch'],
            train['expected_start_commit'],
        )
        completed = set(state.get('completed_stages', []))

        for stage in stages:
            stage_id = stage['stage_id']
            if stage_id in completed:
                print(f'{stage_id}: already production-CI verified; skipping')
                continue

            print(f'=== {stage_id}: {stage["title"]} ===', flush=True)
            run_state = state['stage_runs'].get(stage_id)
            if run_state:
                commit = run_state['commit']
                if git(repo, 'rev-parse', 'HEAD') != commit:
                    raise AgentStop(
                        f'{stage_id} resume HEAD mismatch: '
                        f'{git(repo, "rev-parse", "HEAD")} != {commit}'
                    )
                if git(repo, 'log', '-1', '--pretty=%s') != stage['commit_message']:
                    raise AgentStop(f'{stage_id} resume commit-message mismatch')
                status = run_state.get('status', 'committed')
                print(f'{stage_id}: resuming saved status {status}', flush=True)
            else:
                apply_stage(repo, stage)
                run_verifiers(repo, stage, logs_root / stage_id)
                allowed = [record['path'] for record in stage['files']]
                run(['git', 'add', '--', *allowed], cwd=repo)
                staged = set(git(repo, 'diff', '--cached', '--name-only').splitlines())
                if staged != set(allowed):
                    raise AgentStop(f'{stage_id} staged-file mismatch')
                run(['git', 'commit', '-m', stage['commit_message']], cwd=repo)
                commit = git(repo, 'rev-parse', 'HEAD')
                run_state = {'commit': commit, 'status': 'committed'}
                state['current_head'] = commit
                state['stage_runs'][stage_id] = run_state
                atomic_json(state_file, state)

            if project.get('push_after_local_verification', True) and run_state['status'] == 'committed':
                push_with_confirmation(repo, project['branch'], commit)
                run_state['status'] = 'pushed'
                atomic_json(state_file, state)

            if project.get('ci_enabled', True):
                if not shutil.which('gh'):
                    raise VerificationUnavailable('GitHub CLI is unavailable for CI verification')
                run_id = run_state.get('run_id')
                if not run_id:
                    run_id = find_run_id(
                        project['repository'],
                        project.get('production_workflow', 'CI'),
                        commit,
                    )
                    run_state['run_id'] = run_id
                run_state['status'] = 'watching'
                atomic_json(state_file, state)
                data = watch_run(project['repository'], int(run_id), commit)
                run_state.update({
                    'status': 'success',
                    'conclusion': data.get('conclusion'),
                    'url': data.get('url'),
                })
                state['verification_level'] = 'production CI verified'
            else:
                run_state['status'] = 'locally_verified'
                state['verification_level'] = 'locally verified'

            if stage_id not in state['completed_stages']:
                state['completed_stages'].append(stage_id)
            completed.add(stage_id)
            atomic_json(state_file, state)
            snapshot = repository_snapshot(repo, project)

        snapshot = repository_snapshot(repo, project)
        output, digest = evidence_zip(
            output_dir, 'success', state, snapshot,
            'Production train completed without automatic tagging.', logs_root,
        )
        print(f'SUCCESS evidence ZIP: {output}')
        print(f'SUCCESS evidence SHA-256: {digest}')
        return 0

    except ConfirmedCiFailure as exc:
        snapshot = snapshot or repository_snapshot(repo, project)
        output, digest = evidence_zip(
            output_dir, 'confirmed_ci_failure', state, snapshot, str(exc), logs_root
        )
        print(f'CI FAILURE evidence ZIP: {output}')
        print(f'CI FAILURE evidence SHA-256: {digest}')
        return EXIT_CI_FAILURE
    except VerificationUnavailable as exc:
        atomic_json(state_file, state)
        snapshot = snapshot or repository_snapshot(repo, project)
        output, digest = evidence_zip(
            output_dir, 'paused', state, snapshot, str(exc), logs_root
        )
        print('State is saved. Rerun the same package to resume safely.')
        print(f'PAUSED evidence ZIP: {output}')
        print(f'PAUSED evidence SHA-256: {digest}')
        return EXIT_PAUSED
    except Exception as exc:
        snapshot = snapshot or repository_snapshot(repo, project)
        output, digest = evidence_zip(
            output_dir, 'failure', state, snapshot, str(exc), logs_root
        )
        print(f'FAILURE: {exc}')
        print(f'FAILURE evidence ZIP: {output}')
        print(f'FAILURE evidence SHA-256: {digest}')
        return EXIT_FAILURE


if __name__ == '__main__':
    raise SystemExit(main())
