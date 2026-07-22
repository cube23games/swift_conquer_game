#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {message}")


def main() -> int:
    project_path = ROOT / ".auto-agent" / "project.json"
    shadow_workflow = ROOT / ".github" / "workflows" / "auto-agent-shadow-ci.yml"
    production_workflow = ROOT / ".github" / "workflows" / "swiftconquer_apk.yml"
    agents = ROOT / "AGENTS.md"
    knowledge = ROOT / "CHATGPT_PROJECT_KNOWLEDGE.md"

    for path in [project_path, shadow_workflow, production_workflow, agents, knowledge]:
        require(path.is_file(), f"missing required file: {path.relative_to(ROOT)}")

    project = json.loads(project_path.read_text(encoding="utf-8"))
    expected = {
        "repository": "cube23games/swift_conquer_game",
        "required_github_account": "cube23games",
        "branch": "working/phase170-movement-ci",
        "production_workflow": "SwiftConquer APK Build",
        "shadow_workflow": "Auto-Agent Shadow CI",
        "flutter_version": "3.35.0",
        "java_version": "17",
        "automatic_tagging": False,
        "ci_only_builds": True,
        "visible_command_max_lines": 40,
    }
    for key, value in expected.items():
        require(project.get(key) == value, f"project.json {key} mismatch")

    require(
        project.get("platform_simulation_commands")
        == [["bash", "tools/sc211_shadow_platform.sh"]],
        "platform simulation command mismatch",
    )

    shadow = shadow_workflow.read_text(encoding="utf-8")
    for token in [
        "name: Auto-Agent Shadow CI",
        "'validation/**'",
        "fetch-depth: 0",
        "java-version: '17'",
        "flutter-version: 3.35.0",
        "continue-on-error: true",
        "AUTO_AGENT_SHADOW_RESULTS",
        "test -f \"$RUNNER_TEMP/auto-agent-shadow-results/PASS\"",
    ]:
        require(token in shadow, f"shadow workflow missing: {token}")

    production = production_workflow.read_text(encoding="utf-8")
    for token in [
        "name: SwiftConquer APK Build",
        "flutter-version: 3.35.0",
        "java-version: '17'",
        "flutter build apk --release",
    ]:
        require(token in production, f"production workflow missing: {token}")

    agents_text = agents.read_text(encoding="utf-8")
    for token in [
        "Never tag automatically",
        "Flame renders snapshots",
        "checksum-locked ZIP stages",
        "Local Flutter or Android application builds are forbidden",
    ]:
        require(token in agents_text, f"AGENTS.md missing: {token}")

    knowledge_text = knowledge.read_text(encoding="utf-8")
    for token in ["SC-211 through SC-270", "SC-220", "04d6db6d43a068612f1e79fc388666fdc75dee9b"]:
        require(token in knowledge_text, f"project knowledge missing: {token}")

    forbidden = {".pem", ".key", ".jks", ".p12", ".keystore", ".pyc"}
    for path in ROOT.rglob("*"):
        if "__pycache__" in path.parts:
            raise SystemExit(f"FAIL: forbidden cache path: {path.relative_to(ROOT)}")
        if path.is_file() and path.suffix.lower() in forbidden:
            raise SystemExit(f"FAIL: forbidden suffix: {path.relative_to(ROOT)}")

    print("PASS: SC-211 SwiftConquer governance is project-locked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
