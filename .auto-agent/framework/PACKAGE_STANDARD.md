# Package Standard

A stage or train package contains:

- README
- machine-readable metadata
- exact internal SHA-256 manifest
- exact payload allowlist
- stage metadata
- verifier references
- explicit exit-code meanings
- evidence logic
- no credentials or signing files

Distribute the ZIP with a companion `.sha256`. Verify the outer checksum and ZIP integrity before extraction.

Reject:

- missing or extra internal files
- hash mismatches
- `__pycache__` or `.pyc`
- secret-like suffixes such as `.pem`, `.key`, `.jks`, `.p12`, `.keystore`
- forbidden generated paths from the active profile
- unapproved changed files
