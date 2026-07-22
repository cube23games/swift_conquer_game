# Project Detection

The installer detects:

- repository root and current branch
- origin URL and GitHub slug
- authenticated GitHub account when `gh` is available
- Flutter from `pubspec.yaml`
- Python from `pyproject.toml`, `requirements.txt`, or `.py` files
- Node from `package.json`
- Gradle from `gradlew` or Gradle build files
- existing GitHub Actions workflows and common test commands

Exact project behavior belongs in `.auto-agent/project.json`. Detection is a starting point, not permission to invent missing release rules.

The Breakout Addiction profile is selected automatically only for the exact repository slug `cube23games/Breakout_addiction`.
