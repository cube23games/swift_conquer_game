import 'dart:ui';

import 'package:flutter/material.dart';

import '../buildings/building_footprint.dart';
import '../buildings/building_type.dart';
import '../core/entity_id.dart';
import '../core/world_state.dart';
import '../production/facility_production_queues.dart';
import '../production/production_unit_type.dart';
import '../map/map_definition.dart';
import '../map/map_grid.dart';
import '../math/vec2.dart';
import 'camera_view.dart';

class WorldPainter extends CustomPainter {
  final WorldState world;
  final CameraView cam;
  final Set<EntityId> selected;
  final MapDefinition? map;
  final MapGrid? grid;
  final Set<GridCell> buildRadiusCells;
  final BuildingType? pendingType;
  final Rect? selectionBoxScreen;
  final Set<EntityId> primaryProductionFacilities;
  final Map<EntityId, ProductionQueueSnapshot> productionQueueSnapshots;

  WorldPainter({
    required this.world,
    required this.cam,
    required this.selected,
    required this.map,
    required this.grid,
    required this.buildRadiusCells,
    required this.pendingType,
    required this.selectionBoxScreen,
    this.primaryProductionFacilities = const <EntityId>{},
    this.productionQueueSnapshots =
        const <EntityId, ProductionQueueSnapshot>{},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0B1220);
    canvas.drawRect(Offset.zero & size, bg);

    _drawMapBounds(canvas);
    _drawBuildRadius(canvas);
    _drawBlockedCells(canvas);
    _drawBuildings(canvas);
    _drawUnits(canvas);
    _drawSelectionBox(canvas);
    _drawHudHint(canvas, size);
  }

  void _drawMapBounds(Canvas canvas) {
    if (map == null) return;

    final topLeft = cam.worldToScreen(const Vec2(0, 0));
    final bottomRight = cam.worldToScreen(Vec2(map!.worldWidth, map!.worldHeight));

    final rect = Rect.fromLTRB(
      topLeft.x,
      topLeft.y,
      bottomRight.x,
      bottomRight.y,
    );

    canvas.drawRect(rect, Paint()..color = const Color(0xFF101A28));
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF223247),
    );
  }

  void _drawBuildRadius(Canvas canvas) {
    final g = grid;
    if (g == null) return;

    final fill = Paint()..color = const Color(0x2222C55E);

    for (final cell in buildRadiusCells) {
      final world = g.cellTopLeft(cell);
      final screen = cam.worldToScreen(world);
      final rect = Rect.fromLTWH(
        screen.x,
        screen.y,
        g.cellSize * cam.zoom,
        g.cellSize * cam.zoom,
      );
      canvas.drawRect(rect, fill);
    }
  }

  void _drawBlockedCells(Canvas canvas) {
    final g = grid;
    final m = map;
    if (g == null || m == null) return;

    final fill = Paint()..color = const Color(0xFF243244);

    for (final cell in m.blocked) {
      final world = g.cellTopLeft(cell);
      final screen = cam.worldToScreen(world);
      final rect = Rect.fromLTWH(
        screen.x,
        screen.y,
        g.cellSize * cam.zoom,
        g.cellSize * cam.zoom,
      );
      canvas.drawRect(rect, fill);
    }
  }

  void _drawBuildings(Canvas canvas) {
    final g = grid;
    if (g == null) return;

    for (final id in world.buildingIds) {
      final type = world.buildingTypes[id];
      final pos = world.buildingPositions[id];
      final team = world.buildingTeams[id];
      final hp = world.buildingHealth[id];

      if (type == null || pos == null) continue;

      final fp = footprintFor(type);
      final width = fp.cols * g.cellSize.toDouble();
      final height = fp.rows * g.cellSize.toDouble();

      final topLeftWorld = Vec2(pos.x - width / 2, pos.y - height / 2);
      final topLeftScreen = cam.worldToScreen(topLeftWorld);

      final rect = Rect.fromLTWH(
        topLeftScreen.x,
        topLeftScreen.y,
        width * cam.zoom,
        height * cam.zoom,
      );

      canvas.drawRect(rect, Paint()..color = _buildingColor(type, team?.id ?? 1));
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF0F172A),
      );

      if (selected.contains(id)) {
        canvas.drawRect(
          rect.inflate(4),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0xFFEAB308),
        );
      }

      if (primaryProductionFacilities.contains(id)) {
        _drawPrimaryProductionBadge(canvas, rect);
      }

      final queue = productionQueueSnapshots[id];
      if (queue != null) {
        _drawProductionQueue(canvas, rect, queue);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: type.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 8);

      tp.paint(canvas, Offset(rect.left + 4, rect.top + 4));

      if (hp != null && hp.max > 0) {
        final frac = (hp.current / hp.max).clamp(0.0, 1.0);
        const barH = 6.0;
        final barW = rect.width.clamp(28.0, 96.0);
        final topLeft = Offset(rect.left, rect.top - 10);

        canvas.drawRect(
          topLeft & Size(barW, barH),
          Paint()..color = const Color(0xFF2A3440),
        );

        canvas.drawRect(
          topLeft & Size(barW * frac, barH),
          Paint()..color = const Color(0xFF42D392),
        );
      }
    }
  }

  void _drawProductionQueue(
    Canvas canvas,
    Rect buildingRect,
    ProductionQueueSnapshot queue,
  ) {
    final width = buildingRect.width.clamp(58.0, 112.0).toDouble();
    final rect = Rect.fromLTWH(
      buildingRect.left,
      buildingRect.bottom + 5,
      width,
      22,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xDD111827),
    );

    final progressRect = Rect.fromLTWH(
      rect.left + 3,
      rect.bottom - 5,
      (rect.width - 6) * queue.progress,
      3,
    );
    canvas.drawRect(
      progressRect,
      Paint()
        ..color = queue.ready
            ? const Color(0xFFEAB308)
            : const Color(0xFF38BDF8),
    );

    final item = queue.current;
    final label = item == null
        ? '${queue.totalOrders}'
        : '${item.shortLabel} ${queue.totalOrders}/${queue.capacity}'
            '${queue.ready ? " READY" : ""}';

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 6);

    tp.paint(canvas, Offset(rect.left + 3, rect.top + 2));
  }

  void _drawPrimaryProductionBadge(Canvas canvas, Rect rect) {
    final center = Offset(rect.right - 10, rect.top + 10);
    canvas.drawCircle(
      center,
      10,
      Paint()..color = const Color(0xFFEAB308),
    );
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF111827),
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'P',
        style: TextStyle(
          color: Color(0xFF111827),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy - tp.height / 2,
      ),
    );
  }

  Color _buildingColor(BuildingType type, int teamId) {
    switch (type) {
      case BuildingType.hq:
        return const Color(0xFF1D4ED8);
      case BuildingType.powerPlant:
        return const Color(0xFFEAB308);
      case BuildingType.barracks:
        return const Color(0xFF7C3AED);
      case BuildingType.refinery:
        return const Color(0xFFEA580C);
      case BuildingType.warFactory:
        return const Color(0xFF475569);
      case BuildingType.mobileHqCenter:
        return teamId == 2 ? const Color(0xFFEF4444) : const Color(0xFF60A5FA);
    }
  }

  void _drawUnits(Canvas canvas) {
    for (final id in world.entities) {
      final pos = world.positions[id];
      if (pos == null) continue;

      final hp = world.health[id];
      final team = world.teams[id];
      final kind = world.unitKinds[id] ?? 'tank';

      final screen = cam.worldToScreen(pos.value);
      final center = Offset(screen.x, screen.y);

      final body = Paint()
        ..color = (team?.id == 2)
            ? const Color(0xFFEF4444)
            : const Color(0xFF60A5FA);

      if (kind == 'mobile_hq_center') {
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 28, height: 20),
          body,
        );
      } else if (kind == 'harvester') {
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 30, height: 18),
          body,
        );
      } else if (kind == 'tank') {
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 26, height: 16),
          body,
        );
      } else if (kind == 'infantry') {
        canvas.drawCircle(center, 9, body);
      } else {
        canvas.drawCircle(center, 14, body);
      }

      if (selected.contains(id)) {
        canvas.drawCircle(
          center,
          18,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0xFFEAB308),
        );
      }

      if (hp != null && hp.max > 0) {
        final frac = (hp.current / hp.max).clamp(0.0, 1.0);
        const barW = 40.0;
        const barH = 6.0;

        final topLeft = Offset(center.dx - barW / 2, center.dy - 26);

        canvas.drawRect(
          topLeft & const Size(barW, barH),
          Paint()..color = const Color(0xFF2A3440),
        );

        canvas.drawRect(
          topLeft & Size(barW * frac, barH),
          Paint()..color = const Color(0xFF42D392),
        );
      }
    }
  }

  void _drawSelectionBox(Canvas canvas) {
    final rect = selectionBoxScreen;
    if (rect == null) return;

    canvas.drawRect(
      rect,
      Paint()..color = const Color(0x2238BDF8),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF38BDF8),
    );
  }

  void _drawHudHint(Canvas canvas, Size size) {
    final hint = pendingType == null
        ? '1 finger select. 2 fingers pan + pinch zoom.'
        : 'Build mode: ${pendingType!.label}';

    final tp = TextPainter(
      text: TextSpan(
        text: hint,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 16);

    tp.paint(canvas, Offset(8, size.height - 24));
  }

  @override
  bool shouldRepaint(covariant WorldPainter oldDelegate) => true;
}
