# Failure Recovery

## Before commit

Stop without changing the approved branch. Remove only framework-owned temporary files. Produce preflight/failure evidence.

## After local commit but before confirmed push

Save the intended SHA. Query the remote branch. If the remote already points to that SHA, treat the push as accepted. Otherwise retry with bounded backoff or pause safely.

## After push

Preserve the commit. Save the exact run ID. A repair is a new stage; do not amend or force-push the failed specimen.

## Polling loss

- classify status as temporarily unknown
- retain the exact run ID
- retry boundedly
- reconnect to the same run
- if verification remains unavailable, exit 31 and save state
- never create a repair commit merely because watching failed

## Resume

Revalidate repository identity and package hashes. Verify every already-completed stage by parent SHA, commit message, file hashes, remote alignment, and CI result. Continue from the verified prefix without duplicate commits.
