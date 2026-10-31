import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../sc_master/core/math/vec2.dart';
import '../catalog/rts_catalog.dart';
import '../runtime/runtime_queue.dart';
import '../runtime/swift_rts_runtime.dart';
import '../runtime/visibility_grid.dart';
import 'rts_camera.dart';

class SwiftRtsPainter extends CustomPainter {
  const SwiftRtsPainter({
    required this.runtime,
    required this.camera,
    required this.selectionBox,
  });

  final SwiftRtsRuntime runtime;
  final RtsCamera camera;
  final Rect? selectionBox;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF101A18),
    );

    _drawTerrain(canvas, size);
    _drawOre(canvas);
    _drawStorm(canvas);
    _drawBuildings(canvas);
    _drawRallyPoints(canvas);
    _drawUnits(canvas);
    _drawFog(canvas);
    _drawSelectionBox(canvas);
    _drawReadyStructureHint(canvas, size);
  }

  void _drawTerrain(Canvas canvas, Size size) {
    final topLeft = camera.worldToScreen(Vec2.zero);
    final bottomRight = camera.worldToScreen(
      Vec2(runtime.mapSpec.width, runtime.mapSpec.height),
    );

    final mapRect = Rect.fromLTRB(
      topLeft.x,
      topLeft.y,
      bottomRight.x,
      bottomRight.y,
    );
    canvas.drawRect(
      mapRect,
      Paint()..color = const Color(0xFF183026),
    );
    canvas.drawRect(
      mapRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A6B57),
    );

    final cell = SwiftRtsCatalog.cellSize * camera.zoom;
    if (cell < 14) return;

    final line = Paint()
      ..color = const Color(0x192CC88A)
      ..strokeWidth = 1;

    final firstCol =
        math.max(0, (camera.offset.x / SwiftRtsCatalog.cellSize).floor());
    final lastCol = math.min(
      (runtime.mapSpec.width / SwiftRtsCatalog.cellSize).ceil(),
      ((camera.offset.x + size.width / camera.zoom) /
              SwiftRtsCatalog.cellSize)
          .ceil(),
    );
    final firstRow =
        math.max(0, (camera.offset.y / SwiftRtsCatalog.cellSize).floor());
    final lastRow = math.min(
      (runtime.mapSpec.height / SwiftRtsCatalog.cellSize).ceil(),
      ((camera.offset.y + size.height / camera.zoom) /
              SwiftRtsCatalog.cellSize)
          .ceil(),
    );

    for (var col = firstCol; col <= lastCol; col += 1) {
      final x = camera
          .worldToScreen(Vec2(col * SwiftRtsCatalog.cellSize, 0))
          .x;
      canvas.drawLine(
        Offset(x, mapRect.top),
        Offset(x, mapRect.bottom),
        line,
      );
    }

    for (var row = firstRow; row <= lastRow; row += 1) {
      final y = camera
          .worldToScreen(Vec2(0, row * SwiftRtsCatalog.cellSize))
          .y;
      canvas.drawLine(
        Offset(mapRect.left, y),
        Offset(mapRect.right, y),
        line,
      );
    }
  }

  void _drawOre(Canvas canvas) {
    for (final field in runtime.oreFields) {
      if (field.depleted) continue;
      final center = camera.worldToScreen(field.position);
      final radius = (18 + math.sqrt(field.remaining) / 9) *
          camera.zoom.clamp(0.55, 1.35);

      canvas.drawCircle(
        Offset(center.x, center.y),
        radius.toDouble(),
        Paint()..color = const Color(0xFFB9892C),
      );
      canvas.drawCircle(
        Offset(center.x - radius * 0.25, center.y - radius * 0.2),
        (radius * 0.32).toDouble(),
        Paint()..color = const Color(0xFFE6C55C),
      );
      _text(
        canvas,
        '${field.remaining}',
        Offset(center.x, center.y + radius + 2),
        fontSize: 9,
        color: const Color(0xFFEADFA8),
        center: true,
      );
    }
  }

  void _drawStorm(Canvas canvas) {
    if (!runtime.matchRules.suddenDeathActive(runtime.world.tick)) return;
    const worldCenter = Vec2(600, 400);
    final center = camera.worldToScreen(worldCenter);
    final radius = runtime.stormRadius * camera.zoom;

    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xCCB45CFF),
    );
  }

  void _drawBuildings(Canvas canvas) {
    final primary = runtime.primaryFacilities.primaryIds(
      world: runtime.world,
      teamId: SwiftRtsRuntime.playerTeamId,
    );

    final buildings = runtime.world.buildings.values
        .where((building) => building.alive)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final building in buildings) {
      if (building.teamId != SwiftRtsRuntime.playerTeamId &&
          !runtime.visibility.isVisible(
            SwiftRtsRuntime.playerTeamId,
            building.position,
          )) {
        continue;
      }

      final blueprint =
          SwiftRtsCatalog.buildingOrNull(building.archetype);
      final cols = blueprint?.footprintCols ?? 2;
      final rows = blueprint?.footprintRows ?? 2;
      final worldWidth = cols * SwiftRtsCatalog.cellSize;
      final worldHeight = rows * SwiftRtsCatalog.cellSize;

      final topLeft = camera.worldToScreen(
        Vec2(
          building.position.x - worldWidth / 2,
          building.position.y - worldHeight / 2,
        ),
      );
      final rect = Rect.fromLTWH(
        topLeft.x,
        topLeft.y,
        worldWidth * camera.zoom,
        worldHeight * camera.zoom,
      );

      final fill = building.teamId == SwiftRtsRuntime.playerTeamId
          ? (building.powered
              ? const Color(0xFF326F87)
              : const Color(0xFF554A59))
          : const Color(0xFF8A3C3C);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = runtime.selection.contains(building.id) ? 3 : 1.5
          ..color = runtime.selection.contains(building.id)
              ? const Color(0xFFF3D45D)
              : const Color(0xFF101820),
      );

      _text(
        canvas,
        blueprint?.label ?? building.archetype,
        Offset(rect.left + 5, rect.top + 4),
        fontSize: 10,
        color: Colors.white,
        maxWidth: math.max(30, rect.width - 10).toDouble(),
      );

      if (!building.powered) {
        _text(
          canvas,
          'LOW POWER',
          Offset(rect.left + 5, rect.top + 19),
          fontSize: 8,
          color: const Color(0xFFFFC36B),
          maxWidth: math.max(30, rect.width - 10).toDouble(),
        );
      }

      _healthBar(
        canvas,
        Rect.fromLTWH(
          rect.left,
          rect.top - 9,
          math.min(100.0, rect.width),
          5,
        ),
        building.health,
        building.maxHealth,
      );

      if (primary.contains(building.id)) {
        _badge(
          canvas,
          Offset(rect.right - 11, rect.top + 11),
          'P',
          const Color(0xFFF4C84A),
        );
      }

      if (runtime.isCompromised(building.id)) {
        _badge(
          canvas,
          Offset(rect.left + 11, rect.top + 11),
          '!',
          const Color(0xFFEF6C78),
        );
      }

      if (runtime.flaggedCheaterTeams.contains(building.teamId)) {
        _badge(
          canvas,
          Offset(rect.right - 11, rect.bottom - 11),
          '!',
          const Color(0xFFFF5252),
        );
      }

      final queue = runtime.facilityQueueSnapshot(building.id);
      if (queue != null && queue.count > 0) {
        _queueBar(
          canvas: canvas,
          buildingRect: rect,
          queue: queue,
        );
      } else if (building.archetype == 'hq') {
        final structureQueue = runtime.structureQueueSnapshot(building.teamId);
        if (structureQueue.count > 0) {
          _queueBar(
            canvas: canvas,
            buildingRect: rect,
            queue: structureQueue,
          );
        }
      }
    }
  }

  void _drawUnits(Canvas canvas) {
    final units =
        runtime.world.units.values.where((unit) => unit.alive).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in units) {
      if (unit.teamId != SwiftRtsRuntime.playerTeamId &&
          !runtime.visibility.isVisible(
            SwiftRtsRuntime.playerTeamId,
            unit.position,
          )) {
        continue;
      }

      final point = camera.worldToScreen(unit.position);
      final center = Offset(point.x, point.y);
      final friendly = unit.teamId == SwiftRtsRuntime.playerTeamId;
      final fill =
          friendly ? const Color(0xFF65C9F3) : const Color(0xFFEF6666);

      switch (unit.archetype) {
        case 'tank':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: center,
                width: (27 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
                height: (18 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
              ),
              const Radius.circular(3),
            ),
            Paint()..color = fill,
          );
          break;
        case 'harvester':
          canvas.drawRect(
            Rect.fromCenter(
              center: center,
              width: (30 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
              height: (20 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
            ),
            Paint()..color = fill,
          );
          break;
        case 'engineer':
          canvas.drawCircle(
            center,
            (9 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
            Paint()..color = const Color(0xFF76D6A8),
          );
          break;
        case 'spy':
          canvas.drawCircle(
            center,
            (9 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
            Paint()..color = const Color(0xFFC68BF4),
          );
          break;
        case 'mobile_hq_center':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: center,
                width: (34 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
                height: (24 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
              ),
              const Radius.circular(5),
            ),
            Paint()..color = const Color(0xFF8ED0FF),
          );
          break;
        default:
          canvas.drawCircle(
            center,
            (7 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
            Paint()..color = fill,
          );
          break;
      }

      if (runtime.selection.contains(unit.id)) {
        canvas.drawCircle(
          center,
          (15 * camera.zoom.clamp(0.75, 1.2)).toDouble(),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = const Color(0xFFF3D45D),
        );
      }

      if (runtime.flaggedCheaterTeams.contains(unit.teamId)) {
        _text(
          canvas,
          '!',
          Offset(center.dx + 10, center.dy - 14),
          fontSize: 12,
          color: const Color(0xFFFF5252),
          bold: true,
        );
      }

      _healthBar(
        canvas,
        Rect.fromLTWH(
          center.dx - 18,
          center.dy - 24,
          36,
          4,
        ),
        unit.health,
        unit.maxHealth,
      );

      if (unit.archetype == 'harvester') {
        final cargo = runtime.harvesters[unit.id];
        if (cargo != null) {
          _text(
            canvas,
            '${cargo.cargo}/${cargo.capacity}',
            Offset(center.dx, center.dy + 12),
            fontSize: 8,
            color: Colors.white70,
            center: true,
          );
        }
      }
    }
  }

  void _drawRallyPoints(Canvas canvas) {
    for (final entry in runtime.rallyPoints.entries) {
      final building = runtime.world.buildings[entry.key];
      if (building == null || !building.alive) continue;

      final from = camera.worldToScreen(building.position);
      final to = camera.worldToScreen(entry.value);

      canvas.drawLine(
        Offset(from.x, from.y),
        Offset(to.x, to.y),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xAA70D9FF),
      );
      canvas.drawCircle(
        Offset(to.x, to.y),
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF70D9FF),
      );
      canvas.drawLine(
        Offset(to.x, to.y - 12),
        Offset(to.x, to.y + 10),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF70D9FF),
      );
    }
  }

  void _drawFog(Canvas canvas) {
    final visible = runtime.visibility.visibleCells(
      SwiftRtsRuntime.playerTeamId,
    );
    final explored = runtime.visibility.exploredCells(
      SwiftRtsRuntime.playerTeamId,
    );

    for (var row = 0; row < runtime.visibility.rows; row += 1) {
      for (var col = 0; col < runtime.visibility.columns; col += 1) {
        final cell = VisibilityCell(col, row);
        if (visible.contains(cell)) continue;

        final worldTopLeft = Vec2(
          col * runtime.visibility.cellSize,
          row * runtime.visibility.cellSize,
        );
        final screen = camera.worldToScreen(worldTopLeft);
        final rect = Rect.fromLTWH(
          screen.x,
          screen.y,
          runtime.visibility.cellSize * camera.zoom + 0.5,
          runtime.visibility.cellSize * camera.zoom + 0.5,
        );

        canvas.drawRect(
          rect,
          Paint()
            ..color = explored.contains(cell)
                ? const Color(0x88101818)
                : const Color(0xE80A0E10),
        );
      }
    }
  }

  void _drawSelectionBox(Canvas canvas) {
    final rect = selectionBox;
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
        ..color = const Color(0xFF65C9F3),
    );
  }

  void _drawReadyStructureHint(Canvas canvas, Size size) {
    final queue =
        runtime.structureQueueSnapshot(SwiftRtsRuntime.playerTeamId);
    final order = queue.current;
    if (!queue.ready || order == null) return;

    final text = '${order.label} READY • tap battlefield to place';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 80);

    final rect = Rect.fromLTWH(
      16,
      size.height - 112,
      painter.width + 22,
      30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFFF4C84A),
    );
    painter.paint(
      canvas,
      Offset(rect.left + 11, rect.top + 7),
    );
  }

  void _healthBar(
    Canvas canvas,
    Rect rect,
    int current,
    int maximum,
  ) {
    final fraction = maximum <= 0
        ? 0.0
        : (current / maximum).clamp(0.0, 1.0).toDouble();
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xCC111827),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width * fraction,
        rect.height,
      ),
      Paint()
        ..color = fraction > 0.5
            ? const Color(0xFF62D197)
            : fraction > 0.25
                ? const Color(0xFFE5B95C)
                : const Color(0xFFE76868),
    );
  }

  void _queueBar({
    required Canvas canvas,
    required Rect buildingRect,
    required RuntimeQueueSnapshot queue,
  }) {
    final width = math.min(116.0, math.max(70.0, buildingRect.width));
    final rect = Rect.fromLTWH(
      buildingRect.left,
      buildingRect.bottom + 6,
      width,
      24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xE6111827),
    );

    final current = queue.current;
    final label = current == null
        ? '${queue.count}/${queue.limit}'
        : '${current.label} ${queue.count}/${queue.limit}'
            '${queue.ready ? " READY" : ""}';
    _text(
      canvas,
      label,
      Offset(rect.left + 4, rect.top + 3),
      fontSize: 8,
      color: Colors.white,
      maxWidth: rect.width - 8,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + 3,
        rect.bottom - 5,
        (rect.width - 6) * queue.progress,
        3,
      ),
      Paint()
        ..color = queue.ready
            ? const Color(0xFFF4C84A)
            : const Color(0xFF65C9F3),
    );
  }

  void _badge(
    Canvas canvas,
    Offset center,
    String text,
    Color color,
  ) {
    canvas.drawCircle(
      center,
      10,
      Paint()..color = color,
    );
    _text(
      canvas,
      text,
      center,
      fontSize: 10,
      color: const Color(0xFF111827),
      center: true,
      bold: true,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset, {
    double fontSize = 10,
    Color color = Colors.white,
    double? maxWidth,
    bool center = false,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: maxWidth == null ? null : '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);

    final position = center
        ? Offset(
            offset.dx - painter.width / 2,
            offset.dy - painter.height / 2,
          )
        : offset;
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant SwiftRtsPainter oldDelegate) => true;
}
