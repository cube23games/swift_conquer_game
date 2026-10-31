import '../../sc_master/core/math/vec2.dart';

final class RtsCamera {
  RtsCamera({
    required this.offset,
    this.zoom = 1,
    this.minZoom = 0.55,
    this.maxZoom = 2.25,
  });

  Vec2 offset;
  double zoom;
  final double minZoom;
  final double maxZoom;

  Vec2 worldToScreen(Vec2 world) {
    return Vec2(
      (world.x - offset.x) * zoom,
      (world.y - offset.y) * zoom,
    );
  }

  Vec2 screenToWorld(Vec2 screen) {
    return Vec2(
      offset.x + screen.x / zoom,
      offset.y + screen.y / zoom,
    );
  }

  void panByScreenDelta(Vec2 delta) {
    offset = Vec2(
      offset.x - delta.x / zoom,
      offset.y - delta.y / zoom,
    );
  }

  void zoomAt({
    required double scaleDelta,
    required Vec2 focalScreen,
  }) {
    final before = screenToWorld(focalScreen);
    zoom = (zoom * scaleDelta).clamp(minZoom, maxZoom).toDouble();
    final after = screenToWorld(focalScreen);
    offset = Vec2(
      offset.x + before.x - after.x,
      offset.y + before.y - after.y,
    );
  }

  void clampToWorld({
    required double worldWidth,
    required double worldHeight,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final visibleWidth = viewportWidth / zoom;
    final visibleHeight = viewportHeight / zoom;

    final maxX =
        (worldWidth - visibleWidth).clamp(0.0, double.infinity).toDouble();
    final maxY =
        (worldHeight - visibleHeight).clamp(0.0, double.infinity).toDouble();

    offset = Vec2(
      offset.x.clamp(0.0, maxX).toDouble(),
      offset.y.clamp(0.0, maxY).toDouble(),
    );
  }
}
