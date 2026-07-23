#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ZIP_NAME = "SWIFTCONQUER_SC212_INVENTORY_EVIDENCE_v1.zip"
LOCK_NAME = "SC212_INVENTORY_LOCK_v1.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--base", required=True)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--branch", required=True)
    parser.add_argument("--stage-commit", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--run-attempt", required=True)
    args = parser.parse_args()

    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    exit_code_path = out / "exit_code.txt"
    exit_code = int(exit_code_path.read_text(encoding="utf-8").strip()) if exit_code_path.exists() else 99
    conclusion = "success" if exit_code == 0 else "failure"

    evidence_files = sorted(
        p for p in out.iterdir()
        if p.is_file() and p.name not in {ZIP_NAME, ZIP_NAME + ".sha256", LOCK_NAME, "EVIDENCE_MANIFEST.sha256"}
    )
    hashes = {p.name: sha256(p) for p in evidence_files}
    inventory = {}
    inventory_path = out / "sc212_inventory.json"
    if inventory_path.exists():
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))

    lock = {
        "schema_version": 1,
        "stage": "SC-212",
        "verification_level": "GitHub background inventory shadow",
        "repository": args.repo,
        "base_commit": args.base,
        "validation_branch": args.branch,
        "validation_commit": args.stage_commit,
        "run_id": int(args.run_id),
        "run_attempt": int(args.run_attempt),
        "conclusion": conclusion,
        "passed": exit_code == 0,
        "exit_code": exit_code,
        "tracked_file_count": inventory.get("tracked_file_count"),
        "classification_counts": inventory.get("classification_counts", {}),
        "evidence_hashes": hashes,
        "no_production_commit": True,
        "no_tag": True,
    }
    lock_path = out / LOCK_NAME
    lock_path.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    manifest_paths = evidence_files + [lock_path]
    manifest = "".join(f"{sha256(p)}  {p.name}\n" for p in sorted(manifest_paths, key=lambda p: p.name))
    manifest_path = out / "EVIDENCE_MANIFEST.sha256"
    manifest_path.write_text(manifest, encoding="utf-8")

    zip_path = out / ZIP_NAME
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(manifest_paths + [manifest_path], key=lambda p: p.name):
            archive.write(path, arcname=path.name)
    (out / f"{ZIP_NAME}.sha256").write_text(f"{sha256(zip_path)}  {ZIP_NAME}\n", encoding="utf-8")
    print(f"SEALED: {zip_path}")
    print(f"RESULT: {conclusion}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
