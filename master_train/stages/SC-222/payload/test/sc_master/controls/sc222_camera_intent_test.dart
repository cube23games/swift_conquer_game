import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/control/camera_intent.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';

void main() {
  test('SC-222 camera conversion does not mutate world data', () {
    final camera = CameraIntent(offset: const Vec2(10, 20), zoom: 2);
    expect(camera.screenToWorld(const Vec2(20, 20)), const Vec2(20, 30));
  });
}
