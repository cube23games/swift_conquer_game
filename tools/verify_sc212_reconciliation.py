#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, subprocess, sys
from pathlib import Path

EXPECTED_STAGE = "SC-212"
EXPECTED_REPO = "cube23games/swift_conquer_game"
EXPECTED_BASE = "949bb937fc06a4c18cb184fcab416aa0ea90b4a3"
EXPECTED_PAYLOAD = {
    ".github/workflows/sc212-reconciliation-shadow.yml",
    "docs/SC212_CANONICAL_RUNTIME_MAP.json",
    "docs/SC212_CANONICAL_RUNTIME_MAP.md",
    "tools/verify_sc212_reconciliation.py",
    "tools/sc212_seal_reconciliation_evidence.py",
}

def run(repo: Path, *args: str) -> str:
    return subprocess.check_output(args, cwd=repo, text=True).strip()

def fail(errors: list[str], message: str) -> None:
    errors.append(message)

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=".")
    ap.add_argument("--map", dest="map_path", default="docs/SC212_CANONICAL_RUNTIME_MAP.json")
    ap.add_argument("--report-dir", default="reports/sc212_reconciliation")
    args = ap.parse_args()
    repo = Path(args.repo).resolve()
    report_dir = repo / args.report_dir
    report_dir.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []
    checks: list[dict] = []

    def check(name: str, condition: bool, detail: str) -> None:
        checks.append({"name": name, "passed": bool(condition), "detail": detail})
        if not condition:
            fail(errors, f"{name}: {detail}")

    map_file = repo / args.map_path
    check("map_exists", map_file.is_file(), str(map_file))
    if not map_file.is_file():
        data = {}
    else:
        data = json.loads(map_file.read_text(encoding="utf-8"))

    check("stage", data.get("stage") == EXPECTED_STAGE, str(data.get("stage")))
    check("repository", data.get("repository") == EXPECTED_REPO, str(data.get("repository")))
    check("base_commit", data.get("base_commit") == EXPECTED_BASE, str(data.get("base_commit")))
    check("tracked_file_count", data.get("tracked_file_count") == 275, str(data.get("tracked_file_count")))

    canonical = data.get("canonical_runtime", {})
    required = [
        canonical.get("package_manifest"),
        canonical.get("entry_point"),
        canonical.get("primary_screen"),
        canonical.get("production_workflow"),
        canonical.get("shadow_workflow"),
    ]
    for rel in required:
        check(f"canonical_path:{rel}", bool(rel) and (repo / rel).is_file(), str(rel))

    main_text = (repo / "lib/main.dart").read_text(encoding="utf-8")
    pubspec = (repo / "pubspec.yaml").read_text(encoding="utf-8")
    check("main_declares_entry", "Future<void> main()" in main_text or "void main()" in main_text, "lib/main.dart")
    check("main_routes_game_screen", "GameScreen" in main_text, "lib/main.dart")
    check("root_pubspec_identity", "name: swift_conquer_game" in pubspec, "pubspec.yaml")

    for item in data.get("archive_reference_roots", []):
        rel = item.get("path", "")
        check(f"archive_root:{rel}", bool(rel) and (repo / rel).exists(), rel)

    for item in data.get("phase_171_210_remnants", []):
        rel = item.get("path", "")
        check(f"phase_remnant:{rel}", bool(rel) and (repo / rel).exists(), rel)

    deferred = data.get("deferred_architecture_conflicts", [])
    check("deferred_conflicts_present", len(deferred) >= 4, f"count={len(deferred)}")
    for item in deferred:
        check(f"deferred_status:{item.get('group')}", item.get("decision") == "SC213_REQUIRED", str(item.get("decision")))
        for rel in item.get("live_candidates", []):
            check(f"deferred_path:{rel}", (repo / rel).is_file(), rel)

    changed = set(run(repo, "git", "diff", "--name-only", f"{EXPECTED_BASE}..HEAD").splitlines())
    check("payload_only", changed == EXPECTED_PAYLOAD, f"changed={sorted(changed)}")
    destructive = run(repo, "git", "diff", "--name-status", "--diff-filter=DR", f"{EXPECTED_BASE}..HEAD")
    check("no_delete_or_rename", destructive == "", destructive or "none")

    workflow = (repo / ".github/workflows/sc212-reconciliation-shadow.yml").read_text(encoding="utf-8")
    prohibited = ["git tag", "gh release", "working/phase170-movement-ci"]
    check("no_auto_tag", not any(token in workflow for token in prohibited[:2]), "workflow scan")
    check("shadow_branch_trigger", "sc212-reconciliation-" in workflow, "workflow trigger")

    result = {
        "schema_version": 1,
        "stage": EXPECTED_STAGE,
        "passed": not errors,
        "errors": errors,
        "checks": checks,
        "base_commit": EXPECTED_BASE,
        "head_commit": run(repo, "git", "rev-parse", "HEAD"),
        "changed_paths": sorted(changed),
        "map_sha256": hashlib.sha256(map_file.read_bytes()).hexdigest() if map_file.is_file() else None,
        "no_production_commit": True,
        "no_tag": True,
    }
    (report_dir / "verification.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    lines = ["# SC-212 Reconciliation Verification", "", f"Passed: **{result['passed']}**", ""]
    lines += [f"- {'PASS' if c['passed'] else 'FAIL'} — {c['name']}: {c['detail']}" for c in checks]
    (report_dir / "verification.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["passed"] else 20

if __name__ == "__main__":
    raise SystemExit(main())
