#!/usr/bin/env python3
from pathlib import Path
DRAWER=Path('lib/sc_app/ui/rts_production_drawer.dart')
TEST=Path('test/sc_app/ui/swift_conquer_rts_screen_test.dart')
WORKFLOW=Path('.github/workflows/sc300-classic-rts-application-v6-shadow.yml')
def main():
    failures=[]
    if not DRAWER.is_file(): failures.append(f'missing {DRAWER}')
    else:
        text=DRAWER.read_text(encoding='utf-8')
        for token in ['maintainState: false,','initiallyExpanded: _hasHq','constraints: const BoxConstraints(minHeight: 92)']:
            if token not in text: failures.append(f'{DRAWER}: missing {token!r}')
        for token in ['maintainState: true,','height: 92,']:
            if token in text: failures.append(f'{DRAWER}: forbidden token remains {token!r}')
    if not TEST.is_file(): failures.append(f'missing {TEST}')
    else:
        text=TEST.read_text(encoding='utf-8')
        required=['short landscape phone','drawer handle closes production overlay','ChoiceChip',"expect(find.text('Power Plant'), findsNothing);",'and isolates frame','Clear/prove the initial open-drawer frame first']
        for token in required:
            if token not in text: failures.append(f'{TEST}: missing {token!r}')
        if text.count('expect(tester.takeException(), isNull);') < 3: failures.append(f'{TEST}: expected >=3 independent exception assertions')
    if not WORKFLOW.is_file(): failures.append(f'missing {WORKFLOW}')
    else:
        text=WORKFLOW.read_text(encoding='utf-8')
        required=['validation/sc300-classic-rts-application-v6*','Verify exact SC-300 v4 parent','36eb70bc210c70b22f1204e30640614acef8e930','dbedc8dd830b380b11e36d9f8e6bf3c8065973c4','python3 tools/verify_sc300.py','python3 tools/verify_sc300_v6.py','flutter analyze --no-fatal-infos --no-fatal-warnings','flutter test test/sc_app/runtime --reporter expanded','flutter test test/sc_app/ui --reporter expanded','flutter test test/sc_master --reporter expanded','flutter test --reporter expanded','flutter build apk --debug']
        for token in required:
            if token not in text: failures.append(f'{WORKFLOW}: missing {token!r}')
    if Path('.github/workflows/sc300-classic-rts-application-v4-shadow.yml').exists(): failures.append('old v4 workflow remains')
    if failures:
        for f in failures: print('FAIL:',f)
        return 1
    print('PASS: SC-300 v6 base-verifier-compatible collapsed-section UI contract')
    return 0
if __name__=='__main__': raise SystemExit(main())
