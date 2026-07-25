import 'package:flutter/material.dart';

import '../../game/buildings/building_type.dart';
import '../../game/production/facility_production_queues.dart';
import 'production_section.dart';
import 'production_tile.dart';

typedef SlotCallback = void Function(int slot);
typedef SlotCount = int Function(int slot);
typedef SlotFilled = bool Function(int slot);

class CommandDrawer extends StatelessWidget {
  const CommandDrawer({
    super.key,
    required this.hasHq,
    required this.hasBarracks,
    required this.hasRefinery,
    required this.hasWarFactory,
    required this.hasAdvancedTech,
    required this.barracksCount,
    required this.warFactoryCount,
    required this.selectedRefinery,
    required this.pendingType,
    required this.primaryBarracksQueue,
    required this.primaryWarFactoryQueue,
    required this.selectedRefineryQueue,
    required this.onSelectStructure,
    required this.onQueueInfantry,
    required this.onQueueHarvester,
    required this.onQueueTank,
    required this.onClose,
    required this.onRecallGroup,
    required this.onAssignGroup,
    required this.groupCount,
    required this.onRecallBookmark,
    required this.onSaveBookmark,
    required this.bookmarkFilled,
  });

  final bool hasHq;
  final bool hasBarracks;
  final bool hasRefinery;
  final bool hasWarFactory;
  final bool hasAdvancedTech;
  final int barracksCount;
  final int warFactoryCount;
  final bool selectedRefinery;
  final BuildingType? pendingType;
  final ProductionQueueSnapshot? primaryBarracksQueue;
  final ProductionQueueSnapshot? primaryWarFactoryQueue;
  final ProductionQueueSnapshot? selectedRefineryQueue;
  final ValueChanged<BuildingType> onSelectStructure;
  final VoidCallback onQueueInfantry;
  final VoidCallback onQueueHarvester;
  final VoidCallback onQueueTank;
  final VoidCallback onClose;
  final SlotCallback onRecallGroup;
  final SlotCallback onAssignGroup;
  final SlotCount groupCount;
  final SlotCallback onRecallBookmark;
  final SlotCallback onSaveBookmark;
  final SlotFilled bookmarkFilled;

  String _queueText({
    required bool unlocked,
    required String source,
    required int online,
    required ProductionQueueSnapshot? queue,
  }) {
    if (!unlocked) return 'Requires $source';

    final building = queue?.buildingId.value;
    final sourceText = building == null
        ? 'Primary $source ready'
        : 'Primary $source #$building';
    final onlineText = online > 1 ? ' • $online online' : '';

    if (queue == null) return '$sourceText$onlineText • Idle';

    final percent = (queue.progress * 100).round();
    final state = queue.ready ? 'READY' : '$percent%';
    return '$sourceText$onlineText • '
        '${queue.totalOrders}/${queue.capacity} • $state';
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.43,
      children: children,
    );
  }

  Widget _structures() {
    const types = <BuildingType>[
      BuildingType.powerPlant,
      BuildingType.barracks,
      BuildingType.refinery,
      BuildingType.warFactory,
    ];
    const icons = <IconData>[
      Icons.bolt,
      Icons.groups_2,
      Icons.local_shipping,
      Icons.precision_manufacturing,
    ];

    return _grid(<Widget>[
      for (int i = 0; i < types.length; i++)
        ProductionTile(
          title: types[i].label,
          icon: icons[i],
          subtitle: hasHq ? 'Tap, then place on map' : 'Deploy HQ first',
          enabled: hasHq,
          selected: pendingType == types[i],
          onPressed: () => onSelectStructure(types[i]),
        ),
    ]);
  }

  Widget _infantry() {
    return _grid(<Widget>[
      ProductionTile(
        title: 'Rifle Infantry',
        icon: Icons.person,
        subtitle: _queueText(
          unlocked: hasBarracks,
          source: 'Barracks',
          online: barracksCount,
          queue: primaryBarracksQueue,
        ),
        enabled: hasBarracks,
        onPressed: onQueueInfantry,
      ),
    ]);
  }

  Widget _vehicles() {
    final harvesterText = !hasRefinery
        ? 'Requires Refinery'
        : !selectedRefinery
            ? 'Select a Refinery'
            : selectedRefineryQueue == null
                ? 'Selected Refinery • Idle'
                : 'Selected Refinery • '
                    '${selectedRefineryQueue!.totalOrders}/'
                    '${selectedRefineryQueue!.capacity} • '
                    '${selectedRefineryQueue!.ready
                        ? "READY"
                        : "${(selectedRefineryQueue!.progress * 100).round()}%"}';

    return _grid(<Widget>[
      ProductionTile(
        title: 'Harvester',
        icon: Icons.agriculture,
        subtitle: harvesterText,
        enabled: hasRefinery && selectedRefinery,
        onPressed: onQueueHarvester,
      ),
      ProductionTile(
        title: 'Tank',
        icon: Icons.shield,
        subtitle: _queueText(
          unlocked: hasWarFactory,
          source: 'War Factory',
          online: warFactoryCount,
          queue: primaryWarFactoryQueue,
        ),
        enabled: hasWarFactory,
        onPressed: onQueueTank,
      ),
    ]);
  }

  Widget _specialPowers() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(14, 4, 14, 16),
      child: Text(
        'Advanced tactical powers will charge here after the '
        'Advanced Tech Center system is implemented.',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _slotRow({
    required String title,
    required int count,
    required Widget Function(int slot) builder,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (int slot = 1; slot <= count; slot++) ...<Widget>[
                  builder(slot),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tactical() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 2, 12, 0),
            child: Text(
              'Tap to recall. Long-press to save or assign.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          _slotRow(
            title: 'Control Groups',
            count: 7,
            builder: (slot) => GestureDetector(
              onLongPress: () => onAssignGroup(slot),
              child: OutlinedButton(
                onPressed: () => onRecallGroup(slot),
                child: Text(
                  '$slot${groupCount(slot) > 0
                      ? " (${groupCount(slot)})"
                      : ""}',
                ),
              ),
            ),
          ),
          _slotRow(
            title: 'Camera Bookmarks',
            count: 5,
            builder: (slot) => GestureDetector(
              onLongPress: () => onSaveBookmark(slot),
              child: OutlinedButton(
                onPressed: () => onRecallBookmark(slot),
                child: Text(
                  'B$slot${bookmarkFilled(slot) ? "*" : ""}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleUnlocked = hasRefinery || hasWarFactory;

    return Material(
      key: const ValueKey('command-drawer'),
      color: const Color(0xFF0E1728),
      elevation: 16,
      child: SafeArea(
        left: false,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 54,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'PRODUCTION',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close-command-drawer'),
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                key: const ValueKey('production-section-list'),
                padding: const EdgeInsets.only(top: 8, bottom: 18),
                children: <Widget>[
                  ProductionSection(
                    title: 'STRUCTURES',
                    icon: Icons.apartment,
                    subtitle: hasHq
                        ? 'HQ construction catalog'
                        : 'Deploy HQ to unlock',
                    initiallyExpanded: true,
                    enabled: hasHq,
                    child: _structures(),
                  ),
                  if (hasBarracks)
                    ProductionSection(
                      title: 'INFANTRY',
                      icon: Icons.groups_2,
                      subtitle: _queueText(
                        unlocked: true,
                        source: 'Barracks',
                        online: barracksCount,
                        queue: primaryBarracksQueue,
                      ),
                      child: _infantry(),
                    ),
                  if (vehicleUnlocked)
                    ProductionSection(
                      title: 'VEHICLES',
                      icon: Icons.precision_manufacturing,
                      subtitle: 'Refinery and War Factory production',
                      child: _vehicles(),
                    ),
                  if (hasAdvancedTech)
                    ProductionSection(
                      title: 'SPECIAL POWERS',
                      icon: Icons.auto_awesome,
                      subtitle: 'Advanced technology charging',
                      child: _specialPowers(),
                    ),
                  ProductionSection(
                    title: 'TACTICAL',
                    icon: Icons.radar,
                    subtitle: 'Groups and camera bookmarks',
                    child: _tactical(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
