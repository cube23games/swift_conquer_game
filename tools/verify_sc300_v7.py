#!/usr/bin/env python3
from pathlib import Path

TEST = Path('test/sc_app/ui/swift_conquer_rts_screen_test.dart')
WORKFLOW = Path('.github/workflows/sc300-renderflex-diagnostic-v7-shadow.yml')


def main() -> int:
    failures = []

    if not TEST.is_file():
        failures.append(f'missing {TEST}')
    else:
        text = TEST.read_text(encoding='utf-8')
        required = [
            'short landscape phone',
            'drawer handle closes production overlay',
            'ChoiceChip',
            "import 'package:flutter/rendering.dart';",
            'whereType<RenderFlex>()',
            'SC300_FLEX_DIAG',
            'SC300_FLEX_CREATOR',
            "phase, 'drawer-open'" if False else "'drawer-open'",
            "'after-close'",
            'SC300_INITIAL_EXCEPTION',
            'SC300_CLOSED_EXCEPTION',
            'render.debugCreator',
            'render.toStringDeep(',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{TEST}: missing {token!r}')

    if not WORKFLOW.is_file():
        failures.append(f'missing {WORKFLOW}')
    else:
        text = WORKFLOW.read_text(encoding='utf-8')
        required = [
            'validation/sc300-renderflex-diagnostic-v7*',
            'Verify exact SC-300 v6 parent',
            'c4704460bc5c67fd5bbb6cd8b476a256d7d6a102',
            'dbedc8dd830b380b11e36d9f8e6bf3c8065973c4',
            'python3 tools/verify_sc300.py',
            'python3 tools/verify_sc300_v7.py',
            'flutter analyze --no-fatal-infos --no-fatal-warnings',
            'flutter test test/sc_app/runtime --reporter expanded',
            'flutter test test/sc_app/ui --reporter expanded',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{WORKFLOW}: missing {token!r}')

    if Path('.github/workflows/sc300-classic-rts-application-v6-shadow.yml').exists():
        failures.append('old v6 workflow remains')

    if failures:
        for failure in failures:
            print(f'FAIL: {failure}')
        return 1

    print('PASS: SC-300 v7 RenderFlex diagnostic contract')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
