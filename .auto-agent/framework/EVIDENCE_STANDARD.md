# Evidence Standard

Every evidence ZIP must contain a concise human summary, a machine-readable result, an internal SHA-256 manifest, and enough logs to independently reproduce the classification.

## Repository fields

- project and repository slug
- local path
- authenticated account
- branch
- HEAD
- origin branch SHA
- clean-tree status
- safety branches
- tags
- changed files

## Package fields

- package name and outer SHA-256
- internal manifest validation
- stage IDs
- payload input/output hashes
- changed-file allowlists

## CI fields

- workflow name
- exact run ID
- exact job ID when available
- head SHA
- status
- conclusion
- URL
- whether a saved run ID was reused
- transient errors and classifications

## Status classes

- success
- expected_failure_observed
- unexpected_failure
- confirmed_ci_failure
- verification_unavailable
- safely_paused
- preflight_rejected
- completed_rerun_noop

Evidence must state the highest verification level actually reached.
