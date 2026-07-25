#!/usr/bin/env python3
from pathlib import Path


REQUIRED = {
    'lib/features/command_drawer/command_drawer.dart': [
        'CommandDrawer',
        'GridView.count',
        'CommandDrawerTab.structures',
        'CommandDrawerTab.infantry',
        'CommandDrawerTab.vehicles',
        'CommandDrawerTab.tactical',
        'Requires $source',
    ],
    'lib/features/command_drawer/command_drawer_handle.dart': [
        "ValueKey('command-drawer-handle')",
        'COMMAND',
    ],
    'lib/features/hud/context_command_bar.dart': [
        'ListView.separated',
        'scrollDirection: Axis.horizontal',
        'height: 56',
    ],
    'lib/screens/game_screen.dart': [
        'AnimatedPositioned',
        "ValueKey('command-drawer-scrim')",
        '2 fingers pan + pinch zoom',
        'details.scale / lastScale',
        'CommandDrawerHandle',
        'ContextCommandBar',
    ],
}


def main() -> int:
    failures = []
    for relative, tokens in REQUIRED.items():
        path = Path(relative)
        if not path.is_file():
            failures.append(f'missing {relative}')
            continue
        text = path.read_text(encoding='utf-8')
        for token in tokens:
            if token not in text:
                failures.append(f'{relative}: missing token {token!r}')

    game = Path('lib/screens/game_screen.dart')
    if game.is_file():
        text = game.read_text(encoding='utf-8')
        for forbidden in ['_sidebarWidth', '3 fingers zoom', 'bottom: false']:
            if forbidden in text:
                failures.append(f'GameScreen still contains {forbidden!r}')

    for root in [
        Path('lib/features/command_drawer'),
        Path('lib/features/hud'),
        Path('test/features/command_drawer'),
        Path('test/features/hud'),
    ]:
        for path in root.rglob('*.dart'):
            lines = len(path.read_text(encoding='utf-8').splitlines())
            if lines > 320:
                failures.append(f'new Dart file too long: {path}={lines}')

    if failures:
        print('\n'.join(f'FAIL: {failure}' for failure in failures))
        return 1
    print('PASS: SC-271A mobile command drawer and overflow rescue')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
