import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/ui/sc_master_debug_screen.dart';

void main() {
  testWidgets('SC-269 debug slice exposes the core actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScMasterDebugScreen()));
    expect(find.text('Move Mobile HQ'), findsOneWidget);
    expect(find.text('Deploy HQ'), findsOneWidget);
    expect(find.text('Harvest Ore'), findsOneWidget);
    expect(find.text('Attack Enemy'), findsOneWidget);
  });
}
