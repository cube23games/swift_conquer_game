import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_app/ui/swift_conquer_rts_screen.dart';

void _dumpOverflowingVerticalFlexes(WidgetTester tester, String phase) {
  var candidate = 0;

  for (final render in tester.allRenderObjects.whereType<RenderFlex>()) {
    if (!render.hasSize || render.direction != Axis.vertical) {
      continue;
    }

    var maxBottom = 0.0;
    RenderBox? child = render.firstChild;
    while (child != null) {
      final parentData = child.parentData as FlexParentData;
      final bottom = parentData.offset.dy + child.size.height;
      if (bottom > maxBottom) {
        maxBottom = bottom;
      }
      child = render.childAfter(child);
    }

    final overflow = maxBottom - render.size.height;
    if (overflow > 0.01) {
      candidate += 1;
      debugPrint(
        'SC300_FLEX_DIAG phase=$phase candidate=$candidate '
        'overflow=${overflow.toStringAsFixed(2)} '
        'size=${render.size} constraints=${render.constraints}',
      );
      debugPrint('SC300_FLEX_CREATOR ${render.debugCreator}');
      debugPrint(
        render.toStringDeep(
          minLevel: DiagnosticLevel.info,
          wrapWidth: 140,
        ),
      );
    }
  }

  debugPrint('SC300_FLEX_DIAG phase=$phase candidates=$candidate');
}

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
    expect(find.text('Power Plant'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);

    _dumpOverflowingVerticalFlexes(tester, 'drawer-open');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'drawer handle closes production overlay diagnostic without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SwiftConquerRtsScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    _dumpOverflowingVerticalFlexes(tester, 'before-close');
    final initialException = tester.takeException();
    debugPrint(
      'SC300_INITIAL_EXCEPTION '
      '${initialException == null ? "none" : initialException.toString()}',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('sc300-drawer-handle')),
    );
    await tester.pump(const Duration(milliseconds: 250));

    _dumpOverflowingVerticalFlexes(tester, 'after-close');
    final closedException = tester.takeException();
    debugPrint(
      'SC300_CLOSED_EXCEPTION '
      '${closedException == null ? "none" : closedException.toString()}',
    );

    expect(
      find.byKey(const ValueKey<String>('sc300-battlefield')),
      findsOneWidget,
    );
    expect(closedException, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
