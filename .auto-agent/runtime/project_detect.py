#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path
from urllib.parse import urlparse


class DetectionError(RuntimeError):
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
        raise DetectionError(
            f"Command failed ({result.returncode}): {' '.join(args)}\n{result.stdout or ''}"
        )
    return result


def github_slug(origin: str) -> str | None:
    value = origin.strip().rstrip('/')
    if not value:
        return None
    if value.startswith('git@github.com:'):
        path = value.split(':', 1)[1]
    elif value.startswith('ssh://git@github.com/'):
        path = value.split('github.com/', 1)[1]
    elif value.startswith('http://') or value.startswith('https://'):
        parsed = urlparse(value)
        if (parsed.hostname or '').lower() != 'github.com':
            return None
        path = parsed.path.lstrip('/')
    else:
        return None
    if path.endswith('.git'):
        path = path[:-4]
    parts = [part for part in path.split('/') if part]
    return '/'.join(parts[:2]) if len(parts) >= 2 else None


def detect_project_type(repo: Path) -> str:
    if (repo / 'pubspec.yaml').is_file():
        return 'flutter'
    if (repo / 'package.json').is_file():
        return 'node'
    if (repo / 'pyproject.toml').is_file() or (repo / 'requirements.txt').is_file():
        return 'python'
    if (repo / 'gradlew').is_file() or (repo / 'build.gradle').is_file() or (repo / 'build.gradle.kts').is_file():
        return 'gradle'
    if any(repo.glob('*.py')):
        return 'python'
    return 'generic'


def default_commands(project_type: str, repo: Path | None = None) -> dict[str, list[list[str]]]:
    if project_type == 'flutter':
        return {
            'setup_commands': [['flutter', 'pub', 'get']],
            'validation_commands': [
                ['flutter', 'analyze', '--no-fatal-infos'],
                ['flutter', 'test'],
            ],
        }
    if project_type == 'python':
        return {
            'setup_commands': [],
            'validation_commands': [
                ['python3', '-m', 'compileall', '-q', '.'],
                ['python3', '-m', 'pytest', '-q'],
            ],
        }
    if project_type == 'node':
        lock = (repo / 'package-lock.json').is_file() if repo is not None else False
        setup = [['npm', 'ci']] if lock else [['npm', 'install']]
        return {
            'setup_commands': setup,
            'validation_commands': [['npm', 'test', '--if-present']],
        }
    if project_type == 'gradle':
        return {
            'setup_commands': [],
            'validation_commands': [['./gradlew', 'test']],
        }
    return {'setup_commands': [], 'validation_commands': []}


def detect(repo: Path) -> dict:
    repo = repo.expanduser().resolve()
    if not (repo / '.git').exists():
        raise DetectionError(f'Not a Git repository: {repo}')
    branch = run(['git', 'branch', '--show-current'], repo).stdout.strip()
    head = run(['git', 'rev-parse', 'HEAD'], repo, check=False).stdout.strip()
    origin_result = run(['git', 'remote', 'get-url', 'origin'], repo, check=False)
    origin = origin_result.stdout.strip() if origin_result.returncode == 0 else ''
    slug = github_slug(origin)
    account = ''
    if shutil.which('gh'):
        account_result = run(['gh', 'api', 'user', '--jq', '.login'], repo, check=False)
        if account_result.returncode == 0:
            account = account_result.stdout.strip()
    project_type = detect_project_type(repo)
    commands = default_commands(project_type, repo)
    profile = 'generic'
    if slug and slug.lower() == 'cube23games/breakout_addiction':
        profile = 'breakout_addiction_reference'
    elif project_type == 'flutter':
        profile = 'flutter_android_termux'
    return {
        'repo_path': str(repo),
        'project_name': repo.name,
        'project_type': project_type,
        'profile': profile,
        'branch': branch or 'main',
        'head': head,
        'origin': origin,
        'repository': slug or '',
        'required_github_account': account,
        **commands,
    }


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', default='.')
    args = parser.parse_args()
    print(json.dumps(detect(Path(args.repo)), indent=2, sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
