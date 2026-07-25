#!/usr/bin/env python3
from pathlib import Path


REQUIRED = {
    'lib/game/production/facility_production_queues.dart': [
        'class FacilityProductionQueues',
        'class ProductionQueueSnapshot',
        'readySnapshots',
        'consumeReady',
        'cancelLast',
        'capacity = 5',
    ],
    'lib/game/production/production_unit_type.dart': [
        'enum ProductionUnitType',
        'prototypeBuildSeconds',
        'BuildingType.barracks',
        'BuildingType.refinery',
        'BuildingType.warFactory',
    ],
    'lib/features/command_drawer/production_section.dart': [
        'class ProductionSection',
        'ExpansionTile',
        'production-section-$title',
    ],
    'lib/features/command_drawer/command_drawer.dart': [
        "title: 'STRUCTURES'",
        "title: 'INFANTRY'",
        "title: 'VEHICLES'",
        "title: 'SPECIAL POWERS'",
        "title: 'TACTICAL'",
        'production-section-list',
        'primaryBarracksQueue',
        'primaryWarFactoryQueue',
        'onQueueInfantry',
        'onQueueTank',
    ],
    'lib/screens/game_screen.dart': [
        'FacilityProductionQueues productionQueues',
        '_drainReadyProduction',
        '_tryFindProductionSpawn',
        'return null;',
        'Queue Infantry',
        'Queue Harvester',
        'Queue Tank',
        'Cancel Last (',
        'productionQueueSnapshots:',
    ],
    'lib/game/ui/world_painter.dart': [
        'productionQueueSnapshots',
        '_drawProductionQueue',
        'item.shortLabel',
        'queue.ready',
        '2 fingers pan + pinch zoom',
    ],
    'test/game/production/facility_production_queues_test.dart': [
        'each production building owns an independent queue',
        'changing primary does not transfer existing orders',
        'ready order waits until explicitly consumed',
        'destroyed building removes its queue',
    ],
    'test/features/command_drawer/command_drawer_small_screen_test.dart': [
        'uses expandable sections without tabs',
        'Barracks adds Infantry section',
        'War Factory adds Vehicles section',
        'Special Powers stays hidden',
    ],
}

FORBIDDEN = {
    'lib/features/command_drawer/command_drawer.dart': [
        'CommandDrawerTab',
        'ChoiceChip',
        'selectedBarracks',
        'selectedWarFactory',
        'onProduceInfantry',
        'onProduceTank',
    ],
    'lib/screens/game_screen.dart': [
        '_findProductionSpawn(',
        'Infantry produced from Primary Barracks',
        'Tank produced from Primary War Factory',
    ],
}


def main() -> int:
    failures = []

    obsolete = Path(
        'lib/features/command_drawer/command_drawer_tab.dart'
    )
    if obsolete.exists():
        failures.append(f'obsolete tab file remains: {obsolete}')

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

    print('PASS: SC-272A unified production workflow source contract')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
