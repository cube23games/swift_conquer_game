# Project Auto-Agent + Shadow CI Instructions

This repository uses a human-authorized, evidence-driven development workflow.
These instructions are persistent repository instructions for coding agents.

## Start every task here

1. Read `.auto-agent/project.json`.
2. Read `.auto-agent/framework/CORE_RULES.md`.
3. Read the project profile named by `profile` in `project.json`.
4. Inspect the current branch, exact HEAD, origin URL, origin branch SHA, working-tree state, and tags before changing files.
5. Treat project-specific source, product, and privacy rules as higher priority than generic examples.

If `.auto-agent/project.json` is missing, run the repository bootstrap from this starter before attempting a multi-stage change.

## Authority and safety

- The human operator is the authorization layer.
- Never push, merge, tag, delete, publish, release, deploy, or change credentials unless the human explicitly authorizes that action.
- Never tag automatically.
- Never rewrite a pushed failed specimen to make history look clean.
- Never claim a verification level that was not actually reached.
- Never include credentials, signing material, API keys, private user data, or secret-like files in a package or evidence archive.
- Keep reusable framework code separate from project-specific payloads.

## Required workflow for multi-stage or risky work

### 1. Plan and package

- Split work into focused stages.
- Use one intended production commit per stage.
- For every stage, record exact input hashes, output hashes, changed-file allowlist, commit message, verifier list, and dependencies.
- Seal packages with an internal SHA-256 manifest and an outer `.sha256` companion.
- Reject extra files, missing files, `__pycache__`, `.pyc`, secret-like files, and forbidden generated folders.

### 2. Shadow CI before production

- Create a disposable `validation/...` branch from the exact approved production baseline.
- Apply every planned stage as a separate simulated commit.
- Run the real project CI commands against every incremental tree and the final combined tree.
- Continue after individual failures so one run reports the complete failure set.
- Collect analyzer, compiler, test, verifier, and optional platform-simulation output in one evidence artifact.
- Repair all discovered issues on a new disposable shadow branch or a new shadow revision.
- Repeat until every incremental tree and the final combined tree are green.
- Do not modify `main` during shadow validation.
- A shadow-green result proves only the checks actually run; it does not prove device, store, billing, backend, or real-provider behavior.

### 3. Production train after shadow green

- Lock the production train to the exact green shadow run, job, branch, control commit, stage payload hashes, and baseline commit.
- Recheck account, repository, branch, HEAD, origin alignment, clean tree, tags, forbidden paths, and package hashes.
- Create a safety branch at the exact starting commit.
- Apply and commit one stage at a time.
- Push one stage at a time.
- Save the exact GitHub Actions run ID for that commit and watch that same run to completion.
- Continue only after confirmed success.
- Stop on confirmed CI failure.
- Treat network, API, timeout, and polling loss as verification unavailable, not CI failure.
- Save state and evidence so rerunning the same package resumes without duplicating commits.

## Verification ladder

Use these exact labels:

1. implemented
2. locally verified
3. shadow CI verified
4. production CI verified
5. artifact verified
6. device verified
7. store verified
8. backend/provider verified

Do not collapse or skip levels in status reports.

## Evidence requirements

Every success, failure, preflight rejection, or pause must produce evidence containing:

- exact repository/account/branch/HEAD/origin state
- stage and package hashes
- changed files
- verifier output
- exact CI run ID, job ID, head SHA, status, conclusion, and URL when available
- transient error classification
- safety branch and tag list
- verification level reached
- internal SHA-256 manifest and outer checksum

## Communication rules

- Be explicit about what is known, inferred, unverified, or blocked.
- For phone/Termux operators, keep every visible copy/paste code block at 40 lines or fewer.
- Put complex logic in a checksum-locked package, not a giant chat paste.
- Never tell the operator to run a local build when the active profile says builds are CI-only.
- Use exact hashes and exact run IDs instead of phrases such as “the latest run.”

## Source of truth

Detailed rules live under `.auto-agent/framework/`.
Reusable runtime utilities live under `.auto-agent/runtime/`.
Project configuration lives in `.auto-agent/project.json`.
Reference implementations live in the starter archive under `reference/` and must not be copied blindly without adapting project-specific constants.
