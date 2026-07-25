import 'package:flutter/material.dart';

import '../../game/buildings/building_type.dart';
import 'command_drawer_tab.dart';
import 'production_tile.dart';

typedef SlotCallback = void Function(int slot);
typedef SlotCount = int Function(int slot);
typedef SlotFilled = bool Function(int slot);

class CommandDrawer extends StatefulWidget {
  const CommandDrawer({
    super.key,
    required this.hasHq,
    required this.hasBarracks,
    required this.hasRefinery,
    required this.hasWarFactory,
    required this.selectedBarracks,
    required this.selectedRefinery,
    required this.selectedWarFactory,
    required this.pendingType,
    required this.onSelectStructure,
    required this.onProduceInfantry,
    required this.onProduceHarvester,
    required this.onProduceTank,
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
  final bool selectedBarracks;
  final bool selectedRefinery;
  final bool selectedWarFactory;
  final BuildingType? pendingType;
  final ValueChanged<BuildingType> onSelectStructure;
  final VoidCallback onProduceInfantry;
  final VoidCallback onProduceHarvester;
  final VoidCallback onProduceTank;
  final VoidCallback onClose;
  final SlotCallback onRecallGroup;
  final SlotCallback onAssignGroup;
  final SlotCount groupCount;
  final SlotCallback onRecallBookmark;
  final SlotCallback onSaveBookmark;
  final SlotFilled bookmarkFilled;

  @override
  State<CommandDrawer> createState() => _CommandDrawerState();
}

class _CommandDrawerState extends State<CommandDrawer> {
  CommandDrawerTab tab = CommandDrawerTab.structures;

  String _requirement(bool unlocked, bool selected, String source) {
    if (!unlocked) return 'Requires $source';
    if (!selected) return 'Select $source';
    return 'Ready';
  }

  Widget _tileGrid(List<Widget> children) {
    return GridView.count(
      key: ValueKey('drawer-grid-${tab.name}'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.48,
      children: children,
    );
  }

  Widget _structures() {
    const types = [
      BuildingType.powerPlant,
      BuildingType.barracks,
      BuildingType.refinery,
      BuildingType.warFactory,
    ];
    const icons = [
      Icons.bolt,
      Icons.groups_2,
      Icons.local_shipping,
      Icons.precision_manufacturing,
    ];
    return _tileGrid([
      for (int i = 0; i < types.length; i++)
        ProductionTile(
          title: types[i].label,
          icon: icons[i],
          subtitle: widget.hasHq ? 'Tap, then place on map' : 'Deploy HQ first',
          enabled: widget.hasHq,
          selected: widget.pendingType == types[i],
          onPressed: () => widget.onSelectStructure(types[i]),
        ),
    ]);
  }

  Widget _infantry() {
    final enabled = widget.hasBarracks && widget.selectedBarracks;
    return _tileGrid([
      ProductionTile(
        title: 'Rifle Infantry',
        icon: Icons.person,
        subtitle: _requirement(
          widget.hasBarracks,
          widget.selectedBarracks,
          'Barracks',
        ),
        enabled: enabled,
        onPressed: widget.onProduceInfantry,
      ),
    ]);
  }

  Widget _vehicles() {
    final harvesterEnabled =
        widget.hasRefinery && widget.selectedRefinery;
    final tankEnabled =
        widget.hasWarFactory && widget.selectedWarFactory;
    return _tileGrid([
      ProductionTile(
        title: 'Harvester',
        icon: Icons.agriculture,
        subtitle: _requirement(
          widget.hasRefinery,
          widget.selectedRefinery,
          'Refinery',
        ),
        enabled: harvesterEnabled,
        onPressed: widget.onProduceHarvester,
      ),
      ProductionTile(
        title: 'Tank',
        icon: Icons.shield,
        subtitle: _requirement(
          widget.hasWarFactory,
          widget.selectedWarFactory,
          'War Factory',
        ),
        enabled: tankEnabled,
        onPressed: widget.onProduceTank,
      ),
    ]);
  }

  Widget _slotRow({
    required String title,
    required int count,
    required Widget Function(int slot) builder,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int slot = 1; slot <= count; slot++) ...[
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(
            'Tap to recall. Long-press to save or assign.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        _slotRow(
          title: 'Control Groups',
          count: 7,
          builder: (slot) => GestureDetector(
            onLongPress: () => widget.onAssignGroup(slot),
            child: OutlinedButton(
              onPressed: () => widget.onRecallGroup(slot),
              child: Text(
                '$slot${widget.groupCount(slot) > 0
                    ? " (${widget.groupCount(slot)})"
                    : ""}',
              ),
            ),
          ),
        ),
        _slotRow(
          title: 'Camera Bookmarks',
          count: 5,
          builder: (slot) => GestureDetector(
            onLongPress: () => widget.onSaveBookmark(slot),
            child: OutlinedButton(
              onPressed: () => widget.onRecallBookmark(slot),
              child: Text(
                'B$slot${widget.bookmarkFilled(slot) ? "*" : ""}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    switch (tab) {
      case CommandDrawerTab.structures:
        return _structures();
      case CommandDrawerTab.infantry:
        return _infantry();
      case CommandDrawerTab.vehicles:
        return _vehicles();
      case CommandDrawerTab.tactical:
        return _tactical();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('command-drawer'),
      color: const Color(0xFF0E1728),
      elevation: 16,
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'COMMAND',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close-command-drawer'),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final value in CommandDrawerTab.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text(value.label),
                        selected: tab == value,
                        onSelected: (_) => setState(() => tab = value),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }
}
