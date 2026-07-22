# Shadow CI

Shadow CI is the pre-production failure-discovery layer.

## Purpose

A normal production train discovers one failure per pushed commit because CI stops at the first broken stage. Shadow CI instead builds the complete proposed history on a disposable validation branch and tests every tree in one GitHub Actions run.

## Required trees

- each stage commit in order
- the final combined tree
- optional platform-generation or packaging simulation, when configured

## Required commands

Use the real project commands, not approximations. For the Breakout Addiction reference these were:

- `flutter pub get`
- `flutter analyze --no-fatal-infos`
- `flutter test`
- cumulative Python source verifiers
- isolated Android generation and project-specific patch simulation

Other projects must use their own real CI commands from project configuration.

## Failure behavior

- Keep running after analyzer, compiler, test, or verifier failures.
- Record exit codes and full logs for every tree.
- Produce a consolidated failure summary with filenames, lines, commands, and stage IDs.
- Mark the workflow red only after the matrix has finished and results are uploaded.
- Do not change production branches.

## Green lock

A production package must record the exact shadow workflow name, run ID, job ID, branch, control commit, conclusion, stage list, and payload hashes. A different shadow run or modified payload invalidates the lock.
