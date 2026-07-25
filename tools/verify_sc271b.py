#!/usr/bin/env python3
from pathlib import Path


REQUIRED = {
    'lib/game/production/primary_production_registry.dart': [
        'class PrimaryProductionRegistry',
        'BuildingType.barracks',
        'BuildingType.warFactory',
        'Entity IDs are monotonic',
        'primaryIdsForTeam',
    ],
    'lib/screens/game_screen.dart': [
        'PrimaryProductionRegistry primaryProduction',
        'Make Primary Barracks',
        'Make Primary War Factory',
        'Primary Barracks #',
        'Primary War Factory #',
        'primaryProductionFacilities:',
    ],
    'lib/features/command_drawer/command_drawer.dart': [
        'required this.barracksCount',
        'required this.warFactoryCount',
        'Primary $source',
        'final enabled = widget.hasBarracks;',
        'final tankEnabled = widget.hasWarFactory;',
    ],
    'lib/game/ui/world_painter.dart': [
        'primaryProductionFacilities',
        '_drawPrimaryProductionBadge',
        "text: 'P'",
    ],
    'test/game/production/primary_production_registry_test.dart': [
        'first Barracks stays primary until player changes it',
        'destroyed primary falls back to oldest surviving facility',
        'teams keep separate primary facilities',
    ],
    'test/features/command_drawer/command_drawer_small_screen_test.dart': [
        'Primary Barracks • 2 online',
        'Primary War Factory • 2 online',
    ],
}

FORBIDDEN = {
    'lib/features/command_drawer/command_drawer.dart': [
        'required this.selectedBarracks',
        'required this.selectedWarFactory',
        'widget.selectedBarracks',
        'widget.selectedWarFactory',
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

    for relative, tokens in FORBIDDEN.items():
        path = Path(relative)
        if not path.is_file():
            continue
        text = path.read_text(encoding='utf-8')
        for token in tokens:
            if token in text:
                failures.append(f'{relative}: forbidden token remains {token!r}')

    if failures:
        for failure in failures:
            print(f'FAIL: {failure}')
        return 1

    print('PASS: SC-271B primary production routing source contract')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
