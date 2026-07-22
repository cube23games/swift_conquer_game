<!-- AUTO-AGENT MANAGED START -->
# Standing Project Knowledge — Manual Auto-Agent + Shadow CI

This file is the persistent workflow reference for ChatGPT Projects and other assistants that can use project files as context. It removes the need for a separate seed prompt after it has been added to the project context.

## Core operating model

The project uses two linked systems:

1. **Shadow CI** validates every proposed incremental stage and the final combined tree on a disposable validation branch. It keeps running after individual failures so the complete failure list can be repaired together.
2. **Manual Auto-Agent** promotes the already shadow-green stages to production one focused commit at a time, watching the exact CI run for each commit and pausing safely on network or verification interruptions.

The human remains the authorization layer. The system never tags automatically and never claims device, store, backend, billing, or real-provider success without corresponding evidence.

## Required sequence

1. Inspect exact repository identity and current state.
2. Build checksum-locked stage payloads with exact input/output hashes and changed-file allowlists.
3. Run source preflight.
4. Run Shadow CI across every incremental tree and the final combined tree.
5. Collect all failures in one evidence bundle.
6. Repair the complete failure set and rerun Shadow CI until green.
7. Lock the production train to the exact green shadow evidence.
8. Promote one stage at a time to the approved production branch.
9. Save and watch the exact CI run ID for each production commit.
10. Stop on confirmed red; pause and resume on verification unavailability.
11. Preserve evidence and never create an automatic tag.

## Verification language

Use only: implemented, locally verified, shadow CI verified, production CI verified, artifact verified, device verified, store verified, backend/provider verified.

## Project-specific behavior

Read `.auto-agent/project.json` and the selected profile before making recommendations. The Breakout Addiction reference profile is Android-first, Termux-operated, GitHub-Actions-built, forbids local Flutter/Android builds, requires generated `android/` to remain absent locally, and uses one focused commit per stage.

## Important limitation

A normal chat that is outside the relevant ChatGPT Project or does not have repository access cannot automatically see this file. In repository-aware Codex workflows, the root `AGENTS.md` supplies persistent instructions. In ChatGPT Projects, keep this file in Project sources so it remains available as project context.

## SwiftConquer-specific standing context

SwiftConquer is temporarily housed in `cube23games/swift_conquer_game`. The Phase 171–210 movement and base-building branch at `04d6db6d43a068612f1e79fc388666fdc75dee9b` is the approved working baseline. Development proceeds as SC-211 through SC-270 using ten-stage trains.

The first device gate is SC-220: Mobile HQ/deployed HQ, Power Plant, Barracks, Refinery, War Factory, visible infantry, visible tanks, selection, deselection, and authoritative movement. Flame must remain a renderer. Unresolved factions, named characters, naval rosters, technology trees, costs, and superweapon ownership must remain explicitly unresolved rather than invented.

<!-- AUTO-AGENT MANAGED END -->
