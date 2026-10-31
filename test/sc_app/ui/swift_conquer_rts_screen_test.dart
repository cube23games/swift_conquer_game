import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_app/ui/swift_conquer_rts_screen.dart';

void main() {
  testWidgets('SC-300 default battlefield fits short landscape phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SwiftConquerRtsScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      find.byKey(const ValueKey<String>('sc300-battlefield')),
      findsOneWidget,
    );
    expect(find.text('SWIFT PRODUCTION'), findsOneWidget);
    expect(find.text('STRUCTURES'), findsOneWidget);
    expect(find.text('Deploy HQ to unlock'), findsOneWidget);

    // The collapsed disabled Structures lane must not keep its catalog
    // mounted before Headquarters deployment.
    expect(find.text('Power Plant'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('drawer handle closes production overlay without overflow and isolates frame',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SwiftConquerRtsScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    // Clear/prove the initial open-drawer frame first so the second assertion
    // cannot accidentally report an earlier exception.
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('sc300-drawer-handle')),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey<String>('sc300-battlefield')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
