#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

PHASE_RE = re.compile(r"(?i)(?:phase[ _-]?(?:17[1-9]|18\d|19\d|20\d|210)|(?:17[1-9]|18\d|19\d|20\d|210)[ _-]?phase)")
CLASS_RE = re.compile(r"\b(?:class|enum|mixin|extension)\s+([A-Za-z_][A-Za-z0-9_]*)")
MAIN_RE = re.compile(r"\b(?:Future\s*<\s*void\s*>\s+|void\s+)?main\s*\(")


def run(root: Path, *args: str, text: bool = True) -> str:
    result = subprocess.run(
        ["git", *args], cwd=root, check=True, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, text=text,
    )
    return result.stdout if text else result.stdout.decode("utf-8", "replace")


def git_bytes(root: Path, commit: str, rel: str) -> bytes:
    result = subprocess.run(
        ["git", "show", f"{commit}:{rel}"], cwd=root, check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return result.stdout


def is_text_path(path: str) -> bool:
    return Path(path).suffix.lower() in {
        ".dart", ".py", ".sh", ".yml", ".yaml", ".json", ".md", ".txt",
        ".gradle", ".kts", ".xml", ".properties", ".toml", ".lock",
    }


def classify(path: str, content: str) -> tuple[str, list[str], str]:
    low = path.lower()
    name = Path(path).name.lower()
    tags: list[str] = []

    archived_markers = (
        "/archive/", "/archived/", "/legacy/", "/backup/", "/backups/",
        "_backup", "backup_", "_old", "old_", "/deprecated/",
        "_disabled", "/disabled/", "flame_disabled",
    )
    if any(marker in f"/{low}" for marker in archived_markers):
        return "archived_legacy", ["recovery_candidate"], "path contains archive/legacy/backup/disabled marker"

    if low.startswith(".github/workflows/"):
        obsolete = any(token in low for token in ("old", "legacy", "backup", "obsolete", "disabled"))
        if obsolete:
            return "obsolete_workflow_candidate", ["workflow", "recovery_candidate"], "workflow path carries obsolete marker"
        return "retained_support", ["workflow"], "active workflow candidate"

    if PHASE_RE.search(path) or PHASE_RE.search(content[:200000]):
        return "phase_171_210_remnant", ["recovery_candidate"], "Phase 171–210 marker detected"

    if low.startswith(("build/", ".dart_tool/", ".idea/", ".vscode/")) or name in {
        "pubspec.lock", ".metadata", ".gitignore", ".gitattributes",
    }:
        return "generated_or_project_metadata", [], "generated or project metadata"

    if low.startswith(("test/", "integration_test/", "tools/")):
        return "test_or_verifier", [], "test, verifier, or maintenance tooling"

    if low.startswith(("docs/", "launch/")) or Path(path).suffix.lower() in {".md", ".txt"}:
        return "documentation", [], "documentation or release material"

    if low.endswith(".dart"):
        if MAIN_RE.search(content) or name.startswith("main"):
            tags.append("entry_point")
            return "retained_canonical_candidate", tags, "Dart application entry-point candidate"
        if any(token in low for token in ("simulation", "game_loop", "gameloop", "command", "snapshot", "world_state")):
            return "retained_canonical_candidate", ["authoritative_runtime_candidate"], "deterministic/runtime naming signal"
        if any(token in low for token in ("flame", "component", "render", "painter", "camera")):
            return "retained_canonical_candidate", ["flame_or_render_candidate"], "Flame/render naming signal"
        return "retained_support", [], "Dart support code"

    if low.startswith(("android/", "assets/", "web/", "ios/", "linux/", "macos/", "windows/")):
        return "retained_support", [], "platform or asset support"

    return "retained_support", [], "default retained classification"


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--base", required=True)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    base = args.base

    repo = run(root, "remote", "get-url", "origin").strip()
    head = run(root, "rev-parse", "HEAD").strip()
    branch = run(root, "branch", "--show-current").strip()
    run(root, "cat-file", "-e", f"{base}^{{commit}}")
    paths = [line for line in run(root, "ls-tree", "-r", "--name-only", base).splitlines() if line]

    records: list[dict[str, object]] = []
    hashes: dict[str, str] = {}
    entry_points: list[dict[str, object]] = []
    workflows: list[dict[str, object]] = []
    phase_remnants: list[str] = []
    recovery: list[dict[str, str]] = []
    basenames: defaultdict[str, list[str]] = defaultdict(list)
    symbols: defaultdict[str, list[str]] = defaultdict(list)

    for rel in paths:
        raw = git_bytes(root, base, rel)
        hashes[rel] = hashlib.sha256(raw).hexdigest()
        text = raw.decode("utf-8", "replace") if is_text_path(rel) else ""
        primary, tags, reason = classify(rel, text)
        record = {
            "path": rel,
            "primary_classification": primary,
            "tags": sorted(set(tags)),
            "reason": reason,
            "sha256": hashes[rel],
            "size_bytes": len(raw),
        }
        records.append(record)
        basenames[Path(rel).name.lower()].append(rel)
        if rel.endswith(".dart"):
            for symbol in CLASS_RE.findall(text):
                symbols[symbol].append(rel)
            if MAIN_RE.search(text) or Path(rel).name.lower().startswith("main"):
                entry_points.append({"path": rel, "contains_main": bool(MAIN_RE.search(text))})
        if rel.startswith(".github/workflows/"):
            workflows.append({"path": rel, "classification": primary})
        if primary == "phase_171_210_remnant":
            phase_remnants.append(rel)
        if "recovery_candidate" in tags:
            recovery.append({"path": rel, "classification": primary, "reason": reason})

    duplicate_files = {
        name: sorted(group) for name, group in basenames.items()
        if len(group) > 1 and name not in {"readme.md", ".gitignore"}
    }
    duplicate_symbols = {
        name: sorted(set(group)) for name, group in symbols.items()
        if len(set(group)) > 1
    }
    duplicate_paths = {path for group in duplicate_files.values() for path in group}
    duplicate_paths.update(path for group in duplicate_symbols.values() for path in group)
    for record in records:
        if record["path"] in duplicate_paths:
            record["tags"] = sorted(set(record["tags"]) | {"duplicate_candidate"})

    summary = Counter(str(record["primary_classification"]) for record in records)
    inventory = {
        "schema_version": 1,
        "stage": "SC-212",
        "repository": repo,
        "base_commit": base,
        "validation_head": head,
        "validation_branch": branch,
        "tracked_file_count": len(records),
        "classification_counts": dict(sorted(summary.items())),
        "records": records,
    }
    write_json(out / "sc212_inventory.json", inventory)
    write_json(out / "baseline_sha256_manifest.json", hashes)
    write_json(out / "entry_points.json", entry_points)
    write_json(out / "workflow_inventory.json", workflows)
    write_json(out / "phase_171_210_remnants.json", sorted(phase_remnants))
    write_json(out / "recovery_candidates.json", recovery)
    write_json(out / "duplicate_candidates.json", {
        "duplicate_basenames": duplicate_files,
        "duplicate_symbols": duplicate_symbols,
    })
    write_json(out / "git_state.json", {
        "repository": repo,
        "base_commit": base,
        "validation_head": head,
        "validation_branch": branch,
        "status_porcelain": run(root, "status", "--porcelain").splitlines(),
        "base_to_validation_changes": run(root, "diff", "--name-status", f"{base}..HEAD").splitlines(),
    })

    lines = [
        "# SwiftConquer SC-212 Source-of-Truth Inventory",
        "",
        f"- Repository: `{repo}`",
        f"- Production base: `{base}`",
        f"- Validation head: `{head}`",
        f"- Files inventoried: **{len(records)}**",
        "",
        "## Classification totals",
    ]
    for key, count in sorted(summary.items()):
        lines.append(f"- `{key}`: {count}")
    lines += [
        "",
        f"## Entry points ({len(entry_points)})",
        *[f"- `{item['path']}`" for item in entry_points],
        "",
        f"## Workflows ({len(workflows)})",
        *[f"- `{item['path']}` — {item['classification']}" for item in workflows],
        "",
        f"## Duplicate candidates ({len(duplicate_paths)})",
        *[f"- `{path}`" for path in sorted(duplicate_paths)],
        "",
        f"## Phase 171–210 remnants ({len(phase_remnants)})",
        *[f"- `{path}`" for path in sorted(phase_remnants)],
        "",
        f"## Recovery candidates ({len(recovery)})",
        *[f"- `{item['path']}` — {item['reason']}" for item in recovery],
        "",
        "No files were moved or deleted by this inventory pass.",
    ]
    (out / "sc212_inventory.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"PASS: inventoried and classified {len(records)} tracked files from {base}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
