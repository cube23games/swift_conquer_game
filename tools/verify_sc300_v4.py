#!/usr/bin/env python3
from pathlib import Path

DRAWER = Path('lib/sc_app/ui/rts_production_drawer.dart')
WORKFLOW = Path(
    '.github/workflows/sc300-classic-rts-application-v4-shadow.yml'
)

def main() -> int:
    failures = []

    if not DRAWER.is_file():
        failures.append(f'missing {DRAWER}')
    else:
        text = DRAWER.read_text(encoding='utf-8')
        required = [
            'constraints: const BoxConstraints(minHeight: 92)',
            'initiallyExpanded: _hasHq',
            "subtitle: _hasHq",
            "'Deploy HQ to unlock'",
        ]
        forbidden = [
            'height: 92,',
            'initiallyExpanded: true,\n                    enabled: _hasHq,',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{DRAWER}: missing {token!r}')
        for token in forbidden:
            if token in text:
                failures.append(f'{DRAWER}: forbidden token remains {token!r}')

    if not WORKFLOW.is_file():
        failures.append(f'missing {WORKFLOW}')
    else:
        text = WORKFLOW.read_text(encoding='utf-8')
        required = [
            'validation/sc300-classic-rts-application-v4*',
            'Verify exact SC-300 v3 parent',
            '21769ad963054a3e0b6e52dedc3faa78e8b07994',
            'dbedc8dd830b380b11e36d9f8e6bf3c8065973c4',
            'python3 tools/verify_sc300.py',
            'python3 tools/verify_sc300_v4.py',
            'flutter analyze --no-fatal-infos --no-fatal-warnings',
            'flutter test test/sc_app/runtime --reporter expanded',
            'flutter test test/sc_app/ui --reporter expanded',
            'flutter test test/sc_master --reporter expanded',
            'flutter test --reporter expanded',
            'flutter build apk --debug',
        ]
        forbidden = [
            'Verify exact failed SC-300 v1 parent',
            'validation/sc300-classic-rts-application-v3*',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{WORKFLOW}: missing {token!r}')
        for token in forbidden:
            if token in text:
                failures.append(f'{WORKFLOW}: forbidden token remains {token!r}')

    old_workflow = Path(
        '.github/workflows/sc300-classic-rts-application-v3-shadow.yml'
    )
    if old_workflow.exists():
        failures.append(f'old v3 workflow remains: {old_workflow}')

    if failures:
        for failure in failures:
            print(f'FAIL: {failure}')
        return 1

    print('PASS: SC-300 v4 short-landscape drawer repair contract')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
