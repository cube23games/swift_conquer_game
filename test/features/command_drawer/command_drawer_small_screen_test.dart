import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/features/command_drawer/command_drawer.dart';
import 'package:swift_conquer_game/game/buildings/building_type.dart';

CommandDrawer testDrawer({
  BuildingType? pendingType,
  bool hasBarracks = false,
  bool hasWarFactory = false,
  int barracksCount = 0,
  int warFactoryCount = 0,
  VoidCallback? onProduceInfantry,
  VoidCallback? onProduceTank,
}) {
  return CommandDrawer(
    hasHq: true,
    hasBarracks: hasBarracks,
    hasRefinery: false,
    hasWarFactory: hasWarFactory,
    barracksCount: barracksCount,
    warFactoryCount: warFactoryCount,
    selectedRefinery: false,
    pendingType: pendingType,
    onSelectStructure: (_) {},
    onProduceInfantry: onProduceInfantry ?? () {},
    onProduceHarvester: () {},
    onProduceTank: onProduceTank ?? () {},
    onClose: () {},
    onRecallGroup: (_) {},
    onAssignGroup: (_) {},
    groupCount: (_) => 0,
    onRecallBookmark: (_) {},
    onSaveBookmark: (_) {},
    bookmarkFilled: (_) => false,
  );
}

void main() {
  testWidgets('drawer fits a short landscape phone and exposes all structures',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(width: 300, child: testDrawer()),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('Power Plant'), findsOneWidget);
    expect(find.text('Barracks'), findsOneWidget);
    expect(find.text('Refinery'), findsOneWidget);
    expect(find.text('War Factory'), findsOneWidget);
  });

  testWidgets('infantry tab explains its unlock requirement', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(home: testDrawer(
      pendingType: BuildingType.powerPlant,
    )));

    await tester.tap(find.text('Infantry'));
    await tester.pump();

    expect(find.text('Rifle Infantry'), findsOneWidget);
    expect(find.text('Requires Barracks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('infantry production routes through Primary Barracks',
      (tester) async {
    var produced = false;
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: testDrawer(
        hasBarracks: true,
        barracksCount: 2,
        onProduceInfantry: () => produced = true,
      ),
    ));

    await tester.tap(find.text('Infantry'));
    await tester.pump();

    expect(find.text('Primary Barracks • 2 online'), findsOneWidget);
    await tester.tap(find.text('Rifle Infantry'));
    await tester.pump();
    expect(produced, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tank production routes through Primary War Factory',
      (tester) async {
    var produced = false;
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: testDrawer(
        hasWarFactory: true,
        warFactoryCount: 2,
        onProduceTank: () => produced = true,
      ),
    ));

    await tester.tap(find.text('Vehicles'));
    await tester.pump();

    expect(find.text('Primary War Factory • 2 online'), findsOneWidget);
    await tester.tap(find.text('Tank'));
    await tester.pump();
    expect(produced, isTrue);
    expect(tester.takeException(), isNull);
  });
}
