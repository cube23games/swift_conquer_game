#!/usr/bin/env python3
from pathlib import Path

PAINTER = Path('lib/sc_app/ui/swift_rts_painter.dart')
WORKFLOW = Path(
    '.github/workflows/sc300-classic-rts-application-v3-shadow.yml'
)

def main() -> int:
    failures = []

    if not PAINTER.is_file():
        failures.append(f'missing {PAINTER}')
    else:
        text = PAINTER.read_text(encoding='utf-8')
        required = [
            '_queueBar(\n          canvas: canvas,',
            '_queueBar(\n            canvas: canvas,',
            'width: (27 * camera.zoom.clamp(0.75, 1.2)).toDouble(),',
        ]
        forbidden = [
            "import '../../sc_master/core/id/entity_id.dart';",
            "import '../../sc_master/world/building_state.dart';",
            "import '../../sc_master/world/unit_state.dart';",
            '_queueBar(\n          canvas,',
            '_queueBar(\n            canvas,',
            '2(7 * camera.zoom',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{PAINTER}: missing {token!r}')
        for token in forbidden:
            if token in text:
                failures.append(f'{PAINTER}: forbidden token remains {token!r}')

    if not WORKFLOW.is_file():
        failures.append(f'missing {WORKFLOW}')
    else:
        text = WORKFLOW.read_text(encoding='utf-8')
        required = [
            'validation/sc300-classic-rts-application-v3*',
            'Verify exact failed SC-300 v1 parent',
            'cc5729b4105912e2849309dad4cb262a58165622',
            'dbedc8dd830b380b11e36d9f8e6bf3c8065973c4',
            'python3 tools/verify_sc300.py',
            'python3 tools/verify_sc300_v3.py',
            'flutter analyze --no-fatal-infos --no-fatal-warnings',
            'flutter test test/sc_app/runtime --reporter expanded',
            'flutter test test/sc_app/ui --reporter expanded',
            'flutter test test/sc_master --reporter expanded',
            'flutter test --reporter expanded',
            'flutter build apk --debug',
        ]
        forbidden = [
            'Verify exact green SC-271B parent',
            'validation/sc300-classic-rts-application-v1*',
        ]
        for token in required:
            if token not in text:
                failures.append(f'{WORKFLOW}: missing {token!r}')
        for token in forbidden:
            if token in text:
                failures.append(f'{WORKFLOW}: forbidden token remains {token!r}')

    for old in (
        '.github/workflows/sc300-classic-rts-application-shadow.yml',
        '.github/workflows/sc300-classic-rts-application-v2-shadow.yml',
    ):
        if Path(old).exists():
            failures.append(f'old workflow remains: {old}')

    if failures:
        for failure in failures:
            print(f'FAIL: {failure}')
        return 1

    print('PASS: SC-300 v3 exact analyzer-repair + verifier contract')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
