#!/usr/bin/env python3
from pathlib import Path
import re


REQUIRED = {
    'lib/features/hud/context_command_bar.dart': [
        'class CommandBarAction',
        'final List<CommandBarAction> actions;',
        'ListView.separated',
        'scrollDirection: Axis.horizontal',
        'height: 56',
    ],
    'lib/screens/game_screen.dart': [
        'final actions = <CommandBarAction>[];',
        'CommandBarAction(',
        'ContextCommandBar(',
        'CommandDrawerHandle',
        '2 fingers pan + pinch zoom',
    ],
    'test/features/hud/context_command_bar_small_screen_test.dart': [
        'CommandBarAction(label: label',
        "ValueKey('context-command-bar')",
        'Size(480, 280)',
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

    checked = [
        Path('lib/features/hud/context_command_bar.dart'),
        Path('lib/screens/game_screen.dart'),
        Path('test/features/hud/context_command_bar_small_screen_test.dart'),
    ]
    for path in checked:
        if not path.is_file():
            continue
        text = path.read_text(encoding='utf-8')
        if re.search(r'\bContextAction\b', text):
            failures.append(f'{path}: old ambiguous ContextAction remains')

    hud = Path('lib/features/hud/context_command_bar.dart')
    if hud.is_file():
        lines = len(hud.read_text(encoding='utf-8').splitlines())
        if lines > 140:
            failures.append(f'command bar file unexpectedly large: {lines}')

    if failures:
        for failure in failures:
            print(f'FAIL: {failure}')
        return 1

    print('PASS: SC-271A v2 command-bar action collision repair')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
