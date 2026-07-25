import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/features/command_drawer/command_drawer.dart';
import 'package:swift_conquer_game/game/buildings/building_type.dart';
import 'package:swift_conquer_game/game/core/entity_id.dart';
import 'package:swift_conquer_game/game/production/facility_production_queues.dart';
import 'package:swift_conquer_game/game/production/production_unit_type.dart';

ProductionQueueSnapshot queueSnapshot({
  required int buildingId,
  required ProductionUnitType item,
  int count = 2,
  double progress = 0.5,
}) {
  return ProductionQueueSnapshot(
    buildingId: EntityId(buildingId),
    current: item,
    totalOrders: count,
    progress: progress,
    ready: progress >= 1,
    capacity: 5,
  );
}

CommandDrawer testDrawer({
  bool hasHq = true,
  bool hasBarracks = false,
  bool hasRefinery = false,
  bool hasWarFactory = false,
  int barracksCount = 0,
  int warFactoryCount = 0,
  ProductionQueueSnapshot? barracksQueue,
  ProductionQueueSnapshot? warFactoryQueue,
  VoidCallback? onQueueInfantry,
  VoidCallback? onQueueTank,
}) {
  return CommandDrawer(
    hasHq: hasHq,
    hasBarracks: hasBarracks,
    hasRefinery: hasRefinery,
    hasWarFactory: hasWarFactory,
    hasAdvancedTech: false,
    barracksCount: barracksCount,
    warFactoryCount: warFactoryCount,
    selectedRefinery: false,
    pendingType: null,
    primaryBarracksQueue: barracksQueue,
    primaryWarFactoryQueue: warFactoryQueue,
    selectedRefineryQueue: null,
    onSelectStructure: (_) {},
    onQueueInfantry: onQueueInfantry ?? () {},
    onQueueHarvester: () {},
    onQueueTank: onQueueTank ?? () {},
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
  testWidgets('short landscape drawer uses expandable sections without tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(width: 320, child: testDrawer()),
      ),
    ));

    expect(find.text('STRUCTURES'), findsOneWidget);
    expect(find.text('TACTICAL'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Power Plant'), findsOneWidget);
    expect(find.text('War Factory'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Barracks adds Infantry section and displays queue status',
      (tester) async {
    var queued = false;
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: testDrawer(
        hasBarracks: true,
        barracksCount: 2,
        barracksQueue: queueSnapshot(
          buildingId: 7,
          item: ProductionUnitType.rifleInfantry,
        ),
        onQueueInfantry: () => queued = true,
      ),
    ));

    expect(find.text('INFANTRY'), findsOneWidget);
    await tester.tap(find.text('INFANTRY'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Primary Barracks #7'), findsWidgets);
    expect(find.text('Rifle Infantry'), findsOneWidget);
    await tester.tap(find.text('Rifle Infantry'));
    await tester.pump();
    expect(queued, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('War Factory adds Vehicles section and queues Tank',
      (tester) async {
    var queued = false;
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: testDrawer(
        hasWarFactory: true,
        warFactoryCount: 1,
        warFactoryQueue: queueSnapshot(
          buildingId: 9,
          item: ProductionUnitType.tank,
          count: 1,
          progress: 1,
        ),
        onQueueTank: () => queued = true,
      ),
    ));

    expect(find.text('VEHICLES'), findsOneWidget);
    await tester.tap(find.text('VEHICLES'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Primary War Factory #9'), findsWidgets);
    expect(find.textContaining('READY'), findsWidgets);
    await tester.tap(find.text('Tank'));
    await tester.pump();
    expect(queued, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Special Powers stays hidden before advanced technology',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: testDrawer()));
    expect(find.text('SPECIAL POWERS'), findsNothing);
  });
}
