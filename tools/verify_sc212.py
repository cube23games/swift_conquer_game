#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

ALLOWED_STAGE_FILES = {
    ".github/workflows/sc212-inventory-shadow.yml",
    "tools/sc212_inventory.py",
    "tools/verify_sc212.py",
    "tools/sc212_seal_evidence.py",
}
ALLOWED_CLASSES = {
    "retained_canonical_candidate",
    "retained_support",
    "archived_legacy",
    "obsolete_workflow_candidate",
    "phase_171_210_remnant",
    "generated_or_project_metadata",
    "test_or_verifier",
    "documentation",
}


def git(root: Path, *args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=root, check=True, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    ).stdout


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--inventory", required=True)
    parser.add_argument("--base", required=True)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    inventory_path = Path(args.inventory).resolve()
    data = json.loads(inventory_path.read_text(encoding="utf-8"))
    base = args.base

    if data.get("stage") != "SC-212":
        fail("inventory stage is not SC-212")
    if data.get("base_commit") != base:
        fail("inventory base commit mismatch")

    expected_paths = [p for p in git(root, "ls-tree", "-r", "--name-only", base).splitlines() if p]
    records = data.get("records")
    if not isinstance(records, list):
        fail("records list missing")
    actual_paths = [str(record.get("path")) for record in records]
    if len(actual_paths) != len(set(actual_paths)):
        fail("duplicate path records found")
    if set(actual_paths) != set(expected_paths):
        missing = sorted(set(expected_paths) - set(actual_paths))[:10]
        extra = sorted(set(actual_paths) - set(expected_paths))[:10]
        fail(f"classification coverage mismatch; missing={missing}, extra={extra}")

    for record in records:
        path = str(record.get("path", ""))
        classification = record.get("primary_classification")
        digest = str(record.get("sha256", ""))
        if classification not in ALLOWED_CLASSES:
            fail(f"invalid classification for {path}: {classification}")
        raw = subprocess.run(
            ["git", "show", f"{base}:{path}"], cwd=root, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        ).stdout
        if hashlib.sha256(raw).hexdigest() != digest:
            fail(f"hash mismatch for {path}")

    changes = [line for line in git(root, "diff", "--name-status", f"{base}..HEAD").splitlines() if line]
    changed_paths = set()
    for line in changes:
        status, _, path = line.partition("\t")
        if status.startswith(("D", "R")):
            fail(f"SC-212 shadow must not delete or rename files: {line}")
        changed_paths.add(path)
    if changed_paths != ALLOWED_STAGE_FILES:
        fail(f"unexpected validation-branch payload: {sorted(changed_paths)}")

    out = inventory_path.parent
    required = {
        "baseline_sha256_manifest.json",
        "entry_points.json",
        "workflow_inventory.json",
        "phase_171_210_remnants.json",
        "recovery_candidates.json",
        "duplicate_candidates.json",
        "git_state.json",
        "sc212_inventory.md",
    }
    missing_outputs = sorted(name for name in required if not (out / name).is_file())
    if missing_outputs:
        fail(f"missing evidence outputs: {missing_outputs}")

    entry_points = json.loads((out / "entry_points.json").read_text(encoding="utf-8"))
    workflows = json.loads((out / "workflow_inventory.json").read_text(encoding="utf-8"))
    if not isinstance(entry_points, list) or not entry_points:
        fail("no application entry point recorded")
    if not isinstance(workflows, list) or not workflows:
        fail("no workflow inventory recorded")

    print(f"PASS: SC-212 classified all {len(records)} base paths with no deletion or rename")
    print(f"PASS: recorded {len(entry_points)} entry points and {len(workflows)} workflows")
    print("PASS: recovery, duplicate, Phase 171–210, and SHA-256 evidence files are present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
