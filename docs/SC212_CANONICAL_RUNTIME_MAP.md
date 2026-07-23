# SwiftConquer SC-212 Canonical Runtime Map

- Repository: `cube23games/swift_conquer_game`
- Production branch: `working/phase170-movement-ci`
- Inventory base: `949bb937fc06a4c18cb184fcab416aa0ea90b4a3`
- Tracked files inventoried: **275**
- Status: **Shadow reconciliation candidate**

## Canonical production path

- Root package manifest: `pubspec.yaml`
- Production entry point: `lib/main.dart`
- Primary game screen: `lib/screens/game_screen.dart`
- Production APK workflow: `.github/workflows/swiftconquer_apk.yml`
- Shadow governance workflow: `.github/workflows/auto-agent-shadow-ci.yml`

## Reference-only roots

- `_backup_1765496519/` — archive/reference only
- `_backup_1765576900/` — archive/reference only
- `swift_clean/` — separate experimental/reference app; not production runtime

## Deferred to SC-213 architecture lock

- **auto-agent-shadow-ci.yml**: `.auto-agent/templates/github/auto-agent-shadow-ci.yml`, `.github/workflows/auto-agent-shadow-ci.yml`
- **entity_id.dart**: `lib/game/core/entity_id.dart`, `lib/game/models/entity_id.dart`
- **input_controller.dart**: `lib/game/input/input_controller.dart`, `lib/game/ui/input_controller.dart`
- **simulation_step.dart**: `lib/game/core/simulation_step.dart`, `lib/game/simulation/simulation_step.dart`
- **victory_system.dart**: `lib/game/core/victory_system.dart`, `lib/game/victory/victory_system.dart`

These conflicts are preserved, not guessed away. SC-213 must select canonical implementations using imports, tests, and runtime evidence.

## Safety policy

- No production source deletion in SC-212
- No production source rename in SC-212
- No production commit from this shadow package
- No automatic tag
- All backup and recovery candidates remain preserved

