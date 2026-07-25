# SC-271A v2 — Command-bar action collision repair

GitHub Actions run `30159924087` verified that both command-drawer tests passed.
The HUD test then failed at compile time because Flutter 3.35 exports a
framework class named `ContextAction`.

SwiftConquer v1 used the same unqualified name for its bottom command-bar data
model. That made references ambiguous in files importing both Flutter Material
and SwiftConquer's command-bar library.

The focused repair renames only the SwiftConquer model:

- old: `ContextAction`
- new: `CommandBarAction`

The repair updates:

- `lib/features/hud/context_command_bar.dart`
- `lib/screens/game_screen.dart`
- `test/features/hud/context_command_bar_small_screen_test.dart`

No gameplay rule, production catalog, drawer behavior, camera behavior, RTS
simulation, production branch, or tag policy is changed.
