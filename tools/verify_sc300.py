#!/usr/bin/env python3
from pathlib import Path


REQUIRED = {
    'lib/main.dart': [
        "import 'sc_app/ui/swift_conquer_rts_screen.dart';",
        'SwiftConquerRtsScreen()',
        'SC_LEGACY_GAME_SCREEN',
        'SC_MASTER_SLICE',
    ],
    'lib/sc_app/catalog/rts_catalog.dart': [
        'class SwiftRtsCatalog',
        'prototypeStartingCredits = 15000',
        "'advanced_tech'",
        "'airfield'",
        "'naval_yard'",
        "'engineer'",
        "'spy'",
        'factionSlots',
        "'Swift Dominion'",
        "'Iron Pact'",
        "'Void Syndicate'",
        "'Verdant Union'",
        'legacyDlcPackNames',
        "'Faction Ascension'",
        "'War Machines'",
        "'Void Expansion'",
        "'Verdant Worlds'",
        'modernDlcPackIds = <String>[]',
        'reservedRosterNames',
        'standardUnitCap = 100',
        'largeBattleUnitCap = 200',
        'canonicalDataPending',
    ],
    'lib/sc_app/runtime/swift_rts_runtime.dart': [
        'class SwiftRtsRuntime',
        'Mobile HQ Center',
        'deployPlayerHq',
        'queueStructure',
        'placeReadyStructure',
        'queueUnit',
        'makePrimary',
        'setRallyPoint',
        'assignEngineerTask',
        'assignSpyTarget',
        'purgeCompromisedBuilding',
        'ordinarySellAvailable',
        'beginSpecialPowerTargeting',
        'commandMove',
        'commandAttack',
        '_tickHarvesters',
        '_tickCombat',
        '_tickAi',
        '_tickStorm',
        'authoritativeHash',
        'ReplayJournal',
        'IntegrityMonitor',
        'flaggedCheaterTeams',
        'manualRepairEnabled',
        '_tickManualRepairs',
        '_tickLowPowerBreakdown',
        '_applyIntegrityFinding',
        'unitCap',
    ],
    'lib/sc_app/runtime/visibility_grid.dart': [
        'class VisibilityGrid',
        '_explored',
        '_visible',
        'isExplored',
        'isVisible',
    ],
    'lib/sc_app/runtime/primary_facility_registry.dart': [
        'class PrimaryFacilityRegistry',
        "'barracks'",
        "'war_factory'",
        'makePrimary',
        'eligible.first',
    ],
    'lib/sc_app/runtime/runtime_queue.dart': [
        'class RuntimeBuildQueue',
        'readyOrder',
        'acceptReady',
        'cancelLast',
        'speedMultiplier',
    ],
    'lib/sc_app/ui/rts_production_drawer.dart': [
        "'STRUCTURES'",
        "'INFANTRY'",
        "'VEHICLES'",
        "'AIR'",
        "'NAVAL'",
        "'OPERATIONS'",
        "'TACTICAL'",
        'PageStorageKey',
        'SWIFT PRODUCTION',
    ],
    'lib/sc_app/ui/swift_conquer_rts_screen.dart': [
        '1 finger select/box • 2 fingers pan + pinch zoom',
        'sc300-drawer-scrim',
        'sc300-drawer-handle',
        'MAKE PRIMARY',
        'SET RALLY',
        'PURGE • 10%',
        'DEPLOY HQ',
        'Camera bookmark',
    ],
    'lib/sc_app/ui/swift_rts_painter.dart': [
        '_drawFog',
        '_drawOre',
        '_drawStorm',
        '_drawBuildings',
        '_drawRallyPoints',
        '_queueBar',
        "'P'",
        "'LOW POWER'",
        'flaggedCheaterTeams',
    ],
    'test/sc_app/runtime/swift_rts_runtime_test.dart': [
        'does not auto-deploy',
        'old queues stay put',
        'holds READY while every exit is blocked',
        'locked 10 percent',
        'ordinary building sale remains disabled',
        'integrity monitor',
    ],
    'test/sc_app/runtime/swift_rts_determinism_test.dart': [
        'identical state and replay',
        'replayJson',
        'authoritativeHash',
    ],
    'test/sc_app/ui/swift_conquer_rts_screen_test.dart': [
        'short landscape phone',
        'drawer handle closes production overlay',
        'ChoiceChip',
    ],
    'docs/SC300_CLEAN_ROOM_REFERENCES.md': [
        'CnC_Red_Alert',
        'CnC_Tiberian_Dawn',
        'CnCNet_RedAlert',
        'OpenRA',
        'does not copy third-party gameplay source',
        'Swift Dominion',
        'Faction Ascension',
    ],
}

FORBIDDEN_CODE_TOKENS = [
    'FactoryClass',
    'HouseClass',
    'SidebarClass',
    'OpenRA.',
    'CnCNet.',
    'Westwood',
    'Tiberium',
    'Soviet',
    'Allies',
    'GDI',
    'Nod',
]


def main() -> int:
    failures = []

    old_workflow = Path(
        '.github/workflows/sc271b-primary-production-routing-shadow.yml'
    )
    if old_workflow.exists():
        failures.append(f'old SC-271B workflow remains: {old_workflow}')

    for relative, tokens in REQUIRED.items():
        path = Path(relative)
        if not path.is_file():
            failures.append(f'missing {relative}')
            continue
        text = path.read_text(encoding='utf-8')
        for token in tokens:
            if token not in text:
                failures.append(f'{relative}: missing token {token!r}')

    code_root = Path('lib/sc_app')
    dart_files = sorted(code_root.rglob('*.dart'))
    if len(dart_files) < 10:
        failures.append(
            f'expected >=10 SC-300 Dart app files, found {len(dart_files)}'
        )

    for path in dart_files:
        text = path.read_text(encoding='utf-8')
        for token in FORBIDDEN_CODE_TOKENS:
            if token in text:
                failures.append(
                    f'{path}: clean-room forbidden token {token!r}'
                )

    if failures:
        for failure in failures:
            print(f'FAIL: {failure}')
        return 1

    print(
        'PASS: SC-300 clean-room RTS application source contract; '
        f'app_dart_files={len(dart_files)}'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
