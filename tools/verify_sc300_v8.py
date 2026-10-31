#!/usr/bin/env python3
from pathlib import Path

DRAWER = Path('lib/sc_app/ui/rts_production_drawer.dart')
TEST = Path('test/sc_app/ui/swift_conquer_rts_screen_test.dart')
WORKFLOW = Path(
    '.github/workflows/sc300-classic-rts-application-v8-shadow.yml'
)

def main() -> int:
    failures = []

    if not DRAWER.is_file():
        failures.append(f'missing {DRAWER}')
    else:
        text = DRAWER.read_text(encoding='utf-8')

        required = [
            """Text(
                          'SWIFT PRODUCTION',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,""",
            """Text(
                          'deterministic mobile RTS command surface',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,""",
            'maintainState: false,',
            'initiallyExpanded: _hasHq',
            'constraints: const BoxConstraints(minHeight: 92)',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{DRAWER}: missing {token!r}')

    if not TEST.is_file():
        failures.append(f'missing {TEST}')
    else:
        text = TEST.read_text(encoding='utf-8')

        # Preserve the original SC-300 verifier's literal UI contract.
        for token in [
            'short landscape phone',
            'drawer handle closes production overlay',
            'ChoiceChip',
        ]:
            if token not in text:
                failures.append(f'{TEST}: missing base token {token!r}')

        # v8 must be a normal pass/fail UI gate, not diagnostic instrumentation.
        for token in [
            'SC300_FLEX_DIAG',
            'SC300_FLEX_CREATOR',
            'SC300_INITIAL_EXCEPTION',
            'SC300_CLOSED_EXCEPTION',
            "package:flutter/rendering.dart",
        ]:
            if token in text:
                failures.append(f'{TEST}: diagnostic token remains {token!r}')

        if text.count('expect(tester.takeException(), isNull);') < 3:
            failures.append(
                f'{TEST}: expected >=3 independent overflow assertions'
            )

    if not WORKFLOW.is_file():
        failures.append(f'missing {WORKFLOW}')
    else:
        text = WORKFLOW.read_text(encoding='utf-8')
        required = [
            'validation/sc300-classic-rts-application-v8*',
            'Verify exact SC-300 v7 diagnostic parent',
            '438e560483b69f971983a61ad19d557c2fa0b0a1',
            'dbedc8dd830b380b11e36d9f8e6bf3c8065973c4',
            'python3 tools/verify_sc300.py',
            'python3 tools/verify_sc300_v8.py',
            'flutter analyze --no-fatal-infos --no-fatal-warnings',
            'flutter test test/sc_app/runtime --reporter expanded',
            'flutter test test/sc_app/ui --reporter expanded',
            'flutter test test/sc_master --reporter expanded',
            'flutter test --reporter expanded',
            'flutter build apk --debug',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{WORKFLOW}: missing {token!r}')

    if Path(
        '.github/workflows/sc300-renderflex-diagnostic-v7-shadow.yml'
    ).exists():
        failures.append('old v7 diagnostic workflow remains')

    if failures:
        for failure in failures:
            print(f'FAIL: {failure}')
        return 1

    print('PASS: SC-300 v8 exact drawer-header repair contract')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
