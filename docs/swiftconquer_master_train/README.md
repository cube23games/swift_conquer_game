# SwiftConquer SC-213–SC-270 Master Shadow Train

This directory is installed only on a validation branch by the checksum-locked
phone launcher. It applies every stage cumulatively, runs all stage verifiers,
collects every failure without stopping at the first red result, and then runs
Flutter analysis, tests, and a debug APK build.

Production is not modified by this package. No tag command exists in the
launcher, runtime, workflow, or stage payloads.

## File-size discipline

New Dart source and test files under `lib/sc_master/` and `test/sc_master/`
must remain at or below 160 physical lines. Systems are split by responsibility
and grouped into focused folders.

## Canon limits

The recovered project material does not contain the exact six-faction names,
complete unit/building roster, complete tech tree, or final balance formulas.
The implementation therefore uses data-driven placeholder faction slots and
generic military archetypes. It marks canonical roster data as pending instead
of inventing names or pretending unknown values are locked.

## Shadow behavior

1. Apply SC-213 through SC-270 in numerical order.
2. Run each Python verifier and keep going after failures.
3. Run checkpoint Flutter tests at SC-220, 230, 240, 250, 260, and 270.
4. Run final `flutter analyze`, all tests, and a debug APK build.
5. Push one generated shadow specimen commit back to the validation branch.
6. Upload a complete evidence artifact and make the workflow red unless every
   required check passed.
