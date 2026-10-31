import 'dart:async';

import 'package:flutter/material.dart';

import '../../sc_master/core/id/entity_id.dart';
import '../../sc_master/core/math/vec2.dart';
import '../catalog/rts_catalog.dart';
import '../runtime/primary_facility_registry.dart';
import '../runtime/swift_rts_runtime.dart';
import 'rts_camera.dart';
import 'rts_production_drawer.dart';
import 'swift_rts_painter.dart';

class SwiftConquerRtsScreen extends StatefulWidget {
  const SwiftConquerRtsScreen({super.key});

  @override
  State<SwiftConquerRtsScreen> createState() =>
      _SwiftConquerRtsScreenState();
}

class _CameraMark {
  final Vec2 offset;
  final double zoom;

  const _CameraMark(this.offset, this.zoom);
}

class _SwiftConquerRtsScreenState extends State<SwiftConquerRtsScreen> {
  final SwiftRtsRuntime runtime = SwiftRtsRuntime();
  final RtsCamera camera = RtsCamera(
    offset: const Vec2(280, 220),
    zoom: 1,
  );

  final Map<int, Set<EntityId>> groups = <int, Set<EntityId>>{};
  final Map<int, _CameraMark> bookmarks = <int, _CameraMark>{};

  Timer? _timer;
  bool _drawerOpen = true;
  EntityId? _rallyFacility;

  int _activePointers = 0;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _dragSelecting = false;
  Offset? _lastScaleFocal;
  double? _lastScaleValue;

  Size _playfieldSize = Size.zero;

  static const double _dragThreshold = 12;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      runtime.tick(1 / 60);
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Rect? get _selectionBox {
    if (!_dragSelecting || _dragStart == null || _dragCurrent == null) {
      return null;
    }
    return Rect.fromPoints(_dragStart!, _dragCurrent!);
  }

  EntityId? get _singleSelectedBuilding {
    if (runtime.selection.length != 1) return null;
    final id = runtime.selection.selected.first;
    final building = runtime.world.buildings[id];
    if (building == null ||
        !building.alive ||
        building.teamId != SwiftRtsRuntime.playerTeamId) {
      return null;
    }
    return id;
  }

  EntityId? get _singleSelectedMobileHq {
    if (runtime.selection.length != 1) return null;
    final id = runtime.selection.selected.first;
    final unit = runtime.world.units[id];
    if (unit == null ||
        !unit.alive ||
        unit.teamId != SwiftRtsRuntime.playerTeamId ||
        unit.archetype != 'mobile_hq_center') {
      return null;
    }
    return id;
  }

  List<EntityId> get _selectedFriendlyUnits {
    final ids = runtime.selection.selected.where((id) {
      final unit = runtime.world.units[id];
      return unit != null &&
          unit.alive &&
          unit.teamId == SwiftRtsRuntime.playerTeamId;
    }).toList()
      ..sort();
    return ids;
  }

  List<EntityId> get _selectedEngineers {
    return _selectedFriendlyUnits
        .where((id) => runtime.world.units[id]?.archetype == 'engineer')
        .toList();
  }

  void _notify(VoidCallback action) {
    setState(action);
  }

  void _clampCamera() {
    if (_playfieldSize == Size.zero) return;
    camera.clampToWorld(
      worldWidth: runtime.mapSpec.width,
      worldHeight: runtime.mapSpec.height,
      viewportWidth: _playfieldSize.width,
      viewportHeight: _playfieldSize.height,
    );
  }

  void _handleBattlefieldTap(Offset screenPosition) {
    final worldPosition = camera.screenToWorld(
      Vec2(screenPosition.dx, screenPosition.dy),
    );

    final rally = _rallyFacility;
    if (rally != null) {
      runtime.setRallyPoint(rally, worldPosition);
      _rallyFacility = null;
      return;
    }

    runtime.handleTap(worldPosition);
  }

  void _finishSelectionDrag() {
    final box = _selectionBox;
    if (box == null) return;

    final a = camera.screenToWorld(
      Vec2(box.left, box.top),
    );
    final b = camera.screenToWorld(
      Vec2(box.right, box.bottom),
    );
    runtime.selectBox(a: a, b: b);

    _dragStart = null;
    _dragCurrent = null;
    _dragSelecting = false;
  }

  void _assignGroup(int slot) {
    groups[slot] = Set<EntityId>.from(runtime.selection.selected);
    runtime.status =
        'Assigned ${groups[slot]!.length} item(s) to group $slot.';
    setState(() {});
  }

  void _recallGroup(int slot) {
    final stored = groups[slot] ?? const <EntityId>{};
    final alive = stored.where((id) {
      final unit = runtime.world.units[id];
      final building = runtime.world.buildings[id];
      return unit?.alive == true || building?.alive == true;
    }).toList()
      ..sort();

    runtime.selection.replaceWith(alive);
    runtime.status = alive.isEmpty
        ? 'Group $slot is empty.'
        : 'Recalled group $slot (${alive.length}).';
    setState(() {});
  }

  int _groupCount(int slot) {
    final stored = groups[slot] ?? const <EntityId>{};
    return stored.where((id) {
      return runtime.world.units[id]?.alive == true ||
          runtime.world.buildings[id]?.alive == true;
    }).length;
  }

  void _saveBookmark(int slot) {
    bookmarks[slot] = _CameraMark(
      Vec2(camera.offset.x, camera.offset.y),
      camera.zoom,
    );
    runtime.status = 'Saved camera bookmark $slot.';
    setState(() {});
  }

  void _recallBookmark(int slot) {
    final mark = bookmarks[slot];
    if (mark == null) {
      runtime.status = 'Camera bookmark $slot is empty.';
      setState(() {});
      return;
    }

    camera.offset = Vec2(mark.offset.x, mark.offset.y);
    camera.zoom = mark.zoom;
    _clampCamera();
    runtime.status = 'Recalled camera bookmark $slot.';
    setState(() {});
  }

  Widget _topHud() {
    final wallet = runtime.wallet(SwiftRtsRuntime.playerTeamId);
    final storage = runtime.storage(SwiftRtsRuntime.playerTeamId);
    final power = runtime.power(SwiftRtsRuntime.playerTeamId);

    final seconds = runtime.matchSeconds;
    final minutesText = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsText = (seconds % 60).toString().padLeft(2, '0');

    return Material(
      color: const Color(0xE6111827),
      child: SizedBox(
        height: 54,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 10),
            _metric(
              Icons.payments_outlined,
              '${wallet.balance}',
              'CREDITS',
            ),
            _metric(
              Icons.inventory_2_outlined,
              '${storage.stored}/${storage.capacity}',
              'ORE',
            ),
            _metric(
              Icons.bolt,
              '${power.produced}/${power.demand}',
              power.lowPower ? 'LOW POWER' : 'POWER',
              warning: power.lowPower,
            ),
            _metric(
              Icons.timer_outlined,
              '$minutesText:$secondsText',
              runtime.matchRules.suddenDeathActive(runtime.world.tick)
                  ? 'STORM'
                  : 'MATCH',
              warning: runtime.matchRules.suddenDeathActive(
                runtime.world.tick,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                runtime.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
            _topBookmarks(),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    IconData icon,
    String value,
    String label, {
    bool warning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: warning
            ? const Color(0x443B1D2B)
            : const Color(0x331F3348),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 17,
            color: warning
                ? const Color(0xFFFFA66B)
                : const Color(0xFF77D6FF),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: warning
                      ? const Color(0xFFFFA66B)
                      : Colors.white38,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topBookmarks() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var slot = 1; slot <= 5; slot += 1)
          GestureDetector(
            onLongPress: () => _saveBookmark(slot),
            child: InkWell(
              key: ValueKey<String>('sc300-bookmark-$slot'),
              onTap: () => _recallBookmark(slot),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 31,
                height: 31,
                margin: const EdgeInsets.only(left: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bookmarks.containsKey(slot)
                      ? const Color(0xFF263C56)
                      : const Color(0xFF1B2738),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: bookmarks.containsKey(slot)
                        ? const Color(0xFF6CCBF3)
                        : const Color(0xFF33445B),
                  ),
                ),
                child: Text(
                  'B$slot',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bottomCommandBar() {
    final selectedBuildingId = _singleSelectedBuilding;
    final selectedBuilding = selectedBuildingId == null
        ? null
        : runtime.world.buildings[selectedBuildingId];

    final actions = <Widget>[];

    if (_singleSelectedMobileHq != null) {
      actions.add(
        _action(
          'DEPLOY HQ',
          Icons.home_work_outlined,
          runtime.deployPlayerHq,
          primary: true,
        ),
      );
    }

    if (_selectedFriendlyUnits.isNotEmpty) {
      actions.add(
        _action(
          'STOP',
          Icons.stop_circle_outlined,
          () {
            runtime.stopSelected();
            return true;
          },
        ),
      );
    }

    if (selectedBuilding != null && selectedBuildingId != null) {
      if (PrimaryFacilityRegistry.supports(
            selectedBuilding.archetype,
          ) &&
          !runtime.primaryFacilities.isPrimary(
            world: runtime.world,
            teamId: SwiftRtsRuntime.playerTeamId,
            buildingId: selectedBuildingId,
          )) {
        actions.add(
          _action(
            'MAKE PRIMARY',
            Icons.star_outline,
            () => runtime.makePrimary(selectedBuildingId),
            primary: true,
          ),
        );
      }

      final blueprint =
          SwiftRtsCatalog.buildingOrNull(selectedBuilding.archetype);
      if (blueprint?.productionFacility == true) {
        actions.add(
          _action(
            _rallyFacility == selectedBuildingId
                ? 'CANCEL RALLY'
                : 'SET RALLY',
            Icons.flag_outlined,
            () {
              if (_rallyFacility == selectedBuildingId) {
                _rallyFacility = null;
                runtime.status = 'Rally-point targeting cancelled.';
              } else {
                _rallyFacility = selectedBuildingId;
                runtime.status =
                    'Tap battlefield to set ${blueprint!.label} rally point.';
              }
              return true;
            },
            primary: _rallyFacility == selectedBuildingId,
          ),
        );
      }

      final queue = runtime.facilityQueueSnapshot(selectedBuildingId);
      if (queue != null && queue.count > 0) {
        actions.add(
          _action(
            'CANCEL LAST (${queue.count})',
            Icons.undo,
            () =>
                runtime.cancelLastFacilityOrder(selectedBuildingId) != null,
          ),
        );
      }

      if (selectedBuilding.health < selectedBuilding.maxHealth) {
        actions.add(
          _action(
            runtime.manualRepairEnabled.contains(selectedBuildingId)
                ? 'STOP REPAIR'
                : 'REPAIR',
            Icons.build_outlined,
            () => runtime.manualRepair(selectedBuildingId),
          ),
        );
      }

      if (runtime.isCompromised(selectedBuildingId)) {
        actions.add(
          _action(
            'PURGE • 10%',
            Icons.delete_forever_outlined,
            () => runtime.purgeCompromisedBuilding(selectedBuildingId),
            primary: true,
          ),
        );
      }
    }

    if (_selectedEngineers.isNotEmpty) {
      for (final mode in EngineerTaskMode.values) {
        actions.add(
          _action(
            mode.name.toUpperCase(),
            mode == EngineerTaskMode.repair
                ? Icons.handyman_outlined
                : mode == EngineerTaskMode.capture
                    ? Icons.flag_circle_outlined
                    : Icons.power_off_outlined,
            () {
              runtime.setEngineerMode(mode);
              return true;
            },
            primary: runtime.engineerMode == mode,
          ),
        );
      }
    }

    final special =
        runtime.specialPowers[SwiftRtsRuntime.playerTeamId];
    if (special?.ready == true) {
      actions.add(
        _action(
          'SPECIAL READY',
          Icons.bolt_outlined,
          runtime.beginSpecialPowerTargeting,
          primary: true,
        ),
      );
    }

    actions.add(
      _action(
        'PRODUCTION',
        Icons.view_sidebar_outlined,
        () {
          _drawerOpen = true;
          return true;
        },
      ),
    );
    actions.add(
      _action(
        'CLEAR',
        Icons.deselect,
        () {
          runtime.clearSelection();
          _rallyFacility = null;
          runtime.status = 'Selection cleared.';
          return true;
        },
      ),
    );

    return Material(
      color: const Color(0xE6111827),
      child: SizedBox(
        height: 62,
        child: Row(
          children: <Widget>[
            Container(
              width: 116,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                runtime.selection.length == 0
                    ? 'NO SELECTION'
                    : '${runtime.selection.length} SELECTED',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: <Widget>[
                    for (final action in actions) ...<Widget>[
                      action,
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    bool Function() action, {
    bool primary = false,
  }) {
    final style = primary
        ? ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4C84A),
            foregroundColor: const Color(0xFF101827),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Color(0xFF3A4D67)),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );

    return primary
        ? ElevatedButton.icon(
            onPressed: () {
              _notify(() {
                action();
              });
            },
            style: style,
            icon: Icon(icon, size: 16),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: () {
              _notify(() {
                action();
              });
            },
            style: style,
            icon: Icon(icon, size: 16),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
  }

  Widget _drawer(double width) {
    return RtsProductionDrawer(
      runtime: runtime,
      selectedBuilding: _singleSelectedBuilding,
      onClose: () => setState(() => _drawerOpen = false),
      onQueueStructure: (blueprint) {
        setState(() {
          runtime.queueStructure(
            SwiftRtsRuntime.playerTeamId,
            blueprint.id,
          );
        });
      },
      onQueueUnit: (blueprint) {
        setState(() {
          final selected = _singleSelectedBuilding;
          final preferred = blueprint.producer == 'refinery' &&
                  runtime.world.buildings[selected]?.archetype == 'refinery'
              ? selected
              : null;
          runtime.queueUnit(
            teamId: SwiftRtsRuntime.playerTeamId,
            archetype: blueprint.id,
            preferredFacility: preferred,
          );
        });
      },
      onCancelStructure: () {
        setState(() {
          runtime.cancelLastStructure(SwiftRtsRuntime.playerTeamId);
        });
      },
      onSpecialPower: () {
        setState(() {
          if (runtime.beginSpecialPowerTargeting()) {
            _drawerOpen = false;
          }
        });
      },
      onRecallGroup: _recallGroup,
      onAssignGroup: _assignGroup,
      groupCount: _groupCount,
      onRecallBookmark: _recallBookmark,
      onSaveBookmark: _saveBookmark,
      bookmarkFilled: bookmarks.containsKey,
    );
  }

  Widget _drawerHandle(double drawerWidth) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      top: 108,
      right: _drawerOpen ? drawerWidth : 0,
      child: Material(
        color: const Color(0xFF17243A),
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(10),
        ),
        elevation: 8,
        child: InkWell(
          key: const ValueKey<String>('sc300-drawer-handle'),
          onTap: () => setState(() => _drawerOpen = !_drawerOpen),
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(10),
          ),
          child: SizedBox(
            width: 34,
            height: 72,
            child: Icon(
              _drawerOpen
                  ? Icons.chevron_right
                  : Icons.chevron_left,
              color: const Color(0xFF7AD4F6),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1116),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _playfieldSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            _clampCamera();

            final drawerWidth = (constraints.maxWidth * 0.44)
                .clamp(300.0, 390.0)
                .toDouble();

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (event) {
                      _activePointers += 1;
                      if (_activePointers == 1) {
                        _dragStart = event.localPosition;
                        _dragCurrent = event.localPosition;
                        _dragSelecting = false;
                      } else {
                        _dragStart = null;
                        _dragCurrent = null;
                        _dragSelecting = false;
                      }
                    },
                    onPointerMove: (event) {
                      if (_activePointers == 1 &&
                          _dragStart != null) {
                        _dragCurrent = event.localPosition;
                        final delta = _dragCurrent! - _dragStart!;
                        if (delta.distance >= _dragThreshold) {
                          _dragSelecting = true;
                        }
                        setState(() {});
                      }
                    },
                    onPointerUp: (event) {
                      if (_activePointers == 1) {
                        setState(() {
                          if (_dragSelecting) {
                            _finishSelectionDrag();
                          } else {
                            _dragStart = null;
                            _dragCurrent = null;
                            _dragSelecting = false;
                            _handleBattlefieldTap(
                              event.localPosition,
                            );
                          }
                        });
                      }
                      _activePointers =
                          (_activePointers - 1).clamp(0, 99).toInt();
                      if (_activePointers < 2) {
                        _lastScaleFocal = null;
                        _lastScaleValue = null;
                      }
                    },
                    onPointerCancel: (_) {
                      _activePointers = 0;
                      _dragStart = null;
                      _dragCurrent = null;
                      _dragSelecting = false;
                      _lastScaleFocal = null;
                      _lastScaleValue = null;
                      setState(() {});
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (details) {
                        if (_activePointers < 2) return;
                        _lastScaleFocal = details.focalPoint;
                        _lastScaleValue = 1;
                        _dragStart = null;
                        _dragCurrent = null;
                        _dragSelecting = false;
                      },
                      onScaleUpdate: (details) {
                        if (_activePointers < 2) return;
                        final current = details.focalPoint;
                        final previous = _lastScaleFocal;
                        if (previous != null) {
                          final delta = current - previous;
                          camera.panByScreenDelta(
                            Vec2(delta.dx, delta.dy),
                          );
                        }

                        final previousScale = _lastScaleValue ?? 1;
                        final scaleDelta =
                            details.scale / previousScale;
                        if ((scaleDelta - 1).abs() > 0.002) {
                          camera.zoomAt(
                            scaleDelta: scaleDelta,
                            focalScreen: Vec2(
                              current.dx,
                              current.dy,
                            ),
                          );
                        }

                        _lastScaleFocal = current;
                        _lastScaleValue = details.scale;
                        _clampCamera();
                        setState(() {});
                      },
                      onScaleEnd: (_) {
                        _lastScaleFocal = null;
                        _lastScaleValue = null;
                      },
                      child: CustomPaint(
                        key: const ValueKey<String>(
                          'sc300-battlefield',
                        ),
                        painter: SwiftRtsPainter(
                          runtime: runtime,
                          camera: camera,
                          selectionBox: _selectionBox,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _topHud(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _bottomCommandBar(),
                ),
                if (_drawerOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      key: const ValueKey<String>('sc300-drawer-scrim'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _drawerOpen = false),
                      child: const ColoredBox(
                        color: Color(0x44000000),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  width: drawerWidth,
                  right: _drawerOpen ? 0 : -drawerWidth,
                  child: _drawer(drawerWidth),
                ),
                _drawerHandle(drawerWidth),
                const Positioned(
                  left: 10,
                  bottom: 68,
                  child: IgnorePointer(
                    child: Text(
                      '1 finger select/box • 2 fingers pan + pinch zoom',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                if (_rallyFacility != null)
                  const Positioned(
                    left: 12,
                    top: 64,
                    child: IgnorePointer(
                      child: Chip(
                        label: Text('RALLY TARGETING'),
                      ),
                    ),
                  ),
                if (runtime.specialPowerTargeting)
                  const Positioned(
                    left: 12,
                    top: 64,
                    child: IgnorePointer(
                      child: Chip(
                        label: Text('SPECIAL POWER TARGETING'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
