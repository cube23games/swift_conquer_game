# Manual Auto-Agent

The Manual Auto-Agent is a resumable production promotion system. It is not an unrestricted autonomous release bot.

## Inputs

- project profile
- exact approved baseline commit
- checksum-locked stage package
- exact shadow-green lock
- stage metadata with input/output hashes
- cumulative verifier list
- approved production branch and workflow

## Preflight

Verify account, repository slug, remote, branch, HEAD, origin alignment, clean tree, tags, forbidden paths, package manifest, payload hashes, stage ordering, baseline CI evidence, and shadow-green evidence.

## Per-stage behavior

1. Verify expected input hashes.
2. Copy only allowlisted payload files.
3. Verify exact changed-file set.
4. Run stage and historical verifiers.
5. Stage only allowlisted files.
6. Create one focused commit.
7. Push with bounded retries.
8. Confirm the remote branch points to the intended SHA even if the push connection drops.
9. Save the exact CI run ID for that SHA.
10. Watch the same run to completion.
11. Continue only on confirmed success.

## Exit classes

- `0`: completed success
- `20`: local/preflight/package failure
- `30`: confirmed CI failure
- `31`: verification unavailable or safely paused

Exit 31 must save state and evidence. Rerunning the same package must resume rather than duplicate work.
