import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_app/catalog/rts_catalog.dart';
import 'package:swift_conquer_game/sc_app/runtime/swift_rts_runtime.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';

void driveIdentically(
  SwiftRtsRuntime left,
  SwiftRtsRuntime right,
) {
  expect(left.deployPlayerHq(), isTrue);
  expect(right.deployPlayerHq(), isTrue);

  expect(
    left.queueStructure(SwiftRtsRuntime.playerTeamId, 'power_plant'),
    isTrue,
  );
  expect(
    right.queueStructure(SwiftRtsRuntime.playerTeamId, 'power_plant'),
    isTrue,
  );

  for (var i = 0;
      i < SwiftRtsCatalog.building('power_plant').prototypeBuildTicks;
      i += 1) {
    left.tick(1 / 60);
    right.tick(1 / 60);
  }

  expect(
    left.placeReadyStructure(
      teamId: SwiftRtsRuntime.playerTeamId,
      position: const Vec2(600, 290),
    ),
    isTrue,
  );
  expect(
    right.placeReadyStructure(
      teamId: SwiftRtsRuntime.playerTeamId,
      position: const Vec2(600, 290),
    ),
    isTrue,
  );

  for (var i = 0; i < 180; i += 1) {
    left.tick(1 / 60);
    right.tick(1 / 60);
  }
}

void main() {
  test('SC-300 runtime produces identical state and replay for same inputs', () {
    final left = SwiftRtsRuntime();
    final right = SwiftRtsRuntime();

    driveIdentically(left, right);

    expect(left.snapshot(), equals(right.snapshot()));
    expect(left.replayJson, equals(right.replayJson));
    expect(left.authoritativeHash, right.authoritativeHash);
  });
}
