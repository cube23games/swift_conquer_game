#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path
from urllib.parse import urlparse


class DoctorError(RuntimeError):
    pass


def run(args: list[str], cwd: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        args,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if check and result.returncode != 0:
        raise DoctorError(f"Command failed: {' '.join(args)}\n{result.stdout or ''}")
    return result


def slug(value: str) -> str:
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', default='.')
    parser.add_argument('--config', default='.auto-agent/project.json')
    parser.add_argument('--require-clean', action='store_true')
    parser.add_argument('--fetch', action='store_true')
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    config_path = repo / args.config
    if not config_path.is_file():
        raise DoctorError(f'Missing project config: {config_path}')
    config = json.loads(config_path.read_text(encoding='utf-8'))
    if not (repo / '.git').exists():
        raise DoctorError(f'Not a Git repository: {repo}')

    branch = run(['git', 'branch', '--show-current'], repo).stdout.strip()
    head = run(['git', 'rev-parse', 'HEAD'], repo).stdout.strip()
    origin_result = run(['git', 'remote', 'get-url', 'origin'], repo, check=False)
    origin = origin_result.stdout.strip() if origin_result.returncode == 0 else ''
    dirty = run(['git', 'status', '--porcelain'], repo).stdout.strip()
    tags = run(['git', 'tag', '--list'], repo).stdout.splitlines()

    if config.get('branch') and branch != config['branch']:
        raise DoctorError(f'Wrong branch: {branch}; expected {config["branch"]}')
    if config.get('repository') and origin and slug(origin) != config['repository'].lower():
        raise DoctorError(f'Wrong origin: {origin}')
    if args.require_clean and dirty:
        raise DoctorError('Working tree is not clean.')

    account = ''
    if config.get('required_github_account') and shutil.which('gh'):
        result = run(['gh', 'api', 'user', '--jq', '.login'], repo, check=False)
        if result.returncode == 0:
            account = result.stdout.strip()
            if account != config['required_github_account']:
                raise DoctorError(
                    f'Wrong GitHub account: {account}; expected {config["required_github_account"]}'
                )

    origin_head = ''
    if args.fetch and origin:
        fetched = run(['git', 'fetch', '--prune', 'origin', branch], repo, check=False)
        if fetched.returncode != 0:
            raise DoctorError(f'Origin verification unavailable:\n{fetched.stdout or ""}')
        origin_head = run(['git', 'rev-parse', f'origin/{branch}'], repo).stdout.strip()
        if origin_head != head:
            raise DoctorError(f'HEAD/origin mismatch: {head} != {origin_head}')

    forbidden_present = [
        relative for relative in config.get('forbidden_paths', [])
        if (repo / relative).exists()
    ]
    if forbidden_present:
        raise DoctorError(f'Forbidden paths exist: {forbidden_present}')

    result = {
        'status': 'pass',
        'repository': config.get('repository', ''),
        'repo_path': str(repo),
        'account': account,
        'branch': branch,
        'head': head,
        'origin': origin,
        'origin_head': origin_head,
        'clean': not bool(dirty),
        'tags': tags,
        'ci_only_builds': bool(config.get('ci_only_builds')),
        'automatic_tagging': bool(config.get('automatic_tagging')),
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except DoctorError as exc:
        print(f'FAIL: {exc}')
        raise SystemExit(20)
