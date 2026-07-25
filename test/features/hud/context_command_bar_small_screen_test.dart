import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/features/hud/context_command_bar.dart';

void main() {
  testWidgets('context bar stays one row on a short landscape phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ContextCommandBar(
            selectionCount: 3,
            actions: [
              for (final label in ['Deploy', 'Stop', 'Guard', 'Clear', 'More'])
                ContextAction(label: label, onPressed: () {}),
            ],
          ),
        ),
      ),
    ));

    expect(find.byKey(const ValueKey('context-command-bar')), findsOneWidget);
    expect(find.text('3 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
