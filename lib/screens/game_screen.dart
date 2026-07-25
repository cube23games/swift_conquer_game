import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../features/command_drawer/command_drawer.dart';
import '../features/command_drawer/command_drawer_handle.dart';
import '../features/hud/compact_status_hud.dart';
import '../features/hud/context_command_bar.dart';

import '../game/buildings/build_placement.dart';
import '../game/buildings/build_radius.dart';
import '../game/buildings/building_footprint.dart';
import '../game/buildings/building_type.dart';
import '../game/core/entity_id.dart';
import '../game/core/game_loop.dart';
import '../game/map/map_definition.dart';
import '../game/map/map_grid.dart';
import '../game/map/map_loader.dart';
import '../game/map/occupancy_map.dart';
import '../game/math/vec2.dart';
import '../game/state/build_mode.dart';
import '../game/state/camera_bookmarks.dart';
import '../game/state/selection_groups.dart';
import '../game/ui/camera_view.dart';
import '../game/ui/input_controller.dart';
import '../game/ui/world_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameLoop loop = GameLoop();
  final CameraView cam = CameraView(offset: const Vec2(0, 0), zoom: 1.0);
  final InputController input = InputController();
  final OccupancyMap occupancy = OccupancyMap();
  final BuildMode buildMode = BuildMode();
  final SelectionGroups groups = SelectionGroups();
  final CameraBookmarks bookmarks = CameraBookmarks();

  final Map<EntityId, int> _productionSpawnIndex = <EntityId, int>{};
  final Map<EntityId, int> _productionMoveIndex = <EntityId, int>{};

  Timer? _timer;

  MapDefinition? _map;
  MapGrid? _grid;
  bool _loading = true;
  String _status = 'Loading map...';

  int _activePointers = 0;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _dragSelecting = false;
  Offset? _lastScaleFocal;
  double? _lastScaleValue;

  bool _cameraPrimed = false;
  bool _commandDrawerOpen = false;
  Vec2? _homeCenter;

  static const double _dragThreshold = 12.0;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final loadedMap = await MapLoader.loadAsset('assets/maps/dev_map_01.json');
    _map = loadedMap;
    _grid = MapGrid(loadedMap);

    final center = Vec2(
      loadedMap.worldWidth / 2.0,
      loadedMap.worldHeight / 2.0,
    );

    final mobileHq = loop.world.spawnMobileHqCenter(
      center,
      teamId: 1,
      hp: 35,
    );

    _homeCenter = center;

    input.selected
      ..clear()
      ..add(mobileHq);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      loop.tick(1 / 60);
      if (mounted) {
        setState(() {});
      }
    });

    setState(() {
      _loading = false;
      _status = 'Central Mobile HQ Center ready. Move it, then deploy HQ.';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Rect? get _selectionBoxScreen {
    if (!_dragSelecting || _dragStart == null || _dragCurrent == null) {
      return null;
    }
    return Rect.fromPoints(_dragStart!, _dragCurrent!);
  }

  ButtonStyle _flatButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      side: BorderSide.none,
      backgroundColor: const Color(0xFFE8E2EA),
      foregroundColor: const Color(0xFF6D57A8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  ButtonStyle _chipButtonStyle() {
    return OutlinedButton.styleFrom(
      side: BorderSide.none,
      shadowColor: Colors.transparent,
      backgroundColor: const Color(0x221A2440),
      foregroundColor: const Color(0xFF7C68B4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  EntityId? _singleSelectedMobileHq() {
    if (input.selected.length != 1) return null;
    final id = input.selected.first;
    if (!loop.world.isMobileHqCenter(id)) return null;
    return id;
  }

  EntityId? _singleSelectedBuildingOfType(BuildingType type) {
    if (input.selected.length != 1) return null;
    final id = input.selected.first;
    if (!loop.world.buildingIds.contains(id)) return null;
    if (loop.world.buildingTypes[id] != type) return null;
    return id;
  }

  bool _hasFriendlyBuilding(BuildingType type) {
    for (final id in loop.world.buildingIds) {
      if (loop.world.buildingTeams[id]?.id != 1) continue;
      if (loop.world.buildingTypes[id] == type) return true;
    }
    return false;
  }

  bool get _hasFriendlyHq {
    for (final id in loop.world.buildingIds) {
      if (loop.world.buildingTeams[id]?.id != 1) continue;
      if (loop.world.buildingTypes[id] == BuildingType.hq) return true;
    }
    return false;
  }

  void _primeCameraIfNeeded(Size playfieldSize) {
    if (_cameraPrimed || _map == null || _homeCenter == null) return;

    final world = _map!;
    final center = _homeCenter!;

    final visibleWorldW = playfieldSize.width / cam.zoom;
    final visibleWorldH = playfieldSize.height / cam.zoom;

    final maxX = (world.worldWidth - visibleWorldW).clamp(0.0, double.infinity);
    final maxY = (world.worldHeight - visibleWorldH).clamp(0.0, double.infinity);

    final targetX = (center.x - visibleWorldW / 2.0).clamp(0.0, maxX.toDouble());
    final targetY = (center.y - visibleWorldH / 2.0).clamp(0.0, maxY.toDouble());

    cam.offset = Vec2(targetX, targetY);
    _cameraPrimed = true;
  }

  void _rebuildOccupancy() {
    occupancy.clear();
    final g = _grid;
    if (g == null) return;

    for (final id in loop.world.buildingIds) {
      final type = loop.world.buildingTypes[id];
      final pos = loop.world.buildingPositions[id];
      if (type == null || pos == null) continue;

      final fp = footprintFor(type);
      occupancy.occupy(
        g.footprintCellsForCenter(pos, fp.cols, fp.rows),
      );
    }
  }

  void _deploySelectedMobileHq() {
    final selected = _singleSelectedMobileHq();
    final g = _grid;
    if (selected == null || g == null) {
      setState(() {
        _status = 'Select the Mobile HQ Center first.';
      });
      return;
    }

    final pos = loop.world.positions[selected]?.value;
    if (pos == null) return;

    _rebuildOccupancy();

    final result = BuildPlacement.validate(
      world: loop.world,
      grid: g,
      occupancy: occupancy,
      teamId: 1,
      type: BuildingType.hq,
      center: pos,
      ignoreBuildRadius: true,
    );

    if (!result.ok) {
      setState(() {
        _status = 'Deploy failed: ${result.reason}';
      });
      return;
    }

    loop.world.destroy(selected);
    input.selected.remove(selected);

    final hq = loop.world.spawnBuilding(
      BuildingType.hq,
      result.snappedCenter,
      teamId: 1,
    );

    input.selected
      ..clear()
      ..add(hq);

    _rebuildOccupancy();

    setState(() {
      _status = 'HQ established. Open Commands to construct.';
      _commandDrawerOpen = true;
    });
  }

  void _toggleBuildMode(BuildingType type) {
    if (!_hasFriendlyHq) {
      setState(() {
        _status = 'Deploy the HQ first.';
      });
      return;
    }

    setState(() {
      if (buildMode.pendingType == type) {
        buildMode.clear();
        _status = 'Build mode cancelled.';
      } else {
        buildMode.select(type);
        _commandDrawerOpen = false;
        _status = 'Tap the map to place ${type.label}.';
      }
    });
  }

  bool _isUnitSpawnClear(Vec2 candidate) {
    final map = _map;
    if (map != null) {
      if (candidate.x < 16 ||
          candidate.y < 16 ||
          candidate.x > map.worldWidth - 16 ||
          candidate.y > map.worldHeight - 16) {
        return false;
      }
    }

    for (final id in loop.world.entities) {
      final pos = loop.world.positions[id]?.value;
      if (pos == null) continue;
      final dx = pos.x - candidate.x;
      final dy = pos.y - candidate.y;
      if ((dx * dx) + (dy * dy) < (44 * 44)) {
        return false;
      }
    }

    for (final id in loop.world.buildingIds) {
      final type = loop.world.buildingTypes[id];
      final center = loop.world.buildingPositions[id];
      if (type == null || center == null) continue;

      final fp = footprintFor(type);
      final halfW = fp.cols * 40.0 / 2.0;
      final halfH = fp.rows * 40.0 / 2.0;

      final left = center.x - halfW - 18.0;
      final right = center.x + halfW + 18.0;
      final top = center.y - halfH - 18.0;
      final bottom = center.y + halfH + 18.0;

      if (candidate.x >= left &&
          candidate.x <= right &&
          candidate.y >= top &&
          candidate.y <= bottom) {
        return false;
      }
    }

    return true;
  }

  List<Vec2> _productionSpawnCandidates(EntityId buildingId) {
    final type = loop.world.buildingTypes[buildingId]!;
    final center = loop.world.buildingPositions[buildingId]!;
    final fp = footprintFor(type);

    final halfW = fp.cols * 40.0 / 2.0;
    final halfH = fp.rows * 40.0 / 2.0;

    const dx1 = 84.0;
    const dx2 = 132.0;
    const dx3 = 180.0;
    const dy = 52.0;

    return <Vec2>[
      for (int row = -2; row <= 2; row++)
        Vec2(center.x + halfW + dx1, center.y + row * dy),
      for (int row = -2; row <= 2; row++)
        Vec2(center.x + halfW + dx2, center.y + row * dy),
      for (int row = -2; row <= 2; row++)
        Vec2(center.x + halfW + dx3, center.y + row * dy),
      for (int row = -2; row <= 2; row++)
        Vec2(center.x - halfW - dx1, center.y + row * dy),
      for (int row = -2; row <= 2; row++)
        Vec2(center.x, center.y - halfH - 64 + row * 24.0),
      for (int row = -2; row <= 2; row++)
        Vec2(center.x, center.y + halfH + 64 + row * 24.0),
    ];
  }

  List<Vec2> _productionMoveTargets(EntityId buildingId) {
    final type = loop.world.buildingTypes[buildingId]!;
    final center = loop.world.buildingPositions[buildingId]!;
    final fp = footprintFor(type);

    final halfW = fp.cols * 40.0 / 2.0;

    return <Vec2>[
      Vec2(center.x + halfW + 120, center.y - 140),
      Vec2(center.x + halfW + 120, center.y - 80),
      Vec2(center.x + halfW + 120, center.y - 20),
      Vec2(center.x + halfW + 120, center.y + 40),
      Vec2(center.x + halfW + 120, center.y + 100),
      Vec2(center.x + halfW + 180, center.y - 140),
      Vec2(center.x + halfW + 180, center.y - 80),
      Vec2(center.x + halfW + 180, center.y - 20),
      Vec2(center.x + halfW + 180, center.y + 40),
      Vec2(center.x + halfW + 180, center.y + 100),
    ];
  }

  Vec2 _findProductionSpawn(EntityId buildingId) {
    final candidates = _productionSpawnCandidates(buildingId);
    final start = (_productionSpawnIndex[buildingId] ?? 0) % candidates.length;

    for (int i = 0; i < candidates.length; i++) {
      final idx = (start + i) % candidates.length;
      final candidate = candidates[idx];
      if (_isUnitSpawnClear(candidate)) {
        _productionSpawnIndex[buildingId] = (idx + 1) % candidates.length;
        return candidate;
      }
    }

    final fallback = candidates[start % candidates.length];
    _productionSpawnIndex[buildingId] = (start + 1) % candidates.length;
    return fallback;
  }

  Vec2 _nextProductionMoveTarget(EntityId buildingId) {
    final targets = _productionMoveTargets(buildingId);
    final idx = (_productionMoveIndex[buildingId] ?? 0) % targets.length;
    _productionMoveIndex[buildingId] = (idx + 1) % targets.length;
    return targets[idx];
  }

  void _spawnProducedUnit({
    required EntityId buildingId,
    required String unitKind,
    required int hp,
    required String statusText,
  }) {
    final team = loop.world.buildingTeams[buildingId];
    if (team == null) return;

    final spawn = _findProductionSpawn(buildingId);

    final unit = loop.world.spawnUnit(
      spawn,
      teamId: team.id,
      hp: hp,
      kind: unitKind,
    );

    final moveTarget = _nextProductionMoveTarget(buildingId);
    loop.world.moveOrders[unit]?.target = moveTarget;

    setState(() {
      input.selected
        ..clear()
        ..add(unit);
      _status = statusText;
    });
  }

  void _produceInfantry() {
    final barracks = _singleSelectedBuildingOfType(BuildingType.barracks);
    if (barracks == null) return;
    _spawnProducedUnit(
      buildingId: barracks,
      unitKind: 'infantry',
      hp: 30,
      statusText: 'Infantry produced from Barracks.',
    );
  }

  void _produceHarvester() {
    final refinery = _singleSelectedBuildingOfType(BuildingType.refinery);
    if (refinery == null) return;
    _spawnProducedUnit(
      buildingId: refinery,
      unitKind: 'harvester',
      hp: 80,
      statusText: 'Harvester produced from Refinery.',
    );
  }

  void _produceTank() {
    final wf = _singleSelectedBuildingOfType(BuildingType.warFactory);
    if (wf == null) return;
    _spawnProducedUnit(
      buildingId: wf,
      unitKind: 'tank',
      hp: 120,
      statusText: 'Tank produced from War Factory.',
    );
  }

  void _handleTapAt(Offset localPos) {
    final g = _grid;
    if (_loading || g == null) return;

    final worldTap = cam.screenToWorld(Vec2(localPos.dx, localPos.dy));

    if (buildMode.isActive && buildMode.pendingType != null) {
      _rebuildOccupancy();

      final type = buildMode.pendingType!;
      final result = BuildPlacement.validate(
        world: loop.world,
        grid: g,
        occupancy: occupancy,
        teamId: 1,
        type: type,
        center: worldTap,
      );

      if (result.ok) {
        final built = loop.world.spawnBuilding(
          type,
          result.snappedCenter,
          teamId: 1,
        );
        _rebuildOccupancy();

        setState(() {
          buildMode.clear();
          input.selected
            ..clear()
            ..add(built);
          _dragStart = null;
          _dragCurrent = null;
          _dragSelecting = false;
          _lastScaleFocal = null;
          _lastScaleValue = null;
          _status = '${type.label} placed.';
          _commandDrawerOpen = true;
        });
      } else {
        setState(() {
          _status = 'Cannot place ${type.label}: ${result.reason}';
        });
      }
      return;
    }

    setState(() {
      input.onTapAt(localPos: localPos, world: loop.world, cam: cam);
      _status = input.selected.isEmpty
          ? 'Selection cleared.'
          : '${input.selected.length} item(s) selected.';
    });
  }

  void _finishSelectionDrag() {
    final rect = _selectionBoxScreen;
    if (rect != null &&
        rect.width >= _dragThreshold &&
        rect.height >= _dragThreshold) {
      input.selectBox(
        screenRect: rect,
        world: loop.world,
        cam: cam,
        teamId: 1,
      );
      _status = '${input.selected.length} unit(s) box-selected.';
    }
    _dragStart = null;
    _dragCurrent = null;
    _dragSelecting = false;
  }

  void _assignGroup(int slot) {
    groups.assign(slot, input.selected);
    setState(() {
      _status = 'Assigned ${input.selected.length} item(s) to group $slot.';
    });
  }

  void _recallGroup(int slot) {
    final recalled = groups.recall(slot, loop.world);
    setState(() {
      input.selected
        ..clear()
        ..addAll(recalled);
      _status = recalled.isEmpty
          ? 'Group $slot is empty.'
          : 'Recalled group $slot (${recalled.length}).';
    });
  }

  void _saveBookmark(int slot) {
    bookmarks.save(
      slot: slot,
      offset: cam.offset,
      zoom: cam.zoom,
    );
    setState(() {
      _status = 'Saved bookmark $slot.';
    });
  }

  void _recallBookmark(int slot) {
    final mark = bookmarks.recall(slot);
    if (mark == null) {
      setState(() {
        _status = 'Bookmark $slot is empty.';
      });
      return;
    }

    setState(() {
      cam.offset = Vec2(mark.offset.x, mark.offset.y);
      cam.zoom = mark.zoom;
      _status = 'Jumped to bookmark $slot.';
    });
  }

  Widget _buildGroupChip(int slot) {
    final count = groups.count(slot, loop.world);
    return GestureDetector(
      onLongPress: () => _assignGroup(slot),
      child: OutlinedButton(
        style: _chipButtonStyle(),
        onPressed: () => _recallGroup(slot),
        child: Text('$slot${count > 0 ? "($count)" : ""}'),
      ),
    );
  }

  Widget _buildBookmarkChip(int slot) {
    final filled = bookmarks.hasSlot(slot);
    return GestureDetector(
      onLongPress: () => _saveBookmark(slot),
      child: OutlinedButton(
        style: _chipButtonStyle(),
        onPressed: () => _recallBookmark(slot),
        child: Text('B$slot${filled ? "*" : ""}'),
      ),
    );
  }

  Widget _buildTopBookmarkBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            'Bookmarks:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          ...List<Widget>.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildBookmarkChip(i + 1),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildTopOverlay() {
    return CompactStatusHud(status: _status);
  }


  Widget _buildBottomBar() {
    final actions = <CommandBarAction>[];
    if (_singleSelectedMobileHq() != null) {
      actions.add(CommandBarAction(
        label: 'Deploy HQ',
        onPressed: _deploySelectedMobileHq,
        primary: true,
      ));
    }
    if (_singleSelectedBuildingOfType(BuildingType.barracks) != null) {
      actions.add(CommandBarAction(
        label: 'Produce Infantry',
        onPressed: _produceInfantry,
        primary: true,
      ));
    }
    if (_singleSelectedBuildingOfType(BuildingType.refinery) != null) {
      actions.add(CommandBarAction(
        label: 'Produce Harvester',
        onPressed: _produceHarvester,
        primary: true,
      ));
    }
    if (_singleSelectedBuildingOfType(BuildingType.warFactory) != null) {
      actions.add(CommandBarAction(
        label: 'Produce Tank',
        onPressed: _produceTank,
        primary: true,
      ));
    }
    actions.add(CommandBarAction(
      label: 'Clear',
      onPressed: () {
        setState(() {
          buildMode.clear();
          input.clearSelection();
          _status = 'Selection cleared.';
        });
      },
    ));
    actions.add(CommandBarAction(
      label: 'Commands',
      onPressed: () => setState(() => _commandDrawerOpen = true),
    ));
    return ContextCommandBar(
      selectionCount: input.selected.length,
      actions: actions,
    );
  }


  Widget _buildPersistentBuildSidebar() {
    return CommandDrawer(
      hasHq: _hasFriendlyHq,
      hasBarracks: _hasFriendlyBuilding(BuildingType.barracks),
      hasRefinery: _hasFriendlyBuilding(BuildingType.refinery),
      hasWarFactory: _hasFriendlyBuilding(BuildingType.warFactory),
      selectedBarracks:
          _singleSelectedBuildingOfType(BuildingType.barracks) != null,
      selectedRefinery:
          _singleSelectedBuildingOfType(BuildingType.refinery) != null,
      selectedWarFactory:
          _singleSelectedBuildingOfType(BuildingType.warFactory) != null,
      pendingType: buildMode.pendingType,
      onSelectStructure: _toggleBuildMode,
      onProduceInfantry: _produceInfantry,
      onProduceHarvester: _produceHarvester,
      onProduceTank: _produceTank,
      onClose: () => setState(() => _commandDrawerOpen = false),
      onRecallGroup: _recallGroup,
      onAssignGroup: _assignGroup,
      groupCount: (slot) => groups.count(slot, loop.world),
      onRecallBookmark: _recallBookmark,
      onSaveBookmark: _saveBookmark,
      bookmarkFilled: bookmarks.hasSlot,
    );
  }

  @override

  @override
  Widget build(BuildContext context) {
    final g = _grid;
    if (_loading || _map == null || g == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final buildRadius = BuildRadius.coverageForTeam(
      world: loop.world,
      grid: g,
      teamId: 1,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final drawerWidth =
                (constraints.maxWidth * 0.42).clamp(280.0, 360.0);
            final playfieldSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            _primeCameraIfNeeded(playfieldSize);

            return Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (event) {
                      _activePointers++;
                      if (_activePointers == 1 && !buildMode.isActive) {
                        _dragStart = event.localPosition;
                        _dragCurrent = event.localPosition;
                        _dragSelecting = false;
                      } else {
                        _dragStart = null;
                        _dragCurrent = null;
                        _dragSelecting = false;
                      }
                      setState(() {});
                    },
                    onPointerMove: (event) {
                      if (_activePointers == 1 &&
                          _dragStart != null &&
                          !buildMode.isActive) {
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
                        if (_dragSelecting) {
                          setState(_finishSelectionDrag);
                        } else {
                          _dragStart = null;
                          _dragCurrent = null;
                          _dragSelecting = false;
                          _handleTapAt(event.localPosition);
                        }
                      }
                      _activePointers =
                          (_activePointers - 1).clamp(0, 99);
                      if (_activePointers < 2) {
                        _lastScaleFocal = null;
                        _lastScaleValue = null;
                      }
                      setState(() {});
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
                        if (_activePointers >= 2) {
                          _lastScaleFocal = details.focalPoint;
                          _lastScaleValue = 1.0;
                          _dragStart = null;
                          _dragCurrent = null;
                          _dragSelecting = false;
                        }
                      },
                      onScaleUpdate: (details) {
                        if (_activePointers < 2) return;
                        final current = details.focalPoint;
                        final lastFocal = _lastScaleFocal;
                        if (lastFocal != null) {
                          final delta = current - lastFocal;
                          cam.panByScreenDelta(Vec2(delta.dx, delta.dy));
                        }
                        final lastScale = _lastScaleValue ?? 1.0;
                        final deltaScale = details.scale / lastScale;
                        if ((deltaScale - 1.0).abs() > 0.002) {
                          cam.zoomByScale(
                            scaleDelta: deltaScale,
                            focalScreen: Vec2(current.dx, current.dy),
                          );
                        }
                        _lastScaleFocal = current;
                        _lastScaleValue = details.scale;
                        setState(() {});
                      },
                      onScaleEnd: (_) {
                        _lastScaleFocal = null;
                        _lastScaleValue = null;
                      },
                      child: CustomPaint(
                        painter: WorldPainter(
                          world: loop.world,
                          cam: cam,
                          selected: input.selected,
                          map: _map,
                          grid: g,
                          buildRadiusCells: buildRadius,
                          pendingType: buildMode.pendingType,
                          selectionBoxScreen: _selectionBoxScreen,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Positioned(top: 0, left: 0, right: 0, child: _buildTopOverlay()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomBar(),
                ),
                if (_commandDrawerOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      key: const ValueKey('command-drawer-scrim'),
                      onTap: () =>
                          setState(() => _commandDrawerOpen = false),
                      child: const ColoredBox(color: Color(0x55000000)),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  width: drawerWidth,
                  right: _commandDrawerOpen ? 0 : -drawerWidth,
                  child: _buildPersistentBuildSidebar(),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  top: 104,
                  right: _commandDrawerOpen ? drawerWidth : 0,
                  child: CommandDrawerHandle(
                    open: _commandDrawerOpen,
                    onPressed: () => setState(
                      () => _commandDrawerOpen = !_commandDrawerOpen,
                    ),
                  ),
                ),
                const Positioned(
                  left: 10,
                  bottom: 72,
                  child: IgnorePointer(
                    child: Text(
                      '1 finger select • 2 fingers pan + pinch zoom',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
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
