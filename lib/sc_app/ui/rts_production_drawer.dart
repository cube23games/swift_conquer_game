import 'package:flutter/material.dart';

import '../../sc_master/core/id/entity_id.dart';
import '../catalog/rts_catalog.dart';
import '../runtime/runtime_queue.dart';
import '../runtime/swift_rts_runtime.dart';

typedef UnitQueueCallback = void Function(UnitBlueprint blueprint);
typedef StructureQueueCallback = void Function(BuildingBlueprint blueprint);
typedef SlotCallback = void Function(int slot);
typedef SlotCount = int Function(int slot);
typedef SlotFilled = bool Function(int slot);

class RtsProductionDrawer extends StatelessWidget {
  const RtsProductionDrawer({
    super.key,
    required this.runtime,
    required this.selectedBuilding,
    required this.onClose,
    required this.onQueueStructure,
    required this.onQueueUnit,
    required this.onCancelStructure,
    required this.onSpecialPower,
    required this.onRecallGroup,
    required this.onAssignGroup,
    required this.groupCount,
    required this.onRecallBookmark,
    required this.onSaveBookmark,
    required this.bookmarkFilled,
  });

  final SwiftRtsRuntime runtime;
  final EntityId? selectedBuilding;
  final VoidCallback onClose;
  final StructureQueueCallback onQueueStructure;
  final UnitQueueCallback onQueueUnit;
  final VoidCallback onCancelStructure;
  final VoidCallback onSpecialPower;
  final SlotCallback onRecallGroup;
  final SlotCallback onAssignGroup;
  final SlotCount groupCount;
  final SlotCallback onRecallBookmark;
  final SlotCallback onSaveBookmark;
  final SlotFilled bookmarkFilled;

  bool get _hasHq => runtime.ownsBuilding(
        SwiftRtsRuntime.playerTeamId,
        'hq',
      );

  Widget _section({
    required String title,
    required IconData icon,
    required String subtitle,
    required Widget child,
    bool initiallyExpanded = false,
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      color: const Color(0xFF152238),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('sc300-section-$title'),
        initiallyExpanded: initiallyExpanded,
        enabled: enabled,
        maintainState: false,
        leading: Icon(
          icon,
          color: enabled ? Colors.white70 : Colors.white30,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? Colors.white54 : Colors.white30,
            fontSize: 11,
          ),
        ),
        children: <Widget>[child],
      ),
    );
  }

  Widget _catalogGrid(
    BuildContext context,
    List<Widget Function(double width)> builders,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = ((constraints.maxWidth - 30) / 2)
            .clamp(118.0, 180.0)
            .toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final builder in builders) builder(width),
            ],
          ),
        );
      },
    );
  }

  Widget _catalogTile({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 92),
        child: Material(
        color: highlighted
            ? const Color(0xFF263957)
            : const Color(0xFF182337),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: highlighted
                ? const Color(0xFFF4C84A)
                : const Color(0xFF31435B),
            width: highlighted ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey<String>('sc300-tile-$title'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 25,
                  color: enabled ? Colors.white : Colors.white30,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled
                              ? Colors.white60
                              : Colors.white30,
                          fontSize: 9.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _structures(BuildContext context) {
    final queue = runtime.structureQueueSnapshot(
      SwiftRtsRuntime.playerTeamId,
    );
    final owned = runtime.ownedTech(SwiftRtsRuntime.playerTeamId);

    final builders = <Widget Function(double)>[
      for (final blueprint in SwiftRtsCatalog.buildings)
        if (blueprint.id != 'hq')
          (width) {
            final enabled = _hasHq &&
                blueprint.prerequisites.every(owned.contains) &&
                queue.count < queue.limit;
            final missing = blueprint.prerequisites
                .where((id) => !owned.contains(id))
                .join(', ');
            final subtitle = !enabled && missing.isNotEmpty
                ? 'Needs $missing'
                : '${blueprint.prototypeCost} cr • '
                    '${blueprint.prototypeBuildTicks ~/ 60}s prototype';
            return _catalogTile(
              width: width,
              title: blueprint.label,
              subtitle: subtitle,
              icon: _buildingIcon(blueprint.id),
              enabled: enabled,
              onTap: () => onQueueStructure(blueprint),
            );
          },
    ];

    return Column(
      children: <Widget>[
        _queueStrip(
          title: 'HQ BUILD QUEUE',
          queue: queue,
          emptyText: 'Idle',
          onCancel: queue.count > 0 ? onCancelStructure : null,
        ),
        _catalogGrid(context, builders),
      ],
    );
  }

  Widget _units(
    BuildContext context,
    RtsProductionLane lane,
  ) {
    final owned = runtime.ownedTech(SwiftRtsRuntime.playerTeamId);
    final units = SwiftRtsCatalog.unitsForLane(lane).toList();

    return _catalogGrid(
      context,
      <Widget Function(double)>[
        for (final blueprint in units)
          (width) {
            final enabled =
                blueprint.prerequisites.every(owned.contains);
            final missing = blueprint.prerequisites
                .where((id) => !owned.contains(id))
                .join(', ');

            final facility = blueprint.producer == 'refinery'
                ? selectedBuilding
                : runtime.primaryFacilities.primaryFor(
                    world: runtime.world,
                    teamId: SwiftRtsRuntime.playerTeamId,
                    archetype: blueprint.producer,
                  );

            final queue = facility == null
                ? null
                : runtime.facilityQueueSnapshot(facility);

            final producerText = facility == null
                ? blueprint.producer
                : '${blueprint.producer} #${facility.value}';
            final queueText = queue == null
                ? 'idle'
                : '${queue.count}/${queue.limit}'
                    '${queue.ready ? " READY" : ""}';

            final subtitle = !enabled && missing.isNotEmpty
                ? 'Needs $missing'
                : '${blueprint.prototypeCost} cr • '
                    '$producerText • $queueText';

            return _catalogTile(
              width: width,
              title: blueprint.label,
              subtitle: subtitle,
              icon: _unitIcon(blueprint.id),
              enabled: enabled &&
                  (blueprint.producer != 'refinery' ||
                      runtime.world.buildings[selectedBuilding]?.archetype ==
                          'refinery'),
              onTap: () => onQueueUnit(blueprint),
            );
          },
      ],
    );
  }

  Widget _operations(BuildContext context) {
    final spy = SwiftRtsCatalog.unit('spy');
    final owned = runtime.ownedTech(SwiftRtsRuntime.playerTeamId);
    final spyEnabled = spy.prerequisites.every(owned.contains);
    final special = runtime.specialPowers[SwiftRtsRuntime.playerTeamId]!;
    final advanced =
        runtime.ownsBuilding(SwiftRtsRuntime.playerTeamId, 'advanced_tech');
    final charge = special.chargeTicks <= 0
        ? 0.0
        : (special.progress / special.chargeTicks)
            .clamp(0.0, 1.0)
            .toDouble();

    return Column(
      children: <Widget>[
        _catalogGrid(
          context,
          <Widget Function(double)>[
            (width) => _catalogTile(
                  width: width,
                  title: spy.label,
                  subtitle: spyEnabled
                      ? '${spy.prototypeCost} cr • intelligence'
                      : 'Needs Barracks + Advanced Tech',
                  icon: Icons.visibility_outlined,
                  enabled: spyEnabled,
                  onTap: () => onQueueUnit(spy),
                ),
            (width) => _catalogTile(
                  width: width,
                  title: SwiftRtsCatalog.prototypeSpecialPower.label,
                  subtitle: !advanced
                      ? 'Needs Advanced Tech Center'
                      : special.ready
                          ? 'READY • choose target'
                          : '${(charge * 100).round()}% charged',
                  icon: Icons.bolt_outlined,
                  enabled: special.ready,
                  onTap: onSpecialPower,
                  highlighted: special.ready,
                ),
          ],
        ),
        if (advanced)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: LinearProgressIndicator(
              value: charge,
              minHeight: 5,
              backgroundColor: const Color(0xFF263247),
            ),
          ),
      ],
    );
  }

  Widget _placeholderLane(
    BuildContext context, {
    required String facility,
    required String message,
  }) {
    final unlocked =
        runtime.ownsBuilding(SwiftRtsRuntime.playerTeamId, facility);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 16),
      child: Text(
        unlocked
            ? message
            : 'Construct ${SwiftRtsCatalog.building(facility).label} '
                'to unlock this lane.',
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _tactical() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Control Groups • tap recall, long-press assign',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (var slot = 1; slot <= 7; slot += 1)
                GestureDetector(
                  onLongPress: () => onAssignGroup(slot),
                  child: OutlinedButton(
                    onPressed: () => onRecallGroup(slot),
                    child: Text(
                      '$slot${groupCount(slot) > 0
                          ? "(${groupCount(slot)})"
                          : ""}',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Camera Bookmarks • tap recall, long-press save',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (var slot = 1; slot <= 5; slot += 1)
                GestureDetector(
                  onLongPress: () => onSaveBookmark(slot),
                  child: OutlinedButton(
                    onPressed: () => onRecallBookmark(slot),
                    child: Text(
                      'B$slot${bookmarkFilled(slot) ? "*" : ""}',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _queueStrip({
    required String title,
    required RuntimeQueueSnapshot queue,
    required String emptyText,
    VoidCallback? onCancel,
  }) {
    final current = queue.current;
    final status = current == null
        ? emptyText
        : '${current.label} • ${queue.count}/${queue.limit}'
            '${queue.ready ? " • READY" : ""}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF101A2A),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$title • $status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'CANCEL LAST',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
              ],
            ),
            if (current != null)
              LinearProgressIndicator(
                value: queue.progress,
                minHeight: 4,
                backgroundColor: const Color(0xFF253249),
              ),
          ],
        ),
      ),
    );
  }

  IconData _buildingIcon(String id) {
    switch (id) {
      case 'power_plant':
        return Icons.bolt;
      case 'barracks':
        return Icons.groups_2;
      case 'refinery':
        return Icons.local_shipping;
      case 'war_factory':
        return Icons.precision_manufacturing;
      case 'silo':
        return Icons.inventory_2_outlined;
      case 'advanced_tech':
        return Icons.memory;
      case 'airfield':
        return Icons.flight_takeoff;
      case 'naval_yard':
        return Icons.sailing;
      default:
        return Icons.apartment;
    }
  }

  IconData _unitIcon(String id) {
    switch (id) {
      case 'infantry':
        return Icons.person;
      case 'engineer':
        return Icons.engineering;
      case 'spy':
        return Icons.visibility_outlined;
      case 'harvester':
        return Icons.agriculture;
      case 'tank':
        return Icons.shield;
      default:
        return Icons.adjust;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBarracks =
        runtime.ownsBuilding(SwiftRtsRuntime.playerTeamId, 'barracks');
    final hasVehicles =
        runtime.ownsBuilding(SwiftRtsRuntime.playerTeamId, 'refinery') ||
            runtime.ownsBuilding(
              SwiftRtsRuntime.playerTeamId,
              'war_factory',
            );
    final hasAdvanced = runtime.ownsBuilding(
      SwiftRtsRuntime.playerTeamId,
      'advanced_tech',
    );

    return Material(
      key: const ValueKey<String>('sc300-production-drawer'),
      color: const Color(0xFF0E1728),
      elevation: 18,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'SWIFT PRODUCTION',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'deterministic mobile RTS command surface',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('sc300-close-drawer'),
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                key: const ValueKey<String>('sc300-production-list'),
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                children: <Widget>[
                  _section(
                    title: 'STRUCTURES',
                    icon: Icons.apartment,
                    subtitle: _hasHq
                        ? 'HQ construction queue'
                        : 'Deploy HQ to unlock',
                    initiallyExpanded: _hasHq,
                    enabled: _hasHq,
                    child: _structures(context),
                  ),
                  if (hasBarracks)
                    _section(
                      title: 'INFANTRY',
                      icon: Icons.groups_2,
                      subtitle: 'Primary Barracks production',
                      child: _units(
                        context,
                        RtsProductionLane.infantry,
                      ),
                    ),
                  if (hasVehicles)
                    _section(
                      title: 'VEHICLES',
                      icon: Icons.precision_manufacturing,
                      subtitle: 'Refinery + Primary War Factory',
                      child: _units(
                        context,
                        RtsProductionLane.vehicles,
                      ),
                    ),
                  if (runtime.ownsBuilding(
                    SwiftRtsRuntime.playerTeamId,
                    'airfield',
                  ))
                    _section(
                      title: 'AIR',
                      icon: Icons.flight,
                      subtitle: 'Airfield production lane',
                      child: _placeholderLane(
                        context,
                        facility: 'airfield',
                        message:
                            'Air runtime is wired; final faction aircraft catalog is canon-pending.',
                      ),
                    ),
                  if (runtime.ownsBuilding(
                    SwiftRtsRuntime.playerTeamId,
                    'naval_yard',
                  ))
                    _section(
                      title: 'NAVAL',
                      icon: Icons.sailing,
                      subtitle: 'Naval Yard production lane',
                      child: _placeholderLane(
                        context,
                        facility: 'naval_yard',
                        message:
                            'Naval runtime is wired; final faction vessel catalog is canon-pending.',
                      ),
                    ),
                  if (hasAdvanced)
                    _section(
                      title: 'OPERATIONS',
                      icon: Icons.radar,
                      subtitle: 'Espionage + special powers',
                      child: _operations(context),
                    ),
                  _section(
                    title: 'TACTICAL',
                    icon: Icons.grid_view,
                    subtitle: 'Control groups + camera bookmarks',
                    child: _tactical(),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 0),
                    child: Text(
                      'Legacy: Swift Dominion • modern six-faction/DLC canon pending',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                      ),
                    ),
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
