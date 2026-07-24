import '../core/math/vec2.dart';

final class CameraIntent {
  Vec2 offset;
  double zoom;

  CameraIntent({
    this.offset = Vec2.zero,
    this.zoom = 1,
  });

  void pan(Vec2 screenDelta) {
    offset = offset - (screenDelta * (1 / zoom));
  }

  void zoomBy(double factor) {
    zoom = (zoom * factor).clamp(0.4, 3.0).toDouble();
  }

  Vec2 screenToWorld(Vec2 point) => offset + (point * (1 / zoom));
}
