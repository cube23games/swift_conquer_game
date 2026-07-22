#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
BASELINE_PATH = ROOT / "tools" / "sc211_analysis_baseline.json"
ISSUE_PATTERN = re.compile(
    r"^\s*(info|warning|error)\s+•\s+(.*?)\s+•\s+(.+?):(\d+):(\d+)\s+•\s+([A-Za-z0-9_]+)\s*$"
)


def issue_key(issue: dict[str, Any]) -> tuple:
    return (
        issue["severity"],
        issue["code"],
        issue["path"],
        int(issue["line"]),
        int(issue["column"]),
        issue["message"],
    )


def parse_issues(output: str) -> list[dict[str, Any]]:
    found: list[dict[str, Any]] = []
    for line in output.splitlines():
        match = ISSUE_PATTERN.match(line)
        if not match:
            continue
        severity, message, path, line_number, column, code = match.groups()
        found.append(
            {
                "severity": severity,
                "code": code,
                "path": path,
                "line": int(line_number),
                "column": int(column),
                "message": message,
            }
        )
    return found


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {message}")


def self_test() -> int:
    require(BASELINE_PATH.is_file(), "analysis baseline is missing")
    data = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    require(data.get("issue_count") == 69, "expected 69 locked baseline findings")
    baseline_issues = data.get("issues")
    require(isinstance(baseline_issues, list), "baseline issues must be a list")
    keys = [issue_key(item) for item in baseline_issues]
    require(len(keys) == len(set(keys)), "baseline contains duplicate issue fingerprints")
    sample = (
        "  error • Undefined class 'GameState' • "
        "_backup_1765576900/lib/engine/engine.dart:2:9 • undefined_class\n"
    )
    parsed = parse_issues(sample)
    require(len(parsed) == 1, "analyzer parser sample failed")
    require(parsed[0]["code"] == "undefined_class", "analyzer parser code mismatch")
    print("PASS: SC-211 analyzer baseline gate self-test")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()

    require(BASELINE_PATH.is_file(), "analysis baseline is missing")
    baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    expected = {issue_key(item): item for item in baseline["issues"]}

    result = subprocess.run(
        ["flutter", "analyze", "--no-fatal-infos"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env={**dict(__import__("os").environ), "PYTHONDONTWRITEBYTECODE": "1"},
    )
    output = result.stdout or ""
    sys.stdout.write(output)
    actual_issues = parse_issues(output)
    actual = {issue_key(item): item for item in actual_issues}

    if result.returncode not in (0, 1):
        print(f"FAIL: flutter analyze exited unexpectedly with {result.returncode}")
        return 1
    if result.returncode != 0 and not actual:
        print("FAIL: flutter analyze failed without parseable diagnostics")
        return 1

    unexpected_keys = sorted(set(actual) - set(expected))
    resolved_keys = sorted(set(expected) - set(actual))

    if unexpected_keys:
        print("")
        print(f"FAIL: {len(unexpected_keys)} analyzer finding(s) exceed the locked SC-211 baseline:")
        for key in unexpected_keys:
            item = actual[key]
            print(
                f"- {item['severity']} {item['path']}:{item['line']}:{item['column']} "
                f"{item['code']}: {item['message']}"
            )
        return 1

    print("")
    print(
        "PASS: analyzer introduced no findings beyond the "
        f"{len(expected)} locked SC-211 baseline finding(s)"
    )
    if resolved_keys:
        print(f"IMPROVEMENT: {len(resolved_keys)} locked finding(s) were resolved")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
