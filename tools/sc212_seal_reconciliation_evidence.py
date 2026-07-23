#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, os, zipfile
from pathlib import Path

def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=".")
    ap.add_argument("--run-id", required=True)
    ap.add_argument("--run-attempt", required=True)
    ap.add_argument("--runner-log", required=True)
    ap.add_argument("--out", default="dist/sc212_reconciliation")
    args = ap.parse_args()
    repo = Path(args.repo).resolve()
    out = repo / args.out
    out.mkdir(parents=True, exist_ok=True)
    files = [
        repo / "docs/SC212_CANONICAL_RUNTIME_MAP.json",
        repo / "docs/SC212_CANONICAL_RUNTIME_MAP.md",
        repo / "reports/sc212_reconciliation/verification.json",
        repo / "reports/sc212_reconciliation/verification.md",
        Path(args.runner_log).resolve(),
    ]
    missing = [str(p) for p in files if not p.is_file()]
    if missing:
        raise SystemExit("Missing evidence: " + ", ".join(missing))
    verification = json.loads((repo / "reports/sc212_reconciliation/verification.json").read_text())
    lock = {
        "schema_version": 1,
        "stage": "SC-212",
        "verification_level": "GitHub background canonical reconciliation shadow",
        "repository": "cube23games/swift_conquer_game",
        "base_commit": "949bb937fc06a4c18cb184fcab416aa0ea90b4a3",
        "validation_commit": verification["head_commit"],
        "run_id": int(args.run_id),
        "run_attempt": int(args.run_attempt),
        "passed": bool(verification["passed"]),
        "conclusion": "success" if verification["passed"] else "failure",
        "no_production_commit": True,
        "no_tag": True,
        "evidence_hashes": {p.name: sha(p) for p in files},
    }
    lock_path = out / "SC212_RECONCILIATION_SHADOW_LOCK_v1.json"
    lock_path.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
    zip_path = out / "SWIFTCONQUER_SC212_RECONCILIATION_SHADOW_EVIDENCE_v1.zip"
    members = files + [lock_path]
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for p in members:
            zf.write(p, arcname=p.name)
    (out / (zip_path.name + ".sha256")).write_text(f"{sha(zip_path)}  {zip_path.name}\n")
    print(lock_path)
    print(zip_path)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
